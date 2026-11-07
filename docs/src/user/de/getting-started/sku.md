# WowVision zusammen mit Sku verwenden

WowVision und Sku können nebeneinander installiert sein, und viele Spieler nutzen beide. Sie streiten nicht um dieselben Fenster: Ist Sku geladen, zieht sich WowVision bewusst von den unten aufgeführten Fenstern, Tasten und Befehlen zurück und überlässt sie Sku. Alles, was nicht auf der Liste steht, erledigt weiterhin WowVision.

## So funktioniert es

Wenn das Spiel WowVision lädt, prüft es, welche Addons schon geladen sind. Ist Sku darunter, wird jedes Fenster, jede Tastenbelegung und jeder Befehl, der als "gehört Sku" markiert ist, für diese Sitzung abgeschaltet: Das Fenster öffnet sich in WowVision schlicht nie, die Taste wird nicht übernommen, der Befehl wird nicht registriert. Die Entscheidung fällt einmal beim Login. Das Ein- oder Ausschalten von Sku braucht deshalb ein Neuladen (/reload) oder einen neuen Login, um zu wirken. Nichts wird gelöscht: Deine WowVision-Einstellungen und Tastenbelegungen für diese Funktionen bleiben, wie sie sind, und kommen zurück, sobald Sku aus ist.

Wenn WowVision ein Fenster nicht vorliest und du Sku geladen hast, ist das mit ziemlicher Sicherheit der Grund. Um Sku für eine Sitzung abzuschalten, deaktiviere es in der AddOns-Liste des Spiels oder tippe /disableaddon sku (das schaltet Sku und seine Hilfs-Addons aus und lädt die Oberfläche neu; /enableaddon sku schaltet sie wieder ein). Diese beiden Befehle werden selbst übersprungen, wenn das Addon BlindSlash geladen ist.

## Was Sku behält, wenn beide geladen sind

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
- Die Umschalter der weichen Zielerfassung Soft Target Feind, Soft Target Freund und Soft Target Interaktion (Umschalt+I, Umschalt+P und Umschalt+O).
- Zielfokus 1 bis Zielfokus 5.

Befehle, die Sku behält: /focus1 bis /focus5, /pquit (Gruppe verlassen) und /dquit (Dungeon- oder Schlachtfeldgruppe verlassen).

## Was WowVision weiterhin für dich tut

Alles andere funktioniert wie gewohnt: Sprache und Alarme, die Puffer und Monitore, Zielansagen, Bewegung und Navigation, der Minikarten-Scan, der Scanner, das Chatfenster und die Chatansagen, das Fenster der Chatkanäle, das Fenster der Aktionsleisten, das Beutefenster, das Auktionshaus, die Fenster für Sammlungen und Berufe, wo Sku keine Entsprechung hat, das Spielmenü und die Optionen sowie das WowVision-Menü.

