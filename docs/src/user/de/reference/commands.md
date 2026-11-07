# Slash-Befehle

WowVision fügt Slash-Befehle hinzu, die du in das Chatfeld des Spiels tippst. Diese Seite listet jeden einzelnen auf: was er tut, wie du ihn tippst, ein Beispiel und in welchen Spielversionen es ihn gibt.

Die Befehle selbst tippst du immer genau so, wie sie hier stehen. Auch die Antworten, die sie im Chat ausgeben, sind meist englisch; wo es eine deutsche Übersetzung gibt (zum Beispiel bei "Beacon set" und "No route found"), steht sie in den Beispielen unten (Ansage auf Englisch, wenn nicht übersetzt).

## So funktionieren Befehle

Es gibt zwei Arten.

- /wv-Befehle beginnen mit /wv, gefolgt von einem Wort, zum Beispiel /wv speech 1 9 100. Bei dem Wort kommt es nicht auf Groß- und Kleinschreibung an. /wv allein öffnet das WowVision-Menü, und das tut auch /wv gefolgt von einem Wort, das kein Befehl ist.
- Globale Befehle sind ein eigenes Slash-Wort, zum Beispiel /beacon oder /pquit.

Tippe einen Befehl in das Chatfeld (öffne es mit Eingabe oder der Chattaste des Spiels) und drücke Eingabe. Antworten kommen auf verschiedene Weise zurück:

- Von WowVision gesprochen.
- In dein Chatfenster ausgegeben. Öffne das WowVision-Chatfenster mit Umschalt+F3, um ausgegebene Zeilen zu lesen.
- In einem Fenster mit markiertem Text angezeigt. Drücke Strg+C, um den Text zu kopieren, zum Beispiel in eine Fehlermeldung, und Esc, um das Fenster zu schließen.

Sofern ein Befehl nichts anderes sagt, gibt es ihn in allen Spielversionen: Classic Era, The Burning Crusade (TBC), Mists of Pandaria (Mists), Retail und WoW: Forever.

## Auf einen Blick

| Befehl | Was er tut | Versionen |
|---|---|---|
| /wv | Öffnet das WowVision-Menü | alle |
| /wv speech | Setzt oder listet Sprachstimme, Geschwindigkeit und Lautstärke | alle |
| /wv bind | Öffnet das Fenster für die Tastenbelegung | alle |
| /wv close | Schließt jedes WowVision-Fenster | alle |
| /wv version | Gibt die WowVision-Version aus | alle |
| /wv accept | Nimmt eine Gruppeneinladung an, auch im Kampf | alle |
| /beacon | Setzt ein Beacon, routet zu einem benannten Ort oder liest deine Position vor | alle |
| /focus1 bis /focus5 | Setzt ein virtuelles Fokusziel | alle, nicht mit Sku |
| /pquit | Verlässt deine Gruppe | alle, nicht mit Sku |
| /dquit | Verlässt die Dungeongruppe oder das Schlachtfeld | alle, nicht mit Sku |
| /enableaddon, /disableaddon | Schaltet ein Addon ein oder aus und lädt neu | alle, nicht mit BlindSlash |
| /wv soft | Liest die Werte der weichen Zielerfassung vor | alle |
| /wv targetinfo | Listet auf, was jede Angabe der Zielansage für dein Ziel sagt | alle |
| /wv mscan | Minikarten-Scan und sein Protokoll | wo der Minikarten-Scan funktioniert |
| /wv quests | Prüfung der Questdaten | alle |
| /wv errors | Zeigt Lua-Fehler | alle |
| /wv taint | Zeigt blockierte geschützte Aufrufe | alle |
| /wv dbcheck | Meldet den Zustand der gespeicherten Variablen | alle |
| /wv turnlog | Listet die letzten Drehungen zu einem Wegpunkt | alle |
| /wv keylog | Protokolliert die Tastenbehandlung der Fenster | alle |
| /wv padlog | Startet das Controller-Protokoll neu | Retail und WoW: Forever (Gamepad-Oberfläche an) |
| /wv cdmlog | Protokoll der Monitore des Abklingzeitmanagers | Retail und WoW: Forever |

## Alltägliche Befehle

### /wv

Öffnet das WowVision-Menü, genau wie Umschalt+F1. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

### /wv speech

Setzt deine Sprachstimme, Geschwindigkeit und Lautstärke in einem Zug. Praktisch in einem Makro, das du nach dem Login oder nach /reload drückst.

