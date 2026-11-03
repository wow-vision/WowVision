# Sprache und Ton

WowVision spricht alles über die im Spiel eingebaute Sprachausgabe (TTS, Text-to-Speech) mit den Stimmen, die auf deinem Computer installiert sind. Diese Seite behandelt die Wahl einer Stimme, Geschwindigkeit und Lautstärke, das Stoppen der Sprache, die eigenen TTS-Sounds des Spiels, die aufgenommenen Stimmenpakete und den Schnellbefehl /wv speech.

## Wo die Einstellungen sind

Drücke Umschalt+F1 (oder tippe /wv), um das [WowVision-Menü](./menu-and-settings.md) zu öffnen, drücke S, bis du Sprache hörst, und drücke Eingabe. Du kannst auch direkt dorthin springen, indem du /wv gsettings speech tippst.

Das Modul Sprache ist immer an; es hat kein Kontrollkästchen Aktiviert.

## Die Spracheinstellungen

| Einstellung | Standard | Was sie tut |
|---|---|---|
| Sprachstimme (Speech Voice) | Die erste installierte Stimme | Welche TTS-Stimme spricht. Eingabe öffnet die Liste der auf deinem Computer installierten Stimmen. WowVision merkt sich die Stimme über ihren Namen, sodass das spätere Installieren oder Entfernen von Windows-Stimmen dich nicht stillschweigend auf eine andere umstellt. |
| Sprachlautstärke (Speech Volume) | 100 | Lautstärke der TTS-Stimme, von 0 bis 100. |
| Sprachgeschwindigkeit (Speech Rate) | 0 | Tempo der Stimme. 0 ist normal, negative Zahlen sind langsamer, positive schneller. Sie reicht von -10 bis 10; ein Wert außerhalb springt auf das nächste Ende. |
| Sprachwarteschlange (Speech Queue) | An | (The Burning Crusade, Mists of Pandaria, Retail und WoW: Forever) WowVision spricht eine Zeile nach der anderen und reiht die übrigen ein, auch Sprache vom Spiel und von anderen Addons. Schalte sie nur aus, wenn ein anderes Addon, das Sprache nutzt, Probleme macht; WowVision spricht dann direkt mit dem Spiel. |
| Sprachstil (Speech Style) | Direkt | (nur Classic Era) Direkt spricht jede Zeile sofort. Gepuffert reiht die Sprache ein und wartet nach jeder Unterbrechung einen Moment, bevor die nächste Zeile gesprochen wird. Probiere Gepuffert, wenn die ersten Wörter nach einer Unterbrechung verschluckt werden. |
| Ton zwischen Chatzeilen (Sound Between Chat Lines) | Aus nach deinem ersten Login | Der eigene Sound des Spiels, der Chatzeilen voneinander trennt. Siehe [Spielsounds rund um die Sprache](#spielsounds-rund-um-die-sprache). |
| Aktivitätston bei verborgenem Chatfenster (Activity Sound When Unfocused) | Die Einstellung des Spiels | Der eigene Sound des Spiels, wenn eine Nachricht gesprochen wird, während das Chatfenster verborgen ist. |

Beispiel: Sprechtempo erhöhen.

1. Drücke Umschalt+F1, um das WowVision-Menü zu öffnen.
2. Drücke S, bis du „Sprache, Schalter“ hörst, dann Eingabe.
3. Drücke Pfeil runter bis Sprachgeschwindigkeit, Zahl, 0.
4. Drücke einige Male Pfeil rechts. Du hörst jede neue Zahl, und die Stimme spricht ab der nächsten Zeile schneller. Oder drücke Eingabe, tippe 5 und drücke Eingabe.

Beispiel: Stimme wechseln.

1. Gehe im Menü Sprache zu Sprachstimme und drücke Eingabe.
2. Gehe durch die Liste der Stimmen; die aktuelle wird als „ausgewählt“ gelesen. Drücke Eingabe auf der gewünschten.

In Classic Era, TBC und Mists setzt WowVision Leerzeichen um Schrägstriche in dem, was es sagt, sodass „250/500“ als zwei Zahlen gesprochen wird: „250 / 500“. Retail und WoW: Forever geben den Text unverändert weiter.

Sprachstimme, Sprachlautstärke, Sprachgeschwindigkeit und die Einstellung für Warteschlange oder Stil gelten standardmäßig accountweit. Du kannst einem Charakter eigene Werte geben, indem du im Kontextmenü (Umschalt+F10) einer Einstellung den Eintrag Bereich benutzt, siehe [Einstellungen pro Charakter und accountweit](./menu-and-settings.md#einstellungen-pro-charakter-und-accountweit). Die beiden Kontrollkästchen für Spielsounds sind die eigenen Einstellungen des Spiels und haben keinen Eintrag Bereich.

## Schnelleinrichtung mit /wv speech

/wv speech stellt Stimme, Geschwindigkeit und Lautstärke in einer Zeile ein. Der Befehl ist für ein Login-Makro gedacht, weil er sofort wirkt und eine Bestätigung spricht.

| Was du tippst | Was passiert |
|---|---|
| /wv speech | Gibt im Chatfenster deine aktuelle Stimmennummer, Geschwindigkeit und Lautstärke aus, gefolgt von einer Liste aller Stimmen mit ihren Nummern. Du hörst es normalerweise als Chatnachricht. |
| /wv speech 1 8 100 | Stimme Nummer 1, Geschwindigkeit 8, Lautstärke 100. |
| /wv speech 1 8 | Stimme 1 und Geschwindigkeit 8; die Lautstärke bleibt, wie sie ist. |
| /wv speech 2 | Nur Stimme 2; Geschwindigkeit und Lautstärke bleiben, wie sie sind. |

Die Stimmennummern beginnen bei 0: Deine erste Stimme hat die Nummer 0. Die Geschwindigkeit ist auf -10 bis 10 begrenzt, die Lautstärke auf 0 bis 100, Dezimalstellen werden gerundet. Gibt es die Stimmennummer nicht oder ist ein Wert keine Zahl, gibt WowVision eine Meldung im Chat aus und ändert nichts. Wenn es klappt, hörst du zum Beispiel „Speech voice Microsoft Zira Desktop, rate 8, volume 100“ (Ansage auf Englisch, wenn nicht übersetzt).

## Sprache stoppen

- Drücke Strg allein, um die aktuelle Sprachausgabe jederzeit abzuschneiden. Das funktioniert, egal ob ein Fenster offen ist, und auch, wenn du Strg als Zusatztaste benutzt (Strg+Tab, Strg+D), weil die Sprache in dem Moment stoppt, in dem die Taste nach unten geht.
- Jede Navigationstaste (Pfeiltasten, Tab, Pos1, Ende und so weiter) stoppt die laufende Sprache, bevor sie das neue Steuerelement liest, sodass schnelles Pfeilen nie einen Rückstau aufbaut.
- Die Einstellung Sprache beim Schließen des Fensters unterbrechen (im Menü Benutzeroberfläche, standardmäßig aus) schneidet die Sprache ebenfalls ab, wenn sich ein Fenster schließt. Schalte sie ein, wenn der Text des alten Fensters weiterspricht, nachdem du es verlassen hast.
- Auch Alarme können unterbrechen. Ein TTS-Alarm mit eingeschalteter Prioritätsnachricht (unterbricht) stoppt die laufende Sprache, bevor er spricht, so wie der Alarm Zielwechsel. Siehe [Alarme](./alerts.md).

## Spielsounds rund um die Sprache

Die TTS des Spiels spielt zwei kleine eigene Sounds, und WowVision gibt dir im Menü Sprache für jeden ein Kontrollkästchen:

- Ton zwischen Chatzeilen ist ein kurzer Sound, den das Spiel zwischen Chatzeilen abspielt. Weil er zwischen allen Ansagen von WowVision erklingen würde, schaltet WowVision ihn für dich aus, wenn sich jeder Charakter zum ersten Mal mit dem Addon einloggt. Danach gilt deine Wahl: Schaltest du ihn wieder ein, bleibt er an.
- Aktivitätston bei verborgenem Chatfenster ist der Sound des Spiels für eine Nachricht, die gesprochen wird, während das Chatfenster verborgen ist.

Diese beiden Kontrollkästchen werden nicht von WowVision gespeichert. Es sind die eigenen Einstellungen des Spiels, daher stimmen die Spielbefehle /tts playline und /tts playactivity und das Menü Sprache immer überein.

## Aufgenommene Stimmenpakete

Manche Alarme spielen Aufnahmen ab, statt TTS zu benutzen: die Himmelsrichtungen („Norden“, „Nordosten“), Zahlen von 1 bis 100 (Gesundheit des Ziels, Entfernung zum Ziel, die Anzahl der Gegner) und so weiter. Diese Aufnahmen gibt es in Stimmenpaketen. Zwei werden mit WowVision geliefert:

- Matthew
- Joanna

Jede Alarmausgabe vom Typ Stimmenalarm hat eine Einstellung, die das Paket auswählt. Sie heißt Stimmenpaket und steht direkt unter dem Kontrollkästchen Aktiviert auf dem Bildschirm der Ausgabe. Aufnahmen werden sofort abgespielt und sind von der Sprachwarteschlange, deiner TTS-Stimme und deiner TTS-Geschwindigkeit unabhängig. Siehe [Alarme](./alerts.md) dazu, wie du Ausgaben auswählst.

## Stimmen für einzelne Alarme

Jede TTS-Ausgabe eines Alarms hat ihre eigene Einstellung Stimme. Solange du dort nichts auswählst, folgt sie einfach der Sprachstimme und zeigt diese Stimme als Wert an. Wählst du eine andere Stimme, benutzt dieser Alarm immer sie. So kannst du zum Beispiel Zielwechsel mit einer Stimme hören und den Chat mit einer anderen.

Die Ansagen, die beim Laufen gemacht werden (neue Punkte auf der Minikarte), werden von der Stimme Nummer 0 des Spiels mit deiner Sprachgeschwindigkeit und Sprachlautstärke gesprochen statt mit deiner Sprachstimme, weil ein Screenreader sie bei jedem Tastendruck abschneiden würde. Auch bei diesem Alarm kannst du die Einstellung Stimme ändern. Dieser Alarm hat keine Einstellung Prioritätsnachricht (unterbricht).

## Eine Screenreader-Stimme verwenden

Reicht deine TTS-Stimme den Text an einen Screenreader weiter, etwa an NVDA über die Stimme SAPI2SR, sorgt WowVision dafür, dass wiederholte Zeilen jedes Mal gesprochen werden und eine neue Zeile die alte abschneidet, genau wie bei einer normalen Stimme.

Du musst nichts einschalten.

## Unterschiede zwischen den Spielversionen

| | Classic Era | TBC und Mists | Retail und WoW: Forever |
|---|---|---|---|
| Sprachwarteschlange | nicht verfügbar | ja | ja |
| Sprachstil (Direkt oder Gepuffert) | ja | nicht verfügbar | nicht verfügbar |
| Leerzeichen um Schrägstriche | ja | ja | nein |
| Stimme, Lautstärke, Geschwindigkeit, Kontrollkästchen für Spielsounds | ja | ja | ja |

## Siehe auch

- [Das WowVision-Menü und die Einstellungen](./menu-and-settings.md)
- [Alarme](./alerts.md)
- [Fehlerbehebung](../getting-started/troubleshooting.md)
