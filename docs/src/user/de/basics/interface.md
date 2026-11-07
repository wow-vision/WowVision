# Die Oberfläche bedienen

Sobald sich ein Spielfenster öffnet, zum Beispiel deine Taschen, ein Händler oder das Charakterfenster, liest WowVision es vor und lässt dich per Tastatur darin navigieren, ähnlich wie in einem Desktop-Programm. Diese Seite erklärt die Tasten, die in jedem Fenster funktionieren, was du bei den einzelnen Steuerelementen hörst und wie sich Menüs, Listen, Textfelder und das Kontextmenü verhalten.

Dieselben Navigationstasten steuern auch die eigenen Bildschirme von WowVision: das [WowVision-Menü und die Einstellungen](./menu-and-settings.md), den [Tastenbelegungs-Bildschirm](./keybindings.md), Kontextmenüs und die Dropdown-Menüs des Spiels.

## Wann WowVision deine Tasten übernimmt

WowVision übernimmt die Navigationstasten nur, solange ein Fenster geöffnet ist. Ist kein Fenster offen, tun die Pfeiltasten, Tab, Eingabe und die übrigen Tasten das, was das Spiel normalerweise damit macht (laufen, drehen, springen und so weiter).

- Spielfenster werden automatisch erkannt. Wenn eines aufgeht, beendet WowVision jede laufende Sprachausgabe und liest vor, wo du gelandet bist.
- Sind mehrere Fenster offen, wechselst du mit Strg+Tab und Strg+Umschalt+Tab zwischen ihnen (siehe [Mehrere Fenster gleichzeitig](#mehrere-fenster-gleichzeitig)).
- Esc in einem Spielfenster überlässt WowVision dem Spiel, das seine Fenster selbst mit seinen eigenen Sounds schließt. Auf den eigenen Bildschirmen von WowVision gehört Esc dagegen WowVision: Es geht eine Ebene zurück oder schließt den Bildschirm, wenn du auf der ersten Ebene bist. Dazu zählen das WowVision-Menü und alles darin, Kontextmenüs, Dropdown-Menüs des Spiels und Fenster, die es nur in WowVision gibt, etwa das Chatfenster (Umschalt+F3), das Navigationsfenster (F10), der Scanner (F9) und das Fenster Aktionsleisten (Umschalt+F4).
- /wv close schließt zwangsweise alle WowVision-Fenster. Das ist der Ausweg, falls ein Fenster einmal hängen bleibt.

Wenn sich ein Fenster öffnet, während du eine Bewegungstaste gedrückt hältst, zum Beispiel eine geteilte Quest oder ein Bereitschaftscheck, der beim Laufen aufpoppt, wartet WowVision, bis du die Tasten loslässt, die es braucht, und übernimmt sie erst dann. So läuft oder dreht sich dein Charakter nicht von allein weiter.

## Die Tasten

Alle diese Tasten kannst du im [Tastenbelegungs-Bildschirm](./keybindings.md) ändern. Die meisten sind „unverzichtbar“: Du kannst sie auf eine andere Taste legen, aber nie ganz entfernen.

| Taste | Name der Belegung | Was sie tut |
|---|---|---|
| Pfeil hoch / Pfeil runter | Hoch, Runter | Zum vorherigen oder nächsten Steuerelement gehen. |
| Pfeil links / Pfeil rechts | Links, Rechts | Seitwärts in einer Zeile gehen; bei einer Gruppe sie ein- oder ausklappen; bei einer Zahl sie kleiner oder größer machen. |
| Tab / Umschalt+Tab | Weiter, Zurück | Zum nächsten oder vorherigen Tabstopp springen (ein ganzer Abschnitt eines Fensters, etwa eine Liste oder eine Zeile mit Schaltern). |
| Pos1 / Ende | Zum Anfang springen, Zum Ende springen | Zum ersten oder letzten Steuerelement der Liste oder Zeile springen, in der du bist. |
| Eingabe | Linksklick | Das Steuerelement betätigen (bei Spielschaltern ein echter Linksklick). |
| Rücktaste | Rechtsklick | Das Steuerelement mit Rechtsklick anklicken. |
| Leertaste | Tooltip vorlesen | Den vollständigen Tooltip des Steuerelements vorlesen. Siehe [Tooltips](./tooltips.md). |
| Umschalt+Pfeil hoch, Umschalt+Pfeil runter, Umschalt+Pfeil links, Umschalt+Pfeil rechts | Tooltipzeilen | Den Tooltip Zeile für Zeile durchgehen oder seine linke oder rechte Spalte vorlesen. |
| Umschalt+F10 | Kontextmenü | Das Aktionsmenü für das fokussierte Steuerelement öffnen. |
| Strg+Tab / Strg+Umschalt+Tab | Nächstes Fenster, Vorheriges Fenster | Zwischen geöffneten Fenstern wechseln. |
| Esc | Schließen | Das Fenster schließen (Spielfenster schließt das Spiel selbst). |
| Bild auf / Bild ab | Nach oben scrollen, Nach unten scrollen | Eine lange Liste seitenweise scrollen, in den Listen, die das brauchen (siehe [Lange Listen und Scrollen](#lange-listen-und-scrollen)). |
| \\ oder Strg+D | Ziehen | Alles, was im fokussierten Platz liegt, auf den Cursor nehmen. |
| Entf oder Alt+Strg+\\ | Cursorgegenstand zerstören | Den Gegenstand oder die Zuweisung auf dem Cursor loswerden. |
| Umschalt+F1 | WowVision-Menü | Das WowVision-Menü öffnen (wie die Eingabe von /wv). |
| Strg | (keine Belegung) | Strg allein drücken, um jederzeit die aktuelle Sprachausgabe zu stoppen. |

(\\ liegt auf deutschen Tastaturen auf Alt Gr+ß; belege die Aktion bei Bedarf um.)

Eingabe und Rücktaste nehmen deine Umschalttasten mit: Umschalt+Eingabe ist ein Umschalt-Linksklick, Strg+Rücktaste ein Strg-Rechtsklick und so weiter. Das ist in WoW wichtig, weil Klicks mit Zusatztasten oft etwas anderes bewirken, zum Beispiel ein Umschalt-Klick auf einen Gegenstand, um ihn im Chat zu verlinken.

Jede Navigationstaste stoppt die laufende Sprachausgabe, bevor sie das neue Steuerelement ansagt. So kannst du schnell durch eine Liste pfeilen, ohne dass sich ein Rückstau aufbaut.

## Was du hörst

Wenn du auf einem Steuerelement landest, liest WowVision es in dieser Reihenfolge vor: seinen Namen, welche Art Steuerelement es ist, seinen aktuellen Wert oder Zustand, ob es ausgewählt oder deaktiviert ist, und zuletzt seine Position in der Liste.

| Was du hörst | Bedeutung |
|---|---|
| Schalter | Mit Eingabe betätigen. |
| Kontrollkästchen, dann Aktiviert oder Nicht aktiviert | Eingabe schaltet es um. |
| Optionsfeld, dann Aktiviert oder Nicht aktiviert | Eine Wahl aus mehreren, vor allem in Menüs. |
| Dropdown, dann die aktuelle Auswahl | Eingabe öffnet die Liste der Auswahlmöglichkeiten. |
| Zahl, dann der Wert | Eine Zahl oder ein Schieberegler. Pfeil links und Pfeil rechts ändern sie; mit Eingabe tippst du einen Wert ein. |
| Eingabefeld, dann der Text darin | Ein Textfeld. |
| ausgewählt | Der aktuelle Reiter oder die aktuelle Auswahl. |
| Deaktiviert | Das Steuerelement lässt sich gerade nicht benutzen. |
| 3 von 12 | Position unter den Geschwistern. Wird nur gesprochen, wenn es mehr als eines gibt. |
| Ausgeklappt oder Eingeklappt | Eine Gruppenüberschrift, die sich mit Pfeil rechts öffnen und mit Pfeil links schließen lässt. |

Fenster bestehen aus verschachtelten Containern, und WowVision sagt dir, wenn du einen neuen betrittst, und nennt ihn von außen nach innen: Liste für eine senkrechte Liste, Leiste für eine einzelne Zeile von Steuerelementen (etwa eine Reihe von Reitern), Feld für einen Abschnitt mit mehreren Tabstopps. Solange du dich im selben Container bewegst, wird nur das Steuerelement gelesen. Verlässt du einen Container und betrittst einen anderen, wird zuerst der Name des neuen Containers gelesen.

Beispiele:

- Eintritt in eine Liste namens Kategorien: „Kategorien, Liste, Kampf, 1 von 3“.
- Darin nach unten gehen: „Anzeige, 2 von 3“.
- Eine Einstellung: „Sprache beim Schließen des Fensters unterbrechen, Kontrollkästchen, Nicht aktiviert, 1 von 2“.
- Eine Auswahl: „Sprachstimme, Dropdown, Microsoft Zira Desktop“.
- Eine Zahl: „Sprachgeschwindigkeit, Zahl, 3“.
- Eine Leiste mit Reitern: „Reiter, Leiste, Allgemein, Schalter, ausgewählt, 1 von 4“.

### Änderungen werden angesagt, während du stehen bleibst

Solange ein Steuerelement den Fokus hat, behält WowVision es im Blick. Ändert sich sein Text, sein Aktiviert-Zustand oder seine Benutzbarkeit von selbst, zum Beispiel weil ein Schalter benutzbar wird, sobald du ein Formular ausgefüllt hast, oder weil sich ein Questtext aktualisiert, wird der neue Wert angesagt, ohne dass du etwas drückst.

## Dich bewegen

### Pfeiltasten und Zeilen

Pfeil hoch und Pfeil runter gehen in der Reihenfolge durch die Steuerelemente, in der sie erscheinen. Wo Steuerelemente nebeneinander in einer Zeile stehen, gehen Pfeil links und Pfeil rechts an der Zeile entlang. Wenn du aus einer Zeile nach oben oder unten gehst, landest du auf dem ersten Steuerelement der nächsten Zeile. Ausnahme sind Raster und Tabellen, die in Spalten angeordnet sind: Dort bleibst du in derselben Spalte.

Drückst du am Rand einer Liste eine Pfeiltaste, passiert nichts und es wird nichts gesagt. Die Pfeiltasten springen in Fenstern nicht von hinten nach vorn.

### Tabstopps

Große Fenster sind in Tabstopps unterteilt, meist eine Liste, eine Zeile mit Schaltern, ein Suchfeld und so weiter. Tab und Umschalt+Tab springen zwischen ihnen und laufen vom letzten wieder zum ersten. Jeder Tabstopp merkt sich, wo du warst: Tab bringt dich zu dem Eintrag zurück, den du verlassen hast, oder zum ausgewählten Eintrag, wenn du zum ersten Mal in einen Tabstopp kommst. Ein Fenster mit nur einem Tabstopp, etwa ein einfaches Menü, ignoriert Tab.

### Pos1 und Ende

- In einer Gruppe, die sich ein- und ausklappen lässt, springen sie zum ersten und letzten Eintrag derselben Ebene.
- In einer Zeile von Steuerelementen (einer Aktionsleiste, einer Reihe von Reitern) springen sie zum ersten und letzten Steuerelement dieser Zeile.
- Überall sonst springen sie an den Anfang oder das Ende der Liste, in der du bist.

### Gruppen, die sich öffnen und schließen

Manche Fenster zeigen aufklappbare Gruppen, zum Beispiel Kategorieüberschriften. Sie werden als „Abschnitt, Eingeklappt“ gelesen.

- Pfeil rechts auf einer eingeklappten Gruppe öffnet sie und sagt „Ausgeklappt“. Stellt sich heraus, dass nichts darin ist, schließt WowVision sie wieder und liest sie so, wie sie war.
- Pfeil rechts auf einer offenen Gruppe geht in ihren ersten Eintrag.
- Pfeil links auf einer offenen Gruppe schließt sie und sagt „Eingeklappt“.
- Pfeil links auf einem Eintrag innerhalb einer Gruppe geht zurück zur Überschrift der Gruppe.

## Steuerelemente betätigen und benutzen

### Schalter

Eingabe betätigt einen Schalter. Bei Schaltern, die zum Spiel gehören, führt WowVision einen echten Klick aus, sodass sich alles genauso verhält wie bei einem Mausnutzer. Rücktaste führt einen Rechtsklick aus. Ein Schalter, der gerade nicht benutzbar ist, sagt hinter seinem Namen „Deaktiviert“.

Auf den eigenen Bildschirmen von WowVision (dem Menü, dem Tastenbelegungs-Bildschirm) tut nur Eingabe etwas; die Rücktaste wird nicht benutzt.

### Kontrollkästchen

Eingabe schaltet das Kontrollkästchen um und sagt sofort „Aktiviert“ oder „Nicht aktiviert“.

### Dropdowns

Es gibt zwei Arten, die sich fast gleich anfühlen.

Die eigenen Auswahllisten von WowVision (wie die Einstellung Sprachstimme). Eingabe öffnet eine kurze Liste der Möglichkeiten. Du landest auf der aktuellen, die zum Beispiel als „Microsoft Zira Desktop, Schalter, ausgewählt“ gelesen wird. Mit Pfeil hoch und Pfeil runter bewegst du dich und wählst mit Eingabe aus. WowVision kehrt zur Einstellung zurück und liest den neuen Wert vor. Esc schließt die Liste, ohne etwas zu ändern.

Die Dropdown-Menüs des Spiels (Filter, das Spielermenü, das du an einem Charakter bekommst, die Zahnrad-Menüs in manchen Fenstern). Öffnet das Spiel eines, zeigt WowVision es als Liste und setzt dich auf den ersten Eintrag.

- Einträge werden als Schalter gelesen, bei anhakbaren Einträgen als Kontrollkästchen und Optionsfelder mit „Aktiviert“ oder „Nicht aktiviert“.
- Das Menü selbst wird beim Betreten als „Dropdown, Liste“ angesagt.
- Abschnittstitel innerhalb eines Menüs (der Name eines Charakters, „Interagieren“) sind keine Haltepunkte. Sie werden einmal gelesen, als Teil des ersten Eintrags, auf dem du in ihrem Abschnitt landest.
- Ein Eintrag, der ein Untermenü öffnet, wird als „Dropdown“ gelesen. Eingabe öffnet es und setzt dich auf seinen ersten Eintrag. Esc schließt das innerste Untermenü und bringt dich zum Eintrag darüber zurück; ein weiteres Esc schließt das ganze Menü.
- Ein Menüeintrag mit zusätzlichen Schaltern daneben (ein Abspielen-, Bearbeiten- oder Löschen-Schalter neben einem Eintrag) ist eine Zeile: Mit Pfeil rechts erreichst du die Schalter und mit Pfeil links kommst du zurück.
- Lange Menüs scrollen. WowVision liest jeden Eintrag vor, auch die außer Sicht, und scrollt das Menü für dich, während du nach unten gehst.
- Ein Menüeintrag kann mehrere Steuerelemente nebeneinander enthalten, etwa ein Minimum- und ein Maximum-Feld für einen Stufenbereich oder ein Kontrollkästchen und eine Schaltfläche. Ein solcher Eintrag ist eine Zeile: Pfeil rechts bewegt dich von links nach rechts durch seine Steuerelemente und Pfeil links zurück. Hat der Eintrag einen Titel, hörst du den Titel zusammen mit dem ersten Steuerelement.
- Ein Schieberegler in einem Menü bekommt unter seinem Eintrag eine eigene Zeile und wird als Zahl gelesen. Pfeil links und Pfeil rechts bewegen ihn um einen Schritt, und Eingabe lässt dich einen Wert tippen, wie unter [Zahlen und Schieberegler](#zahlen-und-schieberegler) beschrieben.
- In einem Textfeld innerhalb eines Menüs (zum Beispiel den Feldern für den Stufenbereich) setzt Eingabe den Cursor ins Feld, und nach dem Tippen verlässt dich ein weiteres Eingabe aus dem Feld zurück zum Menüeintrag. Esc tut dasselbe.
- Die Tooltip-Taste (Leertaste) liest den Tooltip des Eintrags, auf dem du stehst, wo das Spiel einen gibt. Siehe [Tooltips](./tooltips.md).
- Dropdown-Menüs nehmen auch Buchstaben an, siehe [Buchstabennavigation](#buchstabennavigation-in-menüs).

Beispiel: Im Filtermenü des Auktionshauses gehst du mit Pfeil runter zur Zeile Stufenbereich. Du hörst ihren Titel und das Feld Minimum. Drücke Eingabe und tippe „20“, drücke Eingabe, um das Feld zu verlassen, und dann Pfeil rechts, um zum Feld Maximum zu gehen.

Beispiel: Ein Rechtsklick auf ein Spielerporträt öffnet das Spielermenü. Pfeil runter bis Einladen, Eingabe. Bei einem Eintrag, der ein Untermenü öffnet, drückst du Eingabe zum Öffnen, Pfeil runter zum gewünschten Eintrag und noch einmal Eingabe.

### Zahlen und Schieberegler

Schieberegler in den Spieloptionen und Zahleneinstellungen in WowVision werden als Zahl gelesen.

- Pfeil links macht den Wert kleiner und Pfeil rechts größer, jeweils um einen Schritt (eine Einheit bei WowVision-Einstellungen, ein Reglerschritt bei den Spieloptionen). Nach jedem Tastendruck wird der neue Wert angesagt.
- Eingabe öffnet ein kleines Tippfeld, in dem du den Wert direkt eingibst (siehe [Text eingeben](#text-eingeben)). Tippe die Zahl und drücke Eingabe. Ein Wert außerhalb des erlaubten Bereichs wird auf den nächsten erlaubten Wert gesetzt. Ist das Getippte keine Zahl, ändert sich nichts.

Beispiel: Bei Sprachgeschwindigkeit, Zahl, 0 hörst du, wenn du dreimal Pfeil rechts drückst, „1“, „2“, „3“.

### Text eingeben

Es gibt zwei Arten von Textfeldern.

Die eigenen Texteinstellungen von WowVision (zum Beispiel eine eigene Nachricht für einen Alarm). Eingabe öffnet ein Tippfeld. WowVision sagt den Namen und liest vor, was darin steht; der Text ist bereits markiert, sodass alles, was du tippst, ihn ersetzt. Jede getippte Taste liest den Text bis dahin vor. Eingabe übernimmt, Esc bricht ab, und Tab übernimmt und geht zum nächsten Steuerelement weiter. Wenn du per Tab (nicht per Pfeiltasten) auf so ein Feld kommst oder wenn sich ein Bildschirm mit dem Cursor darauf öffnet, geht das Tippfeld sofort auf.

Die Textfelder des Spiels (Suchfelder, Formularfelder). Sie werden als „Eingabefeld“ gelesen, gefolgt vom Inhalt. Eingabe setzt den Cursor ins Feld. Wenn du per Tab hineinkommst oder sich ein Fenster mit dem Cursor in einem Suchfeld öffnet (so wie die Spieloptionen), kannst du sofort lostippen. Tab oder Umschalt+Tab verlässt das Feld und geht zum nächsten oder vorherigen Steuerelement. Ansonsten verhält sich das Feld genau wie im Spiel, einschließlich seines eigenen Umgangs mit Esc.

Die Suchfelder des Zauberbuchs, des Talentfensters und des Vermächtnis-Fensters (nur WoW: Forever) bieten beim Tippen Vorschläge an. Mit Pfeil hoch und Pfeil runter liest du den markierten Vorschlag und seine Position, und Eingabe wählt ihn aus oder startet deine getippte Suche, falls keiner markiert ist.

### Kopierfelder

Manche Aktionen geben dir Text zum Kopieren, zum Beispiel Charakternamen kopieren (Copy Character Name) im Spielermenü einer Chatnachricht, oder das Kopieren einer Chatnachricht. WowVision sagt „Jetzt kopieren“ und legt den Text, bereits markiert, in ein kleines Eingabefeld. Drücke Strg+C, um ihn zu kopieren, und dann Esc, um das Feld zu schließen. Der Text wird nicht noch einmal vorgelesen, weil du ihn gerade gehört hast.

### Lange Listen und Scrollen

Du musst nie selbst scrollen. Wenn du mit den Pfeiltasten auf einen Eintrag gehst, der außerhalb des Bildschirms liegt, scrollt das Fenster so, dass er sichtbar wird, damit auch der Tooltip und die Hervorhebung des Spiels funktionieren.

Bild auf und Bild ab scrollen eine Liste um eine volle Seite und setzen dich auf den nächsten Eintrag, der ins Bild gekommen ist. Sie werden nur bei den langen Listen gebraucht, deren Scrollen das Spiel schützt: die Freundes-, Ignorier- und Wer-Listen und die Gildenliste in Classic Era, The Burning Crusade und Mists of Pandaria. In diesen Listen tun Pos1 und Ende nichts, weil das Spiel einen Sprung dieser Größe nicht zulässt.

## Buchstabennavigation in Menüs

In Listen, die die Tastatur für sich haben, kannst du einen Buchstaben drücken, um zum nächsten Eintrag zu springen, dessen Name damit beginnt. Das funktioniert in:

- dem WowVision-Menü und jedem Einstellungsbildschirm darin, auch der Tastenbelegung (dort findet ein Buchstabe eine Aktion über ihren Namen),
- Kontextmenüs,
- den Dropdown-Menüs des Spiels.

In Fenstern, in denen du spielst, funktioniert es nicht, zum Beispiel im Navigationsfenster.

So verhält es sich:

- Drücke einen Buchstaben, um zum nächsten Eintrag zu gehen, der damit beginnt. Drückst du denselben Buchstaben noch einmal, geht es zum übernächsten, am Ende wieder von vorn.
- Tippe mehrere Buchstaben schnell hintereinander (innerhalb einer halben Sekunde), um nach einem längeren Anfang zu suchen: G und dann O findet „Goldhain“.
- Akzente werden ignoriert, also findet U auch „Übersicht“. Zahlen und Satzzeichen am Anfang eines Namens werden übersprungen.
- Beginnt nichts mit dem, was du getippt hast, hörst du „Keine Ergebnisse“.
- Drückst du denselben einzelnen Buchstaben noch einmal und der Eintrag, auf dem du stehst, ist der einzige, der damit beginnt, wird dieser Eintrag noch einmal gelesen.

Solange so eine Liste offen ist, bewegen die Buchstabentasten deinen Charakter nicht. Du kannst das mit der Einstellung Buchstaben-Navigation in Menüs abschalten (Menü Benutzeroberfläche, standardmäßig an). Die Tasten werden außerdem freigegeben, sobald du in den Kampf kommst oder die Liste schließt.

Beispiel: Ganz oben im WowVision-Menü drückst du einmal S, um zu Scanner zu kommen, noch einmal S für Sprache, dann Z für Zielerfassung.

## Das Kontextmenü

Umschalt+F10 öffnet ein Menü mit zusätzlichen Aktionen für das Steuerelement, auf dem du stehst. Du hörst „Menü“ und dann die Einträge.

- Bei einem echten Spielschalter bekommst du meistens Linksklick, Rechtsklick und Ziehen. Manche Fenster ergänzen, was der Klick bewirkt, zum Beispiel „Verkaufen, Rechtsklick“, sowie fensterspezifische Aktionen wie einen Gegenstand im Chat verlinken oder einen Spieler einladen.
- Bei einer Einstellung im WowVision-Menü bekommst du ein Untermenü Bereich (siehe [Einstellungen pro Charakter und accountweit](./menu-and-settings.md#einstellungen-pro-charakter-und-accountweit)).
- Hat ein Steuerelement keine Aktionen, hörst du „Menü Leer“.

Im Menü benutzt du Pfeil hoch und Pfeil runter, Eingabe, um einen Eintrag auszuführen (danach schließt sich das Menü, außer bei Einträgen, die direkt auf das Spiel wirken), und Esc, um es zu schließen. Untermenüs werden als „Dropdown“ gelesen und mit Eingabe geöffnet. Einträge mit dem Zustand Aktiviert oder Deaktiviert werden als Optionsfelder gelesen. Buchstaben springen zu Einträgen, wie oben beschrieben.

Beispiel: Du stehst auf einem Taschenplatz und willst dessen Gegenstand ziehen. Drücke Umschalt+F10, Pfeil runter bis Ziehen, Eingabe. Oder drücke einfach \\ auf dem Platz.

## Mehrere Fenster gleichzeitig

Manche Aktionen öffnen mehr als ein Fenster auf einmal, zum Beispiel öffnet der Besuch bei einem Händler den Händler und deine Taschen. Jedes offene Fenster behält seine eigene Position.

- Strg+Tab geht zum nächsten offenen Fenster, Strg+Umschalt+Tab zum vorherigen. WowVision liest den ganzen Pfad des Fensters vor, auf dem du landest, vom Fensternamen bis zum Steuerelement.
- Taschen, die sich zusammen mit einem anderen Fenster öffnen (zum Beispiel bei einem Händler), nehmen dem Fenster, das du gerade benutzt, den Fokus nicht weg, aber du erreichst sie mit Strg+Tab.
- Wenn du ein Fenster schließt, wechselt der Fokus zu einem anderen offenen Fenster, und sein Pfad wird gelesen.

## Kampf

Im Kampf schützt das Spiel seine Tasten, daher macht WowVision vollständig Platz. Deine Navigationstasten gehen zurück ans Spiel, für Fenster gibt es keine neuen Ansagen, und in deinem Namen wird nichts gelesen. Fenster, die offen sind, bleiben offen. Sobald der Kampf endet, übernimmt WowVision seine Tasten wieder, und deine Fenster und der Fokus sind so, wie du sie verlassen hast.

Alarme und deine auf Tasten gelegten Ansagen (Puffer, Zielansagen und so weiter) sind davon nicht betroffen: Sie funktionieren auch im Kampf. Siehe [Kampf](../world/combat.md).

## Cursor und Ziehen

Das Spiel bewegt Gegenstände über den Cursor. Was immer du aufnimmst, ein Taschengegenstand, ein Zauber, ein Makro, ein Reittier, hängt am Cursor, und du hörst, was es ist.

- Eingabe (Linksklick) auf einem Taschen- oder Ausrüstungsplatz nimmt dessen Gegenstand auf. Eingabe auf einem anderen Platz legt ihn dort ab oder tauscht.
- Rücktaste (Rechtsklick) benutzt den Gegenstand meistens: legt ihn an, trinkt ihn, öffnet ihn, je nach Gegenstand und Fenster.
- \\ oder Strg+D ist Ziehen: Es nimmt auf, was der fokussierte Platz enthält, nach den Regeln des Spiels (gesperrte Leisten oder nicht erlernte Zauber lehnen ab, wie bei der Maus). Ziehen gibt es auch im Kontextmenü.

Auf einer Aktionsleiste leert Ziehen den Platz sofort und legt dessen Zauber, Gegenstand oder Makro auf deinen Cursor. Dann kannst du einen anderen Platz ziehen, um es dort abzulegen, oder Entf (oder Alt+Strg+\\) drücken, um es wegzuwerfen.

- Ein Zauber, ein Makro, ein Reittier oder eine Gegenstandsreferenz, die von einer Aktionsleiste aufgenommen wurde, ist nur eine Zuweisung, daher löscht Entf sie einfach, ohne nachzufragen.
- Ein echter Gegenstand aus deinen Taschen wird von Entf erst zerstört, nachdem das Spiel dich um Bestätigung gebeten hat, damit dein Inventar sicher bleibt. Gegenstände von seltener oder besserer Qualität bekommen die stärkere Bestätigung des Spiels, bei der du im Popup des Spiels „LÖSCHEN“ eintippen musst.

Details zu den einzelnen Fenstern findest du unter [Aktionsleisten](../windows/action-bars.md) und [Taschen und Bank](../windows/bags-and-bank.md).

## Diagnosebefehle

Sie sind vor allem für Fehlerberichte gedacht. Die ersten drei sprechen ihr Ergebnis und öffnen es als Text, den du kopieren kannst.

| Befehl | Was er tut |
|---|---|
| /wv gnode | Beschreibt das fokussierte Steuerelement und den Spielframe dahinter. |
| /wv glive | Beschreibt, was WowVision am fokussierten Steuerelement beobachtet. Nützlich, wenn etwas bei Änderungen nicht angesagt wird. |
| /wv gdrop | Beschreibt das offene Dropdown-Menü und den fokussierten Menüeintrag. |
| /wv keylog | Schaltet ein Protokoll ein oder aus („WowVision key log on“ oder „off“ erscheint im Chatfenster). Solange es an ist, zeigt das Chatfenster jedes Mal eine Zeile, wenn WowVision die Navigationstasten und die Buchstabentasten übernimmt, auf sie wartet oder sie freigibt. Nutze es, wenn sich ein Charakter beim Öffnen eines Fensters von allein dreht oder läuft. Schicke die Zeilen, die mit „WowVision keys“ beginnen, aus deinem Chatprotokoll zusammen mit dem, was du gerade getan hast. (Diese Meldungen erscheinen auf Englisch.) |

Die vollständige Liste der Befehle steht in den [Slash-Befehlen](../reference/commands.md).

## Siehe auch

- [Tooltips](./tooltips.md)
- [Tastenbelegung](./keybindings.md)
- [Das WowVision-Menü und die Einstellungen](./menu-and-settings.md)
- [Controller](../controller.md)
