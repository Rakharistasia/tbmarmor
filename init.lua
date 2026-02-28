--[[
    TBM Armor Buyer & Equipper v1.0 by Joakhan
    Buys TBM (The Broken Mirror) armor, non-visible gear, and weapons
    from Lyndalin Delwadamain in Plane of Tranquility and equips them.

    Usage: /lua run tbmarmor

    Currency: Remnants of Tranquility
    Vendor:   Lyndalin Delwadamain
    Zone:     Plane of Tranquility (potranquility)
    Inspired by: TBMSwap
]]

local mq = require('mq')
---@type ImGui
local imgui = require 'ImGui'

-- ---------------------------------------------------------------------------
-- Character info
-- ---------------------------------------------------------------------------
local myName  = mq.TLO.Me.Name()
local myLevel = mq.TLO.Me.Level()
local myClass = mq.TLO.Me.Class.ShortName()
local RoT     = mq.TLO.Me.AltCurrency('Remnants of Tranquility')() or 0

-- ---------------------------------------------------------------------------
-- Class groupings
-- ---------------------------------------------------------------------------
local plateClasses  = { BRD = true, CLR = true, PAL = true, SHD = true, WAR = true }
local clothClasses  = { ENC = true, MAG = true, NEC = true, WIZ = true }
local leatherClasses = { BST = true, DRU = true, MNK = true }
local chainClasses  = { BER = true, RNG = true, ROG = true, SHM = true }

-- ---------------------------------------------------------------------------
-- Determine armor set for this class
-- ---------------------------------------------------------------------------
local function getArmorSet()
    if plateClasses[myClass]  then return 'Protector' end
    if clothClasses[myClass]  then return 'Sponsor'   end
    if leatherClasses[myClass] then return 'Sifter'    end
    if chainClasses[myClass]  then return 'Dredger'    end
    return 'Unknown'
end

local armorSet = getArmorSet()

-- ---------------------------------------------------------------------------
-- Visible armor definitions per set (7 pieces)
-- ---------------------------------------------------------------------------
local visibleArmor = {
    Protector = {
        { name = "Preserving Protector's Helm",        slot = 'head'      },
        { name = "Preserving Protector's Breastplate",  slot = 'chest'     },
        { name = "Preserving Protector's Vambraces",    slot = 'arms'      },
        { name = "Preserving Protector's Gauntlets",    slot = 'hands'     },
        { name = "Preserving Protector's Greaves",      slot = 'legs'      },
        { name = "Preserving Protector's Boots",        slot = 'feet'      },
        { name = "Preserving Protector's Bracer",       slot = 'leftwrist' },
    },
    Sponsor = {
        { name = "Preserving Sponsor's Cap",         slot = 'head'      },
        { name = "Preserving Sponsor's Robe",        slot = 'chest'     },
        { name = "Preserving Sponsor's Sleeves",     slot = 'arms'      },
        { name = "Preserving Sponsor's Gloves",      slot = 'hands'     },
        { name = "Preserving Sponsor's Pants",       slot = 'legs'      },
        { name = "Preserving Sponsor's Boots",       slot = 'feet'      },
        { name = "Preserving Sponsor's Wristguard",  slot = 'leftwrist' },
    },
    Sifter = {
        { name = "Preserving Sifter's Cowl",        slot = 'head'      },
        { name = "Preserving Sifter's Tunic",       slot = 'chest'     },
        { name = "Preserving Sifter's Armwraps",    slot = 'arms'      },
        { name = "Preserving Sifter's Gloves",      slot = 'hands'     },
        { name = "Preserving Sifter's Leggings",    slot = 'legs'      },
        { name = "Preserving Sifter's Boots",       slot = 'feet'      },
        { name = "Preserving Sifter's Wristguard",  slot = 'leftwrist' },
    },
    Dredger = {
        { name = "Preserving Dredger's Coif",        slot = 'head'      },
        { name = "Preserving Dredger's Coat",        slot = 'chest'     },
        { name = "Preserving Dredger's Sleeves",     slot = 'arms'      },
        { name = "Preserving Dredger's Gauntlets",   slot = 'hands'     },
        { name = "Preserving Dredger's Leggings",    slot = 'legs'      },
        { name = "Preserving Dredger's Boots",       slot = 'feet'      },
        { name = "Preserving Dredger's Wristguard",  slot = 'leftwrist' },
    },
}