Syntax: /wv speech Stimme Geschwindigkeit Lautstärke

| Argument | Bedeutung |
|---|---|
| Stimme | Die Nummer einer Stimme. Deine erste Stimme hat die Nummer 0. |
| Geschwindigkeit | Die Sprechgeschwindigkeit von -10 bis 10. Werte außerhalb werden auf diesen Bereich gekappt. Optional. |
| Lautstärke | Die Lautstärke von 0 bis 100. Optional. |

Geschwindigkeit und Lautstärke kannst du weglassen, um die aktuellen Werte zu behalten.

Ohne etwas dahinter gibt /wv speech deine aktuelle Stimme, Geschwindigkeit und Lautstärke aus und listet jede installierte Stimme mit ihrer Nummer auf, zum Beispiel "Voice 0: Microsoft David Desktop".

Beispiel: /wv speech 1 9 100 wählt Stimme 1, Geschwindigkeit 9, Lautstärke 100 und spricht "Speech voice ... rate 9, volume 100". Eine unbekannte Stimmnummer gibt "No voice with id 5. Type /wv speech to list the voices" aus. Alles, was keine Zahlen sind, gibt "Usage: /wv speech voiceID rate volume, for example /wv speech 1 9 100" aus.

Versionen: alle. Siehe [Sprache und Ton](../basics/speech.md).

### /wv bind

Öffnet das Fenster für die Tastenbelegung direkt, denselben Bildschirm wie WowVision-Menü (Umschalt+F1), Benutzeroberfläche, Tastenbelegung. Esc schließt es. Siehe [Tastenbelegung](../basics/keybindings.md).

### /wv close

Schließt jedes offene WowVision-Fenster auf einmal. Benutze ihn, wenn ein Fenster festzuhängen scheint. Die eigenen Frames des Spiels werden nicht geschlossen. Versionen: alle.

### /wv version

Gibt die installierte WowVision-Version in dein Chatfenster aus, zum Beispiel V0.9.0, oder "beta" bei der Beta-Vorabversion. Versionen: alle.

### /wv accept

Nimmt die Gruppeneinladung an, die gerade angezeigt wird, und sagt "Gruppeneinladung angenommen". Das geht auch im Kampf, wo WowVision das Einladungs-Popup nicht öffnen kann. Ist keine Einladung da, sagt es "Keine Gruppeneinladung". Die Taste Gruppeneinladung annehmen (Accept Group Invitation) tut dasselbe; sie ist unbelegt. Versionen: alle. Siehe [Gruppensuche](../windows/group-finder.md).

### /beacon

Setzt ein Beacon in gerader Linie, routet zu einem benannten Ort oder sagt dir, wo du bist. Das Beacon spielt dann beim Laufen seinen Ton ab und spricht. Es ist dasselbe Beacon, das das Navigationsfenster benutzt. Siehe [Navigation und Routen](../world/navigation.md).

| Getippt | Was es tut |
|---|---|
| /beacon | Spricht deine Position auf der Zonenkarte (zum Beispiel "50.5 30.4") und, wenn ein Beacon aktiv ist, seine Entfernung und die Grad, um die du dich drehen musst |
| /beacon x y | Setzt ein Beacon auf Kartenkoordinaten der aktuellen Zonenkarte: die Prozentwerte, die Questführer angeben, etwa 50.5 30.4 |
| /beacon world x y | Setzt ein Beacon auf rohe Weltkoordinaten |
| /beacon to Name | Routet mithilfe der Kartendaten zum nächsten bekannten Ort, dessen Name den Text enthält. Gib einen Teil eines Namens an, etwa "mailbox". |
| /beacon stop | Beendet das Beacon oder die Route, genau wie Umschalt+F12 |

Beispiele: /beacon 50.5 30.4 sagt "Beacon gesetzt 245 Meter" und startet ein Beacon in gerader Linie zu dieser Stelle; es öffnet nicht das Navigationsfenster. /beacon to innkeeper spricht den gefundenen Ort und startet eine Route dorthin, oder sagt "Keine Route gefunden innkeeper". /beacon 12 mit nur einer Zahl sagt "Usage beacon x y".

Versionen: alle. /beacon to braucht Kartendaten für den Kontinent, auf dem du bist; siehe [Navigation und Routen](../world/navigation.md).

### /focus1 bis /focus5

WoW unterstützt nur ein Fokusziel. WowVision fügt fünf virtuelle hinzu, die du dann mit den Belegungen Zielfokus 1 bis Zielfokus 5 (Target Focus 1 bis 5; standardmäßig unbelegt) erfassen kannst.

