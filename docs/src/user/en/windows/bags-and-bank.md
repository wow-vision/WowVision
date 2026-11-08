# Bags and Bank

WowVision reads your bags and your bank as lists of slots that you can walk through, pick up from, use, sell and rearrange with the keyboard. This page explains how the bags window is laid out on each game version, what a slot says, and how to move, use and destroy items with the cursor.

## Opening your bags

Open your bags with the game's own keys, exactly as a sighted player does (B for all bags, or the backpack key). When any bag is open, the bags window appears in WowVision.

The bags window is a background window. It also opens by itself next to a merchant, the mailbox, the bank or a trade, because the game opens your bags there. The merchant, mailbox or bank keeps the focus. Press Ctrl+Tab to switch to the bags and Ctrl+Tab again to come back. See [Navigating windows](../basics/interface.md).

Close the bags the way the game does, by pressing the bag key again.

If the addon Sku is loaded, WowVision leaves the bags to Sku and does not read them.

## Bag shape: grid or list

The Bag Shape setting (Windows, then Containers) decides how the slots of one bag are read.

| Setting | Default | What it does |
|---------|---------|--------------|
| Bag Shape | List | List reads the slots of a bag as one vertical list in slot order, slot 1 first. Up and Down move through it. Grid reads them as the rows the game draws: Left and Right move along a row, Up and Down move between rows. |

In the grid shape, Up and Down follow the position in the row, not the screen column. On some bags a short row sits at the top, pushed to the right. From the first cell of that short row, Down lands on the first cell of the row below, so you never skip anything when you read from the top left downward.

Home and End jump to the first or last slot (in a grid, of the current row). Change the setting in the WowVision menu. See [Menu and settings](../basics/menu-and-settings.md).

## What a slot says

An empty slot says "Empty". A slot with an item says the item's name followed by its quality colour as a word, and the stack count.

- Classic Era, TBC and Mists: "Linen Cloth, White 12", "Heavy Leather Ball, White".
- Retail and WoW: Forever: "Linen Cloth, White, 12". After the count the slot may add Quest Item, New, Locked (the item is in use, for example on the cursor) and Filtered (the slot does not match the bag search). While the game has not yet sent an item's name, the slot says Loading.

The colour word follows the game's quality colours: Grey (poor), White (common), Green (uncommon), Blue (rare), Purple (epic), Orange (legendary), Light Gold (artifact), Light Blue (heirloom). You can switch individual colours off in the Tooltip settings under Quality. See [Tooltips](../basics/tooltips.md).

The slot label is live. If you pick up an item, the slot you are standing on says "Empty" at once. If you drop one in, it says the new item.

Press Space for the full tooltip of the item.

## What you can do with a slot

