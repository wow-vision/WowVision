# NPCs: Gossip, Vendors, Trainers, Flight Masters and Books

This page covers the windows you meet when you talk to a character in the world: the conversation window (gossip), merchants, trainers, flight masters, books and letters, and the hunter's pet stable. All of them open when the game opens them. Walk up to the NPC and interact as usual, for example with the interact key. WowVision then reads the window and lets you move through it.

In all these windows Tab and Shift+Tab move between the parts of the window (each part is a "stop"), the arrow keys move inside a part, Enter clicks, Space reads the tooltip where there is one, and Escape closes the window. Backspace right clicks, which matters only where a right click does something, such as on a merchant's goods. Shift+F10 opens the context menu of the focused entry. See [Navigating windows](../basics/interface.md).

If the addon Sku is loaded, WowVision leaves the gossip, merchant, trainer, flight master and pet stable windows to Sku.

## Gossip

The gossip window is the conversation you get when you talk to most NPCs. It lists what the NPC says and what you can choose.

The window reads, from the top. Every entry is a stop of its own, so use Tab and Shift+Tab to move from one to the next:

1. The greeting, the NPC's current text. The name of the NPC is announced as the window's title.
2. Options, one entry for each thing the NPC offers, for example "Train me", "Make this inn your home" or "I want to browse your goods". Press Enter to pick one.
3. Available Quest: ... entries, quests you can accept from this NPC, followed by the quest title.
4. Accepted Quest: ... entries, quests you have already taken that involve this NPC, for example to turn them in.
5. Goodbye, which ends the conversation.

When you pick an option, the NPC answers and the window refreshes. The new text is read to you automatically from the top, and focus returns to the greeting. While the game is still working on your choice, WowVision keeps showing the old page rather than a half-updated one, and then jumps to the new page when it is ready.

Picking a quest entry opens the quest window. See [Quests](../world/quests.md). Choosing an option that opens a trainer, merchant or flight master closes the conversation and opens that window.

Example: set your hearthstone at an innkeeper.