Syntax: /focus1 (oder 2 bis 5), optional gefolgt von einer Einheit.

- /focus1 ohne etwas dahinter setzt Fokus 1 auf dein aktuelles Ziel. Ohne Ziel bleibt der alte Fokus, und es erscheint "Kein Ziel. Benutze `/focus1 <Name>` oder erfasse ein Ziel."
- /focus1 party1 setzt ihn auf die Einheit oder den Namen, den du angibst, alles, was der /target-Befehl des Spiels versteht.

Bei einem Ziel merkt sich WowVision den Namen des Ziels, zwei Kreaturen mit demselben Namen lassen sich also nicht unterscheiden. Es gibt "Fokus 1 auf Name gesetzt." aus. Im Kampf funktioniert es nicht und sagt "Virtueller Fokus kann im Kampf nicht gesetzt werden." Versionen: alle. Ist Sku geladen, wird der Befehl nicht registriert. Siehe [Zielerfassung](../world/targeting.md).

### /pquit

Verlässt deine aktuelle Gruppe. Versionen: alle. Wird nicht registriert, wenn Sku geladen ist.

### /dquit

Verlässt deine Dungeon- oder Gruppensuche-Gruppe und verlässt in einem Schlachtfeld oder einer Arena das Schlachtfeld. Außerhalb einer Instanz und außerhalb einer Gruppe der Gruppensuche tut er nichts. Versionen: alle. Wird nicht registriert, wenn Sku geladen ist.

### /enableaddon und /disableaddon

Schaltet ein Addon ein oder aus und lädt die Oberfläche sofort neu.

Syntax: /enableaddon Name und /disableaddon Name. Der Name ist der Ordnername des Addons, Groß- und Kleinschreibung spielen keine Rolle. Ohne Namen geben sie "Syntax: `/enableaddon <name>`" aus. Die Oberfläche lädt auch dann neu, wenn es kein Addon mit diesem Namen gibt.

Beispiel: /disableaddon sku. Der Name sku ist etwas Besonderes: Er schaltet das Addon Sku zusammen mit seinen Audiodaten und Beacon-Addons um, damit nichts halb geladen bleibt. /enableaddon sku schaltet alles wieder ein.

Benutze nicht /disableaddon wowvision; es würde WowVision selbst ausschalten. Diese Befehle werden nicht registriert, wenn das Addon BlindSlash geladen ist. Versionen: alle.

## Hilfsbefehle

### /wv soft

Liest den Modus der weichen Zielerfassung und jeden Spielwert der weichen Zielerfassung vor, je eine Zeile: zuerst den Sperrmodus (Soft Target bei festem Ziel), dann Zeilen wie "SoftTargetEnemy 3 (default 0)". Ein Wert, der auf das Kampfende wartet, wird mit "after combat" und dem Wert markiert, den er bekommt, und ein Wert, den deine Spielversion nicht hat, mit "not available". Die Zeilen werden in den Chat ausgegeben und gesprochen. Siehe [Zielerfassung](../world/targeting.md).

### /wv targetinfo

