# Schnellstart

Deine ersten fünfzehn Minuten mit WowVision: prüfen, dass es läuft, deine Stimme einstellen und die wichtigsten Tasten ausprobieren. Alles hier wird auf den Seiten, die bei den einzelnen Schritten verlinkt sind, ausführlicher erklärt.

Diese Seite setzt voraus, dass WowVision installiert ist und dein Charakter in der Spielwelt steht. Wenn nicht, beginne mit der [Installation](installation.md).

## Schritt 1: Prüfen, ob WowVision läuft

Drücke Umschalt+F1. Das WowVision-Menü öffnet sich, und WowVision liest seinen ersten Eintrag vor. Drücke Esc, um es wieder zu schließen.

Passiert nichts, tippe /wv ins Chatfeld und drücke Eingabe. Wenn auch das nichts bewirkt, ist WowVision nicht geladen: Siehe [Fehlerbehebung](troubleshooting.md#wowvision-lädt-nicht).

## Schritt 2: Die Stimme angenehm einstellen

Die meisten Spieler wollen eine schnellere Stimme als die Standardstimme.

1. Drücke Umschalt+F1, um das WowVision-Menü zu öffnen.
2. Suche mit Pfeil runter den Eintrag Sprache (Speech) und drücke Eingabe.
3. Gehe zu Sprachgeschwindigkeit (Speech Rate) und erhöhe sie um ein paar Stufen (0 ist normal; die Stimmen des Spiels akzeptieren -10 bis 10). Die neue Geschwindigkeit gilt ab sofort für alles, was WowVision sagt.
4. Ändere Sprachstimme (Speech Voice) und Sprachlautstärke (Speech Volume) auf dieselbe Weise, wenn du magst.
5. Drücke Esc, bis das Menü geschlossen ist.

Schneller geht es, praktisch zum Beispiel in einem Makro, das beim Anmelden läuft: Tippe `/wv speech 1 8 100` für Stimme 1, Geschwindigkeit 8 und Lautstärke 100. `/wv speech` allein gibt deine aktuellen Werte und die Liste der Stimmen mit ihren Nummern im Chatfenster aus (die erste Stimme hat meist die Nummer 0). Einzelheiten stehen unter [Sprache und Ton](../basics/speech.md).

## Schritt 3: Die Fenstertasten lernen

Öffne deine Taschen mit der Taschentaste des Spiels (standardmäßig B). WowVision liest das Taschenfenster vor. Probiere jetzt Folgendes:

| Taste | Was sie tut |
|---|---|
| Pfeil hoch / Pfeil runter | Durch die Plätze gehen |
| Tab / Umschalt+Tab | Zum nächsten oder vorherigen Teil des Fensters wechseln |
| Leertaste | Den Tooltip des Gegenstands lesen |
| Umschalt+Pfeil runter / Umschalt+Pfeil hoch | Den Tooltip Zeile für Zeile lesen |
| Eingabe | Linksklick (den Gegenstand aufnehmen) |
| Rücktaste | Rechtsklick (den Gegenstand benutzen oder anlegen) |
| Umschalt+F10 | Kontextmenü mit weiteren Aktionen |
| Esc | Das Fenster schließen |

Dieselben Tasten funktionieren in jedem Spielfenster und in den eigenen Fenstern von WowVision. Solange kein Fenster geöffnet ist, gehören diese Tasten wieder dem Spiel, du kannst also wie gewohnt laufen und kämpfen. Mehr dazu unter [Die Oberfläche bedienen](../basics/interface.md).

## Schritt 4: Deinen Status mit Puffern prüfen

Drücke, ohne etwas zu öffnen, ein paar Mal Alt+Pfeil runter. WowVision liest die Zeilen des Puffers Allgemein (General) vor: dein Leben, dein Mana oder eine andere Ressource, Erfahrung, Geld, freie Taschenplätze, Haltbarkeit, Post, Ruhestein, die Uhrzeit und deinen PvP-Status. Mit Alt+Pfeil hoch gehst du zurück.

Alt+Pfeil links und Alt+Pfeil rechts wechseln zu anderen Puffern, und Alt+Strg+Pfeil links und Alt+Strg+Pfeil rechts zu anderen Puffergruppen, sobald du welche angelegt hast. Siehe [Puffer](../information/buffers.md).

## Schritt 5: Der Spielwelt zuhören

Spiel einfach einen Moment und hör zu. Von Haus aus sagt WowVision an:

- dein neues Ziel, wenn du das Ziel wechselst, und seine Gesundheit in Fünf-Prozent-Schritten
- die Himmelsrichtung, wenn du dich drehst
- Zonen- und Unterzonenwechsel, in Gebäuden und im Freien, beim Schwimmen und Fliegen
- steigende Töne, wenn du fällst, und ein dumpfes Geräusch, wenn du gegen eine Wand läufst
- "Kampf begonnen", die Anzahl der Gegner, die gegen dich kämpfen, "Kampf beendet"
- Fehlermeldungen des Spiels wie "Außer Reichweite"
- Chatnachrichten in dem Reiter, den du gerade liest

Jede dieser Ansagen ist ein Alarm, den du im WowVision-Menü ändern oder ausschalten kannst. Siehe [Alarme](../basics/alerts.md).

## Schritt 6: Deinen Weg finden

- Drücke F9, um den Scanner zu öffnen: eine Liste von Questgebern, Quests und anderen Dingen um dich herum. Eingabe auf einem Eintrag startet die Führung dorthin.
- Drücke F10, um das Navigationsfenster zu öffnen und ein Ziel für eine Route zu wählen (in Versionen mit Kartendaten).
- Während eine Route läuft, drehst du dich mit I zum aktuellen Wegpunkt und hörst mit Alt Gr (oder Strg+Alt) die Entfernung. Umschalt+F12 beendet die Route.

Siehe [Scanner](../world/scanner.md) und [Navigation und Routen](../world/navigation.md).

## Schritt 7: Weitere Tasten, die du jetzt kennen solltest

| Taste | Was sie tut |
|---|---|
| Umschalt+F3 | Chatfenster: den Chatverlauf lesen |
| Umschalt+F4 | Fenster für die Aktionsleisten |
| Alt+T | Menü deines Ziels (flüstern, einladen und mehr) |
| Umschalt+I / Umschalt+O / Umschalt+P | Weiche Zielerfassung für Feinde, Interaktion und Freunde ein- oder ausschalten |
| Strg+Umschalt+F | Die Minimap nach Kräutern, Erz und anderen verfolgten Dingen absuchen (wo verfügbar) |

Alle Tasten stehen in der [Tastenreferenz](../reference/keybindings.md), und du kannst jede davon ändern: Siehe [Tastenbelegung](../basics/keybindings.md).

## Wie es weitergeht

- Lies [Die Oberfläche bedienen](../basics/interface.md) einmal gründlich; es zahlt sich in jedem Fenster aus.
- Stöbere im WowVision-Menü (Umschalt+F1), um zu sehen, welche Module und Alarme es gibt.
- Wenn etwas nicht funktioniert, siehe [Fehlerbehebung](troubleshooting.md).