1. Interact with the innkeeper. You hear the name of the NPC and the greeting.
2. Press Tab to move through the options until you hear "Make this inn your home".
3. Press Enter. The NPC answers, probably with a confirmation popup. See [System windows](./system.md#popups-and-confirmation-dialogs).

Not read: some friendship and special reputation displays that the modern game shows in gossip.

## Merchants

The merchant window is where you buy, sell and repair.

The stops, in order:

1. Tabs: a row with two tabs, the merchant's goods and Buyback. The one you are on says "selected". Use Left and Right, and Enter to switch.
2. Items: the goods for sale on this page, or the items you sold, on the Buyback tab. Ten goods per page; the buyback list has up to twelve. An empty page says "Empty".
3. Previous Page and Next Page: one stop each, only when the merchant has more than one page.
4. Repair (only at merchants who repair): Repair All, Repair Item and, where available, Guild Bank Repair. These are on the Merchant tab only.

### What an item says

Each item reads its name and quality colour, how many you get in a stack, the price, how many are left, and any other costs:

- "Linen Bandage, White, 1 Silver 5 Copper"
- "Rough Arrow, White x 200, 3 Silver, 2 in stock"
- "Insignia of Conquest, Purple, Honor Points 1200"

The price is shown in gold, silver and copper. A stack like "x 200" shows only when the merchant sells more than one at a time. Items that cost extra currencies or items add them at the end, for example "Marks of Honor 20" or the name of the required item. Limited items add "N in stock". These labels are live. Page flips rewrite the same slots while you stay on them.

Press Space for the item tooltip.

### Buying

- Backspace (right click) on an item buys it. A stack item buys the whole stack the merchant offers, as in the game.
- Enter (left click) picks the item up onto your cursor. You can then put it into a bag slot to buy it there.
- To buy a chosen amount of a stack item, press Shift+Enter on it. The game opens a small box that asks how many you want: type the amount and press Enter. WowVision does not read that box.

### Selling

- Open your bags (see [Bags and bank](./bags-and-bank.md)), and press Backspace on an item. With a merchant open this sells it. The context menu of the slot says "Sell, Right Click" so you can check before you press.
- Or pick the item up with Enter and put it down in the merchant's items.
- Items you sold by mistake can be bought back on the Buyback tab, for the price you got.

### Repairing

On the Repair stop press Enter on Repair All to repair everything you have equipped for the price shown by the game (the cost is in the button's tooltip, read with Space). Repair Item puts the game's repair tool on your cursor, and then you click the item to repair. Guild Bank Repair repairs with the guild's money where you may.

### Merchant settings

Open the WowVision menu and go to Windows, then Merchant.

| Setting | Default | What it does |
|---------|---------|--------------|
| Automatically Sell Poor Items | Off | When a merchant opens, every grey item in your bags that has a vendor value is sold at once. WowVision prints "Sold N poor quality items for X." in the chat. |
| Automatically Repair If Possible | Off | When a merchant opens, your gear is repaired at once with your own money. WowVision prints "Repaired all items for X." in the chat. It is skipped silently if the merchant cannot repair, nothing is damaged, or you cannot pay. |

Both are meant for the common run: arrive at a vendor, hear what you sold and repaired, and move on. Locked items are not sold. The automatic sale looks at the backpack and your four bags.

Like every window, the merchant has an Enabled switch on the same menu page.

## Trainers

The trainer window teaches you spells, skills and professions.

The stops, in order:

1. Next rank (WoW: Forever only): WoW: Forever lifts the next rank of a profession you have not learned yet out of the list into its own button above the list.
2. Filter: a dropdown with Available, Unavailable and Already Known. On WoW: Forever the game hides unavailable skills by default, so a new character hears only one entry and nothing of what comes later. Open the filter and tick Unavailable to see everything.
3. Training: the list of services, a spell or skill per entry. Enter selects one.
4. Details: the selected service's name (Space reads its tooltip), a second skill line when there is one, what it requires, and the cost.
5. The Train button. Press Enter to learn the selected service.

### What a service says

A service reads its name and rank, then Known or Unavailable where that applies, the price, and its requirements:

- "Fireball Rank 2, 20 Silver, Requires: Level 6"
- "Apprentice Cooking, Known"
- "Heroic Strike Rank 3, Unavailable, 1 Gold, Requires: Level 16"

The word "selected" follows the one you have selected. The requirements are shown whether or not you already meet them, and the line is built from the game's own wording, so it may differ slightly from the examples. Headers in the list (the groups the game uses, such as Available) say Expanded or Collapsed, and Enter folds or unfolds them.

Example: learn a new spell.

1. Interact with your class trainer.
2. Press Tab until you hear "Training", then walk with Down through the list.
3. Stop on a service you can afford and press Enter. It says "selected".
4. Press Tab until "Details" and read the cost. Then press Tab to Train.
5. Press Enter. The game teaches you the spell, and your money goes down.

### Your pet's Beast Training

On WoW: Forever the hunter's Beast Training ability opens your pet's skills in the same trainer window, without a trainer to talk to. WowVision reads it like the class trainer. The window is named after your pet, and the stops are the same: Filter, Training and the Train button. One stop is new, at the top: Training Points, which reads how many points your pet has left, for example "Training Points: 19".

A skill costs training points, not money, and says so: "Natural Armor Rank 1, Training point cost: 1, Requires: Level 8". Press Enter on a skill to select it, then Tab to Train and Enter to teach it. The points go down, and you hear the new total.

## Flight masters

A flight master window lists where you can fly. It has one stop, named with the title of the map (usually the flight master's location or the continent), and one entry per destination.

Each entry reads the name of the place and the cost:

- "Ironforge, Dun Morogh, 2 Silver"
- "Menethil Harbor, Wetlands, 1 Silver 40 Copper"

Walk with Up and Down, and press Enter on a destination to take the flight. Only the destinations the game draws on its map are listed, and the place you stand at may be among them.

## Books, letters and plaques

When you read an item or object that has text, such as a book, a letter or a plaque, the item text window opens. It reads:

1. The text stop: the item's name, "From" and the author (only if there is one), and then the body of the text. A page of text is read as one piece.
2. Previous Page and Next Page, only for texts that have more than one page. Press Enter to turn the page. The new page is read when it arrives.
3. A Close button. Escape also closes it.

The text can take a moment to come from the server. WowVision stays quiet until it arrives and then reads it.

## Pet stable

(The Burning Crusade only.)

Hunters use the pet stable on The Burning Crusade to keep extra pets. Talk to a stable master and choose to open the stable. The window reads:

1. Selected Pet: the pet's level, its loyalty or happiness text where the game shows one, and what it eats.
2. Slots: the current pet, then Stable slot 1 and Stable slot 2. Each reads its heading, the pet's name and "Level N Family", or "Empty Stable Slot". The slot you have selected says "selected".
3. Purchase: the button to buy the next slot, with its price.
4. Money: your money.
5. Close.

Stabling and taking a pet out work with the cursor, like items:

- To stable your current pet: press Shift+F10 on the current pet slot, choose Drag, then press Enter on a free stable slot.
- To bring a stabled pet out: press Shift+F10 on the stabled pet, choose Drag, then press Enter on the current pet slot. The two pets swap if you already have one.
- Enter on a slot with nothing on your cursor selects it, and the window shows that pet's details.

The Drag keys (\\ and Ctrl+D) do nothing on stable slots, so use the Drag entry of the context menu.

Classic Era, Mists of Pandaria, Retail and WoW: Forever have no stable reader.
