# Go-Frontend / Core-V11 — ausführbarer ASCII-Lexer-Anschluss

## Neu und tatsächlich implementiert

- 637 ursprüngliche V10-Core-Closures plus **18 neue SE-Core-Funktionen, `semantic_document.v1`, `index_base=0`, `value_model="explicit"`.
- `compiler/core/Semantic Document 1 - V11 Go Lexer Attached.se` ist das wirklich zusammengeführte Core-Dokument. Bisherige `main` nach `compiler_v10_main` umbenannt; neuer `main` ruft `GoFrontend_CoreSmoke` auf und kehrt nur bei erfolgreicher Lexik zu V10 zurück.
- `GoFrontend_TokenizeAscii8(word, next_byte)` klassifiziert ein **acht Byte langes, little-endian gepacktes ASCII-Quellstück**, kein komplettes Go-Programm. Tokenbits: Low8 Länge, Bits 8..15 Tokenart, Bit16 Fortsetzungsflag. 18 einzelne native Linux-Tests plus 1 integrierter Gesamtbuild bestanden. Rebuild: `python3 build_go_frontend_core_v11.py` nach Entpacken; als Ergebnis entsteht `rebuild_v11.zip`.
- `compiler/core/GoFrontend-Core-Closed-Lexer.se` enthält transitive Closure-Definitionen für einen einzeln importfreien Lexer-Baustein. Die Einzelroutinen besitzen echte Core-`ClosureExpr`-Funktionskörper und `semantic.call_target`-Kanten.
- `compiler/native/tests/` enthält nativ ausgeführte Linux-ELFs aus den SE-Core-Graphen; die Emitterwerkzeuge sind **Python-basiert, nicht der SWC Selfhost-Compiler**.

## Was unverändert und noch nicht ausführbar bleibt

`frontend-rich/` enthält die Original-Go-Frontend-Closures und den Adapter aus Deiner `se.zip`. **Diese Originalfunktionen sind noch nicht als Core ausführbar.** Ihr Format ist `index_base=1`, `tagged_dynamic_binary64` mit Rich-Knoten (`AggregateExpr`, `IndexExpr`, `ForEachStmt`, `MemberAccessExpr`, usw.) und bislang 1.786 offenen Aufrufstellen. Ein direktes Anhängen dieser Quelldatei an Core wäre irreführend. Unser neuer Lexer ist deshalb eine **neue native SE-Core-Funktionseinheit**, kein Ersatz für die originale `GoTypedSyntaxToSemantic`-Implementierung.

## Prüfungen

`compiler/compatibility.json` und `compiler/native_tests.json` enthalten die geprüften Formate, Aufruf-IDs und Ausführungsergebnisse. Original-GitHub-Repository und bisherige ZIP-Dateien wurden nicht verändert. Die aktuelle `swc (4).exe` wurde nicht neu gebaut.
