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

## Quests und Questziele finden

Der [Scanner](scanner.md) verwandelt Questdaten in Orte, zu denen du gehen kannst. Er ist der wichtigste Weg, mit WowVision Quests zu finden.

- Quests, In der Nähe: Quests, die du in deiner Umgebung annehmen kannst, der nächste Questgeber zuerst.
- Quests, Laufend: dein Log. Jede Quest, die die Datenquelle kennt, öffnet sich zu ihren Zielen, jedes Ziel zu den Kreaturen, Objekten und Gegenstandsquellen, um die es geht, und jede davon zu ihren Fundorten.
- NPCs, Questgeber: dieselben Questgeber, nach NPC gruppiert.

Eingabe auf einer Quest, einem Ziel, einem Ziel-NPC oder einem Fundort führt dich zu seinem Ort. Siehe [Navigation und Routen](navigation.md).

So werden Orte in den Listen beschrieben: Ein Fundort liest sich mit seinem Gebiet, dann dem besten Hinweis, den WowVision für den Ort im Gebiet hat. Liegt ein Wahrzeichen der Karte, etwa eine Stadt oder ein Lager, innerhalb von etwa 600 Metern, liest sich der Fundort "bei Halfhill, 40 Meter", oder einfach "Halfhill, 40 Meter", wenn die erkundete Karte die Stelle ebenfalls Halfhill nennt. Benennt die Questdatenquelle das Untergebiet, steht dessen Name zuerst. Ist kein Wahrzeichen nah, wird der Gebietsname der erkundeten Karte benutzt. Das ist eine Beschreibung, die dir hilft, dir den Ort vorzustellen, keine genaue Adresse.

## Einstellungen

Öffne das WowVision-Menü, dann Quests. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Stufenbereich für Quests in der Nähe | 5 | Die Liste In der Nähe blendet Quests aus, die um mehr als so viele Stufen unter deiner Stufe liegen. Von 0 bis 60. Stelle 60 ein, um jede Quest zu sehen, oder 0, um nur Quests auf deiner Stufe oder darüber zu sehen. |
| Wiederholbare Quests einbeziehen | An | Ob wiederholbare und tägliche Quests in der Liste In der Nähe erscheinen. |
| Quests nach Entfernung sortieren | An | Ob die Liste Laufend nach Entfernung sortiert ist, die nächste zuerst, und zwar nach dem Ort, zu dem dich Eingabe auf der jeweiligen Quest führen würde (das nächste offene Ziel, oder die Abgabe, sobald eine Quest abgeschlossen ist). Quests ohne Ort, zu dem du gehen kannst, folgen in der Reihenfolge deines Questlogs. Schalte die Einstellung aus, um die Reihenfolge des Questlogs zu behalten. |
| Questgebiet | siehe oben | Ansagen beim Betreten oder Verlassen eines Zielgebiets. |
| Questfortschritt, Ziel erreicht, Quest abgeschlossen | siehe oben | Ansagen zum Questfortschritt. |

Die Liste In der Nähe lässt außerdem Quests weg, die du noch nicht annehmen kannst, wegen deiner Stufe oder einer fehlenden Vorquest.

## Beispiel: Eine Quest durcharbeiten

1. Geh zu einem Questgeber. Das Spiel öffnet das Questfenster. Du hörst den Namen des NPCs, dann "Quests" mit "Verfügbare Quest: A Threat Within" oder die Details der einzelnen Quest.
2. Drücke Pfeil runter, um Beschreibung und Ziele zu lesen. Drücke Tab, dann Eingabe auf Annehmen.
3. Drücke F9, öffne Quests, dann Laufend. Die Quest ist aufgelistet, "A Threat Within, 0 von 1". Drücke Pfeil rechts, um das Ziel zu öffnen, und noch einmal Pfeil rechts, um zu sehen, was du töten sollst, dann drücke Eingabe auf einem Fundort, um dorthin geführt zu werden.
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
