MeeyrasLockouts = LibStub("AceAddon-3.0"):NewAddon("Meeyra's Lockout Tracker", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "LibMagicUtil-1.0")
local mod = MeeyrasLockouts
local tooltip

local fmt = string.format


local L        = LibStub("AceLocale-3.0"):GetLocale("MeeyrasLockouts", false)
local QTIP     = LibStub("LibQTip-1.0")
local LDBIcon = LibStub("LibDBIcon-1.0", true)
local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(L["Meeyra's Lockout Tracker"],
        {
            type =  "data source",
            label = L["Meeyra's Lockout Tracker"],
            text = L["Lockouts"],
            icon = [[Interface\Addons\MeeyrasLockoutTracker\keyhole]]
        })


local function c(text, color)
    text = text or ""
    return fmt("|cff%s%s|r", color, text)
end
local gmod = _G.mod
local format = format


function mod:OnProfileChanged(event, newdb)
    mod.gdb = self.db.profile
    self:ApplyProfile()
end

function mod:OnInitialize()
    mod.db = LibStub("AceDB-3.0"):New("MeeyrasLockouts", mod.defaults, "Default")
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    mod.gdb = mod.db.profile
    if LDBIcon then
        LDBIcon:Register("MeeyrasLockouts", ldb, mod.gdb.minimapIcon)
    end
    mod:InitializeConfig()
end

function mod:ApplyProfile(verbose)
    if not self.gdb.minimapIcon.hide then
        LDBIcon:Show("MeeyrasLockouts")
        if verbose then
            print(c("Meeyra's Lockout Tracker:", "ffff00") .." Minimap icon is shown.")
        end
    else
        LDBIcon:Hide("MeeyrasLockouts")
        if verbose then
            print(c("Meeyra's Lockout Tracker:", "ffff00") .." Minimap icon is hidden.")
        end

    end
end


function mod:OnEnable()
end

function mod:OnDisable()
end

function mod:GetDate(delta)
    local dt = date("*t", time()-(delta or 0))
    return dt.year * 10000 + dt.month * 100 + dt.day
end

---------------------------------------------------
-- LDB Display and display utility methods
function formatRemaining(time)
    if time <= 0 then
        return L["Expired"]
    end
    local remain = ""

    local days = floor(time/86400)
    if days > 0 then
        remain = format("%dd", days)
    end
    local hours = floor(gmod(time, 86400)/3600)
    if hours > 0 or strlen(remain) then
        remain = format("%s%s%dh", remain, strlen(remain) > 0 and ", " or "", hours)
    end
    local minutes = floor(gmod(time,3600)/60)
    if minutes > 0 or strlen(remain) > 0 then
        remain = format("%s%s%dm", remain, strlen(remain) > 0 and ", " or "", minutes)
    end
    if strlen(remain) <= 4 then
        local seconds = floor(gmod(time,60))
        remain = format("%s%s%ds", remain, strlen(remain) > 0 and ", " or "", seconds)
    end
    return remain
end

local new, del, newHash, newSet, deepDel
do
    local list = setmetatable({}, {__mode='k'})
    function new(...)
        local t = next(list)
        if t then
            list[t] = nil
            for i = 1, select('#', ...) do
                t[i] = select(i, ...)
            end
            return t
        else
            return { ... }
        end
    end

    function newHash(...)
        local t = next(list)
        if t then
            list[t] = nil
        else
            t = {}
        end
        for i = 1, select('#', ...), 2 do
            t[select(i, ...)] = select(i+1, ...)
        end
        return t
    end

    function del(t)
        if type(t) ~= table then
            return nil
        end
        for k,v in pairs(t) do
            t[k] = nil
        end
        list[t] = true
        return nil
    end

    function deepDel(t)
        if type(t) ~= "table" then
            return nil
        end
        for k,v in pairs(t) do
            t[k] = deepDel(v)
        end
        return del(t)
    end
end

local lockouts = new()

function mod:GenerateLockouts()
    local lockoutKeys =  new()
    deepDel(lockouts)

    for i = 1,1000, 1 do
        local name,id,remaining,_,_,_,_,_,_,size = GetSavedInstanceInfo(i)
        if name == nil then
            break
        end

        local sortname, replaced = gsub(name, "^The ", "")
        if replaced > 0 then
            sortname = sortname .. ", The"
        end

        if not lockouts[size] then
            lockouts[size] = new()
        end

        lockouts[size][#lockouts[size]+1] = newHash(
                "name", name,
                "sortname", sortname,
                "id", id,
                "expired", remaining == 0,
                "remaining", formatRemaining(remaining)
        )
    end

    for n,v in pairs(lockouts) do
        table.insert(lockoutKeys, n)
        table.sort(v, function(a, b) return a.sortname < b.sortname  end)
    end

    table.sort(lockoutKeys)

    return lockoutKeys
end

