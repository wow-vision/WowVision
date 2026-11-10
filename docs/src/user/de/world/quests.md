# Quests

Diese Seite behandelt alles rund um Quests, was WowVision für dich tut: das Questlog lesen, das Fenster eines Questgebers lesen und beantworten, hören, wenn du das Gebiet eines Questziels betrittst, und Questgeber und Questziele mit dem [Scanner](scanner.md) finden. Sie erklärt auch das Addon Questie, das auf den klassischen Spielversionen die meisten Questdaten liefert.

Hinweis: Die Ansagen dieser Seite kommen größtenteils aus lokalisierten Texten und werden auf einem deutschen Client auf Deutsch gesprochen. Questtitel, Zieltexte und Namen von NPCs und Orten stammen aus den Spieldaten bzw. aus Questie und bleiben in den Beispielen so, wie sie dort stehen.

## Woher die Questdaten kommen

WowVision muss wissen, wo Quests beginnen und wo ihre Ziele sind. Es holt sich das aus bis zu drei Quellen und benutzt, was deine Spielversion bietet:

| Quelle | Benutzt auf | Was sie weiß |
|--------|-------------|--------------|
| Questie (ein separates Addon) | Classic Era, The Burning Crusade, Mists of Pandaria, WoW: Forever | Alles: jede Quest im Spiel, Quest-Stufen, Namen der Questgeber, die Kreaturen, Objekte und Gegenstände hinter jedem Ziel mit allen ihren Fundorten und die Art jedes NPCs (Händler, Lehrer, Gastwirt und so weiter). |
| Die eigenen Questkartendaten des Spiels | Retail; WoW: Forever, Mists of Pandaria, Classic Era und The Burning Crusade, wenn Questie fehlt und der Client diese Daten hat | Die Quests, die auf deiner aktuellen Karte angeboten werden, und ein Punkt pro Quest in deinem Log. Questgeber haben keine Namen ("Questgeber" an einem Ort), und es gibt keine Spawn-Tabellen. |
| Gesehene NPCs vom [Minikarten-Scanner](minimap.md) | WoW: Forever | Die Questgeber und anderen NPCs, die der Minikarten-Scan seit deinem Login gefunden hat. Er füllt die Lücken, wo das Spiel keine eigenen Questdaten bietet. |

WowVision benutzt Questie, wann immer es geladen ist, und sonst die eigenen Daten des Spiels. Wo keines von beiden existiert, enthalten die Kategorien Quests und NPCs des Scanners nur die eine Zeile "Keine Questdatenquelle". Mit Questie funktioniert es immer. Die Fenster für dein Questlog und die Fenster der Questgeber funktionieren ohne jede dieser Quellen. Nur das Finden von Orten braucht sie.

### Questie: was du tun musst

1. Installiere das Addon Questie für deine Spielversion und lass es aktiviert. Siehe [Installation](../getting-started/installation.md).
2. Logge dich ein. Questie baut seine Quest-Datenbank beim Login auf. Bis sie bereit ist, sagen die Questlisten im Scanner "Lädt", und `/wv quests` sagt "Questie lädt noch". Das dauert meist ein paar Sekunden.
3. Öffne den Scanner mit F9 und sieh dir Quests und NPCs an.

Was Questie hinzufügt, das den eigenen Daten des Spiels fehlt:

- Questnamen, Stufen und Namen der Questgeber in der Liste In der Nähe.
- Bei laufenden Quests die Kreaturen, Objekte und Gegenstandsquellen hinter jedem Ziel, mit jedem Fundort.
- NPC-Rollengruppen in der Kategorie NPCs des Scanners: Händler, Reparieren, Lehrer, Flugmeister, Gastwirte, Bankiers, Auktionatoren, Stallmeister, Kampfmeister, Geistheiler, Klassenlehrer, Briefkästen und Seltene Gegner. Die NPC-Liste von Questie wird nach dem Login im Hintergrund indiziert, deshalb sagen diese Gruppen kurze Zeit vielleicht "Lädt".
- Ortsnamen für Fundorte, etwa "Elwynn Forest, Goldshire" oder "Valley of the Four Winds, bei Halfhill, 40 Meter".

Questie enthält nur Quests und Fundorte, die es für deinen Charakter gibt. Fundorte, die wegen der Story-Phase deines Charakters verborgen sind, werden als ausgephast aufgelistet; sie stehen am Ende der Liste, falls die Vermutung falsch ist.

