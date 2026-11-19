# Auction House

The auction house window lets you search for items, bid on them, buy them out, put your own goods up for sale, and check your active auctions and bids. WowVision reads the whole window, and on The Burning Crusade (TBC) it adds a price database that remembers what things cost.

## Check the price before you buy

Always check the total price before you buy. The window can change while you use it, and some sellers list items at very high prices, hoping someone buys them by accident.

This is most likely when you enter a quantity of a commodity. There are often a few at a cheap price and then many at a much higher one, and those are included automatically. On Mists, Retail and WoW: Forever, Total Price tells you what you will pay, and Buy asks you to confirm, so you can still back out.

## What is available on which version

| Version | Auction house reader |
|---|---|
| Classic Era | Not available |
| The Burning Crusade (TBC) | Yes: the classic three-tab window (Browse, Bids, Auctions), with the extra scanning tools and the price database |
| Mists of Pandaria (Mists) | Yes: the modern window (Buy, Sell, Auctions) |
| Retail | Yes: the same modern window as Mists (it loads the same reader), with Full Scan and prices in tooltips |
| WoW: Forever | Yes: the same modern window as Mists, with Full Scan and prices in tooltips |

The two windows work quite differently, so they have separate sections below: [TBC](#the-burning-crusade-auction-house) and [Mists, Retail and WoW: Forever](#the-modern-auction-house-mists-retail-and-wow-forever).

## Opening and closing

Walk up to an auctioneer and open the conversation. WowVision reads the auction window as soon as it opens, and the game also opens your bags. Use Ctrl+Tab to switch between the auction window and the bags (see [Bags and bank](./bags-and-bank.md)). Escape closes the auction house.

General keys inside the window (see [Interface basics](../basics/interface.md)):

| Key | What it does |
|---|---|
| Tab / Shift+Tab | Next or previous section |
| Up / Down | Move inside a list or section |
| Left / Right | Move along a row of tabs or sort headers |
| Enter | Left click: select a result, press a button, open a menu |
| Backspace | Right click |
| Space | Read the tooltip of the focused row |
| Shift+F10 | Context menu |
| Page Up / Page Down | Scroll long lists |

### Entering prices

Prices are entered in up to three separate edit boxes, each its own stop: Gold, Silver and Copper, under a heading naming the price ("Bid Price", "Buyout Price", "Starting Bid"). When you arrive on a box with Tab you can type straight away. Tab again moves to the next box. Type plain numbers: to set 2 gold 50 silver, type 2 in Gold, 50 in Silver and leave Copper empty.

Prices are always read out as the game writes them: "1 Gold 20 Silver 5 Copper".

## The Burning Crusade auction house

### Layout

The window has three tabs, shown as the first row ("Tabs"): Browse, Bids and Auctions (the game's own names). Left and Right move between them; the open tab reads "selected". Enter switches tabs.

### Browse tab

Press Tab to move through these sections, in this order:

1. Categories: the game's category buttons (Weapons, Armor, Containers, and so on). Enter on a category searches it at once. Choosing a category opens its sub-categories as new buttons in the same list. An empty list reads "Empty".
2. Search: an edit box for the item name. Type, then press Enter to search.
3. Results: the list of auctions on the current page (see below). While a multi-page scan runs this is replaced by the Abort Scan button; with scan results it becomes Scan Results.
4. Page controls: Previous Page and Next Page, each present only when it can be used. They become Load More or Scan in the situations described under Min Stack Size.
5. The actions for the selected auction, only while one is selected: the Buyout Price (as text) and the Buyout button, then the Bid Price boxes (Gold, Silver, Copper) and the Bid button.
6. Sort: a row of sort buttons.
7. Price Options: unit and total price sorting choices, only when the game shows them.
8. Filters: opens the filters screen (described below).
9. Search: the game's search button.
10. Full Scan: the price database scan (described below).
11. Reset: the game's reset button for all filters, when enabled.

#### Results

Each auction row reads the item, the stack size, the seller, the buyout, the current bid and the time left, for example:

> Linen Cloth x20, Seller: Bob, Buyout: 1 Silver 20 Copper, Current Bid: 90 Copper, Time Left: Long

Details:

- "x20" is the stack size, left out for single items.
- The buyout is left out when the auction has none.
- "Current Bid" is the highest bid so far, or the starting bid when nobody has bid.
- Time left is one of Short, Medium, Long or Very Long: these are the game's four duration groups, roughly under 30 minutes, up to 2 hours, up to 12 hours, and up to 48 hours.
- A selected row reads "selected".

Enter selects the row and you hear "Selected: Linen Cloth" (this is the Item Selected alert). Space reads the item's full tooltip.

#### Bidding and buying out

1. Enter on the auction you want. The bid and buyout sections appear after the results.
2. To buy out: Tab to the Buyout Price line (you hear the price) and then the Buyout button; press Enter.
3. To bid: Tab to Bid Price, type your amount in the Gold, Silver and Copper boxes and press Enter on Bid.
4. The game then shows a confirmation popup. WowVision adds the item name and stack size to the end of its text, for example "... Linen Cloth x20", so you know what you are confirming. Answer it like any popup (see [System windows](./system.md)).

The same confirmation extra text appears when you cancel one of your own auctions.

#### Sorting

The Sort row has buttons for Rarity, Level, Time Left, Seller and Current Bid (the game's names, and only the ones the game shows).

- Left and Right move between the buttons.
- Up and Down choose the direction. WowVision says "Ascending" or "Descending" as you press them.
- Enter applies the sort. On the Browse tab this runs the search again.
- Each button reads its name, its direction, and "Active" if it is the sort the list uses now.

Sorting by Current Bid ascending puts the cheapest starting bids first. Buyouts are read on every row, so use Down to compare them.

#### The filters screen

Enter on Filters opens a small screen of its own. Escape returns to the browse tab. It holds:

- Min Stack Size: a number. See below.
- Minimum Level and Maximum Level: edit boxes.
- The rarity dropdown (the game's label and your current pick, for example "All").
- The game's Usable check box (usable items only).
- The game's character-preview check box (only changes the picture, so it does nothing useful for you).

The level, rarity and usable settings are the game's filters and apply to the next search. Min Stack Size is WowVision's own and is explained next.

#### Min Stack Size, scanning and Load More

The game cannot filter an auction search by stack size. WowVision can: set Min Stack Size in the filters screen to hide stacks smaller than your number. For example, 20 shows only stacks of 20 or more. Setting it to 0 or 1 turns the filter off. It lasts until you change it or reload the interface.

With the filter on:

- After a search the Results list shows only the matching auctions of the current page, with the seller on each row. "No Results" is read when nothing matches.
- In the page controls position you find a Scan button, as long as the search found any auctions. Enter on it walks through the result pages one by one. It stops at the end of the page where it has found at least 20 matching auctions, or at the last page.

While scanning you hear "Scanning, 12 Page" (the number of pages) and "Page 5 / 12" every fifth page. The Abort Scan button reads its progress, for example "Abort Scan (3/12)", and Enter stops it. When it ends you hear one of:

- "Scan complete, 23 Results in 340 scanned": 23 matches were found among 340 auctions looked at.
- "Scan aborted, 7 Results": you stopped it; what was found so far is kept.
- "Scan failed": the game would not accept the next page search within 10 seconds.

Closing the auction house also stops a scan.

Afterwards the Scan Results list replaces the browse list. Rows read like normal results, with the seller. Enter on a row asks the game for that page again and selects the exact auction, then shows the bid and buyout sections as above. A Scan Results button then brings you back to the list. If the auction has been sold or has changed meanwhile you hear "Item not found" and it is removed from your list. When your buyout or bid is placed you hear "Item purchased" and are returned to the list with that result removed.

At the end of the scan results the Load More button continues the scan from the next page and adds the next 20 or so matches to the list. It is offered only when more pages exist.

Starting a new search by hand throws the scan results away.

### Bids tab

1. The Sort row (Rarity, Level, Time Left, Buyout, Status, Current Bid), used as on Browse (without searching again).
2. Bids: the auctions you have bid on, read like browse rows but without the seller. "No Bids" is read when you have none.
3. After you select a bid, the Bid Price boxes and Bid button to raise it, and the Buyout button.

### Auctions tab: selling and your auctions

Stops in order:

1. Place Item Here: the sale slot. It reads the item once placed, for example "Linen Cloth x20".
2. Create Auction: the sale form (see below).
3. Auctions: your active auctions (see below).
4. Cancel Auction, only when an auction is selected and can be cancelled.
5. Sort: Rarity, Time Left, Status, Current Bid.

#### Placing an item

Put the item on your cursor first: open the bags with Ctrl+Tab, press Enter on the stack to pick it up (see [Bags and bank](./bags-and-bank.md)), switch back with Ctrl+Tab, go to Place Item Here and press Enter. With an item on the cursor, Enter puts it into the slot.

#### The sale form

These stops appear once an item is placed:

1. Stack Size: how many items per auction. A Max button follows.
2. Number of Stacks: how many auctions to create, with its own Max button.
3. Buyout Price: the Gold, Silver and Copper boxes. Leave them empty for an auction without a buyout.
4. Starting Bid: a button. Enter opens a small screen with the Gold, Silver and Copper boxes for the starting price. Escape returns to the form.
5. Duration: three check boxes, 12 Hours, 24 Hours and 48 Hours. The game starts on 24 Hours.
6. Deposit: the deposit you will pay, read as text. It is shown once an item is placed.
7. Create Auction: the game's button.

#### Your auctions

Each of your auctions reads: "Sold" first when it has sold, then the item and stack size, the buyout, the current bid, the bidder's name where there is one, and the time left. Enter selects one so you can cancel it with Cancel Auction; the game asks you to confirm and WowVision adds the item name to the confirmation text.

### Example: sell 20 Linen Cloth (TBC)

1. Talk to the auctioneer. On the Tabs row move to Auctions and press Enter.
2. Press Ctrl+Tab, find the Linen Cloth stack in your bags and press Enter to pick it up. Press Ctrl+Tab back.
3. Tab to Place Item Here and press Enter. It now reads "Linen Cloth x20".
4. Tab to Stack Size and type 20. Tab to Number of Stacks and type 1.
5. Tab to Buyout Price. Type 1 in Gold, 20 in Silver.
6. Tab to Starting Bid, press Enter, type 90 in Silver, press Escape.
7. Tab to Duration and Enter on 24 Hours (already chosen by default).
8. Tab to Deposit to hear what it costs.
9. Tab to Create Auction and press Enter. Your auction shows up in the Auctions list.

### Example: find the cheapest Copper Ore (TBC)

1. On the Browse tab Tab to Search and type "Copper Ore". Press Enter.
2. Tab to Results and press Down to read the first rows. You hear item, stack, seller, buyout, current bid and time left.
3. To sort by price, Tab to the Sort row, move to Current Bid with Right, press Up until you hear "Ascending", then Enter. The list is searched again, cheapest bids first.
4. To buy only larger stacks: Tab to Filters, press Enter, set Min Stack Size to 20, press Escape, search again and use Scan to collect matches.
5. On the stack you want press Enter, Tab to Buyout and press Enter. Confirm in the popup.

### The price database and Full Scan (TBC only)

WowVision can remember what items cost on your realm. The database is kept per realm and faction and survives between sessions.

#### Full Scan

The Full Scan button on the Browse tab asks the server for the entire auction house in one request and records the lowest buyout price per item. The server allows this once every 15 minutes. The button changes with the state:

| What you hear | What it means |
|---|---|
| "Full Scan" | You can start a scan; Enter starts it |
| "Full Scan, Cooldown active" | You scanned less than 15 minutes ago; Enter tells you the time left, for example "12 min 30 sec" |
| "Scanning, 45 sec" | The server is preparing the data (the seconds waited so far); Enter aborts |
| "Scanning, 63%" | The data is being processed; Enter aborts |

Spoken progress: "Full scan started, 45000 auctions" when the data arrives, "Full scan complete, 3200 items updated" at the end. Other messages: "Full scan aborted" (you pressed Enter while scanning), "Cooldown active", "Auction not open" (you closed the auction house during the scan) and "Full scan failed". A scan that finished keeps its cooldown through a reload of the interface. A scan you aborted or that failed still holds the cooldown until you reload.

While a full scan runs WowVision takes over the game's list updates, so the Browse list does not refresh. This is intentional: the game would freeze for seconds trying to draw tens of thousands of rows. Wait for the scan to finish before you search.

#### What is stored and what it adds to tooltips

For each item the database keeps the lowest buyout per single item, the day it was seen, and a daily high, low and auction count for the last few days. With Tooltip Prices on, extra lines are added to item tooltips everywhere (bags, merchants, auction rows, links), which you read with Space:

- Auction Price: the last lowest buyout, for example "Auction Price: 2 Silver 50 Copper (3 days ago)". The age is left out for today's scan.
- A mean line, for example "7-Day Mean: 2 Silver 10 Copper": the average of the daily lows over the number of days you set.
- Vendor Sell: what a vendor pays for it.
- Vendor Buy: what a vendor charges for it, once you have seen that vendor sell the item. Only items a vendor always has in stock are remembered, and only from merchants you have visited.

#### Auction Prices settings

In the WowVision menu open the Auction Prices module (TBC only):

| Setting | Default | What it does |
|---|---|---|
| History Days | 21 | How many days of daily high and low prices are kept per item. Older days are removed whenever a scan updates the item |
| Mean Days | 7 | How many days the mean line averages. It also names the line ("7-Day Mean") |
| Tooltip Prices | On | Adds the auction and vendor price lines to item tooltips |
| Auto Scan | Off | Starts a full scan automatically each time you open the auction house, if the 15 minute cooldown has passed |

If you turn on Auto Scan, remember the Browse list does not refresh during the scan. If you want to search straight away after opening the auction house, leave it off and press Full Scan when you want it.

#### The Item Selected alert

In the WowVision menu, under the Auction House module (inside Windows), the Item Selected alert controls the "Selected: item name" message you hear when you select a browse result. It has a text-to-speech output you can turn off or change like any alert (see [Alerts](../basics/alerts.md)).

## The modern auction house (Mists, Retail and WoW: Forever)

This window has three tabs, Buy, Sell and Auctions (the game's names). On the first row, Left and Right move along the tabs and Enter opens one; the open tab reads "selected". While the game's buy confirmation is open, it covers the whole window (see below).

Items that stack, like cloth and ore, are "commodities": you buy and sell them by quantity at a price per unit. Other items, such as armor and weapons, are single auctions with a bid and buyout.

### Buy tab

Stops in order:

1. Categories: the category list (Weapons, Armor, ... and the sub-categories). Enter selects a category and the results change. The selected one reads "selected".
2. Filter: the game's filter dropdown (Enter opens the menu). Its level-range row holds two edit boxes read as Minimum and Maximum.
3. Search: an edit box. Type a name and press Enter.
4. The game's Search button.
5. Results: the list of items found.
6. Full Scan: on Retail and WoW: Forever, once you have turned it on (see [Full Scan and prices in tooltips](#full-scan-and-prices-in-tooltips-retail-and-wow-forever)).

Each result reads the item name, the lowest price, and how many are available, for example:

> Copper Ore, 5 Silver, Available 340

Enter on a result opens its purchase pane.

The WoW Token category is not supported: that body reads "This tab is not supported yet".

#### Buying a commodity

The result becomes a purchase pane. WowVision moves the focus to its Back button and remembers which result you came from, so Back returns you there.

1. Back: returns to the results.
2. Auctions: the sellers' stacks, cheapest first, each "Copper Ore, Unit Price 5 Silver, Available 200".
3. Quantity: how many you want. Type it.
4. Total Price: the total, read as text, for example "Total Price 1 Gold".
5. Buy: press Enter to open the game's confirmation.

#### Buying a single item

1. Back.
2. Auctions: each auction reads the item name, "Bid Price" if there is a bid, "Buyout Price", and the time left, for example "Time Left Long". Time left is Short, Medium, Long or Very Long. Enter selects one.
3. Once one is selected: under a "Buyout Frame" heading the buyout price, and a Buyout button; then under "Bid Frame" the Gold, Silver and Copper boxes and the Bid button.

#### The buy confirmation

Buying a commodity or an item opens the game's buy dialog. WowVision shows it alone, under the heading "Auction House". It reads the item, then the price, then the Buy Now button and the Cancel button. Tab moves between them, Enter presses one.

### Sell tab

Stops in order:

1. Place Item Here: the item slot. When an item is in it, this reads the item's name (with item level for gear). Press Enter while you hold the item on your cursor to place it, or use \\ or Ctrl+D (the drag command) for the same effect. While the auction house is open, Backspace on a bag item offers Put up for Auction (see [Bags and bank](./bags-and-bank.md)).
2. Quantity: how many to sell. A Max button follows.
3. Duration: a dropdown; Enter opens the choices (12, 24 or 48 hours).
4. Auctions (comparables): other sellers' auctions of the same item. For commodities each reads item name, "Unit Price" and "Seller" names; for single items name, "Bid Price" and "Buyout Price". Use these to price yourself.
5. The price boxes. The heading is the game's, usually "Unit Price" for commodities, and "Bid Price" and "Buyout Price" for single items. Each has Gold, Silver and Copper. For single items a check box (the game's label) switches between the buyout-only and the bid-and-buyout form; a second price input appears for the other price.
6. Deposit: the deposit, read as text.
7. Total Price: the total price of the auction.
8. Post: the game's post button.

As on the other tab, the WoW Token sale form reads "This tab is not supported yet".

### Auctions tab: your auctions and bids

First a row with the two sub-tabs (the game's own names, for example "Auctions" and "Bids"); Enter opens one.

Auctions sub-tab: a list named "Auctions" with your current sales, then Cancel Auction. Each reads: "Sold" first if sold, item name, "x20" for stacks, "Bid Price", "Buyout Price", and the time left written out, for example "Time Left 1 Hr 30 Min". Enter selects one for cancelling.

Bids sub-tab: a list named "Bids" with the auctions you bid on. Each reads item name, "Bidder" (who is highest), "Bid Amount", "Minimum Bid" and the time left group. After selecting one: the Bid Frame with Gold, Silver and Copper boxes and a Bid button to raise your bid, and a Buyout Frame with the price and a Buyout button.

Item names in all these lists are read from the game as each row comes into view. When a name has not loaded yet the row is read without it; move away and back, or Shift+Tab and Tab, and it appears.

### Full Scan and prices in tooltips (Retail and WoW: Forever)

Full Scan asks the server for the entire auction house in one request and remembers the prices of every item. It is off until you turn it on: open the WowVision menu with Shift+F1, go to Windows, then Auction House, and check Full Scan. The Full Scan button then is the last stop on the Buy tab. The server allows one scan every 15 minutes. The button changes with the state of the scan:

| You hear | Meaning |
|---|---|
| "Full Scan" | You can start a scan; Enter starts it |
| "Full Scan, Cooldown active" | You scanned less than 15 minutes ago; Enter tells you the time left, for example "12 min 30 sec" |
| "Scanning, 12 sec" | The server is preparing the data; Enter stops the scan |
| "Scanning, 40%" | WowVision is reading the data; Enter stops the scan |

Spoken progress: "Scanning" when you press the button, "Full scan started, 45000 auctions" when the data arrives, "Scanning, 25%" at every quarter, and "Full scan complete, 3200 items updated" at the end. Closing the auction house stops the scan.

Item tooltips then end with these lines, read like any other line:

- Vendor price per item, what a vendor pays for one item. Where the game shows its own Sell Price, which counts the whole stack, this line follows it,
- Auction minimum, the lowest price per item, with how many days ago the item was last seen (left out when it was seen today),
- Auction average, the average price per item, counting every item of every stack,
- Auction maximum, the highest price per item,
- Vendor Buy, what a vendor charges, once you have seen the item at a merchant.

The three auction prices cover every day on which a scan saw the item, at most the last 30 days. Each of these lines names the number of days before the price, for example "Auction minimum 3 days: 5 Silver".

The settings are in the WowVision menu under Windows, then Auction House:

| Setting | Default | What it does |
|---|---|---|
| Full Scan | Off | Shows the Full Scan button and the price lines in item tooltips |
| History Days | 30 | How many days of prices are kept and counted, at most 30 |
| Tooltip Prices | On | Adds the price lines to item tooltips while Full Scan is on |

### Example: find the cheapest Copper Ore and buy 20 (Mists, Retail, Forever)

1. Open the auction house. On the Buy tab press Tab to Search and type "Copper Ore". Press Enter.
2. Tab to Results. You hear "Copper Ore, 5 Silver, Available 340". Press Enter.
3. Focus lands on Back. Tab to Auctions to hear the stacks, cheapest first.
4. Tab to Quantity and type 20.
5. Tab to Total Price to hear the total. Tab to Buy and press Enter.
6. In the dialog, Tab to Buy Now and press Enter. To change your mind, press Cancel.

### Example: sell 20 Linen Cloth (Mists, Retail, Forever)

1. Pick up the Linen Cloth stack in your bags with Enter (use Ctrl+Tab to switch to them and back).
2. On the Tabs row open Sell. Tab to Place Item Here and press Enter with the cloth on your cursor.
3. Tab to Quantity and type 20.
4. Tab to Duration and press Enter to pick 24 hours.
5. Tab to Auctions to hear what others charge per unit.
6. Tab to the price boxes and type your unit price, for example 90 in Silver.
7. Tab to Deposit and Total Price to hear the costs.
8. Tab to Post and press Enter.

## What is not read yet

- The WoW Token on Buy and Sell in the modern window.
- On TBC there is no price history window: the price database only adds the tooltip lines described above.

See also: [Bags and bank](./bags-and-bank.md), [Windows overview](./overview.md), [Alerts](../basics/alerts.md), [Tooltips](../basics/tooltips.md).
