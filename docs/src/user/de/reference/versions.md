# Funktionen nach Spielversion

WowVision läuft auf fünf Spielversionen. Das Spiel wählt beim Start selbst den passenden Teil von WowVision aus, du musst also nichts auswählen: Alles, was für deine Version aufgeführt ist, ist einfach da. Diese Seite zeigt, welche Funktionen und Fenster es in welcher Version gibt.

Die Versionen:

- Classic Era — das ursprüngliche Spiel (Vanilla) auf den Classic-Era-Realms
- TBC — The Burning Crusade, auf den Anniversary-Realms
- Mists — Mists of Pandaria Classic
- Retail — die aktuelle Erweiterung von World of Warcraft
- WoW: Forever — der WoW: Forever-Client

The Burning Crusade und Mists of Pandaria sind die Versionen, an denen am meisten gearbeitet wird; WoW: Forever ändert sich schnell. Classic Era und Retail bekommen alles, was alle Versionen gemeinsam haben, aber weniger eigene Spielfenster.

## Gemeinsam in allen Versionen

Das funktioniert überall gleich (kleine Unterschiede werden auf den einzelnen Seiten erklärt):

- Bewegen durch WowVision-Fenster, Klicks, Kontextmenüs, Tooltips: [Die Oberfläche bedienen](../basics/interface.md), [Tooltips](../basics/tooltips.md)
- Spracheinstellungen, Alarme, das WowVision-Menü, Tastenbelegung: [Grundlagen](../basics/index.md)
- Puffer: [Puffer](../information/buffers.md)
- Zielerfassung, weiche Zielerfassung, Fokusziele, das Zielmenü: [Zielerfassung](../world/targeting.md)
- Kampfalarme, Gegneranzahl, Fehlermeldungen des Spiels: [Kampf](../world/combat.md)
- Kompass, Zonen- und Bewegungsalarme, Fall- und Wanderkennung, Folgen, Leichenlauf, Neigungssperre: [Bewegung und Orientierung](../world/movement.md)
- Das Navigationsfenster und Routen (F10), überall dort, wo es Kartendaten gibt: [Navigation und Routen](../world/navigation.md)
- Der Scanner (F9): [Scanner](../world/scanner.md)
- Chat, das Chatfenster und Chat-Reiter-Puffer: [Chat](../windows/chat.md)
- Fenster für die Aktionsleisten (Umschalt+F4): [Aktionsleisten](../windows/action-bars.md)
- NPC-Gespräche, Händler, Lehrer, Flugmeister, Bücher und Briefe: [Mit NPCs sprechen](../windows/npcs.md)
- Questgeber-Fenster: [Quests](../world/quests.md)
- Posteingang, Handelsfenster, Tasten für Beutewürfe: [Beute, Handel und Post](../windows/loot-trade-mail.md)
- Spielmenü, Spieloptionen, Popups, Makros, Farbwähler: [Menüs, Optionen und Dialoge](../windows/system.md)
- Popups für Bereitschaftscheck und Rollenabfrage, Gildeneinladung: [Gruppensuche](../windows/group-finder.md), [Soziales](../windows/social.md)

## Unterschiede nach Version

"Ja" heißt: WowVision liest oder bietet das in dieser Version an. "Nein" heißt: Es ist dort noch nicht verfügbar (das Fenster des Spiels bleibt dann ungelesen, oder die Funktion gibt es in dieser Spielversion nicht).

### Monitore

| Funktion | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Aura-Monitor | Ja | Ja | Ja | Nein | Nein |
| Abklingzeit-Monitor | Ja | Ja | Ja | Nein | Nein |
| Monitor Auren des Abklingzeitmanagers | Nein | Nein | Nein | Ja | Ja |
| Monitor Zauber-Abklingzeiten (mit Proc-Regeln) | Nein | Nein | Nein | Ja | Ja |
| Gruppen-Gesundheitsmonitor (spricht die Gesundheit deiner Gruppe als Zahlen mit Tonhöhe, standardmäßig aus) | Nein | Nein | Nein | Ja | Ja |
| Fenster des Abklingzeitmanagers (`/cdm`) | Nein | Nein | Nein | Ja | Ja |

In Retail und WoW: Forever verbirgt das Spiel Aura- und Abklingzeitdaten im Kampf und in Instanzen vor Addons, deshalb haben diese Versionen eigene Monitortypen. Siehe [Monitore](../information/monitors.md).

### Navigation

| Funktion | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Mit WowVision gelieferte Kartendaten (WowVision_MapData_TBC) | Ja | Ja | Nein | Nein | Ja |
| WowNav-Routenplaner | Nein | Nein | Nein | Nein | Ja |
| Minimap-Scan (Strg+Umschalt+F) | Nein | Nein | Nein | Ja | Ja |

Routen brauchen Kartendaten: Ohne sie hat das Navigationsfenster nichts, entlang dessen es routen könnte, auch wenn der Scanner dich weiterhin direkt auf Dinge zeigen lassen kann. Der Minimap-Scan funktioniert in Retail und WoW: Forever. Den Classic-Clients fehlt eine Minimap-Funktion, die er braucht; in Classic Era, TBC und Mists antwortet die Taste deshalb "Minikarten-Scanner auf diesem Client nicht verfügbar". Siehe [Minimap](../world/minimap.md).

