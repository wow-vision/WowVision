# Minimap

Ein sehender Spieler sieht Questgeber, Händler, Kräuter und Erz als Punkte auf der Minikarte. WowVision kann das Bild der Minikarte nicht ansehen, aber es kann das Spiel fragen, wie jeder Punkt heißt. Genau das tut der Minikarten-Scanner (Minimap Scanner): Er findet die benannten Punkte um dich herum, sortiert sie nach Art, errechnet grob, wo jeder liegt, und führt sie im [Scanner](scanner.md) auf, damit du zu ihnen laufen kannst. Er kann auch neue Punkte ansagen, während du an ihnen vorbeigehst.

Derzeit nicht verfügbar: Eine Änderung von Blizzard hat die Minikarten-Abfragen unbrauchbar gemacht, auf denen der Scanner beruht; er ist deshalb vorerst abgeschaltet. Die Scan-Taste und `/wv mscan` antworten "Wegen Einschränkungen von Blizzard ist der Minikarten-Scanner nicht verfügbar.", und die Lauf-Ansagen laufen nicht. Der Rest dieser Seite beschreibt den Scanner so, wie er arbeitet, wenn das Spiel es zulässt.

(Retail und WoW: Forever.) Der Scanner braucht Minikarten-Funktionen, die nur die neueren Spielclients bieten. Die Classic-Clients haben sie nicht: In Classic Era, The Burning Crusade und Mists of Pandaria antwortet die Scan-Taste "Minikarten-Scanner auf diesem Client nicht verfügbar", und die Laufansagen starten nie.

Hinweis: Die Ansagen des Scanners kommen aus lokalisierten Texten und werden auf einem deutschen Client auf Deutsch gesprochen. Namen von Punkten und Aufspür-Fähigkeiten stammen vom Spiel selbst und erscheinen in der Sprache deines Clients.

## Was er findet

Die Minikarte zeigt nur, was dein Charakter gerade darauf sehen kann. Der Scanner liest genau das, was er findet, hängt also von deinem Aufspüren ab.

- Questgeber. Jeder Punkt eines NPCs, der eine Quest anbietet oder annimmt. Der Scanner sagt dir auch, ob der Questgeber eine neue Quest anbietet oder eine abnimmt (siehe "Questgeber" unten).
- Stadtbewohner, nach Aufspür-Art. Der Scanner schaltet jede deiner Aufspür-Arten der Minikarte kurz ein und merkt sich, welche neuen Namen erscheinen. So sortiert er die Namen in diese Arten: Auktionatoren, Bankiers, Kampfmeister, Flugmeister, Händler (Nahrungs-, Munitions-, Reagenzien- und Gifthändler), Gastwirte, Briefkästen, Klassenlehrer, Lehrer (Berufslehrer), Reparieren, Stallmeister und Andere NPCs (Barbiere, Transmogrifizierer, NPCs für Gegenstandsaufwertung). Du bekommst eine Art nur, wenn dein Charakter diese Aufspür-Art hat. Die meisten hat jeder Charakter.
- Sammelpunkte. Kräuter, Erzadern und Schatztruhen, aber nur, solange die passende Aufspür-Fähigkeit eingeschaltet ist: Kräuter aufspüren (Find Herbs), Mineralien aufspüren (Find Minerals) oder Schätze aufspüren (Find Treasure). Siehe "Sammelpunkte" unten.
- Interessante Orte. Die Städte und Wahrzeichen, die die Minikarte als Pfeile zeichnet, etwa Goldhain oder Sturmwind. Das sind nur Namen ohne Position, weil das Spiel diese Pfeile in einem festen Abstand in Richtung des Ortes zeichnet.
- Anderes Aufspüren. Hast du eine andere Aufspür-Fähigkeit an, zum Beispiel Wildtiere aufspüren oder Humanoide aufspüren, lassen sich ihre Punkte nicht nach Namen sortieren. Sie werden als Unsortiert (Unsorted) in der Kategorie Sammeln des Scanners aufgeführt. Solange eine solche Aufspür-Fähigkeit an ist, kann der Scanner diese Punkte außerdem nicht von Questgebern unterscheiden, sodass Questgeber ohne spezielle Aufspür-Art ebenfalls in Unsortiert landen.

