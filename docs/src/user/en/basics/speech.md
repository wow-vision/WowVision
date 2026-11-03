# Speech and Sound

WowVision speaks everything through the game's built-in text to speech (TTS), using the voices installed on your computer. This page covers choosing a voice, setting speed and volume, stopping speech, the game's own TTS sounds, the recorded voice packs, and the quick /wv speech command.

## Where the settings are

Press Shift+F1 (or type /wv) to open the [WowVision menu](./menu-and-settings.md), press S until you hear Speech, and press Enter. You can also jump straight there by typing /wv gsettings speech.

The Speech module is always on; it has no Enabled checkbox.

## The speech settings

| Setting | Default | What it does |
|---|---|---|
| Speech Voice | The first installed voice | Which TTS voice speaks. Enter opens the list of voices installed on your computer. WowVision remembers the voice by its name, so installing or removing Windows voices later does not silently switch you to a different one. |
| Speech Volume | 100 | Loudness of the TTS voice, from 0 to 100. |
| Speech Rate | 0 | Speed of the voice. 0 is normal, negative numbers are slower and positive numbers faster. It goes from -10 to 10; a value outside that range snaps to the nearest end. |
| Speech Queue | On | (The Burning Crusade, Mists of Pandaria, Retail and WoW: Forever) WowVision speaks one line at a time and lines up the rest, including speech from the game and from other addons. Turn it off only if another addon that uses speech misbehaves; WowVision then talks to the game directly. |
| Speech Style | Direct | (Classic Era only) Direct speaks each line at once. Buffered lines the speech up and waits a moment after every interruption before speaking the next line. Try Buffered if the first words after an interruption get swallowed. |
| Sound Between Chat Lines | Off after your first login | The game's own sound that separates chat lines. See [Game sounds around speech](#game-sounds-around-speech). |
| Activity Sound When Unfocused | The game's setting | The game's own sound when a message is spoken while the chat window is hidden. |

Example: raise your speech rate.

1. Press Shift+F1 to open the WowVision menu.
2. Press S until you hear "Speech, Button", then Enter.
3. Press Down to Speech Rate, Number, 0.
4. Press Right a few times. You hear each new number, and the voice speaks faster from the next line on. Or press Enter, type 5, and press Enter.

Example: change the voice.

1. In the Speech menu, move to Speech Voice and press Enter.
2. Move through the list of voices; the current one reads as "Selected". Press Enter on the one you want.

On Classic Era, TBC and Mists, WowVision puts spaces around slashes in what it says, so "250/500" is spoken as two numbers: "250 / 500". Retail and WoW: Forever hand the text over untouched.

Speech Voice, Speech Volume, Speech Rate and the queue or style setting are account-wide by default. You can give one character its own values with the Scope entry of the context menu (Shift+F10) on a setting, see [per-character and account-wide settings](./menu-and-settings.md#per-character-and-account-wide-settings). The two game sound checkboxes are the game's own settings and have no Scope entry.

## Quick setup with /wv speech

/wv speech sets the voice, rate and volume in one line. It is made for a login macro, because it takes effect at once and speaks a confirmation.

| What you type | What happens |
|---|---|
| /wv speech | Prints your current voice number, rate and volume in the chat frame, followed by a list of all voices with their numbers. You normally hear it as a chat message. |
| /wv speech 1 8 100 | Voice number 1, rate 8, volume 100. |
| /wv speech 1 8 | Voice 1 and rate 8; volume stays as it is. |
| /wv speech 2 | Voice 2 only; rate and volume stay as they are. |

Voice numbers start at 0: your first voice is number 0. Rate is limited to -10 to 10, volume to 0 to 100, and decimals are rounded. If the voice number does not exist, or a value is not a number, WowVision prints a message in chat and changes nothing. When it works you hear, for example, "Speech voice Microsoft Zira Desktop, rate 8, volume 100".

## Stopping speech

- Press Ctrl on its own at any time to cut off the current speech. This works whether or not a window is open, and also when you use Ctrl as a modifier (Ctrl+Tab, Ctrl+D), because speech stops the moment the key goes down.
- Every navigation key (arrows, Tab, Home, End and so on) stops what is being spoken before it reads the new control, so fast arrowing never builds a backlog.
- The Interrupt Speech on Window Close setting (in the UI menu, off by default) also cuts speech when a window closes. Turn it on if the old window's text keeps talking after you have left it.
- Alerts can interrupt too. A TTS alert with Priority Message (interrupts) switched on stops the current speech before it speaks, as the Target Change alert does. See [Alerts](./alerts.md).

## Game sounds around speech

The game's TTS plays two small sounds of its own, and WowVision gives you a checkbox for each in the Speech menu:

- Sound Between Chat Lines is a short sound the game plays between chat lines. Because it would play between all of WowVision's announcements, WowVision turns it off for you the first time each character logs in with the addon. After that your choice stands: if you turn it on again, it stays on.
- Activity Sound When Unfocused is the game's sound for a message spoken while the chat window is hidden.

These two checkboxes are not stored by WowVision. They are the game's own settings, so the game's /tts playline and /tts playactivity commands and the Speech menu always agree.

## Recorded voice packs

Some alerts play recordings instead of using TTS: the compass directions ("north", "northeast"), numbers from 1 to 100 (target health, range to the target, the enemy count), and so on. These recordings come in voice packs. Two ship with WowVision:

- Matthew
- Joanna

Each alert output of type Voice Alert has a setting that picks the pack. It is called Voice Pack and sits right below the Enabled checkbox of the output's screen. Recordings play immediately and are not affected by the speech queue, your TTS voice or your TTS rate. See [Alerts](./alerts.md) for how to choose outputs.

## Voices for single alerts

Every TTS alert output has its own Voice setting. Until you choose something there, it simply follows Speech Voice, and it shows that voice as its value. Pick another voice and that alert always uses it. This lets you, for instance, hear target changes in one voice and chat in another.

The announcements made while you walk (new dots on the minimap) are spoken by the game's voice number 0 at your Speech Rate and Speech Volume, instead of your Speech Voice, because a screen reader would cut them off at every key press. You can change that alert's Voice setting as well. This alert has no Priority Message (interrupts) setting.

## Using a screen reader voice

If your TTS voice hands the text to a screen reader, such as NVDA through the SAPI2SR voice, WowVision makes sure that repeated lines are spoken every time and that a new line cuts off the old one, just as with a normal voice.

There is nothing to switch on.

## Differences between game versions

| | Classic Era | TBC and Mists | Retail and WoW: Forever |
|---|---|---|---|
| Speech Queue | not available | yes | yes |
| Speech Style (Direct or Buffered) | yes | not available | not available |
| Spaces around slashes | yes | yes | no |
| Voice, volume, rate, game sound checkboxes | yes | yes | yes |

## See also

- [The WowVision menu and settings](./menu-and-settings.md)
- [Alerts](./alerts.md)
- [Troubleshooting](../getting-started/troubleshooting.md)
