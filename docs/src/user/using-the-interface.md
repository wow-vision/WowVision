# Using the Interface

If you've used a screenreader on Windows before, WowVision will feel familiar. When a game window opens — your bags, a merchant, the escape menu — WowVision automatically reads it and lets you navigate with the keyboard, just like a desktop application.

## Speech

WowVision uses WoW's built-in text-to-speech to announce everything. The default voice and speed will work out of the box, but you'll likely want to adjust the speech rate and voice to your preference. You can do this from the WowVision menu (`/wv`) under the speech settings.

## Navigation

- **Arrow keys** move between elements in the window. Up and Down move vertically through lists and sections. Left and Right move horizontally when available.
- **Tab** and **Shift+Tab** move to the next or previous element, cycling through the window linearly.
- **Home** and **End** jump to the first or last element.
- **Ctrl+Tab** and **Ctrl+Shift+Tab** switch between open windows when more than one is open. Each window remembers where your focus was.
- **Enter** performs a left click on the focused element.
- **Backspace** performs a right click on the focused element.
- **Escape** closes the current window.

Both Enter and Backspace support modifiers — Shift+Enter triggers a shift-left-click, Ctrl+Backspace triggers a ctrl-right-click, and so on. This matters in WoW because modifier+click combinations often do different things (shift-clicking an item to link it in chat, for example).

When you land on an element, WowVision announces its label and type — for example, "Close, Button" or "Auto Loot, Checkbox, Selected."

## The Cursor

WoW uses a cursor system for moving items around. When you left click (Enter) an item in your bags or inventory, it gets picked up and attached to the cursor. You'll hear an announcement when this happens. From there, you can left click another slot to place it, or press Escape to put it back.

Right clicking (Backspace) an item typically uses it directly — equipping gear, drinking a potion, or opening a container, depending on the item and context.

## Reading Tooltips

Many elements in WoW have tooltips with additional information — item stats, spell descriptions, NPC details. WowVision gives you full access to these:

- **Space** reads the full tooltip for the focused element.
- **Shift+Up** and **Shift+Down** move through the tooltip line by line.
- **Shift+Left** and **Shift+Right** read the left or right column of the current tooltip line (useful for stat breakdowns and other two-column layouts).

## Alerts

As you play, WowVision announces various game events automatically — changing zones, selecting a target, receiving chat messages, and more. These are alerts, and each one can be configured to speak a message, play a sound, or both. You can enable, disable, and customize individual alerts from the WowVision menu.

## The WowVision Menu

Type `/wv` in chat to open the WowVision menu. From here you can access settings, configure alerts, and manage other addon options.

## Combat

When you enter combat, WowVision steps aside — navigation is suspended so your keybindings don't interfere with gameplay. When combat ends, your window and focus state are restored automatically.
