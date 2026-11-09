# Chat

WowVision spricht eingehende Chatnachrichten, sobald sie ankommen, führt einen Verlauf für jeden deiner Chat-Reiter und lässt dich diesen Verlauf lesen, die Namen und Links darin anklicken und Zeilen aus dem Spiel herauskopieren. Diese Seite behandelt die Ansagen, das Chatfenster, die Chat-Einstellungen und was du tun kannst und was nicht, solange das Spiel Chattext verbirgt.

Der Chat funktioniert in jeder Spielversion: Classic Era, The Burning Crusade (TBC), Mists of Pandaria (Mists), Retail und WoW: Forever. Die wenigen Stellen, an denen sich die Versionen unterscheiden, sind gekennzeichnet.

## Wie WowVision deinen Chat-Reitern folgt

WowVision folgt den Chat-Reitern, die du im Spiel hast. Welche Nachrichten und Kanäle ein Reiter erhält, bestimmen die Chat-Einstellungen des Spiels, genau wie bei einem sehenden Spieler. WowVision entscheidet nur, wie jeder Reiter gesprochen wird. Änderst du, welche Nachrichten ein Reiter erhält (siehe [Festlegen, was ein Reiter empfängt](#festlegen-was-ein-reiter-empfängt)), folgen gesprochene Nachrichten und Verlauf.

Jeder Reiter speichert bis zu 5000 Zeilen. Der Verlauf wird mit deinem Charakter gespeichert, ist also nach einem Neuladen oder einer neuen Anmeldung noch da. Schließt du einen Reiter, geht sein Verlauf verloren. Jede Zeile wird mit Datum und Uhrzeit gespeichert.

## Eingehende Nachrichten

Kommt eine Nachricht in einem Reiter an, der sprechen darf, hörst du die Zeile so, wie das Spiel sie zeigen würde, zum Beispiel „[Gilde] Xynayya: jemand für die Todesminen?“. Standardmäßig spielt dazu ein kurzer Ton.

Zwei Dinge entscheiden, ob ein Reiter spricht:

- Der Nachrichtenalarm des Reiters muss eingeschaltet sein (das ist er standardmäßig).
- Die Auswahl Nachrichten sprechen (Speak Messages) des Reiters, unten erklärt.

Eine Nachricht, die mehrere sprechende Reiter erreicht, wird nur einmal gesprochen, vom ersten Reiter, der sie erhält. Nachrichten, die du hörst, werden außerdem in den Verlauf des Reiters geschrieben, egal ob sie gesprochen wurden oder nicht.

Das Spiel hat für den Chat eine eigene Text-zu-Sprache-Funktion (in den Chat-Einstellungen des Spiels unter „Text zu Sprache“). Lass sie ausgeschaltet, sonst hörst du jede Nachricht doppelt.

## Alarme pro Reiter

Öffne das WowVision-Menü (Umschalt+F1) und gehe zu Chat. Der Bildschirm listet einen Eintrag für jeden geöffneten Chat-Reiter auf, genau so benannt wie der Reiter (zum Beispiel Allgemein oder Handel), gefolgt von Flüster-Reiter. Drücke Eingabe auf einem Eintrag, um seine Einstellungen zu sehen.

Jeder Reiter-Eintrag hat dieselben Einstellungen:

| Einstellung | Standard | Was sie tut |
|---|---|---|
| Aktiviert | An | Schaltet den ganzen Alarm für diesen Reiter ein oder aus. Ist er aus, ist der Reiter stumm (sein Verlauf wird trotzdem geführt). |
| TTS-Alarm | An | Eine Gruppe mit drei Einstellungen: Aktiviert (die Nachricht sprechen), Prioritätsnachricht (unterbricht) (wenn an, unterbricht die Nachricht, was gerade gesprochen wird, statt zu warten, bis sie dran ist; standardmäßig aus) und Stimme (welche Stimme spricht; standardmäßig folgt sie deiner Sprachstimme). |
| Soundalarm | An | Eine Gruppe mit Aktiviert und Sound, dem Ton, der mit jeder Nachricht spielt. Der Standard ist ein kurzer Chat-Ton. |
| Nachrichten sprechen | Wenn der Reiter angezeigt wird | Wann der Reiter spricht: siehe unten. |

Die Auswahl Nachrichten sprechen hat zwei Werte:

- Wenn der Reiter angezeigt wird: Der Reiter spricht nur, solange du ihn sehen kannst, also solange er der ausgewählte Reiter seines Docks oder ein eigenes Fenster auf dem Bildschirm ist. Das ist das Verhalten, das du von einem gewöhnlichen Chatfenster kennst.
- Immer: Der Reiter spricht alles, was er erhält, egal ob er ausgewählt ist oder nicht.

Die Einstellungen des ersten Reiters (des Allgemein-Reiters) werden aus älteren Versionen von WowVision übernommen, in denen es nur einen einzigen Chat-Alarm gab.

Beispiel: Flüsternachrichten sollen dich erreichen, egal welchen Reiter du gerade liest.

1. Lege im Spiel einen neuen Chat-Reiter an, der nur Flüsternachrichten erhält (siehe [Festlegen, was ein Reiter empfängt](#festlegen-was-ein-reiter-empfängt)).
2. Drücke Umschalt+F1, gehe zu Chat und drücke Eingabe auf dem Eintrag des neuen Reiters.
3. Stelle Nachrichten sprechen auf Immer.
4. Öffne Soundalarm, dann Sound, und wähle einen eigenen Ton, damit du ein Flüstern von anderen Nachrichten unterscheiden kannst.

Chat-Reiter, die nicht geöffnet sind, erscheinen nicht. Die Einstellungen eines Alarms, den du konfiguriert hast, bleiben für die Reiternummer gespeichert, ein Reiter, den du schließt und wieder öffnest, behält also seine Auswahl.

Der Reiter für das Haustierkampf-Protokoll wird gelesen, nicht gesprochen: Er hat keinen Alarm.

### Flüster-Reiter

Das Spiel kann für jedes Flüstergespräch einen neuen Reiter öffnen (in den Interface-Optionen des Spiels, Neue Flüsternachrichten: in einem neuen Reiter oder in beiden). Battle.net-Flüsternachrichten funktionieren genauso. WowVision erfasst diese Reiter in dem Moment, in dem das Spiel sie öffnet, damit die allererste Flüsternachricht nicht verloren geht.

Alle Flüster-Reiter teilen sich einen Alarm, Flüster-Reiter, mit denselben Einstellungen wie oben. Er spricht standardmäßig Immer, weil das Spiel in diesem Modus die Flüsternachricht aus jedem anderen Reiter nimmt und ein Reiter, den du gerade nicht ansiehst, sie sonst nie sagen würde.

Flüster-Reiter schließen sich, wenn du sie schließt oder dich abmeldest. Die Zeilen aller Flüster-Reiter werden außerdem zusammen in einer Liste namens Flüster-Reiter geführt, die wie die anderen Verläufe gespeichert wird (bis zu 5000 Zeilen) und die du in einem Puffer lesen kannst (siehe [Chat-Reiter-Puffer](#chat-reiter-puffer)).

Zeilen, die schon in einem Reiter standen, als WowVision ihn erfasste (zum Beispiel die Zeilen, die das Spiel aus dem Reiter, in dem du warst, in einen neuen Flüster-Reiter kopiert), werden nicht erneut gesprochen.

## Das Chatfenster

Drücke Umschalt+F3, um das Chatfenster zu öffnen. Esc schließt es. Es hat zwei Teile, die du mit Tab und Umschalt+Tab erreichst:

- Die Nachrichtenliste des ausgewählten Reiters. Sie ist die erste Station.
- Die Reiterleiste, eine Zeile mit einer Schaltfläche pro sichtbarem Chat-Reiter, in der Reihenfolge, in der das Spiel sie zeigt (angedockte Reiter von links nach rechts, dann Fenster, die für sich stehen). Flüster-Reiter sind eingeschlossen. Der ausgewählte Reiter sagt „ausgewählt“.

### Nachrichten lesen

Die Nachrichtenliste ist ein einziges Steuerelement, das alle Zeilen des ausgewählten Reiters enthält. Sie öffnet sich bei der neuesten Nachricht.

| Taste | Was sie tut |
|---|---|
| Pfeil hoch und Pfeil runter | Vorherige (ältere) und nächste (neuere) Nachricht. |
| Pos1 und Ende | Zur ältesten und zur neuesten Nachricht springen. |
| Pfeil links und Pfeil rechts | Zum vorherigen oder nächsten Chat-Reiter wechseln. Du hörst den Namen des Reiters und seine neueste Nachricht. Beim ersten oder letzten Reiter passiert nichts. |
| Strg+Pfeil links und Strg+Pfeil rechts | Zwischen den anklickbaren Teilen der Nachricht wechseln (siehe unten). |
| Eingabe | Linksklick auf den ausgewählten Teil. |
| Rücktaste | Rechtsklick auf den ausgewählten Teil. |
| Umschalt+Eingabe | Umschaltklick auf den ausgewählten Teil. |
| Leertaste | Den Tooltip des ausgewählten Links lesen. |
| Umschalt+Pfeil hoch, Umschalt+Pfeil runter, Umschalt+Pfeil links, Umschalt+Pfeil rechts | Den Tooltip Zeile für Zeile lesen (siehe [Tooltips](../basics/tooltips.md)). |
| Umschalt+F10 | Das Kontextmenü der Nachricht öffnen (siehe unten). |

Jede Nachricht wird als Zeile gesprochen, gefolgt von Datum und Uhrzeit, zum Beispiel „[Gilde] Xynayya: jemand für die Todesminen? 11/02/26 14:03:22“. Wenn die Nachrichtenliste den Fokus bekommt (das Fenster öffnet sich oder du kommst aus einem Menü zurück), hörst du außerdem deine Position, zum Beispiel „340 / 340“. Beim Bewegen mit Pfeil hoch, Pfeil runter, Pos1 und Ende werden nur die Nachricht und ihre Uhrzeit gesprochen. Erreichst du die erste oder letzte Nachricht noch einmal, wird nichts gesagt. Ein Reiter ohne Zeilen sagt „Leer“.

Das Wechseln zwischen Reitern mit Pfeil links und Pfeil rechts klickt wirklich auf den benachbarten Reiter, genau wie eine Maus es täte, sodass sich auch der ausgewählte Reiter des Spiels ändert. Es macht keinen Unterschied, ob du in der Reiterleiste Eingabe auf einem Reiter drückst oder in der Nachrichtenliste Pfeil links und Pfeil rechts.

Beispiel: Lies, was du im Gildenreiter verpasst hast.

1. Drücke Umschalt+F3.
2. Drücke Pfeil rechts, bis du den Namen des Gildenreiters zusammen mit seiner neuesten Nachricht hörst.
3. Mit Pfeil hoch gehst du durch die Nachrichten zurück, mit Ende zur neuesten.
4. Drücke Esc, um das Fenster zu schließen.

### Die Reiterleiste

Auf einer Reiter-Schaltfläche wählt Eingabe den Reiter aus, und Rücktaste öffnet das eigene Reitermenü des Spiels (umbenennen, Einstellungen, neues Fenster, schließen und so weiter), das WowVision wie jedes andere Dropdown liest (siehe [Spielermenüs und Dropdown-Menüs](social.md#spielermenüs-und-dropdown-menüs)). Umschalt+F10 listet dieselben Klicks auf.

### Die Teile einer Nachricht anklicken

Ein sehender Spieler kann Teile einer Chatzeile anklicken: den Namen des Absenders, den Kanalnamen und jeden verlinkten Gegenstand, jede Quest und jeden Zauber. WowVision gibt dir dieselben Klicks.

Drücke Strg+Pfeil links und Strg+Pfeil rechts, um zwischen den anklickbaren Teilen der aktuellen Nachricht zu wechseln, in der Reihenfolge, in der sie in der Zeile stehen. Jeder Teil wird mit Art und Name angesagt, zum Beispiel:

- „Spieler Xynayya“
- „Kanal 2. Handel - Stadt“
- „Gegenstand Leinenstoff“
- „Quest Die Bruderschaft der Defias“
- „Zauber Frostblitz“

Andere Linkarten werden als Talent, Erfolg, Beruf, Währung oder einfach Link angesagt. Der erste und der letzte Teil sind Grenzen: Versuchst du, darüber hinaus zu gehen, wird nichts gesagt.

Wenn du bei einer Nachricht ankommst, ist der erste verlinkte Gegenstand schon ausgewählt, falls es einen gibt, sodass die Tooltip-Tasten ihn sofort lesen können. Hat die Nachricht keinen Link, ist der Absender ausgewählt, sonst der erste Teil.

Auf dem ausgewählten Teil:

- Eingabe ist ein Linksklick. Bei einem Spieler beginnt er ein Flüstern an ihn (das Chat-Eingabefeld öffnet sich), bei einem Kanal beginnt er eine Nachricht an diesen Kanal, und bei einem Gegenstand, einer Quest, einem Zauber oder einem anderen Link liest er den Tooltip.
- Rücktaste ist ein Rechtsklick. Bei einem Spieler oder einem Kanal öffnet er das eigene Menü des Spiels (flüstern, einladen, Freund hinzufügen, ignorieren und so weiter).
- Umschalt+Eingabe ist ein Umschaltklick. Bei einem Link fügt er den Link in dein Chat-Eingabefeld ein (das Feld öffnet sich zuerst, falls es geschlossen ist), damit du ihn senden kannst. Bei einem Spieler fügt er den Namen in ein offenes Chat-Eingabefeld ein oder, wenn kein Feld offen ist, startet eine Wer-Suche nach diesem Spieler. Bei einem Kanal öffnet er das Fenster Chatkanäle (nur Retail und WoW: Forever). Bei einem Battle.net-Spieler tut das Spiel selbst nichts, also tut WowVision auch nichts.
- Leertaste und Umschalt+Pfeiltasten lesen den Tooltip eines ausgewählten Links.

Ein Link ohne Tooltip (ein Talent-Build in Retail, ein Kalenderereignis) wird mit dem eigenen Klick des Spiels behandelt, statt gelesen zu werden.

Beispiel: Flüstere dem Spieler, der eine Nachricht geschrieben hat.

1. Wähle im Chatfenster die Nachricht mit Pfeil hoch und Pfeil runter aus.
2. Drücke Strg+Pfeil links oder Strg+Pfeil rechts, bis du „Spieler“ und den Namen hörst.
3. Drücke Eingabe. Das Chat-Eingabefeld öffnet sich mit dem bereits adressierten Flüstern, und ein Ton spielt.
4. Tippe deine Nachricht und sende sie mit Eingabe. Drücke Esc, wenn du es dir anders überlegst.

Beispiel: Sieh nach, was ein verlinkter Gegenstand ist.

1. Wähle die Nachricht aus. Enthält sie einen Gegenstand, ist „Gegenstand“ schon ausgewählt; sonst benutze Strg+Pfeil links und Strg+Pfeil rechts.
2. Drücke Eingabe oder Leertaste, um den Tooltip zu hören. Mit Umschalt+Pfeil runter und Umschalt+Pfeil hoch gehst du ihn Zeile für Zeile durch.

Beispiel: Prüfe Stufe und Zone eines Spielers.

1. Wähle den Spielerteil einer Nachricht aus.
2. Drücke Umschalt+Eingabe. Das Spiel sendet eine Wer-Suche. Die Antwort kommt als Systemnachricht in deinem Chat an (in Classic Era, TBC und Mists kann sie außerdem die Wer-Liste öffnen, siehe [Soziales](social.md#die-wer-liste)).

### Das Kontextmenü der Nachricht

Drücke Umschalt+F10 auf einer Nachricht, um ihr Kontextmenü zu öffnen. Es nennt, was jeder Klick für den ausgewählten Teil tut, gefolgt vom Klick, der dasselbe bewirkt, damit du dir die Tasten nicht merken musst:

- Bei einem Spieler: Name anflüstern (Linksklick), Spielermenü für Name (Rechtsklick), Wer-Abfrage für Name (Umschaltklick, nicht bei Battle.net-Spielern). Jeder Eintrag nennt den Spieler und endet mit dem Klick, für den er steht, zum Beispiel „Xynayya anflüstern, Linksklick“.
- Bei einem Kanal: In Kanal schreiben (Linksklick), Kanalmenü für Kanal (Rechtsklick) und Fenster Chatkanäle (Umschaltklick, nur Retail und WoW: Forever).
- Bei jedem anderen Link: Tooltip von Link vorlesen (Linksklick) und Link im Chat verlinken (Umschaltklick), zum Beispiel „Leinenstoff im Chat verlinken, Umschaltklick“.
- Zeile kopieren steht immer ganz am Ende.

### Zeile kopieren

Wähle Zeile kopieren (Copy Line) im Kontextmenü, um die Nachricht aus dem Spiel herauszubekommen, zum Beispiel eine Webadresse oder einen langen Text. WowVision sagt „Jetzt kopieren“, und die Nachricht, ohne Farben, Link-Auszeichnung und Symbole, steht als reiner Text markiert in einem kleinen Eingabefeld. Drücke Strg+C, um sie zu kopieren, und Esc, um das Feld zu schließen. Die Zeile wird nicht noch einmal vorgelesen.

Das Spielermenü hat eine Zeile Charaktername kopieren (Copy Character Name). Wurde das Menü aus dem Chatfenster geöffnet, öffnet WowVision dieselbe Art von Kopierfeld für den Namen, sodass auch diese Zeile funktioniert.

### Chat während der Chatsperre (Retail und WoW: Forever)

In Retail und WoW: Forever verbirgt das Spiel Chattext vor allen Addons bei Bosskämpfen, in Herausforderungsmodi, in PvP-Spielen und auf manchen Karten (zum Beispiel in Dungeons und Schlachtzügen). Der Chat wird weiterhin gesprochen und in den Verlauf geschrieben, aber WowVision kann dann nicht in die Zeilen hineinsehen. Das hat diese Folgen:

- Strg+Pfeil links, Strg+Pfeil rechts, Eingabe, Rücktaste, Umschalt+Eingabe und Zeile kopieren antworten „Links hier nicht verfügbar“, statt zu handeln.
- Das Kontextmenü der Nachricht bietet nur Zeile kopieren, das ebenfalls „Links hier nicht verfügbar“ sagt.
- Nachrichten über Beute, Geld, Währung, Erfolge und Erfahrung sind nicht betroffen, ihre Links funktionieren also wie gewohnt.

Außerhalb der Sperre funktioniert wieder alles, und die Nachrichten aus der Sperre im Verlauf werden danach womöglich nicht anklickbar.

Classic Era, TBC und Mists haben keine Sperre.

## Festlegen, was ein Reiter empfängt

WowVision ändert nicht, was ein Reiter empfängt. Das stellst du im Chat-Einstellungsfenster des Spiels ein, das WowVision vorliest.

Um es zu öffnen, gehe zur Reiterleiste des Chatfensters, drücke Rücktaste auf dem Reiter und wähle im Menü Einstellungen. Das Chat-Einstellungsfenster öffnet sich dann mit diesen Teilen:

1. Kategorien: eine Liste von Schaltflächen, etwa die Chat-Einstellungen, die Kanaleinstellungen und die weiteren Nachrichtengruppen. Eingabe öffnet eine.
2. Chat-Einstellungen, Kanaleinstellungen und weitere Gruppen von Kontrollkästchen: Jede Gruppe ist durch ihre Überschrift benannt und enthält die Kontrollkästchen der Nachrichten (Sagen, Schreien, Gilde, Flüstern, Beute und so weiter). Eingabe schaltet ein Kontrollkästchen ein oder aus.
3. Kanäle: die Liste der globalen Kanäle (Allgemein, Handel und so weiter), in der Eingabe einen Kanal für diesen Reiter betritt oder verlässt.

Welche Gruppen du siehst, hängt von der gewählten Kategorie ab. Esc schließt das Fenster.

Beispiel: ein Reiter nur für Flüsternachrichten.

1. Öffne im Chatfenster die Reiterleiste und drücke Rücktaste auf einem beliebigen Reiter. Wähle im Reitermenü des Spiels die Zeile, die ein neues Fenster erstellt, und gib ihm einen Namen.
2. Öffne das Menü auf dem neuen Reiter erneut und wähle Einstellungen.
3. Wähle bei den Kategorien die Chat-Einstellungen und schalte nur Flüstern ein.
4. Schließe mit Esc. Der Reiter erscheint unter seinem Namen im WowVision-Menü Chat.

## Chat-Reiter-Puffer

Jeder Chat-Reiter kann auch über einen Puffer gelesen werden, sodass du den Chat mit den Puffertasten von überall prüfen kannst, ohne das Chatfenster zu öffnen. Ein Chat-Reiter-Puffer (Chat Tab Buffer) enthält dieselben Zeilen, die das Chatfenster für einen Reiter zeigt.

Um einen hinzuzufügen, öffne das WowVision-Menü, gehe zu den Puffern, füge einer Gruppe einen Puffer hinzu und wähle Chat-Reiter-Puffer als seinen Typ. Wähle dann seinen Chat-Reiter: jeden geöffneten Chat-Reiter nach Namen oder Flüster-Reiter für die Zeilen aller Flüster-Reiter zusammen. Ohne eigenen Namen heißt der Puffer wie der Reiter, den er zeigt.

Ein Chat-Reiter-Puffer beginnt bei der neuesten Zeile und folgt neuen Zeilen, sobald sie ankommen. Sobald du in ältere Zeilen zurückgegangen bist, bleibt er dort, wo du bist, bis du zum Ende zurückkehrst.

Wie Puffer, Gruppen und ihre Tasten funktionieren, steht unter [Puffer](../information/buffers.md).

## Nachrichten senden

WowVision liest den Chat vor, ersetzt aber nicht das Chat-Eingabefeld des Spiels. Um eine Nachricht zu senden, drücke Eingabe, solange kein WowVision-Fenster offen ist (oder die Taste, die du im Spiel benutzt), tippe deine Nachricht und drücke erneut Eingabe. Das Eintippen eines Slash-Befehls wie /w Name funktioniert wie gewohnt. Du kannst auch aus dem Chatfenster heraus eine Nachricht beginnen, indem du einen Spieler oder einen Kanal anklickst (siehe oben), wodurch sich das Chat-Eingabefeld bereits adressiert öffnet.

Zwei Töne sagen dir, wohin deine Tasten gehen: Einer spielt, wenn das Chat-Eingabefeld die Tastatur zum Tippen übernimmt, und ein anderer, wenn es sie wieder loslässt. Das ist wichtig, denn solange das Chat-Eingabefeld offen ist, wird jede Taste, die du drückst, dort eingetippt und weder von WowVision noch vom Spiel benutzt.

## Übersicht der Einstellungen

Alles für den Chat findest du im WowVision-Menü unter Chat.

| Einstellung | Standard | Was sie tut |
|---|---|---|
| Aktiviert | An | Schaltet das ganze Chat-Modul aus oder ein: Ist es aus, gibt es keine Ansagen und es wird kein Verlauf geführt. |
| Ein Eintrag pro geöffnetem Chat-Reiter, benannt wie der Reiter | siehe oben | Der Alarm des Reiters: Aktiviert, TTS-Alarm, Soundalarm und Nachrichten sprechen (standardmäßig Wenn der Reiter angezeigt wird). |
| Flüster-Reiter | siehe oben | Der gemeinsame Alarm für alle Flüster-Reiter, dieselben Einstellungen, aber Nachrichten sprechen steht standardmäßig auf Immer. |
| Chat-Eingabefeld geöffnet | An | Ton, wenn das Chat-Eingabefeld die Tastatur übernimmt. Hat Aktiviert und einen Soundalarm mit Aktiviert und Sound. |
| Chat-Eingabefeld geschlossen | An | Ton, wenn das Chat-Eingabefeld die Tastatur loslässt. Dieselben Einstellungen. |
| Addon-Meldungen im Chat | Aus | Schreibt die Meldungen von WowVision zusätzlich in deinen Haupt-Chat-Reiter, mit "WowVision:" davor: zum Beispiel, dass eine Route gestartet ist, wie weit ein Auktionshaus-Scan ist oder warum etwas nicht geht. Vorgelesenes wie Menüs, dein Ziel oder Tooltips erscheint dort nicht, und auch keine Alarme. Diese Zeilen werden nicht noch einmal gesprochen. Sie stehen wie jede andere Zeile im Verlauf des Reiters. |

Beide Chat-Eingabefeld-Töne funktionieren in jedem Chatfenster, im klassischen Chatstil (in dem das Feld im Leerlauf auf dem Bildschirm bleibt) ebenso wie im modernen Stil. Es geht um den Tastaturfokus, nicht darum, ob das Feld sichtbar ist.

Wie Alarme, Stimmen und Töne allgemein eingestellt werden, steht unter [Alarme](../basics/alerts.md) und [Sprache und Ton](../basics/speech.md).

## Tasten im Überblick

| Taste | Standard | Wo | Was sie tut |
|---|---|---|---|
| Umschalt+F3 | Belegt | Überall | Das Chatfenster öffnen. Kann als Chat umbelegt werden. |
| Strg+Pfeil links | Belegt | Nachrichtenliste | Vorheriger Link in der Nachricht. |
| Strg+Pfeil rechts | Belegt | Nachrichtenliste | Nächster Link in der Nachricht. |
| Umschalt+Eingabe | Belegt | Nachrichtenliste | Umschaltklick auf den ausgewählten Teil. |
| Pfeil hoch, Pfeil runter, Pos1, Ende | Belegt | Nachrichtenliste | Zwischen Nachrichten wechseln. |
| Pfeil links, Pfeil rechts | Belegt | Nachrichtenliste | Zum vorherigen oder nächsten Reiter wechseln. |
| Eingabe, Rücktaste, Leertaste | Belegt | Nachrichtenliste | Linksklick, Rechtsklick, Tooltip lesen. |

Die drei chatspezifischen Tasten (Vorheriger Link in der Nachricht, Nächster Link in der Nachricht, Umschaltklick) und Chat lassen sich im Fenster für die Tastenbelegung ändern (siehe [Tastenbelegung](../basics/keybindings.md)). Sie halten ihre Tasten nur, solange die Nachrichtenliste den Fokus hat.

## Fehlerbehebung

- Jede Nachricht wird doppelt gesprochen. Schalte in den Chat-Einstellungen des Spiels die eigene Text-zu-Sprache-Funktion des Spiels für den Chat aus.
- Ein Flüster-Reiter sagt nichts. Öffne Chat im WowVision-Menü, gehe zu Flüster-Reiter und stelle Nachrichten sprechen auf Immer.
- Ein Reiter, den du liest, ist stumm. Wahrscheinlich steht seine Auswahl Nachrichten sprechen auf Wenn der Reiter angezeigt wird, und der Reiter ist nicht der ausgewählte. Stelle sie auf Immer.
- „Links hier nicht verfügbar“. Das Spiel verbirgt den Chattext vor Addons (siehe [Chat während der Chatsperre](#chat-während-der-chatsperre-retail-und-wow-forever)).
- Chatfenster nach dem Neuladen leer. Der Verlauf wird pro Reiter geführt; ein Reiter, den du geschlossen hast, hat seinen Verlauf verloren.
