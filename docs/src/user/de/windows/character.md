# Charakter

Im Charakterfenster siehst du, was du trägst, deine Werte, deinen Ruf, deine Fähigkeiten, deinen PvP-Stand und deine Währungen. WowVision liest es als eine Reihe von Haltepunkten, durch die du mit der Tab-Taste gehst. Der Inhalt jedes Reiters ist als Liste aufgebaut, die du mit den Pfeiltasten durchläufst.

Beschriftungen, die das Spiel selbst liefert, hörst du in der Sprache deines Spielclients. Wo hier ein englischer Name steht, ist das die Bezeichnung aus dem englischen Client.

## Wo es verfügbar ist

| Spielversion | Was gelesen wird |
|---|---|
| Classic Era | Noch nicht unterstützt. |
| The Burning Crusade (TBC) | Fünf Reiter: die Charakterpuppe (Ausrüstung, Werte, Widerstände), Begleiter, Ruf, Fähigkeiten und PvP. |
| Mists of Pandaria (Mists) | Die Charakterpuppe (Ausrüstung und Werte), Ruf und Währung. Der Reiter Begleiter steht in der Reiterliste, sein Inhalt wird aber noch nicht gelesen. |
| Retail | Noch nicht unterstützt. |
| WoW: Forever | Sechs Reiter: Charakter (Ausrüstung, Werte, Ausrüstungssets, Begleiterwerte), Ruf, Fähigkeiten, PvP, Währung und Statistiken. |

## Öffnen und Schließen

Öffne das Fenster mit der Charaktertaste des Spiels (C, solange du sie nicht geändert hast). Die Tasten des Spiels für einzelne Reiter, etwa die Ruftaste, öffnen dasselbe Fenster auf diesem Reiter, und WowVision liest den Reiter, den das Spiel gerade zeigt.

Mit Esc schließt du es. WowVision schließt dabei das eigene Fenster des Spiels für dich.

Ist auch das Addon Sku geladen, liest WowVision dieses Fenster nicht, damit sich nicht zwei Addons um dieselben Tasten streiten. Schalte Sku aus, wenn WowVision das Fenster lesen soll.

Du kannst das Vorlesen dieses Fensters mit dem Schalter Aktiviert aus- und einschalten: Öffne das WowVision-Menü mit Umschalt+F1, gehe zu Fenster und dann zu Charakter. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

## Wie das Fenster aufgebaut ist

Jeder Reiter besteht aus ein paar Haltepunkten. Tab und Umschalt+Tab wechseln zwischen den Haltepunkten, die Pfeiltasten bewegen dich innerhalb eines Haltepunkts. Der Inhalt des aktiven Reiters kommt zuerst, die Reiterleiste ist immer der letzte Haltepunkt. Das heißt:

- Beim Öffnen landest du auf dem ersten Haltepunkt des aktuellen Reiters, normalerweise der Ausrüstungsliste.
- Umschalt+Tab vom ersten Haltepunkt springt direkt zu den Reitern, weil die Haltepunkte im Kreis laufen.
- Um den Reiter zu wechseln, gehst du zum Haltepunkt Reiter, wählst mit Pfeil links und Pfeil rechts einen Reiter und drückst Eingabe. Der Reiter, auf dem du bist, wird als „ausgewählt“ gelesen. Der Inhalt darunter wird neu aufgebaut, und Tab bringt dich hinein.

Die Tasten, die bei den meisten Elementen hier funktionieren:

| Taste | Was sie tut |
|---|---|
| Eingabe | Linksklick: einen angelegten Gegenstand aufnehmen, eine Zeile öffnen oder auswählen, ein Kontrollkästchen umschalten. |
| Rücktaste | Rechtsklick: benutzt zum Beispiel einen angelegten Schmuckgegenstand. |
| \\ oder Strg+D | Ziehen: nimmt den fokussierten Ausrüstungsplatz auf, damit du den Gegenstand verschieben kannst. |
| Leertaste | Liest den Tooltip des fokussierten Elements. Umschalt+Pfeil hoch und Umschalt+Pfeil runter gehen seine Zeilen durch. |
| Umschalt+F10 | Kontextmenü mit Linksklick, Rechtsklick und Ziehen. |

(\\ liegt auf deutschen Tastaturen auf Alt Gr+ß; belege die Aktion bei Bedarf um.)

Mehr dazu unter [Die Oberfläche bedienen](../basics/interface.md) und [Tooltips](../basics/tooltips.md).

## Ausrüstung

Der erste Haltepunkt des Charakter-Reiters ist die Liste Ausrüstung, ein Eintrag pro Platz, in der Reihenfolge, in der das Spiel sie zeichnet: Kopf, Hals, Schultern, Rücken, Brust, Hemd, Wappenrock, Handgelenke, Hände, Taille, Beine, Füße, die zwei Fingerplätze, die zwei Schmuckplätze, Haupthand, Nebenhand, Distanz und, wo das Spiel einen hat, Munition.

