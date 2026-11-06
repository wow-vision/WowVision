# Alarme

Ein Alarm ist etwas, das WowVision dir ungefragt mitteilt: Du hast das Gebiet gewechselt, ein Kampf hat begonnen, dein Ziel hat gewechselt, du bist gegen eine Wand gelaufen. Jeder Alarm kann Text sprechen, einen Sound abspielen, eine aufgenommene Stimme abspielen oder mehrere davon gleichzeitig, und jeder Teil lässt sich im [WowVision-Menü](./menu-and-settings.md) ein-, ausschalten oder ändern. Diese Seite erklärt, wie Alarme aufgebaut sind, wie du sie änderst, und listet jeden Alarm nach Modul auf.

## Alarme und Ausgaben

Jeder Alarm hat:

- einen Schalter Aktiviert, der den ganzen Alarm ein- oder ausschaltet, und
- eine oder mehrere Ausgaben, die Wege, auf denen er dich erreicht. Jede Ausgabe hat ihren eigenen Schalter Aktiviert und ihre eigenen Einstellungen.

Es gibt vier Arten von Ausgaben.

| Ausgabe | Name im Menü | Was sie tut |
|---|---|---|
| Sprachausgabe | TTS-Alarm | Spricht Text mit deiner TTS-Stimme, zum Beispiel „Kampf begonnen“. |
| Sound | Soundalarm (oder ein spezifischerer Name) | Spielt eine Sounddatei ab, zum Beispiel ein Klicken oder einen Glockenton. |
| Aufgenommene Stimme | Stimmenalarm | Spielt eine Aufnahme aus einem [Stimmenpaket](./speech.md#aufgenommene-stimmenpakete) ab, zum Beispiel „Norden“ oder eine Zahl. |
| Signal | Signalton | Ein Richtungston, der dir sagt, wo ein Wegpunkt liegt. Wird nur von der Navigation benutzt. |

Ein Alarm spricht nur, wenn der Alarm und die Ausgabe beide aktiviert sind. Schalte einen Alarm aus, um ihn ganz stummzuschalten; schalte eine Ausgabe aus, um die übrigen zu behalten.

Beispiel: Gebietsänderungs-Alarm hat einen TTS-Alarm (an) und einen Soundalarm (aus). Ab Werk hörst du den Namen des Gebiets. Willst du zusätzlich einen Glockenton, schalte den Soundalarm ein. Willst du nur den Glockenton, schalte auch den TTS-Alarm aus.

Die Einstellungen von Alarmen sind accountweit: Änderst du einen Alarm bei einem Charakter, ändert er sich bei allen. Soll ein Charakter eine eigene Fassung eines Alarms bekommen, drücke Umschalt+F10 auf dem Schalter des Alarms und benutze Bereich, siehe [Einstellungen pro Charakter und accountweit](./menu-and-settings.md#einstellungen-pro-charakter-und-accountweit). Den Filter pro Fehler des Moduls Fehler nutzen immer alle deine Charaktere gemeinsam, und die Alarme in einem Monitor folgen dem [Bereich dieses Monitors](../information/monitors.md#accountweit-oder-pro-charakter).

## Einen Alarm finden und ändern

Alarme stehen unten auf dem Bildschirm des Moduls, zu dem sie gehören, nach dessen Einstellungen, jeweils als Schalter. (Das Modul Chat listet die Alarme seiner Reiter direkt nach Aktiviert, und Zielerfassung hält die drei Zielalarme innerhalb von Festes Ziel.)

1. Öffne das WowVision-Menü mit Umschalt+F1 und gehe in das Modul, zum Beispiel Navigation, dann Kompass.
2. Gehe nach unten zum Alarm, zum Beispiel Gebietsänderungs-Alarm, und drücke Eingabe.
3. Der Bildschirm des Alarms öffnet sich mit einem Kontrollkästchen Aktiviert oben, gefolgt von einem Schalter pro Ausgabe. Alarme mit einer eigenen Einstellung (wie Nachrichten sprechen beim Chat) zeigen sie hier ebenfalls.
4. Drücke Eingabe auf einer Ausgabe, zum Beispiel Soundalarm, um ihre Einstellungen zu öffnen.
5. Esc geht jeweils eine Ebene zurück.

### Was der Bildschirm einer Ausgabe enthält

Jeder Ausgabe-Bildschirm beginnt mit Aktiviert. Danach, je nach Art der Ausgabe:

| Einstellung | Ausgabe | Was sie tut |
|---|---|---|
| Prioritätsnachricht (unterbricht) | TTS | Wenn an, wird die laufende Sprache gestoppt, bevor dieser Alarm spricht. Standardmäßig aus, außer bei Alarmen, die sofort zu hören sein müssen, wie der Alarm Zielwechsel und die Alarme für weiche Ziele. Nicht verfügbar beim Neuer Minikarten-Punkt, der von einer eigenen Spielstimme gesprochen wird. |
| Stimme | TTS | Welche TTS-Stimme diesen Alarm spricht. Solange du keine auswählst, folgt sie deiner Einstellung Sprachstimme und zeigt den Namen dieser Stimme. |
| Nachricht | TTS | Nur bei TTS-Ausgaben, die ihren Text von anderswo beziehen, wie Fehler ansagen und der TTS-Alarm einer Monitorregel. Alarme mit eigener Formulierung (Kampf begonnen, ein Gebietsname, eine Chatnachricht und so weiter) haben sie nicht. Tippst du hier Text ein, wird er jedes Mal statt des üblichen Texts gesprochen. Lass das Feld leer, um den üblichen Text zu hören. |
| Sound | Sound | Ein Schalter, der den Sound-Browser öffnet. Er liest den Namen der aktuellen Datei. Siehe [Einen Sound auswählen](./menu-and-settings.md#einen-sound-auswählen). Manche Soundalarme haben einen festen Sound und nur das Kontrollkästchen Aktiviert. |
| Stimmenpaket | Stimme | Wähle zwischen den aufgenommenen Stimmen Matthew und Joanna. |
| Signalton | Signal | Ein Browser wie der Sound-Browser, für die Signaltöne. Beim Daraufgehen wird ein Beispiel abgespielt. |

Beispiel: Den Namen deines Ziels von einer anderen Stimme sprechen lassen.

1. Umschalt+F1, dann Z für Zielerfassung, Eingabe.
2. Pfeil runter bis Festes Ziel, Eingabe, dann zu Zielwechsel, Eingabe.
3. Pfeil runter bis TTS-Alarm, Eingabe, dann Pfeil runter (an Prioritätsnachricht (unterbricht) vorbei) bis Stimme, Eingabe.
4. Wähle mit Eingabe eine Stimme aus der Liste.

Beispiel: Den Kompass auf TTS statt auf aufgenommene Stimme umstellen.

1. Umschalt+F1, N (Navigation), Eingabe, dann K (bis du Kompass hörst; Karten kommt davor), Eingabe.
2. Öffne Kompassrichtung ansagen. Öffne Stimmenalarm und schalte Aktiviert aus. Gehe zurück und öffne TTS-Alarm, schalte Aktiviert ein.

## Die Alarme, Modul für Modul

Die Menüpfade beginnen bei der ersten Ebene des WowVision-Menüs. Der Zustand in Klammern ist der Standard der jeweiligen Ausgabe. „An“ heißt aktiviert. Wo beim Standard nichts steht, ist die Ausgabe an.

### Benutzeroberfläche

| Alarm | Menüpfad | Wann er auslöst | Ausgaben |
|---|---|---|---|
| Kampf-gestartet-Alarm | Benutzeroberfläche, Kampf | Du trittst in den Kampf ein. | TTS „Kampf begonnen“ |
| Kampf-beendet-Alarm | Benutzeroberfläche, Kampf | Du verlässt den Kampf. | TTS „Kampf beendet“ |
| Gegneranzahl-Alarm | Benutzeroberfläche, Kampf | Die Zahl der Gegner im Kampf ändert sich. Braucht im Spiel eingeschaltete Namensplaketten für Gegner: Sind sie aus, wenn der Kampf beginnt, sagt WowVision einmal pro Sitzung „Schalte die Namensplaketten für Feinde ein, um Gegner zu zählen“. Siehe [Kampf](../world/combat.md). | TTS (die Zahl), Stimmenalarm (aus; aufgenommene Zahlen) |

### Navigation

| Alarm | Menüpfad | Wann er auslöst | Ausgaben |
|---|---|---|---|
| Kompassrichtung ansagen | Navigation, Kompass | Die Richtung, in die du blickst, ändert sich (Norden, Nordosten, Osten und so weiter). | Stimmenalarm (an; aufgenommene Richtungen), TTS-Alarm (aus) |
| Gebietsänderungs-Alarm | Navigation, Kompass | Du betrittst ein neues Gebiet. Spricht den Namen des Gebiets. | TTS, Soundalarm (aus) |
| Untergebietsänderungs-Alarm | Navigation, Kompass | Du betrittst ein neues Untergebiet, etwa ein Stadtviertel oder eine Höhle. Spricht seinen Namen. | TTS, Soundalarm (aus) |
| Draußen-Alarm | Navigation, Kompass | Du trittst ins Freie. Sagt „draußen“. | TTS, Soundalarm (aus) |
| Drinnen-Alarm | Navigation, Kompass | Du gehst nach drinnen. Sagt „drinnen“. | TTS, Soundalarm (aus) |
| Flug-gestartet-Alarm | Navigation, Kompass | Du hebst auf einem Flugreittier ab. Sagt „fliegen“. | TTS, Soundalarm (aus) |
| Flug-beendet-Alarm | Navigation, Kompass | Du landest. Sagt „Flug beendet“. | TTS, Soundalarm (aus) |
| Schwimm-Alarm | Navigation, Kompass | Du gehst ins Wasser. Sagt „schwimmen“. | TTS, Soundalarm (aus) |
| Tauch-Alarm | Navigation, Kompass | Du tauchst unter Wasser. Sagt „tauchen“. | TTS, Soundalarm (aus) |
| Fallerkennung | Navigation, Fallerkennung | Du fällst. Die Ansage wird einmal gesprochen, wenn die Fallsounds beginnen. | Fallgeräusch (eine aufsteigende Reihe von Sounds; je länger der Fall, desto höher der Sound), Fallansage (TTS „Fallen“) |
| Wanderkennung | Navigation, Wanderkennung | Du bewegst dich, aber etwas hält dich zurück. | Fünf Sounds für fünf Grade der Behinderung: Blockiert, Größtenteils blockiert, Behindert, Verlangsamt und Leicht verlangsamt. |
| Signal | Navigation, Karten | Eine Route oder ein Signal ist aktiv. | Signalton (ein Richtungs-Ping, der schneller wird, wenn du dich dem Ziel zuwendest), Signal ausgerichtet (ein Klick, wenn du ihm zugewandt bist), Signal abseits des Kurses (wenn du dich abwendest), Wegpunkt erreicht (wenn du ankommst) |

In Instanzen meldet das Spiel nicht, in welche Richtung du blickst, daher bleibt Kompassrichtung ansagen dort stumm, während die übrigen Kompassalarme weiter funktionieren. Die Einstellungen der Fallerkennung (Verzögerung (Millisekunden), Sprünge ignorieren) stehen auf dem Bildschirm des Moduls, siehe [Bewegung und Orientierung](../world/movement.md). Die Ankunftseinstellungen von Signal stehen unter [Navigation und Routen](../world/navigation.md).

### Zielerfassung

| Alarm | Menüpfad | Wann er auslöst | Ausgaben |
|---|---|---|---|
| Zielwechsel | Zielerfassung, Festes Ziel | Du erfasst etwas als Ziel. Spricht die Angaben, die du unter Zielerfassung, Namen ausgewählt hast (standardmäßig Name, Stufe und Ähnliches), optional beginnend mit seiner Schlachtzugmarkierung. | TTS mit eingeschalteter Prioritätsnachricht (unterbricht) und der Einstellung Schlachtzugmarkierung bei festem Ziel ansagen (an); Ziel-im-Kampf-Sound (spielt einen Glockenton, wenn dein Ziel mit dir oder deiner Gruppe im Kampf ist) |
| Lebensüberwachung | Zielerfassung, Festes Ziel | Die Gesundheit des Ziels überschreitet eine 5-Prozent-Stufe. Spricht die Stufe, zum Beispiel „75%“. Nicht auf Retail und WoW: Forever, wo das Spiel die Gesundheit im Kampf verbirgt; siehe [Zielerfassung](../world/targeting.md). | TTS, Stimmenalarm (aus; aufgenommene Zahlen) |
| CC auf dem Ziel | Zielerfassung, Festes Ziel | Auf deinem Ziel liegt CC von irgendjemandem (betäubt, in Furcht versetzt, verwandelt und Ähnliches), oder du wechselst zu einem Ziel mit CC; und noch einmal, wenn es wieder frei ist oder wenn du von einem Ziel mit CC zu einem freien wechselst. Nicht verfügbar auf The Burning Crusade Anniversary. | Klang bei CC, Klang bei Ende des CC, TTS-Alarm (aus; spricht „CC“ oder „Frei“) |
| Weiches Ziel Feind, Weiches Ziel Freund, Weiches Ziel Interaktion | Zielerfassung | Das weiche Ziel des Spiels dieser Art ändert sich. Spricht die Angaben, die du unter Zielerfassung, Namen ausgewählt hast, und spielt einen Sound. Der ganze Alarm ist standardmäßig aus. Schalte jeden Alarm mit Umschalt+I (Feind), Umschalt+P (Freund) und Umschalt+O (Interaktion) oder mit seinem Kontrollkästchen Aktiviert ein. Er enthält auch Winkel und Reichweite dieses weichen Ziels, siehe [Zielerfassung](../world/targeting.md). | TTS, Soundalarm |
| Reichweite geändert | Zielerfassung, Festes Ziel | Das obere Ende der Reichweite zu deinem Ziel ändert sich, oder du erfasst etwas Neues. Sagt die Zahl als Aufnahme. | Stimmenalarm |

Siehe [Zielerfassung](../world/targeting.md) für die Einstellungen, die dazugehören.

### Chat

| Alarm | Menüpfad | Wann er auslöst | Ausgaben |
|---|---|---|---|
| Ein Alarm für jeden Chat-Reiter, benannt wie der Reiter im Spiel (zum Beispiel Allgemein) | Chat | Auf diesem Reiter kommt eine Nachricht an. | TTS-Alarm (spricht die Nachricht), Soundalarm (ein Chat-Sound) und die Auswahl Nachrichten sprechen: Wenn der Reiter angezeigt wird (der Standard) oder Immer |
| Flüster-Reiter | Chat | Auf einem beliebigen Flüster-Reiter kommt eine Nachricht an. Ein Alarm deckt alle Flüster-Reiter ab. | Dasselbe, aber Nachrichten sprechen steht standardmäßig auf Immer |
| Chat-Eingabefeld geöffnet | Chat | Das Chat-Eingabefeld übernimmt die Tastatur. | Soundalarm |
| Chat-Eingabefeld geschlossen | Chat | Das Chat-Eingabefeld gibt die Tastatur zurück. | Soundalarm |

Eine Nachricht, die mehrere sprechende Reiter erreicht, wird nur einmal gesprochen. Temporäre Chatfenster werden nicht aufgelistet. Siehe [Chat](../windows/chat.md).

### Fehler

| Alarm | Menüpfad | Wann er auslöst | Ausgaben |
|---|---|---|---|
| Fehler ansagen | Fehler | Der Hauptschalter für Fehler- und Infomeldungen des Spiels („Fähigkeit ist noch nicht bereit“, „Außer Reichweite“). Er spricht auch Lua-Fehler und Meldungen, die der Filter nicht einordnen kann. | TTS-Alarm |
| Ein Eintrag für jede Meldung, die du gesehen hast | Fehler, Filter pro Fehler | Diese Meldung erscheint. | TTS-Alarm (an), Soundalarm (aus) |

Der Filter pro Fehler listet jede Meldung mit ihrem Zustand hinter dem Namen: „Sprache“, „Sound“, „Sprache und Sound“ oder „Stumm“. Öffne einen Eintrag, um ihn zu ändern. Das Kontrollkästchen Alle bekannten Fehler anzeigen ganz oben listet jede Meldung auf, die das Spiel kennt, auch solche, denen du noch nicht begegnet bist. Wiederholungsverzögerung (2 Sekunden, 0 bis 30) verhindert, dass derselbe Fehler erneut gesprochen wird, solange du eine Taste hältst. Siehe [Kampf](../world/combat.md).

### Weitere Module

| Alarm | Menüpfad | Wann er auslöst | Ausgaben |
|---|---|---|---|
| Neuer Minikarten-Punkt | Minikarten-Scanner | Beim Laufen kommt ein benannter Punkt auf die Minikarte. Spricht seinen Namen, seine Stufe, ob er drinnen liegt, und seine Art. Braucht Verfolgte Punkte beim Laufen ansagen (an). | TTS (gesprochen von der Spielstimme 0, außer du wählst eine andere Stimme), Soundalarm (aus) |
| Questgebiet (Quest Area Alert) | Quests | Du betrittst das Gebiet einer Quest oder verlässt es. Sagt „Betrete Gebiet: “ oder „Verlasse Gebiet: “, gefolgt vom Questtitel. | TTS, Soundalarm (aus) |
| Gegenstand ausgewählt (Item Selected) | Fenster, Auktionshaus | Du wählst in der Durchsuchen-Liste eine Auktion aus. Sagt „Ausgewählt: “ und den Namen des Gegenstands. (Nur The Burning Crusade.) | TTS |

Siehe [Minikarte](../world/minimap.md) und [Quests](../world/quests.md).

### Monitore

Monitore haben eigene Alarme, einen pro Zustand jeder Regel. Die Regeltypen und ihre Alarme sind:

- Aura-Zustandsregel: Aktiv, Pandemic, Läuft ab und Fehlend.
- Abklingzeit-Zustandsregel: Bereit, Lädt auf und Klingt ab, dazu Aufladung erhalten und Aufladung verbraucht in Classic Era, The Burning Crusade und Mists of Pandaria.
- Aura-Regel des Abklingzeitmanagers (Retail und WoW: Forever): Aktiv, Pandemic (nicht in WoW: Forever, das kein Pandemic-Fenster hat) und Fehlend.
- Zauber-Abklingzeitregel (Retail und WoW: Forever): Bereit, Lädt auf und Klingt ab.
- Zauber-Proc-Regel (Retail und WoW: Forever): Proc und Proc beendet.

Jeder Alarm hat einen Soundalarm und einen TTS-Alarm, und beide Ausgaben sind zunächst aus, ein neuer Monitor ist also stumm, bis du sie einschaltest. Die Seite über Monitore erklärt, wie du sie einrichtest. Siehe [Monitore](../information/monitors.md).

## Tipps

- Du weißt nicht, wie ein Alarm klingt? Öffne seine Ausgabe Soundalarm und gehe mit den Pfeiltasten durch die Sounds: Jeder wird abgespielt, sobald du darauf landest.
- Willst du eine bestimmte Spielmeldung nicht hören, schalte sie mit dem Filter pro Fehler stumm, statt Fehler ansagen auszuschalten.
- Wird ein TTS-Alarm von anderer Sprache zu schnell abgeschnitten, schalte dafür Prioritätsnachricht (unterbricht) ein. Schneidet er ständig alles andere ab, schalte sie aus.

## Siehe auch

- [Das WowVision-Menü und die Einstellungen](./menu-and-settings.md)
- [Sprache und Ton](./speech.md)
- [Kampf](../world/combat.md)
