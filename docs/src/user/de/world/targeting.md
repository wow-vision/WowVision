# Zielerfassung

WowVision sagt dir an, was du im Ziel hast, lässt dich bis zu fünf "virtuelle Fokusziele" auf Tasten legen, kann die weiche Zielerfassung des Spiels ein- und ausschalten und öffnet mit einer einzigen Taste das Menü deines Ziels. Diese Seite behandelt alles davon: die Ansagen, die Tasten und die Einstellungen.

Alle Einstellungen zur Zielerfassung findest du im WowVision-Menü (tippe /wv) unter Zielerfassung. Die Zielerfassung funktioniert in jeder unterstützten Spielversion gleich, abgesehen von den Hinweisen für Retail und WoW: Forever. Die weiche Zielerfassung braucht Unterstützung vom Spiel selbst; fehlt in deiner Version eine ihrer Einstellungen, listet /wv soft sie als "nicht verfügbar" auf.

Hinweis: Die Beispiele unten zeigen, was du auf einem deutschen Client hörst. Wo eine Ansage noch nicht übersetzt ist, ist das beim Beispiel vermerkt (Ansage auf Englisch).

## Die Zieltasten im Überblick

| Taste | Name der Belegung | Was sie tut |
|-------|-------------------|-------------|
| Umschalt+I | Weiches Ziel Feind (Soft Target Enemy) | Schaltet die weiche Zielerfassung für Feinde ein oder aus |
| Umschalt+P | Weiches Ziel Freund (Soft Target Friend) | Schaltet die weiche Zielerfassung für Freunde ein oder aus |
| Umschalt+O | Weiches Ziel Interaktion (Soft Target Interact) | Schaltet die weiche Zielerfassung für Interaktion ein oder aus |
| Alt+T | Zielmenü öffnen (Open Target Menu) | Öffnet das Menü deines aktuellen Ziels |
| standardmäßig unbelegt | Zielfokus 1 bis Zielfokus 5 (Target Focus 1 bis 5) | Erfasst die Einheit, die du in diesem virtuellen Fokusplatz gespeichert hast |

Du kannst Tasten ändern oder hinzufügen im Fenster für die Tastenbelegung (WowVision-Menü, Benutzeroberfläche, Tastenbelegung); siehe [Tastenbelegung](../basics/keybindings.md). Die vollständige Liste aller Tasten steht in der [Tastenreferenz](../reference/keybindings.md).

Ist gleichzeitig das Addon Sku geladen, überlässt WowVision die Tasten der weichen Zielerfassung, die Zielfokus-Tasten und die Befehle /focus1 bis /focus5 Sku und registriert sie nicht. Alt+T ist davon nicht betroffen.

## Dein Ziel hören (festes Ziel)

Ein "festes Ziel" ist das Ziel, das du auf dem normalen Weg bekommst: per Mausklick, mit Tab, per Makro oder mit /target. Immer wenn dein festes Ziel auf eine neue Einheit wechselt, liest WowVision sie vor.

Du hörst denselben Text, den das Spiel im Mouseover-Tooltip dieser Einheit zeigt: Name, Stufe, Kreaturentyp, Gilde und so weiter. Trägt die Einheit eine Schlachtzugmarkierung, steht der Name der Markierung vorne; du hörst zum Beispiel "Totenkopf Gnollschläger, Stufe 12 ...". Die Markierungen sind Stern, Kreis, Diamant, Dreieck, Mond, Quadrat, X und Totenkopf.

Einige Details:

