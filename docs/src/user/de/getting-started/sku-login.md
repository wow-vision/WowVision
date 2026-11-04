# Anmelden mit dem Sku-Login-Tool

WowVision beginnt zu arbeiten, sobald dein Charakter in der Spielwelt steht. Erst dann lädt das Spiel Addons, also kann kein Addon, auch WowVision nicht, die Bildschirme davor vorlesen; nur das Spiel selbst könnte sie zugänglich machen. WoW: Forever liest seine Anmeldebildschirme zwar vor, sie brauchen aber trotzdem die Maus; das Tool hilft also auch dort. Um durch den Anmeldebildschirm, die Realmliste, die Charakterauswahl und die Charaktererstellung zu kommen, kannst du das WoW Login Tool (Version 4.x) benutzen, das zu Sku gehört. Diese Seite erklärt, was es ist, wie du es bekommst und wie du es benutzt, damit du an WowVision übergeben kannst, sobald du die Welt betrittst.

Eine Vorbemerkung zu den Zitaten auf dieser Seite: Das Login-Tool hat eigene Sprachdateien. Die Ansagen und Menüeinträge, die hier in Anführungszeichen oder fett stehen, sind der deutsche Wortlaut des Tools, so wie du ihn hörst, wenn du das Tool auf Deutsch gestellt hast. Bei der ersten Erwähnung steht manchmal die englische Fassung in Klammern. Das Tool nennt die Tasten teils anders als deine Tastatur: Es sagt "Enter" für die Eingabetaste und "Escape" für Esc. Bei Realms sagt das Tool "Server"; das Spiel selbst sagt im deutschen Client "Realm". Auf dieser Seite steht in Fließtext "Realm", in Tool-Zitaten und Menüeinträgen "Server". Bei den Tastennamen schreibt diese Seite die deutschen Namen der Tasten (Pfeil hoch, Eingabe, Esc).

## Was es ist

Das WoW Login Tool ist ein kleines Windows-Programm, das neben dem Spiel läuft. Es ist das "Startmenü"-Werkzeug des Sku-Projekts. Es ist kein Addon und kein Teil von WowVision. Es liest oder ändert nicht den Speicher des Spiels. Es betrachtet nur das Spielfenster und drückt Tasten und Mausklicks, genau das, was auch ein sehender Spieler tut.

Damit kannst du:

- Dich auf dem Accountbildschirm anmelden, wenn das Spiel dich nicht von selbst angemeldet hat.
- Den Realm wechseln.
- Einen Charakter wählen und die Welt betreten.
- Einen Charakter erstellen, einschließlich einer Namensprüfung.
- Einen Charakter löschen.
- Die Pop-up-Meldungen des Spiels vorgelesen bekommen, zum Beispiel "Name nicht verfügbar".

Diese Seite beschreibt das WoW Login Tool in Version 4. Das Tool sagt beim Start seine Versionsnummer.

Wie es arbeitet, hängt von der Spielversion ab:

- Auf Classic Era und The Burning Crusade (TBC) Anniversary betrachtet das Tool den Bildschirm mit der Windows-Texterkennung (OCR) und liest ihn dir mit seiner eigenen Stimme vor. Es sagt echte Charakternamen, Stufen, Klassen und Gebiete an, außerdem die echte Realmliste.
- Auf WoW: Forever liest das Spiel seine Anmeldebildschirme selbst mit seiner Text-zu-Sprache-Stimme vor. Das Tool liest dir den Bildschirm dort nicht vor. Stattdessen bewegt es für dich die Maus von Element zu Element, und das Spiel spricht jedes einzelne.

### Welche Spielversionen unterstützt werden

| Spielversion | Unterstützung in Version 4.x |
|---|---|
| Classic Era | Unterstützt. |
| The Burning Crusade Anniversary (2.5.x) | Unterstützt. |
| WoW: Forever (Live-Client) | Unterstützt, mit der ganzen Charaktererstellung einschließlich aller Aussehensoptionen. |
| Mists of Pandaria Classic | Nicht unterstützt. Das Tool sagt an, dass diese Spielversion noch nicht unterstützt wird. |
| Retail und Cataclysm Classic | In der Einrichtung wählbar, aber nicht unterstützt. |

Das Tool erkennt die Spielversion selbst (siehe "Der erste Start"). Clients von Wrath of the Lich King werden ebenfalls nicht unterstützt.

## Was du brauchst

- Windows 10 oder Windows 11. Das Tool benutzt in Windows eingebaute Funktionen (Fensteraufnahme und Texterkennung), deshalb wird nichts über das Internet gesendet.
- AutoHotkey Version 2 (siehe "Beschaffen und installieren").
- Das Spiel selbst, mindestens einmal gestartet.
- Für die Stimme über den Screenreader: NVDA. Siehe "Stimme und Sprachausgabe" weiter unten.

Die Windows-Texterkennung braucht die Sprache deines Spielclients. Das Tool benutzt die Sprache, die du in seiner Einrichtung wählst: Englisch, Deutsch, Französisch, Russisch oder Spanisch. Wenn Windows für diese Sprache keine Texterkennung hat, greift das Tool auf die Sprachen deines Windows-Profils zurück. Es läuft weiter, liest aber Namen und Realms möglicherweise schlecht.

Es gibt auch eine Mac-Version des Tools, diese Anleitung behandelt sie aber nicht.

## Beschaffen und installieren

