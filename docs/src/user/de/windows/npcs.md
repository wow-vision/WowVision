# Mit NPCs sprechen: Gespräche, Händler, Lehrer, Flugmeister und Bücher

Diese Seite behandelt die Fenster, die du triffst, wenn du in der Welt mit einer Figur sprichst: das Gesprächsfenster (Gossip), Händler, Lehrer, Flugmeister, Bücher und Briefe sowie den Stall des Jägers. Alle öffnen sich, wenn das Spiel sie öffnet. Gehe zum NPC und interagiere wie gewohnt, zum Beispiel mit der Interaktionstaste. WowVision liest dann das Fenster und lässt dich darin navigieren.

In all diesen Fenstern wechseln Tab und Umschalt+Tab zwischen den Teilen des Fensters (jeder Teil ist ein „Stopp“), die Pfeiltasten bewegen sich innerhalb eines Teils, Eingabe klickt, die Leertaste liest den Tooltip, wo es einen gibt, und Esc schließt das Fenster. Die Rücktaste macht einen Rechtsklick, was nur dort eine Rolle spielt, wo ein Rechtsklick etwas bewirkt, etwa bei den Waren eines Händlers. Umschalt+F10 öffnet das Kontextmenü des fokussierten Eintrags. Siehe [Die Oberfläche bedienen](../basics/interface.md).

Ist das Addon Sku geladen, überlässt WowVision die Fenster für Gespräche, Händler, Lehrer, Flugmeister und Stall Sku.

## Gespräche

Das Gesprächsfenster ist die Unterhaltung, die du bekommst, wenn du mit den meisten NPCs sprichst. Es listet auf, was der NPC sagt und was du auswählen kannst.

Das Fenster liest von oben. Jeder Eintrag ist ein eigener Stopp, benutze also Tab und Umschalt+Tab, um vom einen zum nächsten zu kommen:

1. Die Begrüßung, der aktuelle Text des NPCs. Der Name des NPCs wird als Titel des Fensters angesagt.
2. Optionen, ein Eintrag für alles, was der NPC anbietet, zum Beispiel „Bildet mich aus“, „Macht dieses Gasthaus zu Eurem Heimatort“ oder „Ich möchte Eure Waren sehen“. Drücke Eingabe, um eine auszuwählen.
3. Einträge Verfügbare Quest: ..., Quests, die du von diesem NPC annehmen kannst, gefolgt vom Questtitel.
4. Einträge Angenommene Quest: ..., Quests, die du schon angenommen hast und die diesen NPC betreffen, zum Beispiel um sie abzugeben.
5. Auf Wiedersehen, was die Unterhaltung beendet.

Wenn du eine Option auswählst, antwortet der NPC, und das Fenster aktualisiert sich. Der neue Text wird dir automatisch von oben vorgelesen, und der Fokus kehrt zur Begrüßung zurück. Solange das Spiel noch an deiner Auswahl arbeitet, zeigt WowVision weiter die alte Seite statt einer halb aktualisierten und springt dann zur neuen Seite, wenn sie fertig ist.

Wählst du einen Questeintrag, öffnet sich das Questfenster. Siehe [Quests](../world/quests.md). Wenn du eine Option wählst, die einen Lehrer, Händler oder Flugmeister öffnet, schließt sich die Unterhaltung, und dieses Fenster öffnet sich.

Beispiel: deinen Ruhestein bei einem Gastwirt festlegen.

