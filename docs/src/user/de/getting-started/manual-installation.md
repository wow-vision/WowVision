# Installation von Hand

Diese Seite installiert WowVision ohne den Installer: auf einem Mac, wo der Installer nicht läuft, oder wenn du deine Addons lieber selbst verwaltest. Unter Windows ist [der Installer](./installer.md) einfacher und erledigt all das für dich.

Wenn die Dateien an ihrem Platz sind, mach weiter mit [Das Addon einschalten](./installation.md#das-addon-einschalten).

## Herunterladen

WowVision wird auf GitHub veröffentlicht. Es gibt zwei Arten von Downloads, und beide bestehen aus einer einzelnen Zip-Datei.

- Das neueste Release. Die stabile Version. Du lädst sie von der [Release-Seite von WowVision](https://github.com/wow-vision/WowVision/releases/latest) herunter. Das Zip ist nach der Version benannt, zum Beispiel WowVision-V1.0.0.zip, und ist ein großer Download (etwa 100 MB).
- Die Beta-Vorabversion. Zwischen den Releases gibt es genau eine Vorabversion namens beta. Sie wird jedes Mal neu gebaut, wenn die Entwickler etwas ändern. Sie ist also für Tester gedacht. Sie liegt immer unter derselben Adresse: [die Seite der Beta-Vorabversion](https://github.com/wow-vision/WowVision/releases/tag/beta). Das Zip selbst liegt immer unter https://github.com/wow-vision/WowVision/releases/download/beta/WowVision-beta.zip. Die Versionshinweise auf dieser Seite listen jede Änderung seit dem letzten Release auf.

Beide Arten installierst du auf dieselbe Weise. Wenn du die Beta über eine ältere Kopie installierst, ersetzt sie einfach die Dateien.

### Was im Zip steckt

Das Zip enthält auf oberster Ebene zwei Addon-Ordner:

- WowVision: das Addon selbst. Es enthält alles für alle Spielversionen, auch die Übersetzungen sowie die Sounds und Sprachaufnahmen, die WowVision abspielt. Übersetzungen und Audio musst du nicht getrennt herunterladen.
- WowVision_MapData_TBC: die Kartendaten der klassischen Routen, mit denen die Navigation (das F10-Fenster und die Routen) auf den Anniversary-Realms von The Burning Crusade funktioniert. Siehe [Navigation und Routen](../world/navigation.md). WoW: Forever routet standardmäßig mit WowNav, dessen Daten schon im Ordner WowVision liegen (siehe [WowNav (WoW: Forever)](../world/wownav.md)), und benutzt diesen Ordner nur, wenn du WowNav ausschaltest. Für die anderen Spielversionen ist er nicht gedacht; dort kannst du ihn weglassen.

Beide Ordner werden durch dasselbe Entpacken angelegt. Kartendaten-Addons, die andere Leute veröffentlichen, kannst du daneben installieren.

## Wo du es ablegst

Entpacke das Zip in den Ordner AddOns der Spielversion, die du spielst. Jede Spielversion hat in deiner World-of-Warcraft-Installation einen eigenen Ordner. Der übliche Installationsordner ist C:\Program Files (x86)\World of Warcraft\. Auf einem Mac ist es meist World of Warcraft in deinem Ordner Programme, mit denselben Versionsordnern darin.

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

Die Sounds, Beacon-Töne und aufgenommenen Stimmen (Stimmenpakete) liegen ebenfalls im Ordner WowVision. Wenn du jemals ein Problem mit einem "fehlenden Sound" hast, liegt es an einer beschädigten oder unvollständigen Entpackung: Lösche den Ordner und entpacke das Zip erneut.

## Von Hand aktualisieren

1. Schließe das Spiel vollständig.
2. Lade das neuere Release oder das Beta-Zip herunter.
3. Entpacke es in denselben AddOns-Ordner wie bei der Erstinstallation und stimme dem Ersetzen von Dateien zu. Für ein sauberes Update lösche vorher die alten Ordner WowVision und WowVision_MapData_TBC, damit keine übrig gebliebene Datei einer älteren Version zurückbleibt. Deine Einstellungen liegen nicht in diesen Ordnern und gehen nicht verloren.
4. Starte das Spiel und logge dich ein. Tippe /wv version, um die neue Version zu sehen.

## Wie es weitergeht

- [Das Addon einschalten](./installation.md#das-addon-einschalten) und [Erster Login](./first-login.md#in-der-welt).
- [Fehlerbehebung](./troubleshooting.md): wenn WowVision nicht lädt.