-- ---------------------------------------------------------------------------
-- Non-visible items: full item pool per slot group
-- Classes restriction: nil = all classes; table = only those classes
-- ---------------------------------------------------------------------------
local nonVisPool = {
    charm = {
        { name = "Footman's Trinket"   },
        { name = "Inspector's Trinket" },
        { name = "Delegator's Trinket" },
    },
    back = {
        { name = "Gutter-Runner's Cape"  },
        { name = "Bright Sapphire Cloak" },
    },
    neck = {
        { name = "Malignant Necklace"   },
        { name = "Woven Flesh Necklace" },
    },
    face = {
        { name = "Courtier's Mask" },
        { name = "Rebuker's Mask"  },
        { name = "Defender's Mask", classes = { WAR=true, PAL=true, SHD=true, BRD=true } },
    },
    shoulder = {
        { name = "Skirmisher's Shoulderpads" },
        { name = "Privateering Pauldrons"    },
    },
    ear = {
        { name = "Sneak's Earring"   },
        { name = "Abettor's Earring" },
        { name = "Invoker's Earring" },
        { name = "Evoker's Earring"  },
        { name = "Abjurer's Earring" },
    },
    finger = {
        { name = "Acolyte's Ring"    },
        { name = "Delegator's Ring"  },
        { name = "Footman's Ring"    },
        { name = "Inspector's Ring"  },
        { name = "Ring of Depravity" },
    },
    waist = {
        { name = "Footman's Belt"   },
        { name = "Inspector's Belt" },
    },
    ranged = {
        { name = "Ball of Everliving Golem" },
        { name = "Grim Idol of Dread"       },
    },
}

-- Ordered slot layout for the UI (rightwrist added dynamically from getDeathscentWrist)
local nonVisSlotDefs = {
    { label = 'Charm',        slot = 'charm',       group = 'charm'    },
    { label = 'Back',         slot = 'back',        group = 'back'     },
    { label = 'Neck',         slot = 'neck',        group = 'neck'     },
    { label = 'Face',         slot = 'face',        group = 'face'     },
    { label = 'Shoulder',     slot = 'shoulder',    group = 'shoulder' },
    { label = 'Left Ear',     slot = 'leftear',     group = 'ear'      },
    { label = 'Right Ear',    slot = 'rightear',    group = 'ear'      },
    { label = 'Left Finger',  slot = 'leftfinger',  group = 'finger'   },
    { label = 'Right Finger', slot = 'rightfinger', group = 'finger'   },
    { label = 'Waist',        slot = 'waist',       group = 'waist'    },
    { label = 'Ranged',       slot = 'ranged',      group = 'ranged'   },
}

-- Second wrist item per armor type (all classes get one)
local function getDeathscentWrist()
    if plateClasses[myClass]   then return "Deathscent Bracer"             end
    if clothClasses[myClass]   then return "Deathscent Cloth Wristguard"   end
    if leatherClasses[myClass] then return "Deathscent Leather Wristguard" end
    if chainClasses[myClass]   then return "Deathscent Chain Wristguard"   end
    return nil
end

-- Build per-slot selection state from the pool, filtered to the current class.
-- Each entry: { label, slot, items (string list with "None" first), selectedIdx (0-based), enabled }
local function buildNonVisSelections()
    local sels = {}
    for _, def in ipairs(nonVisSlotDefs) do
        local pool  = nonVisPool[def.group] or {}
        local items = { 'None' }
        for _, item in ipairs(pool) do
            if not item.classes or item.classes[myClass] then
                table.insert(items, item.name)
            end
        end
        if #items > 1 then
            table.insert(sels, {
                label       = def.label,
                slot        = def.slot,
                items       = items,
                selectedIdx = 1,   -- 0-based; 1 = first real item
                enabled     = true,
            })
        end
    end
    -- Right wrist: single class-specific Deathscent item
    local deathscentName = getDeathscentWrist()
    if deathscentName then
        table.insert(sels, {
            label       = 'Right Wrist',
            slot        = 'rightwrist',
            items       = { 'None', deathscentName },
            selectedIdx = 1,
            enabled     = true,
        })
    end
    return sels
