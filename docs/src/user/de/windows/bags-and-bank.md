# Taschen und Bank

WowVision liest deine Taschen und deine Bank als Listen von Plätzen, durch die du dich bewegen kannst und aus denen du mit der Tastatur Dinge aufnehmen, benutzen, verkaufen und umordnen kannst. Diese Seite erklärt, wie das Taschenfenster in jeder Spielversion aufgebaut ist, was ein Platz sagt und wie du Gegenstände mit dem Cursor verschiebst, benutzt und zerstörst.

## Deine Taschen öffnen

Öffne deine Taschen mit den Tasten des Spiels, genau wie ein sehender Spieler (B für alle Taschen oder die Rucksacktaste). Sobald irgendeine Tasche offen ist, erscheint in WowVision das Taschenfenster.

Das Taschenfenster ist ein Hintergrundfenster. Es öffnet sich auch von selbst neben einem Händler, dem Briefkasten, der Bank oder einem Handel, weil das Spiel dort deine Taschen öffnet. Der Händler, der Briefkasten oder die Bank behält den Fokus. Mit Strg+Tab wechselst du zu den Taschen und mit Strg+Tab wieder zurück. Siehe [Die Oberfläche bedienen](../basics/interface.md).

Schließe die Taschen so, wie es das Spiel tut: Drücke die Taschentaste noch einmal.

Ist das Addon Sku geladen, überlässt WowVision die Taschen Sku und liest sie nicht.

## Form der Tasche: Raster oder Liste

Die Einstellung Taschenform (Bag Shape; Fenster, dann Behälter) legt fest, wie die Plätze einer Tasche gelesen werden.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Taschenform | Liste | Liste liest die Plätze einer Tasche als eine senkrechte Liste in Platzreihenfolge, Platz 1 zuerst. Pfeil hoch und Pfeil runter bewegen dich durch sie. Raster liest sie als die Zeilen, die das Spiel zeichnet: Pfeil links und Pfeil rechts bewegen dich entlang einer Zeile, Pfeil hoch und Pfeil runter zwischen den Zeilen. |

In der Rasterform folgen Pfeil hoch und Pfeil runter der Position in der Zeile, nicht der Bildschirmspalte. Bei manchen Taschen sitzt oben eine kurze Zeile, nach rechts geschoben. Von der ersten Zelle dieser kurzen Zeile landet Pfeil runter auf der ersten Zelle der Zeile darunter, sodass du beim Lesen von oben links nach unten nie etwas überspringst.

Pos1 und Ende springen zum ersten oder letzten Platz (im Raster der aktuellen Zeile). Ändere die Einstellung im WowVision-Menü. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

## Was ein Platz sagt

Ein leerer Platz sagt „Leer“. Ein Platz mit einem Gegenstand sagt den Namen des Gegenstands, gefolgt von seiner Qualitätsfarbe als Wort und der Stapelgröße.

- Classic Era, TBC und Mists: „Leinenstoff, Weiß 12“, „Schwerer Lederball, Weiß“.
- Retail und WoW: Forever: „Leinenstoff, Weiß, 12“. Nach der Anzahl kann der Platz Questgegenstand, Neu, Gesperrt (der Gegenstand ist in Benutzung, zum Beispiel auf dem Cursor) und Gefiltert (der Platz passt nicht zur Taschensuche) ergänzen. Solange das Spiel den Namen eines Gegenstands noch nicht geschickt hat, sagt der Platz Lädt.

Das Farbwort folgt den Qualitätsfarben des Spiels: Grau (schlecht), Weiß (gewöhnlich), Grün (ungewöhnlich), Blau (selten), Violett (episch), Orange (legendär), Hellgold (Artefakt), Hellblau (Erbstück). Einzelne Farben kannst du in den Tooltip-Einstellungen unter Qualität ausschalten. Siehe [Tooltips](../basics/tooltips.md).

Die Beschriftung des Platzes ist live. Nimmst du einen Gegenstand auf, sagt der Platz, auf dem du stehst, sofort „Leer“. Legst du einen hinein, nennt er den neuen Gegenstand.