Der Scanner sieht Punkte bis zur Reichweite der Minikarte: etwa 233 Yards im Freien und 150 Yards drinnen. Drinnen zeigt die Minikarte nur das Gebäude, in dem du bist, ein Scan drinnen kennt also nur dieses Gebäude. Das Spiel schaltet die Minikarte nicht nur in Häusern auf ihre Innenansicht, sondern auch in manchen überdachten Straßen, zum Beispiel in Teilen von Sturmwind; WowVision bemerkt das und behandelt es als drinnen.

Namen, die Titel von Quests in deinem Questlog sind, werden weggelassen. Die Minikarte zeigt sie als Gebiet der Quest oder als Pfeil an ihrem Rand, der dorthin zeigt; diese Quests hat WowVision schon mit ihren echten Orten unter Quests, Laufend im [Scanner](scanner.md).

## Scannen: Strg+Umschalt+F

Drücke Strg+Umschalt+F (Minikarte scannen, Scan Minimap), um einmal zu scannen. Die Belegung lässt sich im Fenster für die Tastenbelegung ändern; siehe [Tastenbelegung](../basics/keybindings.md). Du kannst auch `/wv mscan` tippen.

Du hörst "Scanne Minikarte" und das Ergebnis, nach ein bis zwei Sekunden, wenn nichts neu ist, und nach bis zu etwa sechs Sekunden, wenn viel Neues zu verorten ist. Zum Beispiel:

- "Scan fertig, 4 neu: 1 Interessante Orte, 1 Gastwirte, 2 Questgeber"
- "Nichts Neues in der Nähe"

Das Ergebnis zählt nur Einträge, die seit dem letzten Scan neu sind. Sind Einträge, die auf deiner Liste standen, verschwunden (ein Kraut, das du gepflückt hast, eine Quest, die du angenommen hast), nennt das Ergebnis zusätzlich, wie viele weg sind, zum Beispiel "Scan fertig, 1 neu: 1 Kräuter aufspüren, 2 weg". Hast du drinnen gescannt, endet es mit "drinnen, nur dieses Gebäude".

### Bevor du scannst

Ein Scan übernimmt vorübergehend die Minikarte und den Mauszeiger, deshalb müssen einige Dinge stimmen. Sonst verweigert der Scan oder bricht ab:

- Bleib stehen. "Zum Scannen stehen bleiben", wenn du dich bewegst.
- Nicht im Kampf. "Nicht im Kampf".
- Keine Maussteuerung. "Zum Scannen Maussteuerung beenden", wenn du mit der Maus steuerst.
- Schließe jedes Fenster. Der Mauszeiger muss über der Spielwelt ruhen, nicht über einem Fenster. Standardmäßig bewegt der Scan den Mauszeiger selbst in die Bildschirmmitte (siehe Mauszeiger vor dem Scan zentrieren), deshalb blockiert jedes Fenster, das in der Bildschirmmitte offen ist, ihn. Die Meldung nennt das Fenster, das im Weg ist: "Scan abgebrochen, Fenster: " gefolgt vom Namen des Fensters. Schließe das Fenster mit Esc und scanne erneut.
- Sei an einem Ort mit Position. "Hier keine Position" erscheint an Orten, an denen das Spiel dich nicht orten kann, zum Beispiel in manchen Instanzen.
- Nichts am Mauszeiger. Solange ein Zauber darauf wartet, auf dem Boden platziert zu werden, etwas am Mauszeiger hängt oder eine Maustaste gedrückt ist, startet der Scan nicht: "Scan abgebrochen, Zielauswahl" oder "Scan abgebrochen, Maus".

