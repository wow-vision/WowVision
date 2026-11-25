# Begleiter-Gesundheit

Verfügbar in Retail und WoW: Forever.

WowVision sagt dir, wie viel Gesundheit dein Begleiter noch hat: das Tier eines Jägers, der Dämon eines Hexenmeisters oder jeder andere Begleiter. Eine Taste sagt es, wann immer du willst, und WowVision kann es im Kampf auch von selbst ansagen. Der [Gruppen-Gesundheitsmonitor](group-health.md) beobachtet nur Spieler, dein Begleiter gehört nicht dazu.

## Die Taste

Gesundheit des Begleiters ansagen (Standard Alt+Umschalt+H) sagt die Gesundheit des Begleiters, zum Beispiel "Begleiter 45 Prozent". Ohne Begleiter hörst du "Kein Begleiter", bei einem toten Begleiter "Begleiter tot".

Der Prozentwert wird auf ein Vielfaches von 5 aufgerundet: "Begleiter 45 Prozent" heißt mehr als 40 und höchstens 45. Ein Begleiter, der noch Gesundheit hat, wird nie als 0 angesagt. Du kannst in den Einstellungen eine andere Stufe wählen.

Um die Taste zu ändern, öffne das WowVision-Menü, gehe zu Benutzeroberfläche, dann Tastenbelegung, oder gib `/wv bind` ein. Siehe [Tastenbelegung](../basics/keybindings.md).

## Von selbst ansagen

Das ist aus, bis du in den Einstellungen der Begleiter-Gesundheit (Umschalt+F1 oder `/wv`, dann Begleiter-Gesundheit) Gesundheitsänderungen ansagen einschaltest.

- Im Kampf wird eine Änderung der Gesundheit deines Begleiters höchstens alle 3 Sekunden angesagt, und nur, wenn WowVision sonst nichts zu sagen hat. Eine Änderung, die warten muss, wird angesagt, sobald WowVision still ist, mit der Gesundheit, die der Begleiter dann hat.
- Wenn der Kampf endet, wird eine noch nicht angesagte Änderung einmal angesagt.
- Wenn dein Begleiter stirbt, hörst du sofort "Begleiter tot".

## Einstellungen

| Einstellung | Standard | Wirkung |
|---|---|---|
| Aktiviert | An | Aus sagt das Modul nichts, und seine Taste tut nichts |
| Gesundheitsänderungen ansagen | Aus | Sagt die Gesundheit des Begleiters von selbst an, wenn sie sich ändert, siehe oben |
| Auch außerhalb des Kampfes | Aus | Mit eingeschalteten Ansagen auch Änderungen außerhalb eines Kampfes, zum Beispiel während sich der Begleiter erholt |
| Höchstens alle (Sekunden) | 3 | Die kürzeste Zeit zwischen zwei Ansagen, von 1 bis 30 |
| Aufrunden auf | 5 Prozent | Die Stufe, auf die der Prozentwert aufgerundet wird: 1, 5, 10, 20 oder 25 Prozent |

## Grenzen

- Das Spiel verbirgt die Gesundheit deines Begleiters vor Addons. WowVision kann sie aussprechen lassen, aber nicht kennen: Es kann dich nicht unterhalb eines Wertes deiner Wahl warnen, und es sagt eine Änderung auch dann an, wenn der gerundete Wert derselbe wie vorher ist.
- Gibt das Spiel die Gesundheit nicht heraus, sagt die Taste "Begleiter-Gesundheit hier nicht verfügbar".
