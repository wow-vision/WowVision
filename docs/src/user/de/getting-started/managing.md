# WowVision verwalten

Wo WowVision deine Einstellungen speichert und wie du sie sicherst, wie du WowVision aktualisierst und wie du es entfernst.

## Wo deine Einstellungen gespeichert werden

WowVision hält seine Daten in den eigenen Dateien des Spiels für gespeicherte Variablen. Das Spiel schreibt sie, wenn du dich ausloggst oder /reload tippst, nicht während du spielst. Wenn das Spiel abstürzt oder du es mit dem Task-Manager schließt, gehen Änderungen seit dem letzten Logout oder Reload verloren.

| Gespeicherte Variable | Enthält | Bereich |
|---|---|---|
| WowVisionGlobalDB | Standardmäßig die meisten Einstellungen, Alarme, Tastenbelegungen, Puffer und Monitore | Der ganze Account |
| WowVisionDB | Einstellungen, die du auf "dieser Charakter" gelegt hast, sowie deine Zauberhistorie | Eine Datei pro Charakter |
| WowVisionDump | Diagnoseaufzeichnungen: Lua-Fehler, Aufzeichnungen blockierter Aufrufe, das Controller-Log, das Laufprotokoll der Minikarte, der Quest-Probe-Bericht und Ähnliches | Der ganze Account |
| WowVisionPriceDB | Die Preisdatenbank des Auktionshauses (The Burning Crusade, Retail und WoW: Forever) | Der ganze Account |

Die Dateien liegen im WTF-Ordner des Spiels, im Versionsordner, in den du installiert hast:

- Accountweite Dateien: `WTF\Account\<ACCOUNTNAME>\SavedVariables\` mit den Namen WowVisionGlobalDB.lua, WowVisionDump.lua und, auf TBC, WowVisionPriceDB.lua.
- Dateien pro Charakter: `WTF\Account\<ACCOUNTNAME>\<Realm>\<Charakter>\SavedVariables\WowVisionDB.lua`.

Standardmäßig teilen sich alle deine Charaktere die meisten Einstellungen. Du kannst die Einstellungen eines Moduls stattdessen einem einzelnen Charakter zuordnen: Setze im WowVision-Menü den Fokus auf das Modul, drücke Umschalt+F10 und wähle Bereich. Die Tastenbelegungen (einschließlich der Controller-Tasten) werden ebenso geteilt und haben einen eigenen Eintrag Bereich auf dem Schalter Tastenbelegung. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md) und [Tastenbelegung](../basics/keybindings.md).

Um deine Einrichtung zu sichern, kopiere diese Dateien bei geschlossenem Spiel. Um alles zurückzusetzen, lösche sie bei geschlossenem Spiel; WowVision startet beim nächsten Login mit den Standardwerten. Wenn Einstellungen immer wieder verschwinden, siehe [Einstellungen gehen verloren](./troubleshooting.md#meine-einstellungen-gehen-verloren).

## WowVision aktualisieren

- Mit dem Installer: Starte den WowVision-Updater über seine Verknüpfung auf dem Desktop oder im Startmenü und wähle Jetzt aktualisieren. Siehe [Aktualisieren mit dem Updater](./installer.md#aktualisieren-mit-dem-updater).
- Von Hand: Lade das neue Zip herunter und ersetze die Ordner. Siehe [Von Hand aktualisieren](./manual-installation.md#von-hand-aktualisieren).

WowVision überträgt gespeicherte Einstellungen selbst auf das neue Format, wenn ein Update das erfordert. Lies die Versionshinweise auf der Release-Seite: Sie listen die Änderungen seit dem letzten Release auf und sagen, wann etwas zurückgesetzt wird. Die Beta wird jedes Mal unter derselben Adresse ersetzt, du kannst sie also so oft aktualisieren, wie du willst.

## Deinstallieren

1. Schließe das Spiel.
2. Lösche die Ordner WowVision und WowVision_MapData_TBC aus dem AddOns-Ordner.
3. Lösche optional die oben aufgeführten Dateien mit den gespeicherten Variablen von WowVision, um die gespeicherten Einstellungen zu entfernen.

Die Änderungen, die WowVision beim ersten Login einmalig vorgenommen hat (die Sperre der Aktionsleisten, der Kamera-Folgestil und der Ton zwischen Chatzeilen), und Klicken zum Bewegen, falls du es mit der WowVision-Einstellung umgeschaltet hast, bleiben im Spiel, wenn du das Addon entfernst. Stelle sie in den Spieloptionen zurück, wenn du sie wie vorher haben willst, wie unter [Was WowVision beim ersten Login eines Charakters ändert](./first-login.md#was-wowvision-beim-ersten-login-eines-charakters-ändert) beschrieben.

Wenn du mit dem Installer installiert hast, hat er vielleicht noch mehr installiert, etwa die zusätzlichen Addons, das WoW Login Tool oder die Stimmen-Optionen. Sie stehen unter [Was der Installer anlegt](./installer.md#was-der-installer-anlegt). Lösche die Ordner dessen, was du nicht mehr willst, und die Verknüpfungen des WowVision-Updaters.