- Das Ziel zu löschen bleibt stumm. Nur ein neues Ziel wird angesagt.
- Die Ansage unterbricht alles, was gerade gesprochen wird. So entsteht beim schnellen Zielwechsel nie ein Stau alter Namen.
- Befindet sich die Einheit, die du erfasst, bereits im Kampf mit dir, spielt zusätzlich ein kurzer Ton. WowVision entscheidet das anhand der Bedrohungslisten von dir, deinen Gruppen- oder Schlachtzugsmitgliedern und deren Begleitern. Es funktioniert also auch, wenn nur ein Gruppenmitglied oder ein Begleiter gegen die Einheit kämpft.
- (Nur Retail und WoW: Forever) Das Spiel verbirgt vor Addons, welche Schlachtzugmarkierung eine Einheit trägt. WowVision sagt dir trotzdem, dass es eine gibt, nennt aber statt des Namens ihre Nummer: 1 ist Stern, 2 Kreis, 3 Diamant, 4 Dreieck, 5 Mond, 6 Quadrat, 7 X und 8 Totenkopf. In manchen Situationen verbirgt das Spiel auch die Identität einer Einheit vor Addons; die Ansage funktioniert weiter, weil der Tooltip-Text so an die Sprachausgabe weitergereicht wird, wie das Spiel ihn liefert.

### Einstellungen für Ansagen des festen Ziels

Öffne Zielerfassung, dann Festes Ziel (Hard Target). Es gibt drei Alarme, jeweils mit den üblichen Alarmeinstellungen (siehe [Alarme](../basics/alerts.md)).

Zielwechsel (Target Change) ist die oben beschriebene Ansage.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert (Alarm) | An | Schaltet den ganzen Alarm Zielwechsel ein oder aus |
| TTS-Alarm | An | Spricht das Ziel. Seine Einstellung Prioritätsnachricht (unterbricht) ist standardmäßig an, und mit Stimme kannst du eine Stimme nur für diesen Alarm wählen |
| Schlachtzugmarkierung bei festem Ziel ansagen | An | Stellt die Schlachtzugmarkierung vor die Beschreibung des Ziels |
| Ziel-im-Kampf-Sound | An | Spielt den Ton, wenn das neue Ziel im Kampf mit dir oder deiner Gruppe ist; mit seiner Einstellung Sound kannst du einen anderen Ton wählen |

Die Lebensüberwachung (Health Monitor) liest die Gesundheit deines Ziels in Fünf-Prozent-Schritten vor, wenn sie sinkt (oder steigt).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert (Alarm) | An | Schaltet die Gesundheitsansage ein oder aus |
| TTS-Alarm | An | Spricht den Prozentwert, zum Beispiel "85%" |
| Stimmenalarm | Aus | Spielt statt Sprachausgabe eine aufgenommene Zahl aus deinem Stimmenpaket ab |

Die Gesundheit wird auf das nächste Vielfache von fünf aufgerundet. Du hörst also "95%", sobald das Ziel bei 95 Prozent oder darunter ist, dann "90%", "85%" und so weiter. Bei voller Gesundheit und bei null wird nichts gesagt. Wechselst du das Ziel, hörst du die Gesundheit des neuen Ziels direkt nach seinem Namen, außer es hat volle Gesundheit.

(Nur Retail und WoW: Forever) Das Spiel hält die Gesundheit mancher Ziele vor Addons geheim. Für diese Ziele bleibt die Lebensüberwachung stumm; WowVision kann daran nichts ändern.

Beispiel: Du willst einen ruhigeren Kampf und schaltest die Gesundheitsansagen aus.

1. Drücke Umschalt+F1 (oder tippe /wv), um das Menü zu öffnen, und gehe zu Zielerfassung, dann Festes Ziel.
2. Wähle Lebensüberwachung.
3. Schalte Aktiviert aus.

CC auf dem Ziel (Target Crowd Control) sagt dir, wenn auf deinem Ziel CC von irgendjemandem liegt: betäubt, in Furcht versetzt, verwandelt und Ähnliches. Das funktioniert auch im Kampf.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert (Alarm) | An | Schaltet den ganzen Alarm ein oder aus |
| Klang bei CC | An | Spielt einen Klang, wenn dein Ziel CC bekommt oder wenn du zu einem Ziel wechselst, auf dem schon CC liegt |
| Klang bei Ende des CC | An | Spielt einen Klang, wenn der CC auf deinem Ziel endet oder wenn du von einem Ziel mit CC zu einem freien wechselst |
| TTS-Alarm | Aus | Spricht "CC" oder "Frei" statt der Klänge oder zusätzlich dazu |