Drücke die Leertaste für den vollständigen Tooltip des Gegenstands.

## Was du mit einem Platz tun kannst

| Taste | Was sie tut |
|-------|-------------|
| Eingabe | Linksklick. Mit leerem Cursor nimmt er den Gegenstand auf. Mit einem Gegenstand auf dem Cursor legt er ihn im Platz ab (und tauscht, wenn der Platz belegt ist). |
| Rücktaste | Rechtsklick. Er benutzt, legt an, öffnet oder verschiebt den Gegenstand, je nachdem, was offen ist (siehe unten). |
| \\ oder Strg+D (Ziehen) | Nimmt den Gegenstand auf deinen Cursor, wie beim Ziehen mit der Maus. |
| Entf oder Alt+Strg+\\ (Cursorgegenstand zerstören) | Zerstört den Gegenstand auf deinem Cursor, nach einer Rückfrage. Das funktioniert überall im Spiel, nicht nur in den Taschen. |
| Umschalt+F10 | Das Kontextmenü des Platzes. Es führt Linksklick, Rechtsklick und Ziehen auf und sagt, was jeder Klick gerade bewirkt. |

(\\ liegt auf deutschen Tastaturen auf Alt Gr+ß; belege die Aktion bei Bedarf um.)

Das Kontextmenü ist der schnellste Weg herauszufinden, was die Rücktaste tun wird. Jeder Klick-Eintrag ist nach seiner Wirkung benannt, zum Beispiel „Verkaufen, Rechtsklick“ oder „Anlegen, Rechtsklick“.

### Was ein Rechtsklick bewirkt

Das entscheidet das Spiel danach, welche Fenster offen sind. In der Reihenfolge, in der WowVision prüft:

| Situation | Rechtsklick auf einen Taschengegenstand sagt |
|-----------|----------------------------------------------|
| Ein Händler ist offen | Verkaufen (nicht angeboten bei Gegenständen ohne Händlerwert). |
| Der Gegenstand liegt in der Bank | In die Taschen legen. |
| Die Bank ist offen | In die Bank legen. |
| Der Reiter zum Senden von Post ist offen | An Post anhängen. |
| Ein Handel ist offen | Zum Handel hinzufügen. |
| Das Auktionshaus ist offen | Zur Auktion anbieten. |
| Der Gegenstand ist ein Behälter, den du öffnen kannst | Öffnen. |
| Der Gegenstand ist anlegbar | Anlegen. |
| Der Gegenstand ist lesbar | Lesen. |
| Der Gegenstand hat einen Benutzungseffekt | Benutzen. |

Der Linksklick-Eintrag sagt Aufnehmen, oder Gegenstand ablegen, solange du etwas hältst.

### Einen Stapel teilen

Um einen Stapel zu teilen, drücke Umschalt+Eingabe auf dem Platz. Das Spiel öffnet ein kleines Feld, das fragt, wie viele Gegenstände du nehmen willst; WowVision liest es nicht vor. Tippe die Menge, drücke Eingabe und lege den neuen Stapel mit Eingabe auf einem leeren Platz ab.

## Der Cursor

WoW bewegt Dinge mit einem Cursor. Du nimmst etwas auf, und das Spiel hält es auf dem Cursor, bis du es ablegst. WowVision sagt keine eigene Meldung, wenn etwas auf dem Cursor landet. Prüfe stattdessen den Platz, von dem du es genommen hast: Er sagt jetzt „Leer“.

- Um einen Gegenstand zu verschieben, nimmst du ihn auf (Eingabe oder \\), gehst zu einem anderen Platz und drückst dort Eingabe.
- Um einen Gegenstand in eine Tasche zu legen, nimmst du ihn auf und drückst dann Eingabe auf dem Taschenplatz-Eintrag (siehe „Taschenplätze“ unten) oder auf einem freien Platz dieser Tasche.
- Gegenstände auf dem Cursor benutzt du auch mit anderen Fenstern. Du kannst einen auf einen Handelsplatz, einen Postanhang oder einen Händler legen, um ihn zu verkaufen. Siehe [Beute, Handel und Post](./loot-trade-mail.md) und [Mit NPCs sprechen](./npcs.md).
- Ein Gegenstand aus einer Tasche, von einem Handelsplatz oder von einem Händler ist ein echter Gegenstand. Ein Zauber, ein Makro oder eine andere Verknüpfung von einer [Aktionsleiste](./action-bars.md) ist nur ein Verweis.

