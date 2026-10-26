"""Inventory UAST kinds and evidence; this tool does not perform compiler lowering."""
import argparse,collections,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent
def read_graph(path):
    t=path.read_text(encoding='utf-8-sig')
    if t.lstrip().startswith('{'):return json.loads(t)['nodes']
    a=t.split('nodes=[\n',1)[1].split('\n]\nrelations=[\n',1)[0]
    return json.loads('['+a.rstrip(',\n')+']')
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    catalog=json.loads((ROOT/'manifests/uast-kinds.json').read_text(encoding='utf-8'))
    counts=collections.Counter(n['structural_kind'] for n in read_graph(args.source))
    # Each entry records only an established subset, never whole-kind completeness.
    subsets={
        'AggregateExpr':'Explicit bounded packed bytes; raw immutable stable-i64 parameter snapshots.',
        'AssignStmt':'Existing scalar slots and flat binding-pattern paths.',
        'BindingPattern':'Existing flat binding-pattern path; general destructuring is open.',
        'BreakStmt':'Nearest loop/switch with validated explicit control targets.',
        'CallExpr':'Named direct calls with at most six scalar arguments and supported intrinsics.',
        'ClosureExpr':'Named scalar functions; mutable captures and indirect calls remain open.',
        'ConditionalExpr':'Lazy integer Core conditionals, including V23 metadata-first nodes.',
        'ContinueStmt':'Nearest loop with validated control targets.',
        'ForEachStmt':'Existing pointer-aggregate iteration and bounded packed-byte iteration.',
        'IfStmt':'Scalar conditional branches.',
        'IndexExpr':'Bounded packed bytes; stable-i64 snapshots; proven V24 heap-view reads and effect-ordered writes with explicit sentinel policies.',
        'LiteralExpr':'Integer, Boolean and explicit finite binary64 literals; historical string-address path. General string/runtime representations remain open.',
        'LoopStmt':'Scalar while and supported iteration paths.',
        'MemberAccessExpr':'Existing backend-specific layout paths; general layouts and lvalues remain open.',
        'NilLiteral':'Explicit zero-represented 64-bit pointer and historical compiler nil forms.',
        'OperationExpr':'Scalar integer operations, typed Boolean short circuiting, explicit native binary64 arithmetic/comparisons declared switch forms, and explicit V24 unsafe page-memory intrinsics.',
        'ParameterDecl':'Scalar native ABI with at most six arguments.',
        'ReturnStmt':'Scalar returns.',
        'Scope':'Ordered statement traversal, including sparse statement ordinals.',
        'SliceExpr':'Bounded packed bytes; explicit-copy stable-i64 snapshots; proven V24 alias-preserving 64-bit heap views.',
        'SymbolRef':'Native local/parameter slots; raw snapshot reads require unique stable parameter binding.',
        'TupleExpr':'Raw bounded immutable stable-i64 snapshot reads.',
    }
    kinds=sorted(set(catalog['structural_kinds'])|set(counts))
    report={
        'schema':'swc.uast-lowering-inventory.v1',
        'source':str(args.source),'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest().upper(),
        'catalog_basis_sha256':catalog['basis_sha256'],
        'catalog_kinds':len(catalog['structural_kinds']),'observed_kinds':len(counts),'observed_nodes':sum(counts.values()),
        'full_uast_lowerable':False,
        'interpretation':'An executable subset is not proof that every instance, type, effect or source-language contract of a kind is lowerable. Type/effect/ABI and analysis nodes also require semantic consumption rather than standalone machine instructions.',
        'kinds':[{'kind':k,'source_nodes':counts[k],'full_semantics_verified':False,'native_subset':subsets.get(k),'status':'subset_evidence' if k in subsets else 'no_full_native_coverage_proof'} for k in kinds],
        'open_families':['General typed memory layout, allocation, aliasing and lvalue writes','General floating environments/conversions, strings, maps, interfaces and dynamic dispatch','Closures, captures, methods and indirect calls','General patterns, tuples and multiple results','Panic/recover, cleanup, defer and exception semantics','Channels, select, spawn/await and synchronization semantics','Generics, reflection, unsafe and foreign ABI contracts','Complete type/binding/ownership analysis and source-language preservation','Complete original Go frontend and native transpile CLI'],
    }
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(f"Catalog: {report['catalog_kinds']} kinds; source: {report['observed_nodes']} nodes / {report['observed_kinds']} kinds; full lowering: false")
if __name__=='__main__':main()
