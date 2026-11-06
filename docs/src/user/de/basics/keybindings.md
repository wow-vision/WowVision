# Tastenbelegung

Jede Taste, die WowVision benutzt, lässt sich ändern. Der Tastenbelegungs-Bildschirm listet jede Aktion und ihre Tasten auf und lässt dich Tasten hinzufügen, entfernen und von einer Aktion auf eine andere verschieben. Diese Seite erklärt, wie du ihn benutzt und was die Meldungen bedeuten. Die vollständige Liste der Aktionen und ihrer Standardtasten steht in der [Tastenreferenz](../reference/keybindings.md).

## Den Tastenbelegungs-Bildschirm öffnen

1. Drücke Umschalt+F1 (oder tippe /wv), um das [WowVision-Menü](./menu-and-settings.md) zu öffnen.
2. Drücke B, um zu Benutzeroberfläche zu kommen, und drücke Eingabe.
3. Drücke Pfeil runter bis Tastenbelegung und drücke Eingabe.

Du landest auf der ersten Belegung und hörst zum Beispiel „Tastenbelegung, Liste, Hoch, Leiste, Pfeil hoch, Schalter, 1 von 2“. Esc geht zurück ins Menü Benutzeroberfläche.

Schneller geht es mit /wv bind. Der Befehl öffnet denselben Bildschirm direkt als eigenes Fenster; Esc schließt es dann.

(Die Namen der Tasten, zum Beispiel „Pfeil hoch“ oder „Eingabe“, stammen vom Spiel und werden in der Sprache deines Clients angesagt.)

## Wie der Bildschirm aussieht

Jede Aktion hat eine Zeile. Eine Zeile enthält von links nach rechts:

- einen Schalter pro Taste, die die Aktion gerade hat, benannt nach der Taste („Eingabe“, „Pfeil hoch“, „Strg-Tab“),
- einen Schalter Hinzufügen,
- bei eingeschalteter Gamepad-Oberfläche des Spiels einen Schalter pro Controller-Taste und einen Schalter Controller-Taste hinzufügen (siehe [Controller-Tasten](#controller-tasten-retail-wow-forever)).

Die Zeile wird mit dem Namen der Aktion angesagt, dann „Leiste“, dann der Schalter, auf dem du landest, zum Beispiel „Linksklick, Leiste, Eingabe, Schalter, 1 von 2“. Eine Aktion, die gar keine Taste hat (und bei der keine Controller-Tasten angezeigt werden), hat in ihrer Zeile nur Hinzufügen und wird als „Liste“ statt als „Leiste“ angesagt.

| Taste | Was sie hier tut |
|---|---|
| Pfeil runter / Pfeil hoch | Zur nächsten oder vorherigen Aktion gehen. |
| Pfeil rechts / Pfeil links | An der Zeile der Tasten, Hinzufügen und so weiter entlanggehen. |
| Pos1 / Ende | Zur ersten oder letzten Aktion springen. |
| Ein Buchstabe | Zur nächsten Aktion springen, deren Name mit ihm beginnt. |
| Eingabe auf einer Taste | Entfernt diese Taste von der Aktion. |
| Eingabe auf Hinzufügen | Beginnt, eine neue Taste aufzunehmen. |
| Esc | Verlässt den Bildschirm. |

Die Aktionen stehen in der Reihenfolge, in der das Addon sie geladen hat: zuerst die Navigationstasten der Fenster, dann die anderen Module. Um eine zu finden, tippe den Anfang ihres Namens: S springt zur nächsten Aktion, die mit S beginnt, noch einmal S zur übernächsten, und S und dann schnell C findet "Scanner". Du landest auf der ersten Taste der Aktion, oder auf Hinzufügen, wenn sie keine hat. Siehe [Buchstabennavigation in Menüs](./interface.md#buchstabennavigation-in-menüs).

Eine Aktion ohne Taste zeigt nur Hinzufügen. Das sind die Aktionen, die „standardmäßig unbelegt“ sind: Es gibt sie, aber sie warten darauf, dass du ihnen eine Taste gibst, zum Beispiel Alle Monitore ein- oder ausschalten, Route zu deinem Ziel oder Entfernung ansagen.

## Eine Taste hinzufügen

1. Gehe zum Schalter Hinzufügen der Aktion und drücke Eingabe. WowVision sagt den Namen der Aktion und nimmt die Tastatur in Beschlag. Während der Aufnahme erreicht keine Taste das Spiel oder die eigenen Aktionen von WowVision.
2. Drücke die gewünschte Tastenkombination, zum Beispiel halte Alt und drücke D. Während du drückst, liest WowVision die Kombination vor, etwa „ALT-D“.
3. Lass die Haupttaste los. Die Kombination wird der Aktion hinzugefügt. Zusatztasten werden immer in der Reihenfolge Alt, Strg, Umschalt geschrieben, also „ALT-CTRL-SHIFT-K“. (Diese Aufnahme-Ansage kommt unverändert vom Addon und kann daher englische Tastenkürzel enthalten.)

Was du bei der Aufnahme wissen solltest:

- Esc bricht die Aufnahme ab. Deshalb lässt sich Esc selbst hier keiner Aktion zuweisen.
- Eine Zusatztaste allein (nur Umschalt, nur Strg) lässt sich nicht belegen. Sie zählt nur als Teil einer Kombination mit einer anderen Taste.
- Als Kombination zählen die Zusatztasten, die du gehalten hast, als die Haupttaste nach unten ging. Es ist in Ordnung, Alt einen Moment vor dem Buchstaben loszulassen.
- Nach dem Hinzufügen der Taste hörst du nichts mehr. Drücke von Hinzufügen aus Pfeil links, um den Schalter der neuen Taste zu hören.

Beispiel: Gib Entfernung ansagen die Taste Alt+D.

1. Öffne den Tastenbelegungs-Bildschirm wie oben.
2. Drücke Pfeil runter, bis du „Entfernung ansagen, Liste, Hinzufügen, Schalter“ hörst.
3. Drücke Eingabe. Du hörst „Entfernung ansagen“.
4. Halte Alt, drücke D, lass beide los. Du hörst „ALT-D“, wenn die Taste nach unten geht.
5. Drücke Pfeil links, um „Alt-D, Schalter“ zu hören. Die Taste ist gespeichert und sofort aktiv.

Eine Aktion kann mehrere Tasten haben. Ziehen zum Beispiel wird mit \\ und Strg+D geliefert. Füge so viele hinzu, wie du willst. (\\ liegt auf deutschen Tastaturen auf Alt Gr+ß; belege die Aktion bei Bedarf um.)

## Eine Taste entfernen

Drücke Eingabe auf dem Schalter einer Taste. Sie wird sofort und ohne Rückfrage entfernt, und du hörst, wo der Fokus als Nächstes landet. Um eine Taste zu ändern, füge die neue hinzu und entferne dann die alte, oder umgekehrt.

Bei den meisten Aktionen kannst du alle Tasten entfernen; die Aktion hat dann einfach keine Taste, bis du eine hinzufügst. Ausnahmen sind die unverzichtbaren Aktionen weiter unten.

## Konflikte

Zwei Aktionen können nicht dieselbe Taste teilen. Gehört die aufgenommene Taste schon einer anderen Aktion, hörst du eine dieser Meldungen:

| Was du hörst | Was es bedeutet | Was du tun solltest |
|---|---|---|
| „Diese Eingabe existiert bereits für diese Belegung.“ | Die Aktion hat diese Taste schon. | Nichts hat sich geändert. |
| „Diese Eingabe steht in Konflikt mit (Name der Aktion). Ersetzen?“, gefolgt von Yes und No (diese beiden Schalter werden auf Englisch angesagt) | Eine andere Aktion hat diese Taste. | Yes nimmt der anderen Aktion die Taste weg und gibt sie dieser. No oder Esc ändert nichts. |
| „Diese Belegung kann nicht ersetzt werden, da mindestens eine Eingabe erforderlich ist.“ | Die andere Aktion ist unverzichtbar, und das ist ihre einzige Taste. | Gib dieser Aktion zuerst eine andere Taste und versuche es dann noch einmal. |

Beispiel: Du willst, dass die Leertaste auch als Linksklick wirkt. Öffne Hinzufügen bei Linksklick, drücke die Leertaste. Du hörst „Diese Eingabe steht in Konflikt mit Tooltip vorlesen. Ersetzen?“. Drücke Pfeil runter bis Yes und Eingabe. Die Leertaste klickt jetzt, und Tooltip vorlesen hat seine Taste verloren; gib ihr eine andere, zum Beispiel Umschalt+Leertaste, wenn du sie noch haben willst.

WowVision prüft Tasten nur gegen die eigenen Aktionen. Die Tastenbelegungen des Spiels werden nicht geprüft, und solange die Taste von WowVision aktiv ist, hat sie Vorrang. Wähle Tasten, die du nicht für etwas anderes brauchst.

## Unverzichtbare Aktionen

Unverzichtbare Aktionen behalten immer mindestens eine Taste, sodass du dich nie aus der Oberfläche aussperren kannst. Versuchst du, die letzte Taste einer solchen Aktion zu entfernen, kommt „Entfernen nicht möglich; Belegung muss mindestens eine Eingabe haben.“ Du kannst trotzdem eine andere Taste hinzufügen und dann die alte entfernen.

| Aktion | Standardtaste |
|---|---|
| Hoch | Pfeil hoch |
| Runter | Pfeil runter |
| Links | Pfeil links |
| Rechts | Pfeil rechts |
| Weiter | Tab |
| Zurück | Umschalt+Tab |
| Nächstes Fenster | Strg+Tab |
| Vorheriges Fenster | Strg+Umschalt+Tab |
| Schließen | Esc |
| Linksklick | Eingabe |
| Rechtsklick | Rücktaste |
| Ziehen | \\ und Strg+D |
| Nach oben scrollen | Bild auf |
| Nach unten scrollen | Bild ab |
| Kontextmenü | Umschalt+F10 |

Bei den anderen Aktionen, etwa Zum Anfang springen, Zum Ende springen, Tooltip vorlesen, WowVision-Menü und Cursorgegenstand zerstören, dürfen alle Tasten entfernt werden. Entfernst du jemals alle Tasten von WowVision-Menü, kannst du das Menü trotzdem öffnen, indem du /wv tippst.

Die Navigationstasten oben sind nur aktiv, solange ein WowVision-Fenster offen ist. Ist kein Fenster offen, gehören sie wie gewohnt dem Spiel. Andere Aktionen, etwa die Puffertasten, die Scannertaste (F9) und die Taste des Navigationsfensters (F10), sind ständig aktiv. Siehe [Die Oberfläche bedienen](./interface.md).

## Wo deine Änderungen gespeichert werden

Tastenbelegungen sind accountweit: Änderst du eine Taste bei einem Charakter, ändert sie sich bei allen. Soll ein Charakter eigene Tasten bekommen, geh im Menü Benutzeroberfläche zu Tastenbelegung, drücke Umschalt+F10, wähle Bereich und dann den Namen deines Charakters. Dieser Charakter bekommt eine Kopie der aktuellen Tasten, und zwar aller auf einmal; mit Global kehrst du zu den gemeinsamen Tasten zurück. Es gibt keinen Schalter „Auf Standard zurücksetzen“; um eine Standardtaste wiederherzustellen, füge sie anhand der [Tastenreferenz](../reference/keybindings.md) wieder hinzu.

## Tasten, die bei geladenem Sku aus bleiben

Wenn du auch das Addon Sku benutzt, übernimmt WowVision einige Tasten nicht, die auch Sku benutzt, damit sich die beiden nicht in die Quere kommen. Das sind die vier Tasten für Tooltipzeilen (Umschalt+Pfeil hoch, Umschalt+Pfeil runter, Umschalt+Pfeil links, Umschalt+Pfeil rechts), die Tasten für die weiche Zielerfassung (Umschalt+I, Umschalt+P, Umschalt+O) und die fünf Tasten Zielfokus. Andere Befehle, die es auch bei Sku gibt, etwa /pquit, /dquit und /focus1 bis /focus5, überlässt WowVision ebenfalls Sku. Die Tasten werden im Tastenbelegungs-Bildschirm weiterhin angezeigt, tun aber nichts, solange Sku geladen ist. Ebenso überlässt WowVision viele Spielfenster (Taschen, Händler, Gossip, Post, Handel, Quest und andere) Sku.

## Controller-Tasten (Retail, WoW: Forever)

Wenn die Gamepad-Optionen des Spiels an sind, zeigt jede Zeile des Tastenbelegungs-Bildschirms auch die der Aktion zugewiesenen Controller-Tasten, gefolgt von Controller-Taste hinzufügen. Sie funktionieren wie Tasten:

- Eingabe auf einer Controller-Taste entfernt sie.
- Eingabe auf Controller-Taste hinzufügen sagt den Namen der Aktion, gefolgt von „Drücke eine Controller-Taste“. Drücke die gewünschte Taste. Die Schultertasten, die Trigger und der Rechte Stickklick lassen sich als Zusatztasten halten, sodass „Rechter Trigger plus A-Taste“ eine eigene Kombination ist. Eine Zusatztaste, die allein gedrückt und losgelassen wird, zählt als die Taste selbst.
- Es gelten dieselben Konfliktmeldungen. Esc auf der Tastatur, zehn Sekunden ohne Taste oder der Beginn eines Kampfes brechen die Aufnahme mit „Abgebrochen“ ab. Im Kampf ist die Aufnahme nicht möglich: Du hörst „Nicht im Kampf“.

Die Aktion Schließen (Controller) hat standardmäßig keine Tastaturtaste. Mit ihr lässt du die Schließen-Taste des Controllers das Esc des Spiels in Fenstern ausführen, in denen Esc beim Spiel bleibt.

Alle Einzelheiten stehen auf der Seite [Controller](../controller.md).

## Siehe auch

- [Tastenreferenz](../reference/keybindings.md)
- [Die Oberfläche bedienen](./interface.md)
- [Das WowVision-Menü und die Einstellungen](./menu-and-settings.md)