end

-- ---------------------------------------------------------------------------
-- Weapons
-- ---------------------------------------------------------------------------
local weaponDefs = {
    -- 2H weapons
    { name = "Armsman's Greatsword", slot = 'primary',   classes = { WAR = true, PAL = true, RNG = true, SHD = true, BER = true } },
    { name = "Armsman's Staff",      slot = 'primary',   classes = { WAR = true, PAL = true, RNG = true, SHD = true, MNK = true, BST = true, BER = true } },
    -- 1H weapons
    { name = "Armsman's Axe",        slot = 'primary',   classes = { PAL = true, SHD = true } },
    { name = "Armsman's Sword",      slot = 'primary',   classes = { WAR = true, RNG = true, BRD = true, ROG = true } },
    { name = "Armsman's Club",       slot = 'primary',   classes = { WAR = true, RNG = true, MNK = true, BRD = true, ROG = true, BST = true } },
    { name = "Armsman's Shiv",       slot = 'primary',   classes = { WAR = true, RNG = true, BRD = true, ROG = true, BST = true } },
    { name = "Armsman's Dagger",     slot = 'primary',   classes = { ROG = true } },
    { name = "Armsman's Knuckles",   slot = 'primary',   classes = { MNK = true, BST = true } },
    { name = "Armsman's Wand",       slot = 'primary',   classes = { NEC = true, WIZ = true, MAG = true, ENC = true } },
    { name = "Armsman's Rod",        slot = 'primary',   classes = { CLR = true, DRU = true, SHM = true } },
    -- Offhand / Shield
    { name = "Armsman's Shield",     slot = 'secondary', classes = { WAR = true, PAL = true, RNG = true, SHD = true, MNK = true, BRD = true, ROG = true, BST = true } },
    { name = "Armsman's Buckler",    slot = 'secondary', classes = { CLR = true, DRU = true, SHM = true, NEC = true, WIZ = true, MAG = true, ENC = true } },
    -- Ranged
    { name = "Armsman's Bow",        slot = 'range',     classes = { WAR = true, PAL = true, RNG = true, SHD = true, ROG = true } },
}

local function buildWeaponList()
    local list = {}
    for _, wep in ipairs(weaponDefs) do
        if wep.classes[myClass] then
            table.insert(list, { name = wep.name, slot = wep.slot, checked = false })
        end
    end
    return list
end

-- ---------------------------------------------------------------------------
-- State variables
-- ---------------------------------------------------------------------------
local doDebug   = false
local isRunning = false
local statusLines = {}
local MAX_STATUS = 200

-- Selection tables (built once, modified by user)
local visChecks        = {}   -- { {name, slot, checked}, ... }
local nonVisSelections = {}   -- { {label, slot, items, selectedIdx, enabled}, ... }
local weaponChecks     = {}

local function initCheckboxes()
    visChecks = {}
    local setItems = visibleArmor[armorSet] or {}
    for _, item in ipairs(setItems) do
        table.insert(visChecks, { name = item.name, slot = item.slot, checked = true })
    end

    nonVisSelections = buildNonVisSelections()

    weaponChecks = buildWeaponList()
end

initCheckboxes()

-- ---------------------------------------------------------------------------
-- Utility helpers
-- ---------------------------------------------------------------------------
local function addStatus(msg)
    table.insert(statusLines, msg)
    if #statusLines > MAX_STATUS then
        table.remove(statusLines, 1)
    end
    print(msg)
end

local function updateRemnant()
    RoT = mq.TLO.Me.AltCurrency('Remnants of Tranquility')() or 0
end

--- Check if an item is already equipped in the given slot
local function isEquipped(itemName, slotName)
    local equipped = mq.TLO.Me.Inventory(slotName)
    if equipped() and equipped.Name() == itemName then
        return true
    end
    return false
end

