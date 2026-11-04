# Installation

Es gibt zwei Wege, WowVision zu installieren. Diese Seite hilft dir bei der Wahl und behandelt, was nach beiden kommt: die Addons, mit denen WowVision zusammenarbeitet, und das Einschalten des Addons. Mach danach weiter mit [Dein erster Login](./first-login.md).

## Zwei Wege zur Installation

- Mit dem Installer (empfohlen). Der WowVision-Installer ist ein Windows-Programm, das alles für dich erledigt: Er findet deine Spielversionen, legt WowVision in die richtigen Ordner, setzt die Spieleinstellungen, die WowVision braucht, und kann nebenbei das WoW Login Tool und weitere nützliche Addons installieren. Startest du ihn später erneut, hält er alles aktuell. Jeder Schritt wird gesprochen. Siehe [Installation mit dem Installer](./installer.md).
- Von Hand. Du lädst das Zip herunter und entpackst es selbst in den AddOns-Ordner des Spiels. Nimm diesen Weg auf einem Mac, wo der Installer nicht läuft, oder wenn du deine Addons lieber selbst verwaltest. Siehe [Installation von Hand](./manual-installation.md).

Beide geben dir dasselbe WowVision. Welchen Weg du auch wählst, komm für [das Einschalten des Addons](#das-addon-einschalten) auf diese Seite zurück und mach dann weiter mit [Dein erster Login](./first-login.md).

## Optionale Addons

WowVision funktioniert allein. Es kennt außerdem drei andere Addons und nutzt sie, wenn sie installiert sind. In den TOC-Dateien von WowVision stehen sie als optional, sodass das Spiel sie zuerst lädt, wenn sie eingeschaltet sind.

| Addon | Was es ist | Was WowVision damit macht | Eingetragen für |
|---|---|---|---|
| Sku | Das altbewährte Barrierefreiheits-Addon | Wenn Sku geladen ist, zieht sich WowVision von einer Liste von Fenstern, Tasten und Befehlen zurück und überlässt sie Sku. Siehe [WowVision zusammen mit Sku verwenden](./sku.md). | alle Versionen |
| BlindSlash | Ein weiteres Barrierefreiheits-Addon, auf Retail verbreitet | Die beiden Befehle /enableaddon und /disableaddon werden nicht registriert, wenn BlindSlash geladen ist. | Retail, Mists, WoW: Forever |
| Questie | Das Addon mit der Quest-Datenbank | WowVision liest Questgeber, Ziele und Orte aus Questie, wenn es installiert ist, und sonst aus den eigenen Questdaten des Spiels. Questie stellt beim ersten Start eine einmalige Frage, die WowVision als Fenster vorliest. | Classic Era, TBC, Mists, WoW: Forever |

Alles zu Quests und Questie, einschließlich der Frage beim ersten Start, steht unter [Quests](../world/quests.md).

## Das Addon einschalten

Neue Addons werden nur beim Start des Spiels gefunden. Starte das Spiel also nach der Installation, oder starte es neu. Ein /reload reicht für ein ganz neues Addon nicht aus.

Das Spiel schaltet neue Addons von selbst ein. Nach dem Installer lädt WowVision einfach, wenn dein Charakter die Welt betritt, und nach einer Installation von Hand normalerweise auch. Prüfe es mit Umschalt+F1, wie unter [Erster Login](./first-login.md#in-der-welt) beschrieben.

Die eigene Addon-Liste des Spiels auf dem Charakterauswahlbildschirm braucht die Maus; du musst sie nicht benutzen. Lädt WowVision nicht, weil Addons dort ausgeschaltet wurden, zum Beispiel von einem sehenden Helfer, tippe den eigenen Befehl des Spiels /enableaddons, sobald dein Charakter in der Welt ist. Er schaltet alle deine Addons ein und lädt die Oberfläche neu.

### Veraltete AddOns

Wenn das Spiel einen Patch bekommt, ist ein Addon, dessen TOC-Datei für den alten Patch gemacht wurde, veraltet. Der Anmeldebildschirm zeigt dann eine Warnung, dass du veraltete AddOns hast, und das Spiel lädt sie meist gar nicht; das Kontrollkästchen Veraltete AddOns laden in der AddOns-Liste des Spiels ändert daran nichts mehr. Die Lösung ist eine WowVision, deren TOC zum Patch passt:

- Mit dem Installer: Er passt die TOC von WowVision bei jedem Durchgang an den Patch deines Spiels an. Starte nach einem Patch den WowVision-Updater und wähle Jetzt aktualisieren.
- Von Hand: Lade eine neuere WowVision von der Release-Seite herunter. Sie wird normalerweise kurz nach einem Patch aktualisiert.

Der Kartendaten-Ordner ist nur für The Burning Crusade und WoW: Forever gemacht. Auf den anderen Spielversionen hält das Spiel ihn für veraltet; lass ihn bei einer Installation von Hand dort weg. Der Installer legt ihn nur in The Burning Crusade und WoW: Forever ab.

Wenn dir die Charakterauswahl Probleme macht, kann das Sku-Login-Tool sie für dich bedienen. Siehe [Anmelden mit dem Sku-Login-Tool](./sku-login.md). Wenn WowVision nicht lädt, geh zu [Fehlerbehebung](./troubleshooting.md).

## Wie es weitergeht

[Dein erster Login](./first-login.md): wie du durch die Anmeldebildschirme kommst und was passiert, wenn dein Charakter die Welt betritt.