### Einen Gegenstand zerstören

Du musst den Gegenstand zuerst aufnehmen. Das ist Absicht und entspricht dem Spiel, in dem du einen Gegenstand wegziehst, um ihn zu zerstören. Außerdem schützt es dich davor, das Falsche zu löschen.

Beispiel: ein Zerbrochenes Schwert zerstören.

1. Gehe in deinen Taschen zu seinem Platz.
2. Drücke Eingabe (oder \\), um es aufzunehmen.
3. Drücke Entf.
4. Das Bestätigungs-Popup des Spiels öffnet sich, und WowVision liest es vor. Siehe [Menüs, Optionen und Dialoge](./system.md#popups-und-bestätigungsdialoge). Bei gewöhnlichen Gegenständen hat das Popup einen Text und zwei Schaltflächen: Lies den Text, gehe mit Tab zur bestätigenden Schaltfläche und drücke Eingabe. Bei Gegenständen von seltener Qualität oder besser (Erbstücke ausgenommen) musst du eventuell zusätzlich das Wort LÖSCHEN (im englischen Client DELETE) in ein Textfeld eingeben, bevor die Bestätigungsschaltfläche funktioniert.
5. Mit Esc oder der Abbrechen-Schaltfläche bleibt der Gegenstand auf deinem Cursor. Lege ihn mit Eingabe wieder in einem Platz ab.

Drückst du Entf, während nichts auf deinem Cursor liegt, passiert nichts.

## Taschen in Classic Era, TBC und Mists

Jede offene Tasche ist ein eigener Tabstopp, in dieser Reihenfolge: Rucksack, dann Taschen 1 bis 4. Mit Tab und Umschalt+Tab wechselst du zwischen den Taschen, mit den Pfeiltasten bewegst du dich innerhalb einer Tasche.

- Die Tasche wird mit ihrem Namen angesagt, zum Beispiel „Rucksack“ oder „Rucksack des Gesellen“. Banktaschen werden als „Bank: “ und ihr Name angesagt.
- Der erste Eintrag einer Tasche ist ihr Taschenplatz: „Taschenplatz Rucksack“. Das ist die Schaltfläche, auf die du eine neue Tasche legst, und von hier aus kannst du die Tasche aufnehmen. Danach folgen die Gegenstandsplätze.
- Die Schaltflächen der Taschenplätze liegen im eigenen Stopp jeder Tasche. Du erreichst sie also nur, solange diese Tasche offen ist.

Der Schlüsselbund (Classic Era und The Burning Crusade) wird nicht gelesen.

WowVision liest in diesen Versionen keine Sortierschaltfläche, auch wenn das Spiel eine zeichnet. Ordne Gegenstände von Hand oder nutze die Sortierfunktion, die deine Spielversion bietet.

### Die Bank in Classic Era, TBC und Mists

Gehe zu einem Bankier und öffne die Bank. Das Bankfenster liest:

1. Einen Stopp namens Bank mit den eigenen Gegenstandsplätzen der Bank.
2. Einen Stopp namens Banktaschenplätze (Bank Bag Slots) mit den Banktaschenplätzen, die du besitzt. Jeder liest den Namen der Tasche oder „Leer“, gefolgt von der Beschreibung des Platzes durch das Spiel. Lege mit Eingabe eine Tasche in einen Platz, wie bei deinen eigenen Taschenplätzen. Unterhalb der Plätze, die du besitzt, liest WowVision, wenn du einen weiteren kaufen kannst, den Kauftext, „Kosten“ und den Preis sowie eine Kaufschaltfläche. Drücke Eingabe auf der Schaltfläche, um zu kaufen.
3. Jede offene Banktasche erscheint als eigener Stopp mit dem Namen „Bank: “ und dem Taschennamen.

Um Gegenstände zwischen deinen Taschen und der Bank zu verschieben, öffnest du beides, nimmst einen Gegenstand auf und drückst Eingabe auf einem freien Platz der anderen Seite. Oder du benutzt die Rücktaste auf dem Gegenstand. Bei geöffneter Bank legt ein Rechtsklick auf einen Taschengegenstand ihn in die Bank, und ein Rechtsklick auf einen Bankgegenstand legt ihn in deine Taschen.

## Taschen in Retail und WoW: Forever

(Nur Retail und WoW: Forever.)

Diese Versionen haben zwei Taschenansichten, die du im Taschenmenü des Spiels wählst. WowVision folgt dem, was das Spiel zeigt.

### Zusammengefasste Taschen

Alle deine Taschen werden als ein großes Raster gezeichnet, und WowVision liest es genauso: zuerst der Rucksack, dann die anderen Taschen, ohne Taschengrenzen. Das Fenster öffnet sich auf dem Stopp Taschen. Die Stopps sind:

1. Taschensteuerung (Bag Controls): Taschenmenü (Bag Menu), ein Dropdown mit einem Untermenü pro Tasche (Filter, Aufräumen, Taschenansicht wechseln); Taschen sortieren; Geld, das dein Gold liest, zum Beispiel „Geld, 12 Gold 5 Silber“; und Plätze hinzufügen, wenn das Spiel das anbietet.
2. Suchen (Search): ein Textfeld. Gehe mit Tab hinein und tippe, und Plätze, die nicht passen, lesen Gefiltert. Mit Tab verlässt du das Feld.
3. Taschen (Bags): die Plätze in der Form, die du gewählt hast (ein Raster ist zehn Plätze breit, die erste Zeile kann kürzer sein). In der Listenform stehen die Plätze in Platzreihenfolge, der Rucksack zuerst.
4. Taschenplätze (Bag Slots): eine Zeile mit den Taschenplatz-Schaltflächen des Rucksacks und deiner vier Taschen. Jede liest „Taschenplatz“ und den Namen der Tasche. Die Reagenzientasche und, in WoW: Forever, der Schlüsselbund zeichnet das Spiel auch in der zusammengefassten Ansicht als eigene Rahmen. Sie stehen nicht in dieser Zeile. Jede bekommt einen eigenen Stopp, mit ihrem Taschenplatz zuerst, wie in der Einzelansicht weiter unten.

Ein Rucksack eines Accounts ohne Authenticator zeigt vier zusätzliche Plätze, die nichts aufnehmen können. WowVision liest diese nicht als Plätze. Die Schaltfläche Plätze hinzufügen bleibt in der Taschensteuerung.

Beispiel: deinen Ruhestein mit der Suche finden.

1. Öffne die Taschen mit B. Drücke Strg+Tab, wenn du in einem anderen Fenster bist.
2. Das Fenster öffnet sich auf Taschen. Drücke einmal Umschalt+Tab, um „Suchen“ zu erreichen.
3. Tippe `ruhe`. Die Plätze, die nicht passen, lesen jetzt Gefiltert.
4. Gehe mit Tab zum Stopp Taschen und lies die Plätze mit Pfeil runter.

### Einzelne Taschen

Jede Tasche ist ein eigenes Fenster, wie in Classic. Jede offene Tasche ist ein Stopp, der mit dem Namen der Tasche angesagt wird. Die Rucksacktaste allein öffnet nur den Rucksack. Die Taste Alle Taschen öffnen (Open All Bags) des Spiels (standardmäßig Umschalt zusammen mit der Rucksacktaste) öffnet alles.

- Der erste Eintrag ist der Taschenplatz: „Taschenplatz“ und der Taschenname. Beide Klicks darauf sagen Tasche schließen, oder Gegenstand ablegen, solange du eine Tasche hältst. Das eigene Menü der Tasche (Filter, Aufräumen, Taschenansicht wechseln) liegt im Kontextmenü des Platzes, als Taschenmenü.
- Taschen sortieren, Geld und Plätze hinzufügen gehören zum Rucksack. Sie erscheinen vor den Taschen in einem Stopp namens Taschensteuerung, gefolgt vom Stopp Suchen. Das Fenster öffnet sich auf der ersten Tasche.

## Bank in Retail und WoW: Forever

(Nur Retail und WoW: Forever.)

Die moderne Bank ist ein einziges Fenster, das die Charakterbank und die Kriegsmeutebank (Warband, accountweit) zeigt. Ein Bankier öffnet sie. Die Stopps sind:

1. Bankreiter (Bank Tabs): eine Zeile mit den Reitern. Das sind die Reiter für die Bankart (Charakter- und Kriegsmeutebank, vom Spiel benannt), die Seitenreiter in WoW: Forever, die seitlichen Reiter für jeden Bankreiter in Retail (Eingabe wählt aus, Rücktaste öffnet in Retail seine Einstellungen) und der Kaufreiter. Der aktuelle sagt „ausgewählt“.
2. Ein Stopp pro Bankreiter: seine Plätze, benannt nach dem Namen des Reiters. In WoW: Forever werden alle gekauften Reiter der aktuellen Bankart auf einmal gezeigt, auf Seiten.
3. Banktaschenplätze (WoW: Forever): eine Zeile mit den Banktaschenplatz-Schaltflächen, die du mit der Taste für Ziehen aufnehmen kannst.
4. Suchen: ein Textfeld.
5. Banksteuerung (Bank Controls): Bank sortieren, Geld (in der Kriegsmeutebank ist das das eingezahlte Gold, mit den Einzahlen- und Abheben-Schaltflächen des Spiels) sowie der Preis und die Kaufschaltfläche für den nächsten Reiter oder die nächste Tasche.

Eine gesperrte oder noch nicht gekaufte Bank zeigt statt der Plätze die Erklärung des Spiels. Sie wird als Text unter dem Namen „Bank“ gelesen.

Plätze lesen sich wie Taschenplätze. Ein Rechtsklick verschiebt einen Gegenstand zwischen Taschen und Bank, wie in Classic: In die Bank legen und In die Taschen legen.

Beispiel: einen Gegenstand in deine Kriegsmeutebank legen (Retail).

1. Öffne die Bank. Drücke Tab bis zur Reiterzeile und Pfeil rechts bis zum Reiter der Kriegsmeutebank. Drücke Eingabe.
2. Drücke Strg+Tab zu deinen Taschen, suche den Gegenstand und drücke Eingabe, um ihn aufzunehmen.
3. Gehe mit Strg+Tab zurück, gehe zu einem freien Platz in der Kriegsmeutebank und drücke Eingabe, um den Gegenstand dort abzulegen.

## Einstellungen

Die Taschen und die Bank haben eine Einstellung, Taschenform, die oben beschrieben ist. Wie jedes Fenster haben die Taschen einen Schalter Aktiviert im WowVision-Menü, unter Fenster, dann Behälter. Sie haben keine Alarme und keine eigenen Tastenbelegungen. Die Tasten auf dieser Seite sind die gemeinsamen Fenstertasten, die du im Fenster für die Tastenbelegung ändern kannst. Siehe [Tastenbelegung](../basics/keybindings.md).

## Fehlerbehebung

- Nichts passiert, wenn ich Entf drücke. Entf zerstört nur, was auf dem Cursor liegt. Nimm den Gegenstand zuerst auf.
- Ich finde die Taschen nicht. Sie sind ein Hintergrundfenster. Drücke Strg+Tab, um durch die Fenster zu wechseln.
- Die Platzreihenfolge scheint rückwärts zu sein. Stelle sicher, dass Taschenform auf Liste steht, wenn du die Platzreihenfolge willst. Im Raster folgen die Zeilen dem Bildschirm.
