# WowNav (WoW: Forever)

WowNav ist das Routensystem von WoW: Forever. Es wurde von Broesel33 für blinde Spieler gemacht, aus einer Vermessung des tatsächlich begehbaren Bodens der Spielwelt, und WowVision enthält es mit seiner Erlaubnis. Es weiß, wo du wirklich gehen kannst, einschließlich Treppen, Brücken und der Stockwerke von Gebäuden, und es kann dich zu Portalen, Aufzügen, Schiffen, Zeppelinen und der Tiefenbahn bringen. Diese Seite erklärt, was es tut, wie es sich von den klassischen Routen unterscheidet und wie du es benutzt.

Du benutzt WowNav über dasselbe Navigationsfenster und dieselben Tasten wie die klassischen Routen. Lies zuerst [Navigation und Routen](./navigation.md); diese Seite beschreibt nur, was sich ändert.

Hinweis: Die Ansagen dieser Seite kommen aus lokalisierten Texten und werden auf einem deutschen Client auf Deutsch gesprochen. Die Beispiele zeigen, was du hörst. Namen von NPCs und Orten stammen aus den Spieldaten und bleiben so, wie sie dort stehen.

(Nur WoW: Forever. Die anderen Spielversionen benutzen die klassischen Routen.)

## WowNav ausschalten

WowNav ist standardmäßig an. Jede Routenanfrage geht daran: das Navigationsfenster (F10), Eingabe im Scanner, /beacon to, die Route zu deinem Ziel, der Leichenlauf und die Tasten für besuchte Orte. Die klassischen Routen werden nicht benutzt, solange es an ist.