1. Interagiere mit dem Gastwirt. Du hörst den Namen des NPCs und die Begrüßung.
2. Drücke Tab, um die Optionen durchzugehen, bis du „Macht dieses Gasthaus zu Eurem Heimatort“ hörst.
3. Drücke Eingabe. Der NPC antwortet, wahrscheinlich mit einem Bestätigungs-Popup. Siehe [Menüs, Optionen und Dialoge](./system.md#popups-und-bestätigungsdialoge).

Nicht gelesen werden: einige Freundschafts- und Sonderrufanzeigen, die das moderne Spiel im Gespräch zeigt.

## Händler

Im Händlerfenster kaufst und verkaufst du und lässt reparieren.

Die Stopps, der Reihe nach:

1. Reiter (Tabs): eine Zeile mit zwei Reitern, den Waren des Händlers und Rückkauf (Buyback). Der, auf dem du bist, sagt „ausgewählt“. Mit Pfeil links und Pfeil rechts gehst du hin und her, mit Eingabe wechselst du.
2. Gegenstände (Items): die Waren, die auf dieser Seite zum Verkauf stehen, oder im Reiter Rückkauf die Gegenstände, die du verkauft hast. Zehn Waren pro Seite; die Rückkaufliste hat bis zu zwölf. Eine leere Seite sagt „Leer“.
3. Vorherige Seite und Nächste Seite: je ein Stopp, nur wenn der Händler mehr als eine Seite hat.
4. Reparieren (Repair; nur bei Händlern, die reparieren): Alles reparieren, Gegenstand reparieren und, wo verfügbar, Gildenbankreparatur. Diese gibt es nur im Händler-Reiter.

### Was ein Gegenstand sagt

Jeder Gegenstand liest seinen Namen und seine Qualitätsfarbe, wie viele du als Stapel bekommst, den Preis, wie viele noch übrig sind und weitere Kosten:

- „Leinenverband, Weiß, 1 Silber 5 Kupfer“
- „Rauer Pfeil, Weiß x 200, 3 Silber, 2 auf Lager“
- „Insignie der Eroberung, Violett, Ehrenpunkte 1200“

Der Preis wird in Gold, Silber und Kupfer angegeben. Ein Stapel wie „x 200“ erscheint nur, wenn der Händler mehr als einen auf einmal verkauft. Gegenstände, die zusätzliche Währungen oder Gegenstände kosten, hängen diese am Ende an, zum Beispiel „Ehrenzeichen 20“ oder den Namen des benötigten Gegenstands. Begrenzte Gegenstände ergänzen „N auf Lager“. Diese Beschriftungen sind live. Beim Umblättern werden dieselben Plätze neu beschrieben, während du darauf stehst.

Drücke die Leertaste für den Tooltip des Gegenstands.

### Kaufen

- Rücktaste (Rechtsklick) auf einem Gegenstand kauft ihn. Ein Stapelgegenstand kauft den ganzen Stapel, den der Händler anbietet, wie im Spiel.
- Eingabe (Linksklick) nimmt den Gegenstand auf deinen Cursor. Du kannst ihn dann auf einen Taschenplatz legen, um ihn dort zu kaufen.
- Um eine bestimmte Menge eines Stapelgegenstands zu kaufen, drücke Umschalt+Eingabe darauf. Das Spiel öffnet ein kleines Feld, das fragt, wie viele du willst: Tippe die Menge und drücke Eingabe. WowVision liest dieses Feld nicht vor.

### Verkaufen

- Öffne deine Taschen (siehe [Taschen und Bank](./bags-and-bank.md)) und drücke die Rücktaste auf einem Gegenstand. Bei geöffnetem Händler verkauft das ihn. Das Kontextmenü des Platzes sagt „Verkaufen, Rechtsklick“, sodass du vor dem Drücken nachsehen kannst.
- Oder nimm den Gegenstand mit Eingabe auf und lege ihn bei den Gegenständen des Händlers ab.
- Gegenstände, die du aus Versehen verkauft hast, kannst du im Reiter Rückkauf zurückkaufen, für den Preis, den du bekommen hast.

### Reparieren

Drücke im Stopp Reparieren auf Alles reparieren die Eingabe, um alles, was du angelegt hast, für den vom Spiel angezeigten Preis zu reparieren (die Kosten stehen im Tooltip der Schaltfläche, den du mit der Leertaste liest). Gegenstand reparieren legt das Reparaturwerkzeug des Spiels auf deinen Cursor, und du klickst dann auf den Gegenstand, der repariert werden soll. Gildenbankreparatur repariert mit dem Geld der Gilde, wo du das darfst.

### Händler-Einstellungen

Öffne das WowVision-Menü und gehe zu Fenster, dann Händler.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Automatischer Verkauf schlechter Gegenstände (Automatically Sell Poor Items) | Aus | Wenn sich ein Händler öffnet, wird jeder graue Gegenstand in deinen Taschen, der einen Händlerwert hat, sofort verkauft. WowVision gibt im Chat „N schlechte Gegenstände für X verkauft.“ aus. |
| Automatisch reparieren, falls möglich (Automatically Repair If Possible) | Aus | Wenn sich ein Händler öffnet, wird deine Ausrüstung sofort mit deinem eigenen Geld repariert. WowVision gibt im Chat „Alles für X repariert.“ aus. Es wird still übersprungen, wenn der Händler nicht reparieren kann, nichts beschädigt ist oder du nicht bezahlen kannst. |

Beide sind für den üblichen Ablauf gedacht: zu einem Händler kommen, hören, was du verkauft und repariert hast, und weitergehen. Gesperrte Gegenstände werden nicht verkauft. Der automatische Verkauf schaut in den Rucksack und deine vier Taschen.

Wie jedes Fenster hat der Händler auf derselben Menüseite einen Schalter Aktiviert.

## Lehrer

Das Lehrerfenster bringt dir Zauber, Fertigkeiten und Berufe bei.

Die Stopps, der Reihe nach:

1. Nächster Rang (Next rank; nur WoW: Forever): WoW: Forever hebt den nächsten Rang eines Berufs, den du noch nicht gelernt hast, aus der Liste heraus in eine eigene Schaltfläche über der Liste.
2. Filter: ein Dropdown mit Verfügbar, Nicht verfügbar und Bereits bekannt. In WoW: Forever blendet das Spiel nicht verfügbare Fertigkeiten standardmäßig aus, sodass ein neuer Charakter nur einen Eintrag hört und nichts von dem, was später kommt. Öffne den Filter und hake Nicht verfügbar an, um alles zu sehen.
3. Ausbildung (Training): die Liste der Angebote, ein Zauber oder eine Fertigkeit pro Eintrag. Eingabe wählt einen aus.
4. Details: der Name des gewählten Angebots (die Leertaste liest seinen Tooltip), eine zweite Fertigkeitszeile, wenn es eine gibt, was es voraussetzt und was es kostet.
5. Die Schaltfläche Trainieren (Train). Drücke Eingabe, um das gewählte Angebot zu lernen.

### Was ein Angebot sagt

Ein Angebot liest seinen Namen und Rang, dann Bekannt oder Nicht verfügbar, wo das zutrifft, den Preis und seine Voraussetzungen:

- „Feuerball Rang 2, 20 Silber, Benötigt: Stufe 6“
- „Kochkunst (Lehrling), Bekannt“
- „Heldenhafter Stoß Rang 3, Nicht verfügbar, 1 Gold, Benötigt: Stufe 16“

Auf das Wort „ausgewählt“ folgt das Angebot, das du gewählt hast. Die Voraussetzungen werden angezeigt, egal ob du sie schon erfüllst, und die Zeile wird aus dem Wortlaut des Spiels gebaut, sie kann daher leicht von den Beispielen abweichen. Überschriften in der Liste (die Gruppen, die das Spiel benutzt, etwa Verfügbar) sagen Ausgeklappt oder Eingeklappt, und Eingabe klappt sie ein oder aus.

Beispiel: einen neuen Zauber lernen.

1. Interagiere mit deinem Klassenlehrer.
2. Drücke Tab, bis du „Ausbildung“ hörst, und gehe dann mit Pfeil runter durch die Liste.
3. Halte bei einem Angebot an, das du bezahlen kannst, und drücke Eingabe. Es sagt „ausgewählt“.
4. Drücke Tab bis „Details“ und lies die Kosten. Drücke dann Tab bis Trainieren.
5. Drücke Eingabe. Das Spiel bringt dir den Zauber bei, und dein Geld sinkt.

### Die Tierausbildung deines Begleiters

Auf WoW: Forever öffnet die Fähigkeit Tierausbildung des Jägers die Fertigkeiten deines Begleiters im selben Ausbilderfenster, ohne dass du einen Ausbilder ansprichst. WowVision liest es wie den Klassenlehrer. Das Fenster trägt den Namen deines Begleiters, die Stationen sind dieselben: Filter, Ausbildung und die Schaltfläche Trainieren. Eine Station ist neu, ganz oben: Trainingspunkte; sie liest, wie viele Punkte dein Begleiter noch hat, zum Beispiel "Trainingspunkte: 19".

Eine Fertigkeit kostet Trainingspunkte, kein Geld, und sagt das auch: "Natürliche Rüstung Rang 1, Kosten in Trainingspunkten: 1, Benötigt: Stufe 8". Drücke Eingabe auf einer Fertigkeit, um sie auszuwählen, dann Tab zu Trainieren und Eingabe, um sie beizubringen. Die Punkte sinken, und du hörst die neue Summe.

## Flugmeister

Ein Flugmeisterfenster listet auf, wohin du fliegen kannst. Es hat einen Stopp, benannt mit dem Titel der Karte (meist der Ort des Flugmeisters oder der Kontinent), und einen Eintrag pro Ziel.

Jeder Eintrag liest den Namen des Ortes und die Kosten:

- „Eisenschmiede, Dun Morogh, 2 Silber“
- „Hafen von Menethil, Sumpfland, 1 Silber 40 Kupfer“

Gehe mit Pfeil hoch und Pfeil runter und drücke Eingabe auf einem Ziel, um den Flug anzutreten. Es werden nur die Ziele aufgeführt, die das Spiel auf seiner Karte zeichnet, und der Ort, an dem du stehst, kann darunter sein.

## Bücher, Briefe und Tafeln

Wenn du einen Gegenstand oder ein Objekt mit Text liest, etwa ein Buch, einen Brief oder eine Tafel, öffnet sich das Fenster für den Gegenstandstext. Es liest:

1. Den Stopp Der Text: den Namen des Gegenstands, „Von“ und den Autor (nur wenn es einen gibt) und dann den Haupttext. Eine Textseite wird als ein Stück gelesen.
2. Vorherige Seite und Nächste Seite, nur bei Texten mit mehr als einer Seite. Drücke Eingabe, um umzublättern. Die neue Seite wird gelesen, sobald sie ankommt.
3. Eine Schaltfläche Schließen. Auch Esc schließt sie.

Der Text kann einen Moment brauchen, bis er vom Server kommt. WowVision bleibt still, bis er da ist, und liest ihn dann vor.

## Tierstall

(Nur The Burning Crusade.)

Jäger benutzen in The Burning Crusade den Tierstall, um zusätzliche Tiere unterzubringen. Sprich mit einem Stallmeister und wähle, den Stall zu öffnen. Das Fenster liest:

1. Ausgewähltes Tier (Selected Pet): die Stufe des Tiers, den Text zu Loyalität oder Zufriedenheit, wo das Spiel einen zeigt, und was es frisst.
2. Plätze (Slots): das aktuelle Tier, dann Stallplatz 1 und Stallplatz 2. Jeder liest seine Überschrift, den Namen des Tiers und „Stufe N Familie“ oder „Leerer Stallplatz“. Der Platz, den du gewählt hast, sagt „ausgewählt“.
3. Kaufen (Purchase): die Schaltfläche, um den nächsten Platz zu kaufen, mit ihrem Preis.
4. Geld (Money): dein Geld.
5. Schließen.

Ein Tier einstallen und herausholen funktioniert mit dem Cursor, wie bei Gegenständen:

- Um dein aktuelles Tier einzustallen: Drücke Umschalt+F10 auf dem Platz des aktuellen Tiers, wähle Ziehen und drücke dann Eingabe auf einem freien Stallplatz.
- Um ein eingestalltes Tier herauszuholen: Drücke Umschalt+F10 auf dem eingestallten Tier, wähle Ziehen und drücke dann Eingabe auf dem Platz des aktuellen Tiers. Die beiden Tiere tauschen, wenn du schon eins hast.
- Eingabe auf einem Platz wählt ihn aus, wenn nichts auf deinem Cursor liegt, und das Fenster zeigt die Details dieses Tiers.

Die Tasten für Ziehen (\\ und Strg+D) tun auf Stallplätzen nichts, benutze also den Eintrag Ziehen im Kontextmenü. (\\ liegt auf deutschen Tastaturen auf Alt Gr+ß; belege die Aktion bei Bedarf um.)

Classic Era, Mists of Pandaria, Retail und WoW: Forever haben keinen Stall-Leser.
