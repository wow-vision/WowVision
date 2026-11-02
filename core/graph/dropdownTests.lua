local testRunner = WowVision.testing.testRunner
local dropdown = WowVision.graph.dropdown

-- Menu stand-ins: a name, the menu it hangs from and its left edge.
local function menu(name, parent, left)
    return { name = name, parent = parent, left = left }
end

local function anchorOf(frame)
    return frame.parent
end

local function leftOf(frame)
    return frame.left
end

local function names(menus)
    local out = {}
    for i, frame in ipairs(menus) do
        out[i] = frame.name
    end
    return table.concat(out, ",")
end

testRunner:addSuite("DropdownChain", {
    ["submenus to the right: root, then each level"] = function(t)
        local root = menu("root", nil, 100)
        local sub = menu("sub", root, 300)
        local subsub = menu("subsub", sub, 500)
        t:assertEqual(names(dropdown.chainMenus(root, { subsub, sub }, anchorOf, leftOf)), "root,sub,subsub")
    end,

    ["a submenu flipped left of its parent is still the second level"] = function(t)
        -- Set Loot Specialization opened at the cursor near the screen's right edge
        local root = menu("root", nil, 1500)
        local sub = menu("sub", root, 1300)
        t:assertEqual(names(dropdown.chainMenus(root, { sub }, anchorOf, leftOf)), "root,sub")
    end,

    ["a menu whose anchor cannot be followed comes last, by left edge"] = function(t)
        local root = menu("root", nil, 100)
        local sub = menu("sub", root, 300)
        local loose = menu("loose", nil, 200)
        t:assertEqual(names(dropdown.chainMenus(root, { loose, sub }, anchorOf, leftOf)), "root,sub,loose")
    end,
})
