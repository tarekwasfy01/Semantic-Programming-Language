# COFF-/Legacy-Familienmatrix für SWC (2026-10-12)

Quelle der Evidenz:

- `D:\codex-build-selfhost\all-se-objects\*.obj`
- `D:\gui-maximalbuild-2026-09-08\se\internal\backend\*.se`
- Go-Backend unter `C:\Users\tarek\Desktop\Transpiler\Universal-Code-Transpiler - Kopie\snap-build\internal\backend\`
- aktiver Graph `src\swc-selfhost-windows.se`

Die OBJ-Dateien werden nicht als Payload gelinkt. Sie dienen nur zur ABI-/Familienbestätigung. Die aktive SWC bleibt Semantic-only und muss die ausführbaren Pfade selbst erzeugen.

## Matrix

| Familie | D-/OBJ-Evidenz | Aktiver SWC-Stand | Fehlerklasse | Nächster sichere Schritt |
|---|---|---|---|---|
| Literal/primitive values | `primitive_compiler.obj`, `machine_compile.obj` | im `compile_expr`-Pfad vorhanden | kein offener Kernfehler belegt | mit Fixture validieren |
| Index read/address | `uast_index_address`, `uast_target_codegen.obj`, `__index_set`-ABI | `compile_index_expr`, `uast_index_address`, `legacy_index_call_contract` vorhanden | Read-Pfad vorhanden; Write-ABI noch nicht native emittiert | Container-/Index-ABI explizit kontraktieren, dann `__index_set` in `compile_stmt`/assignment verdrahten |
| Member read/address | `legacy_member_get_emit`, `legacy_member_address_emit`, `uast_target_codegen.obj` | `compile_member_expr` und PE-Emitter vorhanden | Offset/Layout bleibt caller-supplied; kein Layout erfinden | Fixture mit belegtem Offset bis PE testen |
| Member/index write | Go: `__member_set`, `__index_set` | `native_store_family_code` + `native_store_emit_contract` sind als Semantic-Closures im aktiven Graph; der Emitter nutzt ausschließlich `emit_mov_mem_rax(c, offset)`; Familiencodes 1/2/3 sind kontraktiert | Container-/Index-Repräsentation und Member-Offset sind weiterhin caller-supplied; kein generischer Container-ABI erfunden | Rich-Assignment-Dispatch auf diese Verträge setzen; unbekannte Layouts bleiben fail-closed |
| Assignment targets | Go: `__assign_target` in `native_go_lower.go` | kein eindeutiger `compile_assign_target`-Closure im aktiven Graph | Rich-LValue-Semantik nicht vollständig im Native-Core | Index/member/general target getrennt lowern; unbekannt fail-closed |
| Type assertion | Go: `__type_assert` | kein aktiver nativer Type-assert-Lowerer belegt | Runtime-/Type-layout fehlt | nur nach belegtem Type-ABI importieren |
| Rich ForEach | `machine_compile.obj`, Rich units | `compile_foreach_stmt`, kind dispatch vorhanden | Iterator/map semantics absichtlich nicht erfunden | array/span Fixture; übrige Formen fail-closed |
| Slice | `uast_target_codegen.obj`, Rich units | `compile_slice_expr`, kind dispatch vorhanden | bounds/step/allocation nur teilweise kontraktiert | span-only path validieren |
| Switch | `primitive_compiler.obj`, `switch_cfg` | `compile_switch_stmt` traversiert statements; kind `23` erkannt | selector/case/default-Auswahl noch nicht graph-level vollständig | selector-once + ordered equality chain als native graph transform |
| Typed operation | D `native_function_43` / `uastTypedOperation` | keine 1:1 native D-Closure importierbar | D-Closure hängt an `g.*`, `graph.*`, Go stdlib | primitive operation table auf vorhandene SWC `OperationExpr` abbilden |
| Generic target codegen | `uast_target_codegen.obj` 189,649 B | nicht direkt importierbar | Host-compiler object model (`g.*`) | nur einzelne, belegte native emitter-Funktionen übernehmen |
| Execution registry/contracts | `uast_execution_registry.obj`, `uast_contracts.obj` | Rich contract units im Graph | Registry ist überwiegend Evidenz, nicht PE codegen | Familienmatrix als dispatch contract verwenden |

## Fehlerklassen nach Familien und Primitiven

Diese Tabelle trennt echte Native-Core-Fehler von absichtlich offenen ABI-
Verträgen. Ein Eintrag wird erst als behoben markiert, wenn der entsprechende
Pfad im erreichbaren Closure liegt und der Selfhost-Gate erfolgreich ist.

| Familie | Primitive/Operation | Aktueller Fehler | Sicherheitsklasse | Umsetzungskriterium |
|---|---|---|---|---|
| Werte | literal, symbol, constant | kein belegter Fehler | A: aktiv | vorhandener `compile_expr`-Emitter bleibt byte-stabil |
| Operationen | unary-not, compare, binary-op | kein belegter Fehler im Kernpfad | A: aktiv | `OperationExpr` wird auf vorhandene RAX-Primitiven abgebildet |
| Speicher lesen | `mem_load8`, `mem_load64` | Intrinsic vorhanden, Layout kommt vom Caller | B: ABI prüfen | nur belegte Adresse/Offset-Relationen verwenden |
| Speicher schreiben | `mem_store8`, `mem_store64` | Intrinsic vorhanden, Ziel-ABI nicht allgemein | B: ABI prüfen | keine erfundene Containerrepräsentation |
| Index | address/read | read/address erreichbar | B: Fixture fehlt | Container-, Index- und Elementlayout mit Fixture belegen |
| Index | `__index_set` | Write-Zielvertrag unvollständig | C: offen | native store family nur bei belegtem `(container,index,value)`-ABI |
| Member | address/read | Offset caller-supplied | B: Fixture fehlt | belegten Memberoffset bis PE verfolgen |
| Member | `__member_set` | Objekt-/Offsetlayout nicht vollständig belegt | C: offen | nur dokumentierte Layout-Relationen lowern |
| Assignment | slot target | bestehender einfacher Slotpfad aktiv | A: aktiv | unverändert lassen, da selfhost-stabil |
| Assignment | index/member/general target | kein eindeutiger Ziel-Lowerer | C: offen | Zielart zuerst klassifizieren, unbekannt fail-closed |
| Aggregate | element address | Primitive vorhanden, Layoutfälle nicht vollständig | B: Fixture fehlt | element address mit belegtem stride/offset testen |
| Slice | span start/length | bounds/step/allocation nicht vollständig | C: offen | span-only ohne implizite Allokation |
| ForEach | iterator-next/exit | array/span möglich, map/iterator offen | C: offen | exit-label und evaluation order zuerst testen |
| Control | break/continue | Core dispatch vorhanden | B: Nested-Fixture fehlt | verschachtelte Labels byte-stabil prüfen |
| Switch | selector/case/default | kind `23` erkannt; Arm-Call-Argumente und Statement-Kindrolle `1` verdrahtet, Selectorvergleich/Default-Auswahl weiterhin offen | B/C: teilweise | selector-once + geordnete Gleichheitskette |
| Type | `__type_assert` | Runtime-/Type-layout fehlt | C: offen | erst nach belegtem Type-ABI aktivieren |
| Runtime | `sys_open/read/write/close/mmap` | Intrinsics, keine fehlenden Semantic-Bindings | B: ABI prüfen | Windows-ABI und emitted call sequence prüfen |

Legende: **A** = im aktiven Native-Pfad; **B** = erreichbar, aber mit
belegungs-/ABI-Fixture zu verifizieren; **C** = bewusst nicht aktiviert.

## Aktueller Audit-Snapshot

- 156 Semantic-Unit-Dateien im Unit-Verzeichnis
- 443 Function-Bindings im aktiven Graph
- 113 erreichbare Native-Funktionen aus den Compiler-Roots
- 55 doppelte Binding-Gruppen (Auditproblem, nicht automatisch zusammenführen)
- 10 erreichbare Intrinsic-Namen ohne Semantic-Closure
- 162 kleine/stubverdächtige Closures im Gesamtgraph; kein Beweis, dass sie
  erreichbar sind
- aktive Graphgröße: 19.742 Nodes / 19.384 Relationen
- aktiver PE-Hash nach Compile-Expr-Emitter-Argumenten: `91199F5B38E560A0ACA13F4375851EA03B2D7DE46FA5BA911B9A4D362EB3066C`

Die zehn fehlenden erreichbaren Namen sind ausschließlich native Intrinsics:
`address_of`, `mem_load8`, `mem_load64`, `mem_store8`, `mem_store64`,
`sys_open`, `sys_read`, `sys_write`, `sys_close`, `sys_mmap`. Sie werden nicht
als Dummy-SE-Funktionen ergänzt, weil das den ABI verschleiern würde.

### Switch-Prüfung 2026-10-12

Die vorhandenen Einheiten `rich_switch_case_match` und
`rich_switch_default_match` beweisen nur:

- `selector == pattern -> 1`, sonst `0`
- `case_matched == 0 -> 1`, sonst `0`

Nicht belegt sind dagegen die Relationen für Selector-Auswertung genau einmal,
geordnete Case-Auswahl, Fall-through/Abbruch und die anschließende Body-
Ausführung. Deshalb bleibt `SwitchMatchStmt -> 23` zwar erkannt, aber die
graph-level Armselektion fail-closed. Ein bloßes Einfügen der skalaren
Prädikate würde keine vollständige UAST-Codegen-Semantik herstellen.

## Ergebnis des D-Importversuchs

Die D-Unit `uast_target_codegen.se` wurde lossless nach canonical JSON konvertiert (9.144 Nodes). Ein Closure-Import der vier relevanten Entry-Bindings wurde absichtlich abgewiesen, weil transitive Callees unresolved bleiben:

`__index_set`, `__make_float64`, `Check`, `fmt.Errorf`, `fmt.Sprintf`, `g.dispatch`, `g.freshName`, `g.letExpression`, `g.name`, `g.uastExpression`, `graph.firstChild`, `graph.many`, `length`, `native_var_append`, `native_var_targetSpec`, `native_var_unquote`, `operation.validate`, `strconv.Quote`, `strings.ContainsAny`, `strings.EqualFold`, `strings.Join`, `strings.TrimSpace`, `strings.TrimSuffix`.

Das ist kein SWC-Parserfehler. Es zeigt, dass diese D-Closure ein hostseitiger Go-Codegenerator ist und nicht ohne eine zusätzliche native Semantic-ABI-Schicht in den aktuellen PE-Core eingesetzt werden darf.

## Aktiver verifizierter Stand

- `swc.exe`: 121.856 Bytes
- `src\swc-selfhost-windows.se`: 4.498.329 Bytes
- neuer aktiver Baustein: `src\units\native-store-family-contract.se`
- neue Closures: `native_store_family_code`, `native_store_emit_contract`
- Import: 2 Bindings, 0 fehlend, 0 unresolved Callees
- letzter aktiver PE-Hash: `91199F5B38E560A0ACA13F4375851EA03B2D7DE46FA5BA911B9A4D362EB3066C`
- vollständiger Selfhost-Gate: PASS
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42

## Nachtrag: Member-Compile-Argumente 2026-10-12

Der erreichbare `compile_member_expr`-Closure wurde mit 44 belegten
Argument-Relationen vervollständigt: Basis-/Längenfelder, Membernamen,
rekursive Basis-Auswertung, die vier dokumentierten Member-Offsets und der
vorhandene PE-Emitter. Die Layoutwerte bleiben caller-supplied und wurden
nicht neu erfunden.

Aktiver Nachweis:

- `tmp\active-after-compile-member-args-20261012\current-state-report.json`
- Stage 2/3: PASS, jeweils 122.368 Bytes
- PE: gültig, x64, Entry in `.text`, kein trivialer Stub
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42

## Nachtrag: SwitchMatch-Kind-Code 2026-10-12

Die vorhandene Kind-Code-Tabelle ordnet `SwitchMatchStmt` dem Code `20` zu.
Der erreichbare `compile_stmt`-Dispatch verglich zuvor fälschlich mit `23`.
Der Vergleich wurde auf den belegten Code `20` korrigiert. Das ist keine neue
Switch-Semantik, sondern macht den bereits vorhandenen Switch-Lowerer
erreichbar.

Validierung:

- Aktiv: `tmp\active-after-switch-kind-code-20261012\current-state-report.json`
- Stage 2/3: PASS, jeweils 122.368 Bytes
- PE: gültig, x64, Entry in `.text`, kein trivialer Stub
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42
- Der Rich-Switch-Fixture-Test bleibt Exit 3, weil die Arm-/Default-
  Auswahl und Body-Ausführung noch nicht als vollständiger Graph vorliegen.

Zusätzliche direkte Rich-ABI-Validierung mit dem aktiven `swc.exe`:

- `uast-index-call-abi.se`: PASS
- `uast-member-address.se`: PASS
- `uast-slice-span.se`: PASS

Damit sind die drei vorhandenen ABI-Verträge lesbar und kompilierbar; das ist
noch kein Beweis für eine vollständige End-to-End-Rich-Programmsemantik.

## Nachtrag: Aggregate-Compile-Argumente 2026-10-12

Der erreichbare `compile_aggregate_expr`-Closure wurde mit 20 belegten
Argument-Relationen vervollständigt: Child-Iteration, Frame-Allokation,
Slot-/Adress-Emitter und rekursives Element-Compile. Der PE blieb dabei
byte-identisch, weil der Standard-Probe kein Aggregate enthält; der Graph ist
jedoch größer und der Kandidat bestand den vollständigen Selfhost-Gate.

Aktiver Nachweis:

- `tmp\active-after-compile-aggregate-args-20261012\current-state-report.json`
- Stage 2/3: PASS, jeweils 122.368 Bytes
- PE: gültig, x64, Entry in `.text`, kein trivialer Stub
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42

Der größere Kandidat wurde nach erfolgreichem Gate als `swc.exe` aktiviert.
Der vorherige Compiler liegt als
`tmp\swc-before-compile-expr-args-20261012.exe` vor. Das anschließende
Selfhost-Gate mit dem neuen `swc.exe` ist ebenfalls vollständig PASS:
122.368 Bytes in Stage 2 und Stage 3, gültiges x64-PE, byte-stabil, Runtime-
Probe Exit 42.

Zusatz-Audit nach diesem Patch: Im erreichbaren `compile_expr`- und
`compile_stmt`-Closure gibt es keine `CallExpr` mehr, die nur über ihren
`callee` und ohne Argument-Relationen verbunden sind. Das ist ein
Graph-Integritätsnachweis für diese beiden zentralen Compile-Pfade, aber noch
kein Beweis für vollständige Rich-Switch-Semantik.

## Nachtrag: Compile-Expr-Emitter-Argumente 2026-10-12

Im zentralen `compile_expr`-Closure wurden 26 fehlende Argument-Relationen
ergänzt: Aggregate- und Member-Dispatch, Unary-Byteemission,
`compile_expr`-Rekursion sowie der vorhandene Compare-Emitter. Alle Zielnodes
und Literale waren bereits im Graph vorhanden; es wurden keine neuen
Semantikregeln oder externen Payloads eingeführt.

Der PE-Kandidat wuchs dabei von 121.856 auf 122.368 Bytes.

Validierung:

- Kandidat: `tmp\compile-expr-args-gate-20261012\current-state-report.json`
- Aktiv: `tmp\active-after-compile-expr-args-20261012\current-state-report.json`
- Stage 2/3: PASS, jeweils 122.368 Bytes
- PE: gültig, x64, Entry in `.text`, kein trivialer Stub
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42

## Nachtrag: Slice-Compile-Argumente 2026-10-12

Im erreichbaren `compile_slice_expr`-Closure waren die vorhandenen Argument-
Nodes für `child`, die beiden `emit8`-Aufrufe, `compile_expr` und den
`compile_slice_expr`-Dispatch nicht über `syntax.child` verbunden. Diese zwölf
Relationen wurden ergänzt. Die bestehende Slice-Strategie und der vorhandene
Emitter bleiben unverändert; unbekannte Slice-Layouts bleiben weiterhin
fail-closed.

Validierung:

- Kandidat: `tmp\compile-slice-args-gate-20261012\current-state-report.json`
- Aktiv: `tmp\active-after-compile-slice-args-20261012\current-state-report.json`
- Stage 2/3: PASS, jeweils 121.856 Bytes
- PE: gültig, x64, Entry in `.text`, kein trivialer Stub
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42

## Nachtrag: Unary-/Boolean-Emitter-Argumente 2026-10-12

Im erreichbaren `compile_stmt`-Teilgraphen waren die fünf `emit8`-Aufrufe
des belegten Unary-/Boolean-Bytepfads nur mit ihrem Callee verbunden. Die
bereits vorhandenen `c`- und Byte-Literal-Nodes wurden mit zehn
`syntax.child`-Argument-Relationen angeschlossen. Es wurden keine neuen
Emitter oder ABI-Annahmen eingeführt.

Validierung:

- Kandidat: `tmp\compile-stmt-emit8-args-gate-20261012\current-state-report.json`
- Aktiv: `tmp\active-after-compile-stmt-emit8-args-20261012\current-state-report.json`
- Stage 2/3: PASS, jeweils 121.856 Bytes
- PE: gültig, x64, Entry in `.text`, kein trivialer Stub
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42

## Nachtrag: Switch-Dispatch-Argumente 2026-10-12

Im `compile_stmt`-Zweig für den Rich-Kind-Code `23` fehlten am Aufruf von
`compile_switch_stmt` die drei belegten Argumente `c`, `id` und `retk`. Der
Kandidat ergänzt genau diese drei `syntax.child`-Relationen am `CallExpr` 3420.
Es wurden keine neuen Semantikregeln und keine Runtime-Stubs eingeführt.

Validierung des Kandidaten und des anschließend aktivierten Graphen:

- Kandidat: `tmp\switch-dispatch-call-args-gate-20261012\current-state-report.json`
- Aktiv: `tmp\active-after-switch-dispatch-call-args-20261012\current-state-report.json`
- Stage 2/3: PASS, jeweils 121.856 Bytes
- PE: gültig, x64, Entry in `.text`, kein trivialer Stub
- Byte-Stabilität: PASS
- Runtime-Probe: PASS, Exit 42
- Direkter Rich-Switch-Fixture-Test bleibt bewusst offen (Exit 3), weil
  Selector-Auswertung, geordnete Case-Auswahl und Default-Ausführung noch
  nicht als vollständiger Semantic-Graph belegt sind.

## Gezählt im aktiven Semantic-Graph

- `ClosureExpr`: 515
- `AssignStmt`: 603
- `IndexExpr`: 23
- `MemberAccessExpr`: 11
- `SliceExpr`: 1
- `OperationExpr`: 1.389
- `CallExpr`: 2.160

Die Zählung ist eine Bestandsaufnahme des Graphen, kein Beweis dafür, dass jede Rich-Familie bereits bis zur PE-Emission reicht. Der Beweis bleibt der jeweilige Familienvertrag plus Selfhost-Gate.

## Regel für die nächste Implementierungsrunde

## Closure-Audit 2026-10-13

Der aktuelle erreichbare Compiler-Closure-Audit bestätigt:

- 443 Function-Bindings insgesamt
- 113 erreichbare Native-Funktionen
- 0 erreichbare Stubs
- 10 verbleibende externe Namen, ausschließlich dokumentierte Native-
  Intrinsics: `address_of`, `mem_load8`, `mem_load64`, `mem_store8`,
  `mem_store64`, `sys_open`, `sys_read`, `sys_write`, `sys_close`, `sys_mmap`
- Auditdatei: `tmp\call-closure-after-member-20261012.json`

Diese Intrinsics werden nicht als falsche Semantic-Closures ergänzt. Der
verbleibende Rich-UAST-Block ist damit nicht mehr allgemeine Call-Verkabelung,
sondern die belegte SwitchCase-/SwitchDefault-Auswahl und deren Body-ABI.

Eine Familie wird erst als „implementiert“ markiert, wenn ihr Graph keine unbelegten Host-Callees mehr enthält, der Native-Emitter den ABI ausgibt und der komplette Selfhost-Gate mit dem neuen Kandidaten besteht. OBJ-Größe allein ist kein Integrationsnachweis.
