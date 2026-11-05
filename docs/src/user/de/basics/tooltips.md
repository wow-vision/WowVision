# Tooltips

Fast alles in WoW hat einen Tooltip: Gegenstandswerte, Zauberbeschreibungen, Erklärungen zu Schaltern, Hilfetexte zu Optionen. WowVision liest den Namen eines Steuerelements vor, sobald du darauf landest, und liefert den Tooltip auf Abruf, entweder auf einmal oder Zeile für Zeile.

## Die Tasten

| Taste | Name der Belegung | Was sie tut |
|---|---|---|
| Leertaste | Tooltip vorlesen | Liest den ganzen Tooltip des fokussierten Steuerelements vor, von der ersten bis zur letzten Zeile. |
| Umschalt+Pfeil runter | Nächste Tooltipzeile | Geht zur nächsten Zeile des Tooltips und liest sie vor. |
| Umschalt+Pfeil hoch | Vorherige Tooltipzeile | Geht zur vorherigen Zeile und liest sie vor. |
| Umschalt+Pfeil rechts | Tooltip rechts vorlesen | Liest nur die rechte Spalte der aktuellen Zeile vor. |
| Umschalt+Pfeil links | Tooltip links vorlesen | Liest nur die linke Spalte der aktuellen Zeile vor. |

Alle fünf kannst du im [Tastenbelegungs-Bildschirm](./keybindings.md) ändern. Drücke jederzeit Strg, um die Sprachausgabe zu stoppen, wenn dir ein langer Tooltip zu viel wird.

## So funktioniert das Lesen

Leertaste liest alle Zeilen der Reihe nach vor, eine nach der anderen, in einem Rutsch. Leerzeilen ändern nichts an dem, was du hörst. Zeilen mit Text auf beiden Seiten (linke und rechte Spalte) werden erst links, dann rechts gelesen: Die Zeile mit „Kopf“ links und „Platte“ rechts wird als „Kopf Platte“ gelesen, und „Rüstung“ mit „120“ als „Rüstung 120“.

Umschalt+Pfeil runter und Umschalt+Pfeil hoch gehen den Tooltip Zeile für Zeile durch und überspringen Leerzeilen. Das erste Umschalt+Pfeil runter, nachdem du auf einem Steuerelement gelandet bist, liest die erste Zeile; das erste Umschalt+Pfeil hoch liest die letzte Zeile. Hast du die erste oder letzte Zeile erreicht, liest ein weiterer Tastendruck diese Zeile einfach noch einmal.

Umschalt+Pfeil links und Umschalt+Pfeil rechts sind für zweispaltige Zeilen gedacht. Nachdem du mit Umschalt+Pfeil hoch oder Umschalt+Pfeil runter zu einer Zeile gegangen bist, kannst du nur ihre linke oder nur ihre rechte Seite hören. Das ist praktisch bei Aufschlüsselungen von Werten oder bei Vergleichs-Tooltips, in denen die Zahlen rechts stehen. Bist du noch zu keiner Zeile gegangen, lesen sie Zeile eins.

Deine Position im Tooltip beginnt jedes Mal von vorn, wenn du zu einem anderen Steuerelement gehst.