--- Check if an item is in inventory (bags)
local function isInInventory(itemName)
    local found = mq.TLO.FindItem('=' .. itemName)
    if found() and found.Name() == itemName then
        -- Make sure it is not an equipped item (FindItem searches equipped too)
        -- If the item's InvSlot is <= 22 it is equipped, not in bags
        local invSlot = found.ItemSlot()
        if invSlot and invSlot >= 23 then
            return true
        end
    end
    return false
end

--- Determine if bow is checked in weapons
local function isBowChecked()
    for _, w in ipairs(weaponChecks) do
        if w.name == "Armsman's Bow" and w.checked then
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Build the final shopping list based on checkboxes
-- ---------------------------------------------------------------------------
local function buildShoppingList()
    local list = {}

    -- Visible armor
    for _, item in ipairs(visChecks) do
        if item.checked then
            table.insert(list, { name = item.name, slot = item.slot })
        end
    end

    -- Non-visible (slot dropdowns)
    local bowSelected = isBowChecked()
    for _, slot in ipairs(nonVisSelections) do
        if slot.enabled and slot.selectedIdx >= 1 then
            local itemName = slot.items[slot.selectedIdx + 1]
            if itemName and itemName ~= 'None' then
                if slot.slot == 'ranged' and bowSelected then
                    addStatus('\\ao  Skipping ranged slot (Bow selected)')
                else
                    table.insert(list, { name = itemName, slot = slot.slot })
                end
            end
        end
    end

    -- Weapons
    for _, w in ipairs(weaponChecks) do
        if w.checked then
            table.insert(list, { name = w.name, slot = w.slot })
        end
    end

    return list
end

-- ---------------------------------------------------------------------------
-- Check / scan equipped gear
-- ---------------------------------------------------------------------------
local function doCheck()
    statusLines = {}
    addStatus('\\ag--- Scanning equipped gear ---')
    local shoppingList = buildShoppingList()
    local needCount = 0
    local skipCount = 0
    local inBagCount = 0

    for _, item in ipairs(shoppingList) do
        if isEquipped(item.name, item.slot) then
            addStatus(string.format('\\ag  [EQUIPPED] \\ax%s in %s', item.name, item.slot))
            skipCount = skipCount + 1
        elseif isInInventory(item.name) then
            addStatus(string.format('\\ao  [IN BAGS] \\ax%s -> %s (needs equip)', item.name, item.slot))
            inBagCount = inBagCount + 1
        else
            addStatus(string.format('\\ar  [NEED TO BUY] \\ax%s -> %s', item.name, item.slot))
            needCount = needCount + 1
        end
    end

    addStatus(string.format('\\ag--- Results: \\at%d\\ag equipped, \\ao%d\\ag in bags, \\ar%d\\ag need buying ---',
        skipCount, inBagCount, needCount))
    updateRemnant()
    addStatus(string.format('\\axRemnants of Tranquility: \\at%d', RoT))
end

-- ---------------------------------------------------------------------------
-- Open the merchant window
-- ---------------------------------------------------------------------------
local function openMerchant()
    if mq.TLO.Window('MerchantWnd').Open() then
        return true
    end

    -- Target the vendor
    mq.cmdf('/target npc "Lyndalin Delwadamain"')
    mq.delay(2000)

    -- Wait for target to fully resolve
    mq.delay(3000, function()
        return mq.TLO.Target() and mq.TLO.Target.CleanName() == 'Lyndalin Delwadamain'
    end)

    if not mq.TLO.Target() or mq.TLO.Target.CleanName() ~= 'Lyndalin Delwadamain' then
        addStatus('\\ar  Could not target Lyndalin Delwadamain!')
        return false
    end

    -- Check distance
    if mq.TLO.Target.Distance() and mq.TLO.Target.Distance() > 20 then
        addStatus('\\ar  Too far from vendor! Use "Go to Vendor" first.')
        return false
    end

    mq.delay(500)
    mq.cmd('/click right target')
    mq.delay(5000, function() return mq.TLO.Window('MerchantWnd').Open() end)

    if not mq.TLO.Window('MerchantWnd').Open() then
        addStatus('\\ar  Failed to open merchant window!')
        return false
    end

    -- Wait for items to be received
    mq.delay(5000, function() return mq.TLO.Merchant.ItemsReceived() end)

    if not mq.TLO.Merchant.ItemsReceived() then
        addStatus('\\ar  Merchant items not received in time!')
        return false
    end

    return true
