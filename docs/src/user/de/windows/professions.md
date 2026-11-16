# Berufe

Diese Seite behandelt alles, womit du Gegenstände herstellst und verbesserst: die Berufsfenster, in denen du handwerkst, das Fenster für Verzauberkunst und Tierausbildung, das Sockeln von Edelsteinen, das Umschmieden und die Gegenstandsaufwertung. WowVision liest jedes Fenster als Liste von Haltepunkten, die du mit Tab und den Pfeiltasten durchgehst.

Beschriftungen, die das Spiel selbst liefert, hörst du in der Sprache deines Spielclients. Wo hier ein englischer Name steht, ist das die Bezeichnung aus dem englischen Client.

## Wo es verfügbar ist

| Fenster | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Berufsfenster (Herstellen) | Nein | Ja | Ja | Nein | Ersetzt durch die Herstellungsseite |
| Handwerksfenster (Verzauberkunst, Tierausbildung) | Nein | Ja | Nein | Nein | Nein |
| Edelsteine sockeln | Nein | Ja | Ja | Nein | Nein |
| Umschmieden | Nein | Nein | Ja | Nein | Nein |
| Gegenstandsaufwertung | Nein | Nein | Ja | Nein | Nein |
| Berufebuch und Herstellungsseite | Nein | Nein | Nein | Nein | Ja |

„Nein“ heißt, WowVision liest es noch nicht. Bei den wichtigsten Berufsfenstern und den Fenstern zur Gegenstandsverbesserung kannst du das Vorlesen mit dem Schalter Aktiviert im WowVision-Menü (Umschalt+F1, dann Fenster, dann der Name des Fensters: Beruf, Handwerk, Sockelung, Umschmieden, Gegenstandsaufwertung oder Berufe) aus- oder einschalten. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

Ist das Addon Sku geladen, liest WowVision weder die TBC-Fenster für Beruf und Handwerk noch die Fenster für Umschmieden und Gegenstandsaufwertung.

## Ein Berufsfenster öffnen

Die Berufsfenster öffnen sich, wenn du den Beruf selbst benutzt:

- In TBC und Mists drückst du Eingabe auf der Zauberschaltfläche des Berufs (im Mists-Zauberbuch auf dem Reiter Berufe, siehe [Zauber und Talente](spells-and-talents.md)), wirkst ihn von einer Aktionsleiste oder mit einem Makro wie `/cast Schneiderei`.
- In WoW: Forever drückst du die Berufetaste des Spiels, um das Berufebuch zu öffnen, und dann Eingabe auf dem Zauber des Berufs. Siehe unten.

Esc schließt jedes dieser Fenster.

## Das Berufsfenster (TBC und Mists)

Wird von jedem Herstellungsberuf benutzt, außer Verzauberkunst und Tierausbildung. Das Fenster ist nach dem Beruf benannt („Schneiderei“, „Erste Hilfe“), und der Bildschirm wird als Kette von Haltepunkten gelesen:

1. Nur TBC: Material vorhanden (Have Materials), ein Kontrollkästchen, das Rezepte ausblendet, die du gerade nicht herstellen kannst.
2. TBC: die Dropdowns Subclass und Inventory Slot. Mists: ein Dropdown Filter. Sie grenzen die Liste nach Kategorie oder Platz ein. Eingabe öffnet das Menü des Spiels.
3. Suchen, ein Eingabefeld. Das Tippen grenzt die Rezeptliste ein.
4. Rezepte, die Liste. Wenn sich das Fenster öffnet, landest du hier.
5. Details des ausgewählten Rezepts.
6. Menge, ein Eingabefeld, das enthält, wie viele du herstellen willst.
7. Die Schaltflächen Herstellen (Create) und Alle herstellen (Create All), jede ein Haltepunkt.

### Die Rezeptliste

Kategorieköpfe lesen ihren Namen und „Ausgeklappt“ oder „Eingeklappt“ und klappen mit Eingabe zu und auf. Ein Rezept liest seinen Namen, wie viele du mit dem herstellen kannst, was du dabeihast, und seine Schwierigkeit als Farbwort:

- „Leinenverband 12 (Orange)“: 12 können hergestellt werden; Orange heißt, dass sich das Herstellen für die Fertigkeit noch lohnt.
- Die Farben sind Orange (optimal), Gelb (mittel), Grün (leicht) und Grau (trivial).
- Kannst du keines herstellen, wird keine Anzahl gesprochen.

Eingabe auf einem Rezept wählt es aus („ausgewählt“) und füllt die Details. Leertaste auf einem Rezept liest seinen Tooltip.

### Die Details

Ein Haltepunkt, Details:

1. Der Rezeptname (die Symbolschaltfläche). Leertaste liest den Tooltip des Gegenstands, den es herstellt.
2. Die Beschreibung, falls es eine gibt.
3. Die Voraussetzung („Benötigt: Amboss“), falls es eine gibt.
4. Eine Gruppe, benannt nach der Reagenzienbeschriftung des Spiels („Reagenzien:“), mit einer Zeile pro Reagenz: sein Name und wie viele du hast und brauchst. Die Anzahl wird gelesen, wie das Spiel sie zeichnet: „Leinenstoff 12 /1“.

Gehe die Zeilen mit Pfeil hoch und Pfeil runter durch. Leertaste auf einer Reagenz liest ihren Tooltip.

### Gegenstände herstellen

Nachdem du ein Rezept ausgewählt hast:

- Gehe mit Tab zu Menge. Sie beginnt bei 1. Tippe eine Zahl, drücke Tab.
- Herstellen stellt so viele des ausgewählten Rezepts her. Alle herstellen stellt so viele her, wie dein Material erlaubt.
- Eine Schaltfläche, die nicht benutzt werden kann, liest „Deaktiviert“.
- Das Spiel stellt die Gegenstände dann mit seiner normalen Zauberleiste her.

### Beispiel: 5 Leinenverbände herstellen (TBC, Mists)

1. Öffne das Fenster für Erste Hilfe: Drücke P für das Zauberbuch, gehe in Mists zum Reiter Berufe (in TBC zum Seitenreiter Allgemein), suche „Erste Hilfe“ und drücke Eingabe.
2. Du landest auf Rezepte. Drücke einmal Umschalt+Tab, um Suchen zu erreichen, tippe „Leinen“ und drücke Tab. Du bist wieder auf Rezepte, und die Liste enthält jetzt nur noch passende Rezepte.
3. Gehe mit Pfeil runter zu „Leinenverband 12 (Grün)“. Drücke Eingabe: „ausgewählt“.
4. Drücke Tab zu Details. Pfeil runter liest die Beschreibung und die Reagenzien, „Leinenstoff 12 /1“, sodass du weißt, dass du genug hast.
5. Drücke Tab zu Menge, tippe 5, drücke Tab.
6. Drücke auf Herstellen Eingabe. Das Spiel stellt fünf Verbände her.

## Das Handwerksfenster (nur TBC)

Verzauberkunst und die Tierausbildung der Jäger benutzen einen älteren Zwilling des Berufsfensters, Handwerk genannt. Es öffnet sich auf dieselbe Weise: Benutze den Zauber Verzauberkunst oder die Fähigkeit Tierausbildung des Jägers.

Die Haltepunkte:

1. Die Fertigkeitsleiste: „Verzauberkunst 300/375“. Wird nicht von jedem Handwerk gezeigt.
2. Trainingspunkte mit den Punkten deines Begleiters, nur für die Tierausbildung.
3. Material vorhanden, ein Kontrollkästchen (wird bei der Tierausbildung nicht gezeigt).
4. Filter-Dropdown Slot, für Verzauberkunst.
5. Rezepte, die Liste, auf der sich das Fenster öffnet. Jeder Eintrag liest seinen Namen, seinen Rang oder Untertext, wie viele du herstellen kannst, seine Schwierigkeitsfarbe und bei der Tierausbildung seine Kosten in Trainingspunkten. Ein Verzauberungseintrag liest sich etwa so: „Armschiene verzaubern - Kraft 3 (Gelb)“.
6. Details: das Handwerkssymbol (Name und Anzahl), die Voraussetzungen, die Kosten, die Abklingzeit, die Beschreibung und eine Gruppe Reagenzien wie beim Berufsfenster.
7. Verzaubern (bei der Tierausbildung Trainieren) und Schließen.

