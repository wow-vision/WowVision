# Gruppensuche, Bereitschaftscheck und Rollenabfrage

Diese Seite behandelt alles rund ums Finden und Bilden von Gruppen: das Gruppensuche-Werkzeug (Looking for Group), in dem du dich selbst einträgst oder die Gruppen anderer Spieler durchsuchst, die Popups für Bereitschaftscheck und Rollenabfrage, die erscheinen, sobald eine Gruppe besteht, das Popup „Dungeon bereit“, das Annehmen einer Gruppeneinladung im Kampf und zwei Befehle, mit denen du eine Gruppe schnell verlässt.

## Was es in welcher Spielversion gibt

| Funktion | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Gruppensuche-Werkzeug (Eintragen, Durchsuchen) | nein | ja | noch nicht | noch nicht | ja |
| Dungeonbrowser (Follower- und bestimmte Dungeons) | nein | nein | noch nicht | ja | nein |
| Who-Reiter in der Gruppensuche | nein | nein | nein | nein | ja |
| Popup für den Bereitschaftscheck | ja | ja | ja | ja | ja |
| Popup „Dungeon bereit“ und Popups für die Rollenüberprüfung | wo das Spiel sie zeigt | wo das Spiel sie zeigt | ja | ja | wo das Spiel sie zeigt |
| /pquit und /dquit | ja | ja | ja | ja | ja |
| /wv accept und die Taste Gruppeneinladung annehmen | ja | ja | ja | ja | ja |

In Mists werden die Fenster für Dungeonbrowser, Schlachtzugsbrowser und vorgefertigte Gruppen selbst noch nicht vorgelesen. In Retail wird der Dungeonbrowser vorgelesen, der Schlachtzugsbrowser, die vorgefertigten Gruppen und die anderen Reiter des Fensters dagegen nicht. Die Popups, die daraus entstehen (Dungeon bereit, Rollenüberprüfung), werden vorgelesen, und /dquit verlässt die Gruppe danach.

Ist das Addon Sku geladen, überlässt WowVision den Bereitschaftscheck, die Popups für „Dungeon bereit“ und Rollenabfrage sowie die Befehle /pquit und /dquit Sku.

## Das Gruppensuche-Werkzeug (TBC und WoW: Forever)

Das Werkzeug hat in The Burning Crusade zwei Reiter (Listing und Browse) und in WoW: Forever drei (Listing, Browse und Who). Die Reiternamen liefert das Spiel; ein deutscher Client kann sie auch übersetzt sprechen. Du öffnest das Werkzeug mit der Gruppensuche-Taste des Spiels oder über das Mikromenü. WowVision liest es vor, sobald es sich öffnet, und Esc schließt es.

Die erste Station ist die Zeile Reiter. Pfeil links und Pfeil rechts bewegen dich darin; der geöffnete Reiter sagt „ausgewählt“.

- In TBC wechselst du mit Eingabe auf einem Reiter zu diesem Reiter.
- In WoW: Forever führt Eingabe auf dem Reiter Listing oder Who die Taste des Spiels für diesen Reiter aus, denn ein Eintrag lässt sich nur aufgeben, wenn das Spiel selbst den Reiter wechselt. Diese Spieltasten schalten das Fenster um, deshalb tut Eingabe nur auf einem Listing- oder Who-Reiter etwas, der gerade nicht geöffnet ist. Drückst du direkt nach dem Wechsel ein zweites Mal Eingabe, würde das Fenster schließen, so wie es die Taste tut. Eingabe auf Browse wechselt ganz normal.

Mit Tab und Umschalt+Tab wechselst du zwischen den Bereichen eines Reiters; innerhalb eines Bereichs benutzt du die Pfeiltasten. Siehe [Die Oberfläche bedienen](../basics/interface.md).

### Listing-Reiter: dich oder deine Gruppe eintragen

Die Stationen von oben nach unten:

1. Optionen (wenn angezeigt): eine Schaltfläche, die „Empfohlene Stufe ignorieren“ (Ignore suggested level) sagt, gefolgt von „Aktiviert“ oder „Nicht aktiviert“. Eingabe öffnet das kleine Menü des Spiels, in dem du den Haken setzen kannst. Ist er gesetzt, erscheinen auch Aktivitäten außerhalb deines Stufenbereichs. In TBC gibt es sie auf beiden Reitern, in WoW: Forever nur auf dem Browse-Reiter.
2. Kategorien, solange du noch keine gewählt hast. Jede Kategorie ist eine Schaltfläche; Eingabe wählt sie. Eine leere Liste sagt „Leer“.
3. Aktivitäten, nachdem du eine Kategorie gewählt hast (sie ersetzen die Kategorien). Ein Baum aus Aktivitätsgruppen und Aktivitäten. Jede Zeile sagt:
   - den Namen der Aktivität, dann ihre empfohlenen Stufen, wo sie welche hat, zum Beispiel „(15 - 25)“ des Spiels,
   - „Aktiviert“ oder „Nicht aktiviert“,
   - „Ausgeklappt“ oder „Eingeklappt“ bei einer Gruppe, die sich zusammenfalten lässt.

   Eingabe setzt oder entfernt den Haken. Setzt du den Haken bei einer Gruppe, werden alle Einträge darin angehakt. Um eine Gruppe ein- oder auszuklappen, öffne das Kontextmenü (Umschalt+F10) und wähle Aus-/Einklappen (Expand/Collapse). Eine Gruppe ohne Aktivität für deine Stufe startet eingeklappt.
4. Zurück (Back): führt von den Aktivitäten zurück zu den Kategorien (wenn das Spiel seine Zurück-Schaltfläche zeigt).
5. Rollen: drei Kontrollkästchen, Tank, Heiler und Schadensausteiler, solange du allein bist. Bist du in einer Gruppe, steht stattdessen ein Rollen-Dropdown und eine Schaltfläche zum Starten einer Rollenabfrage da (mit den Beschriftungen des Spiels). Danach kann ein Kontrollkästchen Neuspielerfreundlich folgen.
6. Kommentar: ein Eingabefeld für den Text, den andere Spieler sehen. Wenn du mit Tab ankommst, kannst du sofort tippen.
7. Nur in WoW: Forever, nach dem Kommentar und nur solange die Aktivitäten (nicht die Kategorien) angezeigt werden: Spielstil (ein Dropdown, das „Spielstil“ und deine Auswahl sagt; das Spiel verlangt eine Auswahl, bevor du einen Eintrag aufgeben kannst), ein Kontrollkästchen für den Stufenfilter der Aktivitätenliste und ein Dropdown für den Sprach-Chat, das seine Beschriftung und deine Auswahl sagt.
8. Die Schaltfläche des Spiels zum Aufgeben des Eintrags (Post); ihr Text ist der, den das Spiel anzeigt.

Kann das Spiel dich gerade nicht eintragen (zum Beispiel wegen deiner Stufe oder deines Gruppenstatus), wird der ganze Reiter durch den Erklärungstext des Spiels ersetzt, der als eine Zeile gelesen wird.

### Beispiel: dich für einen Dungeon eintragen (TBC)

1. Drücke die Gruppensuche-Taste. Das Fenster öffnet sich auf dem Listing-Reiter.
2. Mit Tab zu Kategorien, mit Pfeil runter zu „Dungeons“, dann Eingabe.
3. Du bist jetzt bei Aktivitäten. Mit Pfeil runter zu „Schattenlabyrinth“, Eingabe drücken; es sagt „Aktiviert“.
4. Mit Tab zu Rollen, hake Schadensausteiler mit Eingabe an.
5. Mit Tab zu Kommentar, tippe „dps, kenne die Kämpfe“, dann weiter mit Tab.
6. Mit Tab zur Schaltfläche zum Eintragen (Post) und Eingabe drücken. Andere Spieler sehen jetzt deinen Eintrag.

### Browse-Reiter: eine Gruppe suchen

Die Stationen von oben nach unten:

1. Kategoriefilter und Aktivitätsfilter: zwei Dropdowns (mit den Beschriftungen des Spiels). Eingabe öffnet das Menü des Spiels.
2. Suchen: eine Schaltfläche, die die Ergebnisse mit deinen Filtern aktualisiert.
3. Optionen (die oben beschriebene Schaltfläche „Empfohlene Stufe ignorieren“).
4. Gruppen durchsuchen: die Ergebnisse.
5. Zwei Schaltflächen, die erscheinen, wenn eine Gruppe ausgewählt ist: die Schaltflächen des Spiels zum Anschreiben des Anführers und zum Einladen (ihre Beschriftungen kommen vom Spiel).

Jedes Ergebnis in der Liste sagt: den Namen des Anführers, den Kurznamen der Aktivität, die Gruppengröße und den Kommentar, getrennt durch „ - “, zum Beispiel:

> Thrall - Schattenlabyrinth - 3/5 Mitglieder - Heiler gesucht, keine Ninjas

