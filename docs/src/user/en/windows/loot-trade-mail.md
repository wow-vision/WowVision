# Loot, Trade and Mail

This page covers three ways of moving items and gold between you and other characters: rolling for group loot, trading with another player, and the mailbox. It also tells you what is not read yet.

## Loot

### The loot window

WowVision does not read the loot window that lists the items on a corpse or in a chest. There is no window for it, and no key or menu that lists the loot. The easiest way to collect loot is the game's own Auto Loot option. Turn it on in the game options (see [System windows](./system.md#the-game-options-window)) and everything is picked up as soon as you loot.

What you picked up is announced through the loot messages the game writes in your chat, which WowVision speaks like any other chat message when a chat tab that shows them is set to speak. See [Chat](./chat.md).

Your own target menu holds the loot settings. Target yourself and press Alt+T: the menu that opens has the game's loot and dungeon difficulty entries, among other things, as a right click on your own portrait would. See [Targeting](../world/targeting.md).

### Group loot rolls: need, greed, pass

When you are in a group and an item drops that the group rolls on, the game opens a roll window for each item. WowVision gives you keys to answer it without the mouse. They work wherever you are in the game and need no window to be focused.

| Key | Binding name | What it does |
|-----|--------------|--------------|
| Alt+Ctrl+Y | Roll Tooltip | Reads the whole tooltip of the item that is up for a roll: name, quality, item level, stats and requirements. |
| Alt+Ctrl+U | Roll Need | Rolls Need. |
| Alt+Ctrl+I | Roll Greed | Rolls Greed. |
| Alt+Ctrl+O | Roll Pass | Passes. |
| Alt+Ctrl+P | Roll Bonus | Presses the bonus roll button, where the game has bonus rolls. |

All of these can be changed in the keybinding window. See [Keybindings](../basics/keybindings.md).

If more than one roll window is open, the keys act on the first one that is visible, one item at a time. After you answer it, the next press goes to the next item. If there is no roll window open, WowVision says "No loot."

Example: a group rolls for a blue sword.