Auf WoW: Forever liefert Questie eine Version, die auf Classic-Era-Daten aufbaut. WowVision zieht sie den eigenen Questdaten des Spiels vor, weil die eigenen Questdaten des Spiels dort oft leer sind.

## Das Questlog-Fenster

Öffne das Questlog mit der eigenen Taste des Spiels (standardmäßig L). WowVision liest das Fenster, das sich in deiner Version öffnet. Die Liste und die Details sind getrennte Tabstopps, drücke also Tab, um zwischen ihnen und den Schaltflächen zu wechseln.

In der Questliste bewegen Pfeil hoch und Pfeil runter zwischen Überschriften und Quests. Drücke Eingabe auf einer Quest, um sie auszuwählen, wodurch die Details gefüllt werden. Drücke Eingabe auf einer Überschrift, um sie ein- oder auszuklappen. Drücke die Tooltip-Taste, um den Tooltip der Quest zu hören; siehe [Tooltips](../basics/tooltips.md).

Normalerweise steht der Fokus beim Öffnen auf der ausgewählten Quest. Schalte im WowVision-Menü unter Fenster, Questlog die Einstellung Immer oben beginnen ein, dann steht er beim Öffnen auf dem obersten Eintrag der Liste. Standardmäßig ist sie aus. Öffnet sich das Questlog in den Details einer Quest, bleibst du dort.

### The Burning Crusade

(Nur The Burning Crusade.)

- Quests werden gelesen als "[Abgeschlossen] [Täglich] Questtitel". Die Kennzeichen Abgeschlossen, Fehlgeschlagen, Täglich und Wöchentlich erscheinen, wenn sie zutreffen. Die gewählte Quest sagt "ausgewählt". Gebietsüberschriften sagen "Eingeklappt" oder "Ausgeklappt".
- Die Details sind eine Gruppe namens Details: der Questtitel, seine Beschreibung, der Zieltext und jedes Ziel, etwa "Kobold Vermin slain: 3/10".
- Schaltflächen folgen als eigene Stopps: alle einklappen, abbrechen und teilen, mit den eigenen Beschriftungen des Spiels.
- Das Spiel zeigt nur sechs Quests auf einmal. WowVision scrollt die Liste für dich, während du dich bewegst.

### Mists of Pandaria

(Nur Mists of Pandaria.)

- Dasselbe Lesen wie bei The Burning Crusade für Quests und Überschriften.
- Zielzeilen folgen deinem Fortschritt, solange das Log offen ist.
- Schaltflächen: abbrechen, teilen und verfolgen, mit den eigenen Beschriftungen des Spiels.

### Retail und WoW: Forever

(Retail und WoW: Forever.) In diesen Versionen ist das Questlog Teil der Weltkarte. Die Taste öffnet ein Panel neben der Karte, und WowVision liest dieses Panel.

- Die Liste zeigt Gebietsüberschriften und Quests. Eine Quest liest sich etwa "[12] Wolves Across the Border, Grün, ausgewählt, verfolgt". Eine fertige Quest hat nach dem Titel "Abgeschlossen" ("[12] Wolves Across the Border, Abgeschlossen, Grün"), eine gescheiterte "Fehlgeschlagen", dort wo das Spiel sein Häkchen und die Zeile "Bereit zur Abgabe" oder sein Kennzeichen Fehlgeschlagen zeigt. Das Farbwort (Grau, Grün, Gelb, Orange, Rot) ist die Schwierigkeitsfarbe des Spiels für deine Stufe, so wie ein sehender Spieler sie sieht. "ausgewählt" und "verfolgt" kommen dazu, wenn sie zutreffen. Zielzeilen in der Liste werden übersprungen, weil die Details denselben Text lesen.
- Die Gruppe Details enthält den Titel, die Beschreibung, den Zieltext, jedes aktuelle Ziel und eine einzeilige Zusammenfassung der Belohnungen.
- Schaltflächen: abbrechen, verfolgen (sie liest "Nicht mehr verfolgen", wenn die Quest verfolgt wird), teilen und die Kartenschaltfläche. Ihre Beschriftungen stammen vom Spiel, und die Beschriftung wird nach dem Drücken der Schaltfläche noch einmal gesprochen.
- Eine Belohnung wählst du hier nicht. Das geschieht, wenn du die Quest abgibst.

### Classic Era

