# Monitore

Monitore beobachten das Spiel für dich und sprechen oder spielen einen Sound ab, wenn sich etwas ändert: Ein Debuff, den du gewirkt hast, läuft gleich aus, eine Abklingzeit ist wieder abgelaufen, ein Proc leuchtet auf. Während dir [Puffer](buffers.md) die Antwort geben, wenn du fragst, sagen dir Monitore Bescheid, ohne dass du fragst.

Welche Monitore du hast, hängt von deiner Spielversion ab. Classic Era, The Burning Crusade und Mists of Pandaria haben einen Aura-Monitor (im Menü Aura genannt) und einen Abklingzeit-Monitor (im Menü Cooldown genannt). Retail und WoW: Forever haben Auren des Abklingzeitmanagers (Cooldown Manager Auras) und Zauber-Abklingzeiten (Spell Cooldowns), weil das Spiel dort im Kampf Aura- und Abklingzeitzahlen vor Addons verbirgt. Die Auren des Abklingzeitmanagers lesen den Abklingzeitmanager von Blizzard. Die Zauber-Abklingzeiten nutzen die wenigen Fakten, die das Spiel noch herausgibt, und borgen sich vom Abklingzeitmanager nur die Liste der Zauber zum Auswählen.

## So funktionieren Monitore

Ein Monitor hat eine oder mehrere Regeln. Eine Regel beobachtet eine Sache, meist einen Zauber, und durchläuft Zustände wie Aktiv (Applied), Pandemic, Läuft ab (Expiring) und Fehlend (Missing). Jeder Zustand hat seinen eigenen Alarm, und jeder Alarm hat zwei Ausgaben: einen Sound und eine gesprochene Nachricht. Du entscheidest, welche Zustände Geräusche machen sollen und wie.

Kurz gesagt:

- Der Monitor sagt, welche Art von Ding beobachtet werden soll und auf welcher Einheit (zum Beispiel Auren auf deinem Ziel).
- Jede Regel darin nennt einen Zauber.
- Jeder Zustand einer Regel hat einen Alarm mit den Ausgaben Soundalarm und TTS-Alarm.

Es wird nichts gesprochen, bis du eine Ausgabe einschaltest. Alle Ausgaben sind aus, wenn du eine Regel anlegst.

### Was einen Alarm auslöst

Eine Regel spricht, wenn sich ihr Zustand ändert, nicht dauernd. Der erste Zustand, den eine Regel nach ihrem Start sieht, wird stillschweigend festgestellt. Wenn du dich also anmeldest, während Mondfeuer schon läuft, gibt es keine Ansage. Danach löst jeder Wechsel in einen anderen Zustand die Ausgaben des neuen Zustands aus.

Was passiert, wenn du die Einrichtung änderst, hängt vom Monitortyp ab:

- Aura- und Cooldown-Monitore (Classic Era, TBC, Mists) fangen von vorn an, sobald du änderst, was sie verfolgen: den Zauber einer Regel (oder Vom Spieler gewirkt), die Einheit des Monitors, oder wenn du eine Regel hinzufügst oder entfernst. Beim Neustart werden alle Regeln dieses Monitors zurückgesetzt, und jede Regel sagt dann einmal den Zustand an, den sie findet, wenn die Ausgabe für diesen Zustand an ist. Zum Beispiel kann die erste Regel, nachdem du eine zweite hinzugefügt hast, noch einmal „Mondfeuer Aktiv“ oder „Mondfeuer Fehlend“ ansagen.
- Zauber-Abklingzeiten (Retail, WoW: Forever) starten stillschweigend neu: Nach einer Änderung nimmt jede Regel einfach den aktuellen Zustand auf, ohne zu sprechen.
- Auren des Abklingzeitmanagers (Retail, WoW: Forever) starten nicht neu. Eine Regel, die du änderst, spricht nur, wenn der Zustand, den sie jetzt findet, sich von dem unterscheidet, den sie vorher hatte.

Wenn du eine Ausgabe einschaltest, während ihre Regel schon in diesem Zustand ist, spricht (oder spielt) sie ebenfalls sofort, sobald die Regel das nächste Mal prüft. Wundere dich nicht: Wenn du den Sound für Aktiv einschaltest, während Mondfeuer aktiv ist, hörst du ihn gleich.

### Rückfall zwischen Zuständen

Manche Zustände sind „schlechtere Versionen“ eines anderen. Bei Auren fällt Pandemic auf Aktiv zurück, und Läuft ab fällt auf Pandemic zurück. Die Regel lautet: Wenn ein Zustand keine eigene eingeschaltete Ausgabe hat, wird stattdessen die Ausgabe des Zustands benutzt, auf den er zurückfällt, und eine Ausgabe, die sich von einem Zustand zum nächsten nicht ändert, wird nicht wiederholt.

Praktische Folgen:

- Wenn du nur für Aktiv einen Sound einschaltest, hörst du ihn einmal, wenn die Aura erscheint. Du hörst ihn nicht noch einmal, wenn die Aura in ihr Pandemic-Fenster eintritt oder abzulaufen beginnt.
- Wenn du für Läuft ab einen anderen Sound einschaltest, hörst du den Sound von Aktiv, wenn die Aura aufgelegt wird, und den Sound von Läuft ab, wenn sie gleich abfällt.
- Fehlend hat keinen Rückfall: Es löst nur aus, wenn seine eigene Ausgabe an ist.

Abklingzeit-Zustände (Bereit, Lädt auf, Klingt ab) haben keine Rückfälle; jeder spielt nur seine eigenen Ausgaben.

## Einen Monitor einrichten

1. Drücke Umschalt+F1 (oder gib `/wv` ein), um das WowVision-Menü zu öffnen, gehe zu Monitor und drücke Eingabe.
2. Der Bildschirm zeigt Aktiviert und eine Schaltfläche namens Monitor mit der Zahl der Monitore, zum Beispiel „Monitor (0)“. Drücke Eingabe darauf.
3. Drücke Eingabe auf Hinzufügen. Der Bildschirm Typ auswählen listet die Monitortypen für deine Spielversion auf. Wähle einen.
4. Der neue Monitor öffnet sich, er heißt „Neu“ plus sein Typ, zum Beispiel „Neu Aura“ (oder „Neu Zauber-Abklingzeiten“). Setze die Bezeichnung auf etwas Sinnvolles wie „Ziel-DoTs“.
5. Setze die eigenen Einstellungen des Monitors (die Einheit und so weiter). Sie stehen im Bildschirm des Monitors hinter der Schaltfläche Regeln.
6. Drücke Eingabe auf die Schaltfläche Regeln („Regeln (0)“), dann auf Hinzufügen, und wähle den Regeltyp.
7. Die neue Regel öffnet sich. Setze den Zauber, dann die Schwellenwerte, falls die Regel welche hat.
8. Öffne den Zustand, der dich interessiert (Aktiv, Fehlend, Bereit und so weiter), dann öffne Soundalarm oder TTS-Alarm und schalte ihn ein. Siehe [Alarme](#zustandsalarme-und-ihre-ausgaben) unten.

Mit Esc gehst du einen Bildschirm zurück. Um einen Monitor oder eine Regel zu entfernen, öffne sie und drücke unten Eingabe auf Entfernen. Es gibt keine Rückfrage.

Das Menü ist unter [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md) beschrieben. Die allgemeine Idee der Alarme steht unter [Alarme](../basics/alerts.md).

### Accountweit oder pro Charakter

Monitore, die du hinzufügst, werden standardmäßig accountweit gespeichert, alle deine Charaktere teilen sie sich also. Das ist nicht immer, was du willst: Ein Mondfeuer-Monitor eines Druiden bedeutet auf einem Krieger nichts.

- Um einen Monitor auf einem Charakter zu behalten, gehe zur Monitorliste, wechsle zum Monitor, drücke Umschalt+F10 (das Kontextmenü), wähle Bereich und dann den Namen deines Charakters. Wähle Global, um ihn wieder zu teilen.
- Um alle Monitore auf einmal umzustellen, öffne das WowVision-Menü, gehe zu Monitor, drücke Umschalt+F10, wähle Bereich und dann Global oder den Namen deines Charakters.

Beim Wechseln des Bereichs wird nichts gelöscht.

### Einen Monitor oder eine Regel kopieren

Um einen zweiten Monitor wie einen vorhandenen zu bauen, gehe in der Monitorliste zu ihm, drücke Umschalt+F10 und wähle Kopie. Du hörst den neuen Namen, zum Beispiel „Mondfeuer Kopie 1“; die Kopie steht direkt hinter dem Original, mit denselben Einstellungen, Alarmen und Regeln, im selben Bereich. Benenne sie um und ändere, was anders sein soll. Kopie funktioniert genauso bei einer Regel in einem Monitor.

### Einstellungen, die jeder Monitor und jede Regel hat

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Aktiviert (Monitor) | An | Ein deaktivierter Monitor tut nichts |
| Bezeichnung (Monitor) | „Neu ...“ plus der Typ | Der Name in der Monitorliste. Wenn du ihn leerst, zeigt die Liste den Typ, zum Beispiel „Aura-Monitor (target)“ |
| Regeln | keine | Die Liste der Regeln (das Menü zeigt die Anzahl) |
| Aktiviert (Regel) | An | Eine deaktivierte Regel wird ignoriert |
| Bezeichnung (Regel) | „Neu ...“ plus der Regeltyp | Der Name in der Regelliste. Er sagt weiter „Neu ...“, nachdem du den Zauber gesetzt hast, benenne sie also um; wenn du ihn leerst, zeigt die Liste den Zauber, zum Beispiel „Mondfeuer (8921)“ |

### Zustandsalarme und ihre Ausgaben

Jeder Zustand einer Regel erscheint im Bildschirm der Regel als Schaltfläche, die nach dem Zustand benannt ist, zum Beispiel Aktiv. Eingabe darauf öffnet den Alarm dieses Zustands. Er enthält:

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Aktiviert | An | Der eigene Schalter des Zustands. Siehe den Hinweis unter der Tabelle |
| Soundalarm | Aus | Spielt einen Sound ab. Öffnet einen eigenen Bildschirm |
| TTS-Alarm | Aus | Spricht eine Nachricht. Öffnet einen eigenen Bildschirm |

Schalte die Ausgabe ein, die du willst, und lasse den eigenen Schalter Aktiviert des Zustands an. Derzeit tut dieser Schalter bei den Zuständen keiner Regel etwas: Nur der Schalter Aktiviert im Soundalarm oder TTS-Alarm entscheidet, ob etwas abgespielt wird. Die einzigen Alarme, die auf den eigenen Schalter Aktiviert des Zustands hören, sind Aufladung erhalten und Aufladung verbraucht der Abklingzeit-Regel.

Der Bildschirm Soundalarm hat:

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Aktiviert | Aus | Schaltet den Sound ein |
| Sound | keiner gewählt | Öffnet einen Sound-Browser. Gehe durch die Liste, um jeden Sound als Vorschau zu hören, und drücke Eingabe, um einen auszuwählen. Es wird kein Sound abgespielt, bis du einen ausgewählt hast |

Der Bildschirm TTS-Alarm hat:

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Aktiviert | Aus | Schaltet die Sprache ein |
| Prioritätsnachricht (unterbricht) | Aus | Wenn an, unterbricht die Nachricht, was gerade gesprochen wird, statt auf ihre Reihe zu warten |
| Stimme | Folgt deiner Einstellung Sprachstimme | Spricht diesen Alarm mit einer anderen Stimme. Siehe [Sprache und Ton](../basics/speech.md) |
| Nachricht | leer | Die Worte, die gesprochen werden. Wenn leer, spricht WowVision seine Standardnachricht |

Die Standardnachricht ist bei jedem Monitor der Name des Zaubers und der Zustand: „Mondfeuer Aktiv“, „Mondfeuer Läuft ab“, „Wiedergeburt Klingt ab“, „Wiedergeburt Aufladung erhalten“, „Baumrinde Bereit“, „Sternensog Proc“. Eine Regel ohne Zauber nimmt stattdessen ihre Bezeichnung. Tippe deine eigene Nachricht, etwa „Mondfeuer weg“, um diesen ganzen Satz zu ersetzen.

## Aura-Monitor

(Classic Era, The Burning Crusade, Mists of Pandaria)

Im Menü heißt dieser Monitortyp Aura. Er beobachtet Buffs und Debuffs auf einer Einheit.

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Einheit | target | Welche Einheit beobachtet wird, als Text eingegeben: `target`, `player`, `focus`, `pet`, `mouseover`, `party1` und so weiter |
| Bei Zielwechsel ansagen | Nur Änderungen | Was die Regeln sagen, wenn du das Ziel wechselst (oder sich die Einheit ändert). Nur Änderungen: Eine Regel spricht nur, wenn sich der Zustand des neuen Ziels von ihrem bisherigen unterscheidet. Immer: Jede Regel sagt den Zustand an, den sie auf der neuen Einheit findet, einschließlich Fehlend. Nie: Die Regeln übernehmen den Zustand des neuen Ziels still; spätere Änderungen auf diesem Ziel werden wie gewohnt gesprochen |

Regeltyp: Aura-Zustandsregel. Sie verfolgt einen Zauber durch sein Leben auf der Einheit.

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Zauber | keiner | Die Aura, die beobachtet wird. Siehe [Einen Zauber auswählen](#einen-zauber-auswählen) |
| Vom Spieler gewirkt | An | Zählt die Aura nur, wenn du (oder dein Begleiter) sie aufgelegt hast |
| Pandemic-Fenster (%) | 30 | Die Aura tritt in den Zustand Pandemic ein, wenn dieser Prozentsatz ihrer Gesamtdauer oder weniger übrig ist |
| Ablaufschwelle (Sekunden) | 5 | Die Aura tritt in den Zustand Läuft ab ein, wenn innerhalb des Pandemic-Fensters diese Zahl von Sekunden oder weniger übrig ist |

Die Zustände und wann sie auslösen:

| Zustand | Wann |
|---|---|
| Aktiv | Die Aura ist auf der Einheit und hat noch reichlich Zeit (oder hat keine Dauer) |
| Pandemic | Die Aura ist innerhalb des Pandemic-Fensters: Zeit, sie für das beste Ergebnis zu erneuern |
| Läuft ab | Die Aura ist innerhalb des Pandemic-Fensters und höchstens auf der Ablaufschwelle |
| Fehlend | Die Aura war auf der Einheit und ist weg |

Gut zu wissen:

- Läuft ab braucht beide Bedingungen: innerhalb des Pandemic-Fensters und unter der Ablaufschwelle. Bei einer kurzen Aura (sagen wir 6 Sekunden) ist das Pandemic-Fenster so klein, dass die Aura direkt von Aktiv zu Läuft ab geht.
- Auren ohne Dauer bleiben bei Aktiv.
- Wenn mehr als eine passende Aura vorhanden ist (wenn Vom Spieler gewirkt aus ist und mehrere Leute sie aufgelegt haben), meldet die Regel die gesündeste.
- Fehlend wird gesprochen, wenn eine Aura, die verfolgt wurde, verschwindet. Wenn der Monitor startet (zum Beispiel bei der Anmeldung) und die Aura nie da war, wird Fehlend nicht gesprochen. Stelle Bei Zielwechsel ansagen auf Immer, wenn du bei jedem neuen Ziel „Mondfeuer Fehlend“ oder „Mondfeuer Aktiv“ hören willst.
- Mit Bei Zielwechsel ansagen auf Nur Änderungen (der Standard) spricht ein Zielwechsel trotzdem, wenn sich der Zustand des neuen Ziels von dem unterscheidet, den die Regel hatte (zum Beispiel von Aktiv zu Fehlend). Stelle es auf Nie, um beim Zielwechsel nichts zu hören, nur die Änderungen, die danach auf dem neuen Ziel folgen.
- Vom Spieler gewirkt muss für Effekte ohne Wirker ausgeschaltet werden, etwa viele Procs von Schmuckstücken.
- Eine Regel erkennt die Aura an ihrer eigenen Zaubernummer. Wenn der Zauber, den du wirkst, und die Aura, die er auf das Ziel legt, verschiedene Nummern haben (bei den Classic-Versionen kann das vom Zauberrang abhängen), wähle die Aura aus den Schnellauswahlen, statt den Namen zu tippen. Die Aura erscheint dort, sobald dein Monitor sie auf der Einheit gesehen hat.

## Abklingzeit-Monitor

(Classic Era, The Burning Crusade, Mists of Pandaria)

Im Menü heißt dieser Monitortyp Cooldown. Er beobachtet die Abklingzeiten deiner eigenen Zauber. Er hat keine Einstellungen außer den allgemeinen; die Zauber werden in seinen Regeln genannt.

Regeltyp: Abklingzeit-Zustandsregel.

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Zauber | keiner | Der Zauber, dessen Abklingzeit beobachtet wird |

Zustände:

| Zustand | Wann |
|---|---|
| Bereit | Der Zauber ist nicht in Abklingzeit. Bei einem Zauber mit Aufladungen sind alle Aufladungen verfügbar |
| Lädt auf | Der Zauber hat Aufladungen, mindestens eine ist verfügbar, aber nicht alle |
| Klingt ab | Der Zauber ist in Abklingzeit. Bei einem Zauber mit Aufladungen ist keine Aufladung verfügbar |

Zwei weitere Alarme lösen bei Zaubern mit Aufladungen unabhängig vom Zustand aus:

| Alarm | Wann |
|---|---|
| Aufladung erhalten | Eine Aufladung ist zurückgekommen |
| Aufladung verbraucht | Eine Aufladung wurde benutzt |

Die globale Abklingzeit zählt nie als Abklingzeit. Der erste Zustand, den eine Regel sieht (zum Beispiel bei der Anmeldung), bleibt stumm.

## Auren des Abklingzeitmanagers

(Retail und WoW: Forever)

Auf Retail verbirgt das Spiel Aura-Informationen im Kampf und in Instanzen vor Addons, die gewöhnlichen Aura-Funktionen können dort also deine Debuffs nicht sehen. Der Abklingzeitmanager von Blizzard kann es, und dieser Monitor liest, was er anzeigt. Er sagt dir für jede Aura in den Verfolgten Buffs und Verfolgten Leisten (Tracked Buffs und Tracked Bars) des Abklingzeitmanagers, ob die Aura auf der Einheit ist und ob sie in ihrem Pandemic-Fenster ist.

Bevor du ihn benutzen kannst, muss die Aura einer der verfolgten Buffs oder Leisten des Abklingzeitmanagers sein:

- Nur Auren in den Kategorien Verfolgte Buffs und Verfolgte Leisten können beobachtet werden. Die Kategorien Essential (essenzielle Zauber) und Utility (Hilfszauber) enthalten Zauber, keine Auren. (Die Kategorienamen sind hier so geschrieben, wie sie in der englischen Spieloberfläche heißen; auf einem deutschen Client können sie anders lauten.)
- Nur zwei Einheiten können beobachtet werden: Ziel und Spieler, die beiden, denen der Abklingzeitmanager folgt. Wenn du dich selbst als Ziel hast, hört ein Monitor für das Ziel die Auren auf dir. In Instanzen kann das Spiel verbergen, ob du selbst dein Ziel bist; WowVision richtet sich dann nach der letzten Antwort, die es seit deinem Zielwechsel lesen konnte, damit deine Aura nicht als Fehlend gemeldet wird, solange du dich weiter selbst als Ziel hast.
- Der Abklingzeitmanager muss die Aura anzeigen. Eine Zeile des Abklingzeitmanagers, die du versteckt oder nur für den Kampf eingestellt hast, wird als leer gelesen, solange sie versteckt ist, und deine Regel meldet Fehlend. Wenn ein Alarm zur falschen Zeit ertönt, prüfe, ob die Zeilen angezeigt werden.

Du richtest den Abklingzeitmanager in seinem Einstellungsfenster ein, das WowVision zugänglich macht. Öffne es mit `/cdm`. Das Fenster hat die Reiter Zauber, Auren und Group Buffs, ein Feld Suchen, ein Menü Einstellungen, jede Kategorie mit ihren Elementen, die Auswahlliste Layout und eine Schaltfläche Revert Changes (Änderungen zurücksetzen). Drücke Eingabe auf einem Element, um es aufzunehmen, und Eingabe auf einem anderen Element oder auf dem leeren Platz einer Kategorie, um es dort abzulegen. Drücke Rücktaste auf einem Element für sein Menü (Alarme, in eine andere Kategorie verschieben). Änderungen, die du mit der Tastatur machst, wirken erst, nachdem das Interface neu geladen wurde, weil das Spiel seine Abklingzeitdaten auf dem Bildschirm daraus neu aufbaut. Das Fenster sagt dir das beim ersten Mal und bietet am Ende eine Schaltfläche Interface neu laden an (oder gib `/reload` ein); wenn du das Fenster nach solchen Änderungen schließt, erinnert es dich noch einmal. Mach diese Änderungen, während keine Buffs auf dir sind, zumindest keine, die der Abklingzeitmanager verfolgt. Ist ein solcher Buff aktiv, während du ein Element verschiebst oder etwas in seinem Menü wählst, zeigt das Spiel einen Lua-Fehler. Der Fehler hält dich nicht auf: Die Änderung wird trotzdem gespeichert und wirkt nach dem Neuladen. Er kommt aus dem Code des Spiels selbst, der die Buffs auf dem Bildschirm nicht neu aufbaut, wenn eine Änderung nicht von einem echten Mausklick kommt. Lade das Interface neu, bevor du in einen Kampf gehst: Bis zum Neuladen tragen die Buffs auf dem Bildschirm noch die Änderung von der Tastatur, und der nächste Buff im Kampf bringt denselben Lua-Fehler, egal ob beim Ändern ein Buff auf dir war. Die Elemente werden mit ihrem Namen gelesen, „Nicht erlernt“ bei Zaubern, die du nicht erlernt hast, und der Zahl ihrer Alarme (zum Beispiel „1 Alarm“). Kategorien lassen sich mit Eingabe auf ihrer Überschrift einklappen und ausklappen. Auf dem Reiter Group Buffs liegen die Buffs in einem Abschnitt für angezeigte und einem für versteckte Buffs (Shown und Hidden): Eingabe nimmt einen Buff auf, und Eingabe auf einem Buff im anderen Abschnitt verschiebt ihn dorthin. Wenn du im Menü eines Elements einen Alarm wählst (Add New Alert, oder einen bestehenden bearbeiten), öffnet sich der Alarm-Editor des Spiels als eigenes Fenster namens Alarm-Editor: der Zauber, eine Auswahlliste für jede Wahl und die Schaltfläche, die den Alarm hinzufügt oder speichert, dann Schließen.

Die Alarme des Spiels brauchst du aber selten: Die Monitore von WowVision können alles, was sie können, und das besser. Jeder Zustand einer Regel hat seinen eigenen Sound und seine eigene gesprochene Meldung, mit deinen eigenen Spracheinstellungen, und du kannst beides jederzeit ändern. Zauber-Abklingzeiten funktioniert außerdem für jeden Zauber, nicht nur für die im Abklingzeitmanager. Der Alarm-Editor des Spiels steht dir zur Verfügung, fang aber mit einem Monitor an.

### Monitoreinstellungen

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Einheit | Ziel | Ziel oder Spieler |
| Bei Zielwechsel ansagen | Nur Änderungen | Was die Regeln sagen, wenn du das Ziel wechselst (nur bei Ziel): Nur Änderungen spricht einen Zustand, der sich vom alten Ziel unterscheidet, Immer sagt den aktuellen Zustand jeder Regel an, Nie bleibt still und spricht nur spätere Änderungen auf dem neuen Ziel |
| Timer mit einer Nachkommastelle | Aus | Der Countdown auf den verfolgten Symbolen zeigt unter zehn Minuten Zehntelsekunden („8.7“). Das ändert, was sehende Spieler auf dem Bildschirm sehen, deshalb ist es standardmäßig aus. Es ist auch das, was Verfolgte Auren ansagen liest |

### Regeltyp: Aura-Regel des Abklingzeitmanagers

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Zauber | keiner | Die Aura, die beobachtet wird |

Die Auswahl Zauber listet die Auren auf, die in deinen Verfolgten Buffs und Verfolgten Leisten sind (oder sagt „Keine verfolgten Buffs oder Leisten“). Du kannst weiterhin jeden Zaubernamen und jede Zaubernummer tippen, aber gesehen werden nur Auren, die in diesen beiden Kategorien sind. Die Regel erkennt über den Namen des Zaubers, ein gewirkter Zauber wie Mondfeuer passt also zu seinem Debuff.

Zustände:

| Zustand | Wann |
|---|---|
| Aktiv | Die Aura ist auf der Einheit |
| Pandemic | Der Abklingzeitmanager markiert die Aura als innerhalb ihres Erneuerungsfensters. Pandemic fällt auf Aktiv zurück |
| Fehlend | Die Aura ist nicht auf der Einheit |

Auf WoW: Forever gibt es kein Pandemic-Fenster, der Zustand Pandemic existiert dort also nicht und erscheint nicht im Menü.

Wenn eine verfolgte Aura innerhalb ihres Pandemic-Fensters ausläuft, geht die Regel direkt von Pandemic zu Fehlend, ohne ein falsches Aktiv dazwischen.

Nachdem du das Ziel gewechselt hast, wartet die Regel einen Moment (ein paar Ticks), bis das Spiel seine Symbole aktualisiert hat, bevor sie sie liest, damit ein Zielwechsel nicht so klingt, als wäre die Aura abgefallen und zurückgekommen.

### Verfolgte Auren ansagen

Die Taste Verfolgte Auren ansagen liest jede verfolgte Aura jedes aktivierten Monitors vom Typ Auren des Abklingzeitmanagers, so wie das Spiel sie zeigt: den Namen der Aura, die verbleibende Zeit, die Stapel und „Pandemic“, wenn es zutrifft, oder „Fehlend“. Beispiel: „Mondfeuer, 8.7, 3 Stapel, Pandemic. Krallenhieb, Fehlend“. Wenn nichts verfolgt wird, hörst du „Keine verfolgten Auren“.

Die Taste ist standardmäßig nicht belegt. Du findest sie im Fenster für die Tastenbelegung unter Monitor, siehe [Tastenbelegung](../basics/keybindings.md).

### Diagnosebefehl: /wv cdmlog

Wenn ein Alarm im falschen Moment auslöst, zeigt `/wv cdmlog` in einem Fenster, aus dem du kopieren kannst, ein Protokoll dessen, was jede Regel rund um jede Änderung auf den Rahmen des Abklingzeitmanagers gesehen hat, das Neueste zuletzt, und spricht die neueste Zeile. Füge es bei, wenn du einen Fehler meldest.

- `/wv cdmlog clear` leert das Protokoll.
- `/wv cdmlog spells` listet jeden Eintrag in den Verfolgten Buffs und Verfolgten Leisten mit seinen Zauber-IDs auf.
- `/wv cdmlog cooldowns` listet die Einträge von Essential und Utility auf.

## Zauber-Abklingzeiten

(Retail und WoW: Forever)

Abklingzeitinformationen sind auf Retail im Kampf und in Instanzen geheim, aber das Spiel lässt ein paar einfache Fakten übrig: ob eine Abklingzeit läuft, ob es nur die globale Abklingzeit ist und ob eine Aufladung gerade nachlädt. Dieser Monitor baut seine Zustände allein aus diesen Fakten auf, er funktioniert also überall und für jeden Zauber. Den Abklingzeitmanager braucht er nur, um dir eine Liste von Zaubern zum Auswählen anzubieten; du kannst stattdessen jeden Zauber tippen. Die verbleibende Zeit stammt aus der eigenen Formatierung des Spiels, in einfachen Worten, und kann auch im Kampf gesprochen werden.

Er hat keine eigenen Einstellungen außer den allgemeinen. Er hat zwei Regeltypen.

### Regeltyp: Zauber-Abklingzeitregel

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Zauber | keiner | Der Zauber, der beobachtet wird |

Die Auswahl Zauber bietet die Zauber aus den Kategorien Essential und Utility deines Abklingzeitmanagers an, bei denen das Spiel sagt, dass sie eine Abklingzeit zum Alarmieren haben (ein Sofortzauber wie Sonnenfeuer, der keine hat, wird nicht angeboten; oder sie sagt „Keine Zauber mit Abklingzeit“). Ein Eintrag, der für mehrere Zauber steht, wie Finsternis für Mond und Sonne, wird als jeder dieser Zauber angeboten. Du kannst weiterhin jeden Zaubernamen und jede Zaubernummer tippen.

Zustände:

| Zustand | Wann |
|---|---|
| Bereit | Der Zauber ist nicht in Abklingzeit und hat eine Aufladung zum Benutzen |
| Lädt auf | Eine Aufladung lädt nach, während mindestens eine Aufladung noch verfügbar ist |
| Klingt ab | Der Zauber ist in einer echten Abklingzeit, ohne verbleibende Aufladung |

Die globale Abklingzeit zählt nie. Solange der Zauber in Abklingzeit ist oder aufgeladen wird, prüft die Regel ihn etwa zehnmal pro Sekunde, weil das Spiel kein Ereignis sendet, wenn eine Abklingzeit endet.

### Regeltyp: Zauber-Proc-Regel

Eine Proc-Regel folgt dem Leuchten, das das Spiel um einen Zauber zeichnet, wenn er procct.

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Zauber | keiner | Der Zauber, dessen Leuchten beobachtet wird |

Die Auswahl listet dieselben Zauber des Abklingzeitmanagers ohne Filter auf, weil ein Proc auf jedem Zauber liegen kann (oder sagt „Keine essenziellen oder Hilfszauber“). Zustände, jeder mit seinem eigenen Alarm:

| Zustand | Wann |
|---|---|
| Proc | Das Leuchten ist erschienen |
| Proc beendet | Das Leuchten ist beendet |

### Verfolgte Abklingzeiten ansagen

Die Taste Verfolgte Abklingzeiten ansagen liest den Zustand jeder Regel jedes aktivierten Zauber-Abklingzeiten-Monitors. Beispiel: „Baumrinde, Klingt ab, 49 Sekunden. Feuerschlag, Lädt auf, 1 Aufladungen, 8 Sekunden. Sternensog, Proc. Wildwuchs, Bereit“. Eine Proc-Regel liest „Kein Proc“, wenn das Leuchten aus ist. Wenn es keine Regeln gibt, hörst du „Keine verfolgten Abklingzeiten“.

Die Taste ist standardmäßig nicht belegt. Du findest sie im Fenster für die Tastenbelegung unter Monitor.

## Verfügbarkeit

| Funktion | Classic Era | The Burning Crusade | Mists of Pandaria | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Aura-Monitor | Ja | Ja | Ja | Nein | Nein |
| Abklingzeit-Monitor | Ja | Ja | Ja | Nein | Nein |
| Auren des Abklingzeitmanagers | Nein | Nein | Nein | Ja | Ja |
| Zauber-Abklingzeiten (Abklingzeit- und Proc-Regeln) | Nein | Nein | Nein | Ja | Ja |
| Zustand Pandemic der Auren des Abklingzeitmanagers | Nein | Nein | Nein | Ja | Nein |
| Alle Monitore ein- oder ausschalten | Ja | Ja | Ja | Ja | Ja |
| Verfolgte Auren ansagen, Verfolgte Abklingzeiten ansagen, `/wv cdmlog` | Nein | Nein | Nein | Ja | Ja |

Die vollständige Funktionsübersicht findest du unter [Funktionen nach Spielversion](../reference/versions.md).

## Tasten

| Aktion | Standardtaste | Was sie bewirkt |
|---|---|---|
| Alle Monitore ein- oder ausschalten | nicht belegt | Ist mindestens ein Monitor an, schaltet die Taste alle Monitore aus und sagt „Monitore aus“. Sind alle aus, schaltet sie alle ein und sagt „Monitore an“ |
| Verfolgte Auren ansagen | nicht belegt | Liest alle verfolgten Auren (Retail und WoW: Forever) |
| Verfolgte Abklingzeiten ansagen | nicht belegt | Liest alle verfolgten Zauber-Abklingzeiten und Procs (Retail und WoW: Forever) |

Belege sie im Fenster für die Tastenbelegung, siehe [Tastenbelegung](../basics/keybindings.md). Alle Monitore ein- oder ausschalten wirkt als Stummschaltung: Drücke die Taste einmal, um alle Monitore stumm zu schalten, und noch einmal, um alle wieder einzuschalten. Dabei gehen auch Monitore an, die du vorher einzeln ausgeschaltet hattest.

## Einen Zauber auswählen

Jede Regel hat eine Einstellung Zauber. Drücke Eingabe darauf, um einen kleinen Bildschirm zu öffnen:

- Zaubername öffnet ein Textfeld. Tippe den Namen oder die Nummer des Zaubers und drücke Eingabe. Wenn WowVision den Zauber nicht findet, hörst du „Nicht gefunden“. Bei den Classic-Versionen muss der Name meist ein Zauber sein, den du kennst; für alles andere nimm die Nummer des Zaubers.
- Darunter steht eine Liste von Schnellauswahlen, jede gelesen als „Zaubername (Nummer)“. Wähle eine mit Eingabe. Bei den Regeln Aura, Cooldown und Zauber-Abklingzeiten ist die Liste die der Zauber, die du auf diesem Charakter gewirkt oder als Auren getroffen hast. Die Regeln der Auren des Abklingzeitmanagers und der Zauber-Abklingzeiten bieten stattdessen die eigenen Einträge des Abklingzeitmanagers an, wie oben beschrieben.

Wenn ein Zauber gesetzt ist, liest sich die Einstellung Zauber etwa „Mondfeuer (8921)“.

## Beispiele

### Mondfeuer auf deinem Ziel (Classic Era, TBC, Mists)

Du willst hören, wann dein Mondfeuer gleich vom Ziel abfällt und wann es weg ist.

1. Öffne das WowVision-Menü (Umschalt+F1), dann Monitor, dann Monitor (0), dann Hinzufügen, und wähle Aura.
2. Setze die Bezeichnung auf „Mondfeuer“. Lasse die Einheit auf `target`.
3. Öffne Regeln, drücke Hinzufügen und wähle Aura-Zustandsregel.
4. Setze den Zauber: Drücke Eingabe, wähle Zaubername, tippe `Mondfeuer`, Eingabe. Du hörst den Zauber mit seiner Nummer.
5. Lasse Vom Spieler gewirkt an.
6. Öffne Läuft ab, dann TTS-Alarm. Schalte Aktiviert ein. Setze die Nachricht auf „Mondfeuer läuft ab“.
7. Gehe zurück und öffne Fehlend, dann TTS-Alarm. Schalte Aktiviert ein. Setze die Nachricht auf „Mondfeuer weg“.
8. Optional: Öffne Aktiv, dann Soundalarm, schalte ihn ein und wähle mit Sound einen kurzen Sound, für ein Klicken jedes Mal, wenn du es auflegst.

Wende nun Mondfeuer auf ein Ziel an. Aktiv spielt dein Klicken. Der Zustand Pandemic bleibt still: Er hat keine eigene Ausgabe, fällt also auf Aktiv zurück, und es spielt nichts Neues. Wenn die Aura gleich abläuft, hörst du „Mondfeuer läuft ab“, und wenn sie abfällt, hörst du „Mondfeuer weg“. Wenn du dann zu einem Ziel wechselst, das kein Mondfeuer hat, hörst du ebenfalls „Mondfeuer weg“, weil die Regel von Aktiv zu Fehlend gewechselt ist.

### Ein Alarm für „Abklingzeit bereit“ (Classic Era, TBC, Mists)

1. Monitor, Monitor (0), Hinzufügen, Cooldown. Gib ihm die Bezeichnung „Abklingzeiten“.
2. Regeln, Hinzufügen, Abklingzeit-Zustandsregel. Setze den Zauber auf `Sternenfeuer` (oder einen beliebigen Zauber mit Abklingzeit).
3. Öffne Bereit, dann TTS-Alarm, schalte ihn ein und setze die Nachricht auf „Sternenfeuer bereit“.

Wirke den Zauber. Wenn die Abklingzeit endet, hörst du „Sternenfeuer bereit“. Bei der Anmeldung, wenn der Zauber einfach bereit ist, wird nichts gesagt.

### Ein Alarm für „Abklingzeit bereit“ (Retail und WoW: Forever)

1. Monitor, Monitor (0), Hinzufügen, Zauber-Abklingzeiten.
2. Regeln, Hinzufügen, Zauber-Abklingzeitregel. Öffne Zauber: Die Schnellauswahlen listen die Zauber der Kategorien Essential und Utility deines Abklingzeitmanagers auf, die eine Abklingzeit haben. Wähle Baumrinde.
3. Öffne Bereit, TTS-Alarm, schalte Aktiviert ein.

Wenn Baumrinde zurückkommt, hörst du „Baumrinde Bereit“, auch im Kampf. Schalte zusätzlich den TTS-Alarm Klingt ab ein, wenn du auch „Baumrinde Klingt ab“ hören willst, sobald du sie benutzt. Belege Verfolgte Abklingzeiten ansagen, um den Zustand und die verbleibende Zeit auf Abruf zu hören.

### Ein Debuff im Kampf auf Retail

1. Stelle in den Einstellungen des Abklingzeitmanagers (`/cdm`) sicher, dass die gewünschte Aura in den Verfolgten Buffs oder Verfolgten Leisten ist.
2. Monitor, Hinzufügen, Auren des Abklingzeitmanagers. Lasse die Einheit auf Ziel.
3. Regeln, Hinzufügen, Aura-Regel des Abklingzeitmanagers. Öffne Zauber: Die Schnellauswahlen listen deine verfolgten Auren auf. Wähle den Debuff.
4. Schalte den TTS-Alarm von Fehlend und Pandemic ein.

Du hörst „Mondfeuer Pandemic“, wenn der Abklingzeitmanager den Debuff als bereit zum Erneuern markiert, und „Mondfeuer Fehlend“, wenn er abfällt.

## Tipps

- Fange mit einem Monitor und einer Regel an und stelle sicher, dass es funktioniert, bevor du mehr hinzufügst.
- Schalte nur die Alarme ein, die du brauchst. Ein Sound bei Aktiv und eine gesprochene Nachricht bei Fehlend sind ein guter Anfang.
- Nimm Vom Spieler gewirkt für Auren im Gruppenspiel, damit die Kopien anderer Spieler nicht zählen. Schalte es für Effekte ohne Wirker aus, etwa viele Procs von Schmuckstücken.
- Gib Monitoren und Regeln klare Bezeichnungen; die Listen zeigen sonst nichts.
- Monitore und Puffer ergänzen sich: Lass einen Monitor dir sagen, wann Mondfeuer abfällt, und lies deine anderen Timer auf Abruf mit einem [Puffer](buffers.md) oder den Ansagetasten.
- Wenn ein Alarm nie auslöst, prüfe in dieser Reihenfolge: Der Monitor ist Aktiviert; die Regel ist Aktiviert; der Zauber ist gesetzt; der Soundalarm oder TTS-Alarm des Zustands ist Aktiviert (sie sind standardmäßig aus); und beim Sound ist ein Sound gewählt worden.
- Wenn ein Alarm auf Retail zu einem merkwürdigen Zeitpunkt auslöst, nutze `/wv cdmlog`, siehe [Fehlerbehebung](../getting-started/troubleshooting.md).
