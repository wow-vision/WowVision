# Fehlerbehebung

Diese Seite listet die Probleme auf, auf die Spieler am häufigsten stoßen, jeweils mit der wahrscheinlichen Ursache und dem, was du tun kannst. Wenn dir hier nichts hilft, erklärt der letzte Abschnitt, wie du einen Fehler meldest, damit er behoben werden kann.

Viele der Prüfungen benutzen Slash-Befehle. Du tippst sie in das Chatfeld des Spiels. Einige geben ihre Antwort in deinem Chatfenster aus, statt sie zu sprechen; öffne das Chatfenster mit Umschalt+F3, um sie nachzulesen. Jeder Befehl ist unter [Slash-Befehle](../reference/commands.md) beschrieben.

Egal, welches Problem du hast: Tippe zuerst /reload und drücke Eingabe. Das lädt die Oberfläche neu und behebt die meisten fehlenden Daten und hängenden Fenster.

## WowVision lädt nicht

Anzeichen: Umschalt+F1 tut nichts, /wv tut nichts (oder das Spiel sagt, den Befehl gebe es nicht), und du hörst keine Ansagen von WowVision.

Geh diese Liste der Reihe nach durch.

1. Ist das Addon eingeschaltet? Tippe /enableaddons ins Chatfeld und drücke Eingabe. Das ist der eigene Befehl des Spiels: Er schaltet alle deine Addons ein und lädt die Oberfläche neu. Siehe [Das Addon einschalten](./installation.md#das-addon-einschalten).
2. Ist es veraltet? Nach einem Spielpatch warnt dich der Anmeldebildschirm vor veralteten AddOns, und das Spiel lädt sie meist nicht. Starte den WowVision-Updater und wähle Jetzt aktualisieren, oder lade, wenn du von Hand installiert hast, eine neuere WowVision herunter. Siehe [Veraltete AddOns](./installation.md#veraltete-addons).
3. Hast du das Spiel neu gestartet? Ein neu kopiertes Addon wird nur beim Start des Spiels gefunden. /reload reicht nicht.
4. Liegt es in einem verschachtelten Ordner? Die TOC-Dateien müssen unter AddOns\WowVision\WowVision_Standard.toc liegen (und die vier Geschwister), nicht unter AddOns\WowVision\WowVision\WowVision_Standard.toc. Das Entpacken "in einen neuen Ordner" verursacht das. Siehe [der Fehler mit dem verschachtelten Ordner](./manual-installation.md#der-häufige-fehler-ein-verschachtelter-ordner).
5. Liegt es im Ordner der richtigen Spielversion? Classic Era benutzt `_classic_era_`, das Burning-Crusade-Anniversary `_anniversary_`, Mists `_classic_`, Retail `_retail_` und WoW: Forever `_forever_`. Ein Addon im Ordner einer anderen Version wird vom gestarteten Spiel einfach nie gesehen. Siehe [Wo du es ablegst](./manual-installation.md#wo-du-es-ablegst).
6. Steht eine andere Kopie im Weg? Zwei Kopien des Addons in verschiedenen Ordnern oder eine alte Kopie namens WowVision-beta oder ähnlich können das Spiel verwirren. Behalte genau einen Ordner WowVision pro Spielversion.

Um zu bestätigen, dass WowVision läuft, drücke Umschalt+F1. Öffnet sich das Menü, funktioniert es.

## Ich höre überhaupt keine Sprache

WowVision spricht über die Text-to-Speech-Stimmen, die das Spiel anbietet, also die Stimmen, die in Windows installiert sind. Ohne Sprache kannst du das WowVision-Menü nicht benutzen. Diese Schritte benutzen deshalb nur Befehle, die du blind ins Chatfeld tippst.

1. Neu laden. Tippe /reload und drücke Eingabe.
2. Die Spracheinstellungen zurücksetzen. Tippe /wv speech 0 0 100 und drücke Eingabe. Das wählt die erste Stimme, die normale Geschwindigkeit und volle Lautstärke. Hörst du danach "Speech voice ...", funktioniert die Sprache wieder.
3. Eine andere Stimme probieren. Bleibt die erste Stimme stumm, probiere die nächsten: /wv speech 1, /wv speech 2 und so weiter. Die Nummern zählen die in Windows installierten Stimmen, beginnend bei 0.
4. Die Windows-Stimmen prüfen. Öffne mit deinem Screenreader die Windows-Einstellungen, Zeit und Sprache, Sprache (Speech), und stelle sicher, dass mindestens eine Stimme installiert ist. Das Spiel kann nur diese Stimmen benutzen.
5. Hast du es selbst abgeschnitten? Das Drücken einer der beiden Strg-Tasten stoppt die Sprache, die gerade läuft. Drückst du Strg genau in dem Moment, in dem etwas angesagt wird, hörst du nichts.
6. Benutzt du eine Stimme, die den Text an NVDA weiterreicht (zum Beispiel SAPI2SR)? Bleibt sie stumm, wechsle mit /wv speech und der Nummer einer normalen Windows-Stimme, wie in Schritt 3.
7. Stockt oder stoppt die Sprache nach einer Weile? Auf Retail, TBC, Mists und WoW: Forever hat das Modul Sprache die Einstellung Sprachwarteschlange (standardmäßig an), die WowVision eine Zeile nach der anderen sprechen lässt. Auf Classic Era entspricht ihr Sprachstil mit den Auswahlmöglichkeiten Direkt und Gepuffert. Wenn die Sprache stockt, schalte diese Einstellung um.

## Die Sprache ist zu langsam, zu schnell oder die Stimme falsch

- Geschwindigkeit und Lautstärke: Sprachgeschwindigkeit reicht von -10 bis 10 (Standard 0) und Sprachlautstärke von 0 bis 100 (Standard 100; WowVision sendet nie mehr als 100, denn eine höhere Lautstärke würde die Sprache des Spiels zum Schweigen bringen). Ändere sie im Modul Sprache des WowVision-Menüs oder alle zusammen mit /wv speech.
- Die Nummer deiner Stimme finden: Tippe /wv speech ohne etwas dahinter. Es gibt deine aktuelle Stimme, Geschwindigkeit und Lautstärke aus und listet jede Stimme mit ihrer Nummer auf, etwa "Voice 0: Microsoft David Desktop". Deine erste Stimme hat die Nummer 0.
- Stimme, Geschwindigkeit und Lautstärke in einem Zug setzen: /wv speech 1 9 100 wählt Stimme 1, Geschwindigkeit 9, Lautstärke 100. Geschwindigkeit und Lautstärke kannst du weglassen, um die aktuellen Werte zu behalten.
- Automatisch machen: Lege ein Makro an, das die Zeile /wv speech 1 9 100 enthält, und drücke es nach dem Login oder nach /reload. Wie du Makros anlegst, steht unter [Menüs, Optionen und Dialoge](../windows/system.md).
- Die Stimme hat sich nach einem Windows-Update geändert. WowVision merkt sich deine Stimme anhand ihres Namens, nicht ihrer Nummer. Das Installieren oder Entfernen von Windows-Stimmen schaltet dich also nicht auf eine andere um. Wenn Windows eine Stimme eine Zeit lang weglässt, spricht WowVision mit der Standardstimme und holt deine Wahl zurück, wenn die Stimme wiederkommt.
- Ein Alarm klingt anders als der Rest. Jeder gesprochene Alarm hat seine eigene Einstellung Stimme. Sie folgt der Sprachstimme, bis du bei diesem Alarm eine andere wählst. Siehe [Alarme](../basics/alerts.md).

Mehr zu Stimmen steht unter [Sprache und Ton](../basics/speech.md).

## Meine Tasten tun nichts

Finde zuerst heraus, welche Art von Taste du meinst. Es gibt zwei.

- Fenstertasten (Pfeile, Tab, Eingabe, Rücktaste, Esc, Leertaste, Pos1, Ende und der Rest der Navigation) funktionieren nur, solange ein WowVision-Fenster offen ist. Ohne Fenster machen diese Tasten, was das Spiel mit ihnen macht. Das ist Absicht, damit die Pfeile weiter laufen lassen.
- Globale Tasten (Puffer, Navigation, Umschalt+F1, F9, F10, Umschalt+F3 und so weiter) funktionieren jederzeit.

Wenn eine Taste nichts tut, prüfe diese Ursachen.

1. Du bist im Kampf. Überschreibende Belegungen lassen sich im Kampf nicht ändern. Deshalb gibt WowVision alle Fenstertasten an das Spiel zurück, wenn ein Kampf beginnt, und übernimmt sie danach wieder. Globale Tasten funktionieren weiter. Siehe [Kampf](../world/combat.md).
2. Kein Fenster ist offen. Fenstertasten brauchen ein offenes Fenster. Drücke die Taste, die eines öffnet (zum Beispiel Umschalt+F1 für das Menü), und versuche es noch einmal.
3. Ein Textfeld des Spiels hat die Tastatur. Solange du in das Chatfeld oder ein anderes Eingabefeld tippst, gehen Buchstaben und Pfeile in den Text.
4. Eine Taste wurde noch gehalten, als sich das Fenster öffnete. WowVision wartet mit dem Übernehmen seiner Tasten, bis jede Taste, die es benutzt, losgelassen ist, damit das Spiel nie ein Loslassen verpasst. Lass alle Tasten los, dann übernimmt das Fenster sie binnen Kurzem.
5. Ein anderes Addon oder eine Spielbelegung hat dieselbe Taste. Öffne das WowVision-Menü (Umschalt+F1), dann Benutzeroberfläche, dann Tastenbelegung, und sieh nach, worauf die Belegung gesetzt ist. Wenn du eine Taste hinzufügst, die eine andere WowVision-Belegung schon benutzt, wirst du gefragt "Diese Eingabe steht in Konflikt mit ... Ersetzen?". Tasten, die andere Addons oder das Spiel belegen, werden nicht geprüft, probiere also eine andere Taste. Siehe [Tastenbelegung](../basics/keybindings.md).
6. Sku ist geladen. WowVision überlässt einige Tasten Sku. Siehe unten.
7. Du hast die Taste umbelegt oder entfernt. Manche Belegungen brauchen mindestens eine Taste und lassen sich nicht leeren, die meisten aber schon. Die [Tastenreferenz](../reference/keybindings.md) listet die Standardwerte auf.
8. Buchstaben springen, statt etwas auszulösen. Im WowVision-Menü, in Kontextmenüs und in Dropdown-Listen springt das Tippen eines Buchstabens zum nächsten Eintrag, der damit beginnt. Das lässt sich mit Buchstaben-Navigation in Menüs im Modul Benutzeroberfläche ausschalten.

### Esc und das Schließen von Fenstern

Esc funktioniert auf zwei Arten. Bei einem Fenster, das aus einem der eigenen Frames des Spiels entsteht (ein Händler, die Taschen, der Briefkasten), überlässt WowVision Esc dem Spiel, und das Spiel schließt seinen Frame; WowVision schließt sein Fenster, sobald der Frame verschwindet. Bei den eigenen Fenstern von WowVision (das Menü, die Navigation, der Scanner, das Chatfenster, das Fenster der Aktionsleisten und jeder Bildschirm, der innerhalb eines anderen geöffnet wurde) behandelt WowVision Esc selbst. Auf einem Controller macht B automatisch das Richtige von beiden. Siehe [Controller](../controller.md).

Wenn sich ein WowVision-Fenster nicht schließen lässt, tippe /wv close. Das schließt alle offenen WowVision-Fenster auf einmal. Die eigenen Frames des Spiels bleiben offen.

### Die Pfeiltasten laufen nicht mehr, oder mein Charakter dreht sich dauernd

Ein offenes WowVision-Fenster nimmt die Pfeiltasten. Schließe das Fenster (Esc oder /wv close), dann laufen die Pfeile wieder.

Wenn sich der Charakter von allein dreht oder läuft, heißt das meist, dass beim Öffnen eines Fensters eine Bewegungstaste gehalten wurde und das Spiel das Loslassen verpasst hat. Drücke die Taste und lass sie los, um zu stoppen. Damit die Entwickler die Ursache finden, tippe /wv keylog, um die Tastenprotokollierung einzuschalten, spiele weiter, bis es wieder passiert, und schicke die WowVision-Zeilen aus deinem Chatprotokoll zusammen mit dem, was du gerade getan hast. Tippe /wv keylog noch einmal, um sie auszuschalten.

## Ein Fenster oder eine Taste funktioniert ohne Sku, aber nicht mit Sku

Du hast Sku geladen. Ist Sku geladen, überlässt WowVision bewusst eine Liste von Fenstern, Tasten und Befehlen Sku. Das Fenster öffnet sich dann in WowVision nicht, oder die Taste tut nichts. Die vollständige Liste steht unter [WowVision zusammen mit Sku verwenden](./sku.md).

Um die WowVision-Version dieses Fensters oder dieser Taste zu bekommen, schalte Sku aus:

- Tippe /disableaddon sku. Das schaltet Sku und seine Audio- und Beacon-Hilfs-Addons aus und lädt die Oberfläche neu. /enableaddon sku schaltet sie wieder ein.
- Diese beiden Befehle stehen nicht zur Verfügung, wenn das Addon BlindSlash geladen ist. Deaktiviere Sku in dem Fall stattdessen in der AddOns-Liste des Spiels.
- Die Änderung braucht ein /reload oder einen neuen Login, um zu wirken; /disableaddon lädt für dich neu.

Deine WowVision-Einstellungen und Tastenbelegungen für diese Funktionen werden nicht gelöscht, solange Sku läuft; sie kommen zurück, sobald Sku aus ist.

## Meine Einstellungen gehen verloren

Einstellungen werden gespeichert, wenn du dich ausloggst oder /reload tippst. Ein Absturz oder das Schließen des Spiels über den Task-Manager verliert alles seit dem letzten Speichern.

1. Zuerst neu laden. Wenn Einstellungen oder andere Daten zu fehlen scheinen, tippe /reload. Oft sind sie danach wieder da.
2. Sie gehören zu einem anderen Bereich. Standardmäßig teilen sich alle Charaktere die meisten Einstellungen (Account-Bereich). Wenn du ein Modul auf einen einzelnen Charakter gelegt hast, erscheinen seine Einstellungen nur bei diesem Charakter. Setze im WowVision-Menü den Fokus auf das Modul, drücke Umschalt+F10 und sieh dir Bereich an. Tastenbelegungen und einige andere Dinge gelten immer pro Charakter. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).
3. Ein neues Release hat etwas zurückgesetzt. Die Versionshinweise sagen, wann ein Update eine Einstellung ändert.

Wenn Einstellungen trotzdem nicht bleiben, melde es (siehe [Einen Fehler melden](#einen-fehler-melden)) und füge die Ausgabe von /wv dbcheck bei. Der Befehl gibt einen kurzen Bericht über deine gespeicherten Einstellungen im Chatfenster aus.

## Das Spiel ruckelt oder hängt

- Schließe Fenster, die du nicht benutzt. WowVision baut ein offenes Fenster ständig neu auf.
- Wenn das Ruckeln beim Laufen im Freien auftritt, schalte Verfolgte Punkte beim Laufen ansagen im Modul Minikarten-Scanner aus; es liest die Minikarte zweimal pro Sekunde, während du dich bewegst. Siehe [Minikarte](../world/minimap.md).
- Wenn es im Kampf oder im Schlachtzug auftritt, prüfe, wie viele Monitore du laufen hast. Siehe [Monitore](../information/monitors.md).
- Versuche, mit WowVision als einzigem Addon zu spielen, um zu sehen, ob ein anderes Addon die Ursache ist.

Um ein Lag-Problem zu melden, tippe /wv gperf: Es misst die Arbeit von WowVision pro Frame über 120 Frames und liest die kürzeste, die durchschnittliche und die längste Zeit vor. Füge diese Zeile deiner Meldung bei.

## Spielfehler und die Ansage "Blocked"

- Du hörst "Lua-Fehler: ..." WowVision liest jeden Skriptfehler laut vor, aber denselben nicht öfter als alle fünf Sekunden. Um den vollen Text zu lesen, tippe /wv errors. Es spricht den letzten Fehler und öffnet ein Fenster mit allen Fehlern und ihren Stack-Traces. Der Text ist markiert, drücke also Strg+C, um ihn zu kopieren, und Esc, um das Fenster zu schließen. /wv errors all zeigt auch ältere Verläufe, wenn BugSack oder BugGrabber installiert ist. /wv errors clear leert die Liste. WowVision behält die letzten 20 Fehler, und sie überleben /reload. Um die gesprochenen Fehler auszuschalten, schalte Fehler ansagen im Modul Fehler aus. Um nur bestimmte Spielmeldungen (wie "Außer Reichweite") stummzuschalten, benutze Filter pro Fehler im selben Modul; siehe [Kampf](../world/combat.md).
- Du hörst "Blocked: ..." gefolgt von einem Namen. (Auch diese Ansage kommt auf Englisch.) Das Spiel hat einen Aufruf abgelehnt, den WowVision machte, während eine geschützte Aktion lief (auch ein blockiertes Makro wird angesagt). Blockierungen durch andere Addons werden aufgezeichnet, aber nicht gesprochen. Es ist kein Lua-Fehler, bedeutet aber, dass etwas nicht funktioniert hat. Tippe /wv taint, um die aufgezeichneten Blockierungen mit Zeit und dem, was den Fokus hatte, aufzulisten. /wv taint clear leert die Liste. Erwähne es in einer Fehlermeldung.
- Die Fehlerliste ist leer, aber offensichtlich stimmt etwas nicht. Ist BugSack oder BugGrabber installiert, übernimmt es den Fehlerhandler und hält die Fehler in seiner eigenen Liste; /wv errors liest sie zuerst.

## Die weiche Zielerfassung verhält sich seltsam

Die weiche Zielerfassung ändert Konsolenvariablen des Spiels, und manche davon lassen sich im Kampf nicht ändern. Tippe /wv soft, um den Sperrmodus und den Wert jeder Variable der weichen Zielerfassung zu sehen, mit dem Standardwert des Spiels in Klammern, und einen Hinweis, wenn eine Änderung auf das Kampfende wartet. Was jede Einstellung der weichen Zielerfassung bewirkt, steht unter [Zielerfassung](../world/targeting.md).

## Der Controller tut nichts

Die Controller-Unterstützung gibt es für Retail und WoW: Forever. In den Spieloptionen unter Gamepad müssen Gamepad aktivieren (Enable Gamepad) und Gamepad-Oberfläche aktivieren (Enable Gamepad UI) beide an sein. Im Kampf gibt WowVision die Fenstertasten an das Spiel zurück. Alles Weitere steht unter [Controller](../controller.md), auch wie du mit /wv padlog für eine Fehlermeldung ein frisches Protokoll beginnst.

## Ich hänge auf einer Route fest

Das Beacon führt dich an eine Stelle, an der du nicht weiterkommst, oder ein Wegpunkt gilt nie als erreicht. Probiere Folgendes, eins nach dem anderen:

- Spring nach vorn. Oft hält dich eine kleine Kante, eine Stufe oder eine Wurzel auf, und ein Sprung bringt dich darüber.
- Geh ein paar Schritte nach links oder rechts und dreh dich dann wieder zum Wegpunkt. Die direkte Linie kann in einen Pfosten, eine Ecke oder eine Kiste laufen.
- Überspring den Wegpunkt: Strg+W verschiebt das Beacon zum nächsten Wegpunkt.
- Geh einen Wegpunkt zurück: Strg+S verschiebt das Beacon zum vorherigen Wegpunkt. Lauf zu ihm und versuch das Stück noch einmal.
- Ändere die Ankunftsdistanz mit Alt+P. Eine kürzere Distanz führt dich genauer durch eine Tür oder einen engen Durchgang. Eine weitere Distanz lässt einen Wegpunkt früher als erreicht gelten. Das hilft, wenn du nicht genau auf seiner Stelle stehen kannst.
- Sprich den NPC an, den du suchst. Manchmal steht er direkt vor dir, aber ein Tresen oder ein Tisch ist dazwischen, wie bei der Bank in Sturmwind. Den letzten Wegpunkt erreichst du dort nie. Nimm den NPC ins Ziel und drück deine Interaktionstaste; das Spiel führt dich so nah heran wie möglich und öffnet das Fenster.
- Auf einer WowNav-Route drück die Taste, die du auf Neue WowNav-Route um eine versperrte Stelle gelegt hast. Sie sucht einen Weg um die Stelle, an der du festhängst. Siehe [WowNav](../world/wownav.md#eine-versperrte-stelle).

Nächster Wegpunkt, Vorheriger Wegpunkt und Ankunftsdistanz wechseln kannst du im Fenster für die Tastenbelegung auf andere Tasten legen: WowVision-Menü, Benutzeroberfläche, Tastenbelegung. Die Tasten für Routen stehen unter [Navigation](../world/navigation.md#nächster-und-vorheriger-wegpunkt).

## Einen Fehler melden

Bitte melde Probleme auf GitHub: [das WowVision-Projekt](https://github.com/wow-vision/WowVision). Eröffne ein Issue und beschreibe:

- Was du getan hast, was du zu hören erwartet hast und was stattdessen passiert ist.
- Deine Spielversion (Classic Era, TBC, Mists, Retail oder WoW: Forever) und deine WowVision-Version, die /wv version ausgibt.
- Welche anderen Addons du benutzt, besonders Sku, BlindSlash, Questie und BugSack.

Füge dann die Protokolle bei, die zum Problem passen. Jedes davon ist ein Fenster mit markiertem Text; drücke Strg+C, um ihn zu kopieren, und füge ihn in das Issue ein.

| Problem | Befehl zum Ausführen und Anhängen |
|---|---|
| Ein Skriptfehler | /wv errors |
| "Blocked: ..." oder etwas, das nur außerhalb des Kampfes funktioniert | /wv taint |
| Controller-Probleme (Retail, WoW: Forever) | /wv padlog kurz bevor du das Problem zeigst, dann /reload |
| Zum Wegpunkt drehen dreht in die falsche Richtung | /wv turnlog |
| Monitore des Abklingzeitmanagers auf Retail oder Forever | /wv cdmlog |
| Ein Charakter, der sich von allein dreht oder läuft | /wv keylog |
| Weiche Zielerfassung | /wv soft |
| Verlorene Einstellungen | /wv dbcheck |
| Minikarten-Scan oder Laufansagen | /wv mscan log |
| Questdaten | /wv quests probe |

Einige dieser Protokolle werden auch in der gespeicherten Variable WowVisionDump abgelegt, die das Spiel auf die Festplatte schreibt, wenn du dich ausloggst oder /reload tippst. Hänge die Datei WowVisionDump.lua aus dem Ordner SavedVariables in deinem WTF-Verzeichnis an. Wo sie liegt, steht unter [Installation](./managing.md#wo-deine-einstellungen-gespeichert-werden). Sie kann Charakternamen enthalten, sieh sie also durch, bevor du sie weitergibst.