### Beispiel: Eine Armschiene in TBC verzaubern

1. Öffne das Verzauberkunst-Fenster. Gehe mit Tab zu Rezepte, wähle „Armschiene verzaubern - Kraft“, Eingabe.
2. Gehe mit Tab zu Details und lies die Reagenzien.
3. Gehe mit Tab zur Schaltfläche Verzaubern und drücke Eingabe.
4. Das Spiel verlangt jetzt, dass du den Gegenstand wählst. Öffne dein Charakterfenster (C) und drücke Eingabe auf dem Armschienenplatz, oder öffne deine Taschen und drücke Eingabe auf der Armschiene. Die Verzauberung wird angewendet, und das Spiel zeigt seine eigene Bestätigung.

### Beispiel: Eine Begleiterfähigkeit trainieren (Jäger, TBC)

1. Wirke Tierausbildung. Du hörst das Fenster Handwerk.
2. Gehe mit Tab zu Rezepte und mit den Pfeiltasten zur gewünschten Fähigkeit. Ihre Kosten in Trainingspunkten sind Teil der Zeile.
3. Prüfe Trainingspunkte und gehe mit Tab zu Trainieren. Eingabe.

## Edelsteine sockeln (TBC und Mists)

Das Sockelfenster öffnet sich, wenn du einen Gegenstand mit Edelsteinplätzen benutzt, den du bei dir trägst oder angelegt hast (Rechtsklick darauf: Rücktaste auf dem Gegenstand in deinen Taschen oder im Charakterfenster).

Das Fenster hat drei Haltepunkte:

- Sockelung: ein Eintrag pro Sockel, der seine Farbe und den Edelstein liest: „Rot: Zarter Lebensrubin“ oder „Blau: Leer“. Hast du einen neuen Edelstein eingesetzt, aber noch nicht angewendet, zeigt die Zeile den neuen Edelstein. Spezialsockel lesen das eigene Farbwort des Spiels, wo es eines gibt (Meta, und in Mists Zahnrad- und Sha-Sockel).
- Apply, die Sockelschaltfläche des Spiels. Am Gegenstand ändert sich nichts, bevor du sie drückst.
- Schließen.

### Beispiel: Einen Edelstein sockeln

1. Öffne deine Taschen ([Taschen und Bank](bags-and-bank.md)) und drücke Rücktaste auf dem Gegenstand, den du sockeln willst. Das Sockelfenster öffnet sich.
2. Drücke Strg+Tab, um zum Taschenfenster zurückzukehren, gehe mit den Pfeiltasten zum Edelstein und drücke Eingabe. Der Edelstein hängt an deinem Cursor.
3. Drücke Strg+Tab, um zum Sockelfenster zurückzukehren. Gehe in Sockelung zu „Rot: Leer“ und drücke Eingabe. Die Zeile liest jetzt den neuen Edelstein.
4. Gehe mit Tab zu Apply und drücke Eingabe. Das Spiel bittet dich eventuell, in einem Popup zu bestätigen, zum Beispiel wenn ein Edelstein einen anderen ersetzt.

Die Ziehen-Taste (\\ oder Strg+D; \\ liegt auf deutschen Tastaturen auf Alt Gr+ß, belege die Aktion bei Bedarf um) führt bei einem Sockel die eigene Ziehen-Aktion des Spiels für diesen Sockel aus.

## Umschmieden (nur Mists)

Öffnet sich, wenn du mit einem Umschmied in einer Hauptstadt sprichst. Du wählst einen Gegenstand, dann einen Wert, der sinken soll, und einen, der steigen soll. Die Haltepunkte in dieser Reihenfolge:

1. Gegenstand: der Gegenstandsplatz. Er liest den Gegenstandsnamen oder den Text des Spiels, der dich bittet, einen Gegenstand einzulegen (Eingabe mit einem Gegenstand am Cursor legt ihn ein; die Ziehen-Taste nimmt ihn heraus).
2. Die linke Wertespalte: Ihr Titel ist die Überschrift des Spiels, und jeder Wert ist ein Kontrollkästchen mit dem Text des Werts. Eingabe wählt den Wert, der sinken soll.
3. Die rechte Wertespalte: die Werte, in die du umschmieden kannst. Eingabe wählt den Wert, den du gewinnst.
4. Eine Zeile mit der Wiederherstellen-Meldung, wenn der Gegenstand schon umgeschmiedet wurde.
5. Die Kosten in Gold, Silber und Kupfer, wenn es welche gibt.
6. Die Schaltflächen Umschmieden und Wiederherstellen, jede ein Haltepunkt.

Alles ist live: Wenn du einen Gegenstand einlegst, schreiben sich die Wertespalten neu.

### Beispiel: Deinen Helm umschmieden

1. Sprich mit dem Umschmied. Das Fenster öffnet sich auf Gegenstand.
2. Drücke Strg+Tab zu deinen Taschen, Eingabe auf dem Helm, um ihn aufzunehmen, Strg+Tab zurück zum Umschmiedefenster und Eingabe auf Gegenstand, um ihn einzulegen.
3. Gehe mit Tab zur linken Spalte und wähle den Wert, den du aufgibst, Eingabe.
4. Gehe mit Tab zur rechten Spalte und wähle den Wert, den du gewinnst, Eingabe.
5. Prüfe die Kosten, gehe mit Tab zu Umschmieden, Eingabe.

## Gegenstandsaufwertung (nur Mists)

Öffnet sich beim Händler für Gegenstandsaufwertung. Die Haltepunkte:

1. Gegenstand: der Platz. Er liest den Gegenstandsnamen oder den Text des Spiels, der nach einem Gegenstand fragt. Eingabe mit einem Gegenstand am Cursor legt ihn ein.
2. Die Zeile mit dem Aufwertungsstatus (auf welcher Aufwertungsstufe du bist), wenn das Spiel sie zeigt.
3. Die linke Spalte (der aktuelle Gegenstand) und die rechte Spalte (der aufgewertete Gegenstand), jede ein eigener Haltepunkt, benannt nach der Überschrift des Spiels. Jede beginnt mit der Gegenstandsstufe („Gegenstandsstufe 463“), gefolgt von einer Zeile pro Wert: sein Name, sein Wert und in der aufgewerteten Spalte die Steigerung.
4. Upgrade, die Schaltfläche. Sie liest die Kosten mit: „Upgrade Tapferkeitspunkte 250“.

## WoW: Forever: Berufe

Forever ersetzt die alten Fenster durch das moderne Berufefenster. WowVision liest seine zwei Seiten.

### Das Berufebuch

Drücke die Berufetaste des Spiels. Der Bildschirm heißt Berufe und hat einen Haltepunkt für jede Berufskarte: zuerst die zwei Hauptberufe, dann Kochen, Angeln und Erste Hilfe.

- Ein gelernter Beruf liest seinen Namen (mit seiner Spezialisierung) als Überschrift, dann: die Rangzeile, seine Zauber und bei den Hauptberufen Verlernen.
- Die Zauber sind Schaltflächen, zum Beispiel das Herstellungsfenster des Berufs oder Fähigkeiten wie Kräuter aufspüren und Mineralien aufspüren. Eingabe wirkt den Zauber, und beim Herstellungszauber öffnet das die Herstellungsseite. Die Rücktaste tut hier nichts. Die Ziehen-Taste nimmt den Zauber für eine Aktionsleiste auf. Leertaste liest den Zauber-Tooltip.
- Ein leerer Platz liest die Überschrift und den Hinweis des Spiels, zum Beispiel wie man einen Beruf lernt.

Die Seitenreiter des Fensters werden nicht gelesen: Benutze den Zauber des Berufs, um seine Herstellungsseite zu öffnen.

### Die Herstellungsseite

Wenn du den Zauber eines Berufs öffnest, erscheint die Herstellungsseite, benannt nach dem Beruf. Die Haltepunkte:

1. Reiter: ein Reiter pro Beruf, der ein Herstellungsfenster hat. Eingabe auf einem Reiter wirkt den Zauber dieses Berufs und wechselt zu ihm. Der Beruf, in dem du bist, liest „ausgewählt“ und tut bei Eingabe nichts.
2. Beruf (ein Haltepunkt): die Rangzeile, ein Link-Menü (verlinkt den Beruf im Chat) und deine Berufswerkzeug-Plätze. Ein Werkzeugplatz liest den Gegenstandsnamen oder „Leer“. Eingabe nimmt den Gegenstand auf oder legt den Gegenstand an deinem Cursor ab, wie im Charakterfenster.
3. Filter, ein Dropdown-Menü.
4. Suchen, das Eingabefeld. Tippe, um die Rezepte einzugrenzen.
5. Rezepte, die Liste. Die Seite öffnet sich hier.
6. Details des ausgewählten Rezepts.
7. Menge, ein Eingabefeld.
8. Herstellen, Alle herstellen und View Guild Crafters, wenn sie gezeigt wird. Eine deaktivierte Herstellen-Schaltfläche liest außerdem den Grund des Spiels (was fehlt).

### Die Rezeptliste

- Kategoriezeilen lesen ihren Namen und „Ausgeklappt“ oder „Eingeklappt“. Eingabe klappt sie zu.
- Ein Rezept liest seinen Namen, wie viele du jetzt herstellen kannst und bei gelernten Rezepten ein Farbwort für die Schwierigkeit: „Elixier der Beweglichkeit 3 (Orange)“. Nur Rezepte, die dir noch Fertigkeitspunkte geben, tragen eine Farbe; die anderen lesen „(Grau)“. Ein Rezept, das nicht benutzt werden kann, liest nach einem Komma seinen Grund.
- Rezepte, die du nicht gelernt hast, sind nach einer Trennzeile gruppiert, die den Text „Nicht erlernt“ des Spiels liest.
- Eingabe wählt ein Rezept aus („ausgewählt“). Rücktaste öffnet das Favoritenmenü des Spiels dafür.
- Leertaste liest den Tooltip des Rezepts: den Gegenstand, den es herstellt, die Werkzeuge, die es braucht („Benötigt: Schmiedehammer (Fehlt)“), und die Reagenzien: „Reagenzien:“, dann eine Zeile pro Reagenz in der Form „Friedensblume 3/2“, mit der Zahl, die du hast, zuerst und der benötigten Zahl danach.

### Die Details

Ein Haltepunkt, Details. Er liest den hergestellten Gegenstand mit seiner Anzahl, ein Kontrollkästchen Favorit, den Untertext des Ergebnisses, die Werkzeugzeile, die Abklingzeit, wo ein nicht gelerntes Rezept gelernt wird, einen Bonus für das erste Herstellen, die Beschreibung und die Kontrollkästchen, die das Spiel zeigt (zum Beispiel die besten Reagenzien und das Verfolgen des Rezepts). Die Reagenzien werden hier nicht wiederholt; benutze Leertaste auf dem Rezept oder dem Ergebnisgegenstand.

### Beispiel: 5 Elixiere in WoW: Forever herstellen

1. Drücke die Berufetaste. Gehe mit Tab zur Karte für Alchemie und drücke Eingabe auf ihrem Zauber (zum Beispiel „Alchemie“).
2. Die Herstellungsseite öffnet sich auf Rezepte. Drücke einmal Umschalt+Tab, um Suchen zu erreichen, tippe den Rezeptnamen und gehe mit Tab zurück zu Rezepte.
3. Gehe mit den Pfeiltasten zum Rezept und drücke Eingabe; Leertaste liest, was es braucht: „Friedensblume 3/2“.
4. Gehe mit Tab zu Menge, tippe 5, gehe mit Tab zu Herstellen. Drücke Eingabe.

## Weitere Hinweise

- Einkaufen und Reagenzien kaufen ist unter [Mit NPCs sprechen](npcs.md) beschrieben.
- Um hergestellte Ausrüstung anzulegen oder zwischen Taschen zu verschieben, nutze [Taschen und Bank](bags-and-bank.md).
- Classic Era und Retail haben in WowVision noch keine Berufsfenster.
