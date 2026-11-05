# Puffer

Mit Puffern kannst du Spielinformationen jederzeit abrufen, ohne auf eine Ansage zu warten. Dein Leben, dein Mana, dein Gold, deine Erfahrung, die Buffs auf deinem Ziel und die Zeilen eines Chat-Reiters liegen alle in Puffern, die du mit ein paar Tasten durchgehst. Du kannst die Puffer, die mit WowVision kommen, so verwenden, wie sie sind, oder eigene bauen.

Wenn WowVision dich automatisch informieren soll, sobald sich etwas ändert, zum Beispiel wenn ein Debuff von deinem Ziel abfällt, lies stattdessen [Monitore](monitors.md). Beides ergänzt sich gut.

## So sind Puffer aufgebaut

Puffer haben drei Ebenen:

- Eine Gruppe (Puffergruppe) enthält Puffer. Stell dir eine Gruppe als Ordner oder Thema vor, zum Beispiel „Allgemein“ oder „Kampf“.
- Ein Puffer enthält Elemente. Ein Puffer ist die Liste, die du tatsächlich durchgehst.
- Ein Element (Pufferelement) ist eine Zeile Information: dein Leben, dein Geld, eine Aura.

Gruppen können keine anderen Gruppen enthalten, es gibt also nur eine Ebene von Gruppen.

Du hast immer eine aktuelle Gruppe, in dieser Gruppe einen aktuellen Puffer und in diesem Puffer ein aktuelles Element. WowVision merkt sich für jeden Puffer, wo du warst, solange die Spielsitzung dauert. Wenn du später zu einem Puffer zurückkehrst, liest er das Element vor, bei dem du aufgehört hast. Nach einem Neuladen oder einer neuen Anmeldung beginnt jeder Puffer wieder bei seinem ersten Element (ein Chat-Reiter-Puffer bei seiner neuesten Zeile).

## Tasten

| Aktion | Standardtaste | Was du hörst |
|---|---|---|
| Nächstes Pufferelement | Alt+Pfeil runter | Das nächste Element des aktuellen Puffers |
| Vorheriges Pufferelement | Alt+Pfeil hoch | Das vorherige Element des aktuellen Puffers |
| Nächster Puffer | Alt+Pfeil rechts | Der nächste Puffer der aktuellen Gruppe: sein Name, dann sein aktuelles Element |
| Vorheriger Puffer | Alt+Pfeil links | Der vorherige Puffer der aktuellen Gruppe |
| Nächste Puffergruppe | Alt+Strg+Pfeil rechts | Die nächste Gruppe: ihr Name, der Name ihres aktuellen Puffers, dann das aktuelle Element dieses Puffers |
| Vorherige Puffergruppe | Alt+Strg+Pfeil links | Die vorherige Gruppe |

Diese Tasten funktionieren überall im Spiel. Jede unterbricht, was WowVision gerade spricht, du kannst sie also schnell hintereinander drücken. Du kannst die Tasten im Fenster für die Tastenbelegung ändern, siehe [Tastenbelegung](../basics/keybindings.md).

### So verhalten sich die Tasten

- Wenn du in einem Puffer zum ersten Mal Alt+Pfeil runter drückst, landest du auf seinem ersten Element. Danach rückt jeder Tastendruck ein Element Richtung Listenende. Wenn du vorher mit Alt+Pfeil links oder Alt+Pfeil rechts zu einem Puffer gewechselt bist, hörst du sein erstes Element schon zusammen mit seinem Namen, das nächste Alt+Pfeil runter geht also zum zweiten.
- Elemente laufen nicht im Kreis. Beim letzten Element liest Alt+Pfeil runter dieses Element einfach noch einmal vor. Beim ersten Element liest Alt+Pfeil hoch es noch einmal vor.
- Puffer und Gruppen laufen im Kreis. Nach dem letzten Puffer einer Gruppe geht Alt+Pfeil rechts zurück zum ersten.
- Wenn sich ein Element seit dem letzten Mal geändert hat (zum Beispiel dein Leben), wird es jedes Mal neu gelesen, du hörst also immer den aktuellen Wert.
- Ein leerer Puffer (zum Beispiel ein verfolgter Puffer, in dem nichts ist) bleibt stumm, wenn du Alt+Pfeil hoch oder Alt+Pfeil runter drückst. Wenn du mit Alt+Pfeil links oder Alt+Pfeil rechts zu ihm wechselst, hörst du trotzdem seinen Namen.

Beispiel: Du bist im Standardpuffer „Allgemein“.

1. Drücke Alt+Pfeil runter. Du hörst „250 / 500 Leben“.
2. Drücke noch einmal Alt+Pfeil runter. Du hörst „50 / 100 MANA“ (deine Hauptressource).
3. Drücke Alt+Pfeil hoch. Du bist wieder beim Leben.

### Neuestes Element zuletzt und Elementrichtung umkehren

Elemente sind vom ersten bis zum neuesten aufgelistet, das neueste steht zuletzt. Das ist vor allem bei Puffern wichtig, die wachsen, etwa bei einem Chat-Reiter: Alt+Pfeil runter geht Richtung neueste Zeile, Alt+Pfeil hoch Richtung älteste.

