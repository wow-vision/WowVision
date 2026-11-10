# Das WowVision-Menü und die Einstellungen

Im WowVision-Menü konfigurierst du das Addon: Sprache, Alarme, Navigation, Puffer, Monitore, Fenster und mehr. Es funktioniert wie jedes andere WowVision-Fenster, daher gilt alles aus [Die Oberfläche bedienen](./interface.md). Diese Seite erklärt, wie das Menü aufgebaut ist, wie jede Art von Einstellung bearbeitet wird und wie Einstellungen pro Charakter oder für den ganzen Account gespeichert werden.

## Das Menü öffnen und schließen

| Wie | Was passiert |
|---|---|
| Umschalt+F1 | Öffnet das Menü (die Belegung WowVision-Menü). |
| /wv | Öffnet das Menü. Auch /wv gefolgt von etwas, das WowVision nicht kennt, öffnet es. |
| Pfeil rechts | Öffnet die nächste Ebene, wenn der Eintrag eine hat. |
| Pfeil links | Geht eine Ebene zurück. Auf der ersten Ebene passiert nichts, das Menü bleibt offen. |
| Esc | Geht eine Ebene zurück. Auf der ersten Ebene schließt es das Menü. |
| /wv close | Schließt zwangsweise alle WowVision-Fenster. |

Wenn sich das Menü öffnet, stoppt die Sprache, und du hörst seinen Namen und den ersten Eintrag, zum Beispiel „WowVision, Liste, Benutzeroberfläche, Schalter, 1 von 13“. Die genaue Zahl der Einträge hängt von deiner Spielversion ab.

