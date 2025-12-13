-- [[ FSSHUB: UI MANAGER V3.5 (SURGEON FIX) ]] --
-- Status: Keybinds Fixed via Force-Cast & Flags Injection.
-- Path: main/modules/UIManager.lua

local UIManager = {}
print("[FSSHUB DEBUG] UIManager V3.5 Loading...")

local BaseUrl = getgenv().FSSHUB_DEV_BASE or "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/main/"
local LIB_URL = BaseUrl .. "main/lib/FSSHUB_Lib.lua"

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local LibraryInstance = nil
local ConfigItems = {} -- Registry: {Object, Type, Default}
local SavedState = {}  -- In-Memory State Cache

-- [[ FILE SYSTEM & PATHS ]] --
local ConfigFolder = "FSSHUB_Settings"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local GameFolder = ConfigFolder .. "/" .. tostring(game.GameId)
if not isfolder(GameFolder) then makefolder(GameFolder) end

local AutoSaveFile = GameFolder .. "/_AutoSave.json"

-- [[ DATABASE IKON TERPUSAT ]] --
local IconLibrary = {
    ["Dashboard"] = "10888331510",
    ["Settings"]  = "10888336262",
    ["Player"]    = "10888334695",
    ["Visuals"]   = "10888333282",
    ["Farming"]   = "10888335919",
    ["Combat"]    = "10888339056",
    ["Support"]   = "10888334234",
    ["Misc"]      = "10888338271",
    ["Teleport"]  = "10888337728"
}

-- [[ 1. SERIALIZATION ENGINE ]] --
local function Serialize(val)
    local t = typeof(val)
    if t == "Color3" then
        return {R = val.R, G = val.G, B = val.B}
    elseif t == "Vector3" then
        return {X = val.X, Y = val.Y, Z = val.Z}
    elseif t == "Vector2" then
        return {X = val.X, Y = val.Y}
    elseif t == "EnumItem" then
        return val.Name -- Force String: "Q"
    end
    return val
end

local function Deserialize(val)
    if type(val) == "table" then
        if val.R and val.G and val.B then
            return Color3.new(val.R, val.G, val.B)
        elseif val.X and val.Y and val.Z then
            return Vector3.new(val.X, val.Y, val.Z)
        elseif val.X and val.Y then
            return Vector2.new(val.X, val.Y)
        end
    end
    return val
end

local function SafeEnum(val)
    if type(val) == "string" then
        if val == "None" then return Enum.KeyCode.Unknown end
        local clean = val:gsub("Enum.KeyCode.", "")
        return Enum.KeyCode[clean] or Enum.KeyCode.Unknown
    end
    return val
end

-- [[ 2. STATE MANAGER ]] --
local function LoadState()
    if not isfile(AutoSaveFile) then return {} end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(AutoSaveFile))
    end)

    if success and data then
        local clean = {}
        for k, v in pairs(data) do
            clean[k] = Deserialize(v)
        end
        return clean
    end
    return {}
end

local function SaveState()
    if not LibraryInstance then return end

    local data = {}
    for key, val in pairs(LibraryInstance.flags) do
        data[key] = Serialize(val)
    end

    local s, err = pcall(function()
        writefile(AutoSaveFile, HttpService:JSONEncode(data))
    end)

    if not s then
        warn("[FSSHUB] Save Failed: " .. tostring(err))
    end
end

-- [[ 3. MAIN BUILDER ]] --
local function LoadLibrary()
    if LibraryInstance then return LibraryInstance end
    local success, lib = pcall(function() return loadstring(game:HttpGet(LIB_URL .. "?t=" .. tostring(math.random(1, 10000))))() end)
    
    if success and lib then
        lib:Init()
        LibraryInstance = lib
        return lib
    end
    return nil
end