WowVision hat für Classic Era kein Questlog-Fenster, das eigene Questlog des Spiels wird dort also nicht gelesen. Mit installiertem Questie kannst du deine Quests trotzdem über den [Scanner](scanner.md) lesen, unter Quests, Laufend.

Die oben genannten Questlog-Fenster überlässt WowVision Sku, wenn das Addon Sku zusammen mit WowVision geladen ist.

## Fenster der Questgeber

Sprichst du einen NPC an, der Quests hat, öffnet das Spiel ein Questfenster. WowVision liest, welche Seite davon gerade angezeigt wird. Der Titel des Fensters ist der Name des NPCs. Auf den Seiten für Details, Fortschritt und Belohnung ist der Text eine Liste in einem Tabstopp, gefolgt von seinen Schaltflächen als getrennte Stopps, sodass dich ein Tab vom Text zu den Schaltflächen bringt. Auf der Begrüßungsseite ist der Begrüßungstext ein Stopp und jede Quest ein eigener Stopp.

| Seite | Was du hörst | Schaltflächen |
|-------|--------------|---------------|
| Begrüßung (der NPC hat mehrere Quests) | Der Begrüßungstext, dann Quests: jede als "Verfügbare Quest: Titel" oder "Angenommene Quest: Titel" | Auf Wiedersehen |
| Details (eine Quest wird angeboten) | Details: Titel, Beschreibung, Überschrift der Ziele, Ziele, dann die Belohnungen | Annehmen, Ablehnen |
| Fortschritt (du kommst unfertig oder fertig zurück) | Fortschritt: Titel, Text und die noch benötigten Gegenstände | Weiter, Auf Wiedersehen |
| Belohnung (Abgabe) | Belohnung: Titel, Text und die Belohnungen | Quest abschließen, Abbrechen |

Die Schaltflächen stammen vom Spiel, mit den Beschriftungen des Spiels, die von den obigen leicht abweichen können.

Belohnungen werden in Gruppen gelesen:

- Eine Liste von Auswahlmöglichkeiten, eingeleitet vom eigenen Satz des Spiels, dass du eine dieser Belohnungen wählen kannst. Jede Auswahl liest sich als Gegenstandsname, mit " x 5" dahinter, wenn du mehrere bekommst.
- Eine Liste von Gegenständen, die du erhältst.
- Geld und Erfahrung als einfache Zeilen.

Um eine Belohnung zu wählen, drücke Eingabe auf dem gewünschten Gegenstand. Das ist ein echter Klick, der Gegenstand wird also ausgewählt. Dann gehe mit Tab zu Quest abschließen und drücke Eingabe. Gegenstands-Tooltips funktionieren mit der Tooltip-Taste.

Ein Questgeber kann Quests zuerst über das Gesprächsfenster anbieten; diese Einträge werden ebenfalls als "Verfügbare Quest: Titel" und "Angenommene Quest: Titel" gelesen. Siehe [Mit NPCs sprechen](../windows/npcs.md).

Ist Sku geladen, überlässt WowVision dieses Fenster Sku.

### Dialog zur Questauswahl

(Nur Mists of Pandaria.) Manche Quests, bei denen du zwischen mehreren Optionen wählst, zeigen stattdessen ein Fenster Questauswahl (Quest Choice). Es liest die Frage, dann jede Option als eigenen Tabstopp: den Text der Option, die Ruf-, Gegenstands- und Währungsbelohnungen, die sie gibt, und ihre Wählen-Schaltfläche. Eine letzte Schaltfläche Schließen verlässt das Fenster ohne Wahl.

## Questgebiets-Alarm

Wenn du in das schattierte Gebiet hineingehst oder es verlässt, in dem die Ziele einer verfolgten Quest liegen, sagt WowVision es dir:

- "Betrete Gebiet: Wolves Across the Border"
- "Verlasse Gebiet: Wolves Across the Border"

Das funktioniert für Quests, die du verfolgst, und auch im Kampf. Eine Quest meldet jeden Zustand nur einmal, du hörst also keine Wiederholung.

Während eines Minikarten-Scans ist der Gebietsalarm kurz stummgeschaltet. Der Scan schaltet die Verfolgung ein und aus, was das Spiel sonst als Verlassen und Betreten jedes Gebiets melden würde.

