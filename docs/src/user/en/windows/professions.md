# Professions

This page covers everything you use to make and improve items: the trade skill windows where you craft, the enchanting and beast training window, gem socketing, reforging and item upgrades. WowVision reads each window as a list of stops that you walk with Tab and the arrow keys.

## Where it is available

| Window | Classic Era | TBC | Mists | Retail | WoW: Forever |
|---|---|---|---|---|---|
| Trade skill (crafting) window | No | Yes | Yes | No | Replaced by the crafting page |
| Craft window (Enchanting, Beast Training) | No | Yes | No | No | No |
| Gem socketing | No | Yes | Yes | No | No |
| Reforging | No | No | Yes | No | No |
| Item upgrade | No | No | Yes | No | No |
| Professions book and crafting page | No | No | No | No | Yes |

"No" means WowVision does not read it yet. For the main profession windows and the item improvement windows, you can switch the reading off or on with the Enabled toggle in the WowVision menu (Shift+F1, then Windows, then the window's name: Trade Skill, Craft, Socketing, Reforging, Item Upgrade or Professions). See [The WowVision menu](../basics/menu-and-settings.md).

If the Sku addon is loaded, WowVision does not read the TBC trade skill and craft windows, nor the reforging and item upgrade windows.

## Opening a profession window

The trade skill windows open when you use the profession itself:

- On TBC and Mists, press Enter on the profession's spell button (in the Mists spellbook on the Professions tab, see [Spells and talents](spells-and-talents.md)), or cast it from an action bar, or with a macro such as `/cast Tailoring`.
- On WoW: Forever, press the game's professions key to open the professions book, then Enter on the profession's spell. See below.

Escape closes any of these windows.

## The trade skill window (TBC and Mists)

Used by every crafting profession except Enchanting and Beast Training. The window is named after the profession ("Tailoring", "First Aid") and the screen reads as a chain of stops:

1. TBC only: Have Materials, a check box that hides recipes you cannot make right now.
2. TBC: Subclass and Inventory Slot dropdowns. Mists: one Filter dropdown. They narrow the list by category or slot. Enter opens the game's menu.
3. Search, an edit box. Typing narrows the recipe list.
4. Recipes, the list. When the window opens you land here.
5. Details of the selected recipe.
6. Quantity, an edit box that holds how many you want to make.
7. The Create and Create All buttons, each a stop.

### The recipe list

Category headers read their name and "Expanded" or "Collapsed" and fold with Enter. A recipe reads its name, how many you can make with what you carry, and its difficulty as a colour word:

- "Linen Bandage 12 (Orange)": 12 can be made; orange means it is still worth making for skill.
- The colours are Orange (optimal), Yellow (medium), Green (easy) and Grey (trivial).
- Nothing is spoken for the count when you can make none.

Enter on a recipe selects it ("selected") and fills the details. Space on a recipe reads its tooltip.

### The details

One stop, Details:

1. The recipe name (the icon button). Space reads the tooltip of the item it makes.
2. The description, when there is one.
3. The requirement ("Requires: Anvil"), when there is one.
4. A group named after the game's reagent label ("Reagents:") with one line per reagent: its name and how many you have and need. The count reads as the game draws it: "Linen Cloth 12 /1".

Walk the lines with Up and Down. Space on a reagent reads its tooltip.

### Making items

After you select a recipe:

- Tab to Quantity. It starts at 1. Type a number, press Tab.
- Create makes that many of the selected recipe. Create All makes as many as your materials allow.
- A button that cannot be used reads "Disabled".
- The game then makes the items with its normal cast bar.

### Example: craft 5 Linen Bandages (TBC, Mists)

1. Open the First Aid window: press P for the spellbook, go to the Professions tab on Mists (or the General side tab on TBC), find "First Aid" and press Enter.
2. You land on Recipes. Press Shift+Tab once to reach Search, type "linen" and press Tab. You are back on Recipes, and the list now only holds matching recipes.
3. Arrow down to "Linen Bandage 12 (Green)". Press Enter: "selected".
4. Press Tab to Details. Down reads the description and the reagents, "Linen Cloth 12 /1", so you know you have enough.
5. Press Tab to Quantity, type 5, press Tab.
6. On Create, press Enter. The game makes five bandages.

## The craft window (TBC only)

Enchanting and the hunter's Beast Training use an older twin of the trade skill window, named Craft. It opens the same way: use the Enchanting spell, or the hunter's Beast Training ability.

The stops:

1. The skill bar: "Enchanting 300/375". Not shown by every craft.
2. Training Points with your pet's points, for Beast Training only.
3. Have Materials, a check box (not shown for Beast Training).
4. Slot filter dropdown, for Enchanting.
5. Recipes, the list, where the window opens. Each entry reads its name, its rank or sub text, how many you can make, its difficulty colour, and for Beast Training its training point cost. An enchanting entry reads like "Enchant Bracer - Brawn 3 (Yellow)".
6. Details: the craft icon (name and count), the requirements, the cost, the cooldown, the description and a Reagents group like the trade skill window's.
7. Enchant (or Train for Beast Training) and Close.

### Example: enchant a bracer on TBC

1. Open the Enchanting window. Tab to Recipes, choose "Enchant Bracer - Brawn", Enter.
2. Tab to Details and read the reagents.
3. Tab to the Enchant button and Enter.
4. The game now asks you to choose the item. Open your character pane (C) and press Enter on the bracer slot, or open your bags and press Enter on the bracer. The enchant is applied and the game shows its own confirmation.

### Example: train a pet skill (hunter, TBC)

1. Cast Beast Training. You hear the Craft window.
2. Tab to Recipes and arrow to the ability you want. Its training point cost is part of the line.
3. Check Training Points and Tab to Train. Enter.

## Gem socketing (TBC and Mists)

The socketing window opens when you use an item with gem sockets that you carry or wear (right click it: Backspace on the item in your bags or in the character pane).

The window has three stops:

- Socketing: one entry per socket, reading its colour and the gem: "Red: Delicate Living Ruby" or "Blue: Empty". If you have placed a new gem but not applied it, the line shows the new gem. Special sockets read the game's own colour word where there is one (meta, and on Mists cogwheel and sha-touched sockets).
- Apply, the game's socketing button. Nothing changes in the item until you press it.
- Close.

### Example: socket a gem

1. Open your bags ([Bags and bank](bags-and-bank.md)) and press Backspace on the item you want to socket. The socketing window opens.
2. Press Ctrl+Tab to go back to the bags window, arrow to the gem and press Enter. The gem is on your cursor.
3. Press Ctrl+Tab to return to the socketing window. In Socketing, move to "Red: Empty" and press Enter. The line now reads the new gem.
4. Tab to Apply and press Enter. The game may ask you to confirm in a popup, for example when a gem replaces another.

The drag key (\\ or Ctrl+D) on a socket runs the game's own drag action for that socket.

## Reforging (Mists only)

Opens when you talk to a reforger in a capital city. You choose an item, then one stat to reduce and one to gain. The stops, in order:

1. Item: the item slot. It reads the item name, or the game's text asking you to put an item in (Enter with an item on your cursor places it; the drag key takes it out).
2. The left stat column: its title is the game's heading, and each stat is a check box with the stat's text. Enter picks the stat to reduce.
3. The right stat column: the stats you can reforge into. Enter picks the stat you gain.
4. A restore message line when the item has already been reforged.
5. The cost in gold, silver and copper, when there is one.
6. Reforge and Restore buttons, each a stop.

Everything is live: when you place an item the stat columns rewrite themselves.

### Example: reforge your helmet

1. Talk to the reforger. The window opens on Item.
2. Press Ctrl+Tab to your bags, Enter on the helmet to pick it up, Ctrl+Tab back to the reforging window and press Enter on Item to place it.
3. Tab to the left column and choose the stat you give up, Enter.
4. Tab to the right column and choose the stat you gain, Enter.
5. Check the cost, Tab to Reforge, Enter.

## Item upgrade (Mists only)

Opens at the item upgrade vendor. The stops:

1. Item: the slot. It reads the item name, or the game's text asking for an item. Enter with an item on your cursor places it.
2. The upgrade status line (what upgrade step you are on), when the game shows it.
3. The left column (the current item) and the right column (the upgraded item), each a stop of its own named by the game's heading. Each begins with the item level ("Item Level 463") followed by one line per stat: its name, value and, in the upgraded column, the increase.
4. Upgrade, the button. It reads the cost with it: "Upgrade Valor Points 250".

## WoW: Forever: professions

Forever replaces the old windows with the modern professions window. WowVision reads its two pages.

### The professions book

Press the game's professions key. The screen is named Professions and has a stop for each profession card: the two main professions first, then cooking, fishing and first aid.

- A learned profession reads its name (with its specialization) as a heading, then: the rank line, its spells and, on the main professions, Unlearn.
- The spells are buttons, for example the profession's crafting window or abilities such as Find Herbs and Find Minerals. Enter casts the spell, and for the crafting spell that opens the crafting page. Backspace does nothing here. The drag key picks the spell up for an action bar. Space reads the spell tooltip.
- An empty slot reads the game's heading and hint, for example how to learn a profession.

The side tabs of the window are not read: use the profession's spell to open its crafting page.

### The crafting page

Opening a profession's spell shows the crafting page, named after the profession. The stops:

1. Tabs: one tab per profession that has a crafting window. Enter on a tab casts that profession's spell and switches to it. The profession you are on reads "selected" and does nothing on Enter.
2. Profession (one stop): the rank line, a Link menu (links the profession to chat) and your profession tool slots. A tool slot reads the item name or "Empty". Enter picks the item up or drops the item on your cursor, like the character pane.
3. Filter, a dropdown menu.
4. Search, the edit box. Type to narrow the recipes.
5. Recipes, the list. The page opens here.
6. Details of the selected recipe.
7. Quantity, an edit box.
8. Create, Create All, and View Guild Crafters when it is shown. A disabled create button also reads the game's reason (what is missing).

### The recipe list

- Category rows read their name and "Expanded" or "Collapsed". Enter folds them.
- A recipe reads its name, how many you can make now and, for learned recipes, a colour word for its difficulty: "Elixir of Agility 3 (Orange)". Only recipes that still give you skill points carry a colour; the others read "(Grey)". A recipe that cannot be used reads its reason after a comma.
- Recipes you have not learned are grouped after a divider line that reads the game's "Unlearned" text.
- Enter selects a recipe ("selected"). Backspace opens the game's favorite menu for it.
- Space reads the recipe's tooltip: the item it makes, the tools it needs ("Requires: Blacksmith Hammer (Missing)") and the reagents: "Reagents:" then one line per reagent in the form "Peacebloom 3/2", with the number you have first and the number needed second.

### The details

One stop, Details. It reads the output item with its count, a Favorite check box, the output sub text, the tools line, the cooldown, where an unlearned recipe is learned, a first craft bonus, the description, and the check boxes the game shows (for example the best reagents and tracking the recipe). The reagents are not repeated here; use Space on the recipe or the output item.

### Example: craft 5 Elixirs on WoW: Forever

1. Press the professions key. Tab to the card for Alchemy and press Enter on its spell (for example "Alchemy").
2. The crafting page opens on Recipes. Press Shift+Tab once to reach Search, type the recipe name and Tab back to Recipes.
3. Arrow to the recipe and press Enter; Space reads what it needs: "Peacebloom 3/2".
4. Tab to Quantity, type 5, Tab to Create. Press Enter.

## Other notes

- Item shopping and buying reagents are described in [NPC windows](npcs.md).
- To equip crafted gear or move it between bags use [Bags and bank](bags-and-bank.md).
- Classic Era and Retail have no profession windows in WowVision yet.
