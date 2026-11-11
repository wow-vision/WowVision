# Bewegung und Orientierung

Diese Seite behandelt die Teile von WowVision, die dir helfen, dich durch die Welt zu bewegen, ohne sie zu sehen: die Kompass- und Blickrichtungsansagen, Gebietsnamen, drinnen und draußen, Schwimm- und Flugalarme, die Fallerkennung, die Wanderkennung, Folgen-Töne, den Leichenlauf, die Kameraeinstellungen, die WowVision verwaltet, und die Neigungssperre.

Alles hier steht im WowVision-Menü (tippe /wv) unter Navigation. Die Routen- und Wegpunktfunktionen des Navigationsfensters (F10) haben eine eigene Seite: [Navigation und Routen](navigation.md). Diese Funktionen haben keine eigenen Tasten, und sie funktionieren in jeder Spielversion, sofern kein Hinweis etwas anderes sagt.

| Menüeintrag | Was er enthält |
|-------------|----------------|
| Navigation | Drei Einstellungen: Automatisch zum Interaktionsziel bewegen (Auto-move to Interact Target), Automatisch zur Leiche navigieren (Automatically Navigate to Corpse) und Verbleibende Wegpunkte ansagen (Announce Remaining Waypoints, beschrieben auf der Seite [Navigation und Routen](navigation.md#was-du-hörst)). Die anderen Einträge unter Navigation (Karten, besuchte Orte, Beacon und so weiter) werden auf der Seite [Navigation und Routen](navigation.md) beschrieben |
| Navigation, Umwelt-Alarme | Alarme für Blickrichtung, Gebiet, drinnen/draußen, Fliegen, Schwimmen, Tauchen und Atem |
| Navigation, Fallerkennung | Fallgeräusche und Ansage |
| Navigation, Wanderkennung | Kollisionsgeräusche |
| Navigation, Folgen | Töne für das Folgen und das Beenden des Folgens |
| Navigation, Neigungssperre | Hält dich im Wasser und in der Luft waagerecht |

Jedes dieser Untermenüs hat oben einen Schalter Aktiviert, sodass sich jede Funktion komplett ausschalten lässt.

## Umwelt-Alarme

Das Modul Umwelt-Alarme beobachtet deinen Charakter und spricht, wenn sich etwas an deiner Umgebung ändert. Jeder seiner Einträge ist ein Alarm (siehe [Alarme](../basics/alerts.md)): Er hat einen Schalter Aktiviert und eine oder mehrere Ausgaben, meist TTS-Alarm (Sprache) und Soundalarm.

| Alarm | Was ihn auslöst | Standardausgabe |
|-------|-----------------|-----------------|
| Kompassrichtung ansagen (Speak Compass Direction) | Du drehst dich in eine andere der acht Richtungen | Stimmenalarm an, TTS-Alarm aus |
| Gebietsänderungs-Alarm (Zone Changed Alert) | Du betrittst ein neues Gebiet | TTS-Alarm an, Soundalarm aus |
| Untergebietsänderungs-Alarm (Subzone Changed Alert) | Du betrittst ein neues Untergebiet (ein Bereich innerhalb eines Gebiets) | TTS-Alarm an, Soundalarm aus |
| Draußen-Alarm (Outdoors Alert) | Du gehst von drinnen nach draußen | TTS-Alarm an, Soundalarm aus |
| Drinnen-Alarm (Indoors Alert) | Du gehst von draußen nach drinnen | TTS-Alarm an, Soundalarm aus |
| Flug-gestartet-Alarm (Flying Started Alert) | Du hebst auf einem Flugreittier ab | TTS-Alarm an, Soundalarm aus |
| Flug-beendet-Alarm (Flying Ended Alert) | Du landest | TTS-Alarm an, Soundalarm aus |
| Schwimm-Alarm (Swimming Alert) | Du gehst ins Wasser | TTS-Alarm an, Soundalarm aus |
| Tauch-Alarm (Diving Alert) | Dein Charakter taucht unter die Oberfläche | TTS-Alarm an, Soundalarm aus |
| Atem-Alarm (Breath Alert) | Eine Atem-, Erschöpfungs- oder Totstellen-Leiste sinkt um einen Schritt | TTS-Alarm an, Stimmenalarm aus, Soundalarm aus |

### Kompassrichtung

Der Kompass sagt "Norden", "Nordwesten", "Westen", "Südwesten", "Süden", "Südosten", "Osten" oder "Nordosten", wann immer die Blickrichtung deines Charakters aus einem dieser acht Sektoren in einen anderen wechselt. Jeder Sektor ist 45 Grad breit und auf seine Richtung zentriert, "Norden" umfasst also 22,5 Grad zu beiden Seiten von genau Norden.

Standardmäßig wird die Richtung aus einem aufgenommenen Stimmenpaket abgespielt (die Ausgabe Stimmenalarm) und nicht per Sprachausgabe gesprochen. Bevorzugst du die Sprachausgabe, schalte TTS-Alarm ein und Stimmenalarm aus. In den Einstellungen des Stimmenalarms kannst du auch ein anderes Stimmenpaket wählen. Siehe [Sprache und Ton](../basics/speech.md).

In manchen Instanzen sagt das Spiel Addons nicht, in welche Richtung du blickst; der Kompass ist dort dann stumm, aber alle anderen Alarme der Tabelle funktionieren weiter.

### Gebiet und Untergebiet

Der "Gebietsänderungs-Alarm" spricht den Gebietsnamen, wenn du in ein neues Gebiet wechselst, zum Beispiel "Wald von Elwynn". Der "Untergebietsänderungs-Alarm" spricht den Namen des Bereichs, zum Beispiel "Goldhain". Hat der Bereich keinen Namen, wird nichts gesagt.

### Drinnen, draußen, Fliegen, Schwimmen, Tauchen

Du hörst "draußen" oder "drinnen", wenn das Spiel entscheidet, dass du von einem zum anderen gewechselt hast, "fliegen", wenn du auf einem Flugreittier abhebst, "Flug beendet", wenn du landest, "schwimmen", wenn du ins Wasser gehst, und "tauchen", wenn du unter die Oberfläche gehst. Wenn du wieder aus dem Wasser läufst, wird nichts gesagt.

### Atem und Erschöpfung

Unter Wasser zeigt das Spiel eine Atemleiste, die sinkt, solange du die Luft anhältst. Schwimmst du zu weit ins tiefe Wasser hinaus, erscheint eine Erschöpfungsleiste. Jäger sehen eine Leiste, während sie sich tot stellen. Der Atem-Alarm sagt den Namen der Leiste und wie voll sie ist, eine Zeile pro Schritt nach unten: "Atem 90", "Atem 80" und so weiter bis "Atem 0", wenn du zu ertrinken beginnst. Während sich die Leiste nach dem Auftauchen wieder füllt, wird nichts gesagt; tauchst du wieder ab, zählen die Schritte von dort herunter, wo die Leiste gerade steht.

Die Schritte sind standardmäßig 10 Prozent. Ändere sie mit Atem-Schritt (5, 10, 20 oder 25 Prozent) im Bildschirm Umwelt-Alarme. Das Spiel zeigt nur die Leiste, nicht die verbleibenden Sekunden, darum sagt WowVision ebenfalls Prozent. Der Atem-Alarm spricht mit einer Spielstimme, damit Bewegungstasten ihn nicht abschneiden.

### Das ändern

Jeder Alarm der Tabelle außer Kompassrichtung ansagen hat einen Soundalarm, und der ist standardmäßig aus. Um statt der Sprache oder zusätzlich dazu einen Ton zu bekommen, öffne den Alarm, schalte Soundalarm ein und wähle mit seiner Einstellung Sound einen Ton.

Beispiel: Du willst einen Ton, wenn du nach drinnen trittst, und keine Sprache.

1. Drücke Umschalt+F1 (oder tippe /wv), gehe zu Navigation, dann Umwelt-Alarme, dann Drinnen-Alarm.
2. Schalte TTS-Alarm aus.
3. Schalte Soundalarm ein und wähle mit Sound einen Ton.

## Fallerkennung

Wenn du fällst, spielt WowVision eine aufsteigende Tonfolge, die dir sagt, wie lange du schon fällst: Je länger der Fall, desto weiter ist die Folge hinaufgeklettert. Außerdem sagt es einmal "Fallen", wenn die Töne beginnen. Die Töne sind dieselben wie in Sku. Nach etwa fünf Sekunden hat die Folge ihr Ende erreicht.

Einstellungen unter Navigation, Fallerkennung:

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Verzögerung (Millisekunden) | 200 | Wie lange du schon fallen musst, bevor etwas abgespielt wird, von 0 bis 1000. Ein höherer Wert blendet kurze Sprünge nach unten aus |
| Sprünge ignorieren | An | Ein Fall, der innerhalb von knapp einer Sekunde nach dem Drücken der Sprungtaste beginnt, bleibt stumm, damit gewöhnliche Hüpfer keine Töne spielen. Ein tiefer Fall löst trotzdem einmal aus, sobald dieser Moment vorbei ist |
| Fallerkennung (Alarm) Aktiviert | An | Schaltet die ganze Funktion ein oder aus |
| Fallgeräusch | An | Die aufsteigenden Töne. Schalte es aus, um nur die Ansage zu behalten |
| Fallansage | An | Spricht einmal "Fallen" zu Beginn der Töne |

Wasser zählt nicht als Fall: Ein Fall, der beginnt, während du schwimmst, oder kurz nachdem du das Wasser verlassen hast (zum Beispiel durch einen Sprung heraus), bleibt bis zur Landung stumm.

Beispiel: Du läufst von einem Vorsprung. Nach einer Fünftelsekunde hörst du "Fallen" und den ersten Ton. Die Töne steigen, während du fällst. Wenn du landest, hören sie auf.

## Wanderkennung

Die Wanderkennung sagt dir, dass du gegen etwas drückst. Solange du dich bewegst, sich deine Position aber kaum ändert, spielt WowVision ein kurzes Klonk. Je stärker du zurückgehalten wirst, desto mehr klingt es nach hartem Anschlag. Das ist dasselbe System wie das von Sku, mit denselben Tönen.

So funktioniert es: Alle paar Sekundenbruchteile vergleicht WowVision, wie weit du dich tatsächlich bewegt hast und wie weit dich deine Geschwindigkeit hätte bringen müssen, und stuft die Differenz in fünf Stufen ein:

| Stufe (Soundausgabe) | Bedeutung |
|----------------------|-----------|
| Blockiert (Blocked) | Du hast weniger als ein Viertel der Strecke zurückgelegt, die du hättest schaffen sollen: Du stehst an einer Wand |
| Größtenteils blockiert (Mostly Blocked) | Zwischen 25 und 45 Prozent |
| Behindert (Impeded) | Zwischen 45 und 60 Prozent |
| Verlangsamt (Slowed) | Zwischen 60 und 85 Prozent |
| Leicht verlangsamt (Slightly Slowed) | Zwischen 85 und 100 Prozent: Etwas steht dir nur leicht im Weg |

Ein Ton wird erst gespielt, wenn drei Prüfungen in Folge behindert sind (etwa alle halbe Sekunde), sodass dauerndes Drücken einen gleichmäßigen Klonk-Rhythmus ergibt und kein Brummen. Sobald du dich frei bewegst, beginnt der Rhythmus von vorn.

Worum es sich kümmert:

- Es folgt deinen Bewegungsbefehlen, egal welche Tasten du zum Bewegen belegt hast. Automatisches Laufen zählt auch als Bewegung.
- Es deckt auch Wege ab, die das Spiel für dich geht: wenn du die Interaktionstaste drückst und das Spiel dich zu einem NPC laufen lässt, oder wenn du Klicken-zum-Bewegen benutzt. Endet ein solcher Weg, bevor er sein Ziel erreicht (du bist an etwas hängen geblieben), wird der Ton Blockiert einmal gespielt.
- Betäubt, festgewurzelt, in Furcht versetzt oder anderweitig die Kontrolle verloren zu haben wird nie als Wand gemeldet, und solange du auf einem Flugweg bist, wird nichts eingestuft.
- Greifst du mit der Interaktionstaste an, läuft dein Charakter dem Gegner den ganzen Kampf über hinterher. Sobald du im Kampf bist, bleibt die Wanderkennung dabei still, solange dein automatischer Angriff läuft und du keine Bewegungstaste drückst. Auf dem Weg zum Gegner, bevor der Kampf beginnt, warnt sie bei einem Hindernis wie immer, und ebenso, wenn du eine Bewegungstaste drückst.
- Beim Schwimmen wird deine Schwimmgeschwindigkeit zum Vergleich benutzt.
- (Nur Retail und WoW: Forever) Im Kampf verbirgt das Spiel deine Bewegungsgeschwindigkeit, sodass nur ein völliger Stillstand bemerkt werden kann: Du hörst den Ton Blockiert, aber keine der langsameren Stufen.

Einstellungen: Öffne Navigation, Wanderkennung, dann Wanderkennung (der Alarm).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert | An | Schaltet die Wanderkennung ein oder aus |
| Blockiert, Größtenteils blockiert, Behindert, Verlangsamt, Leicht verlangsamt | Alle an | Fünf Soundausgaben, jede mit eigenem Schalter Aktiviert und eigener Auswahl Sound, sodass du zum Beispiel nur die zwei härtesten behalten kannst |

## Folgen

Wenn du einem anderen Spieler folgst (die Folgen-Funktion des Spiels), spielt WowVision einen kurzen Ton, wenn das Folgen beginnt, und einen anderen, wenn es endet. Das Folgen endet auch von selbst, wenn der andere Spieler außer Reichweite gerät, und dann hörst du den Stopp-Ton. Wie im Spiel beendet auch manuelles Bewegen das Folgen.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Sound bei Folgen oder Entfolgen abspielen | An | Spielt die zwei Töne. Schalte es für stilles Folgen aus |

## Interagieren: Automatisch zum Interaktionsziel bewegen

Im Menü Navigation selbst:

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Automatisch zum Interaktionsziel bewegen | An | Schaltet die eigene Option "Klicken-zum-Bewegen" des Spiels ein (in den Spieloptionen, englisch "Click to Move"). Ist sie an, lässt dein Charakter beim Interagieren mit einem Ziel außer Reichweite, zum Beispiel mit der Interaktionstaste, zuerst zu ihm hinlaufen |

WowVision schaltet das standardmäßig ein, weil neue Spieler es sonst schwer finden, NPCs zu erreichen. WowVision setzt die Option des Spiels bei jedem Login passend dazu; ändere es also hier und nicht in den Optionen des Spiels.

## Leichenlauf

Wenn du stirbst und deinen Geist freilässt, kann WowVision beginnen, dich zu deiner Leiche zu führen. Das geschieht auch, wenn du dich als Geist einloggst oder neu lädst.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Automatisch zur Leiche navigieren | An | Nachdem du deinen Geist freigelassen hast, beginnt sofort eine Route zu deiner Leiche |

Das passiert: Du lässt deinen Geist frei; WowVision schlägt nach, wo deine Leiche ist, zuerst auf deiner aktuellen Karte und dann auf den größeren Karten darum herum (so wird eine Leiche gefunden, die im Gebiet neben dem Friedhof liegt, an dem du erwacht bist), und sagt "Leiche". Dann beginnt es eine Route dorthin, genau so, als hättest du die Leiche im Navigationsfenster ausgewählt. Wo WowNav-Routendaten verfügbar sind (WoW: Forever), wird eine Leiche, die über mehrere Ebenen liegt, zur niedrigsten erreichbaren Ebene geroutet. Findet sich keine Route, zeigt stattdessen ein Beacon direkt auf die Leiche. Der Route wird wie jeder anderen gefolgt; siehe [Navigation und Routen](navigation.md), wie Routen und die Beacon-Töne funktionieren.

Details:

- Direkt nach einem Ladebildschirm weiß das Spiel vielleicht nicht, wo die Leiche ist, deshalb fragt WowVision einige Sekunden lang erneut nach (bis zu achtmal, einmal pro Sekunde), bevor es aufgibt. Gibt es auf, kannst du die Leiche trotzdem mit dem Scanner finden: Drücke F9 und wähle den Leichen-Eintrag unter Spieler. Siehe [Scanner](scanner.md).
- Die Leiche wird nur dann angesteuert, wenn sie auf dem Kontinent liegt, auf dem du bist. Eine Leiche in einer Instanz wird von außen nicht angelaufen.
- Das Ausschalten der Einstellung stoppt den Scanner-Eintrag nicht; es stoppt nur die automatische Route.

## Kamera

Das Drehen zu einem Wegpunkt und die Neigungssperre unten steuern deinen Charakter, indem sie die Spielkamera bewegen. Damit das zuverlässig funktioniert, setzt WowVision zwei Kameraoptionen des Spiels einmal pro Charakter, beim ersten Login mit dem Addon:

- Der Kamera-Folgemodus wird zu "Kamera immer anpassen" (Always adjust camera), was bedeutet, dass die Kamera immer hinter deinem Charakter bleibt.
- Das Wechseln zwischen gespeicherten Kameraansichten geschieht sofort.

Wenn es eine dieser Optionen ändert, gibt WowVision im Chat diese Meldung aus: "WowVision set the camera to always follow behind your character, which turning to waypoints needs. You can change the camera following style in the game options under Controls." (Meldung auf Englisch; in den deutschen Spieloptionen findest du den Kamera-Folgemodus unter "Steuerung".) Änderst du den Folgemodus danach wieder zurück, ändert WowVision ihn für diesen Charakter nicht noch einmal.

WowVision benutzt außerdem Kameraansicht-Platz 5, eine der fünf Ansichten, die das Spiel dich speichern lässt. Es setzt zurück und springt auf diesen Platz, um die Kamera gerade hinter deinen Charakter und beinahe waagerecht zu stellen. Benutzt du selbst Ansicht 5 speichern (Save View 5), überschreibt WowVision sie; nimm für deine eigenen Ansichten einen anderen Platz.

Mit einem Gamepad in Retail und WoW: Forever schaltet WowVision den freien Blick des Gamepads kurz aus, während du dich zu einem Wegpunkt drehst, und danach wieder ein. Siehe [Controller](../controller.md).

## Neigungssperre

Wenn du schwimmst oder fliegst, kippte früher jede Drehung zu einem Wegpunkt die Nase deines Charakters leicht nach unten, bis du langsam im Sturzflug warst und keine Taste das mehr korrigieren konnte. Die Neigungssperre (Pitch Lock) verhindert das, indem sie deinen Charakter waagerecht hält, solange du im Wasser oder in der Luft bist. Sie ist standardmäßig an.

- Sie greift von selbst ein, wenn du zu schwimmen (oder zu fliegen) beginnst, und lässt los, sobald du auf dem Land oder auf einem Flugweg bist. Du hörst nichts.
- Leertaste (nach oben schwimmen, aufsteigen) und X (nach unten schwimmen, absinken) funktionieren weiter; du verlierst keine vertikale Bewegung.
- Bist du bereits geneigt, bringt dich Folgendes wieder in die Waagerechte: das Drücken von Leertaste oder X, das Öffnen des Fensters eines NPCs, nachdem das Spiel dich durchs Wasser zu ihm geführt hat (Gesprächs-, Quest- oder Händlerfenster), und die Taste, die dich zum Wegpunkt dreht (standardmäßig I), wenn du ihn schon ansiehst. Das alles stützt sich auf Kameraansicht-Platz 5.
- Sie funktioniert im Kampf.
- Fliegen: In Classic Era, The Burning Crusade und Mists of Pandaria hält die Sperre auch, während du fliegst. (Retail und WoW: Forever) Die Sperre wird nur beim Schwimmen gehalten, weil Skyriding über die Neigung gesteuert wird.
- Um über die Neigung zu tauchen und zu steigen, schalte die Neigungssperre aus: Öffne Navigation, Neigungssperre und schalte Aktiviert aus. Die Sperre lässt sofort los.

Das Spiel lässt Addons die Neigungsgrenze nicht zurücklesen, deshalb setzt WowVision sie auf den normalen Wert des Spiels, wann immer du die Welt betrittst, ohne dass die Sperre gehalten wird.

## Diagnosebefehle

Keine dieser Funktionen hat einen Befehl, aber wenn eine Bewegungstaste nach dem Öffnen eines Fensters oder dem Ende eines Kampfes festzuhängen scheint, protokolliert /wv keylog, wann WowVision seine Tasten übernimmt und freigibt. Siehe [Kampf](combat.md). Probleme beim Drehen zum Wegpunkt behandelst du mit /wv turnlog, beschrieben auf der Seite [Navigation und Routen](navigation.md).

## Verwandte Seiten

- [Navigation und Routen](navigation.md): Routen, Wegpunkte, das Beacon und das Drehen zu Wegpunkten.
- [Kampf](combat.md): was im Kampf mit den Tasten von WowVision passiert.
- [Alarme](../basics/alerts.md): Ausgaben, Töne und Stimmen.