Am einfachsten geht es mit dem [WowVision-Installer](./installer.md): Seine Option WoW Login Tool installieren ist standardmäßig angehakt. Er installiert das Tool für WoW: Forever, The Burning Crusade Anniversary und Classic Era, bringt das nötige AutoHotkey mit, kopiert die Dateien für die Bildschirmerkennung und die besser lesbare Schrift in Classic Era und The Burning Crusade und legt eine Verknüpfung WoW Login Tool auf dem Desktop und im Startmenü an. Starte das Tool über diese Verknüpfung.

### Von Hand

1. Installiere AutoHotkey Version 2 von [https://www.autohotkey.com/](https://www.autohotkey.com/).
2. Lade WoW-Login-Tool.zip von der [Download-Seite des WoW Login Tools in Version 4](https://github.com/Sku75/Sku-WoW-Addon-TBC/releases/tag/login-tool) herunter. Dieses Release enthält immer das neueste Tool. Entpacke es. Der Ordner darin heißt WoW Login Tool. Leg diesen Ordner am besten in deinen World-of-Warcraft-Ordner, neben die Ordner der Spielversionen. Auf WoW: Forever findet das Tool von dort aus die Einstellungsdatei des Spiels, oder im Standard-Installationsordner.
3. Öffne im Tool-Ordner den Ordner CopyTheContentOfThisFolderToInterface. Er enthält fünf Ordner. Kopiere alle fünf.
4. Öffne deinen World-of-Warcraft-Installationsordner (oft C:\Program Files (x86)\World of Warcraft) und dann den Ordner deiner Spielversion:
   - _anniversary_ für The Burning Crusade Anniversary
   - _classic_era_ für Classic Era
5. Öffne dort den Ordner Interface und füge die fünf Ordner ein. Stimme zu, vorhandene Dateien zu überschreiben.
6. Empfohlen auf Classic Era und TBC: Führe das Skript install_wow_fonts.ps1 aus dem Ordner fonts des Tools als Administrator aus. Es ersetzt die Spielschriftarten durch eine klarere Schrift, die die Texterkennung viel besser liest. Standardmäßig bearbeitet es den Ordner von TBC Anniversary. Für Classic Era gibst du den Ordner mit dem Parameter -ClientDir an. Der Parameter -Remove macht die Änderung rückgängig. Die Änderung wirkt, wenn das Spiel das nächste Mal startet.
7. Starte das Tool, indem du START.ahk im Ordner v2 mit AutoHotkey Version 2 ausführst.

Auf WoW: Forever brauchst du weder die fünf Texturordner noch die Schriftart.

Was du zur Installation wissen solltest:

- Die fünf kopierten Ordner überschreiben Interface-Dateien des Spiels mit denselben Namen. Wenn ein anderes Addon dieselben Dateien ändert, ist es davon betroffen. Wenn das Tool sagt, die "Texturen für die Bildschirmerkennung fehlen im Spielordner", kopiere die fünf Texturordner noch einmal.
- Kopiere nach einer neuen Tool-Version die fünf Ordner noch einmal. Alte Kopien können verhindern, dass das Tool die Bildschirme erkennt.

## Der erste Start

1. Starte das Tool. Es sagt "Login-Tool Version" und seine Nummer, zum Beispiel 4.1. Beim allerersten Start sagt es "Setup mode" und bittet dich, vier Dinge mit den Pfeiltasten einzurichten, in dieser Reihenfolge: Stimme ("Go right to select a voice"), Sprache, Region (Europa oder USA) und Spieltyp. Das Tool kennt deine Sprache zu diesem Zeitpunkt noch nicht und spricht deshalb zuerst Englisch; sobald du bei der Sprache Deutsch gewählt hast, spricht es Deutsch. Mit Pfeil rechts gehst du hinein, mit Pfeil hoch und Pfeil runter wählst du, und mit Eingabe bestätigst du. Jede Wahl wird mit "ausgewählt" bestätigt. Am Ende hörst du "Einrichtung abgeschlossen. Starte jetzt das Spiel."
2. Danach ist das Tool im Pausen Modus und wartet still.
3. Starte das Spiel. Sobald das Tool das Spielfenster sieht und den Bildschirm kennt, sagt es "Login Modus für:" gefolgt von deiner Spielversion, Region und Sprache, zum Beispiel "Login Modus für: Burning Crusade, Europa, Deutsch" (englisch: "Login mode for Burning Crusade, Europe, English"). Während es arbeitet, hörst du einen kurzen, sich wiederholenden Ton. Danach sagt es "Hauptmenü". Wenn das Spiel schon lief, wechsle mit Alt+Tab zurück in das Spiel.

Das Tool findet die Spielversion selbst heraus. Weicht sie von der in der Einrichtung gespeicherten Version ab, schaltet es um und sagt "Spielversion erkannt" mit dem Namen. Bei einem Client, für den es keine Einrichtung hat (zum Beispiel Mists of Pandaria oder Wrath), hörst du "Diese Spielversion wird noch nicht unterstützt." und die Versionsnummer. Rät es falsch, stelle sie mit Spieltyp auswählen im Menü von Hand ein. Zur Wahl stehen Cataclysm, Classic Ära, Burning Crusade, Retail und WoW Forever. Ein von Hand gewählter Spieltyp bleibt fest. Spieltyp automatisch erkennen, ein Eintrag in derselben Liste, schaltet wieder auf automatisch zurück.

Wenn du die Sprache, die Region oder den Spieltyp später änderst, startet sich das Tool selbst neu ("ausgewählt. Wird neu gestartet. Bitte warte."), du hörst also die Version noch einmal. Beim Ändern der Stimme passiert das nicht.

Tipps für den Forever-Client:

- Starte das Tool bevor du WoW: Forever startest. Beim Start, solange das Forever-Spiel nicht läuft, schaltet das Tool die Bildschirmvorlesung des Spiels ein, schaltet die Erststart-Frage des Vorlesers aus und stellt die Vorlesestimme und das Sprechtempo in den Einstellungen des Spiels ein. Wenn es etwas ändert, hörst du "Vorlese-Einstellungen für Forever geschrieben". Das Spiel liest diese Einstellungen nur beim Start. Läuft das Spiel schon, lässt das Tool die Einstellungen in Ruhe und sagt dazu nichts.
- Wenn du nach einer Erstinstallation die Standardstimme des Spiels statt deiner eigenen hörst, schließe das Spiel und starte zuerst das Tool, dann das Spiel.

## Die Modi

- Einrichtungs Modus (Setup mode): nur beim allerersten Start, während du Stimme, Sprache, Region und Spieltyp wählst.
- Pausen Modus (Pause mode): Das Tool wartet. Dieser Modus ist immer aktiv, wenn das Spielfenster nicht den Fokus hat.
- Login Modus (Login mode): das gesprochene Menü für die Anmelde-, Realm- und Charakterbildschirme. Dieser Modus startet automatisch, wenn das Tool einen dieser Bildschirme sieht.
- Spiel Modus (Play mode): Du bist in der Welt. Das Tool lässt alle Tasten zum Spiel durch. WowVision (und Sku, falls installiert) arbeiten von hier an.

Das Tool wechselt den Modus von selbst. Jedes Mal, wenn du das Spielfenster verlässt und zurückkommst, beginnt es wieder im Hauptmenü. Das ist so gewollt. Mit Alt+F1 schaltest du den Modus von Hand um (siehe die Tastentabelle).

Wenn das Tool nicht von selbst zwischen Login Modus und Spiel Modus wechselt, drücke Alt+F1.

Diese Regeln halten das Tool am Laufen:

- Solange es arbeitet und seinen Warteton spielt, drücke keine Tasten, klicke nicht, bewege die Maus nicht und wechsle nicht das Fenster.
- Halte das Spielfenster vorn und sichtbar. Spiele nicht mit minimiertem Fenster.
- Um eine laufende Aktion anzuhalten, drücke Alt+F1.

## Das Tool auf Classic Era und TBC benutzen

### Am Accountbildschirm anmelden

Wenn das Spiel dich nicht von selbst anmelden konnte, steht es auf dem Accountbildschirm. Das Tool sagt dann "Nicht angemeldet. Entweder besteht keine Verbindung zum Server, oder Accountname und Passwort müssen im Spiel noch eingegeben werden." Sein Menü bietet dann nur Dinge an, die ohne Anmeldung funktionieren: Accountname, Passwort, Anmelden, Accountnamen speichern, dann Stimme, Sprache, Spieltyp, Region und Version.

1. Gehe zu Accountname und drücke Eingabe. (Pfeil rechts wiederholt nur den Eintrag.) Du hörst den aktuellen Inhalt des Feldes ("Accountname: leer", wenn nichts drinsteht) und dann "Tippe jetzt. Enter beendet die Eingabe, Escape verlässt sie." Tippe deinen Accountnamen und drücke Eingabe. Das Tool liest den Accountnamen zurück.
2. Gehe zu Passwort und mach dasselbe. Du hörst "Tippe jetzt. Das Passwort wird nie vorgelesen. Enter beendet die Eingabe, Escape verlässt sie." Das Passwort wird nie zurückgelesen, und Eingabe beendet die Eingabe, ohne dich anzumelden.
3. Wähle Anmelden mit Eingabe. Du hörst "Anmeldung läuft. Bitte warten." Das Tool liest jedes Pop-up vor (zum Beispiel bei falschem Passwort), schließt es und sagt "Die Anmeldung hat nicht geklappt." Wenn das Spiel gerade nur verbindet, liest das Tool bloß die Meldung vor und wartet.
4. Accountnamen speichern schaltet das Kästchen des Spiels zum Merken des Accountnamens ein oder aus und sagt "Accountnamen speichern: an" oder "aus".

Während du in ein Feld tippst, gehen die Pfeiltasten an das Spiel, damit du Tippfehler korrigieren kannst. Das Tool speichert dein Passwort nie und hat keine automatische Anmeldung. Die Battle.net-App zu schließen und wieder zu öffnen ist oft der schnellere Weg zurück. Auf Forever erzählt das Spiel stattdessen seinen eigenen Anmeldebildschirm.

### Das Hauptmenü

Das Hauptmenü hat diese Einträge, in dieser Reihenfolge:

1. Charakter auswählen (Select character)
2. Login mit ausgewähltem Charakter (Login with selected character)
3. Neuen Charakter erstellen (Create new character)
4. Server wechseln (Change server)
5. Charakter löschen (Delete character)
6. Stimme auswählen (Select voice)
7. Sprache auswählen (Select language)
8. Spieltyp auswählen (Select game type)
9. Region auswählen (Select region)
10. Ein Versionseintrag. Er liest "WoW Logintool V3.0, Version: V3.0". Das ist nicht die Release-Nummer des Tools. Die Release-Nummer wird beim Start des Tools gesprochen.

Mit Pfeil hoch und Pfeil runter wechselst du zwischen den Einträgen, mit Pfeil rechts gehst du in einen Eintrag mit Untermenü, mit Pfeil links zurück, und mit Eingabe führst du einen Eintrag aus. Der Wortlaut ist in anderen Sprachen anders und kann sich in künftigen Versionen ändern.

### Einen Charakter wählen und die Welt betreten

1. Gehe zu Charakter auswählen und drücke Pfeil rechts. Das Tool listet deine Charaktere mit echtem Namen, Stufe, Klasse und Gebiet auf, zum Beispiel "1: Anna, Stufe 1 Priester". Gibt es keinen, hörst du "Leer. Keine Chars auf diesem Server."
2. Wähle den Charakter mit Pfeil hoch und Pfeil runter (Bild ab und Bild auf springen um zehn) und drücke Eingabe. Das Tool sagt den Namen, gefolgt von "ausgewählt", und springt weiter zu Login mit ausgewähltem Charakter.
3. Drücke Eingabe, um die Welt zu betreten. Das Tool sagt "Spiel Modus". Tut es das nicht, drücke Alt+F1.
4. Ein neuer Charakter beginnt vielleicht mit einem Introfilm. Wenn er endet, stehst du in der Welt, und WowVision übernimmt.

Das Zählen eines Realms mit vielen Charakteren kann mehrere Sekunden dauern. Das Tool sagt "Bitte warten, Charakterliste wird neu aufgebaut." und zählt bei einer langen Liste alle zehn Charaktere laut mit. Ein Realm kann viele Charaktere enthalten, aber der Spielbildschirm zeigt neun auf einmal. Das Tool zählt alle durch, damit alle in der Liste stehen. Konnte es sie nicht zählen, sagt es "Achtung, die Charakterliste ist möglicherweise unvollständig. Drücke zweimal Alt F1, um sie neu aufzubauen."

### Den Realm wechseln

1. Gehe zu Server wechseln und drücke Eingabe. Das Tool öffnet die Realmliste des Spiels und liest die Live-Liste vom Bildschirm ab. Das dauert einige Sekunden, mit dem Warteton. Dann stehst du auf dem ersten Realm. Die Einträge sind die Realms (mit Typ und Auslastung), dann je ein Eintrag pro Kategorie (die Reiter der Realmliste des Spiels, gesprochen "Kategorie auswählen" und der Name des Reiters) und als letzter Eintrag Serverauswahl schließen. Wenn du eine Kategorie wählst, werden die Realms dieses Reiters gelesen.
2. Wähle einen Realm und drücke Eingabe. Das Tool sagt "Server wird gewechselt. Bitte warte." und dann "Server gewechselt", gefolgt vom Namen des Realms.
3. Das Tool prüft, welchen Realm das Spiel wirklich zeigt, und warnt dich, wenn es ein anderer ist: "Achtung. Das Spiel ist auf einem anderen Server:" und der Name, danach "Wechsle den Server erneut, bevor du hier spielst." Wechsle den Server noch einmal, bevor du dort spielst.

Sonderfälle:

- Auf einem Realm, auf dem du noch keine Charaktere hast, geht das Spiel gleich zur Charaktererstellung. Das Tool sagt "Auf diesem Server gibt es noch keine Charaktere."
- Einige Classic-Era-Realms zeigen eine Warnung zu Hardcore oder PvP. Das Tool liest den Text und sagt "Drücke Enter um zuzustimmen, oder Escape um abzulehnen." Es antwortet nie für dich.
- Das Tool behandelt keine Realmwarteschlangen. Solange das Spiel eine Verbindungsmeldung zeigt, liest das Tool sie und wartet. Nach etwa einer Minute sagt es "Das Spiel verbindet noch. Escape bricht ab."
- Öffnet das Spiel selbst die Realmliste, hörst du "Das Spiel hat die Serverauswahl geöffnet." und die Realms erscheinen als Menü. Serverauswahl schließen ist der letzte Eintrag.
- Solange das Spiel verbindet (Anmeldung, Realmwechsel, Spielstart), wird ein Pop-up mit nur einer Schaltfläche vorgelesen, aber nie gedrückt. Diese eine Schaltfläche ist "Abbrechen", und sie zu drücken würde deine Anmeldung stoppen.

### Einen Charakter erstellen

1. Gehe zu Neuen Charakter erstellen und drücke Pfeil rechts.
2. Wähle das Geschlecht, dann das Volk, dann die Klasse (aufgelistet sind nur Klassen, die das Volk spielen kann), dann das Startgebiet. Mit Pfeil rechts gehst du tiefer und mit Pfeil links einen Schritt zurück. Drücke Eingabe beim Startgebiet.
3. Das Tool sagt "Gib den Namen des neuen Charakters ein und drücke die Eingabetaste oder brich die Charaktererstellung mit Escape ab." Tippe den Namen und drücke Eingabe.
4. Lehnt das Spiel den Namen ab, zeigt es ein Pop-up. Das Tool liest das Pop-up laut vor, schließt es, leert das Namensfeld und fragt noch einmal nach dem Namen. Versuche einen anderen Namen.
5. Bei Erfolg hörst du "Charakter erstellt". Die Liste wird neu aufgebaut, und das Tool kehrt zum Hauptmenü zurück. Der neue Charakter wird nicht für dich ausgewählt.
6. Geht etwas anderes schief, zum Beispiel weil der Realm schon die Höchstzahl an Charakteren enthält, wird das Pop-up des Spiels genauso gelesen. Bekommt das Tool etwa 18 Sekunden lang keine Antwort, hörst du "Etwas ist schief gelaufen. Bitte starte das Spiel neu und versuche es noch einmal."

Regeln für Namen: keine Leerzeichen, nicht derselbe Buchstabe dreimal hintereinander, und der erste Buchstabe wird für dich großgeschrieben.

Drücke während der Namenseingabe Esc, um abzubrechen. Das Tool sagt "Die Erstellung wird abgebrochen. Bitte warte." Auf Classic Era und TBC kannst du das Aussehen des Charakters nicht wählen. Es wird das Standardaussehen des Spiels benutzt.

Auf einem Hardcore-Realm bittet dich das Spiel, den Hardcore-Regeln zuzustimmen, bevor der Charakter erstellt wird. Das Tool liest die Regeln Seite für Seite vor und bittet um Eingabe (zustimmen) oder Esc (ablehnen).

Auf einem neuen Account zeigt das Spiel außerdem Blizzards Sozialvertrag. Das Tool scrollt ihn bis zum Ende und akzeptiert ihn für dich: "Blizzards Sozialvertrag ist offen. Er wird akzeptiert, bitte warten." Dann "Sozialvertrag akzeptiert." Schlägt das fehl, hörst du, dass einmal sehende Hilfe gebraucht wird: den Text bis zum Ende scrollen und auf Akzeptieren klicken.

### Einen Charakter löschen

1. Wähle zuerst den Charakter aus, den du löschen willst (siehe "Einen Charakter wählen und die Welt betreten"). Das Tool benutzt die Schaltfläche Löschen des Spiels, es löscht also den Charakter, der im Spiel gerade ausgewählt ist. Direkt nachdem das Tool die Liste gezählt hat, ist das Charakter 1.
2. Wähle Charakter löschen und drücke Eingabe. Das Tool liest das Bestätigungs-Pop-up des Spiels laut vor. Es nennt den Charakter, prüfe also den Namen, bevor du weitermachst.
3. Das Tool bittet dich, das Wort LÖSCHEN in Großbuchstaben zu tippen und Eingabe zu drücken: "Schreibe das Wort LÖSCHEN in Großbuchstaben und drücke Enter. Oder drücke Escape, um abzubrechen." Das Tool tippt das Wort nicht für dich. Nimmt das Spiel es nicht an, hörst du die Aufforderung noch einmal ("Löschen fehlgeschlagen. ..."). Drücke Esc, um abzubrechen (du hörst "Das Löschen wird abgebrochen. Bitte warte").
4. Bei Erfolg hörst du "Charakter gelöscht", und die Liste wird neu aufgebaut.

Im deutschen Client heißt das Wort LÖSCHEN (im englischen Client DELETE). Das Tool fragt nach dem Wort der Sprache, die du im Tool eingestellt hast: DELETE auf Englisch, LÖSCHEN auf Deutsch, EFFACER auf Französisch, BORRAR auf Spanisch, УДАЛИТЬ auf Russisch. Stelle das Tool deshalb auf dieselbe Sprache wie deinen Spielclient.

## Das Tool auf WoW: Forever benutzen

Auf Forever arbeitet das Tool anders, die Tasten tun also andere Dinge. Das Spiel liest jedes Element laut vor, wenn die Maus darauf ruht. Das Tool bewegt die Maus für dich.

1. Erkennt das Tool das Spiel, sagt es "Login Modus für: WoW Forever" mit deiner Region und Sprache. Das Spiel erzählt die ersten Bildschirme: die Frage zum Screenreader (vom Tool ausgeschaltet), den Anmeldebildschirm, die Regelsatz-Karten und die Erfahrungs-Karten. Trifft das Tool auf einen Bildschirm, den es nicht benennen kann, hörst du "Forever-Modus: Das Spiel liest den Bildschirm selbst vor. Strg Alt F3 speichert einen Screenshot zur Kalibrierung." Das ist ein Hinweis für Fehlerberichte. Mach mit den Pfeiltasten weiter.
2. Pfeil hoch und Pfeil runter gehen zum nächsten oder vorherigen Element auf dem Bildschirm. Das Spiel spricht jedes. An den Enden der Liste springt der Cursor herum.
3. Bild auf und Bild ab springen um fünf Elemente. Sie halten am ersten und letzten Element an.
4. Eingabe klickt das Element. In einem Textfeld startet Eingabe den Eingabemodus. Du hörst "Eingabemodus. Enter oder Escape beendet ihn". Tippe, dann drücke Eingabe oder Esc, um die Tastatur wieder an das Tool zu geben. Esc wird außerdem an das Spiel weitergegeben.
5. Pfeil links und Pfeil rechts ändern den Wert einer Aussehensoption. Bei jedem anderen Element liest Pfeil links den Bildschirm erneut vor, und Pfeil rechts sagt das aktuelle Element noch einmal.
6. Esc schließt eine geöffnete Auswahlliste. Sonst geht es an das Spiel, es geht also aus einem Bildschirm zurück oder öffnet das Spielmenü.
7. Das Tool kennt außerdem den Verhaltenskodex (es scrollt von selbst bis zum Ende und lässt den Cursor auf Akzeptieren), die Charakterliste mit dem Löschdialog und das Spielmenü, das du mit Esc bekommst.
8. Die Schaltfläche Welt betreten schaltet das Tool in den Spiel Modus. Alt+F1 geht zurück in den Login Modus, zum Beispiel um zur Charakterauswahl zurückzukehren.

### Einen Charakter auf Forever erstellen

Die Charaktererstellung ist vollständig abgedeckt. Die beiden Erstellungsseiten sind:

- Volk und Klasse. Die Völker sind nach Fraktion aufgelistet. Du hörst sie mit Pfeil hoch und Pfeil runter. Beide Reihen der Klassen und der Körpertyp sind erreichbar.
- Aussehen und Name. Die Seite hat das vollständige Namensfeld, ein zweites Namensfeld, wenn das Spiel eines zeigt, die Namensprüfung, die Würfel-Schaltfläche für einen zufälligen Namen und die Aussehensoptionen mit ihrem aktuellen Wert.

Auf der Aussehensseite änderst du eine Option mit Pfeil links und Pfeil rechts. Das Tool sagt dann den neuen Wert und die Nummer, zum Beispiel "4 von 10". Bei Frisuren und ähnlichen Auswahlen hängt es kurz danach den Namen der Auswahl an, sobald der Bildschirm ihn zeigt. Farboptionen haben im Spiel keinen Namen. Das Tool benennt die Farbe ungefähr, zum Beispiel "hell braun". Rötliche helle Farben heißen rosa. Die Namen können eine Stärke enthalten, etwa blass, matt, kräftig oder leuchtend.

Drücke Pfeil runter auf der untersten Option, um die Liste weiter zu scrollen. Das Tool springt zur nächsten Option. Wenn die Liste endet, geht es weiter zu Fertig.

Die Namensprüfung zeigt neben dem Namensfeld ein kleines Symbol: ein grünes Häkchen (Name frei), ein rotes Kreuz (mit einem Grund) oder nichts, solange das Spiel prüft oder das Feld leer ist. Das Tool sagt, was das Symbol zeigt: dass der Name verfügbar ist ("Name verfügbar"), den Grund, warum der Name abgelehnt wurde (oder "Name nicht verfügbar"), oder "Noch kein Ergebnis der Namensprüfung". Es wartet nach deiner Eingabe bis zu etwa zweieinhalb Sekunden auf das Ergebnis.

### Wiederholte Elemente

Das Spiel sagt jeden Text pro Durchlauf nur einmal. Hörst du nichts, nachdem du zu einem Element gegangen bist, das du schon gehört hast, spricht das Tool es für dich noch einmal. Das ist normalerweise an, wenn du die Brückenstimme des Screenreaders benutzt, und aus bei einer echten Stimme. Du kannst es mit der Einstellung repeatecho ändern (siehe "Einstellungen und Dateien").

## Tastenübersicht

Im Login Modus und bei der Ersteinrichtung nimmt das Tool diese Tasten. Im Spiel Modus gehen sie an das Spiel.

| Taste | Classic Era und TBC | WoW: Forever |
|---|---|---|
| Pfeil hoch / Pfeil runter | Vorheriger oder nächster Menüeintrag | Vorheriges oder nächstes Element auf dem Bildschirm |
| Bild auf / Bild ab | Zehn Einträge nach oben oder unten | Fünf Elemente nach oben oder unten |
| Pfeil rechts | Das Untermenü öffnen, oder den Eintrag noch einmal sagen, wenn er keines hat | Nächster Wert einer Aussehensoption; sonst sagt es das aktuelle Element noch einmal |
| Pfeil links | Zurück zum Menü darüber | Vorheriger Wert einer Aussehensoption; sonst liest es den Bildschirm erneut vor |
| Eingabe | Den Eintrag ausführen; bestätigt einen Namen, ein Löschen oder das Ende der Eingabe in einem Feld; stimmt einer Hardcore-Warnung zu | Das Element klicken; in einem Textfeld startet und beendet es die Eingabe |
| Esc | Bricht Namenseingabe, Löschen und das Ende der Eingabe in einem Feld ab; lehnt eine Hardcore-Warnung ab. Sonst geht es an das Spiel | Schließt eine Liste, beendet die Eingabe oder geht an das Spiel |
| Alt+F1 | Zwischen Login Modus und Spiel Modus umschalten, und eine laufende Aktion anhalten | Zwischen Login Modus und Spiel Modus umschalten |
| Alt+Esc | Das Tool beenden (du hörst "Beendet"; funktioniert in jedem Modus) | Das Tool beenden |
| Strg+Alt+F2 | Vollbild-Screenshot in die Windows-Zwischenablage | Dasselbe |
| Strg+Alt+F3 | Speichert einen Screenshot für die Entwickler im Ordner data\captures des Tools und sagt "Screenshot gespeichert" (für Fehlerberichte) | Speichert einen Screenshot für die Entwickler im Ordner data\captures des Tools und sagt "Screenshot gespeichert" (für Fehlerberichte) |
| Ziffernblock 7 (Numpad 7) | Nur im Spiel Modus: stellt eine Kameraansicht ein und klickt rechts in die Nähe deines Charakters | Dasselbe |
| Ziffernblock 8 (Numpad 8) | Nur im Spiel Modus: stellt eine Kameraansicht ein und klickt links etwas näher zur Bildschirmmitte | Dasselbe |

Die beiden Tasten des Ziffernblocks sind Hilfen für den Spiel Modus und werden mit WowVision nicht gebraucht.

Alt+F1 hält das Tool nicht ausgeschaltet, solange du auf einem Anmelde- oder Charakterbildschirm bleibst: Innerhalb ein oder zwei Sekunden sieht es diesen Bildschirm wieder und geht zurück in den Login Modus. Um das Tool wirklich zu stoppen, drücke Alt+Esc, oder wechsle weg vom Spielfenster (Alt+Tab). Das Tool sitzt dann im Pausen Modus.

## Stimme und Sprachausgabe

- Das Tool spricht über eine Windows-Sprachstimme (SAPI), nicht über den Screenreader. Wähle die Stimme in der Einrichtung beim ersten Start oder später mit Stimme auswählen. Eine Stimme wird zuerst lautlos getestet. Funktioniert eine Stimme nicht, hörst du "Diese Stimme funktioniert nicht, bitte eine andere wählen", und deine alte Stimme bleibt.
- Ist die Stimmenliste leer, hörst du "Keine Stimmen gefunden, Eingabe drücken, um die Systemstimme zu behalten."
- Der besondere Eintrag SAPI2SR ist keine echte Stimme. Er ist eine Brücke, die den Text an NVDA weitergibt, sodass du ihn in der Stimme deines eigenen Screenreaders hörst. Mit dieser Stimme brechen die Pfeiltasten die Sprache von NVDA ab. Mit einer echten Stimme wird die Sprache wie üblich bei jeder Bewegung unterbrochen.
- Auf Forever ist die Vorlesestimme die Position deiner gewählten Stimme in der Windows-Stimmenliste. Das Sprechtempo ist standardmäßig 5. Siehe "Einstellungen und Dateien". Hörst du auf Forever die falsche Stimme, setze voice= in forever.ini. Das Protokoll des Tools listet alle Stimmen mit ihren Nummern auf.
- Das Ausgabegerät kannst du mit gAudioOutputMatch in der Einstellungsdatei ändern. Trage einen Teil des Gerätenamens ein. Leer bedeutet die Systemvorgabe.

## Einstellungen und Dateien

Die Dateien des Tools liegen im Ordner WoW Login Tool. Es sind kleine Textdateien. Bearbeite sie bei geschlossenem Tool.

| Datei | Was sie enthält |
|---|---|
| data\settings.ini | Deine Einrichtung: Spieltyp (und ob du ihn von Hand gewählt hast), Stimme, Sprache, Region, Ausgabegerät. Lösche diese Datei bei geschlossenem Tool, um die Einrichtung beim ersten Start noch einmal zu durchlaufen. |
| data\forever.ini | Forever-Optionen: voice= (Nummer der Windows-Stimme, ab 0 gezählt), rate= (-10 bis 10, 0 ist normal), volume= (0 bis 100), repeatecho= (1 oder 0), echo= (1 lässt das Tool jedes Element sprechen, zum Fehlersuchen), wheelnext=up (dreht die Richtung der Mausradschritte um, wenn die Liste des Spiels in die andere Richtung scrollt). Ohne eine voice-Zeile bekommt Forever die Stimme, die du im Tool gewählt hast. |
| log.txt | Das Protokoll des aktuellen Durchlaufs. Die letzten fünf Durchläufe werden als log-1.txt bis log-5.txt aufbewahrt. |

### Was das Tool ins Spiel schreibt

Auf Forever schreibt das Tool, solange das Spiel geschlossen ist, die Vorlese-Einstellungen in die Einstellungen des Spiels, damit das Spiel mit deiner Stimme spricht.

## Tipps

- Melde dich über die Battle.net-App an, die sich unter Windows und auf dem Mac mit einem Screenreader bedienen lässt, und hake einmal "Angemeldet bleiben" (keep me logged in) an. Dann meldet dich das Spiel von selbst an, und das Tool beginnt bei den Realm- und Charakterbildschirmen.
- Lies diese Schritte auf einem zweiten Gerät. Jedes Mal, wenn das Spielfenster den Fokus verliert, pausiert das Tool und beginnt beim Zurückkommen wieder im Hauptmenü.
- Hör dir die Charakterliste noch einmal an, nachdem du einen Charakter erstellt oder gelöscht hast. Die Liste wird neu aufgebaut, und die Nummern können sich ändern.
- Hab Geduld. Realmlisten und Charakterzählungen brauchen Sekunden. Das Tool spielt einen Warteton, während es arbeitet.
- Schalte auf Classic Era und TBC Overlays und Farbänderungen aus (siehe "Fehlerbehebung" weiter unten).
- Sobald du "Spiel Modus" hörst und die Welt geladen ist, hat WowVision das Kommando. Hörst du nichts von WowVision, schau in die [Fehlerbehebung](troubleshooting.md).

## Wie WowVision und das Login-Tool zusammenarbeiten

Das Tool endet an der Welt. Im Spiel Modus beobachtet es nur den Bildschirm und bietet die beiden Kamerahilfen auf dem Ziffernblock. Von da an ist alles WowVision (siehe den [Schnellstart](quick-start.md)).

- Das Tool braucht WowVision nicht, und WowVision braucht das Tool nicht.
- Du kannst das Tool im Hintergrund weiterlaufen lassen, während du spielst. Willst du es aus haben, drücke Alt+Esc.
- Kommst du zur Charakterauswahl zurück, zum Beispiel nach dem Abmelden, fang wieder am Anfang dieser Seite an. Auf Forever drückst du Alt+F1, um zurück in den Login Modus zu kommen.
- WowVision führt das Sku-Addon als optionales Addon auf. Es benutzt das Login-Tool nicht. Ist das Sku-Addon geladen, schaltet WowVision einige seiner Tasten, Fenster und Befehle ab, damit sich die beiden nicht um Tasten streiten, zum Beispiel die Fokustasten, die weiche Zielerfassung, die Tasten für die Tooltip-Zeilen (Umschalt+Pfeil hoch, Umschalt+Pfeil runter, Umschalt+Pfeil links, Umschalt+Pfeil rechts) und Fenster wie Gossip, Handel, Post und Ausbildung. Die Befehle /pquit, /dquit und /focus1 bis /focus5 bleiben dann Sku überlassen.
- Willst du, dass WowVision komplett übernimmt, schaltet der Befehl /disableaddon sku Sku und seine Audio- und Soundpakete aus und lädt die Oberfläche neu. /enableaddon sku schaltet sie wieder ein. Diese beiden Befehle gibt es nicht, wenn BlindSlash geladen ist.

Die vollständige Liste der Fenster, Tasten und Befehle, die WowVision Sku überlässt, steht unter [WowVision zusammen mit Sku verwenden](sku.md).

## Fehlerbehebung

| Problem | Was du versuchen kannst |
|---|---|
| Das Tool bleibt im Pausen Modus und sagt nichts, wenn das Spiel offen ist | Das Tool arbeitet nur, solange das Spielfenster den Fokus hat, und erst, nachdem es das Spielfenster erkannt hat. Klicke in das Spielfenster. Auf manchen Rechnern klappt es besser, zuerst das Spiel und dann das Tool zu starten. Hilft nichts, starte das Tool und das Spiel neu. |
| "Unbekannter Bildschirm. Schließe den Dialog im Spiel und drücke dann zweimal Alt F1." | Das Spiel zeigt einen Bildschirm, den das Tool nicht kennt, oft das Spielmenü oder einen Dialog. Schließe ihn (Esc), dann drücke zweimal Alt+F1. |
| "Die Texturen für die Bildschirmerkennung fehlen im Spielordner" | Kopiere die fünf Texturordner noch einmal (siehe "Beschaffen und installieren"). |
| Das Tool erkennt keinen Bildschirm | Schalte das Discord-Overlay im Spiel aus (Benutzereinstellungen, Spiel-Overlay; englisch: User Settings, Game Overlay). Blende das Nvidia-Overlay mit Alt+R aus. Setze HDR, hohen Kontrast, Helligkeit und Farbfilter in Windows und im Spiel zurück. |
| "Das Spiel startet. Bitte warten." sehr lange | Das Spiel lädt noch. Das Tool sagt erst nach etwa 12 Sekunden ohne Erkennung "Unbekannter Bildschirm". |
| "Etwas ist schief gelaufen. Bitte starte das Spiel neu und versuche es noch einmal." | Eine Aktion ist fehlgeschlagen. Das Tool piept zweimal und fällt in den Pausen Modus, dann findet es den Bildschirm von selbst wieder. Drücke Alt+F1, um eine laufende Aktion anzuhalten, dann versuche es noch einmal. Passiert es dauernd, starte das Spiel und das Tool neu. |
| "Nicht angemeldet" auf dem Accountbildschirm | Benutze Accountname, Passwort und Anmelden, oder starte Battle.net und das Spiel neu. |
| "Die Serverliste wurde nicht geladen. Bitte erneut versuchen." | Die Realmliste war beim Lesen leer. Warte ein paar Sekunden und öffne Server wechseln noch einmal. |
| Namen, Realms oder Pop-ups werden falsch oder als Unsinn gelesen | Die im Tool eingestellte Sprache passt wahrscheinlich nicht zur Sprache des Spielclients. Das Tool liest den Bildschirm mit dieser Sprache. Ändere sie mit Sprache auswählen. |
| Du hörst auf Forever die Standardstimme des Spiels | Schließe das Spiel, starte das Tool, dann das Spiel, damit das Tool die Vorlese-Einstellungen schreiben kann. |
| Das Tool ist leise oder sagt "Diese Stimme funktioniert nicht" | Wähle bei Stimme auswählen eine andere Stimme. Funktioniert keine, prüfe die Windows-Spracheinstellungen. |
| Wiederholte Elemente auf Forever sind stumm | Setze repeatecho=1 in forever.ini und starte das Tool neu. |
| Es stimmt immer noch etwas nicht | Hol dir das Protokoll. Das eigene Protokoll des Tools ist die Datei log.txt in seinem Ordner. Melde es im WowVision-Discord, mit dem Protokoll und der Tool-Version, die das Tool beim Start sagt. |

## Bekannte Grenzen

- Die Aussehensoptionen auf Classic Era und TBC sind nicht verfügbar.
- Auf Forever kann bei sehr schnellen Wechseln in einer langen Liste (zum Beispiel bei Frisuren) kurz der falsche Wert gesagt werden, bevor das Tool sich korrigiert.
- Das Tool braucht einen Windows-PC. Eine Mac-Version gibt es, sie wird hier aber nicht behandelt.
- Der Lizenztext vor der ersten Anmeldung braucht noch einmal sehende Hilfe. Den Sozialvertrag im Spiel erledigt das Tool.

## Quellen

- [Download des WoW Login Tools in Version 4 (das Release "login-tool" mit WoW-Login-Tool.zip)](https://github.com/Sku75/Sku-WoW-Addon-TBC/releases/tag/login-tool)
- [Einladung zum Sku-Discord, für Hilfe](https://discord.gg/AzFwTDmpbk)

Siehe auch: [Installation](installation.md), [Schnellstart](quick-start.md) und [Fehlerbehebung](troubleshooting.md).
