# Gruppen-Gesundheitsmonitor

Verfügbar in Retail und WoW: Forever.

Der Gruppen-Gesundheitsmonitor (Group Health Monitor) sagt dir, welche Mitglieder deiner Gruppe verletzt sind und wie schwer, ohne Prozentzahlen vorzulesen. Ein verletztes Mitglied wird als seine Nummer gesprochen. Die Tonhöhe zeigt, wie schlimm es ist: Je niedriger die Gesundheit, desto höher der Ton. Gesunde Mitglieder bleiben still.

Die Idee und die Nummerierung stammen vom Gesundheitsmonitor von Sku. Der Monitor ist aus, bis du ihn einschaltest.

## Einschalten

1. Drücke Umschalt+F1 (oder gib `/wv` ein), um das WowVision-Menü zu öffnen.
2. Gehe zu Gruppen-Gesundheitsmonitor. Der Eintrag steht in der Hauptliste zwischen Fenster und Minikarten-Scanner, mit G kommst du schnell hin.
3. Drücke Eingabe auf Aktiviert, um ihn einzuschalten.

Alle Einstellungen des Monitors stehen auf demselben Bildschirm, siehe [Einstellungen](#einstellungen) unten. Schaltest du Aktiviert wieder aus, ist der Monitor völlig still, und seine Taste tut dann nichts.

## Die Nummern

- Du selbst bist die 1.
- Deine Gruppenmitglieder sind 2 bis 5, in der Reihenfolge der Gruppe.
- In einem Schlachtzug mit bis zu 10 Mitgliedern sind die Mitglieder von 1 bis 10 nummeriert, in der Reihenfolge der Gruppen, egal in welchen Gruppen sie stehen.
- In einem Schlachtzug mit 11 oder mehr Mitgliedern ist die Nummer eines Mitglieds seine Gruppennummer mal fünf, minus fünf, plus sein Platz in der Gruppe. Gruppe 1 sind die Nummern 1 bis 5, Gruppe 2 die Nummern 6 bis 10, und so weiter bis 40.

Das sind dieselben Nummern, die Sku für dieselben Mitglieder benutzt.

Im Schlachtzug werden die Nummern nur außerhalb des Kampfes neu vergeben, eine Nummer ändert sich also nie mitten im Kampf.

## Du brauchst eine echte Windows-Stimme

Der Monitor spricht mit einer eigenen Stimme, die du in seinen Einstellungen wählst (Stimme). Die Tonhöhe funktioniert nur mit einer echten Windows-Stimme. Eine Brückenstimme zu einem Screenreader, etwa die NVDA-SAPI-Brücke, spricht die Nummern, ignoriert aber die Tonhöhe. Ist die Brücke die Stimme des Monitors, sagt der Monitor das einmal an. Der Monitor braucht gar keinen Screenreader.

Jede Stimme klingt etwas anders, deshalb sind die Tonhöhenstufen für jede Stimme einzeln abgestimmt. Microsoft Hedda, Zira und Katja sind abgestimmt. Jede andere Stimme benutzt die Stufen von Hedda und klingt vielleicht weniger gleichmäßig.

## Was du hörst

Drei Dinge werden gesprochen.

### Die Wiederholung

Jedes Mitglied unter dem Wert Wiederholen unter seiner Rolle wird im Abstand von Wiederholen alle erneut gesprochen. Die Mitglieder kommen nacheinander dran, eine Nummer nach der anderen, und ein Durchgang beginnt nur, solange WowVision sonst nichts zu sagen hat. Der Monitor hält also nie andere Ansagen zurück.

Ein Mitglied über dem Schwellenwert hat einen stillen Durchgang. Ein stiller Durchgang ist kurz, etwa eine Viertelsekunde, ein Durchlauf durch eine gesunde Gruppe von fünf dauert also etwa anderthalb Sekunden.

Jede Rolle hat eigene Werte: Tanks, Heiler, Schadensverursacher und Mitglieder ohne Rolle. Die Standardwerte:

| Rolle | Wiederholen unter | Wiederholen alle |
|---|---|---|
| Tanks | 80 Prozent | 3 Sekunden |
| Heiler | 70 Prozent | 3 Sekunden |
| Schadensverursacher | 60 Prozent | 3 Sekunden |
| Ohne Rolle | 60 Prozent | 3 Sekunden |

Setzt du Wiederholen alle auf 0, ist die Wiederholung für diese Rolle aus.

### Tode

Stirbt ein Mitglied, hörst du einmal seine Nummer und „tot“. Wer schon tot ist, wenn du der Gruppe beitrittst, wird nicht angesagt.

### Die Schnappschuss-Taste

Gruppengesundheit ansagen (Speak Group Health, Standard Alt+H, auf dem Controller der rechte Trigger zusammen mit dem Druck auf den rechten Stick) sagt einmal alle an, in der Reihenfolge der Nummern, mit ihrer aktuellen Tonhöhe. Ein Mitglied mit voller Gesundheit wird als seine Nummer und „voll“ gesagt, wenn Volle Gesundheit ansagen an ist. Tote Mitglieder werden als ihre Nummer und „tot“ gesagt. Nach dem Schnappschuss beginnt die Wiederholung neu.

Ist niemand da, den der Monitor beobachten kann, hörst du „Niemand zu beobachten“.

Um die Taste zu ändern, öffne das WowVision-Menü, gehe zu Benutzeroberfläche, dann Tastenbelegung, oder gib `/wv bind` ein. Siehe [Tastenbelegung](../basics/keybindings.md).

## Einstellungen

Alle stehen auf dem Bildschirm des Gruppen-Gesundheitsmonitors im WowVision-Menü. Die Namen sind so, wie WowVision sie auf einem deutschen Client spricht.

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Aktiviert | Aus | Schaltet den Monitor ein. Aus sagt er nichts, und seine Taste tut nichts |
| Stimme | Die Standardstimme des Spiels | Die eigene Stimme des Monitors. Wähle eine echte Windows-Stimme |
| Sprachgeschwindigkeit | 7 | Wie schnell die Nummern gesprochen werden, von -10 bis 10. Kurze Nummern gehen schnell, fünf verletzte Mitglieder passen also in wenig Zeit |
| Sprachlautstärke | 100 | Die Lautstärke der Monitorstimme, von 0 bis 100 |
| Dich selbst einbeziehen | An | Du zählst als Nummer 1 |
| Gruppe beobachten | An | Die Mitglieder deiner Gruppe beobachten |
| Schlachtzug beobachten | An | Die Mitglieder deines Schlachtzugs beobachten |
| Volle Gesundheit ansagen | An | Der Schnappschuss sagt „voll“ für Mitglieder mit voller Gesundheit |
| Tode ansagen | An | Ein Tod wird angesagt |
| Außerhalb des Kampfes still | Aus | Außerhalb des Kampfes keine Wiederholung und keine Tode. Die Schnappschuss-Taste funktioniert weiter |
| Nur nach einer Änderung wiederholen | Aus | Siehe unten |
| Schlachtzugsgruppen | Alle an | Ein Kontrollkästchen pro Schlachtzugsgruppe, Gruppe 1 bis Gruppe 8. Schalte die Gruppen aus, die du nicht brauchst, zum Beispiel um nur die Gruppen zu beobachten, die du heilst |
| Tanks, Heiler, Schadensverursacher, Ohne Rolle | Siehe Tabelle oben | Jede hat Wiederholen unter (Prozent), von 0 bis 100, und Wiederholen alle (Sekunden, 0 ist aus), von 0 bis 300 |

### Nur nach einer Änderung wiederholen

Ist die Einstellung aus, kommt jedes Mitglied im Intervall seiner Rolle dran, und Stille heißt, das Mitglied ist gesund.

Ist sie an, kommt ein Mitglied nur dran, wenn sich seine Gesundheit seit seinem letzten Durchgang geändert hat. Ein Mitglied, das einmal getroffen wurde, wird einmal gesagt und bleibt dann still, der Monitor ist also viel ruhiger. Heilung und Schaden zählen als Änderungen, aber pro Mitglied und Intervall gibt es höchstens einen Durchgang.

Achte darauf, was Stille bei eingeschalteter Einstellung bedeutet: Sie heißt, dass sich nichts geändert hat, nicht dass alle gesund sind. Ein Mitglied, das bei niedriger Gesundheit bleibt, wird nicht noch einmal gesagt. Prüfe es mit der Schnappschuss-Taste.

## Grenzen

- Der Monitor verfolgt Gesundheitsänderungen nicht im Moment, in dem sie passieren, und kann weder einen Prozentwert nennen noch eingehende Heilung zählen. Die Wiederholung und der Schnappschuss sind seine einzige Stimme.
- Jedes Mitglied kostet einen Durchgang, ob du ihn hörst oder nicht, ein großer Schlachtzug braucht also eine Weile für eine Runde. Beobachte nur die Schlachtzugsgruppen, die du heilst, oder setze Wiederholen alle für die Rollen, die du nicht brauchst, auf 0.
- In Schlachtfeldern und Arenen lässt das Spiel Addons deine Gruppenmitglieder nicht sehen. Der Monitor sagt dann einmal, dass er nicht verfügbar ist („Gruppen-Gesundheitsmonitor hier nicht verfügbar“).

## Beispiel

Du spielst einen Heiler in einer Gruppe aus fünf und willst wissen, wer dich braucht. Du schaltest den Monitor ein und wählst Microsoft Hedda als seine Stimme. Im Kampf hörst du „3“ in hoher Tonlage: Mitglied 3 ist schwer verletzt. Kurz darauf hörst du „2“ in tieferer Lage: Mitglied 2 ist nur leicht verletzt. Der Tank, Nummer 4, bleibt still, er hat also über 80 Prozent. Nach dem Kampf drückst du Alt+H und hörst alle fünf Nummern nacheinander, jede in ihrer Tonhöhe, und „1 voll“ für dich selbst.

Siehe auch [Monitore](monitors.md) für die Monitore, die deine eigenen Zauber und Auren beobachten, und [Alarme](../basics/alerts.md) für die allgemeine Idee der Alarme.