Der Wechsel von einem freien Ziel zu einem anderen freien Ziel bleibt stumm; den Klang bei Ende des CC hörst du nur, wenn auf dem Ziel davor CC lag. Beide Klänge haben eine Einstellung Sound, mit der du einen anderen wählen kannst.

Dieser Alarm ist auf Retail, WoW: Forever und Mists of Pandaria verfügbar. Auf The Burning Crusade Anniversary liefert das Spiel keine Informationen über CC, deshalb gibt es den Alarm dort nicht.

## Weiche Zielerfassung

Die weiche Zielerfassung ist eine Spielfunktion, die für dich eine Einheit auswählt, ohne dass du ein echtes Ziel hast: den Feind vor dir, einen befreundeten Spieler oder etwas, womit du interagieren kannst (einen NPC, einen Briefkasten, eine Leiche zum Plündern). Die Interaktionstaste des Spiels wirkt auf das weiche Interaktionsziel. WowVision lässt dich die drei Arten per Taste ein- und ausschalten, sagt die Einheit an, wenn sie wechselt, und macht die versteckten Optionen der weichen Zielerfassung des Spiels zugänglich.

Es gibt drei Arten:

- Weiches Ziel Feind (Umschalt+I): der Feind, den das Spiel vor dir auswählen würde.
- Weiches Ziel Freund (Umschalt+P): die freundliche Einheit vor dir.
- Weiches Ziel Interaktion (Umschalt+O): das nächste Ding, mit dem du interagieren kannst.

Alle drei sind standardmäßig aus.

### Ein- und Ausschalten

Drücke die Taste. WowVision schaltet die Einstellung um und sagt zum Beispiel "Weiches Ziel Feind Aktiviert" oder "Weiches Ziel Feind Deaktiviert". Die Taste verhält sich genau wie der Schalter Aktiviert des passenden Alarms im Menü. Beides schaltet die eigene weiche Zielerfassung des Spiels ein (für Tastatur und Gamepad) oder aus.

Das Spiel erlaubt es nicht, diese Schalter im Kampf zu ändern. Drückst du die Taste in einem Kampf, sagt WowVision zum Beispiel "Weiches Ziel Feind Aktiviert, nach dem Kampf", und die Änderung wird in dem Moment übernommen, in dem der Kampf endet.

Hast du die Interaktionstaste in den eigenen Optionen des Spiels eingeschaltet, schaltet WowVision sie beim Einloggen nicht wieder aus; es schaltet nur die Arten ein, die du in WowVision aktiviert hast.

### Was du hörst

Solange eine Art der weichen Zielerfassung an ist, sagt WowVision jedes neue weiche Ziel dieser Art an: den Tooltip-Text der Einheit, mindestens aber ihren Namen, dazu einen kurzen Ton, der für Feind, Freund und Interaktion verschieden ist. Wenn das weiche Ziel verschwindet, wird nichts gesagt.

Jede Art ist ein Alarm im Menü Zielerfassung mit dem Namen Weiches Ziel Feind, Weiches Ziel Freund und Weiches Ziel Interaktion. Der Alarm ist standardmäßig aus; seine Einstellung Aktiviert ist das, was die Taste umschaltet. Darunter findest du TTS-Alarm (gesprochen, standardmäßig unterbrechend) und Soundalarm, beide sind standardmäßig an, sobald der Alarm an ist. Mit der Einstellung Sound der Soundausgabe kannst du einen anderen Ton wählen.

### Winkel und Reichweite

