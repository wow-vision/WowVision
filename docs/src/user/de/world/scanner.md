# Scanner

Der Scanner (Scanner) ist eine Liste der Dinge um dich herum und wo sie sind: Quests, Questgeber, NPCs, deine Leiche, Gruppenmitglieder, Sammelpunkte und mehr. Er übernimmt die Rolle der "Was ist in meiner Nähe"-Liste, die Spieler von anderen Barrierefreiheits-Addons kennen. Du gehst ihn mit den Pfeiltasten durch, hörst, wie weit jeder Eintrag entfernt ist und in welcher Richtung, und drückst Eingabe, um dorthin geführt zu werden.

Drücke F9, um den Scanner zu öffnen. Mit Esc schließt du ihn. Die Taste heißt im Fenster für die Tastenbelegung Scanner und lässt sich dort ändern; siehe [Tastenbelegung](../basics/keybindings.md). Der Scanner funktioniert in jeder Spielversion, aber was er auflisten kann, hängt von der Version und von den verfügbaren Daten ab. Siehe "Hinweise zu den Versionen" am Ende.

Drückst du F9, während du im Questlog bist, öffnet sich der Scanner direkt auf dieser Quest, unter Quests, Laufend: die Quest, auf der dein Cursor im Questlog steht, sonst die Quest, deren Details offen sind. Drücke Pfeil rechts, um ihre Questziele zu hören, oder Eingabe, um zu ihrem nächsten Ziel geführt zu werden.

Hinweis: Die Ansagen des Scanners kommen größtenteils aus lokalisierten Texten und werden auf einem deutschen Client auf Deutsch gesprochen. Die Beispiele zeigen, was du hörst. Namen von NPCs, Orten und Questzielen stammen aus den Spieldaten und bleiben so, wie sie dort stehen.

## Wie er aufgebaut ist

Der Scanner ist ein einziger Baum. Die oberste Ebene enthält Kategorien, Kategorien enthalten Einträge, und viele Einträge enthalten weitere Einträge darunter. Einträge, die weitere enthalten, sind Gruppen. Nach dem Namen einer Gruppe hörst du "Eingeklappt" oder "Ausgeklappt".

| Taste | Was sie tut |
|-------|-------------|
| Pfeil runter und Pfeil hoch | Zum nächsten oder vorherigen Eintrag gehen. |
| Pfeil rechts | Eine eingeklappte Gruppe öffnen oder in eine offene hineingehen. |
| Pfeil links | Eine offene Gruppe schließen oder zu ihrem übergeordneten Eintrag zurückgehen. |
| Eingabe | Auf einem Eintrag mit Ort: dich dorthin führen (siehe unten). Auf einer Gruppe ohne Ort: öffnen oder schließen. Auf einem Kontrollkästchen in der Kategorie Verfolgung: ein- oder ausschalten. |
| Rücktaste | Auf Einträgen mit Zusatztext (Quests): eine kleine schreibgeschützte Liste mit diesem Text öffnen. |
| Tab | Vom Baum zur Schaltfläche Aktualisieren springen und zurück. |
| Esc | Den Scanner schließen. |

Alles andere funktioniert wie in jedem WowVision-Fenster; siehe [Die Oberfläche bedienen](../basics/interface.md) für Pos1, Ende und die Schnellsuche per Buchstaben.

Bei jedem Eintrag mit Ort hörst du seinen Namen, einen Zusatzhinweis, wenn er einen hat, die Entfernung und die Richtung von dem Ort, an dem du jetzt stehst, und seinen Platz in der Liste. Zum Beispiel: "Marshal McBride, gesehen, Quest verfügbar, 85 Meter, voraus links, 3 von 12". Entfernung und Richtung werden berechnet, wenn du auf den Eintrag gehst, sie folgen dir also beim Gehen. Die Richtungen sind relativ zu deiner Blickrichtung: voraus, voraus links, links, hinten links, hinten, hinten rechts, rechts, voraus rechts.

### Eine Momentaufnahme, keine Live-Liste

