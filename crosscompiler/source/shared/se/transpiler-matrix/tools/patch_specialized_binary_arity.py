#!/usr/bin/env python3
"""Add fail-closed left/right edge contracts to specialized binary lowerers."""
import argparse
import json
import re
from pathlib import Path


TARGETS = (
    "compile_signed_division_expr",
    "compile_unsigned_division_expr",
    "compile_unsigned_shift_expr",
    "compile_unsigned_compare_expr",
)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()
    source = Path(args.input).read_text(encoding="utf-8")
    match = re.search(r"nodes=\[(.*?)\]\s*relations=\[(.*?)\]", source, re.S)
    if not match:
        raise SystemExit("expected semantic_document.v1 nodes and relations arrays")
    nodes_list = json.loads("[" + match.group(1) + "]")
    relations = json.loads("[" + match.group(2) + "]")
    nodes = {int(n["id"]): n for n in nodes_list}
    next_id = max(nodes) + 1

    def new_node(kind: str, fields: dict) -> int:
        nonlocal next_id
        node_id = next_id
        next_id += 1
        nodes[node_id] = {"id": node_id, "structural_kind": kind, "fields": fields}
        return node_id

    def child(parent: int, target: int, role: str, ordinal: int = 0) -> None:
        relations.append({"kind": "syntax.child", "from": parent,
                          "to": {"domain": "node", "id": str(target)},
                          "attributes": {"missing": False, "name": "",
                                         "ordinal": ordinal, "role": role}})

    def ref(name: str) -> int:
        return new_node("SymbolRef", {"kind": "identifier", "name": name})

    def integer(value: int) -> int:
        return new_node("LiteralExpr", {"kind": "literal", "operation": {
            "literal_kind": "integer", "text": str(value)}})

    def call(name: str, args: list[int]) -> int:
        call_id = new_node("CallExpr", {"kind": "call"})
        callee = ref(name)
        child(call_id, callee, "callee")
        relations.append({"kind": "call.calls", "from": call_id,
                          "to": {"domain": "node", "id": str(callee)}})
        for i, arg in enumerate(args):
            child(call_id, arg, "argument", i)
        return call_id

    def operation(left: int, right: int) -> int:
        node_id = new_node("OperationExpr", {"kind": "binary", "operation": {
            "semantic_id": "not_equal", "semantics": {"operation": "not_equal"}}})
        child(node_id, left, "left")
        child(node_id, right, "right", 1)
        return node_id

    def expr_stmt(expr: int) -> int:
        node_id = new_node("ExprStmt", {"kind": "expression"})
        child(node_id, expr, "expression")
        return node_id

    def return_stmt(expr: int) -> int:
        node_id = new_node("ReturnStmt", {"kind": "return"})
        child(node_id, expr, "expression")
        return node_id

    def assign(name: str, expr: int) -> int:
        node_id = new_node("AssignStmt", {"kind": "assign", "name": name})
        child(node_id, expr, "expression")
        return node_id

    def get_binding(name: str) -> int:
        found = [int(n["id"]) for n in nodes.values()
                 if n["structural_kind"] == "ClosureExpr"
                 and n.get("fields", {}).get("operation", {}).get("function_binding") == name]
        if len(found) != 1:
            raise ValueError(f"expected one closure {name}, found {len(found)}")
        return found[0]

    def get_children(parent: int, role: str | None = None) -> list[dict]:
        out = [r for r in relations if r["kind"] == "syntax.child"
               and int(r["from"]) == parent]
        if role is not None:
            out = [r for r in out if r.get("attributes", {}).get("role") == role]
        return out

    for fn in TARGETS:
        closure_id = get_binding(fn)
        body_rel = get_children(closure_id, "body")
        if len(body_rel) != 1:
            raise ValueError(f"{fn}: expected one body edge, got {len(body_rel)}")
        body_id = int(body_rel[0]["to"]["id"])
        params = {r.get("attributes", {}).get("ordinal"): nodes[int(r["to"]["id"])]
                  for r in get_children(closure_id, "parameter")}
        param_names = {n.get("fields", {}).get("name") for n in params.values()}
        if not {"c", "id"}.issubset(param_names):
            raise ValueError(f"{fn}: expected c/id parameters, found {sorted(param_names)}")
        current = get_children(body_id, "statement")
        if any(nodes[int(r["to"]["id"])].get("fields", {}).get("name") == "specialized_left_edges"
               for r in current):
            continue

        # Preserve existing statement order by shifting it after the four guards.
        for rel in current:
            rel["attributes"]["ordinal"] = int(rel["attributes"].get("ordinal", 0)) + 4

        for idx, (label, role_code) in enumerate((("left", 7), ("right", 8))):
            count_expr = call("relation_role_count", [ref("c"), ref("id"), integer(role_code)])
            child(body_id, assign(f"specialized_{label}_edges", count_expr), "statement", idx)

        for idx, label in enumerate(("left", "right"), start=2):
            guard = new_node("IfStmt", {"kind": "if"})
            then_scope = new_node("Scope", {"kind": "block"})
            child(guard, operation(ref(f"specialized_{label}_edges"), integer(1)), "condition")
            child(guard, then_scope, "then")
            set_error = call("ctx_set", [ref("c"), integer(208), integer(1)])
            child(then_scope, expr_stmt(set_error), "statement", 0)
            child(then_scope, return_stmt(integer(-1)), "statement", 1)
            child(body_id, guard, "statement", idx)

    prefix, suffix = source[:match.start()], source[match.end():]
    node_rows = [json.dumps(n, ensure_ascii=False, separators=(",", ":"))
                 for n in sorted(nodes.values(), key=lambda n: int(n["id"]))]
    relation_rows = [json.dumps(r, ensure_ascii=False, separators=(",", ":")) for r in relations]
    replacement = "nodes=[\n" + ",\n".join(node_rows) + "\n]\nrelations=[\n" + ",\n".join(relation_rows) + "\n]"
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(prefix + replacement + suffix, encoding="utf-8", newline="\n")
    print(f"SPECIALIZED_BINARY_CONTRACTS={len(TARGETS)} NODES={len(nodes)} RELATIONS={len(relations)} OUTPUT={output.resolve()}")


if __name__ == "__main__":
    main()