Sobald ein Scan läuft, bewege dich nicht, drehe dich nicht, benutze die Maus nicht und gehe nicht in einen Kampf, bis er fertig ist. Jedes davon bricht ihn ab, mit "Scan abgebrochen, bewegt", "Scan abgebrochen, gedreht", "Scan abgebrochen, Maus", "Scan abgebrochen, Maussteuerung" oder "Scan abgebrochen, Kampf". ("Gedreht" kann nur vorkommen, wenn die Spieloption zum Drehen der Minikarte, englisch Rotate Minimap, an ist.) Nichts Halbfertiges wird behalten, scanne also einfach erneut. Drückst du die Taste während eines laufenden Scans, hörst du "Scan läuft bereits".

Während er läuft, schaltet der Scan kurz deine Aufspür-Arten an und aus und verschiebt und verkleinert die Minikarte, danach stellt er alles wieder her. Währenddessen nimmt die Minikarte keine Klicks an (ein Klick würde die Stelle für deine Gruppe markieren), und ihr Tooltip bleibt verborgen. Questgebiet-Ansagen sind stummgeschaltet, bis er fertig ist. Ist eine Aufspür-Art nicht zurückgekommen, sagt WowVision es dir: "Aufspüren nicht wiederhergestellt" gefolgt von ihrem Namen. Schalte sie im [Scanner](scanner.md) unter Verfolgung wieder ein.

Geht innerhalb des Scans etwas schief, hörst du "Minikarten-Scan fehlgeschlagen".

### Wohin die Ergebnisse gehen

Scan-Ergebnisse werden nicht einzeln gesprochen. Sie gehen in den [Scanner](scanner.md) (F9) und bleiben dort, bis du dich ausloggst oder `/reload` tippst. Der Scan gibt jedem Eintrag eine Position auf wenige Yards genau. In welcher Kategorie ein Eintrag landet:

| Art | Wo du sie im Scanner findest |
|-----|------------------------------|
| Questgeber | Quests, In der Nähe; und NPCs, Questgeber |
| Auktionatoren, Bankiers, Kampfmeister, Flugmeister, Händler, Gastwirte, Briefkästen, Klassenlehrer, Lehrer, Reparieren, Stallmeister, Andere NPCs | NPCs, unter dem Namen der Art |
| Sammelpunkte und Unsortiert | Sammeln |
| Interessante Orte | Interessante Orte |

Jeder so gefundene Eintrag ist in der Liste als gesehen markiert und als drinnen, wenn er in einem Gebäude liegt. Kennt deine Quest-Datenbank bereits einen NPC mit demselben Namen (siehe [Quests](quests.md)), wird der Datenbankeintrag angezeigt und der gesehene weggelassen.

### Questgeber

Ein Questgeber, den der Scan gefunden hat, wird als "gesehen" mit einem von zwei Zuständen vorgelesen:

- Quest verfügbar: Der NPC bietet eine Quest an.
- Abgabe: Du hast eine fertige Quest, und dieser NPC ist der, bei dem sie abgegeben wird. WowVision erkennt das, weil das Spiel die Kartenmarkierung einer fertigen Quest auf ihren Abgabe-NPC verschiebt.

Wird der Questgeber nur wegen der Aufspür-Option für "Quests niedriger Stufe" angezeigt, ist er zusätzlich als niedrigstufig markiert. Das Spiel zeichnet denselben Punkt für eine Quest, die noch ein oder zwei Stufen außer Reichweite ist, "Quest verfügbar" ist also ein guter Hinweis, kein Versprechen.

### Echte Namen bei der Ankunft

