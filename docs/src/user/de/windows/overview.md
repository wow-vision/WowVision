# Spielfenster

Das meiste in World of Warcraft passiert in Fenstern: deine Taschen, ein Händler, das Questlog, der Talentbaum, der Briefkasten. Ein sehender Spieler klickt sich mit der Maus durch sie hindurch. WowVision liest dir diese Fenster vor und lässt dich sie mit der Tastatur bedienen, wie eine Desktop-Anwendung mit einem Screenreader.

Diese Seite erklärt, wie das im Allgemeinen funktioniert. Die Seiten in diesem Abschnitt gehen die Fenster dann einzeln durch.

## So funktioniert es

Du öffnest ein Spielfenster auf die übliche Weise: mit der eigenen Taste des Spiels (B für die Taschen, C für das Charakterfenster, L für das Questlog und so weiter), indem du mit einem NPC sprichst oder indem du etwas anklickst. WowVision bemerkt, dass das Fenster offen ist, und macht daraus ein WowVision-Fenster:

- Es sagt den Namen des Fensters und das Element, auf dem du stehst, zum Beispiel "Händler" und dann "Leinenstoff, 1 Silber, Schalter".
- Die Fenstertasten funktionieren jetzt: Die Pfeiltasten, Tab und Umschalt+Tab bewegen dich zwischen den Elementen, Eingabe ist ein Linksklick, Rücktaste ein Rechtsklick, Leertaste liest den Tooltip, Umschalt+F10 öffnet das Kontextmenü. All das wird unter [Die Oberfläche bedienen](../basics/interface.md) erklärt.
- Esc schließt das Fenster, genau wie das Schließen im Spiel.

Sobald das Spielfenster sich schließt, schließt sich auch das WowVision-Fenster, und deine Tasten gehen zurück ans Spiel. Solange kein WowVision-Fenster offen ist, tun die Pfeiltasten, Tab, Eingabe und die anderen Fenstertasten das, was du ihnen im Spiel zugewiesen hast, sodass sie dem Spielen nie im Weg stehen.

WowVision ersetzt die Fenster des Spiels nicht; es liest die echten Fenster vor. Alles, was du tust (kaufen, anlegen, ein Talent lernen), ist ein echter Klick im Fenster des Spiels.

## Mehrere Fenster gleichzeitig

Du kannst mehr als ein Fenster geöffnet haben, zum Beispiel einen Händler und deine Taschen. Strg+Tab und Strg+Umschalt+Tab wechseln zwischen ihnen. Jedes Fenster merkt sich das Element, auf dem du warst.

Ein typischer Fall ist das Verkaufen: Sprich mit einem Händler, öffne deine Taschen, suche den Gegenstand und klicke ihn mit Rücktaste rechts an, um ihn zu verkaufen.

## Fenster von WowVision selbst

Einige Fenster gehören zu WowVision und haben im Spiel keine Entsprechung:

| Fenster | Taste | Seite |
|---|---|---|
| WowVision-Menü (Einstellungen) | Umschalt+F1 oder `/wv` | [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md) |
| Chatfenster | Umschalt+F3 | [Chat](chat.md) |
| Fenster für die Aktionsleisten | Umschalt+F4 | [Aktionsleisten](action-bars.md) |
| Scanner | F9 | [Scanner](../world/scanner.md) |
| Navigationsfenster | F10 | [Navigation und Routen](../world/navigation.md) |

Sie funktionieren mit denselben Tasten wie die Spielfenster.

## Im Kampf

Das Spiel erlaubt Addons nicht, im Kampf Tasten zu übernehmen. Beginnt ein Kampf, gibt WowVision seine Fenstertasten ans Spiel zurück und hört auf, Fenster vorzulesen; endet der Kampf, nimmt es sie wieder zurück, und du bist dort, wo du aufgehört hast. Siehe [Kampf](../world/combat.md).

## Ein Fenster ausschalten

Jedes unterstützte Fenster ist ein Modul unter Fenster (Windows) im WowVision-Menü. Wenn du ein Fenster lieber ohne WowVision bedienen willst oder ein anderes Addon es für dich vorliest, schalte dieses Modul dort aus. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