function UIManager.Build(GameConfig, AuthData)
    -- A. PRE-LOAD STATE
    SavedState = LoadState()
    
    local Library = LoadLibrary()
    if not Library then return end
    LibraryInstance = Library

    -- [SURGEON] Inject Flags Immediately
    -- This ensures Toggles with "_Bind" suffixes pick up their keybinds automatically
    for k, v in pairs(SavedState) do
        Library.flags[k] = v
    end

    -- Setup Status
    local statusIcon = "👤"
    if AuthData then
        if AuthData.Type == "Premium" or AuthData.Type == "Unlimited" then statusIcon = "👑" 
        elseif AuthData.IsDev then statusIcon = "🛠️" end
    end
    Library:Watermark("FSSHUB " .. statusIcon)
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))

    -- [[ DASHBOARD ]] --
    local ProfileTab = Window:Section("Dashboard", IconLibrary["Dashboard"])
    if AuthData then
        if AuthData.MOTD and AuthData.MOTD ~= "" then ProfileTab:Paragraph("📢 ANNOUNCEMENT", AuthData.MOTD) end
        local GameGroup = ProfileTab:Group("Game Information")
        GameGroup:Label("Game: " .. (AuthData.GameName or "Unknown"))
        
        local UserGroup = ProfileTab:Group("User Information")
        UserGroup:Label("License: " .. statusIcon .. " " .. AuthData.Type)
        
        local TimerLabel = UserGroup:Label("Expiry: Syncing...")
        task.spawn(function()
            if not AuthData.Expiry or AuthData.Expiry == 0 then TimerLabel.Text = "Expiry: PERMANENT"; return end
            while TimerLabel.Parent do
                local left = AuthData.Expiry - os.time()
                if left <= 0 then TimerLabel.Text = "EXPIRED"; break
                elseif AuthData.Expiry > 9000000000 then TimerLabel.Text = "Expiry: PERMANENT"; break end
                local d, h, m, s = math.floor(left/86400), math.floor((left%86400)/3600), math.floor((left%3600)/60), math.floor(left%60)
                TimerLabel.Text = string.format("Expires In: %dd %02dh %02dm %02ds", d, h, m, s)
                task.wait(1)
            end
        end)
    end

    -- [[ GENERATOR LOOP ]] --
    ConfigItems = {}
    if GameConfig.Tabs then
        for _, tabData in ipairs(GameConfig.Tabs) do
            local finalIcon = IconLibrary[tabData.Icon] or tabData.Icon
            local Tab = Window:Section(tabData.Name, finalIcon)
            
            for _, element in ipairs(tabData.Elements) do
                local newItem = nil
                
                -- Values are already injected into Library.flags, so we rely on that mostly.
                -- However, we still pass defaults if needed.
                local savedVal = SavedState[element.Title]
                local effectiveDef = (savedVal ~= nil) and savedVal or element.Default

                if element.Type == "Toggle" then 
                    newItem = Tab:Toggle(element.Title, effectiveDef, element.Callback)

                elseif element.Type == "Slider" then 
                    newItem = Tab:Slider(element.Title, element.Min, element.Max, effectiveDef, element.Callback)
                elseif element.Type == "Dropdown" then 
                    newItem = Tab:Dropdown(element.Title, element.Options, effectiveDef, element.Callback)
                elseif element.Type == "Button" then 
                    Tab:Button(element.Title, element.Callback)
                elseif element.Type == "Keybind" then 
                    -- Pass SafeEnum for constructor compatibility
                    local bindVal = SafeEnum(effectiveDef)
                    newItem = Tab:Keybind(element.Title, bindVal, element.Callback)
                elseif element.Type == "TextBox" then
                    newItem = Tab:TextBox(element.Title, effectiveDef, element.Callback)
                elseif element.Type == "Label" then 
                    Tab:Label(element.Title)
                end
                
                -- Store Metadata
                if newItem then
                    ConfigItems[element.Title] = {
                        Object = newItem,
                        Type = element.Type,
                        Default = element.Default
                    }
                end
            end
        end
    end

    -- [[ SETTINGS TAB ]] --
    local SettingsTab = Window:Section("Settings", IconLibrary["Settings"])
    local UI_Group = SettingsTab:Group("Interface Settings")

    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do table.insert(themeNames, name) end

    local savedTheme = SavedState["Theme"] or "FSS Purple"
    if safePresets[savedTheme] then Library:SetTheme(savedTheme) end
    local themeDrop = UI_Group:Dropdown("Theme", themeNames, savedTheme, function(selected) Library:SetTheme(selected) end)
    ConfigItems["Theme"] = {Object = themeDrop, Type = "Dropdown", Default = "FSS Purple"}

    local savedTrans = SavedState["Menu Transparency"] or 0
    Library:SetTransparency(savedTrans/100)
    local transSlide = UI_Group:Slider("Menu Transparency", 0, 90, savedTrans, function(v) Library:SetTransparency(v/100) end)
    ConfigItems["Menu Transparency"] = {Object = transSlide, Type = "Slider", Default = 0}

    local savedWaterTog = (SavedState["Show Watermark"] ~= nil) and SavedState["Show Watermark"] or true
    Library:ToggleWatermark(savedWaterTog)
    local waterTog = UI_Group:Toggle("Show Watermark", savedWaterTog, function(s) Library:ToggleWatermark(s) end)
    ConfigItems["Show Watermark"] = {Object = waterTog, Type = "Toggle", Default = true}

    local savedPos = SavedState["Watermark Pos"] or "Top Right"
    if Library.SetWatermarkAlign then Library:SetWatermarkAlign(savedPos) end
    local waterPos = UI_Group:Dropdown("Watermark Pos", {"Top Right", "Top Left", "Bottom Right", "Bottom Left"}, savedPos, function(p)
        if Library.SetWatermarkAlign then Library:SetWatermarkAlign(p) end
    end)
    ConfigItems["Watermark Pos"] = {Object = waterPos, Type = "Dropdown", Default = "Top Right"}

    local savedNotif = (SavedState["Show Notifications"] ~= nil) and SavedState["Show Notifications"] or true
    Library.flags["Show Notifications"] = savedNotif
    local notifTog = UI_Group:Toggle("Show Notifications", savedNotif, function(state) Library.flags["Show Notifications"] = state end)
    ConfigItems["Show Notifications"] = {Object = notifTog, Type = "Toggle", Default = true}
    
    UI_Group:Keybind("Hide/Show Menu", Enum.KeyCode.RightControl, function()
        if Library.base then
            local main = Library.base:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)

    -- [[ SURGEON: FORCE-CAST LOADING ]] --
    -- Re-apply Keybinds strictly as Enums to handle any initialization misses
    for title, val in pairs(SavedState) do
        -- Handle Standalone Keybinds
        local itemData = ConfigItems[title]
        if itemData and itemData.Object and itemData.Object.SetKeybind then
            if type(val) == "string" then
                local s, k = pcall(function()
                    local clean = val:gsub("Enum.KeyCode.", "")
                    return Enum.KeyCode[clean]
                end)
                if s and k then
                    itemData.Object.SetKeybind(k)
                end
            end
        end

        -- Note: Toggle Keybinds are handled via Flags Injection + Library Init
    end

    -- Utilities
    local Utils_Group = SettingsTab:Group("Utilities")
    
    Utils_Group:Button("Reset All Features", function()
        for title, itemData in pairs(ConfigItems) do
            local item = itemData.Object
            local def = itemData.Default

            if itemData.Type == "Toggle" then
                if item.Set then item.Set(def or false) end
            elseif itemData.Type == "Slider" then
                if item.Set then item.Set(def or 0) end
            elseif itemData.Type == "Dropdown" then
                if item.Set then item.Set(def) end
            elseif itemData.Type == "TextBox" then
                if item.Set then item.Set(def or "") end
            elseif itemData.Type == "Keybind" then
                if item.SetKeybind then item.SetKeybind(def or Enum.KeyCode.None) end
            end
        end
        Library:Notify("System", "All Features Reset", 2)
    end)

    Utils_Group:Button("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)

    if AuthData and AuthData.IsDev then
         Utils_Group:Button("Open Debug Console", function()
            local dbgUrl = BaseUrl .. "main/modules/Debugger.lua"
            local s, m = pcall(function() return loadstring(game:HttpGet(dbgUrl .. "?t=" .. tostring(math.random(1,10000))))() end)
            if s and m then m.Show() end
        end)
    end

    Utils_Group:Button("Unload Script", function()
        SaveState()
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        if Library.base then Library.base:Destroy() end
    end)

    -- [[ AUTO-SAVE SYSTEM ]] --
    task.spawn(function()
        while Library.base do
            task.wait(60)
            SaveState()
        end
    end)

    pcall(function()
        if game.OnClose then game.OnClose = function() SaveState() end end
        game:BindToClose(function() SaveState() end)
    end)

    if LocalPlayer.OnTeleport then
        LocalPlayer.OnTeleport:Connect(function() SaveState() end)
    end

    task.delay(1, function() Library:Notify("Welcome", "State Restored Successfully", 4) end)
end

return UIManager