### Taschen, Bank, Post und soziale Fenster

| Fenster | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Taschen und Bank | Ja | Ja | Ja | Ja | Ja |
| Briefkasten: Reiter Post senden | Ja | Ja | Ja | Nein | Nein |
| Freunde-, Ignorier- und Wer-Liste (klassisches Freundesfenster) | Ja | Ja | Ja | Nein | Nein |
| Fenster Kontakte (Social: Freunde, Battle.net-Freunde, Wer) | Nein | Nein | Nein | Ja | Ja |
| Gildenfenster (klassischer Gildenreiter und seine Dialoge) | Ja | Ja | Nein | Nein | Nein |
| Fenster Gilde und Gemeinschaften, Gildenverwaltung | Nein | Nein | Nein | Ja | Ja |
| Fenster Chatkanäle | Nein | Nein | Nein | Ja | Ja |

Siehe [Soziales](../windows/social.md).

### Charakter, Zauber und Berufe

| Fenster | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Charakterfenster | Nein | Ja | Ja | Nein | Ja |
| Zauberbuch | Nein | Ja | Ja | Nein | Ja |
| Talente | Nein | Ja | Ja | Nein | Ja |
| Glyphen | Nein | Nein | Sagt "Glyphen noch nicht umgesetzt" an | Nein | Nein |
| Zaubersuche | Nein | Nein | Nein | Nein | Ja |
| Berufe | Nein | Ja | Ja | Nein | Ja |
| Handwerksfenster (Verzauberkunst) | Nein | Ja | Nein | Nein | Nein |
| Edelsteinsockelung | Nein | Ja | Ja | Nein | Nein |
| Umschmieden und Gegenstandsaufwertung | Nein | Nein | Ja | Nein | Nein |
| Questlog-Fenster | Nein | Ja | Ja | Ja | Ja |
| Questauswahl-Dialog | Nein | Nein | Ja | Nein | Nein |
| Questie-Unterstützung | Ja | Ja | Ja | Nein | Ja |

Einzelheiten zum Questlog pro Version stehen auf der Seite [Quests](../world/quests.md). Siehe auch [Charakter](../windows/character.md), [Zauber und Talente](../windows/spells-and-talents.md) und [Berufe](../windows/professions.md).

### Sammlungen, Gruppensuche, Auktionshaus

| Fenster | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Reittierjournal | Nein | Nein | Ja | Nein | Ja |
| Haustiere, Spielzeuge, Erbstücke, Erscheinungen | Nein | Nein | Nein | Nein | Ja |
| Vermächtnis (Belohnungsleiste, Herausforderungen, Bäume) | Nein | Nein | Nein | Nein | Ja |
| Gruppensuche | Nein | Ja | Nein | Ja (Dungeonbrowser; andere Reiter noch nicht) | Ja |
| Tierstall | Nein | Ja | Nein | Nein | Nein |
| Auktionshaus | Nein | Ja (mit Preisdatenbank und Komplett-Scan) | Ja | Ja (mit Preisdatenbank und Komplett-Scan) | Ja (mit Preisdatenbank und Komplett-Scan) |

Siehe [Sammlungen und Vermächtnis](../windows/collections.md), [Gruppensuche](../windows/group-finder.md) und [Auktionshaus](../windows/auction-house.md).

### Bewegung und Kampf

| Funktion | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Die Neigungssperre gilt auch beim Fliegen | Ja | Ja | Ja | Nein | Nein |
| Alarm CC auf dem Ziel (Ton, wenn dein Ziel betäubt, verängstigt und so weiter ist) | Nein | Nein | Ja | Ja | Ja |
| Das Spiel verbirgt im Kampf und in Instanzen Werte vor Addons (Leben, Ressourcen, Auren und so weiter) | Nein | Nein | Nein | Ja | Ja |

In Retail und WoW: Forever gilt die Neigungssperre nur beim Schwimmen, weil das Drachenreiten über die Neigung gesteuert wird. Der Alarm CC auf dem Ziel braucht einen CC-Filter im Aurensystem des Spiels. Die Clients Classic Era und TBC haben ihn nicht, deshalb fehlt der Alarm dort. Siehe [Zielerfassung](../world/targeting.md), [Bewegung und Orientierung](../world/movement.md) und [Kampf](../world/combat.md).

### Controller

| Funktion | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Gamepad-Unterstützung, Gamepad-Hauptmenü, Gamepad-Aktionsleisten | Nein | Nein | Nein | Nein | Ja |

Die Classic-Clients haben keine Gamepad-Oberfläche. Siehe [Controller](../controller.md).

## Wenn ein Fenster nicht vorgelesen wird

Wird ein Spielfenster aus der Tabelle in deiner Version nicht vorgelesen, obwohl es das sollte, prüfe zuerst zwei Dinge:

- Ist Sku geladen? Solange Sku läuft, überlässt WowVision viele Fenster Sku. Siehe [WowVision zusammen mit Sku verwenden](../getting-started/sku.md).
- Ist das Fenstermodul aktiviert? Jedes Fenster hat unter Fenster (Windows) im WowVision-Menü eine Einstellung Aktiviert (Enabled). Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

Weitere Hilfe steht unter [Fehlerbehebung](../getting-started/troubleshooting.md).