- Ein belegter Platz liest den Gegenstandsnamen, gefolgt von seiner Qualität als Farbwort: „Sturmgeschmiedeter Helm, Blau“.
- Ein leerer Platz liest den Namen des Platzes: „Kopf“, „Finger“, „Haupthand“.
- Beim Munitionsplatz wird der Gegenstand auch dann gelesen, wenn das Spiel keinen Link dafür liefert.
- Ein Platz, den das Spiel ausblendet, wird übersprungen: In WoW: Forever erscheint der Munitionsplatz nur, solange du eine Fernkampfwaffe trägst, und Mists hat keinen Munitionsplatz.
- In WoW: Forever endet die Liste mit einer Zeile für deine Stufe („Stufe 60 Mensch Paladin“) und, bei einem Jäger mit Begleiter, mit der Loyalität des Begleiters.

Drücke Leertaste auf einem Platz, um den vollständigen Gegenstands-Tooltip mit seinen Werten zu lesen. Mit Eingabe nimmst du den Gegenstand auf deinen Cursor oder legst den Gegenstand, der gerade am Cursor hängt, in den Platz. Wie der Cursor funktioniert und wie du mit der Rücktaste etwas aus deinen Taschen anlegst, steht unter [Taschen und Bank](bags-and-bank.md). \\ oder Strg+D nimmt den Gegenstand ebenfalls auf, genau wie das Ziehen mit der Maus.

## Werte

Die Werte sind schreibgeschützte Zeilen wie „Stärke 142“ oder „Rüstung 1500“. Drücke Leertaste, um zu lesen, was ein Wert bedeutet.

### The Burning Crusade

Zwei Haltepunkte, beide Werte genannt: eine linke und eine rechte Spalte. Jede beginnt mit einem Dropdown, das die Kategorie wählt, die die Spalte zeigt (zum Beispiel Grundwerte, Nahkampf, Fernkampf, Zauber oder Verteidigung). Drücke Eingabe auf dem Dropdown, um das Menü des Spiels zu öffnen, wähle eine Kategorie, und die Zeilen darunter ändern sich. Nach dem Dropdown kommen bis zu sechs Wertezeilen.

Ein dritter Haltepunkt, Widerstände, liest die fünf Widerstände (Feuer, Frost, Natur, Schatten, Arkan) so, wie der Tooltip des Spiels sie formuliert.

### Mists of Pandaria

Ein Haltepunkt namens Werte. Jede Wertekategorie, die das Spiel zeigt, ist eine Zeile. Mit Pfeil hoch und Pfeil runter wechselst du die Kategorie (du hörst den Kategorienamen), mit Pfeil links und Pfeil rechts gehst du die Werte innerhalb der Kategorie durch.

### WoW: Forever

Die Werte liegen in einem Seitenfeld mit drei Ansichten, die du über die Seitenleisten-Reiter wählst (siehe unten). Der Haltepunkt Werte liest die Kategorieköpfe als Ansageebenen: Wenn du in eine Kategorie gehst, wird ihr Name einmal gesprochen, danach gehst du die Wertezeilen mit Pfeil hoch und Pfeil runter durch.

## Ausrüstungsmanager (nur WoW: Forever)

Wähle den Ausrüstungsmanager auf den Seitenleisten-Reitern, und das Feld wechselt zu deinen Ausrüstungssets. Die Haltepunkte in dieser Reihenfolge:

1. Die Setliste. Jedes Set liest seinen Namen, „, Angelegt“, wenn du es trägst, und „, 2 Gegenstände fehlen“, wenn Teile aus deinen Taschen verschwunden sind. Eingabe wählt ein Set aus, und die Zeile liest „ausgewählt“.
2. Neues Set (New Set).
3. Sobald ein Set ausgewählt ist, je ein Haltepunkt für Anlegen, Speichern, Set bearbeiten und Löschen. Anlegen zieht das ausgewählte Set an. Speichern legt in diesem Set ab, was du gerade trägst. Set bearbeiten öffnet das Fenster für Name und Symbol. Löschen lässt das Spiel ein Bestätigungs-Popup zeigen, das du wie jedes andere [Popup](system.md) beantwortest.

Neues Set und Set bearbeiten öffnen das Setfenster als eigenes Fenster: ein Eingabefeld für den Namen, ein Dropdown für den Symboltyp, eine Symbol-Nummer, die du mit Pfeil links und Pfeil rechts änderst (sie liest „3 von 120“; mit Eingabe kannst du eine Zahl tippen) und die Schaltflächen Okay und Abbrechen. Das Fenster öffnet sich mit dem Cursor im geleerten Namensfeld, sodass du die Pfeiltasten sofort benutzen kannst. Eingabe auf dem Namensfeld bringt dich zurück ins Tippen.

