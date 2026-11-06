# Zielerfassung

WowVision sagt dir an, was du im Ziel hast, lässt dich bis zu fünf "virtuelle Fokusziele" auf Tasten legen, kann die weiche Zielerfassung des Spiels ein- und ausschalten, kann mit einer Taste deiner Wahl das Ziel deines Ziels erfassen und öffnet mit einer einzigen Taste das Menü deines Ziels. Diese Seite behandelt alles davon: die Ansagen, die Tasten und die Einstellungen.

Alle Einstellungen zur Zielerfassung findest du im WowVision-Menü (tippe /wv) unter Zielerfassung. Die Zielerfassung funktioniert in jeder unterstützten Spielversion gleich, abgesehen von den Hinweisen für Retail und WoW: Forever. Die weiche Zielerfassung braucht Unterstützung vom Spiel selbst; fehlt in deiner Version eine ihrer Einstellungen, listet /wv soft sie als "nicht verfügbar" auf.

Hinweis: Die Beispiele unten zeigen, was du auf einem deutschen Client hörst. Wo eine Ansage noch nicht übersetzt ist, ist das beim Beispiel vermerkt (Ansage auf Englisch).

## Die Zieltasten im Überblick

| Taste | Name der Belegung | Was sie tut |
|-------|-------------------|-------------|
| Umschalt+I | Weiches Ziel Feind (Soft Target Enemy) | Schaltet die weiche Zielerfassung für Feinde ein oder aus |
| Umschalt+P | Weiches Ziel Freund (Soft Target Friend) | Schaltet die weiche Zielerfassung für Freunde ein oder aus |
| Umschalt+O | Weiches Ziel Interaktion (Soft Target Interact) | Schaltet die weiche Zielerfassung für Interaktion ein oder aus |
| Alt+T | Zielmenü öffnen (Open Target Menu) | Öffnet das Menü deines aktuellen Ziels |
| standardmäßig unbelegt | Ziel des Ziels (Target of Target) | Macht das Ziel deines Ziels zu deinem Ziel |
| standardmäßig unbelegt | Zielfokus 1 bis Zielfokus 5 (Target Focus 1 bis 5) | Erfasst die Einheit, die du in diesem virtuellen Fokusplatz gespeichert hast |

Du kannst Tasten ändern oder hinzufügen im Fenster für die Tastenbelegung (WowVision-Menü, Benutzeroberfläche, Tastenbelegung); siehe [Tastenbelegung](../basics/keybindings.md). Die vollständige Liste aller Tasten steht in der [Tastenreferenz](../reference/keybindings.md).

Ist gleichzeitig das Addon Sku geladen, überlässt WowVision die Tasten der weichen Zielerfassung, die Zielfokus-Tasten und die Befehle /focus1 bis /focus5 Sku und registriert sie nicht. Ziel des Ziels und Alt+T sind davon nicht betroffen.

## Dein Ziel hören (festes Ziel)

Ein "festes Ziel" ist das Ziel, das du auf dem normalen Weg bekommst: per Mausklick, mit Tab, per Makro oder mit /target. Immer wenn dein festes Ziel auf eine neue Einheit wechselt, liest WowVision sie vor.

