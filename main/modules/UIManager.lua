-- [[ FSSHUB: UI MANAGER V2.2 (FINAL POLISH) ]] --
-- Status: All Features Restored. Keybind Logic Perfected.
-- Path: main/modules/UIManager.lua

local UIManager = {}
print("[FSSHUB DEBUG] UIManager V2.2 Loading...")

local BaseUrl = getgenv().FSSHUB_DEV_BASE or "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/main/"
local LIB_URL = BaseUrl .. "main/lib/FSSHUB_Lib.lua"

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local StoredConfig = nil
local StoredAuth = nil
local LibraryInstance = nil
local ConfigItems = {} -- Global registry for UI elements
local ActiveConfig = "Default" -- Tracks currently loaded config

-- [[ FILE SYSTEM SETUP ]] --
local ConfigFolder = "FSSHUB_Settings"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local GameFolder = ConfigFolder .. "/" .. tostring(game.GameId)
if not isfolder(GameFolder) then makefolder(GameFolder) end

local LastUsedFile = GameFolder .. "/_last_used.dat"

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

-- [[ UNIVERSAL SERIALIZER ]] --
local function Serialize(val)
    local t = typeof(val)
    if t == "Color3" then
        return {R = val.R, G = val.G, B = val.B}
    elseif t == "Vector3" then
        return {X = val.X, Y = val.Y, Z = val.Z}
    elseif t == "Vector2" then
        return {X = val.X, Y = val.Y}
    elseif t == "EnumItem" then
        return val.Name -- Stores "Q"
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

-- [[ INTERNAL CONFIG SYSTEM ]] --
local function SaveConfigInternal()
    if not LibraryInstance then return end

    local data = {}
    for key, val in pairs(LibraryInstance.flags) do
        data[key] = Serialize(val)
    end

    local success, err = pcall(function()
        writefile(GameFolder .. "/" .. ActiveConfig .. ".json", HttpService:JSONEncode(data))
        writefile(LastUsedFile, ActiveConfig) -- Update last used
    end)

    if success then
        print("[FSSHUB Config] Auto-Saved: " .. ActiveConfig)
    else
        warn("[FSSHUB Config] Save Failed: " .. tostring(err))
    end
end

local function LoadConfigInternal(configName)
    if not LibraryInstance then return end

    local path = GameFolder .. "/" .. configName .. ".json"
    if not isfile(path) then
        warn("[FSSHUB Config] File not found: " .. configName)
        return
    end

    local success, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)

    if not success or not decoded then
        warn("[FSSHUB Config] Decode Failed for: " .. configName)
        return
    end

    ActiveConfig = configName
    writefile(LastUsedFile, ActiveConfig) -- Update last used

    for key, rawVal in pairs(decoded) do
        local val = Deserialize(rawVal)

        -- Logic Upgrade: Handle Keybind Suffix
        local actualKey = key
        local isSuffixKeybind = false

        if string.sub(key, -8) == "_Keybind" then
             actualKey = string.sub(key, 1, -9) -- Strip "_Keybind"
             isSuffixKeybind = true
        end

        local item = ConfigItems[actualKey] or ConfigItems[key] -- Fallback

        if item then
            -- Determine if this is a keybind operation
            -- 1. Suffix detected (attached to toggle)
            -- 2. Item has SetKeybind but NO Set (standalone keybind)
            local useKeybindMethod = isSuffixKeybind or (item.SetKeybind and not item.Set)

            if useKeybindMethod then
                -- Ensure val is Enum
                if type(val) == "string" then
                     -- Handle "None"
                    if val == "None" then
                        val = Enum.KeyCode.Unknown
                    elseif Enum.KeyCode[val] then
                        val = Enum.KeyCode[val]
                    end
                end

                if item.SetKeybind then item.SetKeybind(val) end
            elseif item.Set then
                -- Standard element
                item.Set(val)
            end
        end
    end

    -- Refresh Theme (Explicit Trigger)
    if LibraryInstance.themeRegistry then
        for _, item in ipairs(LibraryInstance.themeRegistry) do
            if item.Type == "Func" then pcall(item.Func) end
        end
    end

    if LibraryInstance.Notify then
        LibraryInstance:Notify("Config System", "Loaded: " .. configName, 3)
    end
end

-- [[ MAIN BUILDER ]] --
local function LoadLibrary()
    if LibraryInstance then return LibraryInstance end
    local success, lib = pcall(function() return loadstring(game:HttpGet(LIB_URL .. "?t=" .. tostring(math.random(1, 10000))))() end)
    
    if success and lib then
        lib:Init()
        LibraryInstance = lib
        return lib
    else
        print("[FSSHUB DEBUG] LoadLibrary Failed: " .. tostring(lib))
    end
    return nil