Die Seitenleiste hat außerdem einen Haltepunkt Seitenleisten-Reiter (eine Reiterleiste: Pfeil links/Pfeil rechts und Eingabe) und eine Schaltfläche, die das rechte Feld ein- oder ausklappt. Ist das Feld eingeklappt, werden nur die Ausrüstungsliste und die Umschalt-Schaltfläche gelesen. Die Ansicht mit den Begleiterwerten heißt Begleiter und listet die Werte deines Begleiters.

### Beispiel: In WoW: Forever zu deiner Tank-Ausrüstung wechseln

1. Drücke C. Du landest auf der Ausrüstungsliste.
2. Drücke Tab, bis du die Seitenleisten-Reiter hörst, und wähle mit Pfeil rechts und Eingabe den Ausrüstungsmanager.
3. Drücke Tab bis zur Setliste, gehe mit Pfeil runter zu „Tank, 1 Gegenstände fehlen“ (oder wie du dein Set genannt hast) und drücke Eingabe.
4. Drücke Tab, bis du Anlegen hörst, und drücke Eingabe.

## Ruf

Verfügbar in TBC, Mists und WoW: Forever.

Die Fraktionsliste ist ein Haltepunkt namens Ruf. Kopfzeilen (Classic, Burning Crusade, Streitkräfte der Allianz und so weiter) werden als „Ausgeklappt“ oder „Eingeklappt“ gelesen. Eingabe auf einer Kopfzeile klappt sie zu oder auf. Eine Fraktion liest ihren Namen, deinen Stand und den Fortschritt darin:

- „Expedition des Cenarius - Wohlwollend 4500 / 12000“
- In Mists und WoW: Forever lesen Freundschaftsfraktionen die Freundschaftsstufe, die das Spiel zeigt, zum Beispiel „Freund“, mit dem Fortschritt zur nächsten Stufe.
- In WoW: Forever lesen Ruhmfraktionen „Ruhm 12“ mit dem Fortschritt zur nächsten Stufe. Sobald du den höchsten Stand, die höchste Freundschaftsstufe oder den höchsten Ruhm erreicht hast, wird kein Fortschritt mehr gelesen, zum Beispiel „Sturmwind - Ehrfürchtig“.

Eingabe auf einer Fraktion öffnet ihre Details. In WoW: Forever liest die Zeile außerdem „ausgewählt“, solange sie die gewählte Fraktion ist; in TBC und Mists tut sie das nicht. In TBC und Mists sind die Details ein eigener Haltepunkt, benannt nach der Fraktion. In WoW: Forever sind sie ein Haltepunkt Details. Er liest der Reihe nach:

- Die Beschreibung der Fraktion. In WoW: Forever kommen zuerst Titel und Untertitel, dann die Beschreibung und die Detailzeilen.
- Im Krieg, ein Kontrollkästchen.
- Move to Inactive, ein Kontrollkästchen (das Spiel verschiebt die Fraktion in die inaktive Gruppe am Ende).
- Beobachtet, ein Kontrollkästchen, das die Fraktion auf deiner Erfahrungsleiste anzeigt. In WoW: Forever sind die Beschriftungen der drei Kontrollkästchen die eigenen Worte des Spiels.
- Schließen in TBC und Mists. View Renown in WoW: Forever bei Ruhmfraktionen.

In WoW: Forever steht vor der Liste ein Haltepunkt Filter-Dropdown, in dem du wählst, welche Fraktionen die Liste zeigt.

### Beispiel: In TBC einen Ruf beobachten

1. Drücke C, dann Umschalt+Tab, um zu den Reitern zu kommen, Pfeil rechts bis Ruf und Eingabe.
2. Drücke Tab, um in die Liste zu gehen. Gehe mit Pfeil runter zu „Expedition des Cenarius - Wohlwollend 4500 / 12000“.
3. Drücke Eingabe. Die Details der Fraktion öffnen sich.
4. Drücke Tab, um zu den Fraktionsdetails zu kommen. Gehe mit den Pfeiltasten zu Beobachtet, Kontrollkästchen, Nicht aktiviert und drücke Eingabe. Jetzt liest es „Aktiviert“.

## Fähigkeiten (TBC und WoW: Forever)

Der Fähigkeiten-Reiter listet deine Fertigkeitslinien: Berufe, Nebenberufe, Waffenfertigkeiten, Rüstungsfertigkeiten und Sprachen.

