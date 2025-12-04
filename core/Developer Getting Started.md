# Getting Started
This document is meant to be a basic overview of how the addon works and the functionality available so far. This is not intended to be comprehensive documentation is this is a very early prototype of the addon and things are likely to change. Function names, file names, and implementation details may be inconsistent between parts of the code as I have been working on this fairly quickly.

## Modules and Libraries
The addon is divided into modules, which can be nested. The intent is that each piece of functionality has its own module (so the auction house, talent UI, etc would all be their own modules.) This allows for more user customization and modules can be easily swapped out for different behavior depending on the game version.
Note that this isn't using the Ace3 Module prototypes. There were implementation issues with module nesting (only one level of a hierarchy seemed to be possible with Ace3.) As a result a more robust solution was implemented.
Ace3 is used to set up the Module object (IE the global WowVision),; AceConsole, AceDB, and AceLocale are used for slash commands, data storage, and localization respectively. Localization files should be stored in a localization folder with files for each locale (enUS.lua, deDE.lua, etc.)
Scripts are set up using the xml structure instead of .tocs for each directory. This is because xml files better detect added files; when I was using .toc files for everything a /reload would not pick up new scripts and I had to relaunch the entire client whenever I added a new file, which was extremely time consuming.

## Data Storage
Modules use AceDB to store data per profile. The db table for a module looks like this:

``` Lua
{
    submodules = {
        submodule1 = ...
    },
    alerts = {
        --Stored alert configuration goes here (will be referenced by settings)
        --This is stored here just in case we want alerts configured separately from settings
        --Some alerts may additionally not be stored here if they are dynamically created, such as for health/aura monitors later on
    },
    data = {
        --Misc variables go here, such as chat history
    },
    settings = {
        --User configurable settings here
    }
}
```

module.settings refers to the settings table of module's db, module.data refers to the data table. Settings are initialized with a settings object, which is created with the module:hasSettings() method which returns a reference to it.

## UI
The core of UI accessibility is virtual UI elements. These are UI elements that provide accessibility information and interactivity (for example a virtual list you could arrow through which could contain buttons, checkboxes to click on, etc.) this is an entirely auditory and textual UI framework and overlay; note that there are no visual elements for these.

Virtual elements can be created in a number of ways. They can be created similarly to something like WX or Windows Forms:

``` Lua
--Note that this would be part of some higher-level window or UI context, which we will get to later
local function ListButton_Click(event, button)
    print(button:getLabel() .. " was clicked)
end

local buttonList = WowVision.ui:createElement("List")
buttonList:setLabel("Buttons")
for i=1, 5 do
    local button = WowVision.ui:CreateElement("Button")
    button:setLabel("Button " .. i)
    button.events.click:subscribe(nil, ListButton_Click) --Nil means no self object passed to the event handler; don't worry about this for now
    buttonList:add(button)
end
```

This code will create a list of 5 buttons, which when clicked, print a message.

There is an easier way, and this is generated elements. Generators work similarly to React functional components; the elements hierarchy and properties are specified with a lua table schema. Let gen be a generator container; this is just a library of components that can be added to. The above code can be represented like this with a generator:

``` Lua
local function ListButton_Click(event, button)
    print(button:getLabel() .. " was clicked)
end

gen:Element("Example", function(props)
    local result = {"List",
        label = "Buttons",
        children = {}
    }
    for i=1, 5 do
        tinsert(result.children, {"Button",
        label = "Button " .. i,
        events = {
            click = ListButton_Click
        }
    })
    end
    return result
end)
```

Typically generated code will be run as part of a GeneratorPanel, which will update every frame based on game UI state (similar to how the React Virtual Dom would.) If a value in that table schema changed, the underlying virtual UI will efficiently update based on it (for example changing the label prop on one of the elements will simply update the corresponding virtual element without recreating the entire tree.)

Each module has an element generator, which can be set up using the module:hasUI() method. Elements can then be created on that generator, which will automatically be added when that module is enabled at game launch or on user toggle. Windows can then be set up per module, which can automatically show virtual UI when certain frames are activated, or manually depending on what is needed. For a simple example of this, look at the GameMenu module to see how this all fits together.

You might be thinking that it would be annoying to have to implement functionality for each UI element. The solution to this is Proxy Elements (for example ProxyButton, ProxyEditBox.) These can determine their state based on a passed game element and will often automatically retrieve their labels, checked state, etc. You might set up a proxy button like this:

``` Lua
return {"ProxyButton",
    frame = PlayerTalentFrameSpecialization.learnButton
}
```

The label of this button will automatically be set to the text of that button. When that button is hovered/focused in the virtual UI, pressing enter will trigger the left click of that game button for you, without you having to manually trigger it (backspace for right click.) This uses SecureActionButtonTemplate under the hood to click on buttons in a Blizzard approved way without running into issues with protected functions or tainting. In addition, proxy elements will not display if their corresponding game element doesn't (reference is nil or :IsShown() returns false.) Props you set manually will also have priority; if you set the label on a ProxyButton it will use that label and not try to retrieve it from its Blizzard frame.