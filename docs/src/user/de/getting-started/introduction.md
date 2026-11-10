# Einführung

WowVision ist ein Addon für World of Warcraft, mit dem du das Spiel spielen kannst, ohne den Bildschirm zu sehen. Es spricht über die Text-zu-Sprache-Stimmen, die im Spiel und in Windows eingebaut sind. Du brauchst also keinen Screenreader, kannst aber trotzdem einen parallel laufen lassen.

Dieses Handbuch erklärt WowVision aus Sicht des Spielers: was jede Funktion tut, welche Tasten du drückst, was du hörst und was du ändern kannst.

## Was WowVision tut

Es liest die Fenster des Spiels vor und lässt dich sie mit der Tastatur bedienen. Taschen, Händler, Questgeber, der Talentbaum, der Briefkasten, das Auktionshaus und viele mehr werden wie eine Desktop-Anwendung vorgelesen: Die Pfeiltasten und Tab bewegen den Fokus, Eingabe ist ein Linksklick, Rücktaste ein Rechtsklick, Leertaste liest den Tooltip. Siehe [Die Oberfläche bedienen](../basics/interface.md) und [Spielfenster](../windows/overview.md).

Es sagt dir, was um dich herum passiert. Dein neues Ziel, die Zone, die du betrittst, wenn du zu fallen beginnst, gegen eine Wand läufst, in den Kampf gerätst, wie viele Gegner gegen dich kämpfen, Fehlermeldungen des Spiels wie "Außer Reichweite", eingehende Chatnachrichten. Jeden dieser Alarme kannst du sprechen lassen, als Sound abspielen oder ausschalten. Siehe [Alarme](../basics/alerts.md).

Es hält Informationen für dich bereit. Puffer sind Listen, die du jederzeit mit Alt und den Pfeiltasten lesen kannst: dein Leben und dein Mana, dein Gold, deine Erfahrung, freie Taschenplätze, die Buffs und Debuffs auf dir oder deinem Ziel, die Nachrichten eines Chat-Reiters und alles, was du sonst noch hinzufügst. Siehe [Puffer](../information/buffers.md).

Es beobachtet Dinge für dich. Monitore melden sich, wenn ein Debuff von deinem Ziel abfällt, ein Zauber wieder bereit ist oder ein Proc auslöst. Siehe [Monitore](../information/monitors.md).

Es führt dich durch die Spielwelt. Das Navigationsfenster (F10) plant Routen entlang eines Netzes aus Wegpunkten und führt dich mit Beacon-Tönen dorthin. Der Scanner (F9) listet Questgeber, Questziele und andere Dinge in der Nähe auf, und der Minimap-Scan findet Kräuter und Erz. Siehe [Navigation und Routen](../world/navigation.md), [Scanner](../world/scanner.md) und [Minimap](../world/minimap.md).

Es gibt dir zusätzliche Steuerungsmöglichkeiten. Umschalter für die weiche Zielerfassung, fünf Fokusziele, ein Menü für dein Ziel, Tasten für Beutewürfe und in Retail und WoW: Forever Gamepad-Unterstützung. Siehe [Zielerfassung](../world/targeting.md) und [Controller](../controller.md).

## Unterstützte Spielversionen

| Version | Status |
|---|---|
| The Burning Crusade (Anniversary-Realms) | Aktiv in Entwicklung |
| Mists of Pandaria Classic | Aktiv in Entwicklung |
| WoW: Forever | Aktiv in Entwicklung, ändert sich schnell |
| Classic Era | Nur gemeinsame Funktionen |
| Retail | Nur gemeinsame Funktionen |

"Nur gemeinsame Funktionen" bedeutet: Alles, was in allen Versionen funktioniert, ist vorhanden (die Oberfläche, Sprache, Alarme, Puffer, Chat, Navigation, Zielerfassung und viele gängige Fenster), aber einige Spielfenster dieser Version werden noch nicht vorgelesen. Die Einzelheiten stehen unter [Funktionen nach Spielversion](../reference/versions.md).