Jede Art der weichen Zielerfassung hat im Menü Zielerfassung zwei weitere Einstellungen. Alle haben als Standard die eigenen Werte des Spiels, die Installation von WowVision ändert also nichts, bis du sie einstellst.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Weiches Ziel Feind: Winkel (Soft Target Enemy Arc) | Spielstandard | Wie breit der Kegel vor dir ist, in dem die weiche Feind-Erfassung sucht. Auswahl: Spielstandard, Direkt vor dir, 15 Grad vor dir, 180 Grad vor dir |
| Weiches Ziel Feind: Reichweite (Soft Target Enemy Range) | 0 | Maximale Entfernung in Yards, 0 bis 60. 0 bedeutet die eigene Reichweite des Spiels |
| Weiches Ziel Freund: Winkel | Spielstandard | Dieselbe Auswahl, für Freunde |
| Weiches Ziel Freund: Reichweite | 0 | 0 bis 60 Yards, 0 bedeutet die eigene Reichweite des Spiels |
| Weiches Ziel Interaktion: Winkel | Spielstandard | Dieselbe Auswahl, für Interaktionsziele |
| Weiches Ziel Interaktion: Reichweite | 0 | 0 bis 20 Yards, 0 bedeutet die eigene Reichweite des Spiels. Die Obergrenze ist niedriger, weil eine große Interaktionsreichweite Monster hinter Mauern und Gebäuden erfasst |

### Weiche Zielerfassung bei festem Ziel

Das Spiel hat eine zusätzliche Regel dafür, was die weiche Zielerfassung tut, solange du bereits ein echtes Ziel hast. WowVision bietet sie als eine einzige Auswahl an, Weiches Ziel bei festem Ziel (Soft Targeting With a Hard Target; Standard Spielstandard):

| Auswahl | Was passiert |
|---------|--------------|
| Spielstandard | WowVision rührt das eigene Verhalten des Spiels nicht an |
| Nur ohne angreifbares festes Ziel | Solange ein lebender Feind im Ziel ist, hält sich die weiche Zielerfassung heraus, sodass die Interaktionstaste auf diesen Feind wirkt statt auf eine Leiche oder einen Stuhl daneben. Ist eine Leiche, ein NPC oder ein Spieler, dem du folgst, im Ziel, arbeitet die weiche Zielerfassung weiter |
| Nur ohne festes Ziel | Jedes echte Ziel schaltet die weiche Zielerfassung aus |
| Immer | Die weiche Zielerfassung arbeitet, was auch immer du im Ziel hast |

Der Modus folgt jedem Zielwechsel und auch dem Tod deines Ziels, und er funktioniert ebenfalls im Kampf.

Weiches Ziel wird festes Ziel (Make Soft Target the Hard Target; Standard Spielstandard) lässt das Spiel dein echtes Ziel zum weichen machen. Auswahl: Spielstandard, Aus, Feinde, Freunde. Wie die Ein/Aus-Schalter wird auch diese Einstellung bis zum Ende des Kampfes zurückgehalten, wenn du sie während eines Kampfes änderst.

### Beispiel: Leichen plündern und trotzdem mit dem interagieren, was neben deinem Ziel steht

1. Drücke Umschalt+O, um die weiche Interaktion einzuschalten. Du hörst "Weiches Ziel Interaktion Aktiviert".
2. Stelle im Menü Zielerfassung die Einstellung Weiches Ziel bei festem Ziel auf Nur ohne angreifbares festes Ziel.
3. Töte ein Monster und gehe zu seiner Leiche. WowVision sagt dir, was das weiche Interaktionsziel ist, sobald es wechselt.
4. Drücke die Interaktionstaste des Spiels. Solange das tote Monster dein Ziel ist, bleibt die weiche Zielerfassung aktiv, die Taste plündert also die Leiche. Hättest du stattdessen einen lebenden Feind neben der Leiche im Ziel, würde die weiche Zielerfassung beiseitetreten, und die Interaktionstaste würde auf diesen Feind wirken.

### Die Werte prüfen: /wv soft

/wv soft liest den aktuellen Sperrmodus und jede Einstellung der weichen Zielerfassung des Spiels mit ihrem Wert und dem Standardwert des Spiels vor und gibt sie im Chat aus, zum Beispiel "SoftTargetEnemy 3 (Standard 0)". Einstellungen, die auf das Ende des Kampfes warten, sind mit "nach dem Kampf" und dem Wert markiert, den sie bekommen werden. Eine Einstellung, die deine Spielversion nicht hat, wird als "nicht verfügbar" aufgeführt. Das ist für Fehlerberichte nützlich.

