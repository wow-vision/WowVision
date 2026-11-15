# Kampf

Diese Seite erklärt, was WowVision tut, wenn ein Kampf beginnt und endet, wie die Kampfalarme und die Gegneranzahl funktionieren und wie das Modul Fehler die roten und gelben Meldungen des Spiels vorliest ("Außer Reichweite", "Fähigkeit ist noch nicht bereit" und so weiter).

Die Kampfeinstellungen findest du im WowVision-Menü (tippe /wv) unter Benutzeroberfläche, dann Kampf. Die Fehlereinstellungen stehen unter Fehler.

## Was passiert, wenn der Kampf beginnt

WoW erlaubt Addons nicht, im Kampf Tastenbelegungen zu ändern oder viele seiner Funktionen zu benutzen. Mit der Einstellung Menüs im Kampf (Menus in Combat, im Menü Benutzeroberfläche, standardmäßig an) arbeiten die Menüs von WowVision im Kampf trotzdem weiter, über ein sicheres Fenster, dem das Spiel das Halten von Tasten erlaubt; siehe [Menüs im Kampf](#menüs-im-kampf) unten. Ohne offenes WowVision-Fenster bleiben alle Tasten beim Spiel: deine Bewegungstasten, Tab für die Zielerfassung und deine Aktionsleisten verhalten sich genau so, wie das Spiel es vorsieht.

Mit ausgeschalteten Menüs im Kampf tritt WowVision im selben Moment zur Seite, in dem ein Kampf beginnt: die Tasten, die es für seine Fenster übernommen hat, gehen an das Spiel zurück, und seine Fenster werden bis zum Ende des Kampfes weder gelesen noch aktualisiert.

In beiden Fällen:

- Tasten, die nichts mit Fenstern zu tun haben, etwa die Schalter der weichen Zielerfassung und die Zielfokus-Tasten, bleiben, wie sie sind. Einige davon können im Kampf nicht alles; siehe unten.
- Mit einem Gamepad in Retail und WoW: Forever bleiben nur die Tasten bei WowVision, die für die Spielwelt gebraucht werden, zum Beispiel der Druck auf den rechten Stick. Siehe [Controller](../controller.md).

Wenn der Kampf endet, nimmt WowVision seine gewohnten Tasten zurück, sobald keine der benötigten Tasten mehr gehalten wird, und macht dort weiter, wo du warst.

Sollte nach einem Kampf einmal ein WowVision-Fenster hängen bleiben, tippe /wv close. Der Befehl schließt jedes WowVision-Fenster.

### Was auf das Ende des Kampfes wartet

- Das Ein- oder Ausschalten der weichen Zielerfassung und die Einstellung Soft Target wird festes Ziel: WowVision sagt "nach dem Kampf" und übernimmt die Änderung, wenn der Kampf endet. Siehe [Zielerfassung](targeting.md).
- Das Speichern eines virtuellen Fokus mit /focus1 bis /focus5: wird mit der Meldung "Virtueller Fokus kann im Kampf nicht gesetzt werden." abgelehnt.
- Eine neue Taste im Fenster für die Tastenbelegung aufzunehmen: WowVision sagt "Nicht im Kampf".
- Der Minikarten-Scan und ähnliche Aktionen: Auch sie sagen "Nicht im Kampf". Siehe [Minimap](minimap.md).

### Retail und WoW: Forever: im Kampf verborgene Werte

(Nur Retail und WoW: Forever) Blizzard verbirgt eine Reihe von Spielwerten vor Addons, besonders im Kampf und in Instanzen. Diese Einschränkungen merkst du in WowVision:

- Die Gesundheit deines Ziels ist nicht lesbar, deshalb gibt es keine Lebensüberwachung. Nimm stattdessen die Kampf-Audiohinweise des Spiels (Combat Audio Alerts) in seinen Barrierefreiheit-Optionen: Sie können die Gesundheit deines Ziels ansagen, auch im Kampf. Siehe [Zielerfassung](targeting.md).
- Deine Bewegungsgeschwindigkeit ist im Kampf verborgen, deshalb kann die Wanderkennung nur bemerken, dass du stehst, nicht aber, dass du verlangsamt bist ([Bewegung und Orientierung](movement.md)).
- Schlachtzugmarkierungen werden als Zahlen gesprochen.
- Buffs und Debuffs werden im Kampf aus ihren Tooltips gelesen ([Puffer](../information/buffers.md)).

Classic Era, The Burning Crusade und Mists of Pandaria haben diese Einschränkungen nicht.

## Menüs im Kampf

### Öffnen und schließen

Die Tasten, die ein WowVision-Fenster öffnen, wirken im Kampf wie außerhalb: das WowVision-Menü (Umschalt+F1), der Chat (Umschalt+F3), der Scanner (F9), die Navigation (F10) und die Aktionsleisten (Umschalt+F4). Öffnet eine davon ein Fenster, bekommt WowVision seine Menütasten: die Pfeiltasten, Tab und Umschalt+Tab, Strg+Tab, Pos1 und Ende, Eingabe und Rücktaste, Umschalt+F10, Leertaste und Esc. Ein Fenster, das schon offen war, als der Kampf begann, behält sie.

Esc schließt die eigenen Fenster von WowVision und gibt sofort alle Tasten an das Spiel zurück. Die Fenster des Spiels (das Questlog, die Charakteransicht) darf ein Addon im Kampf nicht schließen; sie bleiben auf dem Bildschirm und sind nach dem Kampf wieder da.

Bewegen, Lesen, Reiter und Ebenen funktionieren wie außerhalb des Kampfes. Eingabe und Rücktaste wirken auf die eigenen Einträge von WowVision (Einstellungen, das Menü, Chat, Wegpunkte). Auf einem Eintrag, dessen Klick ein Klick auf einen Knopf des Spiels ist, sagen sie „Im Kampf nicht verfügbar“, außer wo diese Seite sie nennt.

### Deine Taschen (B)

Deine Spieltaste für Alle Taschen öffnen oder Rucksack öffnen öffnet im Kampf alle deine Taschen wie außerhalb, und WowVision landet auf dem ersten Platz deines Rucksacks. Im Kampf lesen sich die Taschen als Liste nach Tasche und Platz: jede Tasche, die du trägst, Platz 1 zuerst, leere Plätze eingeschlossen, so bleibt jede Position den ganzen Kampf lang derselbe Platz. Die Gitterform ist hier eine Liste.

- Pfeil nach oben und unten bewegen innerhalb einer Tasche, Pos1 und Ende zu ihrem ersten und letzten Platz. Tab und Umschalt+Tab gehen zur nächsten und vorigen Tasche.
- Die Rücktaste benutzt den Gegenstand wie sein Rechtsklick: einen Trank, Essen, einen Verband; anlegbare Gegenstände werden angelegt.
- Eingabe nimmt den Gegenstand auf, legt den gehaltenen ab oder tauscht zwei Gegenstände. Dafür braucht es die eigenen Platzknöpfe des Spiels, die WowVision lernt, solange deine Taschen außerhalb des Kampfes offen sind: öffne nach einem Login oder Neuladen deine Taschen zweimal vor deinem ersten Kampf. Bis dahin sagt Eingabe „Um im Kampf Gegenstände aufzuheben, öffne deine Taschen außerhalb des Kampfes noch einmal“. Gibt das Spiel den Plätzen im Kampf einmal andere Knöpfe, hörst du „Taschenanordnung geändert, Enter hebt vielleicht den falschen Gegenstand auf“.
- Die Leertaste liest den Tooltip des Platzes.
- Noch einmal B oder Esc schließt die Taschen und gibt die Tasten zurück.

Beginnt ein Kampf, während du auf einem Taschenplatz stehst, geht es von diesem Platz aus weiter. Kommst du aus einem anderen Fenster zu deinen offenen Taschen zurück, ohne durch sie zu gehen, werden sie gelesen, aber die Tasten gehören ihnen noch nicht: du hörst „Zum Benutzen von Gegenständen drücke“ mit deiner Taschentaste, und diese Taste geht wieder durch sie, von dort, wo du warst.

### Deine Ausrüstung (C)

Das Spiel erlaubt Addons nicht, im Kampf die Charakteransicht zu öffnen, deshalb öffnet deine Spieltaste für Charakterinfo stattdessen eine WowVision-Liste deiner Ausrüstungsplätze, in der Reihenfolge der Charakteransicht.

- Die Rücktaste benutzt den Gegenstand im Platz, zum Beispiel ein Schmuckstück mit Benutzen-Effekt.
- Eingabe nimmt den Gegenstand auf oder legt den gehaltenen an, soweit das Spiel es im Kampf erlaubt (Waffen ja, Rüstung nein).
- Die Leertaste liest den Tooltip. Noch einmal C oder Esc schließt die Liste; sie schließt sich auch von selbst, wenn der Kampf endet.

### Das Kontextmenü in Taschen und Ausrüstung (Umschalt+F10)

Umschalt+F10 auf einem Platz öffnet seine zwei Einträge: den Linksklick und den Rechtsklick, mit dem, was sie tun, zum Beispiel „Aufheben, Linksklick“ und „Benutzen, Rechtsklick“. Pfeil nach oben und unten wählen, Eingabe führt den Eintrag aus, Esc, Pfeil nach links oder Umschalt+F10 schließen das Menü, und du bist wieder auf dem Platz.

### Zwischen Fenstern wechseln (Strg+Tab)

Mit offenen Taschen oder offener Ausrüstung geht Strg+Tab von den Taschen zur Ausrüstung zu deinen anderen Fenstern und reihum; jede Liste wird auf dem Platz wieder aufgenommen, den du verlassen hast. Von Taschen oder Ausrüstung aus geht jeder Besuch zum nächsten deiner anderen Fenster weiter, so kommen alle der Reihe nach dran; Strg+Umschalt+Tab geht andersherum. Ohne anderes Fenster hörst du „Kein anderes Fenster“, und das nächste Strg+Tab geht weiter.

Ein Fenster, das sich von selbst öffnet, während du durch Taschen oder Ausrüstung gehst, etwa die Frage „diesen Gegenstand zerstören?“, bleibt dahinter, damit deiner Liste die Tasten nicht genommen werden: du hörst es und „Zum Antworten drücke“ mit deiner Strg+Tab-Taste. Die Ausnahme ist die Taste Gegenstand am Mauszeiger zerstören (Entf): mit einem Gegenstand am Mauszeiger holt sie die Zerstören-Frage sofort nach vorn. Ohne etwas am Mauszeiger lässt Entf deine Tasten, wo sie sind.

### Popups im Kampf

Ein Popup, das sich im Kampf von selbst öffnet und auf eine Antwort wartet (eine Gruppeneinladung, auch eine, die nach deiner Rolle fragt, eine Beschwörung, eine Wiederbelebung, der Tod, der Bereitschaftscheck), nimmt dir die Tasten nicht: es geht sofort nach Ausstehend, und du hörst seinen Namen, zum Beispiel „Gruppeneinladung, Ausstehend“. Öffne das WowVision-Menü (Umschalt+F1); das Popup ist sein erster Eintrag, und Eingabe holt es nach vorn. Die Knöpfe der Einladungen, Beschwörungen, Wiederbelebungen, des Todes-Kastens und der Zerstören-Fragen funktionieren dort, weil sie nichts aufrufen, was das Spiel im Kampf schützt; die Knöpfe aller anderen Popups, darunter der Bereitschaftscheck und die Rollenabfrage der Dungeonsuche, sagen „Im Kampf nicht verfügbar“. Die Taste Gruppeneinladung annehmen und /wv accept funktionieren ebenfalls weiter. Siehe [Ausstehend](../windows/system.md#ausstehend-eine-frage-die-wartet).

Ein Popup, das auf etwas antwortet, das du gerade getan hast, etwa „diesen Gegenstand an dich binden?“, kommt nach vorn. Hielt WowVision in dem Moment die Tasten nicht, hörst du „Zum Antworten drücke Umschalt-F1“; diese Taste landet darauf. Esc tut dort, was das Esc des Spiels tut, in zwei Schritten: das erste Esc gibt die Tasten an das Spiel zurück, ein zweites Esc ist das des Spiels und bricht ein Popup ab, das auf Esc hört. Ein Popup, das wartet, legt schon das erste Esc nach Ausstehend beiseite.

### Handel im Kampf

Im Kampf sagen die Knöpfe des Handelsfensters (Handel, Abbrechen und die Handelsplätze) „Im Kampf nicht verfügbar“. Nimm den Handel mit der Taste Handel annehmen (Alt+Strg+T) an: sie ist eine Tastenbelegung des Spiels selbst und wirkt deshalb auch im Kampf. Siehe [Tastenbelegung](../reference/keybindings.md).

### Einstellungen und Tasten

- Menüs im Kampf (Menus in Combat, im Menü Benutzeroberfläche, an): aus tritt WowVision im Kampf zur Seite wie oben beschrieben.
- Jede Menütaste hat im Fenster für die Tastenbelegung eine eigene Taste für den Kampf, benannt „Im Kampf:“ und die Taste, zum Beispiel „Im Kampf: Hoch“. Leer gelassen (die Vorgabe) benutzt der Kampf die Tasten der Menütaste selbst; lege dort eine fest, wenn du im Kampf eine andere Taste willst, zum Beispiel weil du dich mit den Pfeiltasten bewegst.
- /wv combatkeys gibt aus, was die Kampftasten gerade tun, zur Fehlersuche. WowVision führt von selbst ein Protokoll darüber; siehe [Slash-Befehle](../reference/commands.md).

## Dein eigenes Leben und deine Ressourcen

WowVision sagt dein eigenes Leben und dein Mana nicht von selbst an. Du liest beides jederzeit im Puffer Allgemein ab:

1. Drücke Alt+Pfeil runter (ohne offenes Fenster). Die ersten beiden Zeilen des Puffers Allgemein sind dein Leben, zum Beispiel "250 / 500 Leben", und deine Hauptressource, zum Beispiel "50 / 100 MANA".
2. Mit Alt+Pfeil hoch gehst du zurück zur ersten Zeile.

Die Zeilen sind immer aktuell, auch im Kampf. Eine zweite Ressource wie Kombopunkte, Heilige Kraft oder Seelensplitter kannst du als eigene Zeile hinzufügen; siehe [Eine andere Kraft als deine Hauptkraft beobachten](../information/buffers.md#eine-andere-kraft-als-deine-hauptkraft-beobachten). Den ganzen Puffer Allgemein beschreibt [Die Standardeinrichtung: die Gruppe Allgemein](../information/buffers.md#die-standardeinrichtung-die-gruppe-allgemein).

In Retail und WoW: Forever kann der [Gruppen-Gesundheitsmonitor](../information/group-health.md) dich einbeziehen: Mit Dich selbst einbeziehen bist du Nummer 1 und wirst angesagt, wenn du verletzt bist.

## Kampfalarme

Zwei Alarme sagen dir, wann ein Kampf beginnt und endet. Sie stehen unter Benutzeroberfläche, Kampf:

| Alarm | Standard | Was du hörst |
|-------|----------|--------------|
| Kampf-gestartet-Alarm (Combat Started Alert) | An, gesprochen | "Kampf begonnen" |
| Kampf-beendet-Alarm (Combat Ended Alert) | An, gesprochen | "Kampf beendet" |

Jeder hat eine Ausgabe TTS-Alarm mit den üblichen Einstellungen (siehe [Alarme](../basics/alerts.md)): Du kannst den ganzen Alarm mit Aktiviert ausschalten, die gesprochene Ausgabe ausschalten oder eine andere Stimme dafür wählen. Für diese beiden Alarme gibt es nur die gesprochene Ausgabe.

## Gegneranzahl

In einem Kampf sagt WowVision jedes Mal, wenn sich die Zahl ändert, wie viele Gegner daran beteiligt sind: "1", "3", "2" und "0", wenn der letzte weg ist. So weißt du schnell, ob der Pull schiefgegangen ist, ohne eine Liste zu lesen.

### Einstellungen

Alle unter Benutzeroberfläche, Kampf.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Gegneranzahl-Alarm, Aktiviert (Enemy Count Alert) | An | Schaltet die Gegneranzahl ein oder aus |
| Gegneranzahl-Alarm, TTS-Alarm | An | Spricht die Zahl |
| Gegneranzahl-Alarm, Stimmenalarm | Aus | Spielt stattdessen eine aufgenommene Zahl aus deinem Stimmenpaket ab |
| Gegner zählen (Count Enemies) | Die dich oder deine Gruppe angreifen | Die dich oder deine Gruppe angreifen zählt jeden Gegner, gegen den du, dein Begleiter oder ein Gruppenmitglied kämpft; in einer Gruppe, solange du, dein Begleiter oder ein Gruppenmitglied im Kampf ist, auch jeden Gegner im Kampf, den niemand außerhalb deiner Gruppe angeschlagen hat. So zählt ein Kampf, den deine Gruppe ohne dich beginnt, sofort mit. Die dich angreifen zählt nur Gegner, die dich als Hauptziel haben (die, deren Aggro du hältst) |
| Nur Elitegegner zählen (Count Elite Enemies Only) | Aus | Lässt normale Monster weg. Elites, seltene Elites und Weltbosse zählen weiterhin |
| Kontrolleffekte ansagen (Announce Crowd Control) | Aus | Experimentell. Mit Zaubernamen oder Ohne Namen zählt die Zahl nur die Gegner, die noch frei kämpfen, und CC wird getrennt angesagt (siehe unten). Aus behält die einfache Zahl |
| Kontrolle-beendet-Alarm, Klangalarm (Crowd Control Ended Alert) | An | Der kurze Klang, wenn ein CC endet, bei eingeschaltetem Kontrolleffekte ansagen |

### Namensplaketten sind Pflicht

Die Zahl stammt von den Namensplaketten der Gegner, den Gesundheitsbalken, die ein sehender Spieler über Gegnern sieht. Ohne Namensplaketten gibt es nichts zu zählen. Schalte die Namensplaketten für Feinde in den Optionen des Spiels ein (die Option Gegnerische Einheiten im Bereich Namensplaketten; in manchen Spielversionen sind sie standardmäßig aus). Gehst du mit eingeschaltetem Alarm und ausgeschalteten Gegner-Namensplaketten in einen Kampf, sagt WowVision einmal: "Schalte die Namensplaketten für Feinde ein, um Gegner zu zählen". Das wiederholt sich erst wieder, nachdem du die Oberfläche neu geladen oder dich neu eingeloggt hast.

Noch ein paar Dinge, die du wissen solltest:

- Ein Gegner zählt nur, solange seine Namensplakette existiert, also innerhalb der Namensplaketten-Reichweite des Spiels (etwa 45 Yards in WoW: Forever).
- Schaltest du die Namensplaketten-Optionen Minor und Minions im Spiel ein (Minor und Minions heißen sie im englischen Spiel; in der deutschen Oberfläche suche nach den entsprechenden Optionen für unwichtige Gegner und Diener), zählen auch kleine Trashmonster und gegnerische Begleiter.
- Nur Gegner zählen, die dir feindlich gesinnt sind, leben und im Kampf sind. Neutrale Monster zählen, sobald sie kämpfen.
- Auch gegnerische Spieler zählen. In einer Gruppe, solange du, dein Begleiter oder ein Gruppenmitglied im Kampf ist, zählt jeder gegnerische Spieler im Kampf in deiner Nähe, auch einer, der gegen jemanden außerhalb deiner Gruppe kämpft: Das Spiel markiert Spieler nie als angeschlagen. Im PvP bekommst du so den weiteren Überblick, alle gegnerischen Spieler, die um dich herum kämpfen, so wie die Namensplaketten sie einem sehenden Spieler zeigen.
- Eine Zahl, die andere Sprachausgabe verworfen hat, bevor sie gesprochen wurde (ein unterbrechender Alarm wie ein Zielwechsel leert die Sprachwarteschlange), wird einmal wiederholt, wenn innerhalb von 5 Sekunden keine neuere Zahl kam und sich die Zahl inzwischen nicht geändert hat. Wiederholt wird nur die gesprochene Zahl: Eine Zahl aus dem Sprachpaket wird sofort abgespielt und nie verworfen. Eine Zahl, die abgeschnitten wurde, während sie schon gesprochen wurde, wird nicht wiederholt. Nicht in Vanilla.
- Eine neue Zahl wird erst angesagt, nachdem sie 0,3 Sekunden lang Bestand hatte. Ein Gegner, der aus der Reichweite und wieder zurück flackert, wird also nicht doppelt gesprochen. Die Wartezeit beginnt bei jeder Änderung neu, so wird eine Gruppe, die nacheinander dazukommt, als eine Zahl gesagt, 0,3 Sekunden nach dem letzten Gegner. Während eines Kampfes wird die Zahl außerdem jede Sekunde neu geprüft, wodurch Monster erfasst werden, die leise sterben oder aufgeben.

### Kontrolleffekte ansagen

Diese Auswahl ist experimentell und standardmäßig aus. Ist sie an, verlässt ein verwandelter, betäubter oder verängstigter Gegner die Zahl, und du hörst so knapp wie möglich, was mit ihm geschieht:

- Ein CC trifft: nur sein Name, in der Sprache deines Spiels. Bei Monstern ist das der Zauber, wie ihn das CC-Symbol auf ihrer Namensplakette zeigt ("Verwandlung", "Frostnova"); bei gegnerischen Spielern das Wort des Spiels ("Betäubt"). Die Zahl ist jetzt um eins kleiner; sie wird nicht noch einmal gesagt.
- Ein CC endet, während der Gegner noch im Kampf ist: ein kurzer Klang, dann die neue Zahl.
- Nur noch kontrollierte Gegner sind übrig: "0" und ihre Namen, zum Beispiel "0, Verwandlung", damit es nicht für das Ende des Kampfes gehalten wird.
- Ein kontrollierter Gegner stirbt: für sich allein nichts; die Zahl oder das Kampfende sagen den Rest.
- Ein Kill im selben Moment wie ein CC sagt beides: "1, Frostnova".

Ein typischer Pull: "3", "Verwandlung" (einer verwandelt), "1", "0, Verwandlung" (die anderen sind tot), der Klang und "1" (die Verwandlung ist gebrochen), dann "0".

Als CC zählt, was das Spiel in die CC-Liste auf der Namensplakette eines Gegners setzt: Betäubungen, Furcht, Verwandlungen, Wurzeln und Ähnliches, keine Verlangsamungen. In WoW: Forever ist diese Liste im Kampf für Addons verborgen; WowVision folgt dann dem CC-Filter des Spiels, der auch eine Verlangsamung zählen kann. In Retail sind die Auren von Gegnern im Kampf und in Instanzen für Addons verborgen, und jeder Gegner zählt als frei.

Ein oder zwei gleichzeitige CCs werden nacheinander genannt ("Verwandlung, Frostnova"). Drei oder mehr auf einmal, meist ein Flächenzauber, werden zu einer Zahl: "3 Frostnova", wenn alle Namen gleich sind, sonst "3 kontrolliert". In WoW: Forever sind die Namen im Kampf für Addons verborgen: WowVision kann sie sprechen, aber nicht vergleichen, daher heißt es dort bei drei oder mehr immer "kontrolliert". Dasselbe gilt für "0" mit drei oder mehr kontrollierten Gegnern: "0, 3 kontrolliert". Wo kein Name lesbar ist, sagt WowVision "kontrolliert".

Ohne Namen lässt die Namen weg, die lang sein können ("Hammer der Gerechtigkeit"): ein CC sagt "kontrolliert", zwei oder mehr auf einmal "2 kontrolliert". Der Klang beim Ende eines CC funktioniert in beiden gleich. Das Stimmenpaket spielt nur die Zahlen.

### Beispiel

Du ziehst in einem Dungeon drei Monster. Du hörst "Kampf begonnen", dann "3". Du tötest eines: "2". Dein Tank nimmt dir die anderen beiden ab, du stellst Gegner zählen auf Die dich angreifen, und die Zahl fällt auf "0", obwohl sie noch leben, weil keines mehr dich angreift. Stelle es zurück auf Die dich oder deine Gruppe angreifen, um den ganzen Kampf zu verfolgen. Wenn der letzte Gegner stirbt, hörst du "0" und "Kampf beendet".

## Fehler- und Infomeldungen

Wenn das Spiel dir oben auf dem Bildschirm eine rote Meldung zeigt ("Außer Reichweite.", "Fähigkeit ist noch nicht bereit.", "Du bist zu weit entfernt.") oder eine gelbe Infomeldung, spricht das Modul Fehler sie aus. Es funktioniert auch in Retail, wo das Spiel normalerweise einige davon vom Bildschirm verbirgt (außer Reichweite, nicht genug Wut, Energie oder Fokus sowie Abklingzeit-Meldungen für Zauber und Fähigkeiten): WowVision hört die Meldung selbst und sagt sie trotzdem an. Es funktioniert auch dann weiter, wenn ein anderes Addon die Fehleranzeige des Spiels verbirgt. Die Meldungen erscheinen in der Sprache deines Spielclients.

Jede Meldung läuft durch einen Filter, in dem du Meldung für Meldung entscheidest, ob sie gesprochen, als Ton abgespielt oder stummgeschaltet wird.

### Einstellungen

Öffne Fehler im WowVision-Menü.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Fehler ansagen (Alarm), Aktiviert (Announce Errors) | An | Der Hauptschalter. Ist er aus, wird keine Spielmeldung gesprochen |
| Fehler ansagen, TTS-Alarm | An | Wie die unter "Immer gesprochen" unten aufgeführten Meldungen gesprochen werden |
| Wiederholungsverzögerung (Repeat Delay) | 2 | Sekunden, 0 bis 30. Dieselbe Meldung wird in dieser Zeit höchstens einmal gesprochen. Das verhindert, dass "Außer Reichweite" stottert, solange du eine Taste gedrückt hältst. 0 schaltet die Verzögerung aus |
| Filter pro Fehler (Per-Error Filter) | | Öffnet den als Nächstes beschriebenen Filterbildschirm |

Hältst du eine Taste gedrückt, wird die Meldung trotzdem wiederholt, und zwar einmal im Abstand der eingestellten Wiederholungsverzögerung. Die Verzögerung zählt ab dem Zeitpunkt, an dem die Meldung zuletzt tatsächlich gesprochen wurde.

### Der Filter pro Fehler

Wähle Filter pro Fehler, um eine Liste aller Fehler- und Infomeldungen zu sehen, denen du bisher begegnet bist. Jede ist eine Schaltfläche. Ihr Name ist der Meldungstext, wobei Namen und Zahlen durch "..." ersetzt werden, damit alle Varianten einer Meldung einen gemeinsamen Eintrag haben. Zum Beispiel ist jede Meldung "... ist gestorben." ein Eintrag, egal wie der Name lautet. Nach dem Namen sagt dir WowVision, was der Eintrag tut: Sprache, Sprache und Sound, Sound oder Stumm.

Drücke Eingabe auf einem Eintrag, um seine Einstellungen zu öffnen:

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert | An | Aus schaltet diese Meldung komplett stumm |
| TTS-Alarm | An | Spricht die Meldung. Hat die üblichen Einstellungen Prioritätsnachricht (unterbricht) und Stimme |
| Soundalarm | Aus | Spielt einen Ton, wenn die Meldung erscheint. Schalte ihn ein und wähle den Ton mit Sound |

Das erste Element des Filterbildschirms ist Alle bekannten Fehler anzeigen (standardmäßig aus). Normalerweise erscheint ein Eintrag erst, nachdem dir die Meldung einmal passiert ist. Schaltest du das ein, enthält die Liste auch jede Meldung, die das Spiel kennt, sodass du eine im Voraus stummschalten kannst. Die Liste ist alphabetisch sortiert; in Menüs kannst du die ersten Buchstaben eines Eintrags tippen, um dorthin zu springen.

Der Filter gilt für alle deine Charaktere: Eine Meldung, die auf einem Charakter stummgeschaltet wurde, bleibt auf allen stumm.

Beispiel: "Fähigkeit ist noch nicht bereit" stummschalten, aber "Außer Reichweite" behalten.

1. Öffne das Menü mit /wv, gehe zu Fehler, dann Filter pro Fehler.
2. Suche Fähigkeit ist noch nicht bereit. (steht sie nicht in der Liste, schalte zuerst Alle bekannten Fehler anzeigen ein) und drücke Eingabe.
3. Schalte Aktiviert aus und verlasse den Bildschirm mit Esc. Der Eintrag heißt jetzt "Stumm".
4. Lass Außer Reichweite. in Ruhe. Sie wird weiterhin gesprochen.

### Immer gesprochen, nicht filterbar

- Meldungen, die das Spiel in einer Form übergibt, die sich nicht untersuchen lässt (eine Retail-Einschränkung), werden so, wie sie sind, über den Alarm Fehler ansagen gesprochen, weil der Filter sie nicht erkennen kann.
- Lua-Fehler, siehe unten.

### Lua-Fehler

Das eigene Lua-Fehlerfenster von WoW lässt sich mit einem Screenreader nicht benutzen. Ist Fehler ansagen an, spricht WowVision "Lua-Fehler:" gefolgt von der Meldung, wenn ein Addon-Fehler auftritt. Derselbe Fehler wird fünf Sekunden lang nicht erneut gesprochen, damit ein Fehler, der in jedem Frame wiederkehrt, die Sprachausgabe nicht überflutet. Die Fehler werden gesammelt, bis zu den letzten 20, und bleiben über /reload und Ausloggen hinweg erhalten.

## Diagnosebefehle

| Befehl | Was er tut |
|--------|------------|
| /wv soft | Liest die Werte der weichen Zielerfassung vor (siehe [Zielerfassung](targeting.md)) |
| /wv errors | Zeigt die letzten Lua-Fehler mit ihrem Stack in einem Fenster, aus dem du kopieren kannst, und spricht die neueste Meldung. Ist das Addon BugSack/BugGrabber installiert, werden dessen Fehler aus dieser Sitzung zuerst aufgeführt |
| /wv errors all | Dasselbe, einschließlich früherer Sitzungen, wenn BugGrabber installiert ist |
| /wv errors clear | Leert die Fehlerliste |
| /wv close | Schließt jedes WowVision-Fenster |
| /wv keylog | Schaltet ein Protokoll ein, das ausgibt, wann WowVision seine Navigationstasten übernimmt und freigibt. Benutze es bei einem Fehlerbericht, wenn eine Bewegungstaste nach dem Öffnen eines Fensters oder dem Ende eines Kampfes festzuhängen scheint |

Wenn du einen Fehler meldest, ist /wv errors das Erste, was du ausprobieren solltest.

## Verwandte Seiten

- [Zielerfassung](targeting.md) für Zielansagen und Fokustasten.
- [Bewegung und Orientierung](movement.md) für Fallen, Wände und ähnliche Alarme, die auch im Kampf funktionieren.
- [Alarme](../basics/alerts.md) zum Konfigurieren jedes Alarms.