Im Kampf macht WowVision Platz, öffne das Menü also vor oder nach einem Kampf, siehe [Kampf](./interface.md#kampf).

Den Bildschirm eines Moduls mit eigenen Einstellungen erreichst du direkt mit /wv gsettings, gefolgt vom Kurznamen, zum Beispiel /wv gsettings speech. Die Namen sind die Modulnamen in Kleinbuchstaben, mit Punkten für Untermodule. Sie bleiben englisch, auch wenn das Menü deutsch spricht:

| Befehl | Öffnet |
|---|---|
| /wv gsettings speech | Sprache |
| /wv gsettings ui | Benutzeroberfläche |
| /wv gsettings ui.tooltip.quality | Benutzeroberfläche, Tooltip, Qualität |
| /wv gsettings ui.combat | Benutzeroberfläche, Kampf |
| /wv gsettings navigation.compass | Navigation, Kompass |
| /wv gsettings navigation.maps | Navigation, Beacon und Routen |
| /wv gsettings chat | Chat |
| /wv gsettings targeting | Zielerfassung |
| /wv gsettings errors | Fehler |
| /wv gsettings navigation.falling | Navigation, Fallerkennung |

Passt der Name zu keinem Modul mit eigenen Einstellungen, zum Beispiel ui.tooltip oder eines der Spielfenster, gibt WowVision im Chat „No settings found for“ und den Namen aus (auf Englisch). Der Befehl ist eine Abkürzung für Tester; über das Menü kommst du immer zu denselben Bildschirmen.

## Wie das Menü aufgebaut ist

Das Menü ist ein Baum. Der erste Bildschirm listet die Module in alphabetischer Reihenfolge auf. Eingabe auf einem Modul öffnet seinen Bildschirm, der seinerseits Untermodule auflisten kann. Jeder Bildschirm ist eine Liste; Esc geht wieder nach oben. Die alphabetische Reihenfolge richtet sich nach den Namen, die du hörst, also nach den deutschen.

Der Bildschirm eines Moduls enthält von oben nach unten:

1. Ein Kontrollkästchen Aktiviert. Jedes Modul außer Sprache und Benutzeroberfläche hat eines. Schaltest du ein Modul aus, enden seine Funktionen sofort, einschließlich seiner Tasten, Alarme und Fenster, und die Wahl wird für diesen Charakter gespeichert.
2. Seine Untermodule als Schalter, in alphabetischer Reihenfolge.
3. Besondere Einträge, die manche Module ergänzen. Zum Beispiel hat das Modul Benutzeroberfläche einen Schalter Tastenbelegung, das Modul Puffer seine Liste von Puffergruppen und das Modul Fehler einen Schalter Filter pro Fehler.
4. Die eigenen Einstellungen des Moduls.
5. Die Alarme des Moduls, jeweils als Schalter. Siehe [Alarme](./alerts.md).

Beispiel: Wenn du Chat öffnest, hörst du „Chat, Liste, Aktiviert, Kontrollkästchen, Aktiviert“. Drücke Pfeil runter, um durch die Alarme der Chat-Reiter und die übrigen Einträge zu gehen.

Weil das Menü eine Liste ist, die die Tastatur für sich hat, kannst du Buchstaben drücken, um zu springen: Z für Zielerfassung, S (zweimal) für Sprache. Siehe [Buchstabennavigation](./interface.md#buchstabennavigation-in-menüs).

### Was auf der ersten Ebene steht

Die Einträge stehen in der alphabetischen Reihenfolge, in der du sie auf einem deutschen Client hörst.

| Eintrag | Spielversionen | Was er enthält | Mehr |
|---|---|---|---|
| Auktionspreise (Auction Prices) | The Burning Crusade | Preisverlauf und zusätzliche Preiszeilen in Gegenstands-Tooltips. | [Tooltips](./tooltips.md#preise-in-tooltips) |
| Benutzeroberfläche (UI) | Alle | Fensterverhalten, Belegungen, Kampf, Cursor, Tooltips. | unten |
| Chat | Alle | Ein Alarm pro Chat-Reiter, Flüster-Reiter, Sounds des Chat-Eingabefelds. | [Chat](../windows/chat.md) |
| Fehler (Errors) | Alle | Wie Fehler- und Infomeldungen des Spiels gesprochen werden. | [Kampf](../world/combat.md) |
| Fenster (Windows) | Alle | Ein Eintrag pro Spielfenster, das WowVision zugänglich macht. | [Spielfenster](../windows/overview.md) |
| Minikarten-Scanner (Minimap Scanner) | Alle | Minikarten-Scan und die Ansagen beim Laufen. | [Minikarte](../world/minimap.md) |
| Monitor (Monitors) | Alle | Aura-, Abklingzeit- und andere Monitore. | [Monitore](../information/monitors.md) |
| Navigation | Alle | Atlas, Beacon und Routen, Kompass, Fallerkennung, Folgen, Neigungssperre, Besuchte Wegpunkte, Wanderkennung und mehr. | [Bewegung und Orientierung](../world/movement.md), [Navigation und Routen](../world/navigation.md) |
| Puffer (Buffers) | Alle | Deine Puffergruppen und Puffer und die Einstellung Elementrichtung umkehren. | [Puffer](../information/buffers.md) |
| Quests | Alle | Werkzeuge für das Questlog, Alarme für Questgebiete. | [Quests](../world/quests.md) |
| Scanner | Alle | Der Scanner (F9): Scan-Radius, Einträge pro Kategorie und Scanner als Baum, um zwischen Baum und Menü zu wählen. | [Scanner](../world/scanner.md) |
| Sprache (Speech) | Alle | Stimme, Geschwindigkeit, Lautstärke und Sprachverhalten. | [Sprache und Ton](./speech.md) |
| Zielerfassung (Targeting) | Alle | Zielansagen, weiche Zielerfassung, Fokusziele. | [Zielerfassung](../world/targeting.md) |

Unter Navigation gibt es in WoW: Forever zusätzlich WowNav-Routen, siehe [WowNav (WoW: Forever)](../world/wownav.md).

### Das Modul Benutzeroberfläche

Drücke im Hauptmenü B, dann Eingabe. Es enthält:

| Eintrag | Standard | Was er tut |
|---|---|---|
| Kampf | | Gegneranzahl und die Alarme für Kampfbeginn und Kampfende, siehe [Kampf](../world/combat.md). |
| Cursor | | Nur ein Kontrollkästchen Aktiviert. Schaltest du es aus, verschwindet die Taste Cursorgegenstand zerstören. |
| Tooltip, dann Qualität | | Welche Farben der Gegenstandsqualität gesprochen werden, siehe [Tooltips](./tooltips.md#gegenstandsqualität-in-namen). |
| Tastenbelegung | | Der Tastenbelegungs-Bildschirm, siehe [Tastenbelegung](./keybindings.md). |
| Sprache beim Schließen des Fensters unterbrechen | Aus | Die Sprache abschneiden, sobald sich ein Fenster schließt. |
| Töne beim Öffnen und Schließen von WowVision-Menüs | An | Einen kurzen Ton spielen, wenn sich ein WowVision-Fenster öffnet, und einen anderen, wenn es sich schließt: das WowVision-Menü, der Scanner, das Navigationsfenster, die Aktionsleisten und der Chat. Die Fenster des Spiels machen ihre eigenen Töne und bekommen keine von WowVision. |
| Buchstaben-Navigation in Menüs | An | Buchstabentasten zu Einträgen in Menüs springen lassen. Schalte sie aus, wenn deine Buchstabentasten auch bei geöffnetem Menü weiter funktionieren sollen. |
| WowVision-Soundkanal | Soundeffekte | Der Soundkanal des Spiels, auf dem jeder WowVision-Sound spielt: Alarmsounds, Stimmenpakete, das Beacon und die Beispiele in den Sound-Browsern. Die Einträge heißen wie die Lautstärkeregler in den Soundoptionen des Spiels, dieser Regler ist dann die Lautstärke von WowVision. Ein Kanal, den du sonst kaum nutzt, gibt WowVision eine eigene Lautstärke. Retail und WoW: Forever bieten zusätzlich Gameplay-Soundeffekte. |

### Das Modul Fenster

Jedes Spielfenster, das WowVision behandelt, hat hier einen eigenen Eintrag, zum Beispiel Spielmenü, Händler, Post und Beute, jeweils mit einem Kontrollkästchen Aktiviert und manchmal eigenen Einstellungen. Schaltest du das Modul eines Fensters aus, ignoriert WowVision dieses Fenster völlig, sodass das Spielfenster bleibt, wie das Spiel es gemacht hat. Das ist nützlich, wenn du für ein bestimmtes Fenster die Behandlung durch ein anderes Addon bevorzugst.

## Wie jede Art von Einstellung bearbeitet wird

| Art | Was du hörst | Wie du sie änderst |
|---|---|---|
| Kontrollkästchen | „Aktiviert, Kontrollkästchen, Aktiviert“ | Eingabe schaltet es um und sagt den neuen Zustand. |
| Zahl | „Verzögerung (Millisekunden), Zahl, 200“ | Pfeil links und Pfeil rechts ändern sie um eins und sagen den neuen Wert. Eingabe öffnet ein Tippfeld: Tippe eine Zahl und drücke Eingabe. Werte außerhalb des erlaubten Bereichs rasten auf den nächsten erlaubten Wert ein. |
| Auswahl | „Gegner zählen, Dropdown, Die dich oder deine Gruppe angreifen“ | Eingabe öffnet die Liste der Möglichkeiten. Du landest auf der aktuellen. Eingabe auf einer anderen wählt sie aus und kehrt zurück; Esc schließt die Liste unverändert. |
| Text | „Nachricht, Eingabefeld, hallo“ | Eingabe öffnet ein Tippfeld mit markiertem Text. Tippe, dann Eingabe zum Übernehmen oder Esc zum Abbrechen. Kommst du per Tab hin, öffnet sich das Feld sofort. |
| Dauer | „(Name), Zahl, 1 Minute 5 Sekunden“ | Wie eine Zahl. Pfeil links und Pfeil rechts gehen jeweils eine Sekunde; beim Tippen gibst du Sekunden ein. |
| Stimme | „Stimme, Dropdown, Microsoft Zira Desktop“ | Eine Auswahl unter deinen installierten TTS-Stimmen. |
| Stimmenpaket | „Stimmenpaket, Dropdown, Matthew“ | Eine Auswahl unter den aufgenommenen Stimmenpaketen. Siehe [Sprache und Ton](./speech.md#aufgenommene-stimmenpakete). |
| Sound- oder Beacon-Auswahl | „Sound, Schalter, chat.mp3“ | Siehe [Einen Sound auswählen](#einen-sound-auswählen). |
| Zauber | „Zauber, Schalter, Sternensog (78674)“ | Siehe [Einen Zauber auswählen](#einen-zauber-auswählen). |
| Vorlage | „Vorlage, Schalter, Standard“ | Siehe [Eine Vorlage bearbeiten](#eine-vorlage-bearbeiten). |
| Alarm | der Name des Alarms, als Schalter | Öffnet den Bildschirm des Alarms, siehe [Alarme](./alerts.md). |
| Gruppe von Einstellungen | ein Schalter | Öffnet einen Bildschirm mit den darin enthaltenen Einstellungen, zum Beispiel Festes Ziel unter Zielerfassung. |
| Liste von Dingen | „Monitor (3), Schalter“ | Siehe [Listen mit Einträgen](#listen-mit-einträgen). |
| Alles andere | „Bezeichnung, Wert“ als einfacher Text | Nur lesbar. |

### Einen Sound auswählen

Die Einstellung Sound der Soundausgabe eines Alarms und die Einstellung Beacon-Ton eines Beacons öffnen einen Browser für Audiodateien.

1. Drücke Eingabe auf Sound. Du landest in einer Liste von Ordnern.
2. Gehe in Sound, dann in WowVision für die Sounds, die mit WowVision geliefert werden, oder in LibSharedMedia für die Sounds, die andere Addons registriert haben. In WowVision heißen die Ordner alerts, errors, notes und falling.
3. Wenn du auf eine Datei gehst, wird sie abgespielt, damit du vor der Auswahl hineinhören kannst. Der Wechsel zur nächsten Datei stoppt den vorherigen Sound.
4. Drücke Eingabe auf der gewünschten Datei. WowVision kehrt zur Einstellung zurück und liest den neuen Wert vor.

Esc geht einen Ordner zurück, ohne etwas auszuwählen. Oben im Browser siehst du außerdem die Ordner Voice und Beacon, die Dateien für andere Arten von Ausgaben enthalten. (Die Namen der Ordner und der Sounds werden auf Englisch angesagt.)

Beacon-Auswahlen funktionieren genauso, nur wählst du einen der Beacon-Töne (Notification, Probe (Deep), Probe (Mid), Steel Gong, Beacon 6), und beim Daraufgehen wird ein Beispiel-Beacon abgespielt.

### Einen Zauber auswählen

Monitorregeln und manche anderen Funktionen haben eine Einstellung Zauber.

1. Drücke Eingabe auf Zauber. Es öffnet sich ein Bildschirm mit Zaubername oben und einer Liste darunter.
2. Bei einem Zauber, dessen Namen oder ID du kennst, drückst du Eingabe auf Zaubername und tippst den Namen oder die Nummer. Eingabe übernimmt. Kennt das Spiel ihn nicht, hörst du „Nicht gefunden“ und kannst es noch einmal versuchen.
3. Andernfalls wählst du aus der Liste darunter, die die Zauber enthält, die WowVision bei diesem Charakter gesehen hat (von dir gewirkt oder als Auren begegnet), nach Namen sortiert, jeweils gelesen als „Name (ID)“. Eingabe wählt aus.
4. Nach der Auswahl kehrt WowVision zur Einstellung zurück und liest „Name (ID)“.

### Eine Vorlage bearbeiten

Pufferelemente benutzen Vorlagen, um zu bestimmen, wie ihr Text gesprochen wird, zum Beispiel „{percent}% ({current} [of] {maximum})“. Die Einstellung Vorlage bietet:

- Eingabe auf Vorlage öffnet eine Liste der Vorlagen, die es für diese Art Objekt gibt. Drücke Eingabe auf einer, um sie zu benutzen. Standard bedeutet die normale Formulierung.
- Benutzerdefiniert lässt dich ein eigenes Format tippen. WowVision sagt Format und öffnet das Tippfeld. Tippst du nichts und drückst Eingabe, geht es zurück zum Standard.

In deinem eigenen Format schreibst du den Namen eines Werts in geschweifte Klammern, um ihn einzufügen, zum Beispiel {percent}. Eckige Klammern fügen ein übersetztes Wort ein, zum Beispiel [of] (das auf einem deutschen Client als „von“ gelesen wird). Schrägstriche im festen Text eines Formats werden mit Leerzeichen drumherum gesprochen. Tippe {{ oder [[ für eine tatsächliche geschweifte oder eckige Klammer. Welche Werte du benutzen kannst, hängt vom Objekt ab und ist bei diesem unter [Puffer](../information/buffers.md) aufgeführt.

### Listen mit Einträgen

Puffer, Puffergruppen, Monitore und Regeln sind Listen von Dingen, die du hinzufügen und entfernen kannst. Eine Einstellung für so eine Liste wird als ihr Name und eine Anzahl gelesen, „Monitor (3)“.

1. Eingabe öffnet die Liste. Jeder vorhandene Eintrag ist ein Schalter.
2. Eingabe auf einem Eintrag öffnet seinen Editor: seine Einstellungen und unten einen Schalter Entfernen, der ihn ohne Rückfrage löscht.
3. Hinzufügen am Ende der Liste öffnet Typ auswählen. Wähle einen Typ, und der neue Eintrag wird erstellt, mit dem Namen „Neu“ und dem Typ, und sein Editor öffnet sich sofort.
4. Umschalt+F10 auf einem Eintrag gibt ihm einen Eintrag Bereich, siehe unten.

Manche Einstellungen enthalten eine einfache Liste von Werten (zum Beispiel eine Liste von Zahlen). Sie wird als „Name (Anzahl)“ gelesen und öffnet einen Bildschirm mit einer Zeile pro Wert: dem eigenen Steuerelement des Werts, gefolgt von einem Schalter Entfernen, und Hinzufügen am Ende.

## Einstellungen pro Charakter und accountweit

WowVision führt zwei Speicher für Einstellungen:

- Den Account-Speicher, den alle Charaktere deines Accounts gemeinsam nutzen.
- Den Charakter-Speicher, nur für diesen Charakter.

Die meisten Einstellungen sind zunächst accountweit, sodass die Sprachstimme oder die Alarmsounds, die du bei einem Charakter einstellst, für alle gelten. Der erste Charakter, der sich nach der Einführung des Account-Speichers einloggte, hat ihn mit seinen eigenen Einstellungen gefüllt (dieser Charakter behält auch seine Kopie); Charaktere, die sich später einloggen, benutzen einfach, was dort steht.

Welche Module aktiviert sind, gilt immer pro Charakter, egal was du wählst. Beim Filter pro Fehler des Moduls Fehler ist es umgekehrt: Ihn nutzen immer alle Charaktere des Accounts gemeinsam, sodass ein Fehler, den du bei einem Charakter stummgeschaltet hast, bei allen stumm bleibt. Die beiden Kontrollkästchen für Spielsounds des Moduls Sprache sind die eigenen Einstellungen des Spiels und werden von WowVision überhaupt nicht gespeichert.

### Den Bereich ändern

Umschalt+F10 auf einer gespeicherten Einstellung öffnet das Kontextmenü, und darin steht Bereich. Drücke Eingabe, um es zu öffnen. Es bietet zwei Optionsfelder: Global und den Namen deines Charakters. Das angehakte zeigt, wo diese Einstellung liegt.

- Mit Global folgt die Einstellung dem Account. Sie übernimmt den Wert des Accounts. Hat der Account noch keinen Wert, wird der Wert dieses Charakters zum Wert des Accounts.
- Mit dem Namen deines Charakters bekommt dieser Charakter eine eigene Kopie, die mit dem aktuellen Wert beginnt. Du kannst sie dann ändern, ohne andere Charaktere zu beeinflussen.

Beim Wechseln wird nie etwas gelöscht, du kannst es dir also gefahrlos anders überlegen.

Derselbe Eintrag Bereich erscheint auch an anderen Stellen:

- Auf dem Schalter eines Moduls im Menü schaltet er alle Einstellungen und Alarme dieses Moduls auf einmal um. Bei Puffer und Monitor verschiebt er auch alle ihre Gruppen oder Monitore.
- Auf dem Schalter eines Alarms verschiebt er diesen Alarm mit allen seinen Ausgaben.
- Auf dem Schalter Tastenbelegung im Menü Benutzeroberfläche verschiebt er alle deine Tastenbelegungen auf einmal.
- Auf einem einzelnen Eintrag in einer Liste von Puffergruppen oder Monitoren verschiebt er nur diesen Eintrag.

Sind die Einstellungen eines Moduls auf beide aufgeteilt, ist weder Global noch der Charaktername angehakt.

Beispiel: Du willst auf deinem Zweitcharakter allein eine schnellere Sprachgeschwindigkeit.

1. Umschalt+F1 öffnet das Menü, S bis Sprache, Eingabe.
2. Pfeil runter bis Sprachgeschwindigkeit, dann Umschalt+F10.
3. Pfeil runter bis Bereich, Eingabe, Pfeil runter zum Namen deines Charakters, Eingabe.
4. Das Menü schließt sich, und du bist wieder auf Sprachgeschwindigkeit. Ändere das Tempo; das deines Hauptcharakters bleibt, wie es war.

## Wann Einstellungen gespeichert werden

Das Spiel schreibt die Einstellungen von WowVision auf die Festplatte, wenn du dich ausloggst, die Oberfläche neu lädst oder das Spiel beendest, nicht in dem Moment, in dem du sie änderst. Stürzt das Spiel ab, können Änderungen der aktuellen Sitzung verloren gehen. Wenn du wichtige Einstellungen änderst, schließe mit /reload ab.

Scheinen deine Einstellungen zwischen Sitzungen zu verschwinden, gibt /wv dbcheck aus, wie die gespeicherten Einstellungen geladen wurden, was für einen Fehlerbericht nützlich ist. Siehe [Fehlerbehebung](../getting-started/troubleshooting.md).

## Zurücksetzen

Im Menü gibt es keinen Zurücksetzen-Schalter. Um eine einzelne Einstellung zurückzusetzen, stelle sie auf den Standard, der in diesem Handbuch steht (die Einstellungen sind mit ihren Standardwerten dokumentiert). Für einen kompletten Neuanfang siehe [Fehlerbehebung](../getting-started/troubleshooting.md).

## Siehe auch

- [Die Oberfläche bedienen](./interface.md)
- [Alarme](./alerts.md)
- [Sprache und Ton](./speech.md)
- [Tastenbelegung](./keybindings.md)