In WoW: Forever hat die Liste zwei einklappbare Überschriften, Solo Players und Groups (so beschriftet sie das Spiel), die jeweils „Ausgeklappt“ oder „Eingeklappt“ sagen. Eingabe auf einer Überschrift klappt sie ein oder aus. Ein ausgewähltes Ergebnis sagt „ausgewählt“.

| Taste auf einem Ergebnis | Was sie tut |
|---|---|
| Eingabe | Wählt die Gruppe aus |
| Rücktaste | Öffnet das Menü des Spiels für diesen Eintrag (Flüstern und Ähnliches) |
| Leertaste | Liest den Tooltip der Gruppe vor |

Wenn du einen Eintrag aufgibst und das Spiel „Blocked: Search()“ meldet, sagt WowVision „Gruppensuche blockiert, zum erneuten Suchen neu laden“. Die Suchen-Schaltfläche des Spiels bleibt dann deaktiviert, bis du /reload eingibst. Das ist eine Einschränkung des Spiels, kein Fehler in deinen Einstellungen.

### Beispiel: eine Gruppe für einen Dungeon finden (TBC)

1. Öffne die Gruppensuche und wechsle in der Zeile Reiter zum Browse-Reiter.
2. Mit Tab zum Kategorie-Dropdown, Eingabe drücken, „Dungeons“ wählen.
3. Mit Tab zum Aktivitäts-Dropdown und den Dungeon wählen.
4. Mit Tab zu Suchen und Eingabe drücken.
5. Mit Tab zu Gruppen durchsuchen und mit Pfeil runter die Ergebnisse anhören.
6. Drücke bei einer Gruppe, die dir gefällt, Eingabe, gehe mit Tab zur Schaltfläche zum Anschreiben des Anführers und drücke Eingabe.

### Who-Reiter (WoW: Forever)

In WoW: Forever hat das Freundesfenster keinen Wer-Reiter, deshalb steckt er in der Gruppensuche. Es ist eine Spielersuche. Die Stationen:

1. Suchen: ein Eingabefeld. Eingabe darin startet die Suche mit deinem Text und dem Filter. Die separate Suchschaltfläche des Spiels ist weggelassen, weil Eingabe dasselbe tut.
2. Filter: ein Dropdown für Klasse, Volk, Zone und Sortierung.
3. Eine nach dem Reiter benannte Liste (meist „Who“), eine Zeile pro Spieler: Name, „Stufe 60 Krieger“, Volk, Zone und Gilde, durch Kommas verbunden. Eingabe hebt den Spieler hervor, Rücktaste öffnet das Spielermenü (Flüstern, Einladen).
4. Eine Summenzeile. Sie wird nur gelesen, wenn der Server mehr Spieler gefunden als gesendet hat; der Server sendet höchstens 50.

Das Kontextmenü (Umschalt+F10) eines Ergebnisses hat zuerst Einladen (Invite), danach die Einträge des Spielermenüs.

## Die Gruppensuche in Retail

In Retail öffnet die Gruppensuche-Taste (oder das Mikromenü) das Gruppensuche-Fenster des Spiels. WowVision liest es vor, sobald es sich öffnet, und Esc schließt es. WoW: Forever benutzt dieses Fenster nicht; dort gibt es das oben beschriebene Gruppensuche-Werkzeug. Bisher wird nur der Dungeonbrowser vorgelesen.

Mit Tab und Umschalt+Tab wechselst du zwischen den Stationen des Fensters; innerhalb einer Station benutzt du die Pfeiltasten. Die Stationen von oben nach unten:

1. Reiter: die Reiter am unteren Rand des Fensters (Gruppensuche, Spieler gegen Spieler, Mythic+-Dungeons und was dein Spiel sonst noch zeigt). Pfeil links und Pfeil rechts bewegen dich durch die Zeile; der geöffnete Reiter sagt „ausgewählt“. Eingabe öffnet einen Reiter.
2. Die Schaltflächen des Reiters Gruppensuche: Dungeonbrowser, Schlachtzugsbrowser und Vorgefertigte Gruppen, in den Worten des Spiels. Die geöffnete sagt „ausgewählt“. Eingabe öffnet sie.
3. Die Seite der geöffneten Schaltfläche. Nur der Dungeonbrowser wird vorgelesen. Bei jedem anderen Reiter und jeder anderen Schaltfläche hörst du „Dieser Reiter wird noch nicht unterstützt“.

### Dungeonbrowser

Die Stationen des Dungeonbrowsers von oben nach unten:

1. Rollen: die Kontrollkästchen Tank, Heiler und Schadensausteiler, dazu ein Kontrollkästchen Anführer, wo das Spiel es zeigt. Pfeil links und Pfeil rechts bewegen dich darin; Eingabe setzt einen Haken, und es sagt „Aktiviert“ oder „Nicht aktiviert“.
2. Das Typ-Dropdown. Es sagt die Beschriftung des Spiels und deine aktuelle Auswahl. Eingabe öffnet das Menü des Spiels, in dem du wählst, wofür du dich anstellen willst: ein zufälliger Dungeon, Follower-Dungeons oder bestimmte Dungeons, je nachdem, was dein Charakter darf.
3. Die Seite zu diesem Typ:
   - Bei einem zufälligen Dungeon: die Belohnungen, die das Spiel dafür auflistet, als eine Zeile gelesen.
   - Bei Follower-Dungeons: zuerst die kurze Erklärung des Spiels, dann die Liste der Follower-Dungeons.
   - Bei bestimmten Dungeons: die Liste der Dungeons.
4. Gruppe suchen (Find Group): die Schaltfläche des Spiels, die dich in die Warteschlange stellt. Eingabe drückt sie.

Jede Zeile einer Dungeonliste sagt der Reihe nach:

- den Namen des Dungeons,
- seine Stufen, zum Beispiel „(Stufe 60)“ oder „(Stufen 15 - 25)“, wo das Spiel sie angibt,
- seinen Zustand: „Aktiviert“, „Nicht aktiviert“, „Teilweise ausgewählt“ (eine Überschrift, bei der nur einige ihrer Dungeons angehakt sind) oder „Gesperrt“,
- bei einer Überschrift, die Dungeons zusammenfasst, „Ausgeklappt“ oder „Eingeklappt“.

Eingabe setzt oder entfernt den Haken bei einem Dungeon. Setzt du den Haken bei einer Überschrift, werden alle Dungeons darin angehakt. Um eine Überschrift ein- oder auszuklappen, öffne auf ihr das Kontextmenü (Umschalt+F10) und wähle Aus-/Einklappen.

Für einen gesperrten Dungeon kannst du dich nicht anstellen. Den Grund hörst du, wenn du auf der Zeile die Tooltip-Taste drückst (standardmäßig die Leertaste, siehe [Tooltips](../basics/tooltips.md)): Der Sperrgrund des Spiels wird vorgelesen, zum Beispiel dass deine Stufe zu niedrig ist.

Sucht deine Gruppe noch nach Mitgliedern oder hast du die Deserteur-Strafe, legt das Spiel eine Meldung über den Browser. WowVision liest dann diese Meldung und ihre Schaltflächen statt der Typ-Seite vor; die Rollen, das Typ-Dropdown und Gruppe suchen bleiben, wo sie waren.

### Beispiel: für einen Follower-Dungeon anstellen

1. Drücke die Gruppensuche-Taste. Das Fenster öffnet sich auf dem Reiter Gruppensuche.
2. Mit Tab zu den Schaltflächen der Gruppensuche, mit Pfeil runter zu Dungeonbrowser, falls er nicht ausgewählt ist, und Eingabe drücken.
3. Mit Tab zu Rollen und die gewünschte Rolle mit Eingabe anhaken.
4. Mit Tab zum Typ-Dropdown, Eingabe drücken und Follower-Dungeons wählen.
5. Mit Tab zur Liste. Mit Pfeil runter zum gewünschten Dungeon und Eingabe drücken; es sagt „Aktiviert“.
6. Mit Tab zu Gruppe suchen und Eingabe drücken. Schlägt die Warteschlange zu, erscheint das unten beschriebene Popup „Dungeon bereit“.

## Bereitschaftscheck

Wenn ein Gruppen- oder Schlachtzugsleiter einen Bereitschaftscheck startet, öffnet WowVision ein Fenster namens Bereitschaftscheck und gibt ihm den Fokus. Es liest:

1. den Fragetext, zum Beispiel „Thrall hat einen Bereitschaftscheck gestartet“,
2. die Schaltfläche des Spiels für „Bereit“ (Ja),
3. die Schaltfläche des Spiels für „Nicht bereit“ (Nein).

Gehe mit Tab zur gewünschten Schaltfläche und antworte mit Eingabe. Das Fenster schließt sich nach deiner Antwort oder wenn der Check endet. Die beiden Schaltflächen tragen die Texte des Spiels (im englischen Client „Ready“ und „Not Ready“).

## Popup „Dungeon bereit“

Wenn eine Dungeon-Warteschlange zuschlägt, öffnet sich das Popup „Dungeon bereit“ (Dungeon Ready) des Spiels in WowVision unter dem Titel des Spiels. Es liest der Reihe nach:

1. deine Rolle, zum Beispiel „Deine Rolle: Tank“,
2. den Fortschrittstext, wie viele Mitglieder angenommen haben, wo das Spiel ihn zeigt,
3. Informationen zur Instanz, wo das Spiel sie zeigt,
4. die Schaltfläche Dungeon betreten (Enter Dungeon) und
5. die Schaltfläche Warteschlange verlassen (Leave Queue).

Mit Tab wechselst du zwischen den Schaltflächen, mit Eingabe drückst du eine.

## Rollenabfrage und Rollenüberprüfung

Die beiden Rollen-Popups, die Rollenabfrage (Role Poll) des Gruppenleiters und die Rollenüberprüfung (Role Check) der Dungeon-Warteschlange, werden gleich gelesen. Der Titel ist der Text des Spiels. Dann:

1. Rollen: eine Liste der Rollen-Kontrollkästchen, die das Spiel zeigt, aus Tank, Heiler und Schadensausteiler. Eingabe schaltet eine um; jede sagt „Aktiviert“ oder „Nicht aktiviert“.
2. Annehmen (Accept), Ablehnen (Decline) und eine Schließen-Schaltfläche, jeweils eine eigene Station (eine Schaltfläche, die das Spiel ausblendet, steht nicht in der Liste).

Beispiel: Ein Leiter startet eine Rollenabfrage. Du hörst den Titel des Popups. Mit Pfeil runter zu Heiler, Eingabe drücken (es sagt „Aktiviert“), dann mit Tab zu Annehmen und Eingabe drücken.

## Eine Gruppeneinladung im Kampf annehmen

Lädt dich jemand in eine Gruppe ein, zeigt das Spiel ein Einladungs-Popup, das du wie jedes andere Popup beantwortest. Im Kampf kann WowVision das Popup nicht für dich öffnen, du erreichst es also erst nach dem Kampf. Diese zwei Wege nehmen die Einladung jederzeit an, auch im Kampf:

| Weg | Was er tut |
|---|---|
| /wv accept | Nimmt die Einladung an, die gerade angezeigt wird |
| Taste Gruppeneinladung annehmen (Accept Group Invitation) | Dasselbe als Taste. Sie ist unbelegt: Leg sie im Tastenbelegungs-Bildschirm (/wv bind) auf eine Taste |

Du hörst „Gruppeneinladung angenommen“. Ist keine Einladung da, hörst du „Keine Gruppeneinladung“. Zum Ablehnen beantwortest du das Popup nach dem Kampf oder lässt die Einladung verfallen.

## Eine Gruppe schnell verlassen: /pquit und /dquit

Zwei Slash-Befehle funktionieren in jedem Chat-Eingabefeld, ohne dass du ein Fenster öffnen musst:

| Befehl | Was er tut |
|---|---|
| /pquit | Verlässt sofort deine Gruppe |
| /dquit | Verlässt deine Dungeonbrowser-Gruppe, falls du in einer bist. Bist du außerdem in einem Schlachtfeld oder einer Arena, verlässt er auch dieses. Außerhalb einer Dungeonbrowser-Gruppe und außerhalb eines Schlachtfelds oder einer Arena tut er nichts |

Benutze /pquit für eine gewöhnliche Gruppe, auch in einem Dungeon, in den du zu Fuß hineingegangen bist. /dquit kann dazu führen, dass das Spiel ein Bestätigungs-Popup zeigt, das du wie jedes andere Popup beantwortest (siehe [Menüs, Optionen und Dialoge](./system.md)). Beide Befehle stehen auch unter [Slash-Befehle](../reference/commands.md).

## Was noch nicht vorgelesen wird

- Die Fenster für Dungeonbrowser, Schlachtzugsbrowser, Szenarienbrowser und vorgefertigte Gruppen in Mists.
- In Retail: die Reiter Schlachtzugsbrowser, Szenarienbrowser, Vorgefertigte Gruppen, Spieler gegen Spieler und Mythic+-Dungeons. Sie sagen jeweils „Dieser Reiter wird noch nicht unterstützt“.
- Die Bewerbungsdialoge der Gruppensuche: die Liste der Spieler, die sich auf deinen Eintrag beworben haben, und die Einladung, die du nach einer Bewerbung bei der Gruppe eines anderen erhältst.
- Die Popups der Schlachtfeld- und Arena-Warteschlangen.

Siehe auch: [Soziales](./social.md), [Spielfenster](./overview.md), [Chat](./chat.md).
