# Installation

Diese Seite zeigt dir, wie du WowVision herunterlädst, in den richtigen Ordner deiner Spielversion legst, einschaltest und was beim ersten Login eines Charakters passiert. Außerdem erfährst du, wo WowVision deine Einstellungen speichert, wie du es aktualisierst und wie du es wieder entfernst.

WowVision beginnt zu arbeiten, sobald dein Charakter in der Welt steht. Den Anmeldebildschirm, die Realmliste und die Charakterauswahl kann es noch nicht vorlesen. Wie du dich dort durchschlägst, steht unter [Anmelden mit dem Sku-Login-Tool](./sku-login.md); oder bitte beim ersten Mal einen sehenden Freund um Hilfe.

## Herunterladen

WowVision wird auf GitHub veröffentlicht. Es gibt zwei Arten von Downloads, und beide bestehen aus einer einzelnen Zip-Datei.

- Das neueste Release. Die stabile Version. Du lädst sie von der [Release-Seite von WowVision](https://github.com/wow-vision/WowVision/releases/latest) herunter. Das Zip ist nach der Version benannt, zum Beispiel WowVision-V0.9.0.zip, und ist ein großer Download (etwa 100 MB).
- Die Beta-Vorabversion. Zwischen den Releases gibt es genau eine Vorabversion namens beta. Sie wird jedes Mal neu gebaut, wenn die Entwickler etwas ändern. Sie ist also für Tester gedacht und für WoW: Forever, das sich schnell verändert. Sie liegt immer unter derselben Adresse: [die Seite der Beta-Vorabversion](https://github.com/wow-vision/WowVision/releases/tag/beta). Das Zip selbst liegt immer unter https://github.com/wow-vision/WowVision/releases/download/beta/WowVision-beta.zip. Die Versionshinweise auf dieser Seite listen jede Änderung seit dem letzten Release auf.

Beide Arten installierst du auf dieselbe Weise. Wenn du die Beta über eine ältere Kopie installierst, ersetzt sie einfach die Dateien.

### Was im Zip steckt

Das Zip enthält auf oberster Ebene zwei Addon-Ordner:

- WowVision: das Addon selbst. Es enthält alles für alle Spielversionen, auch die Übersetzungen sowie die Sounds und Sprachaufnahmen, die WowVision abspielt. Übersetzungen und Audio musst du nicht getrennt herunterladen.
- WowVision_MapData_TBC: die Kartendaten, mit denen die Navigation (das F10-Fenster und die Routen) auf den Anniversary-Realms von The Burning Crusade und in WoW: Forever funktioniert. Siehe [Navigation und Routen](../world/navigation.md). Für die anderen Spielversionen ist er nicht gedacht; dort kannst du ihn weglassen. WoW: Forever kann außerdem mit WowNav routen. Dessen Navigationsdaten liegen schon im Ordner WowVision (siehe [WowNav (WoW: Forever)](../world/wownav.md)).

Beide Ordner werden durch dasselbe Entpacken angelegt. Kartendaten-Addons, die andere Leute veröffentlichen, kannst du daneben installieren.

## Wo du es ablegst

Entpacke das Zip in den Ordner AddOns der Spielversion, die du spielst. Jede Spielversion hat in deiner World-of-Warcraft-Installation einen eigenen Ordner. Der übliche Installationsordner ist C:\Program Files (x86)\World of Warcraft\.

| Spielversion | Ordner in der Installation | AddOns-Ordner |
|---|---|---|
| Classic Era (Vanilla) | `_classic_era_` | `_classic_era_\Interface\AddOns` |
| The Burning Crusade (TBC), Anniversary | `_anniversary_` | `_anniversary_\Interface\AddOns` |
| Mists of Pandaria (Mists) | `_classic_` | `_classic_\Interface\AddOns` |
| Retail | `_retail_` | `_retail_\Interface\AddOns` |
| WoW: Forever | `_forever_` | `_forever_\Interface\AddOns` |

Wenn die Ordner Interface und AddOns noch nicht existieren, lege sie an. Wenn du mehrere Versionen spielst, entpacke das Zip einmal in den AddOns-Ordner jeder Version.

Beispiel: Du spielst The Burning Crusade. Entpacke das Zip nach C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns. Danach liegen die Ordner WowVision und WowVision_MapData_TBC in diesem AddOns-Ordner.

### So sieht die richtige Ordnerstruktur aus

Nach dem Entpacken muss der AddOns-Ordner Folgendes enthalten:

- `WowVision`
  - `WowVision_Vanilla.toc`
  - `WowVision_TBC.toc`
  - `WowVision_Mists.toc`
  - `WowVision_Standard.toc`
  - `WowVision_Camelot.toc`
  - die Ordner `core`, `classic`, `retail`, `libs` und so weiter
- `WowVision_MapData_TBC`
  - `WowVision_MapData_TBC.toc`
  - und die zugehörigen Kartendateien

Der Test: Die TOC-Dateien müssen direkt im Ordner WowVision liegen.

### Der häufige Fehler: ein verschachtelter Ordner

Viele Entpackprogramme bieten an, "in einen neuen Ordner mit dem Namen des Zips" zu entpacken. Wenn du das annimmst, kann ein Ordner im Ordner entstehen, sodass die TOC-Dateien unter AddOns\WowVision\WowVision\WowVision_Standard.toc liegen. Dann findet das Spiel gar kein Addon, und WowVision lädt stillschweigend nie. Dasselbe passiert, wenn du das Zip auf den Desktop entpackst und dann den eigenen Ordner des Zips in einen Ordner namens WowVision kopierst.

Zur Reparatur verschiebst du den inneren Ordner WowVision eine Ebene nach oben, sodass die TOC-Dateien eine Ebene höher liegen, und löschst den leeren äußeren Ordner. Entpacke immer direkt in den Ordner AddOns und lass das Zip die beiden Ordner selbst anlegen.

## Die fünf TOC-Dateien

Eine TOC-Datei ist eine kleine Liste, die dem Spiel sagt, was ein Addon ist und welche Dateien es laden soll. WowVision bringt eine pro Spielversion mit, und das Spiel wählt die richtige selbst aus; du wählst nie.

| Spielversion | Verwendete TOC-Datei | Was geladen wird |
|---|---|---|
| Classic Era | `WowVision_Vanilla.toc` | der gemeinsame Kern, die gemeinsamen Classic-Module und die Classic-Era-Module |
| The Burning Crusade | `WowVision_TBC.toc` | der Kern, die gemeinsamen Classic-Module und die TBC-Module |
| Mists of Pandaria | `WowVision_Mists.toc` | der Kern, die gemeinsamen Classic-Module und die Mists-Module |
| Retail | `WowVision_Standard.toc` | der Kern und die Retail-Module |
| WoW: Forever | `WowVision_Camelot.toc` | der Kern, die Retail-Module und die Forever-Module (mit einigen Classic- und Mists-Teilen für Fenster, die der Forever-Client mit ihnen teilt) |

Für die Version gibt es keine Einstellung. Wenn eine Funktion nur auf manchen Versionen existiert, sagt das Handbuch es, zum Beispiel (nur Retail und WoW: Forever). Die vollständige Tabelle findest du unter [Funktionen nach Spielversion](../reference/versions.md).

## Übersetzungen und Sounds

WowVision bringt Texte auf Englisch, Deutsch und Französisch mit; die Sprache deines Spielclients entscheidet, welche benutzt wird, und jede andere Clientsprache fällt auf Englisch zurück.

Die Sounds, Signaltöne und aufgenommenen Stimmen (Stimmenpakete) liegen ebenfalls im Ordner WowVision. Wenn du jemals ein Problem mit einem "fehlenden Sound" hast, liegt es an einer beschädigten oder unvollständigen Entpackung: Lösche den Ordner und entpacke das Zip erneut.

## Optionale Addons

WowVision funktioniert allein. Es kennt außerdem drei andere Addons und nutzt sie, wenn sie installiert sind. In den TOC-Dateien von WowVision stehen sie als optional, sodass das Spiel sie zuerst lädt, wenn sie eingeschaltet sind.

| Addon | Was es ist | Was WowVision damit macht | Eingetragen für |
|---|---|---|---|
| Sku | Das altbewährte Barrierefreiheits-Addon | Wenn Sku geladen ist, zieht sich WowVision von einer Liste von Fenstern, Tasten und Befehlen zurück und überlässt sie Sku. Siehe [WowVision zusammen mit Sku verwenden](#wowvision-zusammen-mit-sku-verwenden). | alle Versionen |
| BlindSlash | Ein weiteres Barrierefreiheits-Addon, auf Retail verbreitet | Die beiden Befehle /enableaddon und /disableaddon werden nicht registriert, wenn BlindSlash geladen ist. | Retail, Mists, WoW: Forever |
| Questie | Das Addon mit der Quest-Datenbank | WowVision liest Questgeber, Ziele und Orte aus Questie, wenn es installiert ist, und sonst aus den eigenen Questdaten des Spiels. Questie stellt beim ersten Start eine einmalige Frage, die WowVision als Fenster vorliest. | Classic Era, TBC, Mists, WoW: Forever |

Alles zu Quests und Questie, einschließlich der Frage beim ersten Start, steht unter [Quests](../world/quests.md).

## Das Addon einschalten

Neue Addons werden nur beim Start des Spiels gefunden. Starte das Spiel also nach dem Kopieren der Dateien neu. Ein /reload reicht für ein ganz neues Addon nicht aus.

Öffne auf dem Charakterauswahlbildschirm die Liste AddOns (eine Schaltfläche unten links auf dem Bildschirm). Suche WowVision in der Liste und achte darauf, dass es angehakt ist. Hake auch WowVision_MapData_TBC an, wenn du The Burning Crusade oder WoW: Forever spielst. Das Spiel merkt sich diese Wahl pro Charakter; die Liste hat ein Auswahlfeld, mit dem du einen einzelnen Charakter oder alle Charaktere wählst.

### Veraltete AddOns

Wenn das Spiel einen Patch bekommt, werden Addons, die für den alten Patch gebaut wurden, als veraltet markiert und nicht geladen. Oben in der AddOns-Liste gibt es ein Kontrollkästchen namens Veraltete AddOns laden (Load out of date AddOns). Hake es an, wenn WowVision als veraltet markiert ist. WowVision wird normalerweise kurz nach einem Patch aktualisiert; schau also auch auf der Release-Seite nach einer neuen Version.

Der Kartendaten-Ordner ist für die Clients von Burning Crusade und Forever gebaut. Classic Era hat fast dieselbe Welt wie The Burning Crusade, deshalb funktioniert er dort auch; schalte Veraltete AddOns laden ein, falls das Spiel ihn als veraltet markiert. Auf Mists und Retail lass ihn ausgeschaltet; er ist für diese Versionen nicht gedacht.

Wenn dir die Charakterauswahl Probleme macht, kann das Sku-Login-Tool sie für dich bedienen. Siehe [Anmelden mit dem Sku-Login-Tool](./sku-login.md). Wenn WowVision nicht lädt, geh zu [Fehlerbehebung](./troubleshooting.md).

## Erster Login

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

- Die Spieloption Klicken zum Bewegen (Click to Move) folgt der Einstellung Automatisch zum Interaktionsziel bewegen (Auto-move to Interact Target) im Navigationsmenü von WowVision (standardmäßig an); sie sorgt dafür, dass dich die Interaktion mit einem entfernten Ziel zu ihm laufen lässt. WowVision schreibt nur dann ins Spiel, wenn sich diese Einstellung ändert: Schaltest du sie aus, wird Klicken zum Bewegen ausgeschaltet, und WowVision schaltet es bei jedem Login erneut aus, solange die Einstellung aus ist. Wenn du sie angeschaltet lässt, schaltet das allein die Spieloption nicht ein. Wenn du Klicken zum Bewegen willst, prüfe also in den Spieloptionen unter Steuerung, dass es an ist, oder schalte die WowVision-Einstellung aus und wieder an.
- Die Optionen der weichen Zielerfassung ändern nichts, bis du sie selbst setzt. Siehe [Zielerfassung](../world/targeting.md).

Der Puffer Allgemein bekommt außerdem ein paar neue Zeilen (freie Taschenplätze, Haltbarkeit, Post, Ruhestein, Spieluhr), wenn sich ein bestehender Charakter zum ersten Mal nach einem Update einloggt, das sie hinzufügt. Siehe [Puffer](../information/buffers.md).

## Wo deine Einstellungen gespeichert werden

WowVision hält seine Daten in den eigenen Dateien des Spiels für gespeicherte Variablen. Das Spiel schreibt sie, wenn du dich ausloggst oder /reload tippst, nicht während du spielst. Wenn das Spiel abstürzt oder du es mit dem Task-Manager schließt, gehen Änderungen seit dem letzten Logout oder Reload verloren.

| Gespeicherte Variable | Enthält | Bereich |
|---|---|---|
| WowVisionGlobalDB | Standardmäßig die meisten Einstellungen, Alarme, Puffer und Monitore | Der ganze Account |
| WowVisionDB | Einstellungen, die du auf "dieser Charakter" gelegt hast, sowie deine Tastenbelegungen und die Zauberhistorie | Eine Datei pro Charakter |
| WowVisionDump | Diagnoseaufzeichnungen: Lua-Fehler, Aufzeichnungen blockierter Aufrufe, das Controller-Log, das Laufprotokoll der Minikarte, der Quest-Probe-Bericht und Ähnliches | Der ganze Account |
| WowVisionPriceDB | Die Preisdatenbank des Auktionshauses (nur TBC) | Der ganze Account |

Die Dateien liegen im WTF-Ordner des Spiels, im Versionsordner, in den du installiert hast:

- Accountweite Dateien: `WTF\Account\<ACCOUNTNAME>\SavedVariables\` mit den Namen WowVisionGlobalDB.lua, WowVisionDump.lua und, auf TBC, WowVisionPriceDB.lua.
- Dateien pro Charakter: `WTF\Account\<ACCOUNTNAME>\<Realm>\<Charakter>\SavedVariables\WowVisionDB.lua`.

Standardmäßig teilen sich alle deine Charaktere die meisten Einstellungen. Du kannst die Einstellungen eines Moduls stattdessen einem einzelnen Charakter zuordnen: Setze im WowVision-Menü den Fokus auf das Modul, drücke Umschalt+F10 und wähle Bereich. Die Tastenbelegungen (einschließlich der Controller-Tasten) werden pro Charakter gespeichert. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md) und [Tastenbelegung](../basics/keybindings.md).

Um deine Einrichtung zu sichern, kopiere diese Dateien bei geschlossenem Spiel. Um alles zurückzusetzen, lösche sie bei geschlossenem Spiel; WowVision startet beim nächsten Login mit den Standardwerten. Wenn Einstellungen immer wieder verschwinden, siehe [Einstellungen gehen verloren](./troubleshooting.md#meine-einstellungen-gehen-verloren).

## WowVision aktualisieren

1. Schließe das Spiel vollständig.
2. Lade das neuere Release oder das Beta-Zip herunter.
3. Entpacke es in denselben AddOns-Ordner wie bei der Erstinstallation und stimme dem Ersetzen von Dateien zu. Für ein sauberes Update lösche vorher die alten Ordner WowVision und WowVision_MapData_TBC, damit keine übrig gebliebene Datei einer älteren Version zurückbleibt. Deine Einstellungen liegen nicht in diesen Ordnern und gehen nicht verloren.
4. Starte das Spiel und logge dich ein. Tippe /wv version, um die neue Version zu sehen.

WowVision überträgt gespeicherte Einstellungen selbst auf das neue Format, wenn ein Update das erfordert. Lies die Versionshinweise auf der Release-Seite: Sie listen die Änderungen seit dem letzten Release auf und sagen, wann etwas zurückgesetzt wird. Die Beta wird jedes Mal unter derselben Adresse ersetzt, du kannst sie also so oft aktualisieren, wie du willst.

## Deinstallieren

1. Schließe das Spiel.
2. Lösche die Ordner WowVision und WowVision_MapData_TBC aus dem AddOns-Ordner.
3. Lösche optional die oben aufgeführten Dateien mit den gespeicherten Variablen von WowVision, um die gespeicherten Einstellungen zu entfernen.

Die Änderungen, die WowVision beim ersten Login einmalig vorgenommen hat (die Sperre der Aktionsleisten, der Kamera-Folgestil und der Ton zwischen Chatzeilen), und Klicken zum Bewegen, falls du es mit der WowVision-Einstellung umgeschaltet hast, bleiben im Spiel, wenn du das Addon entfernst. Stelle sie in den Spieloptionen zurück, wenn du sie wie vorher haben willst, wie in der Tabelle oben beschrieben.

## WowVision zusammen mit Sku verwenden

WowVision und Sku können nebeneinander installiert sein, und viele Spieler nutzen beide. Sie streiten nicht um dieselben Fenster: Ist Sku geladen, zieht sich WowVision bewusst von den unten aufgeführten Fenstern, Tasten und Befehlen zurück und überlässt sie Sku. Alles, was nicht auf der Liste steht, erledigt weiterhin WowVision.

### So funktioniert es

Wenn das Spiel WowVision lädt, prüft es, welche Addons schon geladen sind. Ist Sku darunter, wird jedes Fenster, jede Tastenbelegung und jeder Befehl, der als "gehört Sku" markiert ist, für diese Sitzung abgeschaltet: Das Fenster öffnet sich in WowVision schlicht nie, die Taste wird nicht übernommen, der Befehl wird nicht registriert. Die Entscheidung fällt einmal beim Login. Das Ein- oder Ausschalten von Sku braucht deshalb ein Neuladen (/reload) oder einen neuen Login, um zu wirken. Nichts wird gelöscht: Deine WowVision-Einstellungen und Tastenbelegungen für diese Funktionen bleiben, wie sie sind, und kommen zurück, sobald Sku aus ist.

Wenn WowVision ein Fenster nicht vorliest und du Sku geladen hast, ist das mit ziemlicher Sicherheit der Grund. Um Sku für eine Sitzung abzuschalten, deaktiviere es in der AddOns-Liste des Spiels oder tippe /disableaddon sku (das schaltet Sku und seine Hilfs-Addons aus und lädt die Oberfläche neu; /enableaddon sku schaltet sie wieder ein). Diese beiden Befehle werden selbst übersprungen, wenn das Addon BlindSlash geladen ist.

### Was Sku behält, wenn beide geladen sind

Fenster in jeder Spielversion:

- Taschen.
- Gossip und andere NPC-Dialoge.
- Händler.
- Briefkasten.
- Popups (die Bestätigungsdialoge des Spiels).
- Fenster des Questgebers (Quests annehmen und abgeben).
- Flugmeister (Flugkarte).
- Handelsfenster.
- Lehrer.
- Bereitschaftscheck und das Popup für die Dungeonbereitschaft.
- Rollenabfrage (die Popups zur Rollenprüfung).
- Gildeneinladung.

Zusätzliche Fenster in Classic Era, The Burning Crusade (TBC) und Mists of Pandaria (Mists):

- Das Fenster Freunde und Soziales mit den Seiten Freunde, Ignorieren, Wer und Gilde.
- Die Mitgliederkarte, die Gildeninformationen, das Gildenereignisprotokoll und die Gildenverwaltung des klassischen Gildenfensters.

Zusätzliche Fenster nur in The Burning Crusade (TBC):

- Charakterfenster.
- Zauberbuch.
- Talente.
- Berufe und das Handwerksfenster (Craft).
- Tierstall.
- Questlog.

Zusätzliche Fenster nur in Mists of Pandaria (Mists):

- Charakterfenster.
- Talente.
- Questlog.
- Gegenstandsaufwertung.
- Umschmieden.

Zusätzliche Fenster in Retail und WoW: Forever:

- Gilde und Gemeinschaften, mit Mitgliederkarte, Texteditor, Ereignisprotokoll und Neuigkeitenfiltern.
- Gildenverwaltung.
- Das Fenster Soziales mit seinen Nebenfenstern (Ignorierliste, Battle.net-Nachricht, Hinweis "Battle.net nicht verfügbar", Schlachtzugsinfo, Freund hinzufügen).
- Das Fenster des Abklingzeitmanagers und seine Alarm-Editoren.
- Questlog.
- Nur in WoW: Forever: Charakterfenster und das Popup für Ausrüstungssets.

Tasten, die Sku behält (WowVision übernimmt sie nicht, solange Sku geladen ist):

- Die Tasten für die Tooltipzeilen: Vorherige Tooltipzeile und Nächste Tooltipzeile (Umschalt+Pfeil hoch und Umschalt+Pfeil runter), Tooltip links vorlesen und Tooltip rechts vorlesen (Umschalt+Pfeil links und Umschalt+Pfeil rechts).
- Die Umschalter der weichen Zielerfassung Weiches Ziel Feind, Weiches Ziel Freund und Weiches Ziel Interaktion (Umschalt+I, Umschalt+P und Umschalt+O).
- Zielfokus 1 bis Zielfokus 5.

Befehle, die Sku behält: /focus1 bis /focus5, /pquit (Gruppe verlassen) und /dquit (Dungeon- oder Schlachtfeldgruppe verlassen).

### Was WowVision weiterhin für dich tut

Alles andere funktioniert wie gewohnt: Sprache und Alarme, die Puffer und Monitore, Zielansagen, Bewegung und Navigation, der Minikarten-Scan, der Scanner, das Chatfenster und die Chatansagen, das Fenster der Chatkanäle, das Fenster der Aktionsleisten, das Beutefenster, das Auktionshaus, die Fenster für Sammlungen und Berufe, wo Sku keine Entsprechung hat, das Spielmenü und die Optionen sowie das WowVision-Menü.

## Wie es weitergeht

- [Schnellstart](./quick-start.md): die ersten fünfzehn Minuten.
- [Fehlerbehebung](./troubleshooting.md): wenn WowVision nicht lädt oder nicht spricht.
- [Slash-Befehle](../reference/commands.md): alles, was du eintippen kannst, auch /wv speech.
