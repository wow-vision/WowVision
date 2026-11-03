# Soziales: Freunde, Gilde, Gemeinschaften und Kanäle

Diese Seite behandelt die Fenster, in denen du mit anderen Spielern zu tun hast: die Freundesliste, die Ignorierliste und die Wer-Liste, Battle.net-Freunde, den Schlachtzug-Reiter, die Gildenfenster, das Fenster Chatkanäle, die Gildeneinladung und die Spielermenüs, die sich von Namen überall im Spiel aus öffnen. Wie du Chatnachrichten liest und sendest, steht unter [Chat](chat.md).

Alle diese Fenster öffnen sich so, wie ein sehender Spieler sie öffnet: mit den eigenen Tasten und Schaltflächen des Spiels. WowVision bemerkt, wenn das Spiel das Fenster öffnet, und liest es vor. Du bewegst dich mit den üblichen WowVision-Tasten (siehe [Die Oberfläche bedienen](../basics/interface.md)): Tab und Umschalt+Tab zwischen den Bereichen, Pfeil hoch, Pfeil runter, Pfeil links und Pfeil rechts innerhalb eines Bereichs, Eingabe für einen Linksklick, Rücktaste für einen Rechtsklick, Leertaste, um einen Tooltip zu lesen, Umschalt+F10 für das Kontextmenü des fokussierten Steuerelements und Esc zum Schließen.

## Was es in welcher Spielversion gibt

| Fenster | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Freundesfenster: Freundesliste, Ignorierliste, Wer-Liste | Ja | Ja | Ja | Nein (siehe Kontakte-Fenster) | Nein (siehe Kontakte-Fenster) |
| Kontakte-Fenster: Battle.net-Leiste, Freunde, Anfragen, letzte Verbündete, Schnellbeitritt, Schlachtzug | Nein | Nein | Nein | Ja, wo das Spiel es benutzt | Ja |
| Gildenreiter des Freundesfensters (klassisches Gildenfenster) | Ja | Ja | Nein: Mists hat ein eigenes Gildenfenster, das noch nicht vorgelesen wird | Nein | Nein |
| Fenster Gilde und Communitys | Nein | Nein | Nein | Ja | Ja |
| Gildenverwaltung | klassische Version | klassische Version | Nein | Ja | Ja |
| Fenster Chatkanäle | Nein | Nein | Nein | Ja | Ja |
| Fenster der Gildeneinladung | Popup | Popup | Fenster, wenn der Client es hat, sonst Popup | Ja | Ja |
| Schlachtzug-Reiter | noch nicht vorgelesen | noch nicht vorgelesen | noch nicht vorgelesen | Ja | Ja |