Der Scanner baut seine Listen einmal auf, wenn du ihn öffnest. Er ändert sich nicht, solange er offen ist, und bremst das Spiel deshalb nie mitten in einem Kampf oder Flug. Nur Entfernung und Richtung werden aktualisiert. Um die Listen auf den neuesten Stand zu bringen, ohne das Fenster zu schließen, drücke Tab zur Schaltfläche Aktualisieren und dann Eingabe. Du hörst "Aktualisiert". Auch ein erneutes Öffnen des Scanners baut frische Listen auf.

Welche Gruppen du geöffnet hast, wird zwischen den Öffnungen gemerkt, bis du dich ausloggst. Beim ersten Öffnen einer Sitzung ist jede Kategorie offen außer Verfolgung.

Hat eine Kategorie beim Aufbau einen Fehler, hörst du an ihrer Stelle eine Zeile, die mit "Fehler" beginnt, und der Rest des Scanners funktioniert weiter. Eine Gruppe ohne Inhalt liest "Leer".

## Die Kategorien

Die Kategorien erscheinen in dieser Reihenfolge. Einige fehlen, solange es nichts aufzulisten gibt.

### Spieler

- Leiche: solange du tot oder ein Geist bist, der Ort, an dem dein Körper liegt, sofern das Spiel ihn auf der aktuellen Karte meldet. Drücke Eingabe, um dorthin geführt zu werden, der übliche Weg, die Leiche bei einem Leichenlauf zu finden.
- Nicht tot: wird stattdessen angezeigt, solange du lebst.
- Friedhöfe: die Friedhöfe der Karte, auf der du bist, jeweils mit ihrer Entfernung. Öffne die Gruppe, um sie zu sehen.

### Gruppe

Die Mitglieder deiner Gruppe oder deines Schlachtzugs. Jedes ist mit Namen aufgelistet. Das Spiel gibt nur für Gruppenmitglieder auf deiner Karte eine Position an. Wenn du Eingabe drückst, richtet sich das Navigationsfenster auf die Position des Mitglieds in diesem Moment aus. Mit WowNav in WoW: Forever wird WowNav mitgeteilt, welches Mitglied du gewählt hast, sodass eine neue Route oder Strg+Umschalt+N die Position des Mitglieds neu liest, statt die alte zu benutzen; siehe [WowNav (WoW: Forever)](wownav.md). Ist das Mitglied nicht mehr auf deiner Karte, hörst du "Keine Position des Gruppenmitglieds verfügbar". Die Kategorie Gruppe fehlt, solange sich kein Mitglied verorten lässt.

### Quests

Zwei Untergruppen: In der Nähe und Laufend. Sie werden aus den Questdaten gefüllt, die deine Spielversion bietet: siehe [Quests](quests.md).

In der Nähe listet Quests, die du in deiner Umgebung annehmen könntest, der nächste Questgeber zuerst. Jeder Eintrag zeigt den Questnamen, dann "Stufe" und die Quest-Stufe, ob sie Täglich oder Wiederholbar ist, und den Namen des Questgebers. Ist ein Questgeber nur ein gesehener Questgeber (vom [Minikarten-Scanner](minimap.md) gefunden), zeigt der Eintrag stattdessen den Namen des Gebers, markiert mit gesehen, Quest verfügbar oder Abgabe, gegebenenfalls niedrigstufig, und drinnen. Drücke Rücktaste auf einer Quest, um ihren Zieltext zu lesen. Welche Quests aufgelistet werden, hängt von den Einstellungen Stufenbereich für Quests in der Nähe und Wiederholbare Quests einbeziehen ab; siehe [Quests](quests.md).

Startet die Datenquelle noch, hörst du "Lädt". Ohne jede Datenquelle enthält die ganze Kategorie Quests nur die eine Zeile "Keine Questdatenquelle".

Laufend listet dein Questlog. Jeder Eintrag zeigt den Questtitel mit seiner Stufe ("Eine Bedrohung von innen, Stufe 5"; es ist die Stufe aus dem Questlog, bei einer skalierenden Quest kann sie leicht abweichen) und seinen Zustand: "Abgeschlossen", "Fehlgeschlagen" oder "2 von 3" dafür, wie viele Ziele erledigt sind. Die Liste ist nach Entfernung sortiert, die nächste zuerst, und zwar nach dem Ort, zu dem dich Eingabe auf der jeweiligen Quest führen würde. Eine Quest, die du ein paar Schritte entfernt abgeben kannst, steht also vor einer am anderen Ende des Gebiets; Quests ohne Ort, zu dem du gehen kannst, folgen zuletzt. Die Einstellung Quests nach Entfernung sortieren schaltet das aus und behält die Reihenfolge des Questlogs bei; siehe [Quests](quests.md). Drücke Rücktaste, um den Zieltext zu lesen. Öffne eine Quest, um ihre Ziele zu sehen:

1. Eine laufende Quest klappt zu ihren Zielen auf (nur wenn die Datenquelle die Quest kennt; eine Quest, die sie nicht kennt, zeigt nur ihren Zustand), zum Beispiel "Kobold Vermin slain: 3/10". Ein erledigtes Ziel ist mit "Abgeschlossen" markiert.
2. Ein Ziel klappt zu dem auf, worum es geht: den Kreaturen, Objekten oder Gegenstandsquellen, die dafür zählen. Eine Gegenstandsquelle heißt etwa "Linen Cloth von Defias Thug". Jede davon zeigt einen Hinweis: ihren Titel, "gesehen", wenn der Minikarten-Scanner sie gefunden hat, "drinnen", die Zahl der Fundorte und, wenn es nur einen Fundort gibt, wo er ist.
3. Etwas mit mehreren Fundorten klappt noch einmal zu jedem Fundort auf, benannt nach seinem Ort, zum Beispiel "Valley of the Four Winds, Halfhill Market, 80 Meter". Ein Fundort, der als ausgephast markiert ist, ist einer, den es für deinen Charakter gerade wahrscheinlich nicht gibt, der aber behalten wird, falls die Vermutung falsch war.
4. Eine abgeschlossene Quest klappt stattdessen gleich zum Abgabe-NPC oder -Objekt auf, markiert mit "Abgabe".

Du hörst also, wonach du suchen sollst, bevor du hörst, wo es ist. Beispiel: Du hast die Quest "Wolves Across the Border" mit dem Ziel "Prowler slain: 3/10". Geh auf die Quest, und du hörst ihren Namen und "0 von 1" (noch kein Ziel erledigt). Drücke Pfeil rechts: Der erste Eintrag ist das Ziel, "Prowler slain: 3/10". Drücke noch einmal Pfeil rechts: "Prowler, 12 Fundorte". Drücke noch einmal Pfeil rechts, und du gehst die Fundorte durch, der nächste zuerst, jeder mit seinem Ortsnamen und seiner Entfernung. Drücke Eingabe auf dem, den du willst.

Die Questzeile und das Ziel tragen jeweils auch eine eigene Position, das erste unerledigte Ziel, sodass Eingabe auf der Quest selbst dich zum nächsten Ort führt, an dem du vorankommen kannst. Eine abgeschlossene Quest führt dich zu ihrer Abgabe.

Manche Ziele nennen nichts, wohin du gehen kannst: ein Gebiet, das du erkunden sollst, ein Gegner, für den die Questdaten keine Fundorte kennen, oder ein Ort auf einem anderen Kontinent. Dann nimmt WowVision die Questmarkierung des Spiels, das Gebiet, das das Spiel auf deiner Karte für den aktuellen Schritt der Quest zeigt, und der Eintrag sagt "Questmarkierung des Spiels". Markiert das Spiel nichts, nimmt WowVision die eigene Kartenmarkierung von Questie für das nächste offene Ziel, den Punkt, den Questie auf deiner Karte zeigt, und der Eintrag sagt "Questie-Markierung". Hat ein Ziel mehrere Questie-Markierungen, klappt es zu ihnen auf, die nächste zuerst. Die Markierung des Spiels führt dich auch zur Abgabe einer abgeschlossenen Quest, deren Abgabe nicht bekannt ist, und zu einer Quest, die Questie nicht kennt. Eingabe führt dich zu all diesen Orten wie zu jedem anderen. Nur wenn weder das Spiel noch Questie etwas markieren, hat der Eintrag keinen Ort.

### NPCs

