# Navigation und Routen

WowVision kann dich zu Fuß an einen Ort führen. Im Navigationsfenster (F10) wählst du, wo du startest und wohin du willst. WowVision berechnet eine Route entlang bekannter Wege, und ein akustisches Beacon führt dich dann von Wegpunkt zu Wegpunkt, bis du ankommst. Diese Seite behandelt das Navigationsfenster, das Beacon und alle Tasten, die du beim Gehen einer Route benutzt.

Hinweis: Die Ansagen dieser Seite kommen aus lokalisierten Texten und werden auf einem deutschen Client auf Deutsch gesprochen. Die Beispiele zeigen, was du hörst. Namen von Orten, NPCs und Objekten stammen aus den Spieldaten und bleiben so, wie sie dort stehen.

## Kurz gefasst

1. Drücke F10, um das Navigationsfenster zu öffnen.
2. Wähle deinen Einstiegspunkt: den Ort im Netz der bekannten Wege, an dem deine Route beginnt. Der nächstgelegene ist schon für dich ausgewählt.
3. Suche ein Ziel und drücke Eingabe darauf.
4. WowVision sagt, wie viele Wegpunkte die Route hat und wie lang sie ist, und ein Beacon beginnt zu pingen.
5. Dreh dich zum Beacon, geh los und hör zu. Jeder Wegpunkt, den du erreichst, spielt einen kurzen Ton, und das Beacon wandert zum nächsten. Am Ende hörst du "Angekommen" und den Namen des Ortes.

Du kannst auch ein Beacon in gerader Linie ganz ohne Route setzen: mit dem Kontrollkästchen Direkt im Fenster, im Scanner oder mit dem Befehl /beacon.

## Welche Routen du hast

Routen brauchen Kartendaten: ein Netz aus Wegpunkten, die miteinander verbunden sind, plus die Namen der Orte, zu denen du gehen kannst. WowVision hat zwei Routensysteme, jedes mit eigenen Daten. Welches du hast, hängt von deiner Spielversion ab:

| Spielversion | Routen |
|--------------|--------|
| WoW: Forever | [WowNav](./wownav.md), standardmäßig an. Du kannst es ausschalten und stattdessen die klassischen Routen benutzen. |
| The Burning Crusade | [Klassische Routen](#klassische-routen). |
| Classic Era | Klassische Routen, wenn das Spiel ihre Kartendaten lädt; siehe [Kartendaten](#kartendaten). |
| Mists of Pandaria und Retail | Hier sind keine Kartendaten enthalten. Das Navigationsfenster öffnet sich, aber seine Listen sind leer. Beacon in gerader Linie, /beacon, die Entfernungsansage und alle anderen Tasten dieser Seite funktionieren trotzdem. |

Beide Systeme benutzen dasselbe Fenster, dieselben Tasten und dasselbe Beacon. Diese Seite gilt also für beide und sagt es, wo sie sich unterscheiden. Was jedes von ihnen ausmacht, steht weiter unten unter [Klassische Routen](#klassische-routen) und auf der Seite [WowNav (WoW: Forever)](./wownav.md).

Die Beispiele auf dieser Seite benutzen die schlichten Ortsnamen von WowNav. Klassische Routen lesen Namen in einer längeren Form; siehe [Ortsnamen](#ortsnamen).

## Das Navigationsfenster (F10)

Drücke F10, um das Navigationsfenster zu öffnen. Mit Esc schließt du es. Auf einem Controller halte beide Schultertasten gedrückt und drücke Steuerkreuz hoch (siehe [Controller](../controller.md)). Kann das Spiel WowVision nicht sagen, wo du bist (zum Beispiel in einer Instanz auf Retail), bleibt das Fenster leer.

Drückst du F10, während du im Questlog bist, öffnet sich das Fenster auf das nächste Ziel dieser Quest ausgerichtet, denselben Ort, zu dem Eingabe auf der Quest im Scanner führt: das nächste Ziel ihres ersten offenen Questziels, oder die Abgabe, sobald sie fertig ist. Dieses Ziel steht oben in der Zielliste und ist ausgewählt, Eingabe startet also die Route. Die Quest ist die, auf der dein Cursor im Questlog steht, sonst die, deren Details offen sind. Eine Quest ohne Ort, oder ein Ort ohne Routendaten, öffnet das Fenster wie gewohnt.

Das Fenster hat vier Stationen. Zwischen ihnen wechselst du mit Tab und Umschalt+Tab, innerhalb einer Liste bewegst du dich mit Pfeil hoch und Pfeil runter. Die allgemeinen Tasten stehen auf der Seite [Die Oberfläche bedienen](../basics/interface.md).

| Station | Was es ist |
|---------|------------|
| Direkt | Ein Kontrollkästchen. Bei jedem Öffnen des Fensters aus. |
| Einstiegspunkte | Die nächsten Punkte des Wegnetzes: 20 bei klassischen Routen, 50 mit WowNav. Nicht sichtbar, solange Direkt an ist. |
| Suchen | Ein Textfeld, das die Zielliste filtert. |
| Ziele | Die Liste der Orte, zu denen du gehen kannst. |

Wenn sich das Fenster öffnet, landest du auf dem Einstiegspunkt, der schon ausgewählt ist, du kannst also oft gleich zur Suche springen.

### Einstiegspunkte

Der Einstiegspunkt ist die Stelle, an der deine Route ins Netz einmündet. WoW ist völlig dreidimensional, und so ist der nächste Wegpunkt manchmal die Straße unter einer Brücke oder der Boden unter dir. Deshalb listet WowVision die nächsten auf und lässt dich wählen.

Jeder Eintrag liest seinen Namen, seine Entfernung und die Richtung relativ zu deiner Blickrichtung, zum Beispiel "Innkeeper Allison (Innkeeper), 4 Meter, voraus links". Die Richtungen sind voraus, voraus rechts, rechts, hinten rechts, hinten, hinten links, links und voraus links. Der gewählte Eintrag wird mit ausgewählt angesagt.

- Der nächste Einstiegspunkt ist beim Öffnen des Fensters ausgewählt.
- Drücke Eingabe auf einem anderen Eintrag, um stattdessen diesen zu wählen. Du hörst sofort ausgewählt, und wieder jedes Mal, wenn du auf ihn zurückkehrst. Es ist immer nur ein Eintrag ausgewählt.
- Während du schwimmst oder tauchst, ist stattdessen der nächste Eintrag vorgewählt, der im Wasser liegt, falls die Daten Wasserpunkte kennen. Mit WowNav hörst du "Kein Wasserpunkt in der Nähe", wenn kein Wasserpunkt in der Nähe ist. In den klassischen Daten gibt es keine Wasserpunkte, dort bleibt also der nächste Eintrag gewählt.

Die Route, die du bekommst, enthält den Weg von deinem Standort bis zum Einstiegspunkt. Wähle also einen Einstiegspunkt, zu dem du wirklich gehen kannst.

### Direkt

Hake Direkt an (drücke Eingabe auf dem Kontrollkästchen), wenn du keine Route willst. Die Einstiegspunkte verschwinden, und Eingabe auf einem Ziel setzt ein gerades Beacon genau auf diesen Punkt. Du hörst zum Beispiel "Direkt: Innkeeper Allison (Innkeeper), 120 Meter" und bei der Ankunft "Angekommen" und den Namen. Nutze das, wenn du schon nah dran bist, wenn du in einem Gebäude bist, das das Netz nicht kennt, oder wenn du in gerader Linie irgendwohin willst.

Direkt ist die erste Station. Um dorthin zu kommen, drücke Umschalt+Tab von den Einstiegspunkten aus.

### Nach einem Ziel suchen

Drücke Tab von den Einstiegspunkten aus, um zu Suchen zu kommen. Das Eingabefeld nimmt deine Eingabe sofort an, und was du tippst, wird beim Tippen vorgelesen. Tippe ein Namensstück, zum Beispiel "Auktionator", und drücke Eingabe, um es anzuwenden. WowVision liest vor, was du getippt hast. Die Liste darunter wird sofort gefiltert. Tab wendet den Text ebenfalls an und geht zur nächsten Station weiter; Esc schließt das Eingabefeld, ohne die Suche zu ändern.

- Die Suche unterscheidet nicht zwischen Groß- und Kleinschreibung und findet jeden Teil des Textes eines Ortes. Es ist ein einziges Textstück, keine mehreren Wörter: "Auktionator Sturmwind" findet nichts, aber "Auktionator" oder "Sturmwind" funktionieren jeweils einzeln.
- Mit WowNav ist dieser Text der Name auf Englisch und Deutsch, die Kategorien des Ortes und sein Gebiet. Bei klassischen Routen ist es der ganze lange Name, einschließlich der Rolle, des Gebiets und der Zahlen.
- Lass das Feld leer, um alles auf deinem Kontinent aufzulisten, mit WowNav bis zu den nächsten 1000 Orten.
- Die Suche umfasst alle Kartendaten des Kontinents, auf dem du bist, Routen können also das Gebiet verlassen, in dem du stehst.

### Ziele

Drücke noch einmal Tab, um zu Ziele zu kommen. Es ist eine einzige lange Liste, sortiert nach der Entfernung von dem Ort, an dem du das Fenster geöffnet hast, das nächste zuerst. Sie kann sehr lang sein (bis zu 1000 Einträge mit WowNav, Zehntausende bei klassischen Routen) und funktioniert deshalb wie ein einziges Bedienelement und nicht wie eine echte Liste aus Einzelelementen:

| Taste | Was sie tut |
|-------|-------------|
| Pfeil hoch / Pfeil runter | Vorheriges / nächstes Ziel. |
| Pos1 / Ende | Erstes / letztes Ziel. |
| Eingabe | Das Fenster schließen und die Route starten (oder das gerade Beacon, wenn Direkt an ist). |

Jedes Ziel liest seinen Namen und seine Entfernung, dann seine Position in der Liste. Mit WowNav kommt nach der Entfernung, was der Ort ist und wo er ist, zum Beispiel "Innkeeper Allison (Innkeeper), 85 Meter, Questgeber, Händler, Gastwirt, Stormwind City, 1 von 342". Ein Ziel, das du in den letzten Minuten erreicht hast, wird mit Besucht davor angesagt; siehe [Besuchte Orte](#besuchte-orte). Eine leere Liste liest "Leer".

Wenn du Eingabe drückst, hörst du die Zusammenfassung der Route, zum Beispiel "12 Wegpunkte, 340 Meter". Die Meter schließen den Weg zu deinem Einstiegspunkt ein. Die Zusammenfassung kann noch mehr darüber sagen, wie die Route endet: siehe [Das letzte Stück](#das-letzte-stück) für klassische Routen und [WowNav (WoW: Forever)](./wownav.md#eine-route-starten-und-ihr-folgen). Stimmt etwas nicht, hörst du Keine Route gefunden, manchmal gefolgt von einem kurzen Grund wie "nicht erreichbar" (kein Weg führt von deinem Einstiegspunkt dorthin) oder "kein Einstieg".

### Vom Scanner aus

Im Scanner ([Scanner](./scanner.md)) öffnet Eingabe auf einer Quest, einem NPC oder einem anderen Eintrag mit Ort das Navigationsfenster, schon auf diesen Eintrag ausgerichtet. Der nächste Einstiegspunkt und der Eintrag des Scanners als Ziel sind beide ausgewählt, und der Fokus liegt auf dem Ziel. Drücke Eingabe, um dorthin zu routen; willst du einen anderen Einstiegspunkt, drücke vorher zweimal Umschalt+Tab. Ohne Kartendaten für den Kontinent setzt der Scanner direkt ein gerades Beacon und öffnet das Fenster nicht.

## Einer Route folgen

### Was du hörst

Wenn die Route beginnt, spricht WowVision die Zusammenfassung, und das Beacon beginnt zu pingen. Die Wegpunkte werden nicht einzeln vorgelesen. Stattdessen hörst du sie:

- Das Beacon pingt in Richtung des aktuellen Wegpunkts. Der Ping ändert sich mit der Richtung und der Entfernung zum Wegpunkt. Er pingt schneller, je direkter du auf den Wegpunkt blickst: etwa alle 0,7 Sekunden, wenn du vom Kurs abweichst, und etwa alle 0,3 Sekunden, wenn du darauf ausgerichtet bist. Die Entfernung hörst du in Schritten von etwa 6 Metern, und sie reicht bis ungefähr 180 Meter.
- Beacon ausgerichtet (ein Klack) spielt, wenn du dich bis auf 10 Grad zum Wegpunkt gedreht hast. Beacon abseits des Kurses (ein Klick) spielt, wenn du dich wieder abwendest. Diese Töne spielen nur, wenn du diese Linie durch Drehen überschreitest.
- Wegpunkt erreicht (ein Erfolgston) spielt jedes Mal, wenn du nah genug an einen Wegpunkt kommst, auch beim letzten.
- Gleich nach dem Ton sagt WowVision, wie viele Wegpunkte noch übrig sind, zum Beispiel "noch 3". Der Wegpunkt, zu dem das Beacon jetzt führt, zählt mit. Am letzten Wegpunkt hörst du stattdessen Angekommen, und an einem Portal, der Tiefenbahn oder einem Aufzug auf einer WowNav-Route die eigenen Ansagen von WowNav. Das gilt für klassische Routen und WowNav-Routen gleichermaßen. Die Einstellung Verbleibende Wegpunkte ansagen (Announce Remaining Waypoints) im Modul Navigation (standardmäßig an) schaltet es aus.
- Angekommen wird am Ende einer Route gesprochen, gefolgt vom Namen des Ziels.
- Beacon gestoppt wird gesprochen, wenn du abbrichst.

Ein Wegpunkt gilt als erreicht, wenn du innerhalb der Ankunftsdistanz von ihm bist (siehe [Ankunftsdistanz](#ankunftsdistanz)). Mit WowNav kann ein Wegpunkt auch eine eigene, größere Distanz haben.

### Beacon-Töne

Alle Beacon-Töne sind ein einziger Alarm namens Beacon im Modul Beacon und Routen (WowVision-Menü, Navigation, Beacon und Routen, Beacon). Der Alarm und jeder seiner vier Töne haben einen eigenen Schalter Aktiviert und einen eigenen Sound, sodass sich jedes Beacon einzeln ausschalten oder ändern lässt. Wie Alarme funktionieren, steht auf der Seite [Alarme](../basics/alerts.md).

| Ton | Standard | Wann er spielt |
|-----|----------|----------------|
| Beacon-Ton (Beacon Sound) | Probe (Mid) | Der gerichtete Ping zum aktuellen Wegpunkt. |
| Beacon ausgerichtet (Beacon Aligned) | Klack | Du hast dich zum Wegpunkt gedreht. |
| Beacon abseits des Kurses (Beacon Off Course) | Klick | Du hast dich vom Wegpunkt abgewendet. |
| Wegpunkt erreicht (Waypoint Reached) | Erfolgston | Du hast einen Wegpunkt erreicht. |

Für Beacon-Ton wählst du eines der Beacon-Sets: Notification, Probe (Deep), Probe (Mid), Steel Gong und Beacon 6 (Skus Beacon 6). Wenn du in der Auswahl auf einen Eintrag gehst, spielt eine Hörprobe. Bei den anderen drei wählst du einen beliebigen Sound aus der Soundliste.

### Tasten beim Gehen

| Taste | Name der Belegung | Was sie tut |
|-------|-------------------|-------------|
| I | Zum Wegpunkt drehen | Dreht deinen Charakter zum aktuellen Wegpunkt. Siehe unten. |
| Alt Gr oder Strg+Alt | (Einstellung) | Spricht die Entfernung zum aktuellen Wegpunkt. Gehalten wiederholt sie sich jede Sekunde. |
| Standardmäßig nicht belegt | Entfernung ansagen | Dieselbe Entfernungsansage auf einer Taste deiner Wahl. |
| Alt+P | Ankunftsdistanz wechseln | Wechselt zwischen kurzer, mittlerer und weiter Ankunftsdistanz. |
| Strg+W | Nächster Wegpunkt | Springt zum nächsten Wegpunkt. |
| Strg+S | Vorheriger Wegpunkt | Geht zum vorherigen Wegpunkt zurück. |
| Strg+Umschalt+N | Route von hier neu starten | Startet die letzte Route von deinem Standort aus neu. |
| Strg+Umschalt+R | Route umkehren (Reverse Route) | Kehrt die laufende Route um, zurück zu ihrem Start. |
| Umschalt+F12 | Navigation abbrechen | Beendet die Route oder das Beacon. |
| F10 | Navigation | Öffnet das Navigationsfenster. |

All das lässt sich im Fenster für die Tastenbelegung ändern (WowVision-Menü, Benutzeroberfläche, Tastenbelegung); siehe [Tastenbelegung](../basics/keybindings.md). Die vollständige Liste steht in der [Tastenreferenz](../reference/keybindings.md).

### Zum Wegpunkt drehen (I)

Addons können deinen Charakter nicht direkt drehen, deshalb dreht WowVision die Kamera und gibt die neue Richtung an deinen Charakter weiter. Drücke I, während du einer Route folgst, und dein Charakter dreht sich zum aktuellen Wegpunkt. Die Drehung dauert ein paar Frames und funktioniert im Stehen und im Gehen; wenn du dich bewegst, zielt sie auf die Stelle, an der der Wegpunkt am Ende der Drehung sein wird, sodass du nicht um einen Wegpunkt kreist, den du gleich erreichst.

Wenn es klappt, wird nichts gesprochen. Ein paar Dinge solltest du wissen:

- Blickst du schon zum Wegpunkt (auf etwa 3 Grad genau), dreht der Tastendruck nichts. Während du schwimmst oder fliegst und die Neigungssperre an ist, richtet er stattdessen deinen Charakter waagerecht aus; siehe [Bewegung und Orientierung](./movement.md).
- Ein Tastendruck, während noch eine Drehung läuft, wird ignoriert. Drückst du selbst eine Drehtaste, stoppt die Drehung dort, wo sie gerade ist.
- Ohne Route hörst du Kein aktiver Wegpunkt. (Die Ausnahme ist WowNav an einem Anleger oder einer Tiefenbahn-Haltestelle; siehe [WowNav (WoW: Forever)](./wownav.md).)
- Wo das Spiel deine Position und Blickrichtung vor Addons verbirgt (Instanzen auf Retail), hörst du Drehen ist hier nicht möglich.
- Auf einem Controller drücke statt I den Rechten Stickklick.

Das Drehen braucht zwei Kameraeinstellungen: den Kamera-Folgestil Immer (die Spieloption "Always adjust camera" des englischen Clients) und das sofortige Umschalten zwischen gespeicherten Kameraansichten. WowVision stellt beides einmal pro Charakter ein, beim ersten Login, bei dem eine der beiden geändert werden musste, und sagt dir das im Chat: "WowVision hat die Kamera so eingestellt, dass sie immer hinter deinem Charakter bleibt; das Drehen zum Wegpunkt braucht das. Den Kamera-Folgestil kannst du in den Spieloptionen unter Steuerung ändern." Stellst du den Folgestil später wieder zurück, landen die Drehungen an den falschen Stellen. WowVision stellt ihn nicht noch einmal ein. WowVision benutzt außerdem die gespeicherte Kameraansicht 5 zum Drehen, alles, was du dort gespeichert hast, wird also überschrieben. Während einer Drehung ändert es kurz die Mausblick-Geschwindigkeit des Spiels und setzt deinen eigenen Wert danach wieder ein. Mit einem Gamepad ist der freie Blick für die Dauer der Drehung ausgeschaltet.

### Ankunftsdistanz

Die Ankunftsdistanz (Arrival Distance) gibt an, wie nah du in Metern an einen Wegpunkt kommen musst, damit er als erreicht gilt. Eine kleine Distanz zwingt dich, jeden Punkt genau zu treffen; eine große verzeiht Umwege. WowVision hat drei Werte, von denen jeweils einer aktiv ist. Er gilt für die klassischen Routen und für WowNav. Mit WowNav nimmt ein Wegpunkt, der in den Daten eine eigene, größere Distanz hat, diese; siehe [WowNav (WoW: Forever)](./wownav.md#eine-route-starten-und-ihr-folgen).

| Name | Standarddistanz |
|------|-----------------|
| Kurze Distanz (Short Range) | 0,3 Meter |
| Mittlere Distanz (Medium Range) | 1 Meter (standardmäßig aktiv) |
| Weite Distanz (Long Range) | 3 Meter |

Drücke Alt+P, während du einer Route folgst, um der Reihe nach durch kurz, mittel, weit und wieder zurück zu kurz zu schalten. WowVision spricht den Namen und die Distanz, zum Beispiel "Weite Distanz, 3 Meter". Nimm die kurze Distanz an engen Stellen wie einer Tür und die weite Distanz im offenen Gelände. Die Einstellungen stehen unter [Einstellungen](#einstellungen). Dort ändern Pfeil links und Pfeil rechts jede Distanz um 0,1 Meter, und mit Eingabe tippst du eine ein, zum Beispiel 0,5.

### Entfernung ansagen

Alt Gr spricht die Entfernung in Metern zu dem Wegpunkt, zu dem du gerade gehst, zum Beispiel "120 Meter", genau wie in Sku. Windows meldet Alt Gr als gleichzeitig gedrücktes Strg und Alt, deshalb tut Strg+Alt dasselbe. Hältst du die Tasten gedrückt, wird die Entfernung beim Gehen jede Sekunde wiederholt. Nur die Sprache transportiert sie; in den Chat wird nichts geschrieben.

- Ohne Route hörst du Kein aktiver Wegpunkt; kann das Spiel deine Position nicht liefern, hörst du Position nicht verfügbar.
- Während du in einem Eingabefeld tippst, bleibt sie stumm, sodass Zeichen, die du mit Alt Gr tippst (wie @, { oder [), nichts sprechen. Sie ist auch stumm, solange Umschalt gedrückt ist.
- Jedes andere Tastenkürzel mit Strg+Alt löst die Ansage ebenfalls aus. Stört dich das, schalte die Einstellung Entfernung mit Alt Gr ansagen aus und lege die Belegung Entfernung ansagen auf eine Taste, die du sonst nicht benutzt.

### Nächster und vorheriger Wegpunkt

Bist du vom Weg abgekommen oder willst du einen Wegpunkt überspringen, den du nicht erreichen kannst, drücke Strg+W, um das Beacon zum nächsten Wegpunkt zu verschieben, oder Strg+S, um einen zurückzugehen. Der Schritt spielt den Ton für "Wegpunkt erreicht" und spricht, wie viele Wegpunkte noch bleiben, den aktuellen eingeschlossen, zum Beispiel "4 verbleibend". An den Enden hörst du Ende der Route oder Anfang der Route; nur das Gehen zum letzten Wegpunkt beendet die Route. Ohne Route hörst du Kein aktiver Wegpunkt.

### Die Route neu starten

Bist du weit von der Route abgekommen, drücke Strg+Umschalt+N. WowVision plant das zuletzt gewählte Ziel neu, ausgehend von dem Ort, an dem du jetzt stehst. Das funktioniert für Ziele aus dem Fenster, aus dem Scanner, von der Route zu deinem Ziel und für den Leichenlauf. Bei klassischen Routen nimmt der Router von den fünf nächsten Wegpunkten denjenigen, der die beste Route ergibt. Mit WowNav beginnt die Route dort, wo du stehst, wenn WowNav weiß, auf welcher Ebene du bist. Du hörst wieder die Zusammenfassung der Route, oder Keine Route zum Neustarten, wenn du noch kein Ziel gewählt hast.

### Die Route umkehren

Auf halber Strecke fällt dir ein, dass du noch einmal zurückmusst. Drücke Strg+Umschalt+R. Die Route kehrt sich um: Der Wegpunkt, zu dem das Beacon gerade führt, wird zum Start einer neuen Route, und ihr Ziel ist der Ort, an dem die vorherige Route begann, also der Einstiegspunkt, den du im Navigationsfenster gewählt hast. Du hörst "Route umgekehrt, zurück zu" und den Namen dieses Ortes, danach die Zusammenfassung der neuen Route. Ein Beispiel: Auf dem Weg von Priesterin Anetta zu Marschall Dughan drückst du Strg+Umschalt+R und hörst "Route umgekehrt, zurück zu Priesterin Anetta". Hat der Start keinen Namen, hörst du "zurück zu dem Start der vorherigen Route".

Das gilt für klassische Routen und WowNav-Routen gleichermaßen. Danach führt Strg+Umschalt+N wieder zu diesem Start. Ohne laufende Route hörst du "Keine Route zum Umkehren".

### Navigation abbrechen

Umschalt+F12 beendet die Route oder das gerade Beacon: Du hörst Beacon gestoppt, und die Pings hören auf. Läuft nichts, hörst du Kein aktiver Wegpunkt. /beacon stop tut dasselbe.

## Route zu deinem Ziel

Die Belegung Route zu deinem Ziel nimmt die Kreatur oder das Gruppenmitglied, das du im Ziel hast, als Ziel der Route. Sie ist standardmäßig nicht belegt; belege sie im Fenster für die Tastenbelegung. Siehe auch [Zielerfassung](./targeting.md).

Was passiert, hängt davon ab, wen du im Ziel hast:

- Ein Gruppen- oder Schlachtzugsmitglied. WowVision benutzt die aktuelle Position dieses Spielers.
- Ein NPC oder eine Kreatur. Bei klassischen Routen sucht WowVision den nächsten Wegpunkt mit genau demselben Namen im Umkreis von 120 Metern. Mit WowNav benutzt es die Position der Kreatur im WowNav-Katalog. Ein weiterer Spawn derselben Art, der weiter als 120 Meter entfernt ist, zählt nicht.
- Alles andere. Du hörst Die Position deines Ziels ist nicht bekannt.

Weitere Dinge, die du hören kannst: Du hast kein Ziel, Du hast dich selbst im Ziel, Position nicht verfügbar, Keine Route zu deinem Ziel (hier keine Kartendaten oder WowNav kann nicht starten). Bei klassischen Routen wird eine Route, die der Router nicht findet, als Keine Route gefunden mit ihrem Grund gemeldet. Klappt es, hörst du den Namen des Ziels (bei klassischen Routen den Namen des passenden Wegpunkts in seiner langen Form) und dann die Zusammenfassung der Route, und die Route beginnt sofort an deiner Position (WowNav) oder am nächsten Einstiegspunkt (klassische Routen).

Kann WowNav nicht erkennen, auf welcher Ebene du bist, hörst du "Deine Ebene ist hier nicht eindeutig. Wähle deinen Start." und das Navigationsfenster öffnet sich mit dem Ziel schon ausgewählt, sodass du den Start selbst wählst.

## Besuchte Orte

Wenn du immer wieder zur selben Art von Ding gehst (Kräuter, Erzadern, die Spawns einer Kreatur), willst du nicht noch einmal an einen Ort geschickt werden, den du gerade geprüft hast. Die Funktion "Besuchte Orte" merkt sich das für dich.

- Ein Ziel, das du gewählt und erreicht hast, gilt eine Anzahl Minuten als besucht (standardmäßig 15, eine Art Respawn-Timer). Nur das Ziel zählt, nicht die Wegpunkte auf dem Weg. Das funktioniert für Ziele aus dem Fenster, dem Scanner, der Route zu deinem Ziel und dem Leichenlauf.
- In der Zielliste wird ein besuchtes Ziel mit Besucht davor angesagt.
- Das Gedächtnis gilt pro Charakter, nutzt Echtzeit und übersteht Ausloggen und Neuladen.
- Besuchte Wegpunkte vergessen (im WowVision-Menü unter Navigation, Besuchte Wegpunkte) löscht es. Du hörst "Besuchte Wegpunkte wurden vergessen".
- Der Schalter Aktiviert des Moduls Besuchte Wegpunkte schaltet die ganze Funktion aus.

Zwei Belegungen, beide standardmäßig nicht belegt, führen dich zum nächsten unbesuchten Ziel mit demselben Namen wie das zuletzt gewählte:

| Belegung | Was sie tut |
|----------|-------------|
| Route zum nächsten unbesuchten gleichnamigen Ziel | Plant eine Route dorthin, mit Einstieg an dem Einstiegspunkt, den das Fenster vorwählen würde. |
| Direkt zum nächsten unbesuchten gleichnamigen Ziel | Setzt dorthin ein gerades Beacon. |

"Gleicher Name" heißt bei WowNav der ganze Name und bei klassischen Routen der Name vor dem ersten Semikolon ("Peacebloom"), ohne Beachtung der Groß- und Kleinschreibung. Der Ort, an dem du gerade bist, und die als besucht markierten werden übersprungen. Drücke die Taste immer wieder, und du gehst nacheinander jeden Spawn dieses Objekts ab.

Ohne früher gewähltes Ziel hörst du Wähle zuerst ein Ziel im Navigationsfenster. Ist jeder Spawn besucht, hörst du "Kein unbesuchtes Ziel Peacebloom gefunden".

### Automatikmodus

Der Automatikmodus übernimmt diese Kette für dich. Drücke im Navigationsfenster Umschalt+F10 auf einem Ziel oder einem Einstiegspunkt und wähle einen von zwei Einträgen:

- Automatisch direkt: ein gerades Beacon zum Ziel. Bei jeder Ankunft geht das nächste gerade Beacon zum nächsten unbesuchten Ziel mit demselben Namen.
- Automatisch routen: eine Route zum Ziel. Bei jeder Ankunft geht die nächste Route zu dem unbesuchten Ziel dieses Namens, das den kürzesten Fußweg entfernt ist. WowVision prüft die 8 nächsten in Luftlinie und nimmt das mit dem kürzesten Weg, damit ein Kraut auf der anderen Seite eines Flusses nicht gegen eines gewinnt, das etwas weiter weg auf deiner Seite liegt. Mit WowNav wird das im Hintergrund geplant, und du hörst vielleicht zuerst Route wird berechnet.

Beim Start hörst du "Automatisch direkt" oder "Automatisch routen", danach die üblichen Ansagen jedes Beacons und jeder Route. Das erste Stück beginnt am Einstiegspunkt, den du im Fenster gewählt hast, wie bei Enter. Die Kette endet, wenn jeder Spawn besucht ist (du hörst "Kein unbesuchtes Ziel" und den Namen), wenn eine andere Führung beginnt (ein anderes Ziel, ein Beacon, /beacon, Strg+Umschalt+R) oder wenn du die Führung mit Umschalt+F12 beendest. Strg+Umschalt+N startet das aktuelle Stück neu und behält die Kette.

Strg+W und Strg+S gehen durch die Kette, so wie sie durch eine Route gehen. Hinter dem Ende des aktuellen Stücks geht Strg+W zum nächsten Spawn: bei Automatisch direkt sofort, weil ein gerades Beacon nur einen Punkt hat, bei Automatisch routen nach dem letzten Wegpunkt der Route. So überspringst du einen Spawn, den du nicht erreichst oder der leer ist, und die Kette bietet ihn nicht wieder an. Findet ein Stück keine Route, geht Strg+W genauso weiter. Strg+S vor dem Anfang eines Stücks geht zum Spawn davor zurück. Nach einem Schritt zurück geht die Kette erst durch die Spawns, zu denen sie schon geführt hat, dann zu neuen. Vor dem ersten hörst du Anfang der Route.

Der Automatikmodus braucht die besuchten Orte, denn die überspringt er. Ist das Modul Besuchte Wegpunkte aus, sagen beide Einträge nur "Der Automatikmodus braucht die besuchten Wegpunkte, schalte sie ein".

## Gerade Beacons und der Befehl /beacon

Du kannst ein Beacon auch ohne das Fenster setzen. Tippe diese Befehle ins Chatfeld:

| Befehl | Was er tut |
|--------|------------|
| /beacon | Spricht deine Position in Kartenprozent, zum Beispiel "50.5 30.4", und, falls ein Beacon aktiv ist, dessen Entfernung und Winkel. |
| /beacon 50.5 30.4 | Gerades Beacon zu Kartenkoordinaten auf der Karte deines aktuellen Gebiets: die Zahlen, die Questführer dir geben. Du hörst "Beacon gesetzt" und die Entfernung. |
| /beacon to bank | Routet zum nächsten bekannten Ort, dessen Name "bank" enthält. Du hörst seinen Namen, dann die Zusammenfassung der Route. Du wählst keinen Einstiegspunkt: WowNav benutzt den, den F10 vorwählen würde, und bei klassischen Routen nimmt der Router den besten der fünf nächsten Wegpunkte. |
| /beacon world x y | Gerades Beacon zu rohen Weltkoordinaten. |
| /beacon stop | Dasselbe wie Umschalt+F12. |

Bei /beacon to ergibt ein unbekannter Name "Keine Route gefunden" und den Namen. Ein Beacon von /beacon mit Koordinaten endet mit "Angekommen", wenn du nah genug bist, wie jede Route.

## Klassische Routen

Klassische Routen sind das Routensystem von The Burning Crusade und Classic Era, und von WoW: Forever, wenn du WowNav ausschaltest. Alles auf dieser Seite gilt für sie. Dieser Abschnitt ergänzt, was nur für sie gilt.

### Kartendaten

Die Kartendaten liegen in einem eigenen Addon-Ordner namens WowVision_MapData_TBC. Er steckt im WowVision-Download (zip) neben dem Ordner WowVision, ein einziges Entpacken installiert also beide (siehe [Installation](../getting-started/installation.md)). Er wird automatisch eingeschaltet, solange das Addon in der Addon-Liste des Spiels aktiviert ist. Seine TOC-Datei ist für The Burning Crusade und WoW: Forever gemacht; auf Classic Era hält das Spiel ihn deshalb für veraltet und lädt ihn eventuell nicht. WowNav benutzt diesen Ordner nicht: Seine Daten liegen im Ordner WowVision. Andere Kartendaten-Addons für WowVision funktionieren neben dem mitgelieferten weiter.

Die mitgelieferten Daten stammen aus den Vermessungsdaten des Addons Sku: seine Wegpunkte, die Verbindungen dazwischen und die Namen von NPCs, Kreaturen und Objekten. Sie decken die Östlichen Königreiche, Kalimdor, die Tiefenbahn, die Scherbenwelt und Nordend ab. Die Dateien für Nordend und das Startgebiet der Todesritter sind enthalten, werden aber nie über das hinaus erweitert, was die Vermessung enthielt. Rechne dort also mit mehr Lücken als in der alten Welt. Auf einem deutschen oder französischen Spielclient werden die Ortsnamen in deiner Sprache angezeigt.

### Ortsnamen

Namen in diesen Daten haben eine feste Form: der Name, dann seine Rolle, falls er eine hat, dann das Gebiet, eine Spawn-Nummer und die Kartenkoordinaten, alles durch Semikola getrennt. Zum Beispiel: "Shailiea;Stormwind City;1;30.38;53.33" oder "Eldraeith;Herbalism Supplies;Stormwind City;1;46.66;78.65". WowVision liest den Namen genau so vor. Dein Screenreader macht an den Semikola vielleicht eine Pause oder liest sie laut vor. Die Rollenwörter helfen bei der Suche: "Questgeber", "Lehrer", "Bankier", "Auktionator", "Reparatur", "Stallmeister" und viele mehr sind Teil des Namens.

### Das letzte Stück

Liegt ein Ziel nicht im Verbindungsnetz (die meisten Kreaturen und Objekte tun das nicht), führt die Route durch das Netz zum nächsten verbundenen Wegpunkt und endet dann mit einem geraden Stück bis zum Ziel. WowVision sagt dir, wie lang dieses gerade Stück ist, zum Beispiel "letzte 40 Meter direkt".

## Einstellungen

Öffne das WowVision-Menü (/wv), dann Navigation, dann Beacon und Routen. Die Einstellungen gelten für alle deine Charaktere, solange du das nicht im Kontextmenü des Moduls änderst; siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert | An | Schaltet das ganze Modul Beacon und Routen aus: nicht nur das Beacon, sondern auch Routen, die Tasten und /beacon. |
| Ankunftsradius (Arrival Radius) | Mittlere Distanz | Welche Ankunftsdistanz aktiv ist. Alt+P ändert sie auch. |
| Kurze Distanz | 0,3 Meter | Die kurze Ankunftsdistanz (0,1 bis 20 Meter). |
| Mittlere Distanz | 1 Meter | Die mittlere Ankunftsdistanz (0,1 bis 20 Meter). |
| Weite Distanz | 3 Meter | Die weite Ankunftsdistanz (0,1 bis 20 Meter). |
| Entfernung mit Alt Gr ansagen | An | Ob Alt Gr und Strg+Alt die Entfernung sprechen. Die Belegung Entfernung ansagen funktioniert in jedem Fall. |
| Beacon | (siehe oben) | Der Beacon-Alarm und seine vier Töne: Beacon-Ton, Beacon ausgerichtet, Beacon abseits des Kurses, Wegpunkt erreicht. Jeder hat Aktiviert und eine Soundauswahl; Beacon-Ton hat dazu Beacon-Lautstärke. |

Das Modul Besuchte Wegpunkte (unter Navigation) hat eine Einstellung:

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Gilt als besucht für (Minuten) | 15 | Wie lange ein erreichtes Ziel als besucht gilt (1 bis 1440 Minuten). |

Drei Einstellungen des Moduls Navigation hängen damit zusammen: Verbleibende Wegpunkte ansagen (standardmäßig an) sagt nach jedem erreichten Wegpunkt, wie viele noch übrig sind, Automatisch zur Leiche navigieren (standardmäßig an) startet eine Route zu deinem Körper, sobald du ein Geist bist, und Automatisch zum Interaktionsziel bewegen wird bei den Bewegungsfunktionen erklärt. Dazu, zum Kompass und zum Folgen eines Spielers siehe [Bewegung und Orientierung](./movement.md).

## Diagnosebefehle

| Befehl | Was er tut |
|--------|------------|
| /wv turnlog | Listet die letzten Drehungen der Taste I mit ihrem Fehler in Grad auf, in einem Fenster und im Chat, und spricht eine Zusammenfassung wie "10 turns, mean error 1.2 degrees" (Ansage auf Englisch, wenn nicht übersetzt). Gib das bei einer Fehlermeldung an, wenn das Drehen schiefgeht. |

## Beispiele

### Von der Bank zum Auktionshaus gehen (Sturmwind)

1. Stell dich vor die Bank und drücke F10. Du landest auf dem nächsten Einstiegspunkt, angesagt mit ausgewählt. Das passt, lass ihn also.
2. Drücke Tab. Du bist in Suchen und kannst gleich tippen. Tippe "Auktionator" und drücke Eingabe. WowVision wiederholt deinen Text.
3. Drücke Tab, um zu Ziele zu kommen. Du hörst den nächsten Auktionator mit seiner Entfernung und seiner Position in der Liste. Drücke Pfeil runter, um den nächsten zu hören.
4. Drücke Eingabe. Das Fenster schließt sich, und du hörst eine Zusammenfassung wie "9 Wegpunkte, 410 Meter".
5. Drücke I, um dich zum ersten Wegpunkt zu drehen, und geh los. Wenn du das Beacon schneller pingen hörst, blickst du in die richtige Richtung. Drücke jederzeit Alt Gr, um zu hören, wie weit der aktuelle Wegpunkt entfernt ist.
6. Verirrst du dich, drücke Strg+Umschalt+N, um die Route von deinem Standort aus neu zu planen.
7. Am Ende hörst du "Angekommen" und den Namen des Ortes.

### Einer Route zu einem Quest-NPC folgen

1. Drücke F9, um den Scanner zu öffnen, und finde die Quest, dann ihren NPC (siehe [Scanner](./scanner.md)).
2. Drücke Eingabe auf dem NPC. Das Navigationsfenster öffnet sich mit dem nächsten Einstiegspunkt und dem NPC, beide ausgewählt, der Fokus auf dem Ziel.
3. Drücke Eingabe. Willst du vorher einen anderen Startpunkt, drücke zweimal Umschalt+Tab, um zu den Einstiegspunkten zu kommen, wähle einen mit Eingabe und kehre mit zweimal Tab zurück.
4. Geh die Route wie oben. Liegt der NPC nicht im Wegnetz, ist das letzte Stück kein bekannter Weg, nutze also das Beacon und Alt Gr. Bei klassischen Routen sagt das die Zusammenfassung ("letzte 25 Meter direkt"), und WowNav sagt dir am Ende des Netzes, wie weit der NPC noch entfernt ist.

### Das nächste Kraut finden

1. Suche im Fenster nach "Peacebloom" und geh zum nächsten. Wenn du ankommst, gilt es als besucht.
2. Belege Route zum nächsten unbesuchten gleichnamigen Ziel auf eine Taste.
3. Drücke diese Taste. Du wirst zur nächsten Peacebloom geroutet, die du noch nicht besucht hast. Drücke sie nach jeder Ankunft immer wieder.

## Verwandte Seiten

- [WowNav (WoW: Forever)](./wownav.md): das Routensystem von WoW: Forever.
- [Bewegung und Orientierung](./movement.md): Kompass, Blickrichtung, Folgen, Fallen, Wände und der Leichenlauf.
- [Scanner](./scanner.md): Listen von Dingen um dich herum, wobei Eingabe ans Navigationsfenster übergibt.
- [Zielerfassung](./targeting.md): das Ziel für die Route zu deinem Ziel auswählen.
- [Alarme](../basics/alerts.md): wie du die Beacon-Töne änderst.