Ist das Addon Sku geladen, überlässt WowVision die Fenster für Freunde, Gilde, Gemeinschaften und Kontakte Sku und liest sie nicht vor (siehe [WowVision zusammen mit Sku verwenden](../getting-started/installation.md#wowvision-zusammen-mit-sku-verwenden)). Das Chatfenster und das Fenster Chatkanäle sind davon nicht betroffen.

## Das Freundesfenster (Classic Era, TBC, Mists)

Öffne es mit der Kontakte-Taste des Spiels (standardmäßig O) oder mit der Schaltfläche Freunde im Spielmenü.

Das Fenster wird in diesen Teilen gelesen, in dieser Reihenfolge, die du mit Tab erreichst:

1. Die Seite selbst: die Freundesliste, die Ignorierliste, die Wer-Liste oder die Gildenseite, je nach Reiter.
2. Seitensteuerung (genannt Steuerung): die Schaltflächen unter der Seite.
3. Auf dem Reiter Freunde eine Leiste mit Unterreitern (Freunde und Ignorieren), wo das Spiel sie hat.
4. Die Leiste der Hauptreiter am Ende (Freunde, Wer, Gilde und Schlachtzug; in älteren Versionen auch Ignorieren). Der ausgewählte Reiter sagt „ausgewählt“. Eingabe wechselt den Reiter.

Der Reiter Schlachtzug wird noch nicht vorgelesen: Er sagt „Dieser Reiter wird noch nicht unterstützt“.

### Freundesliste

Die Liste enthält deine Freunde in der Reihenfolge, die das Spiel benutzt: zuerst Battle.net-Freundschaftsanfragen (unter einer Überschrift Freundschaftsanfragen), dann Freunde, die online sind (erst Charakterfreunde, dann Battle.net-Freunde), dann die, die offline sind. Pfeil hoch und Pfeil runter bewegen dich durch die Liste, Bild auf und Bild ab scrollen sie. Pos1 und Ende funktionieren in dieser Liste nicht (ebenso wenig in der Ignorierliste, der Wer-Liste oder der Gildenliste dieses Fensters).

Jeder Freund wird in einem Zug angesagt:

- Ein Charakterfreund: der Name und, wenn online, „Stufe 60 Magier“; dann der Status (Offline, Abwesend, Beschäftigt), dann die Zone und die Notiz („Notiz ...“). Hast du den Freund ausgewählt, kommt „ausgewählt“ hinzu.
- Ein Battle.net-Freund: der Accountname, der Charakter, den er spielt, und, wenn er nicht in WoW ist, das Spiel, in dem er ist; dann der Status (Freunde, die offline sind, sagen, wann sie zuletzt online waren), die Zone, die Notiz und seine Statusnachricht.

Tasten bei einem Freund:

- Eingabe wählt den Freund aus (ein Linksklick).
- Rücktaste öffnet das Freundesmenü des Spiels: flüstern, in die Gruppe einladen, eine Notiz setzen, Freund entfernen und so weiter. Siehe [Spielermenüs und Dropdown-Menüs](#spielermenüs-und-dropdown-menüs).
- Umschalt+F10 listet dieselben beiden Klicks auf.

Der Bereich Steuerung nach der Liste enthält:

- Nachricht senden (Send Message): den ausgewählten Freund anflüstern.
- Freund hinzufügen (Add Friend): öffnet den Dialog des Spiels zum Hinzufügen eines Freundes, in dem du einen Charakternamen oder BattleTag tippst (siehe [Popups](system.md)).
- Status: ein Dropdown für deinen eigenen Status (verfügbar, abwesend, beschäftigt).

Freundschaftsanfragen: Die Überschrift Freundschaftsanfragen (N) klappt die Anfragen ein, wenn du Eingabe drückst. Jede Anfrage sagt „Freundschaftsanfrage“ und den Namen des Absenders. Hat eine Anfrage den Fokus, erreichst du mit Tab Annehmen (Accept), und mit Tab noch einmal Ablehnen (Decline), ein Dropdown mit Ablehnen, Blockieren und Melden. Beide drücken die eigenen Schaltflächen des Spiels.

Beispiel: einen Freund anflüstern.

1. Drücke O, um das Freundesfenster zu öffnen. Du landest auf der Freundesliste.
2. Benutze Pfeil hoch und Pfeil runter, bis du den Namen des Freundes hörst.
3. Drücke Rücktaste für das Freundesmenü und wähle Anflüstern (Whisper). Das Chat-Eingabefeld öffnet sich, an den Freund adressiert, mit einem Ton.
4. Tippe deine Nachricht und sende sie mit Eingabe.

Oder statt der Schritte 3 und 4: Drücke Eingabe, um den Freund auszuwählen, gehe mit Tab zu Steuerung und drücke Eingabe auf Nachricht senden.

Beispiel: einen Freund in deine Gruppe einladen.

1. Öffne das Freundesfenster und wähle den Freund aus.
2. Drücke Rücktaste und wähle Einladen (Invite).

Beispiel: einem Freund eine Notiz hinzufügen.

1. Drücke Rücktaste auf dem Freund und wähle Notiz festlegen (Set Note).
2. Das Spiel öffnet ein kleines Eingabefeld (ein Popup). Tippe die Notiz und drücke Eingabe.

### Ignorierliste

Die Ignorierliste ist ein eigener Reiter oder Unterreiter. Sie hat eine Überschrift Ignorierliste mit den Spielern, die du ignorierst, und darunter, wenn du welche hast, eine Überschrift für blockierte Battle.net-Einladungen. Eingabe wählt einen Namen aus, und Rücktaste ist ein Rechtsklick.

Die Steuerung enthält die Schaltfläche des Spiels zum Ignorieren eines Spielers (sie fragt nach einem Namen oder nimmt dein Ziel) und die Schaltfläche, mit der du das Ignorieren des ausgewählten Namens beendest.

Beispiel: jemanden nicht mehr ignorieren.

1. Wechsle zur Ignorierliste (mit Tab zur Reiterleiste, dann Eingabe auf Ignorieren).
2. Gehe zum Namen und drücke Eingabe, um ihn auszuwählen.
3. Mit Tab zu Steuerung und Eingabe auf der Schaltfläche drücken, die das Ignorieren beendet.

### Die Wer-Liste

Öffne den Reiter Wer, um nach Spielern zu suchen. Er hat:

- Suchen: ein Eingabefeld. Tippe eine Suche wie einen Namen, einen Stufenbereich („60“), eine Klasse („c-Magier“), eine Zone („z-Orgrimmar“), eine Gilde („g-Name“) und drücke Eingabe, wie im Spiel.
- Liste: die Ergebnisse, eine Zeile pro Ergebnis: „Name, Stufe 60 Magier, Volk, Zone, Gilde“. Eingabe wählt ein Ergebnis aus, und Rücktaste öffnet sein Spielermenü.
- Steuerung: die Summe („12 Spieler“), die Suchschaltfläche, Freund hinzufügen, In Gruppe einladen (Group Invite) und ein Dropdown Spalte, das wählt, welche zusätzliche Spalte das Spiel zeigt (Zone, Gilde oder Volk).

Wie die Freundesliste scrollt auch diese Liste mit Bild auf und Bild ab; Pos1 und Ende funktionieren darin nicht.

Beispiel: Spieler in einer Zone finden und einen einladen.

1. Öffne das Freundesfenster und wechsle zum Reiter Wer.
2. Tippe bei Suchen „z-Wald von Elwynn 10-20“ und drücke Eingabe.
3. Mit Tab zur Liste und zu einem Namen gehen. Drücke Eingabe, um ihn auszuwählen.
4. Mit Tab zu Steuerung und Eingabe auf In Gruppe einladen drücken.

Die Wer-Liste gibt es in Classic Era, TBC und Mists. In Retail hat das Kontakte-Fenster keinen Wer-Reiter; eine Wer-Suche (von einem Chatnamen aus mit Umschalt+Eingabe oder mit dem Befehl /who) zeigt ihre Antwort so, wie es das Spiel tut. In WoW: Forever ist der Wer-Reiter Teil des Fensters der Gruppensuche (siehe [Gruppensuche](./group-finder.md#who-reiter-wow-forever)).

### Der Gildenreiter des Freundesfensters

In Classic Era und TBC ist der Gildenreiter des Freundesfensters das Gildenfenster. Mists hat ein eigenes Gildenfenster, das WowVision noch nicht vorliest. Es wird unter [Das Gildenfenster (Classic Era, TBC)](#das-gildenfenster-classic-era-tbc) beschrieben.

## Das Kontakte-Fenster (Retail, WoW: Forever)

Wo das Spiel das Kontakte-Fenster (Social) benutzt (WoW: Forever tut das und schaltet die ältere Freundesliste ab), öffnet die Kontakte-Taste des Spiels (standardmäßig O) es anstelle des Freundesfensters. Retail benutzt dasselbe Fenster.

Das Fenster wird von oben nach unten gelesen:

1. Battle.net, eine Zeile mit: deinem BattleTag, BattleTag kopieren (legt ihn in die Zwischenablage), einer Hinweisschaltfläche, wenn Battle.net ausgefallen ist (Eingabe öffnet ein kleines Hinweisfenster, das seine Überschrift und seinen Text liest), Status (ein Dropdown, zusammen mit deinem aktuellen Status gelesen) und einem Dropdown Menü (Rundnachricht, Ignorierliste und mehr).
2. Die Seite des ausgewählten Reiters.
3. Reiter, eine Zeile: Freunde, Letzte Verbündete, Schnellbeitritt, Freundschaftsanfragen, Freund werben und Schlachtzug. Ein Reiter sagt „ausgewählt“, wenn er der angezeigte ist, und „Deaktiviert“ zusammen mit seinem Grund, wenn er nicht benutzt werden kann. Ein Reiter kann auch eine Anzahl ansagen (zum Beispiel die Zahl der Schnellbeitritt-Gruppen).

Die Seite „Freund werben“ (Recruit a Friend) wird noch nicht vorgelesen: Sie sagt „Dieser Reiter wird noch nicht unterstützt“.

### Listenseiten

Freunde, Letzte Verbündete, Schnellbeitritt und Freundschaftsanfragen teilen sich ein Layout:

- Suchen und Filter: ein Eingabefeld für die Suche und ein Filter-Dropdown, in einem Bereich.
- Eine Hinweiszeile, wo es eine gibt („Wird geladen“, Battle.net nicht verfügbar).
- Bei Freundschaftsanfragen eine einmalige Warnung zu Real-ID-Anfragen mit einer Schaltfläche zum Fortfahren.
- Die Liste, in Gruppen unter einklappbaren Überschriften wie „Freunde (3/10)“. Eingabe auf einer Überschrift klappt sie ein oder aus; sie sagt Eingeklappt oder Ausgeklappt.
- Eine Aktionsschaltfläche: Freund hinzufügen oder Beitreten (Join).

Eine Karte sagt den Namen, Favorit wo zutreffend, den Status (online, abwesend, beschäftigt, offline, im Spiel und so weiter), dann was die Karte zeigt (Charakter, Stufe, Klasse, wo, zuletzt gesehen) und „ausgewählt“, wenn es die ausgewählte Karte ist. Ein Schnellbeitritt-Eintrag liest die Namen der Freunde in der Gruppe, dann wofür sie in der Warteschlange stehen, und „Deaktiviert“, wenn du nicht beitreten kannst.

Auf einer Karte:

- Eingabe wählt sie aus (ein Linksklick).
- Rücktaste öffnet das Menü des Spiels dafür.
- Umschalt+F10 öffnet das Kontextmenü, das die eigenen Schaltflächen der Karte als Einträge auflistet: Einladen (Freunde, Letzte Verbündete), Herbeirufen (Freund werben), Annehmen und Ablehnen (Freundschaftsanfragen; Ablehnen öffnet ein Menü), dann den Links- und den Rechtsklick.

Beispiel: einen Freund aus dem Kontakte-Fenster in deine Gruppe einladen.

1. Drücke O und stelle sicher, dass der Reiter Freunde ausgewählt ist (prüfe die Reiterzeile mit Tab).
2. Gehe durch die Liste zum Freund. Wenn du willst, tippe zuerst bei Suchen den Namen.
3. Drücke Umschalt+F10 und wähle Einladen.

Beispiel: eine Freundschaftsanfrage annehmen.

1. Öffne das Kontakte-Fenster, gehe mit Tab zur Reiterzeile und drücke Eingabe auf Freundschaftsanfragen.
2. Gehe zur Anfrage, drücke Umschalt+F10 und wähle Annehmen.

Beispiel: einen Freund anflüstern.

1. Öffne den Reiter Freunde und gehe zum Freund.
2. Drücke Rücktaste für das Menü des Spiels und wähle Anflüstern; das Chat-Eingabefeld öffnet sich mit einem Ton. Tippe und drücke Eingabe.

### Das Fenster „Freund hinzufügen“

Freund hinzufügen öffnet ein eigenes Fenster. Beim ersten Mal kommt zuerst eine Informationsseite (mit einer Schaltfläche Okay). Dann: ein Eingabefeld „Charakternamen oder BattleTag eingeben“, danach eine Fehler- oder Informationszeile, Anfrage senden und Abbrechen, und danach die Erklärungen, was jede Art von Namen bewirkt.

### Der Reiter „Schlachtzug“

Wenn du in einem Schlachtzug bist: die Rollenanzahlen („Tank 2, Heiler 3, Schaden 5“), dann jede Gruppe („Gruppe 1“ und so weiter) mit ihren Mitgliedern. Ein Mitglied wird gelesen als „Name, Stufe 80 Krieger, Schlachtzugsleiter, Main-Tank, Offline oder Tot, Zone“. Eingabe erfasst das Mitglied als Ziel, und Rücktaste öffnet das Spielermenü; Umschalt+F10 listet beides auf. Das Verschieben von Mitgliedern zwischen Gruppen ist Ziehen und Ablegen und wird nicht vorgelesen.

Bist du nicht in einem Schlachtzug, erscheint statt der Gruppen die Beschreibung des Spiels. Der Bereich Steuerung enthält das Kontrollkästchen Alle sind Assistenten (Everyone is Assistant), In Schlachtzug umwandeln (Convert to Raid; nur wenn du nicht in einem Schlachtzug bist) und Schlachtzuginfo (Raid Info).

### Schlachtzuginfo

Schlachtzuginfo öffnet ein Fenster mit den gespeicherten Instanzen und Weltbossen: „Name, Schwierigkeitsgrad, Zeit bis zum Zurücksetzen“, dazu „Verlängert“, wo du die Sperre verlängert hast. Eine abgelaufene Sperre liest den Text „abgelaufen“ des Spiels statt einer Zeit. Eingabe wählt einen Eintrag aus, Verlängern (Extend) verlängert die ausgewählte Sperre, Schließen schließt das Fenster.

### Ignorierliste (Kontakte-Fenster)

Die Ignorierliste öffnet sich über das Battle.net-Menü. Sie listet ignorierte Spieler und blockierte Einladungen unter ihren Überschriften auf; Eingabe wählt einen Namen aus. Zwei Schaltflächen darunter: eine, um einen Spieler zu ignorieren (dein Ziel oder ein getippter Name), und eine, um den ausgewählten Namen zu entfernen.

### Rundnachricht

Wähle den Eintrag für die Rundnachricht (Broadcast) im Battle.net-Menü, um die Nachricht festzulegen, die deine Battle.net-Freunde unter deinem Namen sehen. Das Fenster hat das Eingabefeld, Aktualisieren (Update) und Abbrechen.

## Das Gildenfenster (Classic Era, TBC)

Öffne den Gildenreiter mit der Gildentaste des Spiels (standardmäßig J) oder indem du im Freundesfenster den Reiter Gilde wählst. Der Gildenreiter wird von oben nach unten gelesen:

1. Gildenname: eine Überschrift mit der Mitgliederzahl, der Zahl der Mitglieder online und der Nachricht des Tages. Darfst du die Nachricht des Tages ändern, ist sie eine Schaltfläche: Eingabe öffnet das Eingabefeld des Spiels.
2. Mitglieder: die Mitgliederliste. Ein Mitglied wird gelesen als „Name, Stufe 60 Magier, Zone, Rang, Notiz“. Ein Mitglied, das offline ist, sagt statt der Zone, wann es zuletzt online war. Abwesende und beschäftigte Mitglieder sagen das ebenfalls.
3. Steuerung: das Kontrollkästchen Gildensuche (Looking for Guild), wo es zutrifft, eine Schaltfläche, die zwischen den beiden Spaltensätzen umschaltet (Spielerstatus (Player Status): Stufe, Klasse, Zone; Gildenstatus (Guild Status): Rang, Notiz, online), die Sortierköpfe (Sortieren) und die Schaltflächen Mitglied hinzufügen (Add Member), Gildenverwaltung, Gildeninformation (Guild Information) und, wo angezeigt, die Schaltfläche, um einen inaktiven Gildenmeister zu ersetzen.

Bei einem Mitglied: Eingabe wählt es aus und öffnet die Mitgliederkarte; Rücktaste öffnet das Mitgliedermenü des Spiels (flüstern, einladen, befördern, degradieren, entfernen).

### Die Mitgliederkarte

Die Mitgliederkarte öffnet sich als eigenes Fenster neben dem Freundesfenster. Sie liest: den Namen, „Stufe 60 Magier“, Zone, Rang, zuletzt online oder online, die Schaltflächen Befördern (Promote) und Degradieren (Demote) (für Offiziere, die sie benutzen dürfen), die persönliche Notiz und, für Offiziere, die Offiziersnotiz, dann Entfernen, In Gruppe einladen und Schließen.

Eine Notiz, die du bearbeiten darfst, ist eine Schaltfläche: Eingabe darauf öffnet das Notizfeld des Spiels, in dem du tippst und Eingabe drückst.

Beispiel: ein Gildenmitglied in deine Gruppe einladen.

1. Öffne den Gildenreiter mit J und gehe in der Mitgliederliste zum Mitglied.
2. Drücke Eingabe. Die Mitgliederkarte öffnet sich.
3. Gehe zu In Gruppe einladen und drücke Eingabe. Schließe die Karte mit Esc.

(Oder drücke Rücktaste auf dem Mitglied und wähle im Menü Einladen.)

Beispiel: eine Offiziersnotiz festlegen.

1. Wähle das Mitglied aus (Eingabe), damit sich die Mitgliederkarte öffnet.
2. Mit Tab oder den Pfeiltasten zur Schaltfläche Offiziersnotiz. Sie sagt den aktuellen Text der Notiz.
3. Drücke Eingabe, tippe die neue Notiz in das Feld des Spiels und speichere mit Eingabe.

Beispiel: die Nachricht des Tages festlegen.

1. Gehe im Gildenreiter zur Nachricht des Tages, die eine Schaltfläche ist, wenn du das Recht hast, sie zu ändern.
2. Drücke Eingabe, tippe die Nachricht und drücke Eingabe.

### Gildeninformation, Ereignisprotokoll und Gildenverwaltung

- Gildeninformation: ein Fenster mit dem Text der Gildeninformation. Darfst du ihn bearbeiten, ist es ein Eingabefeld, gefolgt von Speichern, Abbrechen, Ereignisprotokoll (Event Log) und Schließen.
- Gildenereignisprotokoll: eine Zeile pro Ereignis (wer eingeladen hat, beigetreten ist, befördert wurde und so weiter), das neueste zuerst, dann Schließen.
- Gildenverwaltung (Gildenmeister und Offiziere): das Rang-Dropdown, das Feld für den Rangnamen, Rang hinzufügen (Add Rank) und Rang entfernen (Remove Rank); die Kontrollkästchen für die Rechte des ausgewählten Rangs und das Gold, das er pro Tag abheben darf; und, wo die Gildenbank eingeschaltet ist, eine Zeile mit Bankreitern mit, für den ausgewählten Reiter, den Kontrollkästchen Ansehen (View), Einzahlen (Deposit) und Text aktualisieren (Update Text) und der Anzahl der Abhebungen pro Tag; Annehmen (Accept) und Abbrechen am Ende.

## Das Fenster Gilde und Communitys (Retail, WoW: Forever)

Öffne es mit der Gildentaste des Spiels (standardmäßig J). Es hat diese Teile, die du mit Tab in dieser Reihenfolge erreichst:

1. Ein Banner, wenn die Gilde umbenannt werden muss (nur für Gildenleiter).
2. Gilde und Communitys, die Liste links: deine Gilde, deine Gemeinschaften, Einladungen und die Sucheinträge (Gildensuche, Gemeinschaft finden, einer Gemeinschaft beitreten). Eingabe wählt einen aus. Rücktaste öffnet das Menü des Spiels dafür. Jeder Eintrag sagt seinen Namen, „Gilde“ bei einer Gilde, Favorit, „ausgewählt“ und „Deaktiviert“ bei Suchen, die du nicht benutzen kannst. Ist das Fenster minimiert, ist diese Liste stattdessen ein Dropdown.
3. Die Seite, mit den Reitern gewählt.
4. Steuerung, die Schaltflächen am unteren Rand, die von der Seite und deinem Rang abhängen: Einladen, Community-Einstellungen (Community Settings), Gildenrekrutierung (Guild Recruitment), Gildenverwaltung, Protokoll ansehen (View Log) und Maximieren oder Minimieren.
5. Reiter, eine Zeile: Chat, Mitgliederliste (Roster), Gildenvorteile (Guild Benefits), Gildeninfo (Guild Info) und, bei Gemeinschaften, Bevorzugter Spielstil (Preferred Play). Der ausgewählte Reiter sagt „ausgewählt“. Der Chat-Reiter kann gesperrt sein (Chat stummgeschaltet oder ausgeschaltet) und sagt dann „Deaktiviert“ und den Grund.

Eine Einladung in eine Gemeinschaft erscheint als eigene Seite: der Einladungstext, Name, Art, Mitgliederzahl, Anführer und Beschreibung der Gemeinschaft, dann Annehmen und Ablehnen.

Die Suchen (Gildensuche, Gemeinschaft finden), die Listen der Bewerber und die Einstellungen für den Bevorzugten Spielstil werden noch nicht vorgelesen; sie sagen „Dieser Reiter wird noch nicht unterstützt“.

### Chat-Seite

- Das Kanal-Dropdown, Zum Chat hinzufügen (Add to Chat) und die Kalenderschaltfläche.
- Nachrichten: die letzten fünfzig Nachrichten, die älteste zuerst. Der Fokus beginnt bei der neuesten. Jede Nachricht wird mit auf ihren Text reduzierten Links gelesen. Zu Ungelesenem springen (Jump to Unread) folgt, wenn es welches gibt.
- Chat: das eigene Chat-Eingabefeld des Spiels. Tippe und sende mit Eingabe.
- Die kurze Mitgliederliste: die Mitgliederzahl, Offline anzeigen (Show Offline) und die Mitglieder. Ein Mitglied wird gelesen als „Name, Anführer oder Moderator, Abwesend oder Beschäftigt oder Offline“.

### Seite „Mitgliederliste“

- Das Spalten-Dropdown (eine Gilde und eine Gemeinschaft haben jeweils ihr eigenes), um eine zusätzliche Spalte zu wählen, etwa Erfolgspunkte oder Dungeonwertung.
- Die Mitgliederzahl und das Kontrollkästchen Offline anzeigen.
- Sortieren nach: eine Zeile mit Spaltenkopf-Schaltflächen. Eingabe sortiert nach dieser Spalte.
- Mitglieder: jedes Mitglied, zum Beispiel „Name, Stufe 80 Jäger, Zone, Rang, Notiz“. Ein Mitglied, das offline ist, sagt, wann es zuletzt online war. Eine ausstehende Einladung liest den Namen des Eingeladenen, und Abbrechen steht in ihrem Kontextmenü.

Eingabe auf einem Gildenmitglied öffnet die Mitgliederkarte. Rücktaste öffnet das Spielermenü. Bei einem Mitglied einer Gemeinschaft tut Eingabe, was ein Linksklick im Spiel für diese Zeile tut (zum Beispiel die Rezepte eines Berufs unter einer Berufsüberschrift anzeigen).

### Seite „Gildeninfo“

- Herausforderungen (Challenges), wo die Gilde welche hat, jeweils mit ihrem Fortschritt.
- Nachricht des Tages mit ihrem Text und einer Bearbeiten-Schaltfläche. Eingabe auf der Bearbeiten-Schaltfläche öffnet ein kleines Fenster mit einem Eingabefeld, Annehmen und Schließen. Im Nachrichtenfeld bestätigt Eingabe; im Feld für die Gildeninformation beginnt Eingabe eine neue Zeile.
- Gildeninformation: der Text und seine Bearbeiten-Schaltfläche.
- Die Neuigkeiten: eine Schaltfläche Filter festlegen (Set Filters) (ein Fenster mit einem Kontrollkästchen pro Art von Neuigkeit und Schließen), die Schaltfläche zum Ersetzen eines inaktiven Gildenmeisters, wo das Spiel sie anbietet, und die Neuigkeitenliste. Daten sind Überschriften; jede Zeile liest sich etwa wie „Xynayya hat den Erfolg ... errungen“. Gibt es keine Neuigkeiten, hörst du den Text „keine Neuigkeiten“ des Spiels.

### Seite „Gildenvorteile“

Die Vorteile, die Belohnungen („Gegenstandsname, Kosten, Voraussetzung“) und die Erfolgspunkte und der Ruf der Gilde.

### Die Mitgliederkarte

Die Karte eines Gildenmitglieds ist ein eigenes Fenster, dasselbe wie in Classic: Name, Stufe und Klasse, Zone, Rang, zuletzt online, die Notizen, Entfernen, In Gruppe einladen und Schließen. Wo du befördern oder degradieren darfst, ist der Rang ein Dropdown. Eine Notiz, die du bearbeiten darfst, ist eine Schaltfläche; Eingabe öffnet das Notizfeld des Spiels.

### Das Ereignisprotokoll

Protokoll ansehen (unter der Steuerung) öffnet das Gildenereignisprotokoll: eine Zeile pro Ereignis („A hat B eingeladen“, „A hat B zum Offizier befördert“ und so weiter) mit ihrer Zeit, das neueste zuerst, dann Schließen.

Beispiele für dieses Fenster:

Ein Gildenmitglied in deine Gruppe einladen.

1. Drücke J. Mit Tab zu Reiter und mit Eingabe Mitgliederliste wählen.
2. Mit Tab zurück zu den Mitgliedern und zum Spieler gehen.
3. Drücke Rücktaste und wähle Einladen. Oder drücke Eingabe für die Mitgliederkarte und benutze In Gruppe einladen.

Eine Offiziersnotiz festlegen.

1. Öffne die Seite Mitgliederliste und drücke Eingabe auf dem Mitglied.
2. Gehe in der Mitgliederkarte zu Offiziersnotiz, drücke Eingabe, tippe und drücke Eingabe.

Lesen, was die Gilde gesagt hat.

1. Öffne die Seite Chat. Der Fokus landet auf der neuesten Nachricht; Pfeil hoch geht zurück.
2. Drücke Tab, um zu Chat zu gelangen und eine Antwort zu tippen.

## Gildenverwaltung (Retail, WoW: Forever)

Die Schaltfläche Gildenverwaltung (Gildenmeister und Offiziere) öffnet ein Fenster zur Rangverwaltung. Ein Dropdown oben wählt die Seite:

- Gildenränge (Guild Ranks): eine Zeile pro Rang, jeweils mit dem Feld für den Rangnamen (das Spiel speichert einen neuen Namen, wenn du das Feld verlässt) und Schaltflächen, um den Rang nach oben oder unten zu verschieben und ihn zu löschen; Pfeil rechts erreicht die Schaltflächen. Darunter Neuer Rang (New Rank) unterhalb der Liste.
- Rangrechte (Rank Permissions): das Rang-Dropdown („Rang auswählen“ und der angezeigte Rang), das Kontrollkästchen für Offizier mit seiner Erklärung, die Kontrollkästchen der Rechte, die Gildenbankrechte mit dem Gold, das der Rang pro Tag abheben darf (liest „Deaktiviert“, wenn ausgegraut), und das Kontrollkästchen für den Authenticator (kann beim letzten Rang und bei einem benutzten Rang ausgegraut sein).
- Gildenbank-Reiterrechte (Guild Bank Tab Permissions): das Rang-Dropdown, dann jeder Gildenbank-Reiter mit seinen Kontrollkästchen Ansehen und Einzahlen und seinen Gegenstandsabhebungen pro Tag und, bei einem Reiter, den du noch kaufen kannst, seinen Kosten und der Schaltfläche zum Kaufen.
- Discord: die Discord-Link-Seite, gelesen als ihre Texte und Steuerelemente.

Schließen schließt das Fenster.

Beispiel: die Rechte eines Rangs festlegen.

1. Drücke im Gildenfenster Gildenverwaltung.
2. Wähle im Seiten-Dropdown Rangrechte.
3. Wähle den Rang mit dem Rang-Dropdown.
4. Gehe durch die Kontrollkästchen und drücke bei jedem Eingabe, um es ein- oder auszuschalten.

## Das Fenster Chatkanäle (Retail, WoW: Forever)

Das Fenster der Kanäle des Spiels. Öffne es mit der Kanalschaltfläche des Chatfensters, der Taste des Spiels zum Umschalten des Chat-Reiters oder mit Umschalt+Eingabe auf einem Kanalnamen im Chatfenster.

Es hat:

- Kanäle: die Kanalliste unter Überschriften (Gruppe, global, benutzerdefiniert, Gemeinschaften). Eingabe auf einer Überschrift klappt sie ein oder aus; sie sagt Eingeklappt oder Ausgeklappt. Eingabe auf einem Kanal wählt ihn aus; der Kanal sagt „ausgewählt“ und „Deaktiviert“, wenn du ihn verlassen hast. Rücktaste öffnet das Kanalmenü (verlassen, betreten, ein Passwort festlegen, einladen).
- Mitglieder: die Mitglieder des ausgewählten Kanals, nach ihm benannt („Mitglieder, Handel“). Jedes wird gelesen als „Name, Besitzer oder Moderator, Offline“. Rücktaste öffnet das Spielermenü.
- Die Schaltflächen Hinzufügen (Add) und Einstellungen (Sprach-Chat).

Hinzufügen öffnet das Feld für einen neuen Kanal: ein Eingabefeld für den Namen und eines für das Passwort (es öffnet sich im Namensfeld, du kannst also sofort tippen), ein Kontrollkästchen für den Sprach-Chat, wo das Spiel es hat, OK und Abbrechen. Eingabe in einem der beiden Felder erstellt den Kanal.

Die Teile für den Sprach-Chat (die Headset-Schaltfläche bei einem Kanal, Stummschalten und Ertauben bei Mitgliedern) werden noch nicht vorgelesen.

Beispiel: einem benutzerdefinierten Kanal beitreten.

1. Öffne das Fenster Chatkanäle und gehe mit Tab zu Hinzufügen. Drücke Eingabe.
2. Tippe den Kanalnamen und, falls er eines hat, das Passwort und drücke Eingabe.

## Die Gildeneinladung

Wenn dich ein Spieler in eine Gilde einlädt, öffnet WowVision das Einladungsfenster (Retail, WoW: Forever und überall, wo das Spiel es benutzt): den Einladenden, den Einladungstext, den Namen der Gilde, ihre Erfolgspunkte, wo das Spiel sie zeigt, und eine Warnung zum Gildenruf, wenn du welchen verlieren würdest. Mit Tab erreichst du Gilde beitreten (Join Guild) und Ablehnen.

Das Schließen der Einladung lehnt sie ab, wie im Spiel: Esc lehnt ab. Das Spiel lehnt auch von selbst nach einer Minute ab.

In Classic Era und TBC ist die Einladung ein gewöhnliches Popup und wird wie jedes andere Popup gelesen (siehe [Popups](system.md)).

## Spielermenüs und Dropdown-Menüs

Fast jeder Name, den du im Spiel auswählen kannst, hat ein Menü, und WowVision liest sie alle auf dieselbe Weise vor. Sie erscheinen, wenn du Rücktaste (Rechtsklick) auf einem Spieler in der Freundesliste, der Wer-Liste, der Mitgliederliste, der Schlachtzugsliste, bei Kanalmitgliedern oder in einer Chatnachricht drückst, wenn du Alt+T für dein Ziel drückst und von einem Reiter oder einer Karte aus.

Ein Menü öffnet sich als eigener Bereich. Jede Menüebene ist eine eigene Station: zuerst das Hauptmenü, und ein Untermenü ist eine weitere Ebene, die sich öffnet, wenn du Eingabe auf einer Zeile mit Untermenü drückst (sie sagt „Dropdown“). Esc schließt die Ebene, in der du bist. In einem Menü, in das du tippen kannst, springt das Drücken eines Buchstabens zur nächsten Zeile, die mit ihm beginnt.

Die eigenen Überschriften des Menüs (der Name des Spielers, Interagieren, Weitere Optionen) werden einmal gelesen, wenn du in ihren Bereich wechselst, und du landest nicht auf ihnen. Jede Zeile sagt ihren Text und, wo es zutrifft, Aktiviert oder Deaktiviert, und Deaktiviert, wenn du sie nicht benutzen kannst. Eine Zeile mit kleinen Schaltflächen (wie Abspielen oder Löschen) ist eine Zeile: Pfeil rechts erreicht sie.

Das Menü eines Spielers hat die üblichen Zeilen des Spiels, zum Beispiel Anflüstern, Einladen, Freund hinzufügen, Ignorieren, Untersuchen, Ziel, Fokus, Melden, Notiz festlegen und Charaktername kopieren. Welche Zeilen du siehst, hängt vom Spieler und von der Spielversion ab.

Charaktername kopieren (Copy Character Name): In einem Menü, das du aus dem Chatfenster geöffnet hast, öffnet WowVision für diese Zeile ein eigenes Feld (dasselbe wie Zeile kopieren im Chat): Es sagt „Jetzt kopieren“, der Name ist markiert, Strg+C kopiert und Esc schließt. In anderen Menüs ist die Zeile die des Spiels und kopiert den Namen direkt in die Zwischenablage.

### Das Zielmenü (Alt+T)

Alt+T öffnet das Menü deines aktuellen Ziels, das, das ein Rechtsklick auf das Porträt des Ziels öffnet: anflüstern, einladen und der Rest. Hast du dich selbst als Ziel, bietet es Alle Instanzen zurücksetzen (Reset All Instances), Beute und Dungeon-Schwierigkeit an. Ohne Ziel öffnet sich nichts. Die Taste ist standardmäßig belegt und lässt sich im Fenster für die Tastenbelegung ändern. Sie wird zusammen mit den anderen Zielerfassungstasten unter [Zielerfassung](../world/targeting.md) beschrieben.

Beispiel: den Spieler einladen, den du als Ziel hast.

1. Erfasse den Spieler als Ziel.
2. Drücke Alt+T, gehe zu Einladen und drücke Eingabe.

Die allgemeinen Regeln für Dropdowns und Kontextmenüs stehen unter [Die Oberfläche bedienen](../basics/interface.md).

## Tasten im Überblick

| Taste | Wo | Was sie tut |
|---|---|---|
| Eingabe | Listen | Auswählen (Linksklick). |
| Rücktaste | Listen | Rechtsklick: das Menü des Spiels öffnen. |
| Umschalt+F10 | Jedes Steuerelement | Kontextmenü des Steuerelements (Klicks, Schaltflächen der Karte). |
| Leertaste | Jedes Steuerelement | Den Tooltip lesen. |
| Tab, Umschalt+Tab | Fenster | Nächster und vorheriger Bereich. |
| Alt+T | Überall | Menü deines Ziels. |
| Esc | Fenster oder Menü | Schließen. Lehnt eine Gildeneinladung ab. |

Die eigenen Tasten des Spiels öffnen die Fenster (Kontakte-Taste, Gildentaste und so weiter); WowVision fügt dafür keine eigenen Tasten hinzu.
