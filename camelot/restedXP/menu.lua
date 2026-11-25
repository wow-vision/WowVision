-- RestedXP's menus (the right-click menu of its window, the cog, the minimap button, the tips window) are lists of
-- items in the shape of the game's drop-down menus: text, func with arg1 and arg2, hasArrow with menuList for a
-- submenu, isTitle for a heading, checked for a box, disabled. This reads such a list as plain items so the
-- screens can show them as WowVision controls, and runs an item the way the drop-down would. No game calls here.
local ns = WowVision.restedXP
local Text = ns.Text

local Menu = {}
ns.Menu = Menu

-- What a drop-down item's function receives as "self" (the button that was clicked). Nothing in RestedXP's menus
-- uses more than calling Hide on it, so every method does nothing.
local button = setmetatable({}, {
    __index = function()
        return function() end
    end,
})

local function checkedOf(info)
    local checked = info.checked
    if type(checked) == "function" then
        local ok, value = pcall(checked, button)
        return ok and value and true or false
    end
    return checked and true or false
end

-- The items of a menu list: { kind, text, disabled, checked, children, info }.
--   kind "title": a heading, nothing to do
--   kind "submenu": children() gives its items (built when asked, a menu of every guide is long)
--   kind "toggle": a box; checked() says whether it is ticked
--   kind "button": runs its func
-- An item with no text is a separator and is left out.
function Menu.items(list)
    local items = {}
    if type(list) ~= "table" then
        return items
    end
    for _, info in ipairs(list) do
        if type(info) == "table" then
            local text = Text.plain(info.text)
            if text ~= nil then
                local item = { info = info, text = text, disabled = info.disabled and true or false }
                if info.isTitle then
                    item.kind = "title"
                elseif info.hasArrow and type(info.menuList) == "table" then
                    item.kind = "submenu"
                    item.children = function()
                        return Menu.items(info.menuList)
                    end
                elseif info.notCheckable then
                    item.kind = "button"
                else
                    item.kind = "toggle"
                    item.checked = function()
                        return checkedOf(info)
                    end
                end
                items[#items + 1] = item
            end
        end
    end
    return items
end

-- Whether Enter does something on the item.
function Menu.canActivate(item)
    if item.kind == "title" or item.disabled or item.info.notClickable then
        return false
    end
    if item.kind == "submenu" then
        return false
    end
    return type(item.info.func) == "function"
end

-- Whether the menu stays open after the item runs (a box that keeps the menu shown).
function Menu.keepsOpen(item)
    return item.info.keepShownOnClick and true or false
end

-- Runs the item as a click on it does: func(button, arg1, arg2, checked). Returns true, or false and the error.
function Menu.activate(item)
    if not Menu.canActivate(item) then
        return false
    end
    local info = item.info
    local ok, err = pcall(info.func, button, info.arg1, info.arg2, item.checked ~= nil and item.checked() or nil)
    if not ok then
        return false, err
    end
    return true
end