Auf den neueren Clients zeigen manche NPCs ihren Titel als Namen auf der Minikarte, zum Beispiel "Kürschnerlehrer" statt des Namens der Person. Kommst du bei einem gesehenen NPC an, indem du einem Beacon aus dem Scanner folgst, sieht WowVision sich die NPCs um dich herum an und nennt, falls einer diesen Titel trägt, seinen echten Namen gefolgt vom Namen, den die Minikarte zeigte, zum Beispiel "Olivia Burnside, Kürschnerlehrer". Der echte Name wird für die Sitzung gemerkt, und Eingabe auf demselben Eintrag spricht ihn später bei der Ankunft erneut.

Das funktioniert nur für NPCs, die das Spiel WowVision lesen lässt: dein Ziel, dein Soft Target und NPCs mit Namensplakette. Das Spiel verbirgt die Namensplaketten freundlicher NPCs standardmäßig. Braucht der Scanner sie, sagt er es dir einmal: "Freundliche NPC-Namensplaketten einschalten, um NPC-Namen zu lernen". Schalte die Option des Spiels für Namensplaketten freundlicher NPCs ein, wenn du echte Namen willst.

### Sammelpunkte

Kräuter, Erz und Schätze werden am Namen erkannt, weil die Minikarte sie alle als schlichte Punkte zeichnet. Der Scanner hat Namenslisten für die Sammelpunkte von Classic Era bis Wrath of the Lich King, auf Englisch, Deutsch und Französisch. Ein Name muss nur einen Listennamen enthalten, sodass auch Varianten wie eine verdorrte Version eines Krauts zählen. Clients in anderen Sprachen benutzen die englischen Namen.

- Kräuter aufspüren listet Kräuter wie Friedensblume, Silberblatt und Königsblut auf.
- Mineralien aufspüren listet Adern und Vorkommen wie Kupfervorkommen und Mithrilvorkommen auf.
- Schätze aufspüren listet Truhen auf (auf dem englischen Client etwa "Solid Chest").

Du musst die Aufspür-Fähigkeit selbst einschalten, entweder über den Aufspür-Knopf der Minikarte im Spiel oder im [Scanner](scanner.md) unter Verfolgung, Minimap-Verfolgung. Der Scan schaltet diese Fähigkeiten nie für dich ein, weil das Einschalten einen Zauber wirkt. Im Scanner erscheinen die Punkte in einer Kategorie Sammeln mit einer Gruppe pro Fähigkeit, benannt nach ihr (zum Beispiel "Kräuter aufspüren").

Punkte aus späteren Erweiterungen stehen nicht in den Listen, deshalb erkennt der Scanner sie nicht als Sammelpunkte. Er behandelt einen solchen Punkt dann wie einen Questgeber und führt ihn unter den Questgebern auf (oder unter Unsortiert, wenn eine andere Aufspür-Fähigkeit wie Wildtiere aufspüren an ist).

## Laufansagen

Während du gehst, läufst oder fliegst, sieht WowVision zweimal pro Sekunde auf die Minikarte und sagt Namen an, die in Reichweite kommen. So hörst du ein Kraut, einen Briefkasten oder einen Questgeber auftauchen, während du unterwegs bist. Es ist standardmäßig eingeschaltet.

Jede Ansage ist der Name, danach Zusätze, wenn sie zutreffen:

- oben oder unten: Der Punkt liegt auf einer anderen Höhe als du, zum Beispiel ein Kraut auf einer Klippe über dir oder ein Punkt unter Wasser.
- drinnen: Der Punkt liegt in einem Gebäude oder unter der Erde.
- die Art: entweder "Questgeber" oder der Name der Aufspür-Art, die ihn zeigt, zum Beispiel "Kräuter aufspüren" oder "Bankiers". Die Art wird erst hinzugefügt, nachdem ein Scan diesen Namen sortiert hat. Bis dahin hörst du nur den Namen.

Beispiele:

- "Friedensblume" (noch kein Scan)
- "Friedensblume, Kräuter aufspüren" (nachdem ein Scan sie sortiert hat)
- "Kupfervorkommen, unten"
- "Olivia Burnside, Bankiers"
- "Marschall McBride, Questgeber"
- "Gastwirt Farley, drinnen, Gastwirte"