Der Alarm heißt Questgebiet (Quest Area Alert) und gehört zum Modul Quests. Wie Alarme funktionieren, steht auf der Seite [Alarme](../basics/alerts.md).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Questgebiet, Aktiviert | An | Schaltet die Ansage ein oder aus. |
| TTS-Alarm, Aktiviert | An | Spricht die Ansage. |
| TTS-Alarm, Prioritätsnachricht (unterbricht) | Aus | Wenn an, unterbricht die Ansage das, was gerade gesprochen wird. |
| TTS-Alarm, Stimme | Folgt deiner Sprachstimme | Wähle eine Stimme nur für diesen Alarm. |
| Soundalarm, Aktiviert | Aus | Spielt einen Ton statt oder neben der Sprache. |
| Soundalarm, Sound | keiner | Welcher Ton gespielt wird. |

## Alarme für den Questfortschritt

Das Spiel zeigt den Questfortschritt als Meldung in der Bildschirmmitte. WowVision spricht diese Meldungen so, wie das Spiel sie formuliert, und spielt einen Ton für das, was passiert ist, mit drei eigenen Alarmen:

- Questfortschritt (Quest Progress Alert): ein Zähler ändert sich, etwa "Kobold Vermin getötet: 3/8" oder "Leinenstoff: 2/6". Sein Ton ist success1, der Ton von Sku.
- Ziel erreicht (Objective Complete Alert): ein Ziel ist erledigt, etwa "Erkundet die Mine (Abgeschlossen)", oder die Meldung "Aufgabe abgeschlossen." des Spiels, die kein Ziel nennt. Sein Ton ist objective_complete.
- Quest abgeschlossen (Quest Complete Alert): alle Ziele einer Quest sind erledigt, du kannst sie abgeben. Sein Ton ist success2, der Ton von Sku, und er spielt statt des Tons für das Ziel. Das Spiel schickt dafür keine Meldung, deshalb liest WowVision es aus deinem Questlog. Seine Sprachausgabe, der Questtitel und "Abgeschlossen", startet ausgeschaltet, denn die Meldung des Spiels zum letzten Ziel hörst du schon.

Die Meldung des Spiels wird sofort gesprochen. Ist ein Ziel erledigt, wartet sein Ton einen Moment, weniger als eine halbe Sekunde, um zu erfahren, ob damit die Quest fertig ist. Jeder Alarm hat TTS und Sound und lässt sich einzeln ausschalten. Sie arbeiten unabhängig vom Modul Fehler, auch wenn es ausgeschaltet ist, und diese Meldungen erscheinen nicht in seinem Filter pro Fehler. Hattest du eine dieser Meldungen dort stummgeschaltet oder Fehler ansagen ausgeschaltet, startet ihr Alarm ausgeschaltet. Siehe [Alarme](../basics/alerts.md).

## Quest-Töne in der Nähe

Beim Laufen hörst du die Quests in deiner Nähe. Jeder Quest-Ton ist ein kurzer Ping, der aus der Richtung des Ortes kommt, wie das Beacon. Er ist leiser, je weiter der Ort entfernt ist, und du hörst ihn nur, wenn der Ort vor dir liegt. Drehst du dich zu einem Ping, den du verpasst hast, hörst du ihn noch einmal. Die Töne brauchen Questie, gelten also für Classic Era, The Burning Crusade, Mists of Pandaria und WoW: Forever mit geladenem Questie. Ohne Questie bleiben sie stumm.

Es gibt drei Töne:

- Ton für annehmbare Quests: Der Questgeber einer Quest, die du annehmen kannst, ist in deiner Nähe. Es ist der weiche Benachrichtigungston, den auch Sku spielt.
- Ton für abgebbare Quests: Eine Quest in deinem Log ist abgeschlossen und die Person, bei der du sie abgibst, ist in deiner Nähe. Es ist der Stahlgong, den auch Sku spielt.
- Ton für Questziele: Eine Quest in deinem Log hat ein offenes Ziel in deiner Nähe, etwa Kreaturen zum Töten oder einen Gegenstand zum Finden. Es ist ein tiefer Sondierungston. Sku hat dafür keinen Ton.

Ein Ort pingt zum ersten Mal einen Moment, nachdem du in seine Reichweite gekommen bist, früher, wenn er nah ist, und später, wenn er weit weg ist. Mehrere Quests beim selben Questgeber ergeben einen Ping. Nach dem Ping bleibt der Ort still, bis du ein anderes Gebiet betrittst. Bekommt der Questgeber eine neue Quest zum Anbieten, hörst du ihn wieder. Ist die Einstellung zum einmaligen Spielen aus, pingt der Ort immer wieder, solange du in Reichweite bleibst. Questziele sind wieder still, wenn du dich weit von ihnen entfernt hast, und pingen wieder, wenn du zurückkommst. Stehst du nah an einem Ort, näher als die Entfernung für Stumm, ist er still. Du hörst nichts, solange du auf einer Flugroute reist, tot bist oder kämpfst. Nach dem Kampf kommen die Pings wieder.