end

local function closeMerchant()
    if mq.TLO.Window('MerchantWnd').Open() then
        mq.cmdf('/notify MerchantWnd MW_Done_Button leftmouseup')
        mq.delay(1000)
    end
end

-- ---------------------------------------------------------------------------
-- Buy a single item from the merchant
-- ---------------------------------------------------------------------------
local function buyItem(itemName)
    addStatus(string.format('\\ao  Buying: \\at%s', itemName))

    mq.cmdf('/invoke ${Merchant.SelectItem[=%s]}', itemName)
    mq.delay(1000)

    mq.cmdf('/notify MerchantWnd MW_Buy_Button leftmouseup')
    mq.delay(1000)

    -- Handle confirmation dialog if it appears
    if mq.TLO.Window('ConfirmationDialogBox').Open() then
        mq.cmdf('/notify ConfirmationDialogBox CD_Yes_Button leftmouseup')
        mq.delay(1500)
    end

    mq.delay(500)
    updateRemnant()
    return true
end

-- ---------------------------------------------------------------------------
-- Equip a single item from inventory
-- ---------------------------------------------------------------------------
local function equipItem(itemName, slotName)
    -- First check if MQ2Exchange plugin is loaded for easier equipping
    if mq.TLO.Plugin('MQ2Exchange').IsLoaded() then
        addStatus(string.format('\\ao  Equipping (exchange): \\at%s \\ax-> %s', itemName, slotName))
        mq.cmdf('/exchange "%s" %s', itemName, slotName)
        mq.delay(1500)
    else
        -- Manual method: pick up item, then click on the slot
        addStatus(string.format('\\ao  Equipping (itemnotify): \\at%s \\ax-> %s', itemName, slotName))

        -- Pick up the item from inventory
        mq.cmdf('/itemnotify "%s" leftmouseup', itemName)
        mq.delay(750)

        -- Check if item is on cursor
        if not mq.TLO.Cursor() then
            addStatus(string.format('\\ar  Failed to pick up "%s" from inventory!', itemName))
            return false
        end

        -- Click the equipment slot to equip it
        mq.cmdf('/itemnotify %s leftmouseup', slotName)
        mq.delay(750)

        -- If something was displaced to cursor, auto-inventory it
        if mq.TLO.Cursor() then
            mq.cmd('/autoinventory')
            mq.delay(500)
        end
    end

    -- Verify it equipped
    mq.delay(500)
    if isEquipped(itemName, slotName) then
        addStatus(string.format('\\ag  Equipped: \\at%s \\axin %s', itemName, slotName))
        return true
    else
        addStatus(string.format('\\ar  Warning: %s may not have equipped into %s - check manually', itemName, slotName))
        return false
    end
end