Dieselben Tasten funktionieren auf einer Aura in einem Puffer: Solange du auf einem Buff oder Debuff in einem Aura-Puffer bist, lesen Umschalt+Pfeil runter und Umschalt+Pfeil hoch seinen Namen, seine Beschreibung und die verbleibende Zeit Zeile für Zeile, auch im Kampf. Siehe [Aura-Puffer](../information/buffers.md#aura-puffer).

Beispiel: Du stehst in deinen Taschen auf einem Rüstungsteil.

1. Drücke die Leertaste und höre dir den ganzen Gegenstand an, zum Beispiel „Pelzstiefel. Wird beim Aufheben gebunden. Füße Stoff. Verbreitet. Gegenstandsstufe 12. 8 Rüstung.“ (Die genauen Zeilen hängen vom Gegenstand ab.)
2. Du willst nur die Rüstungszeile noch einmal hören. Drücke Umschalt+Pfeil hoch: Du hörst die letzte Zeile.
3. Drücke Umschalt+Pfeil hoch, bis du bei der gewünschten Zeile bist. Drücke Umschalt+Pfeil rechts, um nur ihre rechte Spalte zu hören.

## Was zu Gegenstands-Tooltips hinzugefügt wird

Gehört der Tooltip zu einem Gegenstand, ergänzt WowVision zwei Zeilen, die das Spiel nicht immer als reinen Text zeigt:

- Den Qualitätsnamen (Schlecht, Verbreitet, Ungewöhnlich, Selten, Episch, Legendär, Artefakt, Erbstück), direkt unter der Platzzeile des Gegenstands (oder unter dem Namen des Gegenstands, wenn er keine Platzzeile hat).
- Die Gegenstandsstufe, direkt nach der Qualität. Zeigt das Spiel eine eigene Zeile für die Gegenstandsstufe (die Aufwertungen berücksichtigt), wird diese Zeile dorthin verschoben, statt eine zweite hinzuzufügen. Nur anlegbare Gegenstände bekommen eine Gegenstandsstufe.

Geld im Tooltip wird mit seinen Münzen vorgelesen. Das Spiel zeigt Gold, Silber und Kupfer als kleine Münzbilder, die die Sprachausgabe weglassen würde. WowVision liest den Verkaufspreis und andere Beträge als „Verkaufspreis: 1 Gold, 23 Silber, 45 Kupfer“. Ein Gegenstand, der nur ein paar Münzen wert ist, klingt zum Beispiel so: „Verkaufspreis: 7 Kupfer“.

## Gegenstandsqualität in Namen

In Listen und auf Plätzen tragen Gegenstandsnamen die Qualität als die Farbe, in der ein sehender Spieler den Namen sieht, sodass du „Pelzstiefel, Weiß“ oder „Donnerzorn, Orange“ hörst. Das betrifft nur Namen. Der Tooltip liest immer den Qualitätsnamen („Verbreitet“, „Legendär“), egal was du unten einstellst.

| Qualität | Farbe, die du hörst | Name der Einstellung |
|---|---|---|
| Schlecht | Grau | Grau (Schlecht) |
| Verbreitet | Weiß | Weiß (Verbreitet) |
| Ungewöhnlich | Grün | Grün (Ungewöhnlich) |
| Selten | Blau | Blau (Selten) |
| Episch | Violett | Violett (Episch) |
| Legendär | Orange | Orange (Legendär) |
| Artefakt | Hellgold | Hellgold (Artefakt) |
| Erbstück (und die WoW-Marke) | Hellblau | Hellblau (Erbstück) |

(Der Teil in Klammern ist der Qualitätsname aus dem deutschen Spielclient.)

Zum Ändern öffnest du das [WowVision-Menü](./menu-and-settings.md) mit Umschalt+F1, dann Benutzeroberfläche, Tooltip, Qualität. Jede Farbe ist ein Kontrollkästchen, standardmäßig an. Schalte eines aus, um diese Farbe nach Gegenstandsnamen nicht mehr zu hören. Das Kontrollkästchen Aktiviert ganz oben im Menü Qualität schaltet alle auf einmal aus.

Beispiel: Du findest, dass zu viele „Weiß“ und „Grau“ deine Taschenansage zumüllen. Schalte Weiß (Verbreitet) und Grau (Schlecht) aus. Die Namen lauten dann bei diesen „Leinenstoff“, während „Pelzstiefel, Grün“ seine Farbe behält.

## Preise in Tooltips (nur The Burning Crusade)

In The Burning Crusade können Gegenstands-Tooltips zusätzliche Preiszeilen enthalten, die wie jede andere Zeile gelesen werden:

- Auktionspreis (Auction Price), der zuletzt im Auktionshaus gesehene Preis, mit der Angabe, vor wie vielen Tagen er gesehen wurde (entfällt, wenn es heute war),
- das Tage-Mittel (Day Mean), der Durchschnitt der letzten Tage, gelesen mit seiner Tageszahl (zum Beispiel „7-Tage-Mittel“),
- Händler-Verkaufspreis (Vendor Sell), was ein Händler für den Gegenstand zahlt,
- Händler-Kaufpreis (Vendor Buy), was ein Händler dafür verlangt, sobald du den Gegenstand bei einem Händler gesehen hast.

Diese Preise stammen aus der Preisdatenbank, die WowVision aufbaut, während du das Auktionshaus benutzt. Eine Zeile erscheint nur, wenn WowVision diesen Preis kennt: Ein Gegenstand, den du nie im Auktionshaus gesehen hast, bekommt keine Auktionszeilen, und einer, den du nie bei einem Händler gesehen hast, keine Zeile Händler-Kaufpreis. Das Kontrollkästchen Preise im Tooltip im Menü Auktionspreise (standardmäßig an) schaltet die zusätzlichen Zeilen aus oder ein. Im selben Menü gibt es Tage im Preisverlauf (21), Tage für den Mittelwert (7) und Automatischer Scan (aus), siehe [Auktionshaus](../windows/auction-house.md).

## Steuerelemente ohne Tooltip

Nicht jedes Steuerelement hat einen Tooltip. Wo keiner existiert, bleibt die Leertaste dem Spiel überlassen, das heißt, dein Charakter springt, wenn du nicht gerade tippst. Die Umschalt+Pfeiltasten tun in diesem Fall nichts.

## Wenn du nichts hörst

- Ein Gegenstand, den das Spiel noch nicht geladen hat, kann zunächst einen leeren Tooltip haben. WowVision fragt erneut an, wenn du die Leertaste drückst; bis dahin sind die Informationen meist angekommen. Drücke die Leertaste noch einmal, falls du nichts gehört hast.
- Die Tooltip-Tasten lesen, was zum fokussierten Steuerelement gehört. Ist kein Fenster offen, gibt es nichts zu lesen.
- Wenn du auch das Addon Sku benutzt, lässt WowVision die vier Umschalt+Pfeiltasten für den Tooltip unbelegt, damit sich die beiden Addons nicht um sie streiten. Die Leertaste funktioniert weiterhin.

## Diagnosebefehl

Fehlen Tooltips in einem bestimmten Fenster oder sind sie falsch, fokussiere das Steuerelement und tippe /wv gtooltip. WowVision spricht und zeigt an, was der Tooltip-Leser über das Steuerelement weiß, was bei einem Fehlerbericht hilft. Siehe die [Slash-Befehle](../reference/commands.md).

## Siehe auch

- [Die Oberfläche bedienen](./interface.md)
- [Tastenbelegung](./keybindings.md)