## Wenn Sku geladen ist

Läuft gleichzeitig Sku, das ältere Barrierefreiheits-Addon, überlässt WowVision viele Fenster Sku und liest sie nicht selbst vor. Welche das sind, steht unter [WowVision zusammen mit Sku verwenden](../getting-started/installation.md#wowvision-zusammen-mit-sku-verwenden).

## Fenster, die noch nicht vorgelesen werden

Nicht jedes Spielfenster wird in jeder Version unterstützt. Öffnet sich ein Fenster und WowVision sagt nichts, gehört es wahrscheinlich dazu. [Funktionen nach Spielversion](../reference/versions.md) enthält die vollständige Tabelle; die folgenden Seiten erwähnen, was in den einzelnen Fenstern fehlt.

Fenster, die jede Version vorliest: Taschen und Bank, Händler, NPC-Gespräche, das Questgeber-Fenster, Flugmeister, Lehrer, Handel, der Posteingang, Bücher und Briefe, die Bestätigungs-Popups des Spiels, Bereitschaftscheck und Rollenabfrage, Gildeneinladungen, das Spielmenü und die Optionen, Makros und der Farbwähler. Darüber hinaus hat jede Version ihren eigenen Satz:

| Version | Weitere Fenster |
|---|---|
| Classic Era | Freunde-, Ignorier- und Wer-Listen, die klassischen Gildenfenster, der Reiter Post senden. Sonst noch nichts. |
| The Burning Crusade (TBC) | Der Satz von Classic Era, dazu Charakterfenster, Zauberbuch, Talente, Berufe, Handwerksfenster, Edelsteinsockelung, Questlog, Tierstall, Gruppensuche und Auktionshaus. |
| Mists of Pandaria (Mists) | Der Satz von Classic Era, dazu Charakterfenster, Zauberbuch, Talente, Berufe, Edelsteinsockelung, Umschmieden, Gegenstandsaufwertung, Questlog, Questauswahl, Reittierjournal und Auktionshaus. |
| Retail | Questlog, Auktionshaus, Chatkanäle, das Fenster Kontakte (Social), Gilde und Gemeinschaften, Gildenverwaltung und das Fenster des Abklingzeitmanagers. |
| WoW: Forever | Der Satz von Retail, dazu Charakterfenster, Zauberbuch mit Talenten, Berufe, Sammlungen, Vermächtnis, Gruppensuche, die Gamepad-Fenster und die WowNav-Stockwerkliste. |

## Die Seiten in diesem Abschnitt

- [Aktionsleisten](action-bars.md) — das Fenster für die Aktionsleisten, Zauber und Gegenstände ziehen, Gamepad-Leisten
- [Taschen und Bank](bags-and-bank.md) — Taschen, Bank, Gegenstände benutzen und verschieben, Gegenstände zerstören
- [Mit NPCs sprechen](npcs.md) — Gespräche, Händler, Lehrer, Flugmeister, Bücher und Briefe, Tierstall
- [Beute, Handel und Post](loot-trade-mail.md) — Beutewürfe, Handel mit Spielern, der Briefkasten
- [Charakter](character.md) — Ausrüstung, Werte, Ruf, Fertigkeiten, PvP, Ausrüstungssets
- [Zauber und Talente](spells-and-talents.md) — Zauberbuch, Talente, Glyphen, Zaubersuche
- [Berufe](professions.md) — Berufe, Herstellung, Sockelung, Umschmieden, Gegenstandsaufwertung
- [Sammlungen und Vermächtnis](collections.md) — Reittiere, Haustiere, Spielzeuge, Erbstücke, Erscheinungen, Vermächtnis
- [Gruppensuche](group-finder.md) — Gruppensuche, Bereitschaftscheck, Rollenabfrage
- [Auktionshaus](auction-house.md) — kaufen, verkaufen, Preis-Scans
- [Chat](chat.md) — Chatansagen, das Chatfenster, Links anklicken
- [Soziales](social.md) — Freunde, Gilde, Gemeinschaften, Kanäle
- [Menüs, Optionen und Dialoge](system.md) — Spielmenü, Spieloptionen, Popups, Makros und mehr
