# Go-Frontend Core V12 — begrenzte Go-Ausdrücke und Deklarationen

Der neue Parser und alle Hilfsroutinen sind in **echten `ClosureExpr`-Funktionskörpern** als `semantic_document.v1` und `index_base=0`, `value_model="explicit"` geschrieben. Keine externen Imports.

- **655** V11-Funktionen unverändert übernommen, außer notwendiger Umbindung `main` → `compiler_v11_main`.
- **64** neue Core-Funktionen mit `syntax.child`, `semantic.call_target`, `ParameterDecl`, `ReturnStmt` und Verträgen; **63 separat geschlossene SE-Einzelmodule** unter `compiler/modules/` (die neue `main`-Integration steht im Gesamtdokument).
- Neuer Einstieg `GoFrontend_ParseTinyGo16(lo, hi)` gibt gepackten Status `((wert+1000000)*32+pos)` oder `-1` zurück. Die Eingabe sind zwei little-endian 64-Bit-Wörter mit höchstens 16 ASCII-Bytes und NUL-terminierter Kurzquelle; eingebettetes NUL ausgeschlossen.
- Grammar: Dezimalzahlen von 1–4 Stellen, `+`, `-`, `*`, `/`, `%`, unäres Vorzeichen, Klammern, Leerzeichen, sowie `return <expr>`, `var x = <expr>`, `const x = <expr>` und `x := <expr>` mit **einem ASCII-Zeichen als Variablennamen**. Operator-Priorität, linke Assoziativität und Division-durch-null-Abbruch. Ergebniswert -999999..999999.
- **16 native Linux-ELF-Ausführungstests** bestanden (einschließlich vollständigem V11→V12-Gesamtbuild mit Exitcode 147). Ein erweiterter Win64-Referenzemitter legt jetzt fünfte/sechste Argumente im Caller-Stack ab und liest sie im Callee aus. Eine PE64-Parser-Smoke-Datei ohne statische Imports liegt bei; **Windows-Ausführung ist nicht getestet**.
- `compiler/core/GoFrontend-TinyGo16-Closed.se`: eigenständiger erreichbarer Parser mit allen transitiven Call-Closures.
- `compiler/core/Semantic Document 1 - V12 Go Parser Attached.se`: Go-Parser an den bestehenden V11-Core angebunden.
- Ein Neuaufbau nach Entpacken erfolgt mit `python3 build_go_frontend_core_v12.py`; im Paket enthaltene `buildtools/` bilden alle benötigten Eingaben.

## Grenzen

Es ist ein **kleiner tatsächlich ausgeführter Go-Teilmengenparser/Evaluator, kein vollständiger Go-Parser**. Es gibt noch keine Ausgabe von Go-AST/UAST, keine Bezeichnerbindung von Deklarationen, kein Unicode, keine Multi-Byte-Strings, keine Go-Funktionen, Typechecker oder Imports. Die ursprünglichen 64 Rich-Go-Frontend-Funktionen und ihre unaufgelösten Runtime-Abhängigkeiten bleiben separat und nicht auf Core abgesenkt. Der Nachweis stammt vom Python-basierten Referenz-Codegenerator; SWC wurde nicht neu gebaut und hat diesen Parser nicht selbst kompiliert.