- Questgeber: die NPCs, die die unter In der Nähe aufgelisteten Quests anbieten, jeweils mit der Zahl der Quests darunter ("3 Quests"). Öffne einen, um seine Quests zu sehen. Ein Questgeber, der nur durch den Minikarten-Scan gefunden wurde, ist ein einzelner Eintrag mit der Markierung "gesehen".
- Rollengruppen: Händler, Reparieren, Lehrer, Flugmeister, Gastwirte, Bankiers, Auktionatoren, Stallmeister, Kampfmeister, Geistheiler, Klassenlehrer, Briefkästen, Andere NPCs, Seltene Gegner. Jede listet die NPCs dieser Art in deinem aktuellen Gebiet und innerhalb des Scan-Radius auf, der nächste zuerst.

Wie viele erscheinen, hängt von den Daten ab. Mit einer Quest-Datenbank (Questie, siehe [Quests](quests.md)) können alle erscheinen. Ohne eine erscheint eine Rollengruppe erst, wenn der Minikarten-Scanner einen NPC dieser Art gesehen hat, und die Gruppen für Geistheiler und Seltene Gegner erscheinen nie. Einträge, die der Minikarten-Scan gefunden hat, sind mit "gesehen" markiert. Ein NPC, den die Datenbank schon aufführt, wird nicht noch einmal als gesehen wiederholt.

### Interessante Orte

Die Städte und Wahrzeichen, die der letzte Minikarten-Scan auf der Minikarte gesehen hat. Das sind nur Namen ohne Position, Eingabe tut darauf also nichts. Wird nur angezeigt, nachdem ein Scan welche gefunden hat. Siehe [Minikarten-Scanner](minimap.md).

### Sammeln

Kraut-, Erz- und Schatzpunkte, die der Minikarten-Scan gefunden hat, mit einer Gruppe für jede Verfolgungsfähigkeit, benannt danach, etwa "Find Herbs" oder "Find Minerals". Eine Gruppe "Unsortiert" enthält Punkte anderer Verfolgungsfähigkeiten, die sich nicht einordnen ließen. Wird nur angezeigt, nachdem ein Scan welche gefunden hat. Jeder Punkt ist, wo es zutrifft, mit "gesehen" und "drinnen" markiert. Siehe [Minikarten-Scanner](minimap.md).

### Verfolgung

Diese Kategorie beginnt eingeklappt. Sie enthält die Verfolgungs- und Kartenfilter-Auswahlen, die ein sehender Spieler in den Menüs der Minikarte und der Weltkarte umschaltet. Es sind Kontrollkästchen: Eingabe schaltet das um, auf dem du stehst, und du hörst den neuen Zustand.

- Minimap-Verfolgung (Minimap Tracking): jede Verfolgungsart deines Charakters, etwa Find Herbs, Find Minerals, Auktionator, Bankier, Flugmeister, Gastwirt, Briefkasten, Reparieren und Händler. Was du hier einschaltest, kann die Minikarte und damit der Minikarten-Scanner und seine Ansagen beim Gehen anzeigen.
- Kartenfilter (Map Filter): die Filteroptionen der Weltkarte: Questziele auf der Karte, Quest-Stufen, Farben der Quest-Schwierigkeit, Dungeoneingänge, niedrigstufige Quests und verfolgte Gegenstände. Die Namen kommen vom Spiel. Drücke Rücktaste auf einem, um die Beschreibung des Spiels dazu zu lesen. Ein Filter, den deine Spielversion nicht hat, wird nicht aufgelistet.

## Was Eingabe tut

Eingabe auf einem Eintrag mit Ort schließt den Scanner und beginnt, dich zu führen. Was dann folgt, ist das [Navigationsfenster](navigation.md):

- Gibt es Routendaten für den Kontinent, auf dem du bist, öffnet sich das Navigationsfenster mit dem nächsten Einstiegspunkt ins Wegnetz und deinem gewählten Eintrag schon als Ziel ausgewählt. Drücke dort Eingabe, um die Route zu gehen. Sie folgt dem Wegpunktnetz und endet mit einem geraden letzten Stück bis zum Eintrag.
- Gibt es keine Routendaten, hörst du "Beacon gesetzt", gefolgt von der Entfernung in Metern, zum Beispiel "Beacon gesetzt 40 Meter", und ein Klang-Beacon führt dich in gerader Linie. Wenn du ankommst, hörst du "Angekommen".