So benutzt du stattdessen die [klassischen Routen](./navigation.md#klassische-routen):

1. Öffne das WowVision-Menü (/wv), dann Navigation, dann WowNav-Routen.
2. Schalte Routen von WowNav aus.

Es gibt auch einen Schalter Aktiviert für das Modul WowNav-Routen selbst, der an bleiben muss, damit WowNav funktioniert.

## Was es abdeckt

Die Daten werden mit WowVision geliefert (in den Release- und Beta-Downloads) und brauchen nichts weiter. Sie decken 51 Gebiete auf vier Karten ab:

- Östliche Königreiche (26 Gebiete, darunter die Hauptstädte Sturmwind, Eisenschmiede und Unterstadt sowie Riverglades)
- Kalimdor (23 Gebiete, darunter Orgrimmar, Donnerfels und Darnassus, Berg Hyjal und Shendralas)
- Die Tiefenbahn
- Zephras Isle

Etwa 111.000 Orte (NPCs, Kreaturen, Objekte), 242 Orte, um woandershin zu kommen (Dungeoneingänge, Portale, Aufzüge, Anleger, Haltestellen der Tiefenbahn, Übergänge zwischen Gebieten), und 788 Angelplätze an den Gewässern von 45 Gebieten lassen sich als Ziele wählen.

Was WowNav nicht tut:

- Keine Instanzen. Das Innere von Dungeons und Schlachtzügen gibt es in den Daten nicht. Dungeoneingänge schon, und du kannst zu ihnen gehen. Die Eingänge einiger der Dungeons, die in WoW Forever neu sind, fehlen.
- Keine Fahrzeuge in einer Route. Routen gehen immer zu Fuß. Ein Schiff, ein Zeppelin oder die Tiefenbahn ist kein Teil einer Route: WowNav führt dich zu ihrem Anleger, und du steigst selbst ein.
- Keine Flugrouten.
- Keine Gefahrenwarnungen vor Gegnern oder Kreaturenstufen. Die einzige Ausnahme ist die weiter unten beschriebene Warnung vor feindlichen Posten.
- Das Tauchen ist deine Sache. Wasser ist in den Daten flach. Die einzige Tauchroute sind die Ruins of Blackfathom in Dunkelküste.

Auf einer Karte, die die Daten nicht kennen, listet F10 nichts auf, und /beacon to antwortet "Keine Route gefunden". Der Scanner setzt mit Eingabe dann ein gerades Beacon, wie ohne Kartendaten. Wo WowNav Daten hat, führt Eingabe im Scanner auf einem NPC oder Objekt, das WowNavs Ortsliste an dieser Stelle kennt, zu WowNavs eigenem Eintrag dafür, mit seiner Höhe; siehe [Scanner](./scanner.md). Kann die Ortsliste einer Karte gar nicht gelesen werden, hörst du "WowNav-Katalog nicht nutzbar", gefolgt von einem Grund; gib ihn bei einer Fehlermeldung an.

## Wie es sich von den klassischen Routen unterscheidet

| | Klassische Routen | WowNav |
|---|---|---|
| Spielversionen | TBC und WoW: Forever | WoW: Forever |
| Einstiegspunkte in F10 | Die 20 nächsten verbundenen Wegpunkte, benannt wie die Orte | Die 50 nächsten Einträge: Orte, die im Wegnetz liegen (ein NPC, eine Tür, ein Portal), und die eigenen Wegpunkte des Netzes im Umkreis von 10 Metern. Mit Automatische Wegpunkte zeigen auch die Wegpunkte weiter weg |
| Ziele | Jeder benannte Wegpunkt des Kontinents, der nächste zuerst | Die nächsten 1000 Orte, die zu deiner Suche passen, jeweils mit ihren Kategorien und dem Gebiet |
| Suche | Findet Name, Rolle und Gebiet als einen Text | Findet Namen auf Englisch und Deutsch, Kategorien, Such-Aliase und den Gebietsnamen |
| Namen | "Name;Role;Zone;1;30.38;53.33" | Schlichte Namen wie "Innkeeper Allison (Innkeeper)" (viele NPCs tragen ihren Beruf in Klammern) und beschreibende Namen wie "Portal nach Orgrimmar" |
| Ebenen | Nicht bekannt | Kennt Ebenen und fragt, welche du meinst, wenn es das nicht erkennt |
| Portale, Tiefenbahn, Aufzüge, Anleger | Ein Wegpunkt wie jeder andere | Sonderbehandlung mit gesprochener Führung |
| Wenn du vom Weg abkommst | Du drückst Strg+Umschalt+N | Findet selbst zurück und hat eine Taste für eine neue Route um eine versperrte Stelle |
| Ankunftsdistanz | Alt+P kurz, mittel, weit | Dasselbe; ein Wegpunkt mit einer eigenen, größeren Distanz in den Daten nimmt diese |

## Das Navigationsfenster mit WowNav

F10 funktioniert wie in [Navigation und Routen](./navigation.md) beschrieben: Direkt, Einstiegspunkte, Suchen und Ziele. Was anders ist:

### Einstiegspunkte

Die Einstiegspunkte sind die 50 nächsten Einträge: die Orte, die im Netz liegen (der Flugmeister vor dir, eine Tür, ein Portal), und die eigenen Wegpunkte des Netzes direkt neben dir. Du wählst, wo deine Route beginnt, wie bei den klassischen Routen. WowNav berechnet deinen Start nie selbst, außer bei Strg+Umschalt+N und bei der Route zu deinem Ziel, die dort starten, wo du stehst, wenn das eindeutig ist. Wählst du einen Ort als Start, beginnt deine Route an diesem Ort selbst.

- Die eigenen Wegpunkte des Netzes im Umkreis von 10 Metern stehen immer in der Liste. So kannst du genau dort starten, wo du stehst, auch wenn der nächste Ort weit weg ist. Mit Automatische Wegpunkte zeigen an kommen auch die Wegpunkte weiter weg dazu. Ein Wegpunkt wird als "Auto, Höhe 54" gelesen: Nur seine Höhe in Metern wird gesagt.
- Während du schwimmst oder tauchst, ist der nächste Wasserpunkt innerhalb von 100 Metern immer in der Liste und vorgewählt. Gibt es keinen, hörst du "Kein Wasserpunkt in der Nähe".
- Ist nichts vom Netz nah genug, sagt die Liste Leer, und eine Routenanfrage antwortet "Hier kein WowNav-Netz".

### Ziele

Jedes Ziel liest seinen Namen, seine Entfernung, was es ist und wo es ist, zum Beispiel "Innkeeper Allison (Innkeeper), 85 Meter, Questgeber, Händler, Gastwirt, Stormwind City". Die zusätzlichen Wörter stammen aus den Kategorien des Ortes. Das sind: Questgeber, Lehrer, Händler, Flugmeister, Gastwirt, Bankier, Stallmeister, Auktionator, Geistheiler, Geistführer, NPC oder Gegner, Truhe, Kraut oder Erz, Objekt, Questgegenstand, Interaktionsobjekt, Briefkasten, Amboss, Schmiede, Tür, Buch, Stuhl, Schild, Angelplatz, Schalter, Falle, Zauberfokus, Eroberungspunkt, zerstörbares Gebäude, Gildenbank, Falltür, Wegpunkt, Orientierungspunkt, Transport, Live-Ziel, Zonenübergang, Verkehrsmittel, Schiff, Tiefenbahn, Dungeon, Portal, Zeppelin, Aufzug und tauchen. Du kannst nach jedem dieser Wörter suchen, nach dem Namen oder nach einem Gebietsnamen: "Bankier", "Briefkasten", "Ironforge".

- Die Liste zeigt höchstens die nächsten 1000 Treffer. Wurde sie gekürzt, beginnt der erste Eintrag, den du hörst, mit "Die nächsten 1000 von 4821 Treffern".
- Ein Ziel ohne Netzpunkt in der Nähe (siehe Zielradius um das Netz (Meter)) wird weggelassen. Ein Ort, dessen Gebiet noch nicht vorbereitet ist, wird ungeprüft angeboten und beim Wählen geprüft.
- Zusätzliche Informationen können vor den Kategorien kommen: "ungenau +3.2 Meter" (der Ort liegt nicht genau im Netz), "Ebene wählen" (der Ort liegt über mehreren Ebenen), "Ebene unbekannt", "kein Netzpunkt im Radius" oder "Wasseroberfläche, Tauchtiefe 12 Meter".
- Orte, um woandershin zu kommen, haben beschreibende Namen: "Dungeoneingang: The Deadmines", "Portal nach Orgrimmar", "Schiffsanleger nach Auberdine", "Zeppelinturm nach Grom'gol", "Tiefenbahn-Haltestelle Richtung Ironforge", "Eingang der Tiefenbahn", "Aufzug: Thunder Bluff", "Übergang nach Westfall", "Hier tauchen" und "Hier auftauchen". Wo zwei Orte eines Gebiets gleich klingen würden, bekommen sie "(unten)", "(oben)", eine Höhe oder eine Nummer angehängt. Die Ortswörter in diesen Namen stammen vom Spielclient. Auf einem deutschen Client sind die Namen deutsch.
- Kreaturen und Objekte (NPCs, Monster, Kräuter, Erze, Briefkästen) werden auf Clients, die weder englisch noch deutsch sind, in deiner Spielsprache benannt, wenn Questie sie kennt. Die Navigationsdaten selbst haben nur englische und deutsche Namen; deshalb kommt der Name auf anderen Clients aus Questies Datenbank anhand der ID der Kreatur oder des Objekts, und kennt Questie sie nicht, bleibt der englische Name. In Klammern geschriebene Titel wie "(Innkeeper)" werden mit übersetzt. Die eigene Sprache von Questie muss auf Auto oder auf der Sprache des Spiels stehen. Auf englischen und deutschen Clients ändert sich nichts. Die Einstellung Namen in deiner Sprache schaltet das ab.
- Angelplätze heißen nach dem Gewässer, in das du wirfst: "Angelplatz am Ufer: Crystal Lake" oder "Angelplatz auf Steg oder Kai: The Temple Gardens", mit einer Nummer, wenn mehrere Plätze eines Gebiets gleich heißen. Suche nach "Angelplatz" oder "Angeln". Siehe [Angelplätze](#angelplätze).
- Ein Dungeon mit mehreren Eingängen nennt den Flügel: "Dungeoneingang: Scarlet Monastery, Friedhof".
- Die Einsteigpunkte von Anlegern sind ebenfalls aufgelistet: "Am Schiff", "Am Zeppelin" und "Am Fahrzeug", mit dem Namen des Anlegers als zusätzlichen Wörtern.
- Mit Direkt an wird kein Ziel als unerreichbar weggelassen, weil ein gerades Beacon keine Route braucht.

Wählst du einen Ort, der einen Schritt weiter weg liegt, als das Netz reicht, beendet WowNav die Route am Netz und sagt das; siehe [Was du am Ende hörst](#was-du-am-ende-hörst).

### Nach der Ebene gefragt werden

Liegt dein Ziel über mehreren Ebenen (ein Turm, ein mehrstöckiges Gebäude) und nichts sagt, welche du willst, öffnet sich ein kleines Fenster: Wähle die Ebene des Ziels. Es hat eine Schaltfläche pro Ebene, die unterste zuerst, zum Beispiel:

- "Ebene 1 von 3, unterste, Höhe 40"
- "Ebene 2 von 3, Höhe 52"
- "Ebene 3 von 3, oberste, Höhe 64, kein Weg von hier"

kein Weg von hier heißt, dass diese Ebene von deinem Startpunkt aus nicht erreichbar ist. Bewege dich mit Pfeil hoch und Pfeil runter und drücke Eingabe auf der gewünschten Ebene; dann wird die Route geplant. Nach deiner eigenen Ebene wird nie gefragt, weil du deinen Start in F10 gewählt hast. Ein Leichenlauf nimmt ohne Nachfrage die unterste erreichbare Ebene.

## Eine Route starten und ihr folgen

Wenn du ein Ziel wählst, sucht WowNav die Route in kleinen Schritten, damit das Spiel nicht ruckelt. Dauert die Suche länger als eine Sekunde, hörst du "Route wird berechnet". Dann hörst du die Zusammenfassung, zum Beispiel "14 Wegpunkte, 520 Meter".

Die Zusammenfassung kann weitergehen:

- "ungefähr, 4 Meter" (der Ort liegt nicht genau im Netz; "Höhe unbekannt" kann dazukommen) oder "Wasseroberfläche, Tauchtiefe 12 Meter".
- "dann das Portal" (oder "die Tiefenbahn", "den Aufzug", "ein Tauchgang", "Auftauchen"): Die Route endet an einem Verkehrsmittel, das weiter unten beschrieben ist.
- "Ungefähre Zielposition.", wenn die Position des Ortes in den Daten selbst eine Schätzung ist.
- "Warnung: Es gibt keinen Weg um den feindlichen Posten, die Route führt hindurch." oder "Warnung: Das Ziel liegt in einem feindlichen Posten.", nur mit Feindliche Posten meiden an.

Das Beacon, seine Töne, Strg+W, Strg+S, Umschalt+F12, Alt Gr und I funktionieren alle wie in [Navigation und Routen](./navigation.md). Die Unterschiede:

- Ein Wegpunkt gilt als erreicht innerhalb der Ankunftsdistanz von Alt+P, oder innerhalb seiner eigenen Distanz aus den Daten, wenn diese größer ist. Auch die Bereiche von Portalen, Tiefenbahn und Aufzügen werden mit Alt+P weiter.
- Strg+W und Strg+S gehen die eigenen Wegpunkte der Route entlang.
- Strg+Umschalt+N plant das letzte Ziel von deinem Standort aus neu, aber nur, wenn WowNav weiß, auf welcher Ebene du bist. Stehst du neben dem Netz, beginnt die Route an seinem nächsten Punkt im Umkreis von 30 Metern. Sonst hörst du "Deine Ebene ist hier nicht eindeutig", oder "Hier kein WowNav-Netz", wenn innerhalb von 30 Metern nichts vom Netz ist.
- Umschalt+F12 beendet alles, was WowNav tut: die Suche, die Route, ein Verkehrsmittel, das auf sein anderes Ende wartet, die Anleger-Führung und das Beacon an einem Angelplatz.
- /beacon to name nimmt den nächsten Ort mit diesem Namen aus der Liste von WowNav, mit dem Einstiegspunkt, den F10 vorwählen würde.

### Beim Gehen

WowNav beobachtet deinen Fortschritt und spricht nur, wenn es darauf ankommt:

| Du hörst | Was es bedeutet |
|----------|-----------------|
| "Letzter Netzpunkt; das letzte Stück ist ungeprüft, geh vorsichtig" | Das Wegnetz endet vor deinem Ziel. Der Rest ist ein gerader Weg. |
| "Wieder auf der Route" | Du bist abgekommen, standest aber auf einem späteren Teil der Route, der jetzt der aktuelle ist. |
| "Einen Wegpunkt zurück" | Du wurdest an einer Engstelle seitlich weggeschoben, deshalb ging das Beacon einen Wegpunkt zurück. |
| "Route beendet" | Die Route ist fertig, meist weil du die Karte verlassen hast. |
| "Route außerhalb der Gebiete des Netzes beendet." | Du bist aus dem Bereich gelaufen, den die Daten kennen. |

Bleibst du hängen, versucht WowNav, wieder in die Route einzusteigen und an Engstellen zurückzutreten, aber es plant nie von selbst eine neue Route. Das ist deine Entscheidung: Drücke die Taste unten. Stirbst du, endet die Route ohne ein Wort.

### Was du am Ende hörst

- Im Netz oder höchstens 1,5 Meter vom Ende des Netzes: "Angekommen" und der Name des Ortes.
- Nah am Netz, aber weiter von seinem Ende entfernt: "Das Netz endet 4.2 Meter vom Ziel; Umgebung selbst absuchen. Die letzte Strecke ist ungeprüft." Kennen die Daten die Höhe nicht, kommt "horizontal" dazu.
- Ein Wasserziel: "Das Netz endet 6.1 Meter von der Position an der Wasseroberfläche; Tauchtiefe 12.0 Meter. Den restlichen Weg und das Tauchen selbst übernehmen, die letzte Strecke ist ungeprüft."

### Routenstatus und neue Route

Zwei Belegungen sind standardmäßig nicht belegt; belege sie im Fenster für die Tastenbelegung (WowVision-Menü, Benutzeroberfläche, Tastenbelegung), siehe [Tastenbelegung](../basics/keybindings.md):

| Belegung | Was sie tut |
|----------|-------------|
| WowNav-Routenstatus | Sagt, was WowNav gerade tut: "Suche die Route zu Allison", "Unterwegs zu Allison, Wegpunkt 3 von 14", "Warte auf das andere Ende von das Portal", "Fahrt zum vorgemerkten Anleger Schiffsanleger nach Auberdine", "Am Anleger, warten", "Am Angelplatz" oder "Keine aktive Route". |
| Neue WowNav-Route um eine versperrte Stelle | Benutze sie, wenn du an einer Verbindung festhängst (ein Zaun, eine geschlossene Tür, eine Rampe, die du nicht hochkommst). Die Verbindung, auf der du bist, wird im Plan gesperrt, und ab dem letzten Wegpunkt, den du erreicht hast, wird eine neue Route gesucht. Du hörst "Neue Route wird gesucht". Ohne Route hörst du "Keine aktive Route". |

## Verkehrsmittel: Anleger, Schiffe, Zeppeline, Tiefenbahn, Portale und Aufzüge

### Anleger

Ein Anleger ist ein Wartepunkt für ein Schiff, einen Zeppelin oder eine Haltestelle der Tiefenbahn. Wählst du einen in F10, wirst du zu Fuß zu seinem Wartepunkt geroutet. Wenn du ankommst, hörst du, worauf du warten sollst, zum Beispiel: "Anleger Schiffsanleger nach Auberdine erreicht. Hier auf das Schiff warten. Steige ein, wenn du die Ankunft hörst. Das Beacon zeigt die Einsteigrichtung; I dreht dich dorthin." Das Beacon führt dann zu einem Einsteigpunkt ein paar Meter weiter vorn und endet dort: "Einsteigpunkt Schiffsanleger nach Auberdine erreicht". WowNav kann nicht erkennen, wann das Fahrzeug da ist; du steigst nach Gehör ein.

Stehst du an einem Anleger und wählst das andere Ende derselben Linie, wird nichts gegangen. WowNav merkt es sich und sagt, wohin die Fahrt geht und womit, zum Beispiel "Fahrt nach Ironforge mit die Tiefenbahn: hier warten, nach Gehör einsteigen und an der Endhaltestelle aussteigen. In der Nähe dreht dich I zum Anleger." Kommst du später in die Nähe dieses Anlegers, hörst du seinen Namen, gefolgt von "ist nah; I dreht dich dorthin", und I blickt jetzt zu diesem Anleger. Wähle den Anleger erneut, um den Rest des Weges zu gehen. Das funktioniert nur bei einer Linie, deren Anleger auf derselben Karte liegen, wie die Tiefenbahn: Die Liste enthält nur Orte der Karte, auf der du bist, deshalb lässt sich der Anleger am anderen Ende einer Seereise zu einem anderen Kontinent von hier aus nicht wählen.

Eine Station zu betreten (im Umkreis von etwa 100 Metern um einen Anleger) zählt als Erreichen des Anlegers, sodass du den fernen Anleger wählen kannst, ohne vorher zum nahen zu gehen. Wählst du einen Anleger deiner eigenen Station, etwa den anderen Anleger in Menethil Harbor, gehst du wie üblich dorthin.

### Portale, der Eingang der Tiefenbahn und begehbare Orte

Portale und der Eingang der Tiefenbahn funktionieren, indem du hineingehst. Eine Route endet am Portal, und WowNav sagt das, bevor du es erreichst, weil ein Portal sofort teleportiert: "Gleich vor dir: geh in das Portal, danach geht die Route weiter". Geh hinein. Wenn du am anderen Ende wieder herauskommst, hörst du "Die Route geht weiter", und WowNav sucht von dort den Rest des Weges. Passiert innerhalb von etwa 90 Sekunden nichts (länger bei Fahrten, die drei volle Umläufe des Fahrzeugs abwarten), hörst du "Die Fahrt dauerte zu lange; Route beendet". Die Windbrücke von Zephras Isle hat keine solche Grenze: Sie kommt, wann sie kommt.

Wählst du das Portal oder den Eingang der Tiefenbahn selbst als Ziel, wirst du zu einem Punkt kurz davor geführt und hörst: "Vorpunkt erreicht. Gehe geradeaus durch den Eingang oder das Portal; das Beacon bleibt bis zum Aktivierungsbereich an." Dann: "Im Aktivierungsbereich. Gehe geradeaus weiter; erst ein Kartenwechsel bestätigt den Übergang. Die Route bleibt bis dahin an." Nach dem Kartenwechsel hörst du "Kartenwechsel nach dem Aktivierungsbereich; Route beendet. Der Zielort ist nicht bestätigt."

### Aufzüge und Tauchgänge

Ein Aufzug ist ein Ort zum Warten: "Benutze den Aufzug, danach geht die Route weiter. Steige nur ein, wenn das Fahrzeug sicher da ist." Ein Tauchgang ist "Hier tauchen, danach geht die Route weiter", und der Weg zurück nach oben ist "Hier auftauchen, danach geht die Route weiter". Die Route geht weiter, nachdem du am anderen Ende bist.

### Die Drehtaste ohne Route

Die Taste I braucht normalerweise eine Route. An einem Anleger funktioniert sie auch ohne: An einem erreichten Anleger dreht sie dich zum Einsteigpunkt, und in der Nähe eines vorgemerkten Anlegers dreht sie dich zu diesem Anleger. An einem erreichten Angelplatz dreht sie dich zum Wasser.

### Zephras Isle

Die Portale und die Windbrücke (Wind Bridge) von Zephras Isle sind enthalten. Ihre Positionen sind Schätzungen, deshalb sagt WowNav dort zusätzlich "Die Position ist ungefähr." In die Portale gehst du nicht hinein: Du erfasst das Portal und interagierst damit. Eine Route durch eines endet dort mit "Erfasse das Portal mit der weichen Zielerfassung und interagiere damit; danach geht die Route weiter". Die Windbrücke kommt zu ihrer eigenen Zeit: "Warte hier, bis du die Windbrücke hörst, dann tritt in den Windstrom; danach geht die Route weiter". Dafür gibt es keine Zeitgrenze. Sobald du am anderen Ende angekommen bist, geht die Route weiter.

Das Portal nach Valanaar bringt die Horde und die Allianz an verschiedene Orte. Eine Route nimmt nur den Weg, der zu deiner Fraktion gehört.

Wählst du eines dieser Portale oder den Wartepunkt der Windbrücke selbst als Ziel, hörst du am Vorpunkt "Vorpunkt erreicht. Gehe weiter zum Portal; das Beacon bleibt an, bis du dort bist." (bei der Brücke "Vorpunkt erreicht. Gehe weiter zum Wartepunkt der Windbrücke; das Beacon bleibt bis dahin an."). Am Portal hörst du "Am Portal. Erfasse es mit der weichen Zielerfassung und interagiere damit; die Route bleibt an, bis der Übergang bestätigt ist.", an der Brücke "Am Wartepunkt der Windbrücke. Warte, bis du die Brücke hörst, dann tritt in den Windstrom."

## Angelplätze

WowNav kennt 788 Plätze zum Angeln an den Gewässern von 45 Gebieten. Ein Angelplatz liegt auf festem Boden am Ufer oder auf einem Steg, einer Mole, einem Kai oder einer Brücke. Dort darfst du durch flaches Wasser waten, schwimmen musst du nie. Vom Platz aus liegt das Wasser in einer Richtung 10 bis 20 Meter vor dir, so weit reicht dein Wurf.

1. Drücke F10, suche "Angelplatz" und wähle in Ziele einen Platz, zum Beispiel "Angelplatz am Ufer: Crystal Lake (3), 120 Meter, Angelplatz, Elwynn Forest".
2. Folge der Route. Wenn du ankommst, hörst du, wo das Wasser liegt, von deiner Blickrichtung aus: "Angelplatz am Ufer: Crystal Lake (3) erreicht. Das Wasser liegt links vorn. Wurfweite etwa 10 bis 20 Meter. Mit I drehst du dich zum Wasser." Die Richtungen sind vorn, links vorn, links, links hinten, hinten, rechts hinten, rechts und rechts vorn.
3. Jetzt kommt ein Beacon vom Wasser, 15 Meter weit draußen, in der Mitte deiner Wurfweite. Drücke I, um dich zum Wasser zu drehen, und wirf dann aus.
4. Das Beacon endet, wenn du dich vom Platz entfernst (mehr als 20 Meter), wenn du Umschalt+F12 drückst oder wenn du eine neue Route beginnst.

Der Punkt im Wasser ist nur zum Ausrichten da. WowNav schickt dich nie ins Wasser. Endet das Netz weiter vom Platz entfernt als deine Wurfweite, hörst du stattdessen das übliche "Das Netz endet ... vom Ziel", und es kommt kein Beacon.

## Einstellungen

Öffne das WowVision-Menü (/wv), dann Navigation, dann WowNav-Routen.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert | An | Schaltet das ganze Modul ein oder aus. |
| Routen von WowNav | An | Schickt jede Routenanfrage an WowNav statt an die klassischen Routen. |
| Straßen bevorzugen (Prozent länger) | 60 | Eine Route auf Straßen und Wegen darf um so viel Prozent länger sein als der kürzeste Weg. 0 heißt immer der kürzeste. Bis zu 300. Auch Schwimmen zählt um so viel länger. Änderst du es während einer Route, hörst du eine Sekunde nach dem letzten Verstellen "Route wird mit der neuen Straßenvorliebe neu gesucht". |
| Feindliche Posten meiden | An | Routen führen um die Posten und Hauptstädte der gegnerischen Fraktion herum. Wo es keinen Weg drumherum gibt, führt die Route hindurch und warnt dich. Ändern plant eine laufende Route neu. |
| Automatische Wegpunkte zeigen | Aus | Fügt der Zielliste die eigenen Wegpunkte des Netzes im Umkreis von 60 Metern hinzu und mischt die Wegpunkte bis 300 Meter unter die Einstiegspunkte. Ohne die Einstellung zeigen die Einstiegspunkte trotzdem die Wegpunkte im Umkreis von 10 Metern. Sie lesen sich "Auto, Höhe N". |
| Zielradius um das Netz (Meter) | 30 | Wie weit vom Netz ein Ort liegen darf und trotzdem eine Route bekommt (1 bis 100). Weiter entfernte Orte haben keinen Netzpunkt. |
| Höhentoleranz einer Ebene (Meter) | 3 | Das Höhenband, das als eine Ebene zählt (0 bis 20). |
| An Engstellen einen Schritt zurück | An | Driftest du an einer Engstelle seitlich ab, geht das Beacon einen Wegpunkt zurück ("Einen Wegpunkt zurück"). |
| Nachbargebiete vorbereiten | An | Bereitet dein Gebiet und die Nachbargebiete im Hintergrund vor, damit die erste Route dorthin nicht wartet. |
| Namen in deiner Sprache | An | Benennt Kreaturen und Objekte in deiner Spielsprache aus Questies Datenbank, wo sie sie kennt; siehe [Ziele](#ziele). Auf englischen und deutschen Clients ohne Wirkung. |

## Beispiele

### Zu einem Lehrer in einer Stadt gehen

1. Drücke F10. Die Einstiegspunkte sind die Wegpunkte des Netzes direkt neben dir und die nächsten Orte im Netz, zum Beispiel ein Flugmeister. Der nächste ist schon ausgewählt.
2. Drücke Tab und tippe "Lehrer", dann Eingabe.
3. Drücke Tab, um zu Ziele zu kommen. Du hörst zum Beispiel "Einris Brightspear (Hunter Trainer), 140 Meter, Questgeber, Lehrer, Stormwind City". Pfeil runter liest den nächsten.
4. Drücke Eingabe. Du hörst die Zusammenfassung, etwa "12 Wegpunkte, 330 Meter". Drücke I, um dich zu drehen, und folge dem Beacon. Am Ende: "Angekommen Einris Brightspear (Hunter Trainer)".

### Mit dem Schiff von Menethil Harbor nach Auberdine fahren

1. Drücke in Menethil Harbor F10, suche "Auberdine" und wähle in Ziele "Schiffsanleger nach Auberdine".
2. Folge der Route zum Anleger. Du hörst "Anleger Schiffsanleger nach Auberdine erreicht. Hier auf das Schiff warten. Steige ein, wenn du die Ankunft hörst."
3. Drücke I, um in die Einsteigrichtung zu blicken, und steige auf das Schiff, wenn es ankommt.
4. Fahre nach Auberdine. Sobald du in Kalimdor gelandet bist, drücke dort F10 und wähle dein nächstes Ziel wie gewohnt.

### Ein Portal benutzen

1. Drücke F10, suche "Portal" und wähle "Portal nach Orgrimmar" (oder ein beliebiges Portal, das du brauchst).
2. Geh die Route. Vor dem Portal hörst du "Gleich vor dir: geh in das Portal, danach geht die Route weiter".
3. Geh in das Portal. Auf der anderen Seite hörst du "Die Route geht weiter", dann die neue Zusammenfassung.

### Eine versperrte Stelle

1. Du folgst einer Route und läufst gegen einen Zaun, den die Daten nicht kennen. WowNav versucht, selbst zurückzufinden.
2. Steckst du immer noch fest, drücke die Taste, die du auf Neue WowNav-Route um eine versperrte Stelle gelegt hast. Du hörst "Neue Route wird gesucht".
3. Folge dem neuen Beacon. Die versperrte Verbindung wird für den Rest dieser Route gemieden.

## Verwandte Seiten

- [Navigation und Routen](./navigation.md): das Navigationsfenster, Beacon, Ankunftsdistanz und alle Routentasten.
- [Scanner](./scanner.md): Eingabe öffnet auch dort das Navigationsfenster mit WowNav.
- [Bewegung und Orientierung](./movement.md): der Kompass, Folgen, Fallen und der Leichenlauf.
- [Die Oberfläche bedienen](../basics/interface.md): allgemeine Tasten in WowVision-Fenstern.