| Key | What it does |
|-----|--------------|
| Enter | Left click. With an empty cursor it picks the item up. With an item on the cursor it puts it down in the slot (swapping if the slot is full). |
| Backspace | Right click. It uses, equips, opens or moves the item, depending on what is open (see below). |
| \\ or Ctrl+D (Drag) | Picks the item up onto your cursor, like a mouse drag. |
| Delete or Alt+Ctrl+\\ (Destroy Cursor Item) | Destroys the item on your cursor, after a confirmation. It works wherever you are in the game, not only in the bags. |
| Shift+Enter (Select Junk) | Marks the item as junk, or takes the mark off. See [Junk](#junk) below. |
| Shift+Backspace (Select Favorite) | Marks the item as a favorite, or takes the mark off. See [Favorites](#favorites) below. Backspace alone is still the right click. |
| Shift+F10 | The context menu of the slot. It lists Left Click, Right Click and Drag, says what each click does right now, and has Mark as Favorite and Mark as Junk (or Unmark as Favorite and Unmark as Junk). |

The context menu is the quickest way to find out what Backspace will do. Each click entry is named for its effect, for example "Sell, Right Click" or "Equip, Right Click".

### What a right click does

The game decides this by which windows are open. In the order WowVision checks:

| Situation | Right click on a bag item says |
|-----------|--------------------------------|
| A merchant is open | Sell (not offered for items with no vendor value). |
| The item is in the bank | Move to Bags. |
| The bank is open | Move to Bank. |
| The mail send tab is open | Attach to Mail. |
| A trade is open | Add to Trade. |
| The auction house is open | Put up for Auction. |
| The item is a container you can open | Open. |
| The item is equippable | Equip. |
| The item is readable | Read. |
| The item has a use effect | Use. |

The left click entry says Pick Up, or Place Item while you hold something.

### Splitting a stack

To split a stack, press Shift+Enter on the slot. The game opens a small box that asks how many items to take; WowVision does not read it. Type the amount, press Enter, and put the new stack down with Enter on an empty slot.

Shift+Enter is also the default key of Select Junk (see [Junk](#junk)). On the item slots of your bags and bank, Select Junk takes the key first, so Shift+Enter marks junk there and no longer splits a stack or puts an item link into the chat box. If you want the shift click back, give Select Junk another key in the keybinding window (Bindings under UI in the WowVision menu); Shift+Enter then does what it did before.

## Junk

You can mark items as junk. WowVision then sells every marked item for you when a merchant opens, and says what it sold.

- Stand on the item in your bags and press Select Junk (Shift+Enter by default). WowVision says, for example, "Linen Cloth: marked as junk". Press it again and it says "Linen Cloth: no longer junk" and the mark is gone. The slot's context menu (Shift+F10) has the same action, named Mark as Junk or Unmark as Junk.
- A marked item reads "[Junk]" before its name, for example "[Junk] Linen Cloth, White, 12". The tag goes as soon as you take the mark off.
- The mark belongs to the item, not to the slot or the stack: every stack of Linen Cloth in your bags and bank reads "[Junk]", and all of them are sold. Items that come in random variants, such as "Gloves of the Monkey" and "Gloves of the Eagle", are marked one variant at a time; marking the Monkey gloves leaves the Eagle gloves alone. Enchants, gems and the item's level do not change which item it is.
- An item no vendor buys, such as a quest item or the Hearthstone, cannot be marked: WowVision says so. A mark that is already there can always be taken off.
- The marks are remembered between sessions, for each character on its own. A mark made on one character never sells anything on another.
- Windows, then Junk in the WowVision menu has Forget All Junk Marks, which takes every mark off after a confirmation, and an Enabled switch. With the module off there are no tags, no key and no sale.

On Retail and WoW: Forever the Junk category of the Item Lists stop (see [Item lists](#item-lists)) lists every marked item of the bags that are open, in bag order, so all your junk is in one place. Each entry is the same slot as in the bags: Enter picks the item up, Backspace right-clicks it, Space reads its tooltip, and Select Junk takes the mark off, after which the item leaves the list.

What is sold, and when, is set in the merchant settings: see [Merchant settings](./npcs.md#merchant-settings). In short, the sale happens once when the merchant window opens. It sells the items you marked and nothing else (grey items too, if you turned that setting on), only from your bags, never from the bank, and never anything you wear. Items that are locked or that no vendor buys are skipped. Then WowVision says what it sold, for example "Sold marked junk for 3 Silver 20 Copper: Linen Cloth, Worn Shortsword." Up to five names are read, then "and N more". Anything sold by mistake can be bought back on the Buyback tab of the merchant.

## Favorites

You can mark items as favorites, to find them again easily. Unlike junk, a favorite is never sold.

- Stand on the item in your bags and press Select Favorite (Shift+Backspace by default; Backspace alone is the right click). WowVision says, for example, "Linen Cloth: marked as favorite". Press it again and it says "Linen Cloth: no longer a favorite" and the mark is gone. The slot's context menu (Shift+F10) has the same action, named Mark as Favorite or Unmark as Favorite.
- A favorite reads "[Favorite]" before its name, ahead of "[Junk]" if the item is also marked as junk: "[Favorite] [Junk] Linen Cloth, White, 12".
- As with junk, the mark belongs to the item, not to the slot or the stack, and items that come in random variants are marked one variant at a time. Any item can be a favorite, also one no vendor buys, such as the Hearthstone.
- The marks are remembered between sessions, for each character on its own.
- On Retail and WoW: Forever the Favorites category of the Item Lists stop (see [Item lists](#item-lists)) lists every favorite of the bags that are open, in bag order. Each entry is the same slot as in the bags, and Select Favorite there takes the mark off, after which the item leaves the list.
- The sale at a merchant never sells a favorite, even one that is also marked as junk or that is grey, and not when the Favorites module is switched off either: switching it off only hides the marks.
- Windows, then Favorites in the WowVision menu has Forget All Favorites, which takes every mark off after a confirmation, and an Enabled switch. With the module off there are no tags and no key.

## The cursor

WoW moves things with a cursor. You pick something up and the game holds it on the cursor until you put it down. WowVision does not speak a separate message when something lands on the cursor. Instead, check the slot you took it from: it now says "Empty".

- To move an item, pick it up (Enter or \\), walk to another slot and press Enter on it.
- To put an item into a bag, pick it up, then use Enter on the bag slot entry (see "Bag slots" below) or on a free slot of that bag.
- Items on the cursor are also used with other windows. You can put one on a trade slot, on a mail attachment or on a merchant to sell it. See [Loot, trade and mail](./loot-trade-mail.md) and [NPCs](./npcs.md).
- An item taken from a bag, a trade slot or a merchant is a real item. A spell, macro or other shortcut taken from an [action bar](./action-bars.md) is only a reference.

### Destroying an item

You have to pick the item up first. This is on purpose, and it matches the game, where you drag an item away to destroy it. It also protects you from deleting the wrong thing.

Example: destroy a Broken Sword.

1. Walk to its slot in your bags.
2. Press Enter (or \\) to pick it up.
3. Press Delete.
4. The game's confirmation popup opens and WowVision reads it. See [System windows](./system.md#popups-and-confirmation-dialogs). For common items the popup has a text and two buttons: read the text, Tab to the button that confirms and press Enter. Items of rare quality or better (heirlooms excepted) may also ask you to type the word DELETE into a text box before the confirm button works.
5. Pressing Escape or the cancel button leaves the item on your cursor. Put it back in a slot with Enter.

If you press Delete while nothing is on your cursor, nothing happens.

## Classic Era, TBC and Mists bags

Each open bag is its own tab stop, in this order: backpack, then bags 1 to 4. Press Tab and Shift+Tab to move between bags, and the arrow keys to move inside one.

- The bag is announced by its name, for example "Backpack" or "Journeyman's Backpack". Bank bags are announced as "Bank: " and their name.
- The first entry of a bag is its bag slot: "Bag Slot Backpack". This is the button you put a new bag on, and you can pick up the bag from here. After it come the item slots.
- The bag slot buttons live inside each bag's own stop, so you can only reach them while that bag is open.

The keyring (Classic Era and The Burning Crusade) is not read.

WowVision reads no sort button on these versions, even where the game draws one. Arrange items by hand or use the sorting your game version offers.

### The bank on Classic Era, TBC and Mists

Walk up to a banker and open the bank. The bank window reads:

1. A stop named Bank with the bank's own item slots.
2. A stop named Bank Bag Slots with the bank bag slots you own, each reading the bag's name or "Empty" followed by the game's own description of the slot. Put a bag in a slot with Enter, as with your own bag slots. Below the owned slots, when you can buy another one, WowVision reads the purchase text, "Costs" and the price, and a purchase button. Press Enter on the button to buy.
3. Each open bank bag appears as its own stop, named "Bank: " and the bag name.

To move items between your bags and the bank, open both, pick an item up and press Enter on a free slot of the other. Or use Backspace on the item. With the bank open, a right click on a bag item moves it to the bank and a right click on a bank item moves it to your bags.

## Retail and WoW: Forever bags

(Retail and WoW: Forever only.)

These versions have two bag views, which you pick in the game's bag menu. WowVision follows what the game shows.

### Item lists

When there is something to look at, the bags get an extra stop called Item Lists. It comes right after the bags, so opening them still lands on their items. It holds categories like the scanner's, each reading its name and how many items it has, for example "New Items (2)". Right opens a category and Left closes it. Its items read like bag slots, and you can use, equip or move them from there as usual. The same items still sit in their slots in the bags. A category with nothing in it is left out, and with every category empty the stop is gone and the bags open as before.

- Junk: every item you marked as junk, with the tag, in bag order (see [Junk](#junk)). It starts closed.
- Favorites: every item you marked as a favorite, in bag order (see [Favorites](#favorites)). It starts closed.
- New Items: what the game marks as new, the things you looted or bought since you last looked. It starts open. The game takes the new mark off an item as soon as you move the cursor onto it, and WowVision does the same when you land on a slot, so an item would vanish the moment you reach it. WowVision therefore keeps the items it has seen as new in the list until you close the bags. Open the bags again and only what is still marked new is listed.

### Combined bags

All your bags are drawn as one big grid, and WowVision reads it the same way: the backpack first, then the other bags, no bag boundaries. The stops are:

1. Bags: the slots, in the shape you chose (a grid is ten slots wide, with the first row possibly shorter). In the list shape the slots are in slot order, backpack first.
2. Bag Slots: a row with the bag slot buttons of the backpack and your four bags. Each reads "Bag Slot" and the bag's name. The reagent bag and, on WoW: Forever, the keyring are drawn by the game as their own frames even in combined view. They are not in this row. Each gets a stop of its own, with its bag slot first, as in the individual view below.
3. Item Lists: the categories described under Item lists above, when there is something in them.
4. Search: a text box. Tab into it and type, and slots that do not match read Filtered. Tab out to leave it.
5. Bag Controls: Bag Menu, a dropdown with one submenu per bag (filters, clean up, switch bag view); Sort Bags; Money, which reads your gold, for example "Money, 12 Gold 5 Silver"; and Add Slots when the game offers it.

A backpack of an account without an authenticator shows four extra slots that cannot hold anything. WowVision does not read these as slots. The Add Slots button is still in Bag Controls.

Example: find your Hearthstone with the search.

1. Open the bags with B. Press Ctrl+Tab if you are inside another window.
2. Press Tab until you hear "Search".
3. Type `hearth`. The slots that do not match now read Filtered.
4. Press Tab back to the Bags stop and read slots with Down.

### Individual bags

Each bag is its own window, as on Classic. Each open bag is a stop, announced by the bag's name. The backpack key alone opens just the backpack. The game's Open All Bags key (by default Shift together with the backpack key) opens everything.

- The first entry is the bag slot: "Bag Slot" and the bag name. Both clicks on it say Close Bag, or Place Item while you hold a bag. The bag's own menu (filters, clean up, switch bag view) is in the slot's context menu, as Bag Menu.
- Search, Sort Bags, Money and Add Slots belong to the backpack. They appear in a stop called Bag Controls after the bags.
- The Item Lists stop (see Item lists above) comes last, when there is something in it.

## Retail and WoW: Forever bank

(Retail and WoW: Forever only.)

The modern bank is one window that shows the character bank, and the Warband (account) bank. A banker opens it. The stops are:

1. Bank Tabs: a row with the tabs. These are the bank type tabs (character and Warband bank, named by the game), the page tabs on WoW: Forever, the side tabs for each bank tab on Retail (Enter selects, Backspace opens its settings on Retail), and the purchase tab. The current one says "selected".
2. One stop per bank tab: its slots, named by the tab's name. On WoW: Forever all purchased tabs of the current bank type are shown at once, on pages.
3. Bank Bag Slots (WoW: Forever): a row with the bank bag slot buttons, which can be picked up with the Drag key. A slot you have not bought reads Purchasable Bag Slot and the price. Press Enter on it to buy, and the game asks you to confirm. The game sells the next slot in line, whichever unbought slot you press Enter on.
4. Search: a text box.
5. Bank Controls: Sort Bank, Money (in the Warband bank this is the deposited gold, with the game's deposit and withdraw buttons), and the price and purchase button for the next tab or bag.

A locked or not yet bought bank shows the game's explanation instead of slots. It is read as a text under the name "Bank".

Slots read like bag slots. Right click moves an item between bags and bank as on Classic: Move to Bank and Move to Bags.

Example: put an item in your Warband bank on Retail.

1. Open the bank. Press Tab until the tab row, and press Right until the Warband bank tab. Press Enter.
2. Press Ctrl+Tab to your bags, find the item, and press Enter to pick it up.
3. Ctrl+Tab back, walk to a free slot in the Warband bank, and press Enter to drop the item there.

## Settings

The bags and the bank have one setting, Bag Shape, described above. Like every window, the bags have an Enabled switch in the WowVision menu, under Windows, then Containers. They have no alerts and no key bindings of their own. The keys on this page are the shared window keys, which can be changed in the keybinding window. See [Keybindings](../basics/keybindings.md).

## Troubleshooting

- Nothing happens when I press Delete. Delete destroys only what is on the cursor. Pick the item up first.
- I cannot find the bags. They are a background window. Press Ctrl+Tab to cycle windows.
- Slot order seems backwards. Make sure Bag Shape is set to List for slot order. In Grid, rows follow the screen.
