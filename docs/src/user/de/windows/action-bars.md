# Aktionsleisten

Das Fenster Aktionsleisten zeigt jede Aktionsleiste, die das Spiel gerade anzeigt, eine nach der anderen. So hörst du, was auf jedem Platz liegt, kannst einen Platz benutzen und deine Zauber, Gegenstände und Makros umordnen. Mit Umschalt+F4 öffnest du es.

## Das Fenster öffnen

| Taste | Was sie tut |
|-------|-------------|
| Umschalt+F4 | Öffnet das Fenster Aktionsleisten. Anders als die meisten Fenster braucht es kein zuvor geöffnetes Spielfenster. Im Fenster für die Tastenbelegung heißt die Aktion Aktionsleisten (Action Bars), und du kannst sie dort umbelegen. |
| Esc | Schließt das Fenster. |

Mit eingeschalteter Gamepad-Oberfläche (Retail und WoW: Forever) lässt sich dasselbe Fenster auch über die Shortcut-Ebene des Controllers öffnen: Halte beide Schultertasten und drücke den linken Stick. Siehe [Controller](../controller.md).

Im Kampf kannst du das Fenster nicht bedienen. WowVision gibt seine Tasten im Kampf an das Spiel zurück, damit deine eigenen Tastenbelegungen weiter funktionieren, und nimmt sie wieder, sobald der Kampf vorbei ist. Benutze im Kampf deine normalen Belegungen für Fähigkeiten.

## So ist das Fenster aufgebaut

Das ganze Fenster ist ein einziger Tabstopp. Jede Leiste ist darin eine beschriftete Zeile:

- Pfeil links und Pfeil rechts gehen die Plätze der aktuellen Leiste entlang.
- Pfeil hoch und Pfeil runter wechseln zur vorherigen oder nächsten Leiste. Du landest auf dem ersten Platz dieser Leiste.
- Pos1 und Ende springen zum ersten oder letzten Platz der aktuellen Leiste.

Tab tut hier nichts, weil das ganze Fenster nur ein einziger Stopp ist.

Wenn du zu einer anderen Leiste wechselst, sagt WowVision zuerst den Namen der Leiste und dann den Platz. Jeder Platz endet mit seiner Position in der Leiste, zum Beispiel „3 von 12“.

Es werden nur Leisten aufgeführt, die gerade existieren. Das Fenster liest sie in dieser Reihenfolge:

| Leiste, wie angesagt | Was es ist | Wann sie aufgeführt wird |
|----------------------|------------|--------------------------|
| Aktionsleiste (Action Bar) | Die Hauptleiste mit zwölf Plätzen. Sie folgt dem, was das Spiel dort zeigt, auch einer anderen Seite oder einer Haltung oder Gestalt, die die Leiste austauscht. | Immer. |
| Begleiterleiste (Pet Bar) | Die Befehle und Fähigkeiten deines Begleiters (Angriff, Folgen, Bleiben und so weiter). | Solange du einen Begleiter mit Leiste hast. |
| Haltungsleiste (Stance Bar) | Kriegerhaltungen, Druiden- und Schurkengestalten, Paladinauren und Ähnliches. | Solange das Spiel für deine Klasse eine Haltungsleiste zeigt. |
| Untere linke Leiste (Bottom Left Bar) | Die erste Zusatzleiste. | Nur, wenn sie in den Spieloptionen eingeschaltet ist. |
| Untere rechte Leiste (Bottom Right Bar) | Die zweite Zusatzleiste. | Nur, wenn sie in den Spieloptionen eingeschaltet ist. |
| Rechte Leiste (Right Bar) | Die dritte Zusatzleiste. | Nur, wenn sie in den Spieloptionen eingeschaltet ist. |
| Rechte Leiste 2 (Right Bar 2) | Die vierte Zusatzleiste. | Nur, wenn sie in den Spieloptionen eingeschaltet ist. |