## Virtueller Fokus: fünf gespeicherte Ziele

Der virtuelle Fokus funktioniert wie die gleichnamige Funktion von Sku. Du speicherst bis zu fünf Ziele über ihren Namen und rufst jedes mit einer eigenen Taste wieder auf. Er ist unabhängig vom eigenen Fokusziel des Spiels.

Das Modul heißt Virtueller Fokus (Virtual Focus) und steht im Menü unter Zielerfassung. Es hat keine eigenen Einstellungen.

### Einen Fokus speichern

Tippe /focus1 bis /focus5 in den Chat.

- /focus1 ohne weiteren Text speichert den Namen deines aktuellen Ziels in Platz 1. Ohne Ziel behält Platz 1 seinen alten Namen, und WowVision gibt "Kein Ziel. Benutze /focus1 <Name> oder erfasse ein Ziel." aus.
- /focus2 Irgendein Name speichert diesen Namen in Platz 2, egal ob du etwas im Ziel hast.

WowVision antwortet im Chat, zum Beispiel "Fokus 1 auf Hogger gesetzt.". Im Kampf ist das Speichern nicht möglich; WowVision gibt dann "Virtueller Fokus kann im Kampf nicht gesetzt werden." aus. Mach es vor dem Pull.

### Einen Fokus benutzen

Belege eine Taste mit Zielfokus 1 bis Zielfokus 5 (sie sind standardmäßig unbelegt; siehe [Tastenbelegung](../basics/keybindings.md)). Ein Tastendruck erfasst den gespeicherten Namen, genau wie die Eingabe von /target mit diesem Namen. Die Taste funktioniert auch im Kampf.

Weil der Fokus ein Name ist, erfasst das Spiel die nächste Einheit mit diesem Namen. Zwei Monster mit demselben Namen lassen sich nicht unterscheiden. Virtuelle Fokusplätze werden nicht gespeichert: Nach /reload oder einem neuen Login sind die Plätze leer und müssen neu gesetzt werden.

### Beispiel: drei Bosse in einem Schlachtzug

1. Erfasse den ersten Boss und tippe /focus1.
2. Erfasse den zweiten Boss und tippe /focus2, dann den dritten und /focus3.
3. Weise im Fenster für die Tastenbelegung Alt+1, Alt+2 und Alt+3 den Belegungen Zielfokus 1, 2 und 3 zu.
4. Im Kampf erfasst Alt+1 den ersten Boss, und WowVision liest ihn wie jeden Zielwechsel vor.

## Das Menü des Ziels: Alt+T

Drücke Alt+T, um dasselbe Menü zu öffnen, das ein Rechtsklick auf das Porträt deines Ziels öffnet: Charaktername kopieren (Copy Character Name), Flüstern (Whisper), Einladen (Invite) und der Rest, je nachdem, was du im Ziel hast. Erfasst du dich selbst, bekommst du Einträge wie Alle Instanzen zurücksetzen (Reset All Instances) und die Auswahl für Beute- und Dungeon-Schwierigkeit.

Bewege dich mit den Pfeiltasten durch das Menü und drücke Eingabe auf einem Eintrag; siehe [Die Oberfläche bedienen](../basics/interface.md). Ohne Ziel öffnet sich nichts.

## Entfernung zu deinem Ziel

Solange du ein Ziel hast, spielt eine eigene Funktion, das Modul Reichweite (Range; ein eigener Eintrag im WowVision-Menü), die Entfernung deines Ziels in Yards aus einem Stimmenpaket ab, sobald sich die Entfernung ändert. Es gehört nicht zur Zielerfassung; es wird in [Die Entfernungsansage](../windows/system.md#die-entfernungsansage) beschrieben.

## Verwandte Seiten

- [Kampf](combat.md) für die Kampfalarme und die Gegneranzahl.
- [Alarme](../basics/alerts.md) dafür, wie Alarmausgaben funktionieren.
- [Navigation und Routen](navigation.md) für die Routenführung zu deinem Ziel.
