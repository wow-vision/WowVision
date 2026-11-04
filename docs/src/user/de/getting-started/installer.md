# Installation mit dem Installer (empfohlen)

Der WowVision-Installer ist ein Windows-Programm, das WowVision für dich installiert und aktuell hält. Er ist der empfohlene Weg, WowVision zu installieren:

- Er findet die World-of-Warcraft-Versionen auf deinem Computer selbst und legt WowVision in den richtigen Ordner jeder Version. Die Ordnerfehler, die unter [Installation von Hand](./manual-installation.md) beschrieben sind, können so nicht passieren.
- Er passt WowVision an den Patch deines Spiels an, sodass ein Patch WowVision nicht am Laden hindert.
- Er schaltet die Frage "Dieses Skript ausführen?" des Spiels ab, die sonst manche Befehle unterbricht.
- Er kann das WoW Login Tool installieren, mit dem die Anmelde- und Charakterbildschirme bedienbar werden, und eine Reihe von Addons, die viele Spieler nutzen.
- Startest du ihn später erneut, aktualisiert er all das.

Jede Seite des Installers sagt sich selbst an, und der Fortschritt wird während der Installation gesprochen. Er funktioniert also mit NVDA, JAWS oder der Sprachausgabe von Windows.

Der Installer läuft nur unter Windows. Auf einem Mac siehe [Installation von Hand](./manual-installation.md).

## Herunterladen und starten