Frühere Versionen von WowVision haben es andersherum gemacht (Alt+Pfeil hoch ging Richtung neuestes Element). Wenn du daran gewöhnt bist, schalte die Einstellung Elementrichtung umkehren (Invert Item Direction) ein: Sie vertauscht bei Puffern Alt+Pfeil hoch und Alt+Pfeil runter. Sonst ändert sie nichts. Du findest sie im WowVision-Menü unter Puffer, siehe [Einstellungen](#einstellungen).

### Controller

Mit Gamepad in Retail und WoW: Forever hältst du den Rechten Stickklick gedrückt und benutzt das Steuerkreuz: hoch und runter wechseln zwischen Elementen, links und rechts zwischen Puffern. Halte zusätzlich den Linken Trigger (die Umschalttaste des Controllers) gedrückt und drücke links oder rechts, um zwischen Gruppen zu wechseln. Siehe [Controller](../controller.md).

## Die Standardeinrichtung: die Gruppe Allgemein

Dein Account beginnt mit einer Gruppe namens Allgemein. Sie enthält einen Puffer, der ebenfalls Allgemein heißt. Das ist ein statischer Puffer mit diesen Zeilen in dieser Reihenfolge:

| Zeile | Was sie dir sagt | Beispiel |
|---|---|---|
| Leben (Spieler) | Dein aktuelles und dein maximales Leben | „250 / 500 Leben“ |
| Kraft (Spieler) | Deine Hauptressource: Mana, Wut, Energie und so weiter | „50 / 100 MANA“ |
| EP | Erfahrung in Prozent, die Zahlen, die nächste Stufe und deine erholten Erfahrungspunkte, wenn du welche hast | „EP: 45% (12500 von 25000 bis Stufe 31), erholt 3000“ |
| Geld | Dein Gold, Silber und Kupfer | „5 Gold 23 Silber 45 Kupfer“ |
| Taschen | Freie Plätze in deinen normalen Taschen (Köcher, Munitionsbeutel und Berufstaschen zählen nicht mit) | „Freie Taschenplätze: 12“ |
| Haltbarkeit | Der Prozentwert deines am stärksten abgenutzten Gegenstands und wie viele Gegenstände kaputt sind | „Haltbarkeit: niedrigster Gegenstand 45%, 1 kaputt“ |
| Post | Ob ungelesene Post wartet, und von wem sie ist, wenn das Spiel es weiß | „Post von Thrall, Jaina“, „Neue Post“ oder „Post: keine“ |
| Ruhestein | Bereit, oder die verbleibende Abklingzeit, und wohin er dich bringt | „Ruhestein: bereit, Goldhain“ |
| Uhr | Die Spieluhr, so wie du sie in den Uhroptionen des Spiels eingestellt hast (Realm- oder Ortszeit, 12 oder 24 Stunden) | „Zeit: 20:05“ |
| PVP (Spieler) | Ob du für PvP markiert bist | „PVP: Aktiviert“ |

Auf der Maximalstufe lässt die EP-Zeile die nächste Stufe und den erholten Teil weg. Wenn du keine erholten Erfahrungspunkte hast, entfällt der erholte Teil ebenfalls.

Die Ressource in der Kraft-Zeile trägt den Namen, den das Spiel intern verwendet, in Großbuchstaben: MANA, RAGE, ENERGY, FOCUS, RUNIC_POWER und so weiter. Schrägstriche werden immer mit einem Leerzeichen auf jeder Seite gesprochen („250 / 500“), weil manche Sprachausgaben über einen Schrägstrich stolpern, der direkt an den Zahlen klebt.

Wenn dein Charakter angelegt wurde, bevor es die Zeilen Taschen, Haltbarkeit, Post, Ruhestein und Uhr gab, fügt WowVision sie einmalig vor der PVP-Zeile zu deinem Puffer „Allgemein“ hinzu. Wenn du eine davon danach entfernst, bleibt sie entfernt.

Du kannst alles davon ändern oder entfernen, siehe [Puffer im Menü verwalten](#puffer-im-menü-verwalten).

## Puffertypen

Wenn du einer Gruppe einen Puffer hinzufügst, wählst du einen von vier Typen.

### Statischer Puffer

Ein statischer Puffer enthält eine feste Liste von Elementen, die du auswählst, in der Reihenfolge, in der du sie hinzufügst. Der Puffer „Allgemein“ ist ein statischer Puffer. Nimm ihn für Dinge, die du an einer festen Stelle nachsehen willst: dein Leben und Mana, eine Abklingzeit, dein Geld.

Einstellungen eines statischen Puffers: Aktiviert, Bezeichnung und Objekte, die Liste der Elemente (siehe [Elemente](#elemente-und-was-sie-anzeigen-können)).

### Verfolgter Puffer

Ein verfolgter Puffer füllt und leert sich selbst. Du beschreibst, was beobachtet werden soll (eine Art von Information und, bei Einheiteninformationen, welche Einheit), und der Puffer fügt ein Element hinzu, sobald etwas Passendes auftaucht, und entfernt es, wenn es verschwindet. Du verwaltest die Elemente nicht selbst.

Typische Verwendungen: jede Aura auf deinem Ziel oder jeder deiner Zauber, der gerade in Abklingzeit ist.

Auf Retail und WoW: Forever werden verfolgte Puffer nicht angeboten, weil das Spiel dort fast alles, was sie verfolgen könnten, vor Addons verbirgt. Nimm einen Aura-Puffer für Auren, den Monitor Zauber-Abklingzeiten für Abklingzeiten (siehe [Monitore](monitors.md)) und einen statischen Puffer für alles andere. Ein verfolgter Puffer, den du früher angelegt hast, bleibt in deiner Liste.

Einstellungen eines verfolgten Puffers: Aktiviert, Bezeichnung und Quelle. Die Quelle hat einen Typ (was verfolgt werden soll) und bei den meisten Typen Parameter wie die Einheit. Ein frisch hinzugefügter verfolgter Puffer hat noch keinen Typ („Keine“) und bleibt leer, bis du einen auswählst.

Hinweise:

- Verfolgte Puffer lesen jedes Element mit der Standardformulierung des Typs vor. Du kannst ihren Elementen kein eigenes Format geben.
- Für Auren ist der eigene Aura-Puffer (unten) die bessere Wahl: Er funktioniert auf Retail auch im Kampf und in Instanzen.

### Aura-Puffer

Ein Aura-Puffer listet die Buffs und Debuffs auf einer oder mehreren Einheiten auf, jede, die das Spiel kennt, nicht nur die auf dem Bildschirm gezeichneten. Die Auren folgen in einer einzigen Liste aufeinander, ohne Überschriften dazwischen.

Einstellungen:

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Aktiviert | An | Der Ein/Aus-Schalter des Puffers (siehe [Etwas vorübergehend ausschalten](#etwas-vorübergehend-ausschalten)) |
| Bezeichnung | „Neu Aura-Puffer“, wenn er über das Menü hinzugefügt wird | Der Name, den du hörst, wenn du zum Puffer wechselst. Wenn du ihn leerst, heißt der Puffer wie seine Quelle (zum Beispiel „Ziel-Debuffs“) oder „Auren“, wenn er mehrere hat |
| Quellen | Spieler-Debuffs, dann Spieler-Buffs | Die Liste der Quellen, in der Reihenfolge, in der sie im Puffer stehen |
| Verbleibende Zeit ansagen (Speak Time Remaining) | An | Ob eine Aura sagt, wie lange sie noch dauert |
| Beschreibung ansagen (Speak Description) | An | Ob eine Aura sagt, was sie bewirkt |
| Von mir gewirkt, Von mir wirkbar oder bannbar, Abbrechbar, CC, Von meiner Gruppe bannbar, Bannbar, Externe Verteidigung, Große Verteidigung, Im Kampf auf Schlachtzugsrahmen angezeigt, Wichtig | Egal | Je ein Filter, siehe unten |

Jeder Filter ist eine Auswahl mit bis zu drei Werten. Egal ignoriert den Filter. Nur diese behält genau die Auren, die er beschreibt. Ohne diese lässt diese Auren weg. Zum Beispiel listet Von mir gewirkt auf Nur diese nur Auren, die du gewirkt hast, und CC auf Ohne diese blendet Betäubungen, Furcht und Ähnliches aus. Du kannst mehrere Filter kombinieren; eine Aura muss alle bestehen. Die Filter funktionieren auch auf Retail im Kampf und in Instanzen.

- Von mir gewirkt: Auren, die du gewirkt hast.
- Von mir wirkbar oder bannbar: Auren, die du wirken oder bannen könntest.
- Abbrechbar: Buffs, die du abbrechen kannst.
- CC: Betäubungen, Furcht, Verwandlungen und Ähnliches.
- Von meiner Gruppe bannbar: Auren, die jemand in deiner Gruppe bannen kann.
- Bannbar: Auren, die gebannt werden können.
- Externe Verteidigung: Verteidigungseffekte, die andere auf dich wirken.
- Große Verteidigung: starke Verteidigungseffekte.
- Im Kampf auf Schlachtzugsrahmen angezeigt: Auren, die das Spiel im Kampf auf den Schlachtzugsrahmen anzeigt.
- Wichtig: Auren, die das Spiel als wichtig kennzeichnet.

Auf Retail und WoW: Forever bietet jeder Filter Egal, Nur diese und Ohne diese. Auf Classic Era, The Burning Crusade und Mists of Pandaria bietet nur Abbrechbar auch Ohne diese; die anderen bieten Egal und Nur diese. Eine Spielversion bietet nur die Filter an, die sie kennt, deshalb ist die Liste auf manchen Versionen kürzer. Die alte Einstellung Nur meine Auren ist jetzt Von mir gewirkt; ein Puffer, bei dem Nur meine Auren an war, listet weiter nur deine eigenen Auren, bis du Von mir gewirkt einstellst.

Die verfügbaren Quellen sind Spieler-Debuffs, Spieler-Buffs, Ziel-Debuffs, Ziel-Buffs, Fokus-Debuffs, Fokus-Buffs, Begleiter-Debuffs und Begleiter-Buffs. Du kannst sie beliebig mischen, und die Reihenfolge der Liste Quellen ist die Reihenfolge, in der du sie hörst.

Was du zu einer Aura hörst: ihren Namen; ihre Stapelzahl, wenn sie Stapel hat; die verbleibende Zeit, wenn sie eine Dauer hat; bei Debuffs ihre Bannart (Magie, Fluch, Gift, Krankheit); und zuletzt ihre Beschreibung, also was die Aura tut. Zum Beispiel: „Mondfeuer, noch 12 Sek., Magie, Verbrennt den Feind alle 3 Sek. für 4 Arkanschaden“, oder mit Stapeln „Verjüngung, 2 Stapel, noch 9 Sek., Heilt 50 Schaden über 15 Sek.“. Die Beschreibung kommt zuletzt, so kannst du die Sprache mit Strg anhalten, sobald du genug gehört hast. Verbleibende Zeit ansagen und Beschreibung ansagen lassen diese Teile weg. Die Tooltip-Tasten lesen sie trotzdem.

Wenn eine Quelle nichts aufzulisten hat, sagt der Puffer es, statt stumm zu bleiben: „Ziel-Debuffs, keine“, „Ziel-Debuffs, kein Ziel“, „Fokus-Buffs, kein Fokus“, „Begleiter-Buffs, kein Begleiter“ oder „nicht verfügbar“, wenn das Spiel es nicht verrät. Eine Aura, die verschwindet, während du auf ihr bist, wird als „Verschwunden“ gelesen.

Solange du auf einer Aura bist, lesen die Tooltip-Tasten sie Zeile für Zeile: Umschalt+Pfeil runter und Umschalt+Pfeil hoch gehen durch ihren Namen, ihre Beschreibung und die verbleibende Zeit, und Umschalt+Pfeil links und Umschalt+Pfeil rechts lesen den linken oder rechten Teil der aktuellen Zeile. Das funktioniert auch im Kampf, und die verbleibende Zeit ist bei jedem Tastendruck aktuell. Siehe [Tooltips](../basics/tooltips.md).

Die Liste aktualisiert sich von selbst, wenn Auren kommen und gehen oder wenn sich die Einheit ändert (du wählst ein anderes Ziel), und sie behält deine Position.

Auf Retail schließt das Spiel im Kampf und in Instanzen seine Aura-Liste für Addons. Der Aura-Puffer liest dann jede Aura aus dem Tooltip des Spiels: Du hörst weiterhin den Namen, bei Debuffs die Bannart und danach den Rest des Tooltips in der Reihenfolge des Spiels: die Beschreibung, dann die verbleibende Zeit. Die beiden lassen sich dort nicht trennen: Ist Beschreibung ansagen aus, hörst du die letzte Zeile des Tooltips, solange Verbleibende Zeit ansagen an ist, und ist Beschreibung ansagen an, kannst du die verbleibende Zeit trotzdem hören. Die Stapelzahl wird nur für deine eigenen Auren gelesen, in einem Puffer ohne gesetzte Filter, und nur für Auren, die das Spiel auf seinen eigenen Buff- und Debuff-Leisten zeigt.

### Chat-Reiter-Puffer

Ein Chat-Reiter-Puffer enthält die Zeilen eines deiner Chat-Reiter, dieselben Zeilen, die das Chatfenster zeigt, sodass du sie mit den Puffertasten lesen kannst, ohne etwas zu öffnen. Die Chat-Funktionen selbst findest du unter [Chat](../windows/chat.md).

Einstellungen: Aktiviert, Bezeichnung und Chat-Reiter, eine Auswahl unter den Chat-Reitern, die gerade offen sind (mit ihren Namen, wie im Spiel festgelegt), plus Flüster-Reiter, der die Zeilen all deiner Flüster-Reiter zusammenfasst. Ein neuer Chat-Reiter-Puffer beginnt bei deinem ersten Chat-Reiter. Welche Nachrichten ein Reiter erhält, bestimmen die eigenen Chat-Einstellungen des Spiels für diesen Reiter.

Jede Zeile wird als die Nachricht gelesen, gefolgt von ihrem Datum und ihrer Uhrzeit. Der Puffer behält bis zu 5000 Zeilen. Er öffnet sich bei der neuesten Zeile und folgt neuen Zeilen, sobald sie eintreffen, wie ein Chatprotokoll. Sobald du mit Alt+Pfeil hoch (oder mit Alt+Pfeil runter, wenn Elementrichtung umkehren an ist) in ältere Zeilen zurückgegangen bist, bleibt er dort, wo du bist, bis du zur neuesten Zeile zurückkehrst.

Wenn du die Bezeichnung leerst, heißt der Puffer wie sein Reiter.

## Elemente und was sie anzeigen können

Ein Element in einem statischen Puffer zeigt ein „Ding“, das WowVision Objekttyp nennt. Wenn du ein Element hinzufügst, wählst du den Typ aus einer Liste. Manche Typen brauchen etwas mehr Information, sogenannte Parameter.

| Typ | Was er anzeigt | Parameter | Beispiel |
|---|---|---|---|
| Leben | Aktuelles und maximales Leben einer Einheit | Einheit | „250 / 500 Leben“ |
| Kraft | Eine Ressource einer Einheit | Einheit, Krafttyp | „50 / 100 Energie“ |
| PVP | Ob eine Einheit für PvP markiert ist | Einheit | „PVP: Aktiviert“ |
| EP | Deine Erfahrung, nächste Stufe und erholte Erfahrung | Keine | „EP: 45% (12500 von 25000 bis Stufe 31)“ |
| Geld | Dein Geld | Keine | „5 Gold 23 Silber 45 Kupfer“ |
| Taschen | Freie Plätze in normalen Taschen | Keine | „Freie Taschenplätze: 12“ |
| Haltbarkeit | Am stärksten abgenutzter Gegenstand und Zahl der kaputten Gegenstände | Keine | „Haltbarkeit: niedrigster Gegenstand 87%“ oder „Haltbarkeit: 100%“ |
| Post | Ungelesene Post und die ersten Absender | Keine | „Post von Thrall, Jaina“ oder „Post: keine“ |
| Ruhestein | Abklingzeit und Heimatort | Keine | „Ruhestein: 20 Minuten 5 Sekunden, Goldhain“ |
| Uhr | Die Spieluhr | Keine | „Zeit: 20:05“ |
| Abklingzeit | Die Abklingzeit eines Zaubers | Zauber-ID, Klingt ab | „Baumrinde: Bereit“ oder „Baumrinde: 12.3s“ |
| Aura | Eine Aura auf einer Einheit | Einheit | „Verjüngung Stapel 0 12 Sekunden“ |

Die Liste, aus der du auswählst, zeigt diese Namen. Typen ohne Parameter fragen nie nach mehr. Die Namen des Typs, der Einheit und so weiter bilden auch den Namen des Elements in der Elementliste, zum Beispiel „Kraft (player, Mana)“.

Die Formulierung eines Aura-Elements ist fest: ihr Name, das Wort „Stapel“ und die Stapelzahl (0 bei einer Aura, die nicht stapelt), dann die verbleibende Zeit, wenn es eine gibt.

### Parameter

- Einheit: jede Einheit, die das Spiel mit Namen kennt, als Text eingegeben. Die gängigen sind `player`, `target`, `focus`, `pet`, `mouseover`, `targettarget`, `party1` bis `party4` und `raid1` aufwärts.
- Krafttyp: welche Ressource gelesen werden soll, zum Beispiel Mana, Wut, Energie, Fokus, Runenmacht, Kombopunkte, Seelensplitter, Heilige Kraft, Chi, Wahnsinn, Mahlstrom, Zorn, Schmerz, Essenz, Runen. Die Liste enthält jeden Krafttyp, den deine Spielversion kennt, beginnend mit Mana; wähle also einen, den deine Klasse tatsächlich benutzt. Wenn du den Typ eines Elements oder eines verfolgten Puffers auf Kraft stellst, beginnt der Krafttyp bei Mana; öffne Parameter, wenn du einen anderen willst. Ein verfolgter Kraft-Puffer listet jede Ressource auf, die die Einheit hat, und nimmt auch eine Ressource auf, die erst später auftaucht, zum Beispiel Kombopunkte, sobald du sie aufbaust.
- Zauber-ID (Abklingzeit): der Zauber, der beobachtet werden soll. Du kannst seinen Namen oder seine Nummer eingeben oder ihn aus der Liste der Zauber wählen, die dieser Charakter gewirkt (oder als Auren getroffen) hat. Siehe [Einen Zauber auswählen](monitors.md#einen-zauber-auswählen) auf der Seite Monitore.
- Klingt ab (Abklingzeit): ein Ja/Nein-Filter, den verfolgte Puffer benutzen. An bedeutet „nur Zauber, die gerade in Abklingzeit sind“. Aus, nachdem du ihn ein- und wieder ausgeschaltet hast, bedeutet „nur Zauber, die bereit sind“. Wenn du ihn nie anfasst, gibt es keinen Filter.

### Was du zu den einzelnen Typen wissen solltest

- Aura-Elemente sind für verfolgte Puffer gedacht. Ein statischer Puffer braucht ein Element, das auf genau eine Sache zeigt, und eine Aura wird nur durch eine interne Nummer erkannt, die sich bei jedem Anwenden ändert. Deshalb lässt dich das Menü keinen Aura-Parametersatz in einem statischen Puffer speichern. Nimm einen verfolgten Puffer oder einen Aura-Puffer.
- Kraft in einem statischen Puffer braucht einen Krafttyp; ohne einen verweigert das Menü das Speichern („Parameter müssen ein einzelnes Objekt identifizieren“). Die Kraft-Zeile im Standardpuffer „Allgemein“ ist die Ausnahme: Sie hat keinen Krafttyp und liest einfach deine Hauptressource, welche auch immer es ist.
- Abklingzeit braucht in einem statischen Puffer eine Zauber-ID. In einem verfolgten Puffer kannst du den Zauber weglassen und nur Klingt ab setzen: Der Puffer sammelt dann die Zauber, die du gewirkt hast und die eine echte Abklingzeit haben (die globale Abklingzeit zählt nie), und zeigt nur die in Abklingzeit. Zauber erscheinen, nachdem du sie in dieser Sitzung einmal gewirkt hast. Ein verfolgter Abklingzeit-Puffer braucht mindestens eine Zauber-ID oder Klingt ab, um gespeichert zu werden, sonst hörst du „Ungültige Parameter“.
- Abklingzeit-Elemente arbeiten über die normalen Abklingzeit-Funktionen des Spiels. Auf Retail verbirgt das Spiel im Kampf und in Instanzen die Abklingzeitzahlen vor Addons, nimm dort also den Monitor Zauber-Abklingzeiten und seine Taste Verfolgte Abklingzeiten ansagen, siehe [Monitore](monitors.md).
- Leben und Kraft anderer Einheiten können auf Retail im Kampf unlesbar sein; WowVision spricht, was das Spiel erlaubt.
- Ruhestein teilt sich eine Abklingzeit für alle Ruhesteine, meldet also die richtige Zeit, egal welchen Ruhestein du dabeihast. Wenn das Spiel die Abklingzeit verbirgt, hörst du nur den Heimatort.
- Ohne Ziel hat ein Leben-Element für `target` nichts Echtes zu lesen. Wo du verfolgte Puffer hast, ist einer die sauberere Wahl für das Ziel, weil er einfach leer ist, wenn du kein Ziel hast.

### Eigene Formate

Jedes Element in einem statischen Puffer hat eine Einstellung Vorlage, die die Formulierung steuert. Standardmäßig steht sie auf Standard, also der Standardformulierung des Typs (die Beispiele oben).

Bei Typen mit einer registrierten Formulierung (Leben, Kraft, PVP, Uhr, Taschen, Abklingzeit) bietet die Liste Standard und Benutzerdefiniert an. Bei den anderen (EP, Geld, Haltbarkeit, Post, Ruhestein) wird nur Benutzerdefiniert angeboten. Wenn du Benutzerdefiniert wählst, öffnet sich ein Textfeld namens Format. Gib deine eigene Formulierung ein und drücke Eingabe. Wenn du es leer lässt und bestätigst, kehrt das Element zu seiner Standardformulierung zurück.

Ein Unterschied: Bei einem Abklingzeit-Element lautet die Standardformulierung (wenn die Vorlage nie gesetzt wurde) „Baumrinde: Bereit“ oder „Baumrinde: 12.3s“, während die Wahl von Standard in der Liste „Baumrinde: 12 Sekunden“ ergibt (und „Baumrinde: 0 Sekunden“, wenn der Zauber bereit ist).

Ein Format ist einfacher Text mit zwei Arten von Platzhaltern:

- `{name}` wird durch einen Wert ersetzt. Zum Beispiel ist `{current}` das aktuelle Leben.
- `[word]` wird durch dieses Wort in deiner Sprache ersetzt, für Wörter, die WowVision kennt, wie `[Health]`, `[of]`, `[ready]`. Du schreibst dabei immer das englische Schlüsselwort in die Klammern; gesprochen wird die deutsche Entsprechung („Leben“, „von“, „bereit“). Wenn WowVision das Wort nicht kennt, wird der Text in den Klammern so gesprochen, wie du ihn getippt hast.
- Um eine geschweifte oder eckige Klammer wörtlich zu schreiben, verdopple sie: `{{`, `}}`, `[[`, `]]`.
- Ein Schrägstrich in deinem eigenen Text wird wie bei den Standardformulierungen mit einem Leerzeichen auf jeder Seite gesprochen.

Beispiel: Für ein Leben-Element liest das Format `{current} von {maximum}` „250 von 500“. Ein weiteres: `[Health] {current}` liest „Leben 250“.

Benutze in einem Format nur Text- und Zahlenwerte. Ja/Nein-Werte (wie bereit oder ungelesen) lassen sich nicht in ein Format einsetzen; sie fehlen in der Liste unten, und wenn du einen benutzt, schlägt diese Zeile mit einem Fehler fehl, statt zu sprechen.

Die Werte, die du benutzen kannst, nach Typ:

| Typ | Werte |
|---|---|
| Leben | `current`, `maximum`, `minimum` |
| Kraft | `current`, `maximum`, `minimum`, `label` (der Name der Kraft) |
| PVP | `status` („Aktiviert“ oder „Deaktiviert“) |
| EP | `current`, `maximum`, `percent`, `nextLevel`, `rested` |
| Geld | `current` (in Kupfer), `formatted` (Gold, Silber und Kupfer in Worten) |
| Taschen | `free` |
| Haltbarkeit | `lowest` (Prozent des am stärksten abgenutzten Gegenstands), `broken` (Zahl der kaputten Gegenstände) |
| Post | `senders` (bis zu drei Namen) |
| Ruhestein | `remaining` (verbleibende Zeit, leer wenn bereit), `location` |
| Uhr | `time` |
| Abklingzeit | `name`, `remaining` (verbleibende Zeit in Worten), `charges`, `maxCharges`, `duration`, `startTime`, `spellId` |

Ein Wert, der nichts zu sagen hat, etwa `rested`, wenn du keine erholten Erfahrungspunkte hast, fügt einfach nichts hinzu. Zeitwerte werden in Worten gesprochen („1 Minute 5 Sekunden“).

Beispiel: Damit die Geld-Zeile „Ich habe 5 Gold 23 Silber 45 Kupfer“ sagt, setze ihre Vorlage auf Benutzerdefiniert mit dem Format `Ich habe {formatted}`.

## Puffer im Menü verwalten

Die gesamte Pufferverwaltung läuft über das WowVision-Menü. Das Menü ist dieselbe tastaturgesteuerte Liste, die überall sonst in WowVision benutzt wird, siehe [Das WowVision-Menü und die Einstellungen](../basics/menu-and-settings.md) und [Die Oberfläche bedienen](../basics/interface.md).

### Die Puffereinstellungen öffnen

1. Drücke Umschalt+F1 (oder gib `/wv` ein), um das WowVision-Menü zu öffnen.
2. Gehe zu Puffer und drücke Eingabe. Der Bildschirm zeigt in dieser Reihenfolge einen Schalter Aktiviert, eine Schaltfläche namens Puffer gefolgt von der Zahl der Gruppen, zum Beispiel „Puffer (1)“, und die Einstellung Elementrichtung umkehren.
3. Drücke Eingabe auf Puffer (1). Du siehst deine Gruppen, je eine Schaltfläche, gefolgt von einer Schaltfläche Hinzufügen.

Mit Esc gehst du einen Bildschirm zurück.

### Die Ebenen des Menüs

- In der Gruppenliste öffnet Eingabe auf einer Gruppe diese Gruppe. Sie hat Aktiviert, Bezeichnung, eine Schaltfläche Puffer mit der Zahl der Puffer in der Gruppe und Entfernen.
- Eingabe auf der Schaltfläche Puffer zeigt die Puffer der Gruppe und eine Schaltfläche Hinzufügen. Eingabe auf einem Puffer öffnet ihn. Ein Puffer hat Aktiviert, Bezeichnung, seine typspezifischen Einstellungen und Entfernen.
- Bei einem statischen Puffer ist die typspezifische Einstellung die Schaltfläche Objekte (mit der Zahl der Elemente), die die Elemente und eine Schaltfläche Hinzufügen auflistet. Eingabe auf einem Element öffnet es: Objekt, Vorlage und Entfernen.

### Eine Gruppe hinzufügen

1. Gehe in der Gruppenliste zu Hinzufügen und drücke Eingabe.
2. Der Bildschirm Typ auswählen hat einen Eintrag, Puffergruppe. Drücke Eingabe.
3. Die neue Gruppe öffnet sich, sie heißt „Neu Puffergruppe“. Ändere die Bezeichnung in einen Namen, der dir gefällt (Eingabe darauf, tippen, noch einmal Eingabe).

### Einen Puffer zu einer Gruppe hinzufügen

1. Öffne die Gruppe, drücke Eingabe auf Puffer, dann auf Hinzufügen.
2. Wähle den Typ: Statischer Puffer, Verfolgter Puffer (nicht auf Retail und WoW: Forever), Aura-Puffer oder Chat-Reiter-Puffer.
3. Der neue Puffer öffnet sich, er heißt „Neu Statischer Puffer“ (und so weiter). Setze die Bezeichnung auf einen Namen, der sagt, was es ist. Das ist der Name, den du hörst, wenn du zu ihm wechselst.
4. Fülle die typspezifischen Einstellungen aus (die Liste Objekte, die Quelle, die Quellen oder den Chat-Reiter).

### Ein Element zu einem statischen Puffer hinzufügen

1. Öffne den Puffer, gehe zu Objekte und drücke Eingabe.
2. Drücke Eingabe auf Hinzufügen. Die Liste Typ auswählen zeigt die Objekttypen (Aura, Leben, Kraft, PVP, EP, Geld, Taschen, Haltbarkeit, Post, Ruhestein, Uhr, Abklingzeit).
3. Wähle einen aus. Das neue Element öffnet sich.
4. Wenn der Typ Parameter hat, drücke Eingabe auf Objekt. Der Bildschirm hat eine Auswahl Typ (du kannst den Typ hier noch ändern) und bei Typen mit Parametern eine Schaltfläche Parameter. Drücke Eingabe auf Parameter, fülle Einheit, Krafttyp oder Zauber-ID aus, gehe dann zu Speichern und drücke Eingabe. WowVision prüft die Parameter und sagt dir „Ungültige Parameter“ oder „Parameter müssen ein einzelnes Objekt identifizieren“, wenn etwas fehlt.

Setze die Einheit bei Leben-, Kraft- und PVP-Elementen immer ausdrücklich, auch wenn du `player` willst: Ein gerade hinzugefügtes Element hat noch keine Einheit. Das Feld Einheit zeigt „player“, aber Speichern kennt nur das, was du hineingetippt hast. Wenn du also speicherst, ohne das Feld anzufassen, hörst du „Ungültige Parameter“. (Wenn du den Typ eines Elements oder eines verfolgten Puffers auf einen Einheitentyp änderst, wird `player` dagegen für dich eingetragen.)

Elemente werden am Ende der Liste hinzugefügt.

### Etwas ändern oder umbenennen

Öffne die Gruppe, den Puffer oder das Element und ändere seine Einstellungen. Änderungen gelten sofort; es gibt keine Schaltfläche Speichern, außer im Parameterbildschirm. Um eine Gruppe oder einen Puffer umzubenennen, ändere seine Bezeichnung. Elemente haben keine eigene Bezeichnung; ihr Name kommt von ihrem Typ und ihren Parametern.

### Etwas entfernen

Öffne die Gruppe, den Puffer oder das Element und drücke Eingabe auf Entfernen. Es gibt weder eine Rückfrage noch ein Rückgängigmachen. Wenn du eine Gruppe entfernst, entfernst du alle ihre Puffer; wenn du einen Puffer entfernst, entfernst du alle seine Elemente. Wenn du die Standardgruppe „Allgemein“ versehentlich entfernst, musst du sie von Hand neu aufbauen.

### Die Reihenfolge ändern

Das Menü hat kein Nach-oben- oder Nach-unten-Verschieben. Gruppen, Puffer und Elemente erscheinen in der Reihenfolge, in der sie hinzugefügt wurden. Um die Reihenfolge zu ändern, entferne alles, was nach dem Element steht, das du verschieben willst, und füge es in der gewünschten Reihenfolge wieder hinzu.

### Etwas vorübergehend ausschalten

Gruppen und Puffer haben einen Schalter Aktiviert. Eine ausgeschaltete Gruppe oder ein ausgeschalteter Puffer behält seine Einstellungen, aber Alt+Pfeil links, Alt+Pfeil rechts, Alt+Strg+Pfeil links und Alt+Strg+Pfeil rechts überspringen ihn. Schaltest du ihn wieder ein, ist er wieder an seinem Platz. Sind alle anderen Puffer einer Gruppe aus, bleiben Alt+Pfeil links und Alt+Pfeil rechts dort, wo du bist. Der Schalter Aktiviert auf dem Bildschirm Puffer selbst schaltet dagegen die ganze Pufferfunktion aus.

### Accountweit oder pro Charakter

WowVision speichert Einstellungen an zwei Orten: einmal für deinen ganzen Account („Global“) und einmal für jeden Charakter.

- Gruppen werden standardmäßig accountweit gespeichert, jeder Charakter sieht sie also, und eine Änderung auf einem Charakter gilt für alle. Das gilt auch für die Standardgruppe „Allgemein“.
- Wenn sich ein Charakter zum ersten Mal einloggt, seit Puffer accountweit sind, kommen seine Gruppen zu denen des Accounts. Eine Gruppe geht in die Account-Gruppe mit demselben Namen auf, die nur die Puffer übernimmt, die ihr noch fehlen; ein geänderter Puffer steht also neben dem des Accounts. Jede andere Gruppe zieht unverändert um.
- Um zu ändern, wo eine Gruppe liegt, gehe zur Gruppenliste, wechsle zur Gruppe und drücke Umschalt+F10 (das Kontextmenü). Wähle Bereich, dann Global (alle Charaktere) oder den Namen deines Charakters (nur dieser Charakter). Die Puffer und Elemente in einer Gruppe wandern mit ihr und haben keine eigene Bereichsauswahl.
- Um alles auf einmal zu ändern, öffne das WowVision-Menü, gehe zu Puffer, drücke Umschalt+F10, wähle Bereich und dann Global oder deinen Charakter.
- Auch für die Einstellung Elementrichtung umkehren kannst du mit Umschalt+F10 einen Bereich wählen. Sie gilt standardmäßig accountweit.

Beim Wechseln eines Bereichs wird nichts gelöscht: Wenn du deinen Charakter wählst, wird die aktuelle Einrichtung auf diesen Charakter kopiert, und wenn du Global wählst, wird die Account-Version übernommen.

## Beispiele

### Das Leben deines Ziels hören

Am einfachsten geht das mit einem verfolgten Puffer, weil er leer ist, wenn du kein Ziel hast, und sich bei jedem neuen Ziel neu füllt. Auf Retail und WoW: Forever nimmst du den statischen Puffer am Ende dieses Beispiels.

1. Öffne das WowVision-Menü mit Umschalt+F1 und gehe zu Puffer, dann Puffer (1), dann Allgemein, dann Puffer.
2. Drücke Hinzufügen, wähle Verfolgter Puffer.
3. Setze die Bezeichnung auf „Zielleben“.
4. Drücke Eingabe auf Quelle. Setze den Typ auf Leben.
5. Drücke Eingabe auf Parameter. Setze Einheit auf `target`, dann Speichern.
6. Schließe das Menü. Wähle etwas als Ziel und drücke dann Alt+Pfeil rechts, bis du „Zielleben“ hörst, gefolgt vom Leben deines Ziels, zum Beispiel „Zielleben 8200 / 12000 Leben“. Mit Alt+Pfeil runter liest du es noch einmal.

Wenn du lieber einen statischen Puffer nimmst: Füge einen Puffer vom Typ Statischer Puffer hinzu, öffne Objekte, Hinzufügen, Leben, und setze dann bei den Parametern des Elements die Einheit `target`. Ohne Ziel gibt es nichts zu lesen, siehe oben.

### Die Debuffs auf deinem Ziel hören

1. Drücke in der Liste Puffer der Gruppe auf Hinzufügen und wähle Aura-Puffer.
2. Setze die Bezeichnung auf „Ziel-Debuffs“.
3. Drücke Eingabe auf Quellen (2). Du siehst zwei Zeilen, „Spieler-Debuffs“ und „Spieler-Buffs“, jede mit einer Auswahl und einer Schaltfläche Entfernen, und am Ende eine Schaltfläche Hinzufügen. Ändere die erste Zeile auf Ziel-Debuffs und drücke Entfernen auf der zweiten Zeile, sodass nur eine Quelle übrig bleibt. (Hinzufügen hängt eine neue Zeile an, die als „Spieler-Debuffs“ beginnt; ändere sie auf eine beliebige Quelle.)
4. Stelle Von mir gewirkt auf Nur diese, wenn dich nur deine eigenen Debuffs interessieren.
5. Wähle im Spiel einen Gegner als Ziel und drücke Alt+Pfeil rechts, bis du „Ziel-Debuffs“ hörst. Drücke dann Alt+Pfeil runter, um die Debuffs durchzugehen: „Mondfeuer, noch 12 Sek., Magie, Verbrennt den Feind alle 3 Sek. für 4 Arkanschaden“.

### Eine andere Kraft als deine Hauptkraft beobachten

1. Füge einen Puffer vom Typ Statischer Puffer namens „Ressourcen“ hinzu.
2. Objekte, Hinzufügen, Kraft.
3. Öffne das Element, Objekt, Parameter. Setze Einheit auf `player` und Krafttyp auf den gewünschten, zum Beispiel Kombopunkte. Speichern.
4. Im Spiel: Alt+Pfeil rechts bis „Ressourcen“, dann Alt+Pfeil runter: „3 / 5 Kombopunkte“.

### Jeden Zauber sehen, der gerade in Abklingzeit ist

Auf Retail und WoW: Forever nimmst du stattdessen den Monitor Zauber-Abklingzeiten und seine Taste Verfolgte Abklingzeiten ansagen, siehe [Monitore](monitors.md).

1. Füge einen Puffer vom Typ Verfolgter Puffer namens „Abklingzeiten“ hinzu.
2. Öffne Quelle, setze den Typ auf Abklingzeit, öffne Parameter, schalte Klingt ab ein und wähle Speichern.
3. Wirke ein paar Zauber. Immer wenn einer in Abklingzeit ist, taucht er im Puffer auf. Gehe sie mit Alt+Pfeil runter durch: „Baumrinde: 12.3s“.

### Chat lesen, ohne ihn zu öffnen

1. Füge einen Chat-Reiter-Puffer hinzu. Setze die Bezeichnung auf „Flüstern“.
2. Setze Chat-Reiter auf Flüster-Reiter.
3. Drücke Alt+Pfeil rechts, um zu ihm zu wechseln: Du hörst den Namen und die neueste Flüsternachricht. Alt+Pfeil hoch geht zurück in ältere Zeilen.

## Einstellungen

Der Bildschirm Puffer im WowVision-Menü hat:

| Einstellung | Standard | Was sie bewirkt |
|---|---|---|
| Aktiviert | An | Schaltet die Pufferfunktion ein oder aus (die Alt-Tasten funktionieren nicht, solange sie aus ist) |
| Puffer | eine Gruppe | Die Liste der Gruppen |
| Elementrichtung umkehren | Aus | Vertauscht Alt+Pfeil hoch und Alt+Pfeil runter, sodass Alt+Pfeil hoch Richtung neuestes Element geht |

Die Einstellungen der Dinge, die du hinzufügst (Gruppe, Puffer, Element), sind in den Abschnitten oben beschrieben. Für Puffer gibt es keine Alarme; es wird nichts gesprochen, bis du eine Taste drückst.

## Verfügbarkeit

| Funktion | Classic Era | The Burning Crusade | Mists of Pandaria | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Gruppen, statische und Chat-Reiter-Puffer | Ja | Ja | Ja | Ja | Ja |
| Verfolgter Puffer | Ja | Ja | Ja | Nein | Nein |
| Aura-Puffer | Ja | Ja | Ja | Ja | Ja |
| Aura-Puffer-Filter mit Egal und Nur diese | Ja | Ja | Ja | Ja | Ja |
| Aura-Puffer-Filter mit Ohne diese | Nur Abbrechbar | Nur Abbrechbar | Nur Abbrechbar | Alle Filter | Alle Filter |
| Tooltip einer Aura mit den Tooltip-Tasten lesen | Ja | Ja | Ja | Ja | Ja |
| Alle oben aufgeführten Objekttypen | Ja | Ja | Ja | Ja | Ja |
| Auswahl eines Krafttyps | Ja | Ja | Ja | Ja | Ja |

Die vollständige Funktionsübersicht findest du unter [Funktionen nach Spielversion](../reference/versions.md).

## Tipps

- Halte den Puffer „Allgemein“ kurz und lege deine eigenen Dinge in eigene Puffer. Mit Alt+Pfeil links und Alt+Pfeil rechts zwischen Puffern zu wechseln geht schneller, als eine lange Liste durchzugehen.
- Benenne Puffer danach, was du dir selbst sagen würdest: „Ziel-Debuffs“, „Abklingzeiten“, „Flüstern“. Der Name ist das Erste, was du hörst.
- Nimm einen Aura-Puffer für Buffs und Debuffs, einen statischen Puffer für feste Fakten und, wo es ihn gibt, einen verfolgten Puffer für „alles, was gerade passt“.
- Wenn sich Alt+Pfeil hoch und Alt+Pfeil runter verkehrt anfühlen, bist du wahrscheinlich das ältere Verhalten gewohnt: Schalte Elementrichtung umkehren ein.
- Puffer zeigen Informationen auf Abruf. Wenn dir etwas gesagt werden soll, sobald es passiert, richte einen [Monitor](monitors.md) ein.
- Wenn die Tasten nichts tun, siehe [Fehlerbehebung](../getting-started/troubleshooting.md).