function ldb.OnEnter(frame)
    tooltip = QTIP:Acquire("MeeyrasLockoutTooltip")
    tooltip:EnableMouse(false)

    tooltip:Clear()

    if frame then
        tooltip:SetAutoHideDelay(0.5, frame)
        tooltip:SmartAnchorTo(frame)
    end

    local haveLockouts = GetSavedInstanceInfo(1) ~= nil
    tooltip:SetColumnLayout(haveLockouts and 4 or 1, "LEFT")
    if not haveLockouts then
        tooltip:SetColumnLayout(1, "LEFT")
        tooltip:SetCell(tooltip:AddLine(), 1, c(L["No current lockouts"], "ffff00"), "LEFT")
        tooltip:Show()
        return
    end
    local y = tooltip:AddHeader()
    tooltip:SetCell(y, 1, c(L["Name"], "ffff00"), "LEFT")
    tooltip:SetCell(y, 2, c(L["Remaining"], "ffff00"), "RIGHT")
    tooltip:SetCell(y, 3, c(L["ID"], "ffff00"), "CENTER")

    tooltip:AddSeparator(1)

    local lockoutKeys = mod:GenerateLockouts()

    for _,key in ipairs(lockoutKeys) do
        tooltip:AddLine()
        y = tooltip:AddLine()
        tooltip:SetCell(y, 1, c(key, "ffff00"), "LEFT")

        for _,lockout in ipairs(lockouts[key]) do
            local col = lockout.expired and "888888" or "ffffff"
            y = tooltip:AddLine()
            tooltip:SetCell(y, 1, c("    "..lockout.sortname, col), "LEFT")
            tooltip:SetCell(y, 2, c(lockout.remaining, col), "RIGHT")
            tooltip:SetCell(y, 3, c(lockout.id, col), "LEFT")
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddSeparator(1)
    y = tooltip:AddLine("")
    tooltip:SetCell(y, 1, c(L["Click:"], "eda55f") .. " "..c(L["Open addon preferences."], "ffd200"), "LEFT", numCols)
    y = tooltip:AddLine("")
    tooltip:SetCell(y, 1, c(L["Alt-Right Click:"], "eda55f").. " "..c(L["Toggle visibility of minimap icon."], "ffd200"), "LEFT", numCols)
    y = tooltip:AddLine("")
    tooltip:SetCell(y, 1, c(L["Alt-Click:"], "eda55f").. " "..c(L["Print lockouts in party or raid chat."], "ffd200"), "LEFT", numCols)


    del(lockoutKeys)
    deepDel(lockouts)
    tooltip:Show()
end

function mod:OptReg(optname, tbl, dispname, cmd)
    if dispname then
        optname = "Meeyra's Lockout Tracker" .. optname
        LibStub("AceConfig-3.0"):RegisterOptionsTable(optname, tbl, cmd)
        if not cmd then
            return LibStub("AceConfigDialog-3.0"):AddToBlizOptions(optname, dispname, "Meeyra's Lockout Tracker")
        end
    else
        LibStub("AceConfig-3.0"):RegisterOptionsTable(optname, tbl, cmd)
        if not cmd then
            return LibStub("AceConfigDialog-3.0"):AddToBlizOptions(optname, "Meeyra's Lockout Tracker")
        end
    end
end

function mod:PrintLockouts()
    local lockoutKeys = mod:GenerateLockouts()
    for _,key in ipairs(lockoutKeys) do
        print(c(key, "ffff00"), ": ")
        for _,lockout in ipairs(lockouts[key]) do
            print("  ", lockout.name, "-", lockout.id, ": ", lockout.remaining)
        end
    end

    del(lockoutKeys)
    deepDel(lockouts)

end

function mod:SendLockoutsToChat()
    if IsInRaid() then
        dest = "RAID"
    elseif GetNumGroupMembers() > 0 then
        dest = "PARTY"
    else
        mod:PrintLockouts()
        return
    end

    local lockoutKeys = mod:GenerateLockouts()
    SendChatMessage(UnitName("player").."'s instance lockouts:", dest)
    for _,key in ipairs(lockoutKeys) do
        for _,lockout in ipairs(lockouts[key]) do
            SendChatMessage("-- "..lockout.name.." ("..key.."), id "..lockout.id, dest)
        end
    end

    del(lockoutKeys)
    deepDel(lockouts)
end

function ldb.OnClick(frame, button)
    if button == "LeftButton" then
        if IsAltKeyDown() then
            mod:SendLockoutsToChat()
        else
            mod:InterfaceOptionsFrame_OpenToCategory(mod.main)
            mod:InterfaceOptionsFrame_OpenToCategory(mod.main)
        end

    elseif button == "RightButton" and IsAltKeyDown()  then
        mod.gdb.minimapIcon.hide = not mod.gdb.minimapIcon.hide
        mod:ApplyProfile(true)
    end

end

function ldb.OnLeave(frame)
    if ldb.tooltip then
        QTIP:Release(ldb.tooltip)
        ldb.tooltip = nil
    end
end