Ist WowNav an (WoW: Forever), wird ein NPC oder Objekt, das WowNavs eigene Ortsliste an dieser Stelle kennt, aus dieser Liste genommen: dieselbe Kreatur, sonst ein Ort mit demselben Namen. Die Route kennt dann Höhe und Stockwerk des Ziels, führt also auf das richtige Stockwerk und endet ohne den Hinweis, dass das letzte Stück ungeprüft ist. Ein Ziel, das WowNav nicht kennt, wird wie bisher angesteuert.

Bei einem gesehenen NPC, den der Minikarten-Scan gefunden hat, löst die Ankunft außerdem die Suche nach dem echten Namen aus, die im [Minikarten-Scanner](minimap.md) beschrieben ist.

## Einstellungen

Öffne das WowVision-Menü, dann Scanner. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Scan-Radius | 500 | Wie viele Meter um dich herum die Rollengruppen und gesehenen Einträge reichen. Von 50 bis 5000. Er begrenzt nicht die Questlisten In der Nähe oder Laufend. |
| Einträge pro Kategorie | 25 | Die meisten Einträge in einer Gruppe, der nächste zuerst. Von 5 bis 200. |

Die zugehörigen Quest-Einstellungen stehen im Modul Quests: siehe [Quests](quests.md).

## Beispiel: Einen Questgeber finden und zu ihm gehen

1. Drücke F9. Du hörst "Scanner" und die erste Kategorie.
2. Gehe mit Pfeil runter zu Quests, drücke Pfeil rechts, um sie zu öffnen, und öffne dann In der Nähe.
3. Der erste Eintrag ist die nächste Quest, zum Beispiel "A Threat Within, Stufe 1, Marshal McBride, 40 Meter, voraus, 1 von 4".
4. Drücke Rücktaste, um zu lesen, was die Quest von dir verlangt, dann Esc, um zurückzukommen.
5. Drücke Eingabe. Der Scanner schließt sich und das Navigationsfenster öffnet sich, oder du hörst "Beacon gesetzt 40 Meter", wenn es keine Routendaten gibt.
6. Geh zum Questgeber. Du hörst "Angekommen".

## Beispiel: Leichenlauf

1. Gib deinen Geist frei.
2. Drücke F9. Die Kategorie Spieler sagt "Leiche" mit Entfernung und Richtung.
3. Drücke Eingabe, um geführt zu werden. Folge dem Beacon oder der Route.

## Hinweise zu den Versionen

- Classic Era, The Burning Crusade und Mists of Pandaria: Die Quest-Gruppen und NPC-Rollengruppen benutzen das Addon Questie, wenn es geladen ist. Ohne Questie greift WowVision auf die eigenen Questkartendaten des Spiels zurück, wo der Client sie hat, wie Retail; wo nicht, hörst du "Keine Questdatenquelle".
- Retail: Die Questlisten kommen aus den eigenen Questkartendaten des Spiels. Es gibt keine Spawn-Tabellen, daher hat jeder Questeintrag nur eine Position, und die NPC-Gruppen listen nur Questgeber auf, die als "Questgeber" an einem Ort erscheinen statt mit Namen. Es gibt keine Rollengruppen.
- WoW: Forever: benutzt Questie, wenn es geladen ist, sonst die eigenen Questdaten des Spiels. Die eigenen Questdaten des Spiels sind dort oft unvollständig, deshalb ergänzt der Minikarten-Scanner Questgeber, NPC-Arten, Sammelpunkte und interessante Orte. Siehe [Minikarten-Scanner](minimap.md).
- Verfolgung erscheint nur dort, wo das Spiel Minikarten-Verfolgungsarten bereitstellt.
- Friedhöfe erscheinen, wenn das Spiel sie für die Karte auflisten kann.
- Positionen von Gruppenmitgliedern lassen sich nur lesen, wo das Spiel sie bereitstellt.
- Eingabe öffnet das [Navigationsfenster](navigation.md), wo Kartendaten für den Kontinent existieren, und fällt sonst auf ein gerades Beacon zurück.
- Der Scanner liegt auch auf der Kürzelebene des Controllers; siehe [Controller](../controller.md).

## Verwandte Seiten

- [Minikarten-Scanner](minimap.md), der Sammeln, Interessante Orte und die Einträge "gesehen" füllt.
- [Quests](quests.md), für Questdaten und Questie.
- [Navigation und Routen](navigation.md), wohin dich Eingabe bringt.