1. Lade den Installer herunter: [WowVisionInstaller.exe](https://github.com/wow-vision/wowvision-installer/releases/latest/download/WowVisionInstaller.exe). Dieser Link liefert immer die neueste Version.
2. Starte die heruntergeladene Datei. Windows fragt, ob das Programm Änderungen an deinem Computer vornehmen darf; wähle Ja. Der Installer braucht das, weil er in den Ordner des Spiels schreibt.
3. Windows warnt eventuell auch, dass es deinen PC vor einer unbekannten App geschützt hat, weil der Installer keine kostenpflichtige Signatur hat. Wähle Weitere Informationen und dann Trotzdem ausführen.

Der Installer spricht die Sprache von Windows (Deutsch, Englisch oder Französisch). Du kannst sie auf der Seite mit den Bestandteilen umstellen, die unten beschrieben ist.

Gibt es eine neuere Version des Installers selbst, bietet er zuerst "Installer jetzt aktualisieren (empfohlen)" an. Wähle das: Es dauert ein paar Sekunden, dann startet der Installer neu und macht weiter.

## Der Startbildschirm

Die Überschrift sagt dir, wo du stehst: "WowVision ist noch nicht installiert", "Eine Aktualisierung für WowVision ist verfügbar", "WowVision ist installiert und aktuell" oder "Keine World-of-Warcraft-Installation gefunden". Darunter liegen die Schaltflächen:

- Jetzt installieren: installiert WowVision in die Spielversionen, die der Installer gefunden hat, mit der empfohlenen Einrichtung. Bei einer ersten Installation ist das alles, was du brauchst.
- Jetzt aktualisieren: aktualisiert WowVision dort, wo es installiert ist, und behält deine bisherige Auswahl bei.
- WowVision neu oder für weitere Spielversionen installieren: der längere Weg, auf dem du die Spielversionen, die Ordner und die Bestandteile selbst wählst. Siehe den nächsten Abschnitt.
- Durchsuchen: erscheint, wenn World of Warcraft nicht gefunden wurde. Wähle deinen World-of-Warcraft-Ordner, einen Spielversions-Ordner wie `_retail_` oder dessen Ordner Interface\AddOns.
- Alle Protokolle sammeln: schreibt eine Zip-Datei in deinen Ordner Downloads, mit den gespeicherten Daten von WowVision, den Protokollen des Spiels und dem Protokoll des Installers. Hänge sie an eine Fehlermeldung an.

## Alles selbst wählen

"WowVision neu oder für weitere Spielversionen installieren" führt durch drei Seiten. Weiter geht vor, Zurück geht zurück.

1. In welche Spielversionen soll WowVision installiert werden? Hake jede Version an, die du spielst: WoW: Forever, The Burning Crusade Anniversary, Classic Era, Mists of Pandaria Classic und Retail. Alle werden in einem Durchgang erledigt.
2. Wo ist welche Version installiert? Die Ordner, in die WowVision geschrieben wird. Ist einer falsch oder fehlt er, nimm die Schaltfläche Durchsuchen daneben.
3. Was soll installiert werden? Die Vorgaben sind die empfohlene Einrichtung; im Zweifel einfach weiter. Die Seite enthält:
   - Sprache dieses Installers.
   - Welche WowVision: Stabile Version (empfohlen) oder Beta. Die stabile Version ist die letzte nummerierte Version und für die meisten Spieler am besten. Die Beta wird mit jeder Änderung neu gebaut, sie hat also die neuesten Korrekturen und Funktionen und kann neue Fehler enthalten. Deine Wahl wird für spätere Aktualisierungen gemerkt.
   - Zusätzliche empfohlene AddOns: Questie, AtlasLoot Continued, Details, Pawn, Deadly Boss Mods, GTFO sowie BugSack mit BugGrabber. Alle außer Pawn sind angehakt. Jede Spielversion bekommt die Ausgabe, die für sie gebaut ist; ein Addon, das es für eine deiner Spielversionen nicht gibt, sagt das und wird dort übersprungen. Was WowVision mit Questie macht, steht unter [Optionale Addons](./installation.md#optionale-addons).
   - Desktop-Verknüpfung zum WowVision-Updater erstellen (angehakt): eine Verknüpfung auf dem Desktop und im Startmenü, um später zu aktualisieren, ohne den Installer erneut herunterzuladen.
   - NVDA als Stimme in WoW aktivieren (nicht angehakt): installiert die NVDA-Sprachbrücke, sodass NVDA in der Stimmenliste des Spiels erscheint und WowVision darüber sprechen kann. Siehe [Sprache und Ton](../basics/speech.md).
   - Alle Windows-Stimmen für WoW verfügbar machen (nicht angehakt): Windows hält seine neueren Stimmen in einer Liste, die das Spiel nicht sieht; das kopiert sie nach einer Sicherung in die Liste des Spiels. Die Stimmennummern des Spiels können sich dabei verschieben, prüfe danach also deine Sprachausgabe-Stimme.
   - WoW Login Tool installieren (empfohlen, angehakt): ein eigenes Programm, das den Anmelde-, Server- und Charakterbildschirmen ein Audiomenü gibt, für WoW: Forever, The Burning Crusade Anniversary und Classic Era. Es ist das Sku-Login-Tool; siehe [Anmelden mit dem Sku-Login-Tool](./sku-login.md).
   - Alles neu installieren (Reparatur) (nicht angehakt): ersetzt WowVision auch dann, wenn es aktuell ist. Nimm das, um eine kaputte Installation zu reparieren.

Wähle dann Installieren.

Die beiden Stimmen-Optionen ändern die Stimmenliste deines ganzen Computers, die dann jedes Sprachprogramm anbietet. Deshalb sind sie standardmäßig aus, und Jetzt aktualisieren führt sie nie aus.

## Während der Installation

Der Installer sagt jeden Schritt an und während des Herunterladens alle 10 Sekunden den Fortschritt. Der bisherige Fortschritt ist eine Liste, die du mit den Pfeiltasten durchgehen kannst. Installation abbrechen hält nach dem laufenden Schritt an; nichts bleibt halb geschrieben.

Für eine erste Installation in eine Spielversion und für die Spieleinstellungen muss das Spiel geschlossen sein. Läuft es dann, bittet dich der Installer, World of Warcraft vollständig zu schließen, und wartet. Ein Update eines bereits installierten WowVision wird auch bei laufendem Spiel kopiert; tippe danach im Spiel /reload.

## Wenn er fertig ist

Die letzte Seite sagt "Fertig" oder "Mit Problemen beendet", mit dem Grund für jede Spielversion. Ereignisprotokoll anschauen listet jeden Schritt des Durchgangs Zeile für Zeile auf. Installer schließen beendet ihn.

Starte dann World of Warcraft über Battle.net, oder tippe /reload, wenn das Spiel lief. Mach weiter mit [Das Addon einschalten](./installation.md#das-addon-einschalten) und [Erster Login](./first-login.md#in-der-welt).

## Aktualisieren mit dem Updater

Starte den WowVision-Updater über seine Verknüpfung auf dem Desktop oder im Startmenü. Es ist dasselbe Programm: Es aktualisiert zuerst sich selbst, wenn nötig, und zeigt dann den Startbildschirm. Wähle Jetzt aktualisieren. Das aktualisiert WowVision in jeder Spielversion, in die es installiert hat, folgt deiner Wahl zwischen Beta und stabiler Version und aktualisiert auch die zusätzlichen Addons.

Um deine Auswahl zu ändern (eine weitere Spielversion, die Beta statt der stabilen Version, die Stimmen-Optionen), wähle stattdessen "WowVision neu oder für weitere Spielversionen installieren".

Eine Beta, die du von Hand entpackt hast, oder ein anderer Testbuild bleibt, wie er ist, bis du Alles neu installieren wählst, weil der Installer nicht erkennen kann, wie alt er ist. Ein nummeriertes Release, das du von Hand entpackt hast, wird normal aktualisiert.

## Was der Installer anlegt

Der Installer hat kein eigenes Deinstallationsprogramm, weil alles, was er tut, aus Dateien und ein paar Einstellungen besteht:

- die WowVision-Ordner im AddOns-Ordner jeder Spielversion, mit einer kleinen Datei WowVisionInstall.json, die festhält, aus welchem Release jeder Ordner stammt;
- die beiden Spieleinstellungen: Veraltete AddOns laden und keine Frage "Dieses Skript ausführen?";
- der Updater in deinem lokalen Anwendungsdatenordner (`%LOCALAPPDATA%\WowVisionUpdater`) und seine Verknüpfungen;
- die zusätzlichen Addons, die du gewählt hast;
- der Ordner des WoW Login Tools und seine Verknüpfungen, wenn du es gewählt hast;
- die NVDA-Sprachbrücke und die kopierten Windows-Stimmen, wenn du sie gewählt hast.

Um WowVision zu entfernen, folge [Deinstallieren](./managing.md#deinstallieren).
