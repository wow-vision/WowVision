# Menüs, Optionen und Dialoge

Diese Seite behandelt die Fenster, die zum Spiel selbst gehören und nicht zur Welt: das Spielmenü, die Spieloptionen, Popups und Bestätigungsdialoge, das Makrofenster und die Farbauswahl. Sie beschreibt auch die Entfernungsansage, einen kleinen Helfer, der dir sagt, wie weit dein Ziel entfernt ist.

Wenn du stattdessen das WowVision-Menü suchst, das die eigenen Einstellungen von WowVision enthält, siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

## Das Spielmenü

Drücke Esc, wenn kein Fenster offen ist, und das Spiel öffnet sein Spielmenü. WowVision liest es als ein Fenster namens Menü.

- Jede Schaltfläche ist ein eigener Stopp, von oben nach unten. Mit Tab und Umschalt+Tab wechselst du zwischen ihnen. Die Pfeiltasten bewegen sich hier nicht zwischen den Schaltflächen.
- Drücke Eingabe, um die zu benutzen, auf der du bist.
- Drücke noch einmal Esc, um das Menü zu schließen und zum Spiel zurückzukehren.

Die Schaltflächen sind die des Spiels und hängen von der Version ab. Normalerweise gehören Optionen, Makros, Ausloggen, Spiel beenden und Zurück zum Spiel dazu, in manchen Versionen auch Hilfe, Shop, Interface und Bearbeitungsmodus. Jede wird mit ihrer Beschriftung im Spiel gelesen.

Ist ein anderes WowVision-Fenster offen, schließt Esc zuerst dieses Fenster. Das Spielmenü öffnet sich beim nächsten Druck.

## Das Optionsfenster des Spiels

Optionen im Spielmenü öffnen das Einstellungsfenster des Spiels. Der WowVision-Leser deckt fast alles davon ab: seine Reiter, die Kategorienliste, das Suchfeld und fast jede Art von Einstellungszeile. Öffne es über das Spielmenü.

### Die Teile des Fensters

Das Fenster öffnet sich auf Suchen. Die Stopps, der Reihe nach:

1. Reiter (Tabs): Spiel (Game) und AddOns, als Zeile. Die Reiter sind nur da, wenn das Spiel sie zeigt. Eine frische WoW: Forever-Installation hat keine Reiter, bis ein Addon Einstellungen registriert.
2. Suchen (Search): ein Textfeld. Wenn du mit Tab hineingehst, ist es sofort zum Tippen bereit. Tippe einen Teil des Namens einer Einstellung, und die Liste zeigt passende Einstellungen aus allen Kategorien. Tab verlässt das Feld.
3. Kategorien (Categories): die Kategorienliste, etwa Gameplay, Steuerung, Grafik, Audio, Interface, Soziales und Tastenbelegungen. Gruppenüberschriften werden als „Name, Trennlinie“ gelesen. Eingabe auf einer Kategorie zeigt ihre Einstellungen.
4. Einstellungen: die Einstellungen der gewählten Kategorie. Dieser Stopp ist nach der Kategorie benannt, zum Beispiel „Audio“.
5. Standard (Defaults): die Schaltfläche des Spiels, die die aktuelle Kategorie auf ihre Standardwerte zurücksetzt. Das Spiel lässt dich das in einem Popup bestätigen.

Wenn du eine andere Kategorie wählst, beginnt der Einstellungsstopp wieder ganz oben.

### Die Einstellungen

Wie jede Art von Zeile klingt und funktioniert:

| Einstellung | Was du hörst | Wie du sie änderst |
|-------------|--------------|--------------------|
| Kontrollkästchen | Der Name und „Aktiviert“ oder „Nicht aktiviert“. | Eingabe schaltet um. Der neue Zustand wird gesprochen. |
| Schieberegler | Der Name und der Wert. | Pfeil links und Pfeil rechts ändern den Wert um einen Schritt. Eingabe öffnet ein Feld, in das du die genaue Zahl tippen kannst. |
| Dropdown | Der Name und die aktuelle Auswahl. | Eingabe öffnet das Dropdown-Menü des Spiels als WowVision-Menü. Wähle mit Eingabe. Dropdowns mit mehreren Haken, etwa welche Chatarten angezeigt werden, listen die gewählten Einträge auf, oder „Keine“. |
| Schaltfläche | Der Name und die Beschriftung der Schaltfläche, etwa „Abklingzeitmanager, Bearbeitungsmodus öffnen“. | Eingabe drückt sie. |
| Farbfeld | Der Name und die aktuelle Farbe. | Eingabe öffnet die Farbauswahl. Siehe [Die Farbauswahl](#die-farbauswahl). |
| Abschnittsüberschrift | Der Name und „Trennlinie“. | Es gibt nichts zu drücken. |

Manche Zeilen enthalten zwei Bedienelemente, etwa ein Kontrollkästchen und einen Schieberegler oder ein Kontrollkästchen und ein Farbfeld. Sie werden als Paar gelesen: der Name, dann das erste Bedienelement und seine Position, zum Beispiel „1 von 2“. Mit Pfeil runter (oder Pfeil rechts) erreichst du das zweite Bedienelement und mit Pfeil hoch (oder Pfeil links) kommst du zurück. Das zweite Bedienelement liest Deaktiviert, solange sein Kontrollkästchen aus ist, weil das Spiel es ausgraut.

Ein Bedienelement, das das Spiel ausgegraut hat, sagt „Deaktiviert“, und Eingabe darauf tut nichts. Eine Einstellungszeile hat außerdem einen Tooltip. Drücke die Leertaste, um die Erklärung zu lesen, die das Spiel dafür gibt.

Besondere Zeilen:

- Grafikqualität (Graphics Quality) hat zwei Reiter, Basis (Base) und Schlachtzug und Schlachtfelder (Raid and Battlegrounds). Jeder hat einen Qualitätsregler von 1 bis 10, dann eine Liste von Detail-Dropdowns (Schatten, Flüssigkeiten, Partikel, Texturen und so weiter). Der Schlachtzug-Reiter hat ein eigenes Kontrollkästchen Aktiviert. Sichtweite, Umgebungsdetails und Bodenbewuchs sind ebenfalls Regler von 1 bis 10.
- Farben der Gegenstandsqualität (Item Quality Colors; die Kategorie für Farbenblindheit): ein Farbfeld für jede Gegenstandsqualität, benannt nach der Qualität, etwa Schlecht, Gewöhnlich und Selten.
- Vorschau der Schlachtzugsfenster (Raid Frame Preview) und Vorschau der Namensplaketten (Nameplate Preview) werden nur als Text gesprochen, weil die Vorschau ein Bild ist.
- Manche Zeilen stellen neben ein Kontrollkästchen eine Erklärung. Sie wird als Teil des Kontrollkästchens gelesen.
- Die Zeile für die Text-zu-Sprache-Stimme des Spiels ist ein Dropdown mit einer Probe-Schaltfläche daneben und wird wie die Zeilen mit zwei Bedienelementen oben als Paar gelesen.
- Eine Zeile einer Art, die WowVision noch nicht kennt, wird als „Setting type“, der Name des Zeilentyps im Spiel, und „not implemented“ gelesen (diese Ansage kommt auf Englisch). Bitte melde sie. Siehe [Fehlerbehebung](../getting-started/troubleshooting.md).

### Tastenbelegungen

Die Kategorie Tastenbelegungen (Keybindings) listet die eigenen Tastenbelegungen des Spiels in Abschnitten auf.

- Eine Abschnittsüberschrift sagt „Ausgeklappt“ oder „Eingeklappt“. Eingabe klappt sie ein oder aus.
- Manche Abschnitte beginnen mit einer kurzen Erklärungszeile, die wie jeder andere Text gelesen wird.
- Jede Belegung ist ein Paar von Schaltflächen, benannt nach der Aktion, zum Beispiel „Springen“. Jede Schaltfläche liest die Taste, die sie hält, oder „Nicht belegt“. Mit Pfeil links und Pfeil rechts wählst du zwischen den beiden.
- Eingabe auf einer Schaltfläche startet das Umbelegen. Drücke die gewünschte Taste (oder Tastenkombination). Wenn es klappt, sagt WowVision „Rebinding successful“ (auf Englisch).
- Die Rücktaste entfernt die Taste von dieser Schaltfläche.

Das ändert die Belegungen des Spiels. Die eigenen Tasten von WowVision (die, mit denen du dich durch Fenster bewegst) änderst du stattdessen im Fenster für die Tastenbelegung von WowVision. Siehe [Tastenbelegung](../basics/keybindings.md).

Beispiel: Automatisch plündern (Auto Loot) einschalten.

1. Drücke Esc, dann Tab bis Optionen, und drücke Eingabe.
2. Drücke Tab bis Suchen und tippe „automatisch plündern“.
3. Drücke Tab, bis du in der Einstellungsliste bist, und lies bis Automatisch plündern hinunter.
4. Drücke Eingabe, um es einzuschalten oder die Auswahl zu öffnen, je nach Spielversion. Der neue Zustand wird gesprochen.
5. Drücke Esc, um das Fenster zu schließen.

## Popups und Bestätigungsdialoge

Viele Fragen im Spiel erscheinen als kleine Kästen in der Mitte des Bildschirms: eine Gruppeneinladung, ein Wiederbelebungsangebot, eine Beschwörung, die Rückfrage „Willst du diesen Gegenstand binden?“ und die Bestätigung „Diesen Gegenstand zerstören?“. WowVision öffnet für jeden Kasten ein Fenster namens Popup und liest ihn vor. Alle Kästen, die gleichzeitig offen sind, werden in einem Fenster aufgelistet, nacheinander, jeder mit einer eigenen Überschrift Popup.

Ein Kasten hat bis zu drei Teile, jeder ein eigener Stopp:

1. Der Text der Frage. Er wird neu gelesen, wenn er sich ändert, zum Beispiel bei einem Countdown wie „Du wirst in 30 Sekunden teleportiert“. Ist der Kasten einer, bei dem das Spiel erlaubt, zum Annehmen die Eingabetaste zu drücken, drückt Eingabe auf dem Text für dich die erste Schaltfläche.
2. Ein Textfeld, nur wenn der Dialog verlangt, dass du etwas tippst, etwa einen Namen oder das Wort LÖSCHEN (das der deutsche Client beim Zerstören wertvoller Gegenstände verlangt). Es liest den Hinweis des Feldes, dann das, was du getippt hast. Eingabe legt den Tastaturfokus des Spiels hinein, tippe also deinen Text, und dann nimmt noch einmal Eingabe den Dialog an (das ist das eigene Verhalten des Spiels), oder Esc bricht ihn ab.
3. Die Schaltflächen, jede ein eigener Stopp, mit den Beschriftungen des Spiels: Annehmen, Ablehnen, Okay, Abbrechen, Ja, Nein und so weiter. Drücke Eingabe, um eine zu benutzen.

Esc bricht den Kasten genauso ab, wie es das Spiel tut.

Beispiel: eine Gruppeneinladung annehmen.

1. Du hörst das Popup: den Namen des Spielers und „lädt dich in eine Gruppe ein“.
2. Drücke Tab bis Annehmen. Drücke Eingabe.

Ist das Addon Sku geladen, überlässt WowVision Popups Sku.

## Makros

Öffne das Makrofenster über das Spielmenü (Makros) oder mit dem Slash-Befehl `/macro`. Das Fenster liest sich in zwei Modi.

### Das Hauptfenster

Die Stopps, der Reihe nach:

1. Reiter (Tabs): die zwei Reiter, allgemeine Makros und die Makros deines Charakters. Der aktuelle sagt „ausgewählt“.
2. Makros (Macros): deine Makros als Liste, nach Namen. Eingabe wählt eines aus, und das gewählte sagt „ausgewählt“. Die Liste sagt „Leer“, wenn der Reiter keine Makros hat.
3. Ziehen, um Makro aufzunehmen (Drag to pick up macro): die Schaltfläche, die für das Symbol des gewählten Makros steht. Drücke hier \\ (die Taste für Ziehen), um das Makro auf deinen Cursor zu nehmen. (\\ liegt auf deutschen Tastaturen auf Alt Gr+ß; belege die Aktion bei Bedarf um.)
4. Edit: die Schaltfläche, die das Feld für Name und Symbol öffnet. Sie liest sich mit der eigenen Beschriftung des Spiels, normalerweise Name/Symbol ändern (Change Name/Icon).
5. Makrotext (Macro Text): ein Textfeld mit den Befehlen des Makros. Gehe mit Tab hinein und tippe. Mit Tab verlässt du es wieder.
6. Die Schaltflächen, die das Spiel gerade zeigt, jede ein eigener Stopp: Abbrechen, Speichern, Löschen und Neu.

### Das Namensfeld

Nach Neu oder Edit zeigt das Fenster ein kleineres Feld. Es hat das Textfeld für den Namen, Okay und Abbrechen. WowVision liest die Symbolliste nicht, du kannst also kein Symbol wählen. Ein neues Makro bekommt das Symbol, mit dem das Spiel startet.

Beispiel: ein Makro erstellen und auf deine Aktionsleiste legen.

1. Tippe `/macro` ins Chatfeld und drücke Eingabe.
2. Gehe mit Tab zur Schaltfläche Neu (drücke Umschalt+Tab vom Anfang aus, um zu ihr herumzuspringen) und drücke Eingabe.
3. Tippe im Namensfeld „Heilen“, gehe dann mit Tab zu Okay und drücke Eingabe.
4. Gehe mit Tab zu Makrotext. Tippe `/cast Heilende Berührung` und drücke Tab.
5. Gehe mit Tab zu Speichern und drücke Eingabe.
6. Gehe mit Umschalt+Tab zurück zu Ziehen, um Makro aufzunehmen und drücke \\. Das Makro liegt auf deinem Cursor.
7. Öffne das Leistenfenster mit Umschalt+F4, gehe zu einem leeren Platz und drücke \\. Der Platz liest jetzt „Heilen“. Siehe [Aktionsleisten](./action-bars.md).

## Die Farbauswahl

Farbfelder in den Optionen und in manchen Addon-Fenstern öffnen die Farbauswahl des Spiels. Das Farbrad selbst braucht eine Maus, deshalb liest WowVision stattdessen dieselben Farben als Zahlen.

Die Stopps, der Reihe nach:

1. Aktuelle Farbe (Current Color): eine gesprochene Beschreibung der Farbe, zum Beispiel „Aktuelle Farbe: dunkelgräuliches Blau, Slate Gray“. Sie aktualisiert sich, wenn du die Regler änderst.
2. Ursprüngliche Farbe (Original Color): die Farbe, mit der du angefangen hast (nur wenn das Spiel sie kennt).
3. Rot, Grün und Blau: jeweils eine Zahl von 0 bis 255, gefolgt von der Beschreibung der ganzen Farbe, sodass du hörst, was aus der Farbe geworden ist. Pfeil links und Pfeil rechts ändern sie um eins. Eingabe lässt dich einen genauen Wert tippen.
4. Deckkraft (Opacity): nur wenn die Farbe Transparenz hat, als Prozentwert. Pfeil links und Pfeil rechts ändern sie um 5 Prozent, und Eingabe lässt dich einen Wert tippen.
5. Hex-Farbe (Hex Color): ein Textfeld mit der Farbe als Hex-Wert, wo das Spiel eines hat. Tippe einen Code, und die Regler folgen.
6. Okay und Abbrechen, in einer Zeile.

Beispiel: eine Farbe auf reines Rot setzen.

1. Eingabe auf einem Farbfeld in den Optionen. Die Farbauswahl öffnet sich.
2. Gehe mit Tab zu Rot. Drücke Eingabe, tippe 255 und drücke Eingabe.
3. Gehe mit Tab zu Grün, tippe 0. Gehe mit Tab zu Blau, tippe 0.
4. Gehe mit Tab zu Aktuelle Farbe, um die Beschreibung zu hören, gehe dann mit Tab zu Okay und drücke Eingabe.

## Die Entfernungsansage

(In allen Versionen verfügbar.) Solange du ein Ziel hast, sagt dir WowVision seine Entfernung in Yards, damit du weißt, ob du für einen Zauber in Reichweite bist. Es spielt eine aufgenommene Stimme ab, die die Zahl sagt, zum Beispiel „thirty“ (die Stimme Matthew spricht Englisch). Sie spricht, wenn du etwas anvisierst und immer dann, wenn sich die Entfernung auf eine andere Stufe ändert. Sie sagt nichts, solange du kein Ziel hast.

Die Entfernungen stammen aus denselben Reichweitenprüfungen, die die Zauber und Gegenstände des Spiels benutzen, du hörst also Stufen wie 5, 8, 10, 20, 30, 35 oder 40. Die Zahl ist eine Obergrenze, keine genaue Messung: „thirty“ heißt, dein Ziel ist höchstens dreißig Yards entfernt. In manchen Versionen fehlen einige Stufen, weil das Spiel dafür keine Prüfung bietet. Im Kampf ist die Entfernung zu einem freundlichen Ziel nicht verfügbar.

Ist das Ziel weiter weg als die längste Prüfung, die das Spiel bietet, wird nichts gesagt, und die Ansage spricht wieder, wenn du in Reichweite zurückkommst.

Um sie zu ändern, öffne im WowVision-Menü Zielerfassung, dann Festes Ziel, und wähle Reichweite geändert (Range Changed):

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Reichweite geändert, Aktiviert | An | Schaltet die ganze Ansage ein oder aus. |
| Stimmenalarm darin, Aktiviert | An | Die aufgenommene Stimme. |
| Stimmenalarm darin, Stimmenpaket | Matthew | Legt fest, wessen aufgenommene Stimme die Zahlen liest. |

Der Reichweitenalarm hat weder Text-zu-Sprache noch eine Sound-Ausgabe, nur die Stimme. Wie Alarme und Stimmenpakete funktionieren, steht unter [Alarme](../basics/alerts.md) und [Sprache und Ton](../basics/speech.md).

## Einstellungen und Alarme

| Fenster | Einstellungen | Alarme |
|---------|---------------|--------|
| Spielmenü | Keine | Keine |
| Spieloptionen | Keine | Keine |
| Popups | Keine | Keine |
| Makros | Keine | Keine |
| Farbauswahl | Keine | Keine |
| Reichweite | Reichweite geändert, unter Zielerfassung, Festes Ziel (oben) | Reichweite geändert |

Jedes dieser Fenster ist ein Modul unter Fenster im WowVision-Menü, und jedes hat einen Schalter Aktiviert, der verhindert, dass WowVision es liest. Reichweite hat keinen eigenen Eintrag: Sein Schalter Aktiviert liegt auf dem Alarm Reichweite geändert. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md).

## Fehlerbehebung

- Esc öffnet das Spielmenü, statt mein Fenster zu schließen. Das Fenster war schon geschlossen. Drücke Esc noch einmal, um das Spielmenü zu verlassen.
- Ein Popup scheint zu fehlen. Drücke Strg+Tab, um zu ihm zu wechseln. Ein Popup und ein anderes Fenster können gleichzeitig offen sein.
- Ich kann eine Farbe nicht über einen Farbnamen einstellen. Die Farbauswahl nimmt nur Zahlen oder einen Hex-Code.