1. A roll window opens. You hear nothing from it by itself, so press Alt+Ctrl+Y to hear the item name.
2. Decide. Press Alt+Ctrl+U for Need, Alt+Ctrl+I for Greed, or Alt+Ctrl+O to pass.
3. For some items the game asks you to confirm, for example "This item will bind to you". That is a popup. Read it, Tab to the confirm button and press Enter. See [System windows](./system.md#popups-and-confirmation-dialogs).

The Roll Bonus key exists only on game versions where the bonus roll window exists, which is Retail and WoW: Forever, and possibly Mists of Pandaria.

Disenchant rolls are not offered with these keys.

## Trade

When another player trades with you, the trade window opens and WowVision reads it. Start a trade the way the game does. With the player targeted, open the target menu with Alt+T, see [Targeting](../world/targeting.md), or use the game's own trade key or command.

The stops, in order:

1. Your offer: your name, then your six trade slots.
2. Money (yours): the gold you offer, or "Empty".
3. The other player's offer: their name, then their six slots.
4. Their Money: for example "Money 5 Gold", or "Money Empty".
5. The Trade button.
6. The Cancel button.

Each slot reads the item, its quality colour as a word and the number of items if the stack is more than one: "Linen Cloth, White x20", or "Empty". Slots read their current content every time you move onto them. The other player's slots change while they decide, so step onto a slot again to hear what is in it now.

### Putting an item into the trade

- Open your bags and press Backspace on the item. With the trade open it says "Add to Trade" in the context menu and moves the item into the first free slot.
- Or pick the item up with Enter or \\, move to one of your trade slots and press Enter. See [Bags and bank](./bags-and-bank.md).
- To take an item back out, press \\ (Drag) on your trade slot, then put it into a bag with Enter on a free slot.

### Offering gold

You cannot type your gold into the trade window with WowVision. The game seals the money box from addons to protect players from scams. You can hear the amount that is already offered, but entering it is only possible with the mouse. If you need to pay someone gold, send it by mail instead (see below).

### Finishing

Press Enter on the Trade button to accept, or Enter on Cancel to call the trade off. Escape also cancels it. The trade goes through when both sides have accepted. WowVision does not read the other player's accept mark, so listen to the game's chat messages.

## The mailbox

Walk up to a mailbox and interact with it. The mail window opens, and your bags open next to it. (Press Ctrl+Tab to switch between them.)

The stops, in order:

1. Tabs: Inbox and Send Mail. The one you are on says "selected". Left and Right move between them, and Enter switches.
2. Open All: a button that takes everything from your inbox, when the game shows it.
3. Inbox: your letters on this page.
4. Previous Page and Next Page: only when there are more letters than fit.
5. When a letter is open: the letter and its buttons (see below).
6. On the Send Mail tab: the send form (see below).

### The inbox

Each letter reads who it is from and the subject:

- "From: Auction House, Subject: Auction successful: Linen Cloth"
- "From: Thrall, Subject: Hello"

The inbox does not say whether a letter has gold or items. You find that out when you open it. An empty inbox says "Empty".

### Reading a letter and taking what is in it

Press Enter on a letter to open it. Then press Tab until you reach the opened letter (the page buttons, if any, come first). Its stop reads:

1. The sender.
2. The subject.
3. The body text. This is only present when the letter has text.
4. For an auction house sale or purchase, the invoice: the item, the buyer or seller, the sale price, the deposit, the auction house's cut and the total you received.
5. The attachments: Letter for the letter itself, the gold when it holds money (for example "5 Gold 20 Silver"), and each item with its name, colour and count: "Linen Cloth, White x 20". Money that is already taken reads "Empty".

Press Enter on an attachment to take it into your bags or purse. The attachment list shrinks as you take things.

After the letter, each of the buttons the game shows has its own stop: Reply, Delete, Close and Report Spam. Press Enter to use one. Delete removes the letter. Take the attachments first: the game may ask you to confirm deleting a letter that still has something in it.

A cash on delivery (COD) letter asks you to pay when you take the item. The game shows a popup. See [System windows](./system.md#popups-and-confirmation-dialogs).

Example: collect an auction sale.

1. Open the mailbox and press Enter on "From: Auction House, Subject: Auction successful".
2. Tab to the letter. Listen to the invoice.
3. Down to the money attachment and press Enter. The gold is in your purse.
4. Tab to Delete (or Close) and press Enter.

Or press Enter on Open All to take everything at once.

### Sending mail

(Classic Era, The Burning Crusade and Mists of Pandaria. The Send Mail tab is not read on Retail or WoW: Forever yet.)

Select the Send Mail tab. The stops are:

1. Send To: an edit box for the player's name. Tabbing in starts typing.
2. Subject: an edit box.
3. Body: an edit box for the letter text.
4. Attachments: the items attached so far, followed by Drop Item, an empty slot where you can place an item from your cursor.
5. Send Money: a checkbox.
6. COD: a checkbox. It is greyed out until you attach an item. Send Money and COD are a pair: turning one on turns the other off.
7. A money group named Amount to Send or COD Amount, which follows the choice above, with three edit boxes: Gold, Silver and Copper. Each box is a stop of its own, so Tab moves from one to the next.
8. Postage: what sending will cost.
9. The Send button and the Cancel button.

Typing: Tab into an edit box and type. Tab leaves the box and moves on to the next stop, Shift+Tab goes back. The game's own Tab chain between mail fields is turned off.

Example: send 10 Linen Cloth and 5 silver to a friend.

1. Open the Send Mail tab.
2. In Send To type "Anna". Press Tab.
3. In Subject type "Cloth". Press Tab.
4. In Body type a note and press Tab.
5. In your bags, press Backspace on the Linen Cloth (the context menu says "Attach to Mail"). Return with Ctrl+Tab. The Attachments stop now reads "Linen Cloth, White x 10".
6. Tab to Send Money; it is the game's default and should be selected, so you hear that it is checked. In Silver type 5.
7. Tab to Send and press Enter.

## Settings and alerts

None of these windows has settings or alerts of its own. The roll keys can be rebound in the keybinding window. See [Keybindings](../basics/keybindings.md). In the WowVision menu, under Windows, the Loot, Trade and Mail entries each have just an Enabled switch. Switching Loot off turns the roll keys off.

If the addon Sku is loaded, WowVision leaves the trade window and the mailbox to Sku. The roll keys stay active.

## Troubleshooting

- The roll keys say "No loot." No roll window is open. The roll may be over, or the game is not showing it.
- I cannot enter gold into a trade. This cannot be done with WowVision. Use mail.
- The Send Mail tab is empty. On Retail and WoW: Forever it is not read yet.