Quests eines Feiertags zählen nur, solange der Feiertag läuft. Für annehmbare Quests gelten die Einstellungen Stufenbereich für Quests in der Nähe und Wiederholbare Quests einbeziehen, siehe unten. Schalte das Ganze mit Aktiviert im Menü In der Nähe aus.

Öffne das WowVision-Menü, dann Quests, dann In der Nähe.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert | An | Schaltet alle Quest-Töne in der Nähe an oder aus. |
| Ton für annehmbare Quests, Aktiviert | An | Schaltet den Ton für annehmbare Quests an oder aus. |
| Ton für annehmbare Quests, Beacon-Ton, Aktiviert | An | Spielt den Ping. |
| Ton für annehmbare Quests, Beacon-Ton, Beacon-Ton | Notification soft 100 | Welcher Ton gespielt wird. |
| Ton für annehmbare Quests, Beacon-Ton, Lautstärke | 30 | Wie laut der Ping ist, von 10 bis 100. |
| Ton für annehmbare Quests, TTS-Alarm, Aktiviert | Aus | Sagt die Quest, ihren Namen und die Entfernung, zum Beispiel "Quest verfügbar: A Threat Within, 30 yards". |
| Ton für abgebbare Quests | dieselben Einstellungen | Lautstärke 40, Ton steel gong, und es sagt "Quest abgeben" vor dem Namen. |
| Ton für Questziele | dieselben Einstellungen | Lautstärke 30, Ton probe deep 1, und es sagt "Questziel" vor dem Namen. |
| Reichweite für annehmbare Quests | 40 | Entfernung in Yards, ab der annehmbare Quests pingen. Von 5 bis 200. |
| Reichweite für abgebbare Quests | 60 | Entfernung, ab der abgebbare Quests pingen. |
| Reichweite für Questziele | 50 | Entfernung, ab der offene Ziele pingen. |
| Annehmbare Quests nur einmal | An | Jeder Ort pingt einmal, statt immer wieder. |
| Abgebbare Quests nur einmal | An | Dasselbe für abzugebende Quests. |
| Questziele nur einmal | An | Dasselbe für Ziele. |
| Stumm ab Entfernung | 5 | Näher als so viele Yards ist ein Ort still. Von 1 bis 30. |

## Quests und Questziele finden

Der [Scanner](scanner.md) verwandelt Questdaten in Orte, zu denen du gehen kannst. Er ist der wichtigste Weg, mit WowVision Quests zu finden.

- Quests, In der Nähe: Quests, die du in deiner Umgebung annehmen kannst, der nächste Questgeber zuerst.
- Quests, Laufend: dein Log, nach Zonen geordnet wie im Questlog, in jeder Zone die nächste Quest zuerst. Jede Quest, die die Datenquelle kennt, öffnet sich zu ihren Zielen, jedes Ziel zu den Kreaturen, Objekten und Gegenstandsquellen, um die es geht, und jede davon zu ihren Fundorten.
- NPCs, Questgeber: dieselben Questgeber, nach NPC gruppiert.

Eingabe auf einer Quest, einem Ziel, einem Ziel-NPC oder einem Fundort führt dich zu seinem Ort. Siehe [Navigation und Routen](navigation.md).

So werden Orte in den Listen beschrieben: Ein Fundort liest sich mit seinem Gebiet, dann dem besten Hinweis, den WowVision für den Ort im Gebiet hat. Liegt ein Wahrzeichen der Karte, etwa eine Stadt oder ein Lager, innerhalb von etwa 600 Metern, liest sich der Fundort "bei Halfhill, 40 Meter", oder einfach "Halfhill, 40 Meter", wenn die erkundete Karte die Stelle ebenfalls Halfhill nennt. Benennt die Questdatenquelle das Untergebiet, steht dessen Name zuerst. Ist kein Wahrzeichen nah, wird der Gebietsname der erkundeten Karte benutzt. Das ist eine Beschreibung, die dir hilft, dir den Ort vorzustellen, keine genaue Adresse.

## Einstellungen

