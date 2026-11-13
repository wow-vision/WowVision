# Dein erster Login

## Durch die Anmeldebildschirme

WowVision beginnt zu arbeiten, sobald dein Charakter in der Welt steht. Der Anmeldebildschirm, die Realmliste und die Charakterauswahl kommen davor, und das Spiel lädt Addons erst, wenn ein Charakter die Welt betritt. Kein Addon kann diese Bildschirme also vorlesen; nur das Spiel selbst könnte sie zugänglich machen. WoW: Forever liest seine Anmeldebildschirme zwar vor, sie brauchen aber trotzdem die Maus.

Das WoW Login Tool aus dem Sku-Projekt bringt dich durch sie hindurch. Es ist ein kleines Windows-Programm, das neben dem Spiel läuft und diesen Bildschirmen ein gesprochenes Menü gibt. Es unterstützt Classic Era, The Burning Crusade Anniversary und WoW: Forever; auf Mists of Pandaria Classic und Retail funktioniert es nicht, bitte dort einen sehenden Helfer. Melde dich über die Battle.net-App bei Battle.net an; sie lässt sich unter Windows und auf dem Mac mit einem Screenreader bedienen. Hake einmal "Angemeldet bleiben" (keep me logged in) an, dann meldet dich das Spiel von selbst an, wenn du es von dort startest.

Kurz gesagt:

1. Installiere das Tool. Der [Installer](./installer.md) erledigt das für dich (WoW Login Tool installieren ist standardmäßig angehakt) und legt eine Verknüpfung WoW Login Tool auf deinen Desktop. Wie du es von Hand installierst, steht unter [Beschaffen und installieren](./sku-login.md#beschaffen-und-installieren).
2. Starte das Tool, auf WoW: Forever vor dem Spiel. Beim allerersten Start fragt es nach Stimme, Sprache, Region und Spieltyp: Mit Pfeil rechts gehst du hinein, mit Pfeil hoch und Pfeil runter wählst du, mit Eingabe bestätigst du. Du hörst "Einrichtung abgeschlossen. Starte jetzt das Spiel."
3. Starte das Spiel. Das Tool sagt "Login Modus für:" mit deiner Spielversion und dann "Hauptmenü".
4. Auf Classic Era und The Burning Crusade: Gehe zu Charakter auswählen und drücke Pfeil rechts, wähle deinen Charakter mit Pfeil hoch und Pfeil runter und drücke Eingabe, dann drücke Eingabe auf Login mit ausgewähltem Charakter. Das Tool sagt "Spiel Modus". Auf WoW: Forever spricht das Spiel jedes Element, während das Tool dorthin geht; siehe [Das Tool auf WoW: Forever benutzen](./sku-login.md#das-tool-auf-wow-forever-benutzen).

Wechselt das Tool nicht von selbst zwischen seinem Menü und dem Spiel, drücke Alt+F1. Einen Charakter erstellen, den Realm wechseln, die vollständige Tastenübersicht und die Fehlerbehebung des Tools findest du unter [Anmelden mit dem Sku-Login-Tool](./sku-login.md).

## In der Welt

Sobald dein Charakter in der Welt ist, startet WowVision von selbst. Es gibt keine gesprochene Ansage "geladen".

Prüfe auf eine dieser Arten, ob es läuft:

- Drücke Umschalt+F1. Das WowVision-Menü öffnet sich, und sein erster Eintrag wird vorgelesen. Das ist der schnellste Test.
- Tippe /wv in das Chatfeld und drücke Eingabe. Auch das öffnet das Menü. /wv version gibt die installierte Version in deinem Chatfenster aus.

Nimm dir dann ein paar Minuten für den [Schnellstart](./quick-start.md): Er behandelt die ersten Einstellungen, die du dir ansehen solltest, vor allem deine Spracheinstellungen.

### Was WowVision beim ersten Login eines Charakters ändert

Einige Spieleinstellungen stehen der Arbeitsweise von WowVision im Weg. Deshalb ändert WowVision sie für jeden neuen Charakter einmal. Das geschieht nur ein einziges Mal; wenn du eine Einstellung danach zurückstellst, lässt WowVision deine Wahl in Ruhe.

| Was sich ändert | Warum | Wie du es rückgängig machst |
|---|---|---|
| Aktionsleisten sperren (Lock Action Bars) wird ausgeschaltet | Bei gesperrten Leisten bewirkt das Ziehen eines Zaubers oder Gegenstands von einer Aktionsleiste nichts, solange du nicht die Taste zum Aufnehmen hältst, und nichts sagt dir das. WowVision gibt beim ersten Mal einen Hinweis in dein Chatfenster aus. | Hake in den Spieloptionen unter Aktionsleisten Aktionsleisten sperren wieder an. |
| Die Kamera folgt immer hinter deinem Charakter (der Kamera-Folgestil Immer, im englischen Client "Always adjust camera"), und Ansichtswechsel erfolgen sofort | Das Drehen zu einem Wegpunkt dreht die Kamera und übernimmt dann ihre Richtung für den Charakter. Das funktioniert nur mit diesem Stil zuverlässig. WowVision gibt einen Hinweis in dein Chatfenster aus. | Ändere in den Spieloptionen unter Steuerung den Kamera-Folgestil. Das Drehen zum Wegpunkt wird dann unzuverlässig. |
| Ton zwischen Chatzeilen (Sound Between Chat Lines) des Spiels wird ausgeschaltet | Das Spiel spielt einen kurzen Ton zwischen zwei Chatzeilen ab, die es vorliest, und dieser Ton würde zwischen allen Ansagen von WowVision erklingen. | Es ist eine Einstellung im Modul Sprache von WowVision (Ton zwischen Chatzeilen), oder tippe den eigenen Befehl des Spiels /tts playline. |

Zwei weitere Dinge folgen den Einstellungen von WowVision, statt einmalig zu geschehen:

- Die Spieloption Klicken zum Bewegen (Click to Move) folgt der Einstellung Automatisch zum Interaktionsziel bewegen (Auto-move to Interact Target) im Navigationsmenü von WowVision (standardmäßig an); sie sorgt dafür, dass dich die Interaktion mit einem entfernten Ziel zu ihm laufen lässt. WowVision setzt die Spieloption bei jedem Login passend zu dieser Einstellung. Um sie auszuschalten, benutze also die WowVision-Einstellung, nicht die des Spiels.
- Wenn du eine Art der weichen Zielerfassung einschaltest, setzt WowVision ihren Winkel auf den breitesten und ihre Reichweite auf die größte. Arten, die du ausgeschaltet lässt, behalten die Werte des Spiels. Siehe [Zielerfassung](../world/targeting.md).

Der Puffer Allgemein bekommt außerdem ein paar neue Zeilen (freie Taschenplätze, Haltbarkeit, Post, Ruhestein, Spieluhr), wenn sich ein bestehender Charakter zum ersten Mal nach einem Update einloggt, das sie hinzufügt. Siehe [Puffer](../information/buffers.md).

### Empfohlene Spieleinstellungen (freiwillig)

Im Menü Benutzeroberfläche gibt es den Schalter Empfohlene Spieleinstellungen übernehmen. Das ist nur ein Vorschlag: Es ändert sich nichts, solange du ihn nicht drückst, und jede Einstellung kannst du danach in den Spieloptionen wieder ändern. Er setzt:

- Automatisch plündern an und alle Aktionsleisten sichtbar.
- Namensplaketten außerhalb des Bildschirms an: Solange das Spiel feindliche Namensplaketten zeigt, bekommt ein Gegner hinter oder neben dir sofort seine Namensplakette, so kann die Gegnerzahl ihn gleich ansagen. Die feindlichen Namensplaketten selbst werden hier nicht eingeschaltet; siehe [Namensplaketten sind Pflicht](../world/combat.md#namensplaketten-sind-pflicht).
- Die Audiounterstützung des Spiels an: deine Gesundheit, die Gesundheit deines Ziels und deine Ressource alle 20 Prozent (die Gesundheit nur als Zahl) und wenn du anvisiert wirst (ohne Namen des Angreifers). Kampfbeginn und -ende, Zielname und deine Schwächungen werden abgeschaltet.

Tastenbelegungen, Kamera, weiche Zielerfassung und Lautstärken bleiben unberührt. Im Kampf tut der Schalter nichts. Nach einer Änderung lädt die Oberfläche neu, dann sagt WowVision an, was sich geändert hat, und schreibt dasselbe in dein Chatfenster. Ressource und Anvisiert speichert das Spiel je Spezialisierung; drücke den Schalter nach einem Wechsel der Spezialisierung noch einmal.

## Wie es weitergeht

- [Schnellstart](./quick-start.md): die ersten fünfzehn Minuten.
- [WowVision verwalten](./managing.md): wo deine Einstellungen gespeichert werden und wie du WowVision aktualisierst und entfernst.
- [WowVision zusammen mit Sku verwenden](./sku.md): wenn du auch Sku installiert hast.
- [Fehlerbehebung](./troubleshooting.md): wenn WowVision nicht lädt oder nicht spricht.
- [Befehle](../reference/commands.md): alles, was du tippen kannst, einschließlich /wv speech.