end

function UIManager.Build(GameConfig, AuthData)
    StoredConfig = GameConfig
    StoredAuth = AuthData
    ConfigItems = {} -- Reset items
    
    local Library = LoadLibrary()
    if not Library then 
        game.StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Library failed to load.", Duration = 5})
        return 
    end

    local statusIcon = "👤"
    if AuthData then
        if AuthData.Type == "Premium" or AuthData.Type == "Unlimited" then statusIcon = "👑" 
        elseif AuthData.IsDev then statusIcon = "🛠️" end
    end
    
    Library:Watermark("FSSHUB " .. statusIcon)
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))
    
    -- [[ 1. DASHBOARD ]] --
    local ProfileTab = Window:Section("Dashboard", IconLibrary["Dashboard"])
    
    if AuthData then
        if AuthData.MOTD and AuthData.MOTD ~= "" then 
            ProfileTab:Paragraph("📢 ANNOUNCEMENT", AuthData.MOTD) 
        end
        
        local GameGroup = ProfileTab:Group("Game Information")
        local modeText = AuthData.IsUniversal and "⚠️ Universal Mode" or "✅ Official Support"
        GameGroup:Label("Game Name: " .. (AuthData.GameName or "Unknown"))
        GameGroup:Label("Script Type: " .. modeText)
        
        local UserGroup = ProfileTab:Group("User Information")
        UserGroup:Label("License Type: " .. statusIcon .. " " .. AuthData.Type)
        UserGroup:Label("Access Key: " .. (AuthData.Key and string.sub(AuthData.Key, 1, 12) .. "..." or "Hidden"))
        
        local TimerLabel = UserGroup:Label("Expiry: Syncing...")
        task.spawn(function()
            if not AuthData.Expiry or AuthData.Expiry == 0 then 
                TimerLabel.Text = "Expiry: PERMANENT"
                return 
            end
            while TimerLabel.Parent do
                local t = os.time()
                local left = AuthData.Expiry - t
                if AuthData.Expiry > 9000000000 then 
                    TimerLabel.Text = "Expiry: PERMANENT"
                    break
                elseif left <= 0 then 
                    TimerLabel.Text = "LICENSE EXPIRED"
                else 
                    local d = math.floor(left / 86400)
                    local h = math.floor((left % 86400) / 3600)
                    local m = math.floor((left % 3600) / 60)
                    local s = math.floor(left % 60)
                    TimerLabel.Text = string.format("Expires In: %dd %02dh %02dm %02ds", d, h, m, s)
                end
                task.wait(1)
            end
        end)
    end
    ProfileTab:Label("Credits: FingersCrows")

    -- [[ 2. GENERATOR LOOP ]] --
    if GameConfig.Tabs then
        for _, tabData in ipairs(GameConfig.Tabs) do
            local finalIcon = IconLibrary[tabData.Icon] or tabData.Icon
            local Tab = Window:Section(tabData.Name, finalIcon)
            
            for _, element in ipairs(tabData.Elements) do
                local newItem = nil
                
                if element.Type == "Toggle" then 
                    newItem = Tab:Toggle(element.Title, element.Default, element.Callback)
                elseif element.Type == "Slider" then 
                    newItem = Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)
                elseif element.Type == "Dropdown" then 
                    newItem = Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
                elseif element.Type == "Button" then 
                    Tab:Button(element.Title, element.Callback)
                elseif element.Type == "Keybind" then 
                    newItem = Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "TextBox" then
                    newItem = Tab:TextBox(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then 
                    Tab:Label(element.Title)
                end
                
                -- Capture Item for System
                if newItem then
                    ConfigItems[element.Title] = newItem

                    -- Initial Keybind Setup
                    if element.Type == "Keybind" and element.Keybind and newItem.SetKeybind then
                        newItem.SetKeybind(element.Keybind)
                    end
                end
            end
        end
    end
    
    -- [[ 3. SETTINGS & CONFIG ]] --
    local SettingsTab = Window:Section("Settings", IconLibrary["Settings"])
    
    local Config_Group = SettingsTab:Group("Configuration System V2.0")
    
    local function GetConfigList()
        local list = {}
        if isfolder(GameFolder) then
            for _, path in ipairs(listfiles(GameFolder)) do 
                if path:sub(-5) == ".json" then 
                    local name = path:match("^.+\\(.+)$") or path:match("^.+/(.+)$")
                    name = name:gsub(".json", "")
                    table.insert(list, name) 
                end 
            end
        end
        if #list == 0 then table.insert(list, "Default") end
        return list
    end

    local ConfigDropdown
    ConfigDropdown = Config_Group:Dropdown("Select Config", GetConfigList(), ActiveConfig, function(val)
        ActiveConfig = val
    end)
    
    Config_Group:Button("Load Selected", function()
        LoadConfigInternal(ActiveConfig)
    end)
    
    Config_Group:Button("Save Selected", function()
        SaveConfigInternal()
        Library:Notify("Config", "Saved: " .. ActiveConfig, 2)
    end)
    
    Config_Group:Label("Create New:")
    local newConfigName = ""
    Config_Group:TextBox("Config Name", "", function(val) newConfigName = val end)
    
    Config_Group:Button("Create & Save", function()
        if newConfigName == "" then return end
        ActiveConfig = newConfigName
        SaveConfigInternal() -- Save immediately

        -- Refresh UI
        if ConfigDropdown and ConfigDropdown.Refresh then
            ConfigDropdown.Refresh(GetConfigList(), ActiveConfig)
        end
        Library:Notify("Config", "Created: " .. ActiveConfig, 2)
    end)
    
    Config_Group:Button("Delete Selected", function()
        if ActiveConfig == "Default" then
            Library:Notify("Error", "Cannot delete Default", 2)
            return 
        end
        
        local path = GameFolder .. "/" .. ActiveConfig .. ".json"
        if isfile(path) then delfile(path) end
        
        ActiveConfig = "Default"
        if ConfigDropdown and ConfigDropdown.Refresh then
            ConfigDropdown.Refresh(GetConfigList(), ActiveConfig)
        end
        Library:Notify("Config", "Deleted", 2)
    end)

    -- Interface Settings
    local UI_Group = SettingsTab:Group("Interface Settings")

    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do table.insert(themeNames, name) end

    local themeDrop = UI_Group:Dropdown("Theme", themeNames, "FSS Purple", function(selected)
        Library:SetTheme(selected)
    end)
    ConfigItems["Theme"] = themeDrop

    local transSlider = UI_Group:Slider("Menu Transparency", 0, 90, 0, function(v)
        Library:SetTransparency(v/100)
    end)
    ConfigItems["Menu Transparency"] = transSlider

    local waterTog = UI_Group:Toggle("Show Watermark", true, function(s) Library:ToggleWatermark(s) end)
    ConfigItems["Show Watermark"] = waterTog

    local waterPos = UI_Group:Dropdown("Watermark Pos", {"Top Right", "Top Left", "Bottom Right", "Bottom Left"}, "Top Right", function(p)
        if Library.SetWatermarkAlign then
            Library:SetWatermarkAlign(p)
        end
    end)
    ConfigItems["Watermark Pos"] = waterPos -- [RESTORED]

    local notifTog = UI_Group:Toggle("Show Notifications", true, function(state)
        Library.flags["Show Notifications"] = state
    end)
    ConfigItems["Show Notifications"] = notifTog
    
    UI_Group:Keybind("Hide/Show Menu", Enum.KeyCode.RightControl, function()
        if Library.base then
            local main = Library.base:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)
    
    -- Utilities
    local Utils_Group = SettingsTab:Group("Utilities")
    
    Utils_Group:Button("Reset All Features", function()
        for title, item in pairs(ConfigItems) do
            if item.Set then item.Set(false) end
        end
        Library:Notify("System", "All settings reset to default", 3)
    end)

    Utils_Group:Button("Rejoin Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)

    if AuthData and AuthData.IsDev then
         Utils_Group:Button("Open Debug Console", function()
            local dbgUrl = BaseUrl .. "main/modules/Debugger.lua"
            local s, m = pcall(function() return loadstring(game:HttpGet(dbgUrl .. "?t=" .. tostring(math.random(1,10000))))() end)
            if s and m then m.Show() end
        end)
    end

    Utils_Group:Button("Unload Script", function()
        SaveConfigInternal() -- Auto Save on exit
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        if Library.base then Library.base:Destroy() end
    end)

    -- [[ AUTO-PILOT LOGIC ]] --

    -- 1. Auto Load on Startup
    if isfile(LastUsedFile) then
        local last = readfile(LastUsedFile)
        if isfile(GameFolder .. "/" .. last .. ".json") then
            ActiveConfig = last
            task.delay(0.5, function() LoadConfigInternal(ActiveConfig) end)
        end
    else
        -- If no last used, try Default if exists, otherwise it stays Default
        if isfile(GameFolder .. "/Default.json") then
            task.delay(0.5, function() LoadConfigInternal("Default") end)
        end
    end

    -- 2. Auto Save on Game Close
    game:BindToClose(function()
        SaveConfigInternal()
    end)

    -- Welcome
    task.delay(1, function()
        Library:Notify("Welcome", "Script loaded. Config: " .. ActiveConfig, 5)
    end)
end

return UIManager