WowVision befindet sich in der Alpha-Phase. Von Version zu Version ändert sich einiges, und manche Fenster fehlen noch. Deine Fehlerberichte helfen: Siehe [Fehlerbehebung](troubleshooting.md#einen-fehler-melden).

## WowVision und Sku

Viele blinde Spieler kennen Sku, das ältere Barrierefreiheits-Addon. WowVision wurde mit Blick auf Sku-Spieler geschrieben: Viele Sounds und Verhaltensweisen (fallende Töne, Wandgeräusche, die Alt-Gr-Entfernungstaste, Fokusziele) funktionieren so, wie Sku-Spieler es erwarten. Du kannst beide installieren; WowVision überlässt dann einige Fenster und Tasten Sku. Siehe [WowVision zusammen mit Sku verwenden](sku.md).

WowVision kann die Anmelde- und die Charakterauswahl-Bildschirme nicht vorlesen: Das Spiel lädt Addons erst, wenn ein Charakter die Welt betritt, also kann es kein Addon. Das Sku-Login-Tool bringt dich durch sie hindurch: Siehe [Anmelden mit dem Sku-Login-Tool](sku-login.md).

## Wie dieses Handbuch aufgebaut ist

- Erste Schritte — [Installation](installation.md), [dein erster Login](first-login.md) mit dem [Login-Tool](sku-login.md), der [Schnellstart](quick-start.md) für deine ersten Minuten, [WowVision verwalten](managing.md), [zusammen mit Sku verwenden](sku.md) und [Fehlerbehebung](troubleshooting.md).
- [Grundlagen](../basics/index.md) — die Oberfläche, Tooltips, Sprache, das Einstellungsmenü, Alarme und Tastenbelegung. Lies diese Seiten zuerst.
- [Informationen auf Abruf](../information/index.md) — Puffer und Monitore.
- [In der Spielwelt](../world/index.md) — Zielerfassung, Kampf, Bewegung, Navigation, Minimap, Scanner und Quests.
- [Spielfenster](../windows/overview.md) — jedes Spielfenster, das WowVision vorliest, eine Seite pro Thema.
- [Controller](../controller.md) — mit einem Gamepad in Retail und WoW: Forever spielen.
- [Referenz](../reference/index.md) — alle Tasten, alle Befehle, Funktionen pro Version, Glossar und FAQ.

## Konventionen in diesem Handbuch

- Tasten stehen in Fettschrift, mit einem Pluszeichen für Tasten, die gleichzeitig gedrückt werden: Strg+Umschalt+F bedeutet, Strg und Umschalt gedrückt zu halten und F zu drücken. Die Tasten tragen die Namen einer deutschen Tastatur (Strg, Umschalt, Eingabe, Rücktaste, Leertaste, Esc).
- Namen von Einstellungen, Schaltflächen und Menüeinträgen stehen in Fettschrift, genau so, wie WowVision sie spricht, zum Beispiel die Einstellung Elementrichtung umkehren. Auf einem deutschen Spielclient sind das die deutschen Namen; Bezeichnungen, die noch nicht übersetzt sind, spricht WowVision auf Englisch, und sie stehen hier ebenfalls auf Englisch. Wo es hilft, steht die englische Bezeichnung in Klammern dahinter, damit du sie mit englischen Anleitungen vergleichen kannst.
- Gesprochene Beispiele stehen in Anführungszeichen: "250 / 500 Leben".
- Funktionen, die es nur in manchen Spielversionen gibt, sind gekennzeichnet, zum Beispiel (nur WoW: Forever).
- Jede hier genannte Taste ist die Standardbelegung. Du kannst alle ändern; siehe [Tastenbelegung](../basics/keybindings.md).

## Hilfe bekommen

Fragen, Ideen und Fehlerberichte gehen an das [WowVision-Projekt auf GitHub](https://github.com/wow-vision/WowVision).