Was du hörst, hängt davon ab, was für eine Einheit es ist und ob du im Kampf bist. Außerhalb des Kampfes klingt ein Mob etwa so: "Gnollschläger, Stufe 12, Humanoid, Feindselig", im Kampf nur "Gnollschläger, Stufe 12". Diese Angaben wählst du selbst, für Spieler, NPCs, Mobs, Begleiter und Totems, getrennt für im Kampf und außerhalb des Kampfes; siehe [Was angesagt wird: Namen](#was-angesagt-wird-namen). Trägt die Einheit eine Schlachtzugmarkierung, steht der Name der Markierung vorne; du hörst zum Beispiel "Totenkopf Gnollschläger, Stufe 12". Die Markierungen sind Stern, Kreis, Diamant, Dreieck, Mond, Quadrat, X und Totenkopf.

Einige Details:

- Das Ziel zu löschen bleibt stumm. Nur ein neues Ziel wird angesagt.
- Die Ansage unterbricht alles, was gerade gesprochen wird. So entsteht beim schnellen Zielwechsel nie ein Stau alter Namen.
- Befindet sich die Einheit, die du erfasst, bereits im Kampf mit dir, spielt zusätzlich ein kurzer Ton. WowVision entscheidet das anhand der Bedrohungslisten von dir, deinen Gruppen- oder Schlachtzugsmitgliedern und deren Begleitern. Es funktioniert also auch, wenn nur ein Gruppenmitglied oder ein Begleiter gegen die Einheit kämpft.
- (Nur Retail und WoW: Forever) Das Spiel verbirgt vor Addons, welche Schlachtzugmarkierung eine Einheit trägt. WowVision sagt dir trotzdem, dass es eine gibt, nennt aber statt des Namens ihre Nummer: 1 ist Stern, 2 Kreis, 3 Diamant, 4 Dreieck, 5 Mond, 6 Quadrat, 7 X und 8 Totenkopf. In manchen Situationen verbirgt das Spiel auch die Identität einer Einheit vor Addons; die Ansage funktioniert weiter, nur Angaben, die das Spiel in diesem Moment verbirgt, etwa ob ein Spieler abwesend ist, fallen weg.

### Was angesagt wird: Namen

Öffne Zielerfassung, dann Namen (Names). Hier legst du fest, welche Angaben die Zielansage spricht. Die Ansagen der weichen Zielerfassung benutzen dieselbe Auswahl.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Konfigurierte Zielansage (Configured Target Announcement) | Aus | Spricht die Angaben, die du unten auswählst. Ist sie aus, hörst du stattdessen den ganzen Tooltip-Text der Einheit |
| Im Kampf (In Combat) | | Öffnet die Auswahl, die gilt, während du im Kampf bist |
| Außerhalb des Kampfes (Out of Combat) | | Öffnet die Auswahl, die gilt, während du nicht im Kampf bist |

Welche der beiden gilt, entscheidet sich in dem Moment, in dem du das Ziel erfasst: im Kampf Im Kampf, sonst Außerhalb des Kampfes. Beide öffnen dieselben fünf Arten von Einheiten, jede mit einem Kontrollkästchen pro Angabe, und enden mit Auf Standardwerte zurücksetzen (Reset to Defaults). Das setzt die Kontrollkästchen dieses Kampfzustands auf die Standardwerte zurück und sagt "Standardwerte wiederhergestellt". Eine Änderung gilt ab dem nächsten Ziel.

Die fünf Arten von Einheiten:

- Spieler (Players): die Charaktere anderer Spieler und du selbst.
- NPCs: Einheiten, die du nicht angreifen kannst, etwa Händler, Questgeber und die Wachen deiner Fraktion.
- Mobs: Einheiten, die du angreifen kannst, auch neutrale und gegnerische Wachen.
- Begleiter (Pets): Einheiten, die ein Spieler steuert, etwa Jägerbegleiter, Hexenmeisterdämonen und beschworene Diener.
- Totems: die Totems der Schamanen.

Dinge, die keine Einheiten sind, etwa ein Briefkasten oder ein Kraut bei der weichen Interaktion, sprechen immer ihren ganzen Tooltip-Text.

Die Angaben kommen in der Reihenfolge der Liste, getrennt durch Kommas. Stufe und Selten, Elite oder Boss kommen zusammen ("Stufe 11 Elite"), ebenso Rasse und Klasse ("Mensch Krieger"). Eine Angabe, die die Einheit nicht hat, fällt weg; Realm sagt also nichts bei einem Spieler von deinem eigenen Realm. Eine Angabe, die zwei Kontrollkästchen beide sagen würden, kommt nur einmal: Sind Klassifizierung und Elite beide an, hörst du "Elite" einmal. Fehlt in einer Liste ein Kontrollkästchen, bietet deine Spielversion diese Angabe nicht an.

Spieler:

| Angabe | Was du hörst | Im Kampf | Außerhalb des Kampfes |
|--------|--------------|----------|-----------------------|
| Name | Der Name, mit dem Titel davor, wenn Titel auch an ist | An | An |
| Titel (Title) | Der Titel. Allein nur, wenn Name aus ist | Aus | An |
| Realm | "Realm Everlook", bei einem Spieler von einem anderen Realm | Aus | Aus |
| Gilde (Guild) | "Gilde Die Wächter" | Aus | An |
| Stufe (Level) | "Stufe 60", oder "Stufe Totenkopf", wenn die Stufe zu weit über deiner liegt, um sie zu kennen | Aus | An |
| Rasse (Race) | "Mensch" | Aus | An |
| Klasse (Class) | "Krieger" | An | An |
| Geschlecht (Gender) | "Männlich" oder "Weiblich" | Aus | Aus |
| Fraktion (Faction) | "Allianz" oder "Horde" | Aus | Aus |
| Gruppenrolle (Group Role) | "Tank", "Heiler" oder "Schadensausteiler", bei einem Gruppenmitglied mit Rolle | Aus | Aus |
| PvP-Status (PvP Status) | "PvP" bei einem Spieler mit PvP-Markierung, "Jeder gegen jeden PvP" in Gebieten, in denen jeder gegen jeden kämpft | Aus | Aus |
| Abwesend (AFK) | "AFK" | Aus | Aus |
| Nicht stören (DND) | "Nicht stören" | Aus | Aus |
| Beherrscht (Charmed) | "Beherrscht", bei einem Spieler unter Gedankenkontrolle | An | Aus |
| Ziel im Kampf (Target in Combat) | "Im Kampf", solange der Spieler kämpft | Aus | Aus |
| Tot oder Geist (Dead or Ghost) | "Tot" oder "Geist" | An | An |

NPCs:

| Angabe | Was du hörst | Im Kampf | Außerhalb des Kampfes |
|--------|--------------|----------|-----------------------|
| Name | Der Name | An | An |
| Titel (Title) | Die Zeile unter dem Namen im Tooltip, zum Beispiel "Gastwirt" oder "Waffenhändler" | Aus | An |
| Stufe (Level) | "Stufe 30" | Aus | An |
| Klassifizierung (Classification) | Alles davon, was zutrifft: "Selten", "Elite", "Weltboss", "Schwach" für eine schwache Einheit, "Unbedeutend" | Aus | Aus |
| Selten (Rare) | "Selten" | Aus | An |
| Elite | "Elite" | Aus | An |
| Boss | "Boss" oder "Weltboss" | Aus | An |
| Kreaturentyp (Creature Type) | "Humanoid", "Wildtier" und so weiter | Aus | Aus |
| Kreaturenfamilie (Creature Family) | "Wolf", "Katze" und so weiter, bei Wildtieren | Aus | Aus |
| Reaktion (Reaction) | "Feindselig", "Neutral" oder "Freundlich" | Aus | Aus |
| Quest-Boss (Quest Boss) | "Quest-Boss" | Aus | Aus |
| Questziel (Quest Target) | "Questziel", wenn eine deiner Quests diese Einheit braucht | Aus | An |
| Questfortschritt (Quest Progress) | Deine offenen Questziele für diese Einheit, zum Beispiel "Hogger getötet: 0/1" | Aus | An |
| Ziel im Kampf (Target in Combat) | "Im Kampf", solange die Einheit kämpft | Aus | Aus |
| Tot (Dead) | "Tot" | An | An |

Mobs haben dieselben Angaben wie NPCs und zwei mehr:

| Angabe | Was du hörst | Im Kampf | Außerhalb des Kampfes |
|--------|--------------|----------|-----------------------|
| Von anderen beansprucht (Tapped by Others) | "Von anderen beansprucht", wenn ein anderer Spieler ihn zuerst getroffen hat: Du bekommst von ihm weder Beute noch Erfahrung | Aus | An |
| Beherrscht (Charmed) | "Beherrscht", bei einem Mob unter Gedankenkontrolle | Aus | Aus |

Bei Mobs sind die Standardwerte anders als bei NPCs: Im Kampf sind Name, Stufe, Selten, Elite, Boss und Tot an; außerhalb des Kampfes zusätzlich Titel, Kreaturentyp, Reaktion, Quest-Boss, Questziel, Questfortschritt und Von anderen beansprucht.

Begleiter:

| Angabe | Was du hörst | Im Kampf | Außerhalb des Kampfes |
|--------|--------------|----------|-----------------------|
| Name | Der Name | An | An |
| Besitzer (Owner) | Wem der Begleiter gehört, so wie es im Tooltip steht, oder "Von dir" bei deinem eigenen | An | An |
| Stufe (Level) | "Stufe 60" | Aus | An |
| Kreaturentyp (Creature Type) | "Wildtier", "Dämon" und so weiter | Aus | Aus |
| Kreaturenfamilie (Creature Family) | "Wolf", "Katze" und so weiter | Aus | An |
| Reaktion (Reaction) | "Feindselig", "Neutral" oder "Freundlich" | Aus | Aus |
| Ziel im Kampf (Target in Combat) | "Im Kampf" | Aus | Aus |
| Tot (Dead) | "Tot" | An | An |

Totems haben Name und Besitzer (beide an) und Reaktion (aus).

Beispiel: Im Kampf willst du von Mobs nur den Namen hören.

1. Drücke Umschalt+F1 (oder tippe /wv) und gehe zu Zielerfassung, dann Namen, dann Im Kampf, dann Mobs.
2. Schalte Stufe, Selten, Elite, Boss und Tot aus.
3. Schließe das Menü mit Escape. Der nächste Mob, den du im Kampf erfasst, sagt nur seinen Namen.

Um zu hören und zu lesen, was jede Angabe für dein aktuelles Ziel sagt, tippe /wv targetinfo; siehe [Befehle](../reference/commands.md).

### Einstellungen für Ansagen des festen Ziels

Öffne Zielerfassung, dann Festes Ziel (Hard Target). Es gibt drei Alarme, jeweils mit den üblichen Alarmeinstellungen (siehe [Alarme](../basics/alerts.md)).

Zielwechsel (Target Change) ist die oben beschriebene Ansage.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert (Alarm) | An | Schaltet den ganzen Alarm Zielwechsel ein oder aus |
| TTS-Alarm | An | Spricht das Ziel. Seine Einstellung Prioritätsnachricht (unterbricht) ist standardmäßig an, und mit Stimme kannst du eine Stimme nur für diesen Alarm wählen |
| Schlachtzugmarkierung bei festem Ziel ansagen | An | Stellt die Schlachtzugmarkierung vor die Beschreibung des Ziels |
| Ziel-im-Kampf-Sound | An | Spielt den Ton, wenn das neue Ziel im Kampf mit dir oder deiner Gruppe ist; mit seiner Einstellung Sound kannst du einen anderen Ton wählen |

(Classic Era, The Burning Crusade und Mists of Pandaria) Die Lebensüberwachung (Health Monitor) liest die Gesundheit deines Ziels in Fünf-Prozent-Schritten vor, wenn sie sinkt (oder steigt).

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Aktiviert (Alarm) | An | Schaltet die Gesundheitsansage ein oder aus |
| TTS-Alarm | An | Spricht den Prozentwert, zum Beispiel "85%" |
| Stimmenalarm | Aus | Spielt statt Sprachausgabe eine aufgenommene Zahl aus deinem Stimmenpaket ab |

Die Gesundheit wird auf das nächste Vielfache von fünf aufgerundet. Du hörst also "95%", sobald das Ziel bei 95 Prozent oder darunter ist, dann "90%", "85%" und so weiter. Bei voller Gesundheit und bei null wird nichts gesagt. Wechselst du das Ziel, hörst du die Gesundheit des neuen Ziels direkt nach seinem Namen, außer es hat volle Gesundheit.

(Retail und WoW: Forever) Hier gibt es keine Lebensüberwachung, weil das Spiel die Gesundheit eines Ziels im Kampf vor Addons verbirgt, gerade dann, wenn du sie brauchst. Nimm stattdessen die Kampf-Audiohinweise des Spiels (Combat Audio Alerts) in seinen Barrierefreiheit-Optionen: Sie können die Gesundheit deines Ziels ansagen, auch im Kampf.

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

Solange eine Art der weichen Zielerfassung an ist, sagt WowVision jedes neue weiche Ziel dieser Art mit den Angaben an, die du unter Namen ausgewählt hast (siehe [Was angesagt wird: Namen](#was-angesagt-wird-namen)), dazu einen kurzen Ton, der für Feind, Freund und Interaktion verschieden ist. Dinge, die keine Einheiten sind, etwa ein Briefkasten, sprechen ihren Tooltip-Text, mindestens aber ihren Namen. Wenn das weiche Ziel verschwindet, wird nichts gesagt.

Jede Art ist ein Alarm im Menü Zielerfassung mit dem Namen Weiches Ziel Feind, Weiches Ziel Freund und Weiches Ziel Interaktion. Der Alarm ist standardmäßig aus; seine Einstellung Aktiviert ist das, was die Taste umschaltet. Darunter findest du TTS-Alarm (gesprochen, standardmäßig unterbrechend) und Soundalarm, beide sind standardmäßig an, sobald der Alarm an ist. Mit der Einstellung Sound der Soundausgabe kannst du einen anderen Ton wählen.

### Winkel und Reichweite

Jede Art der weichen Zielerfassung hat zwei weitere Einstellungen, in ihrem Alarm im Menü Zielerfassung: Öffne Weiches Ziel Feind, Weiches Ziel Freund oder Weiches Ziel Interaktion, um sie zu finden. Standard sind der breiteste Winkel und die größte Reichweite, weil die eigenen Werte des Spiels für Spieler gemacht sind, die sehen, was vor ihnen ist. WowVision schreibt sie nur für eine Art, die du eingeschaltet hast; für jede Art, die du nicht benutzt, bleiben die Werte des Spiels bestehen. Spielstandard oder eine Reichweite von 0 stellt den eigenen Wert des Spiels wieder her.

| Einstellung | Standard | Was sie tut |
|-------------|----------|-------------|
| Weiches Ziel Feind: Winkel (Soft Target Enemy Arc) | 180 Grad vor dir | Wie breit der Kegel vor dir ist, in dem die weiche Feind-Erfassung sucht. Auswahl: Spielstandard, Direkt vor dir, 15 Grad vor dir, 180 Grad vor dir |
| Weiches Ziel Feind: Reichweite (Soft Target Enemy Range) | 60 | Maximale Entfernung in Yards, 0 bis 60. 0 bedeutet die eigene Reichweite des Spiels |
| Weiches Ziel Freund: Winkel | 180 Grad vor dir | Dieselbe Auswahl, für Freunde |
| Weiches Ziel Freund: Reichweite | 60 | 0 bis 60 Yards, 0 bedeutet die eigene Reichweite des Spiels |
| Weiches Ziel Interaktion: Winkel | 180 Grad vor dir | Dieselbe Auswahl, für Interaktionsziele |
| Weiches Ziel Interaktion: Reichweite | 20 | 0 bis 20 Yards, 0 bedeutet die eigene Reichweite des Spiels. Die Obergrenze ist niedriger, weil eine große Interaktionsreichweite Monster hinter Mauern und Gebäuden erfasst |

### Weiche Zielerfassung bei festem Ziel

Das Spiel hat eine zusätzliche Regel dafür, was die weiche Zielerfassung tut, solange du bereits ein echtes Ziel hast. WowVision bietet sie als eine einzige Auswahl an, Weiches Ziel bei festem Ziel (Soft Targeting With a Hard Target; Standard Spielstandard):

| Auswahl | Was passiert |
|---------|--------------|
| Spielstandard | Das eigene Verhalten des Spiels. Diese Wahl stellt die Werte des Spiels wieder her |
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

- /focus1 ohne weiteren Text speichert den Namen deines aktuellen Ziels in Platz 1. Ohne Ziel behält Platz 1 seinen alten Namen, und WowVision gibt "Kein Ziel. Benutze `/focus1 <Name>` oder erfasse ein Ziel." aus.
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

## Das Ziel deines Ziels

Ziel des Ziels hat von Haus aus keine Taste, leg sie also im Fenster für die Tastenbelegung auf eine. Drücke sie, um zu erfassen, was dein Ziel im Ziel hat: den Gegner, gegen den ein Gruppenmitglied kämpft, oder das Gruppenmitglied, das ein Gegner angreift. WowVision liest das neue Ziel vor wie jeden Zielwechsel. Greift der Gegner dich an, erfasst du dich selbst. Das geht auch im Kampf, und es beginnt keinen Angriff.

Hast du kein Ziel, hörst du "Kein Ziel". Hat dein Ziel kein Ziel, hörst du "Dein Ziel hat kein Ziel", und dein Ziel bleibt, wie es war.

## Das Menü des Ziels: Alt+T

Drücke Alt+T, um dasselbe Menü zu öffnen, das ein Rechtsklick auf das Porträt deines Ziels öffnet: Charaktername kopieren (Copy Character Name), Flüstern (Whisper), Einladen (Invite) und der Rest, je nachdem, was du im Ziel hast. Erfasst du dich selbst, bekommst du Einträge wie Alle Instanzen zurücksetzen (Reset All Instances) und die Auswahl für Beute- und Dungeon-Schwierigkeit.

Bewege dich mit den Pfeiltasten durch das Menü und drücke Eingabe auf einem Eintrag; siehe [Die Oberfläche bedienen](../basics/interface.md). Ohne Ziel öffnet sich nichts.

## Entfernung zu deinem Ziel

Solange du ein Ziel hast, spielt der Alarm Reichweite geändert (Range Changed), unter Festes Ziel im Menü Zielerfassung, die Entfernung deines Ziels in Yards aus einem Stimmenpaket ab, sobald sich die Entfernung ändert. Er wird in [Die Entfernungsansage](../windows/system.md#die-entfernungsansage) beschrieben.

## Verwandte Seiten

- [Kampf](combat.md) für die Kampfalarme und die Gegneranzahl.
- [Alarme](../basics/alerts.md) dafür, wie Alarmausgaben funktionieren.
- [Navigation und Routen](navigation.md) für die Routenführung zu deinem Ziel.