- In TBC steht zuerst eine Schaltfläche Alle einklappen / Alle ausklappen. Ihre Beschriftung zeigt, was das Drücken bewirkt.
- Kopfzeilen lesen „Ausgeklappt“ oder „Eingeklappt“ und klappen mit Eingabe zu oder auf.
- In TBC liest eine Fertigkeit mit Stufen ihren Namen, den Rang und das Maximum: „Bergbau 150/300“. Ein aktiver Bonus steht in Klammern: „Bergbau 150 (+15)/300“. Fertigkeiten ohne Stufen (Rüstungsfertigkeiten, Sprachen) lesen nur ihren Namen.
- In WoW: Forever liest jede Fertigkeit Rang und Maximum mit Leerzeichen um den Schrägstrich: „Bergbau 150 / 300“, mit dem Bonus in Klammern: „Bergbau 150 (+15) / 300“.
- Eingabe wählt eine Fertigkeit aus („ausgewählt“).

Die Details der ausgewählten Fertigkeit kommen nach der Liste. In TBC sind sie ein Haltepunkt Fähigkeitsdetails: die Rangzeile, die Beschreibung und, bei Berufen, die du verlernen kannst, eine Schaltfläche Verlernen. Verlernen öffnet das Bestätigungs-Popup des Spiels. In WoW: Forever sind die Details ein Haltepunkt Details mit Zeilen derselben Art.

## PvP

### The Burning Crusade

Ein Haltepunkt, PVP, der als kurze Zeilen gelesen wird:

- Deine Ehrenpunkte und deine Arenapunkte, jeweils mit ihrem Wert („Ehrenpunkte 1234“).
- Eine Gruppe Ehrenhafte Siege mit „Heute: 12“, „Gestern: 8“ und „Gesamt: 3540“.

Die Umschalt-Schaltfläche am Ende des Reiters wechselt die Statistik zwischen den beiden Ansichten, die das Spiel anbietet, und liest die Beschriftung des Spiels.

### WoW: Forever

Ein Haltepunkt PvP liest die Zeilen des Rangsystems so, wie das Spiel sie zeigt: den Saison-Timer, die aktuelle Saison, deinen Rang und deinen Fortschritt zum nächsten. Danach folgt eine Schaltfläche Nächste Belohnung, dann ein Haltepunkt Details mit den Rang-Informationen.

## Begleiter (nur TBC)

Den Reiter Begleiter gibt es nur, solange du einen Begleiter mit eigenem Begleiterfenster hast (Jäger und Hexenmeister). Ohne einen liest der Reiter „Kein Begleiter“. Mit Begleiter gibt es einen Haltepunkt namens Begleiter mit:

- Name, Stufe, Loyalität und Trainingspunkten,
- dem Erfahrungstext,
- der Ernährung („Ernährung: Fleisch, Fisch“),
- einer Gruppe Werte mit den fünf Attributen, dann Angriffskraft, Schaden, Zauberschaden und Rüstung,
- einer Gruppe Widerstände, die nur die Widerstände auflistet, die nicht null sind.

Alle Zeilen sind live und aktualisieren sich, wenn sich der Begleiter ändert. Eine Schaltfläche Schließen ist der letzte Haltepunkt des Inhalts.

## Währung (Mists und WoW: Forever)

Ein Haltepunkt mit der Liste der Währungen. Kopfzeilen lesen „Ausgeklappt“ oder „Eingeklappt“ und klappen mit Eingabe zu oder auf. Eine Währung liest ihren Namen und deine Menge: „Gerechtigkeitspunkte 2150“. Leertaste liest den Tooltip der Währung mit Obergrenze und Beschreibung.

In WoW: Forever liest eine Währungszeile außerdem „ausgewählt“, wenn sie gewählt ist. Die gewählte Währung hat einen Haltepunkt Details mit zwei Kontrollkästchen, eines, das die Währung als unbenutzt markiert (sie wandert aus der Hauptliste), und eines, das sie in deiner Rucksackleiste anzeigt, dazu eine Übertragen-Schaltfläche für Währungen, die du zwischen deinen Charakteren verschieben kannst. Die Kontrollkästchen lesen mit den eigenen Worten des Spiels.

## Statistiken (nur WoW: Forever)

Ein Haltepunkt mit der Statistikliste, so wie das Erfolgsfenster sie zeigt. Kategorieköpfe klappen mit Eingabe zu und auf. Eine Statistik liest ihren Namen und ihren Wert: „Tode insgesamt 14“.

## Was WowVision noch nicht liest

- Mists: den Reiter Begleiter des Charakterfensters, den Ausrüstungsmanager und die Titelliste.
- WoW: Forever: die Titelliste der Seitenleiste.
- Classic Era und Retail: das gesamte Charakterfenster.

Gegenstände aufnehmen, anlegen und vergleichen kannst du über [Taschen und Bank](bags-and-bank.md), und die Tooltips angelegter Gegenstände liest du hier mit der Leertaste.