Öffne das WowVision-Menü, dann Quests. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Stufenbereich für Quests in der Nähe | 5 | Die Liste In der Nähe blendet Quests aus, die um mehr als so viele Stufen unter deiner Stufe liegen. Von 0 bis 60. Stelle 60 ein, um jede Quest zu sehen, oder 0, um nur Quests auf deiner Stufe oder darüber zu sehen. |
| Wiederholbare Quests einbeziehen | An | Ob wiederholbare und tägliche Quests in der Liste In der Nähe erscheinen. |
| Quests nach Entfernung sortieren | An | Ob jede Zone der Liste Laufend nach Entfernung sortiert ist, die nächste zuerst, und zwar nach dem Ort, zu dem dich Eingabe auf der jeweiligen Quest führen würde (das nächste offene Ziel, oder die Abgabe, sobald eine Quest abgeschlossen ist). Quests ohne Ort, zu dem du gehen kannst, folgen in der Reihenfolge deines Questlogs. Schalte die Einstellung aus, um in jeder Zone die Reihenfolge des Questlogs zu behalten. |
| Questgebiet | siehe oben | Ansagen beim Betreten oder Verlassen eines Zielgebiets. |
| Questfortschritt, Ziel erreicht, Quest abgeschlossen | siehe oben | Ansagen zum Questfortschritt. |

Die Liste In der Nähe lässt außerdem Quests weg, die du noch nicht annehmen kannst, wegen deiner Stufe oder einer fehlenden Vorquest.

## Beispiel: Eine Quest durcharbeiten

1. Geh zu einem Questgeber. Das Spiel öffnet das Questfenster. Du hörst den Namen des NPCs, dann "Quests" mit "Verfügbare Quest: A Threat Within" oder die Details der einzelnen Quest.
2. Drücke Pfeil runter, um Beschreibung und Ziele zu lesen. Drücke Tab, dann Eingabe auf Annehmen.
3. Drücke F9, öffne Quests, dann Laufend, dann Wald von Elwynn. Die Quest ist aufgelistet, "A Threat Within, 0 von 1". Drücke Pfeil rechts, um das Ziel zu öffnen, und noch einmal Pfeil rechts, um zu sehen, was du töten sollst, dann drücke Eingabe auf einem Fundort, um dorthin geführt zu werden.
4. Draußen hörst du "Betrete Gebiet: A Threat Within", wenn du das Zielgebiet erreichst.
5. Ist das Ziel erledigt, liest sich die Quest als "Abgeschlossen". Drücke F9, öffne sie und drücke Eingabe auf der Abgabe. Sprich den NPC an, gehe mit Tab zu Quest abschließen, wähle eine Belohnung, wenn es eine Auswahl gibt, dann Eingabe.

## Diagnosebefehle

Nützlich für Fehlermeldungen. Die Ausgabe geht ins Chatfenster.

| Befehl | Was er tut |
|--------|------------|
| `/wv quests` oder `/wv quests near` | Listet bis zu zehn Quests in der Nähe mit Stufe, Questgeber und Entfernung auf. |
| `/wv quests log` | Listet dein Questlog mit dem Zustand und den Zielen jeder Quest auf. |
| `/wv quests go ID [start\|objectives\|finish]` | Listet auf, wohin dich Quest Nummer ID für diese Phase schickt. Standard ist `objectives`. |
| `/wv quests raw [mapID]` | Gibt aus, was die eigenen Questdaten des Spiels für eine Karte sagen. Nur, wo die eigenen Daten des Spiels die Quelle sind. |
| `/wv quests probe` | Führt einen drei Sekunden langen Test jeder Quest- und Kartendatenquelle durch, die das Spiel bietet, öffnet den Bericht in einem kopierbaren Fenster und speichert ihn für die Fehlermeldung. Es spricht "Quest probe running, 3 seconds" (Ansage auf Englisch, wenn nicht übersetzt) und dann eine kurze Zusammenfassung. |

Meldungen, die du hören kannst: "Keine Questdatenquelle", "Questie lädt noch", "Keine Quests in der Nähe", "Keine laufenden Quests", "Keine Ziele".

## Verwandte Seiten

- [Scanner](scanner.md) und [Minikarten-Scanner](minimap.md).
- [Navigation und Routen](navigation.md), was nach Eingabe passiert.
- [Mit NPCs sprechen](../windows/npcs.md) für Gespräche, Händler und Lehrer.
- [Alarme](../basics/alerts.md).