Die vier Zusatzleisten sind im Spiel standardmäßig aus. Schalte sie in den Spieloptionen unter Aktionsleisten ein (das Optionsfenster beschreibt [Menüs, Optionen und Dialoge](./system.md)). Eine Leiste, die du ausschaltest, verschwindet aus dem Fenster.

In WoW: Forever kommen bei eingeschalteter Gamepad-Oberfläche vier weitere Leisten dazu. Siehe [Gamepad-Aktionsleisten](#gamepad-aktionsleisten-wow-forever).

Nicht gelesen werden: die Leisten, die Retail über die vier oben genannten hinaus hinzugefügt hat (Aktionsleisten 5, 6 und 7), die Zusatzaktionstaste, die Zonenfähigkeitstaste und die Fahrzeug- und Besitzergreifungsleisten. Benutze dafür deine normalen Tastenbelegungen des Spiels.

## Was ein Platz sagt

### Hauptleiste und Zusatzleisten

Ein Platz liest den Namen dessen, was darauf liegt, gefolgt von der Taste, die das Spiel auf dieser Schaltfläche anzeigt, in Klammern:

- „Feuerball (1)“
- „Heiltrank (s-2)“
- „Leer“

Der Tastentext ist genau das, was das Spiel auf die Schaltfläche zeichnet. Umschalt, Strg und Alt erscheinen daher in der Kurzform des Spiels, etwa `s-`, `c-` und `a-`. Ein leerer Platz sagt nur „Leer“.

Die Beschriftung aktualisiert sich, während du auf dem Platz stehst. Wenn du einen Zauber von einem Platz aufnimmst, liest er sofort „Leer“. Zauber, Gegenstände, Makros, Reittiere, Haustiere, Ausrüstungssets und Untermenüs (Flyouts) werden alle mit ihrem Namen gelesen. Selten liest ein Platz „Unknown“, gefolgt von technischen Angaben wie einer ID und einem Typ. Das ist etwas, das das Addon noch nicht benennen kann. Ein Platz, dessen Schaltfläche das Spiel abgeschaltet hat, sagt nach seinem Namen „Deaktiviert“.

### Begleiterleiste

Jeder Platz liest den Namen des Befehls oder der Fähigkeit. Wenn die Fähigkeit automatisch gewirkt werden kann, sagt er zusätzlich Automatischer Zauber oder Kein automatischer Zauber:

- „Angriff“
- „Knurren Automatischer Zauber“
- „Leer“

### Haltungsleiste

Jeder Platz liest den Namen der Haltung, Gestalt oder Aura, zum Beispiel „Verteidigungshaltung“. Auf diesen Plätzen gibt es keinen Tastentext. Es werden nur die Haltungen aufgeführt, die du gelernt hast.

### Tooltips

Drücke auf einem beliebigen Platz die Leertaste, um seinen Tooltip zu lesen, also den Zauber- oder Gegenstands-Tooltip, den das Spiel unter der Maus zeigen würde. Siehe [Tooltips](../basics/tooltips.md).

## Einen Platz benutzen

| Taste | Was sie tut |
|-------|-------------|
| Eingabe | Linksklick: Benutzt den Platz, wirkt also den Zauber, benutzt den Gegenstand oder führt das Makro aus. |
| Rücktaste | Rechtsklick auf den Platz, genau wie mit der Maus. |
| \\ oder Strg+D (Ziehen) | Nimmt auf, was auf dem Platz liegt, und legt es auf deinen Cursor. Der Platz wird leer. |
| Entf oder Alt+Strg+\\ (Cursorgegenstand zerstören) | Nimmt den aufgenommenen Zauber, das Makro oder die Verknüpfung endgültig weg. Siehe unten. |
| Umschalt+F10 | Öffnet das Kontextmenü des Platzes: Linksklick, Rechtsklick und Ziehen. |

(\\ liegt auf deutschen Tastaturen auf Alt Gr+ß; belege die Aktion bei Bedarf um.)

Fähigkeiten benutzt du schneller mit deinen normalen Tastenbelegungen des Spiels. Das Fenster dient dazu, deine Leisten zu prüfen und umzuordnen.

## Verschieben und entfernen

WoW arbeitet mit einem Cursor: Du nimmst etwas auf und legst es dann irgendwo ab. WowVision macht dasselbe mit Tasten.

Beispiel: Feuerball vom ersten auf den fünften Platz der Hauptleiste verschieben.

1. Drücke Umschalt+F4.
2. Gehe mit Pfeil links und Pfeil rechts zum ersten Platz. Er sagt „Feuerball (1)“.
3. Drücke \\ (oder Strg+D). Feuerball liegt jetzt auf deinem Cursor, und der Platz liest „Leer“.
4. Gehe zum fünften Platz.
5. Drücke noch einmal \\. Feuerball landet im fünften Platz. Lag dort schon etwas, wandert es auf deinen Cursor, und du kannst es auf dieselbe Weise woanders ablegen.

Beispiel: einen Zauber endgültig von deiner Leiste nehmen.

1. Fokussiere den Platz und drücke \\. Der Zauber liegt auf deinem Cursor.
2. Drücke Entf. Der Cursor wird geleert, und der Zauber ist von der Leiste verschwunden. Es gibt keine Rückfrage, denn ein Zauber auf einer Aktionsleiste ist nur eine Verknüpfung, und nichts geht verloren. Du kannst ihn jederzeit wieder aus dem Zauberbuch ziehen.

Dasselbe funktioniert bei Makros, Reittieren und Ausrüstungssets. Auch ein Gegenstand auf einer Aktionsleiste ist nur eine Verknüpfung: Entf leert nur den Cursor, und der Gegenstand bleibt in deinen Taschen.

Benutze die Taste für Ziehen (\\ oder Strg+D), wenn du etwas von einer Aktionsleiste aufnimmst, und nicht den Eintrag Ziehen im Kontextmenü des Platzes. Die Taste sagt WowVision, dass das, was auf deinem Cursor liegt, nur eine Leistenverknüpfung ist. Entf bietet dann nie an, den echten Gegenstand zu zerstören. Nimmst du eine Gegenstandsverknüpfung stattdessen über das Kontextmenü auf, behandelt WowVision sie als echten Taschengegenstand, und Entf öffnet dann die Zerstörungsabfrage für diesen Gegenstand. Das spielt nur bei Gegenständen auf einer Leiste eine Rolle. Zauber, Makros und Ähnliches werden immer nur geleert.

Entf tut nichts, wenn dein Cursor leer ist. Das ist Absicht: Du kannst nichts zerstören, indem du es bloß fokussierst. Die Taste Entf funktioniert überall im Spiel, nicht nur in diesem Fenster, solange etwas auf deinem Cursor liegt.

Für Gegenstände aus deinen Taschen siehe [Taschen und Bank](./bags-and-bank.md). Dort steht auch, wie du einen echten Gegenstand zerstörst.

Um einen Zauber aus dem Zauberbuch auf eine Leiste zu legen, nimmst du ihn im Zauberbuch auf (siehe [Zauber und Talente](./spells-and-talents.md)), öffnest dann dieses Fenster mit Umschalt+F4 und legst ihn auf einem Platz ab. Der Cursor bleibt zwischen den Fenstern bei dir. Wie du ein Makro ablegst, steht unter [Menüs, Optionen und Dialoge](./system.md#makros).

## „Aktionsleisten sperren“ wird für dich ausgeschaltet

Das Spiel hat eine Einstellung namens Aktionsleisten sperren (Lock Action Bars). Ist sie an, passiert beim Wegziehen einer Aktion von einer Leiste nichts, es sei denn, du hältst zusätzlich die Aufnahmetaste des Spiels, und nichts sagt dir, warum. Dadurch wirkt das Ziehen kaputt.

Beim ersten Login jedes Charakters mit WowVision wird die Einstellung ausgeschaltet, und WowVision gibt diese Meldung im Chat aus:

„WowVision hat deine Aktionsleisten entsperrt, damit das Ziehen funktioniert. Du kannst sie in den Spieloptionen unter Aktionsleisten wieder sperren.“

Das passiert einmal pro Charakter. Wenn du die Leisten in den Spieloptionen wieder sperrst, bleiben sie gesperrt, und WowVision ändert sie nicht noch einmal. Lehnt das Spiel die Änderung ab (zum Beispiel im Kampf), versucht WowVision es beim nächsten Login wieder. Hörst du beim Login nichts, waren die Leisten entweder schon entsperrt, oder dieser Charakter wurde schon früher behandelt.

## Gamepad-Aktionsleisten (WoW: Forever)

(Nur WoW: Forever.)

Ist die Gamepad-Oberfläche des Spiels an, liegen deine Zauber auf den Gamepad-Aktionsleisten statt auf den Tastaturleisten. Diese Leisten haben je acht Plätze. Das Fenster führt vier zusätzliche Leisten in dieser Reihenfolge auf:

| Leiste, wie angesagt | Welche Controllertasten sie benutzen |
|----------------------|--------------------------------------|
| Gamepad-Leiste (Gamepad Bar) | Kein Trigger gehalten. |
| Leiste linker Trigger (Left Trigger Bar) | Der linke Trigger gehalten. |
| Leiste rechter Trigger (Right Trigger Bar) | Der rechte Trigger gehalten. |
| Leiste beide Trigger (Both Triggers Bar) | Beide Trigger gehalten. |

Auf den Namen der Leiste folgt die Seite, auf der das Spiel gerade ist, zum Beispiel „Gamepad-Leiste, Seite 1“. Die Seiten werden wie bei sehenden Spielern mit Steuerkreuz links und rechts in der Shortcut-Ebene des Controllers umgeblättert (beide Schultertasten gehalten).

Jeder Platz liest sich wie ein normaler Platz, gefolgt von der Controllertaste, die ihn auslöst:

- „Frostblitz, A“
- „Leer, X“

Die acht Plätze sind der Reihe nach: Steuerkreuz links, Steuerkreuz hoch, Steuerkreuz rechts, Steuerkreuz runter und dann die vier Aktionstasten (die linke, die obere, die rechte und die untere). Die Tastennamen folgen der Benennung deines Controllers. Diese Plätze haben keinen Tastentext. Die Leisten erscheinen nur, solange die Option Gamepad-Oberfläche aktivieren (Enable Gamepad UI) des Spiels an ist. Die Controllertasten von WowVision selbst findest du unter [Controller](../controller.md).

## Einstellungen und Alarme

Das Fenster Aktionsleisten hat keine Einstellungen, die du ändern kannst, und keine Alarme. Der einzige gespeicherte Wert ist eine versteckte Notiz, dass die Leisten dieses Charakters schon entsperrt wurden. Wie jedes Fenster hat es einen Schalter Aktiviert im WowVision-Menü, unter Fenster, dann Leisten. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

## Fehlerbehebung

- Eine Leiste fehlt. Das Spiel zeigt sie nicht an. Schalte sie in den Spieloptionen unter Aktionsleisten ein.
- Ziehen tut nichts. Die Leisten sind gesperrt, wahrscheinlich, weil du sie nach dem ersten Login selbst gesperrt hast. Entsperre sie in den Spieloptionen unter Aktionsleisten.
- Das Fenster tut im Kampf nichts. WowVision gibt seine Tasten im Kampf an das Spiel zurück. Beende zuerst den Kampf.
- Eingabe wirkt den Zauber, statt ihn aufzunehmen. Das ist richtig so. Eingabe ist ein Klick. Zum Aufnehmen benutzt du \\ oder Strg+D.