-- ---------------------------------------------------------------------------
-- Main buy-and-equip routine (runs outside ImGui context)
-- ---------------------------------------------------------------------------
local function doBuyAndEquip()
    isRunning = true
    statusLines = {}
    addStatus('\\ag=== TBM Armor Buy & Equip Started ===')

    -- Zone check
    if mq.TLO.Zone.ShortName() ~= 'potranquility' and not doDebug then
        addStatus('\\ar  Not in Plane of Tranquility! Use \\agDebug \\axmode to test, or go to the zone first.')
        isRunning = false
        return
    end

    -- Pause class plugin
    addStatus('\\ao  Pausing class plugin...')
    mq.cmdf('/squelch /%s pause on', myClass:lower())
    if mq.TLO.Plugin('mq2autoforage').IsLoaded() then
        mq.cmd('/squelch /stopforage')
    end

    local shoppingList = buildShoppingList()

    if #shoppingList == 0 then
        addStatus('\\ar  Nothing selected to buy/equip!')
        isRunning = false
        return
    end

    -- Separate into: needs buying, needs equipping (in bags), already done
    local toBuy   = {}
    local toEquip = {}

    for _, item in ipairs(shoppingList) do
        if isEquipped(item.name, item.slot) then
            addStatus(string.format('\\ag  [SKIP] \\ax%s already equipped in %s', item.name, item.slot))
        elseif isInInventory(item.name) then
            addStatus(string.format('\\ao  [IN BAGS] \\ax%s - will equip to %s', item.name, item.slot))
            table.insert(toEquip, item)
        else
            addStatus(string.format('\\at  [BUY] \\ax%s -> %s', item.name, item.slot))
            table.insert(toBuy, item)
        end
    end

    -- Buy phase
    if #toBuy > 0 then
        addStatus(string.format('\\ag--- Buying %d items ---', #toBuy))
        updateRemnant()
        addStatus(string.format('\\axCurrent Remnants: \\at%d', RoT))

        if doDebug then
            for _, item in ipairs(toBuy) do
                addStatus(string.format('\\agDebug: \\axWould buy \\ao%s \\axfor slot %s', item.name, item.slot))
                mq.delay(300)
            end
        else
            -- Open merchant
            if not openMerchant() then
                addStatus('\\ar  Failed to open merchant! Aborting buy phase.')
                isRunning = false
                return
            end

            for _, item in ipairs(toBuy) do
                if not isRunning then break end
                local success = buyItem(item.name)
                if success then
                    table.insert(toEquip, item)
                else
                    addStatus(string.format('\\ar  Failed to buy %s - skipping', item.name))
                end
                mq.delay(500)
            end

            closeMerchant()
        end
    else
        addStatus('\\ag  No items need buying.')
    end

    -- Equip phase
    if #toEquip > 0 then
        addStatus(string.format('\\ag--- Equipping %d items ---', #toEquip))

        if doDebug then
            for _, item in ipairs(toEquip) do
                addStatus(string.format('\\agDebug: \\axWould equip \\ao%s \\axto %s', item.name, item.slot))
                mq.delay(300)
            end
        else
            for _, item in ipairs(toEquip) do
                if not isRunning then break end
                equipItem(item.name, item.slot)
                mq.delay(500)
            end
        end
    else
        addStatus('\\ag  No items need equipping.')
    end

    -- Resume class plugin
    addStatus('\\ao  Resuming class plugin...')
    mq.cmdf('/squelch /%s pause off', myClass:lower())
    if mq.TLO.Plugin('mq2autoforage').IsLoaded() then
        mq.cmd('/squelch /startforage')
    end

    updateRemnant()
    addStatus(string.format('\\axRemnants remaining: \\at%d', RoT))
    addStatus('\\ag=== TBM Armor Buy & Equip Complete ===')
    isRunning = false
end

-- ---------------------------------------------------------------------------
-- Reclaim alternate currency via the inventory currency tab
-- ---------------------------------------------------------------------------
local function doReclaim()
    local invWindow = mq.TLO.Window('InventoryWindow')

    -- Open inventory window
    addStatus('\\ao  Opening inventory window...')
    if not (invWindow() and invWindow.Open()) then
        invWindow.DoOpen()
        mq.delay(5000, function() return invWindow() and invWindow.Open() end)
        if not (invWindow() and invWindow.Open()) then
            addStatus('\\ar  Failed to open inventory window!')
            return
        end
    end

    -- Switch to the currency tab
    addStatus('\\ao  Switching to currency tab...')
    local tabBox = invWindow.Child('IW_Subwindows')
    if not tabBox or not tabBox() then
        addStatus('\\ar  Could not find inventory tab control!')
        return
    end

    local function getCurrentTabName()
        return tabBox.CurrentTab and tabBox.CurrentTab.Name and tabBox.CurrentTab.Name() or ''
    end

    tabBox.SetCurrentTab(5)
    mq.delay(250)
    if getCurrentTabName() ~= 'IW_AltCurrPage' then
        local tabCount = tabBox.TabCount() or 0
        local found = false
        for i = 1, tabCount do
            if i ~= 5 then
                tabBox.SetCurrentTab(i)
                mq.delay(250)
                if getCurrentTabName() == 'IW_AltCurrPage' then
                    found = true
                    break
                end
            end
        end
        if not found then
            addStatus('\\ar  Could not find alt currency tab!')
            return
        end
    end

    -- Click Reclaim All
    addStatus('\\ao  Clicking Reclaim All...')
    local reclaimAllBtn = invWindow.Child('IW_AltCurr_ReclaimAllButton')
    if not reclaimAllBtn or not reclaimAllBtn() then
        addStatus('\\ar  Reclaim All button not found!')
        return
    end
    reclaimAllBtn.LeftMouseUp()

    mq.delay(500)
    updateRemnant()
    addStatus(string.format('\\ag  Reclaim complete! Remnants of Tranquility: \\at%d', RoT))
end

-- ---------------------------------------------------------------------------
-- Request flags (set by UI, consumed by main loop)
-- ---------------------------------------------------------------------------
local requestCheck     = false
local requestBuyEquip  = false
local requestReclaim   = false

-- ---------------------------------------------------------------------------
-- ImGui drawing
-- ---------------------------------------------------------------------------
local function drawPlayerInfo()
    imgui.Text(string.format('%s  Level: %d %s', myName, myLevel, mq.TLO.Me.Class.Name()))
    imgui.SameLine(350)

    if imgui.Button('Go to Vendor') then
        if mq.TLO.Zone.ShortName() == 'potranquility' then
            mq.cmd('/nav spawn "Lyndalin Delwadamain"')
        else
            mq.cmd('/travelto "potranquility"')
        end
    end

    imgui.SameLine()
    if imgui.Button('Stop Nav') then
        mq.cmd('/nav stop')
    end

    imgui.Text(string.format('Remnants of Tranquility: %d', RoT))
    imgui.SameLine(350)
    doDebug = imgui.Checkbox('Debug', doDebug)
    imgui.SameLine()
    imgui.TextColored(0.5, 0.5, 0.5, 1.0, string.format('Armor Set: %s', armorSet))
end

local function drawVisibleArmor()
    if imgui.CollapsingHeader('Visible Armor (' .. armorSet .. ')', ImGuiTreeNodeFlags.DefaultOpen) then
        imgui.Columns(2, 'viscols', false)
        local half = math.ceil(#visChecks / 2)
        for i, item in ipairs(visChecks) do
            item.checked = imgui.Checkbox(item.slot:upper() .. ': ' .. item.name, item.checked)
            if i == half then
                imgui.NextColumn()
            end
        end
        imgui.Columns(1)

    end
end

local function drawNonVisible()
    if imgui.CollapsingHeader('Non-Visible Gear', ImGuiTreeNodeFlags.DefaultOpen) then
        local bowChecked = isBowChecked()
        for _, slot in ipairs(nonVisSelections) do
            local isRanged  = (slot.slot == 'ranged')
            local forcedOff = isRanged and bowChecked
            if forcedOff then slot.enabled = false end

            -- Enable checkbox (greyed when forced off by bow)
            if forcedOff then imgui.BeginDisabled() end
            slot.enabled = imgui.Checkbox('##en_' .. slot.slot, slot.enabled)
            if forcedOff then imgui.EndDisabled() end
            imgui.SameLine()

            -- Slot label
            imgui.Text(slot.label .. ':')
            imgui.SameLine()

            -- Item dropdown
            local comboDisabled = (not slot.enabled) or forcedOff
            if comboDisabled then imgui.BeginDisabled() end
            local preview = slot.items[slot.selectedIdx + 1] or 'None'
            imgui.SetNextItemWidth(290)
            if imgui.BeginCombo('##nv_' .. slot.slot, preview) then
                for i, itemName in ipairs(slot.items) do
                    local isSelected = (i == slot.selectedIdx + 1)
                    if imgui.Selectable(itemName, isSelected) then
                        slot.selectedIdx = i - 1
                    end
                    if isSelected then imgui.SetItemDefaultFocus() end
                end
                imgui.EndCombo()
            end
            if comboDisabled then imgui.EndDisabled() end

            if forcedOff then
                imgui.SameLine()
                imgui.TextColored(1.0, 0.8, 0.0, 1.0, '(bow fills ranged slot)')
            end
        end
    end
end

local function drawWeapons()
    if imgui.CollapsingHeader('Weapons') then
        if #weaponChecks == 0 then
            imgui.Text('No TBM weapons available for your class.')
        else
            for _, w in ipairs(weaponChecks) do
                w.checked = imgui.Checkbox(w.slot:upper() .. ': ' .. w.name, w.checked)
            end
        end
        imgui.TextColored(1.0, 1.0, 0.0, 1.0, 'Note: Checking Bow will auto-skip Ball of Everliving Golem (both ranged slot).')
    end
end

local function drawStatusLog()
    if imgui.CollapsingHeader('Status Log', ImGuiTreeNodeFlags.DefaultOpen) then
        local availX, availY = imgui.GetContentRegionAvail()
        local childHeight = math.max(120, (availY or 120) - 10)
        if imgui.BeginChild('StatusScroll', availX or -1, childHeight, ImGuiChildFlags.Border) then
            for _, line in ipairs(statusLines) do
                imgui.Text(line:gsub('\\a[a-zA-Z]', ''))
            end
            -- Auto-scroll to bottom
            if imgui.GetScrollY() >= imgui.GetScrollMaxY() - 20 then
                imgui.SetScrollHereY(1.0)
            end
        end
        imgui.EndChild()
    end
end

local function tbmArmorUI(open)
    local main_viewport = imgui.GetMainViewport()
    imgui.SetNextWindowPos(main_viewport.WorkPos.x + 100, main_viewport.WorkPos.y + 100, ImGuiCond.FirstUseEver)
    imgui.SetNextWindowSize(700, 600, ImGuiCond.FirstUseEver)

    local show = false
    open, show = imgui.Begin('TBM Armor Buyer by Joakhan', open)

    if not show then
        imgui.End()
        return open
    end

    imgui.PushItemWidth(imgui.GetFontSize() * -12)

    drawPlayerInfo()
    imgui.Separator()

    drawVisibleArmor()
    drawNonVisible()
    drawWeapons()

    imgui.Separator()

    -- Action buttons
    if isRunning then
        imgui.BeginDisabled()
    end

    if imgui.Button('Check Gear') then
        requestCheck = true
    end
    imgui.SameLine()
    if imgui.Button('Buy & Equip') then
        requestBuyEquip = true
    end
    imgui.SameLine()
    if imgui.Button('Reclaim Currency') then
        requestReclaim = true
    end
    imgui.SameLine()
    if imgui.Button('Select All') then
        for _, item in ipairs(visChecks) do item.checked = true end
        for _, slot in ipairs(nonVisSelections) do slot.enabled = true end
    end
    imgui.SameLine()
    if imgui.Button('Deselect All') then
        for _, item in ipairs(visChecks) do item.checked = false end
        for _, slot in ipairs(nonVisSelections) do slot.enabled = false end
        for _, w in ipairs(weaponChecks) do w.checked = false end
    end

    if isRunning then
        imgui.EndDisabled()
        imgui.SameLine()
        imgui.TextColored(1.0, 1.0, 0.0, 1.0, 'Running...')
    end

    drawStatusLog()

    imgui.PopItemWidth()
    imgui.End()
    return open
end

-- ---------------------------------------------------------------------------
-- Register ImGui and run main loop
-- ---------------------------------------------------------------------------
local openGUI = true

ImGui.Register('TBM Armor Buyer', function()
    openGUI = tbmArmorUI(openGUI)
end)

print(string.format('\\ag[TBM Armor] \\axLoaded for \\at%s \\ax(%s) - Armor set: \\ao%s', myName, myClass, armorSet))

while openGUI do
    mq.doevents()
    mq.delay(500)
    updateRemnant()

    -- Process requests from UI
    if requestCheck then
        requestCheck = false
        doCheck()
    end

    if requestBuyEquip then
        requestBuyEquip = false
        doBuyAndEquip()
    end

    if requestReclaim then
        requestReclaim = false
        doReclaim()
    end
end

print('\\ag[TBM Armor] \\axScript exiting.')