Jeder Name wird einmal gesprochen. Er wird erst wieder gesprochen, nachdem du weit genug weggegangen bist, dass der Punkt außer Reichweite war, sodass ein Flackern am Rand der Minikarte ihn nie wiederholt. Konnte WowVision einen Punkt nicht einordnen, zum Beispiel weil er ein Stadtpfeil ist, gilt als Rückfallregel: Nach 30 Sekunden Gehen im Freien, ohne dass der Name in Sicht war, gilt er als weg.

Die Ansagen benutzen die Aufspür-Arten, die du selbst eingeschaltet hast. Sie ändern dein Aufspüren nie. Sie werden übersprungen, solange du stehst, im Kampf bist, mit der Maus steuerst, ein Scan läuft oder ein Fenster unter dem Mauszeiger liegt. Beim ersten Mal in einer Sitzung wird der Mauszeiger außerdem in die Bildschirmmitte bewegt (siehe Mauszeiger vor dem Scan zentrieren).

Die Ansagen benutzen eine eigene Spielstimme, Stimme 0, sofern du keine andere wählst, und nicht die Stimme deines Screenreaders. Screenreader brechen ihre eigene Sprache bei jedem Tastendruck ab, was die Ansagen beim Gehen zerhacken würde. Ändere die Stimme in den Alarmeinstellungen unten.

## Einstellungen

Öffne das WowVision-Menü, dann Minikarten-Scanner. Siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md), wie Einstellungen funktionieren.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Verfolgte Punkte beim Laufen ansagen (Announce Tracked Dots While Walking) | An | Spricht neue Punkte, während du dich bewegst. Schalte es aus, um nur auf Anforderung zu scannen. |
| Mauszeiger vor dem Scan zentrieren (Centre Mouse Cursor Before Scanning) | An | Vor einem Scan und vor der ersten Laufprüfung einer Sitzung wird der Mauszeiger des Spiels für eine Zehntelsekunde in die Bildschirmmitte bewegt, damit die Minikarte darunter gelesen werden kann. Schalte es nur aus, wenn du den Mauszeiger immer selbst in der Mitte hältst. Liegt der Mauszeiger nicht über der Spielwelt, schlägt der Scan mit "Fenster" fehl. |
| Neuer Minikarten-Punkt (New Minimap Dot Alert) | siehe unten | Der Alarm, der die Laufansagen spricht. |

### Neuer Minikarten-Punkt

Das ist ein Standardalarm von WowVision; siehe [Alarme](../basics/alerts.md), wie Alarmeinstellungen funktionieren. Öffne ihn aus den Einstellungen des Minikarten-Scanners.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert | An | Schaltet alle Laufansagen ein oder aus. |
| TTS-Alarm, Aktiviert | An | Spricht den Namen mit einer Sprachausgabe-Stimme. |
| TTS-Alarm, Stimme | Spielstimme 0 | Welche Spielstimme spricht. Sie folgt nicht deiner Einstellung Sprachstimme. Die erste Stimme hat die Nummer 0. |
| Soundalarm, Aktiviert | Aus | Spielt für jeden neuen Punkt einen Ton. |
| Soundalarm, Sound | keiner | Der Ton, der gespielt wird. Wähle einen, bevor du die Ausgabe einschaltest, sonst wird nichts gespielt. |

Derselbe Text wird in beiden Fällen gesprochen. Die Ergebnismeldungen des Scans ("Scan fertig ...") gehören nicht zu diesem Alarm. Sie werden wie jede andere WowVision-Meldung mit deiner normalen Sprachstimme gesprochen.

## Beispiel: die Kräuter um dich herum finden

