<!-- Copyright (c) 2026 Tarek Wasfy -->

# Semantic Programming Language — Beispielprogramme

Diese Sammlung enthält kleine, aufeinander aufbauende Semantic-Programme im
lesbaren und prettified `.se`-Format. Jedes Dokument ist ein eigenständiges
Semantic-Programm und wurde mit der aktuellen Semantic-CLI validiert.

## Beispiele

| Datei | Inhalt |
| --- | --- |
| `01_hello_world.se` | Minimales Programm mit Textausgabe |
| `02_variables_arithmetic.se` | Variablen, Integerwerte und Arithmetik |
| `03_conditionals.se` | Bedingte Ausführung mit `if`/`else` |
| `04_loop_accumulator.se` | Schleife und aufsummierter Integerwert |
| `05_functions.se` | Funktion mit typisierten Parametern und Ergebnis |
| `06_boolean_logic.se` | Boolesche Werte und logische Verknüpfung |
| `07_multiple_results.se` | Funktion mit Mehrfachergebnis und positionsgetreuer Entnahme |
| `08_closure.se` | Closure mit eingefangener Umgebung |

## Verwendung

Mit der Semantic Programming Language CLI können die Dateien geprüft und
formatiert, nach Go transpiliert oder als native Ausgabe gebaut werden:

```text
Semantic Programming Language.exe semantic-validate 01_hello_world.se
Semantic Programming Language.exe semantic-format 01_hello_world.se -readable -o readable.se
Semantic Programming Language.exe semantic-transpile 01_hello_world.se -target go -o output.go
Semantic Programming Language.exe compile 01_hello_world.se -o example.exe
```

Der kompakte Alias `sp` ist äquivalent:

```text
Semantic Programming Language.exe sp semantic-validate 01_hello_world.se
```

Die Dateien sind bewusst klein gehalten: Jede demonstriert eine klar
abgrenzbare Semantic-/UAST-Fähigkeit und kann als Regressionstest oder als
Ausgangspunkt für eigene Programme verwendet werden.