Listet für dein aktuelles Ziel alles auf, was die Zielansage sagen kann: die Art der Einheit, ob gerade Im Kampf oder Außerhalb des Kampfes gilt, und jede Angabe dieser Art mit dem, was sie für dieses Ziel sagt, ob ihr Kontrollkästchen an ist und ob deine Spielversion sie anbietet. Danach die Zeilen des Tooltips deines Ziels und zuletzt die Ansage, so wie du sie hörst. Die Liste öffnet sich im Ergebnisfenster und steht im Chat, die Ansage wird gesprochen. Eine Angabe, die das Spiel gerade verbirgt, steht dort als <secret>. Das hilft bei Fehlerberichten. Die Zeilen sind auf Englisch. Siehe [Zielerfassung](../world/targeting.md#was-angesagt-wird-namen).

### /wv mscan

Der Minikarten-Scanner. Allein getippt scannt er sofort, genau wie Strg+Umschalt+F. Siehe [Minikarte](../world/minimap.md).

| Getippt | Was es tut |
|---|---|
| /wv mscan | Scannt die Minikarte jetzt |
| /wv mscan list | Zeigt jeden Eintrag, den der Scanner in dieser Sitzung gesehen hat |
| /wv mscan clear | Vergisst jeden gesehenen Eintrag und das Laufgedächtnis und sagt "Gesehene Einträge gelöscht" |
| /wv mscan log | Zeigt, wie der letzte Scan und die Laufprüfung verlaufen sind (für Fehlermeldungen) |
| /wv mscan walk | Zeigt, was sich die Laufprüfung merkt |
| /wv mscan raw | Zeigt eine einzelne ungeparste Lesung der Minikarte (für Fehlermeldungen) |

Versionen: Den Befehl gibt es überall, aber das Scannen braucht eine Spielversion, deren Minikarte sich lesen lässt; sonst hörst du "Minikarten-Scanner auf diesem Client nicht verfügbar".

### /wv quests

Eine Prüfung der Questdaten. Sie gibt im Chat aus, was WowVision über Quests weiß. Sie braucht eine Questdatenquelle: Questie, wo installiert, sonst die eigenen Questdaten des Spiels. Ohne Quelle sagt sie "Keine Questdatenquelle", und "Questie lädt noch", solange Questie startet.

| Getippt | Was es tut |
|---|---|
| /wv quests near (oder einfach /wv quests) | Listet bis zu zehn Quests in der Nähe mit Stufe, Geber und Entfernung |
| /wv quests log | Listet die laufenden Quests mit ihren Zielen |
| /wv quests go questId [start, objectives oder finish] | Listet die Ziele dieser Questphase (Standard: objectives) |
| /wv quests raw [mapId] | Gibt die Rohdaten der Questquelle aus (wenn sie welche hat) |
| /wv quests probe | Ein Bericht über jede Quest- und Kartenpunktquelle, die das Spiel anbietet, in einem Fenster mit gesprochener Zusammenfassung; auch in der gespeicherten Variable WowVisionDump abgelegt. Es funktioniert auch ohne Questdatenquelle. |

Versionen: alle. Siehe [Quests](../world/quests.md).

## Diagnosebefehle

Diese dienen dazu, Probleme zu finden und zu melden. [Fehlerbehebung](../getting-started/troubleshooting.md) sagt, wann du welchen benutzt.

### /wv errors

Zeigt die Lua-Fehler dieser Sitzung. Er spricht den letzten und öffnet ein Fenster mit der ganzen Liste und den Stack-Traces. Ist das Addon BugGrabber oder BugSack installiert, wird zuerst dessen Liste gelesen.

| Getippt | Was es tut |
|---|---|
| /wv errors | Die Fehler dieser Sitzung |
| /wv errors all | Auch die älteren Fehler, die BugGrabber behalten hat |
| /wv errors clear | Leert die Liste von WowVision und, falls installiert, auch die von BugGrabber |

Er gibt "No Lua errors recorded" aus, wenn es keine gibt. WowVision behält die letzten 20 seiner eigenen Liste über /reload hinweg.

### /wv taint

Zeigt die Aufrufe, die das Spiel wegen Taint (einer geschützten Aktion, die aus Addon-Code versucht wurde) blockiert hat, mit Zeit, Ereignis, Addon, Funktion und dem, was die Oberfläche im Fokus hatte. WowVision behält die letzten 30. Ohne Aufzeichnungen sagt er "No blocked calls recorded".

/wv taint clear leert die Liste. Die Aufzeichnungen werden in die gespeicherte Variable WowVisionDump geschrieben, wenn du /reload tippst. Du hörst auch "Blocked: ...", wenn WowVision selbst blockiert wird.

### /wv dbcheck

Gibt einen kurzen Bericht über deine gespeicherten Einstellungen im Chatfenster aus. Du musst ihn nicht verstehen: Füge ihn einer Fehlermeldung bei, wenn deine Einstellungen verloren gehen. Siehe [Meine Einstellungen gehen verloren](../getting-started/troubleshooting.md#meine-einstellungen-gehen-verloren).

### /wv turnlog

Listet die letzten Drehungen von Zum Wegpunkt drehen auf, je eine Zeile mit ihrem Fehler in Grad, in einem Fenster und im Chat. Er spricht eine Zusammenfassung wie "12 turns, mean error 2.4 degrees" oder "No turns yet".

### /wv keylog

Schaltet das Tastenprotokoll ein oder aus und gibt "WowVision key log on" oder "off" aus. Solange es an ist, zeigt der Chat, wann Fenster die Navigationstasten übernehmen, auf sie warten und sie freigeben und was die Prüfung gehaltener Tasten gesehen hat. Benutze es, wenn sich ein Charakter von allein dreht oder läuft.

### /wv padlog

Startet das Controller-Protokoll neu. Es gibt "WowVision pad log started afresh" oder "WowVision pad log: only with the gamepad interface on" aus. Der Befehl ist in jeder Spielversion registriert, protokolliert aber nur bei eingeschalteter Gamepad-Oberfläche, also in Retail oder WoW: Forever. Siehe [Controller](../controller.md).

### /wv cdmlog

Zeigt, was die Regeln der Auren des Abklingzeitmanagers (Cooldown Manager Auras) gesehen haben.

| Getippt | Was es tut |
|---|---|
| /wv cdmlog | Das Protokoll dessen, was die Regeln gesehen haben (spricht auch die neueste Zeile) |
| /wv cdmlog clear | Leert das Protokoll |
| /wv cdmlog spells | Listet die verfolgten Buff- und Leisteneinträge deines Abklingzeitmanagers |
| /wv cdmlog cooldowns | Listet die Einträge "essential" und "utility" |

Versionen: Retail und WoW: Forever. Siehe [Monitore](../information/monitors.md).

## Spielbefehle, die WowVision benutzt

Diese gehören dem Spiel, nicht WowVision:

- /reload lädt die Oberfläche neu und speichert deine Einstellungen auf die Festplatte.
- /tts playline und /tts playactivity schalten die Töne des Spiels rund um die Sprachausgabe um. WowVision zeigt beide als Einstellungen im Modul Sprache (Ton zwischen Chatzeilen und Aktivitätston bei verborgenem Chatfenster).
- /cdm öffnet die Einstellungen des Abklingzeitmanagers des Spiels, die WowVision als Fenster liest (Retail und WoW: Forever).

## Für Entwickler und Fehlermeldungen

Diese Befehle sind für die Leute gedacht, die an WowVision arbeiten. Du brauchst sie normalerweise nie, aber ein Entwickler bittet dich vielleicht, einen auszuführen.

| Befehl | Was er tut |
|---|---|
| /wv dev | Macht ein paar Entwicklerfunktionen für die Skriptzeile des Spiels verfügbar |
| /wv tests [Suite] [--verbose] | Führt die eingebauten Tests aus und zeigt die Ergebnisse in einem Fenster |
| /wv gmenu | Öffnet das WowVision-Menü (wie /wv) |
| /wv gsettings Modul | Öffnet den Einstellungsbildschirm eines Moduls, zum Beispiel /wv gsettings speech |
| /wv gnode | Gibt die Struktur des fokussierten Elements aus |
| /wv glive | Gibt den Live-Watch-Zustand des fokussierten Elements aus |
| /wv gdump Ausdruck | Wertet einen Lua-Ausdruck aus und beschreibt das Ergebnis |
| /wv gperf | Misst die Update-Schleife der Oberfläche über 120 Frames und meldet Minimum, Durchschnitt und Maximum in Millisekunden |
| /wv gdrop | Gibt das offene Dropdown-Menü aus |
| /wv bigmenu [Zahl] | Öffnet ein langes, scrollendes Testmenü mit der angegebenen Zahl an Einträgen (60, wenn weggelassen), mit Kontrollkästchen, Optionsfeldern, einem Stufenbereich, einer Zeile aus mehreren Steuerelementen und einem Schieberegler; eine Auswahl wird im Chat ausgegeben |
| /wv bigmenu dump | Öffnet dasselbe Testmenü und gibt es eine Sekunde später aus, so wie /wv gdrop es tut |
| /wv cctest [Einheit] | Prüft, ob eine Einheit (ohne Angabe dein Ziel) unter CC steht, und gibt aus, wie sich das Ergebnis über die nächsten Frames ändert |
| /wv cctest watch | Schaltet eine Prüfung ein oder aus, die bei jedem Zielwechsel eine Zeile ausgibt, die das Ergebnis Frame für Frame zeigt |
| /wv gtooltip | Gibt den Zustand des Tooltip-Lesers aus |
| /wv profile | Profiler: allein startet er, oder report, reset, stop |
| /wv testcd | Baut einen Test-Abklingzeitmonitor |
| /wv dump waypoints oder /wv dump links | Schreibt die Wegpunktdaten von Sku in die gespeicherte Variable WowVisionDump; braucht geladenes Sku, danach /reload |
| /uiinsp | Öffnet einen kleinen Tasteninspektor, der den Namen jeder gedrückten Taste ausgibt; Esc schließt ihn |

Alles in dieser Tabelle kann sich ohne Vorankündigung ändern oder verschwinden.