1. Öffne den Scanner mit F9, gehe zur Kategorie Verfolgung, öffne Minimap-Verfolgung und schalte Kräuter aufspüren mit Eingabe ein. Schließe den Scanner mit Esc. (Ein Kräuterkundiger kann auch den Aufspür-Knopf des Spiels benutzen.)
2. Bleib stehen und drücke Strg+Umschalt+F. Du hörst "Scanne Minikarte", dann zum Beispiel "Scan fertig, 3 neu: 3 Kräuter aufspüren".
3. Drücke F9 und öffne die Kategorie Sammeln, dann Kräuter aufspüren. Jedes Kraut wird mit Entfernung und Richtung aufgeführt, zum Beispiel "Friedensblume, gesehen, 85 Meter, voraus links".
4. Drücke Eingabe auf einem. Das [Navigationsfenster](navigation.md) öffnet sich, auf das Kraut ausgerichtet.
5. Geh los. Während du gehst, wird jedes weitere Kraut, das in Reichweite kommt, angesagt: "Silberblatt, Kräuter aufspüren".
6. Scanne nach dem Pflücken des Krauts erneut. Das Ergebnis lautet "Nichts Neues in der Nähe, 1 weg" oder ähnlich, und das Kraut verschwindet aus der Liste.

## Beispiel: ein Questhub in einem neuen Gebiet

1. Komm in einer Stadt an und bleib stehen. Drücke Strg+Umschalt+F.
2. Du hörst etwa "Scan fertig, 9 neu: 1 Interessante Orte, 1 Gastwirte, 1 Flugmeister, 1 Briefkästen, 5 Questgeber".
3. Drücke F9, öffne Quests, dann In der Nähe. Die gesehenen Questgeber werden nach Entfernung sortiert aufgeführt, der nächste zuerst, jeder markiert mit "gesehen, Quest verfügbar" oder "gesehen, Abgabe". Drücke Eingabe auf einem, um dorthin zu gehen.

## Diagnosebefehle

Du brauchst diese nur für Fehlerberichte.

| Befehl | Was er tut |
|--------|------------|
| `/wv mscan` | Dasselbe wie Strg+Umschalt+F. |
| `/wv mscan list` | Öffnet ein kopierbares Fenster, das jeden gesehenen Eintrag mit Kategorie, Entfernung und Kartenposition auflistet. |
| `/wv mscan clear` | Vergisst jeden gesehenen Eintrag und das Laufgedächtnis. Du hörst "Gesehene Einträge gelöscht". |
| `/wv mscan log` | Zeigt, wie der letzte Scan verlaufen ist, und das Protokoll der Laufansagen. Das Protokoll wird nach `/reload` auch in der Datei der gespeicherten Variablen gesichert. |
| `/wv mscan walk` | Zeigt, was die Laufprüfung gerade im Gedächtnis hat. |
| `/wv mscan raw` | Macht eine unverarbeitete Messung der Minikarte zur Fehlersuche, für den Tag, an dem das Spiel die Benennung der Punkte ändert. Nach /reload steht das Ergebnis in der Datei `WTF\Account\<Account>\SavedVariables\WowVision.lua` (WowVisionDump, minimapRaw), die du einschicken kannst, statt das Fenster zu kopieren. |
| `/wv mscan sku` | Misst die Wege des Scanners, die Minikarte zu lesen, an der Stelle, an der du stehst (dauert etwa eine halbe Minute; bleib stehen): die Reichweite, eine Lesung der verkleinerten Minikarte und die Suche des Scans und der Laufprüfung, jede verglichen mit einer langsamen in voller Größe. Das Ergebnis öffnet sich in einem Fenster und wird als WowVisionDump, minimapSku gespeichert. |

## Verwandte Seiten

- [Scanner](scanner.md), wo die Ergebnisse aufgeführt werden.
- [Navigation und Routen](navigation.md), um zu einem Eintrag zu gehen.
- [Quests](quests.md), wie gesehene Questgeber in die Questlisten kommen.
- [Alarme](../basics/alerts.md) und [Sprache und Ton](../basics/speech.md) für Stimmen.
