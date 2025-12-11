-- [[ FSSHUB: UI MANAGER V6.0 (CENTRALIZED ICONS) ]] --
-- Changelog: Added IconLibrary for centralized asset management
-- Path: main/modules/UIManager.lua

local UIManager = {}
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local StoredConfig = nil
local StoredAuth = nil
local LibraryInstance = nil
local ConfigFolder = "FSSHUB_Settings"

if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

-- [DATABASE IKON TERPUSAT]
-- Ganti semua ID ikon di sini saja kedepannya!
local IconLibrary = {
    -- Kategori Umum
    ["Dashboard"] = "10888331510", -- Rumah
    ["Settings"]  = "10888336262", -- Gerigi
    ["Player"]    = "10888334695", -- Orang
    ["Visuals"]   = "10888333282", -- Mata
    
    -- Kategori Game
    ["Farming"]   = "10888335919", -- Daun
    ["Combat"]    = "10888339056", -- Pedang
    ["Support"]   = "10888334234", -- Hati
    ["Misc"]      = "10888338271", -- Tanda Tanya
    ["Teleport"]  = "10888337728", -- Peta/Pin
}

-- [AUTO-LOAD PURGE]
local AutoLoadPath = ConfigFolder .. "/_AutoLoad.json"
if isfile(AutoLoadPath) then
    delfile(AutoLoadPath)
end

local function LoadLibrary()
    if LibraryInstance then return LibraryInstance end
    print("[FSSHUB] Fetching Library from: " .. LIB_URL)
    local success, lib = pcall(function() return loadstring(game:HttpGet(LIB_URL .. "?t=" .. tostring(math.random(1, 10000))))() end)
    if success and lib then
        print("[FSSHUB] Library Fetched Successfully!")
        lib:Init()
        LibraryInstance = lib
        return lib
    else
        warn("[FSSHUB] Failed to fetch Library!")
    end
    return nil
end

function UIManager.Build(GameConfig, AuthData)
    print("[FSSHUB] Building UI for: " .. (GameConfig.Name or "Unknown"))
    
    StoredConfig = GameConfig
    StoredAuth = AuthData
    
    local Library = LoadLibrary()
    if not Library then 
        game.StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Library failed to load. Check console.", Duration = 5})
        return 
    end

    local statusIcon = "👤"
    if AuthData then
        if AuthData.Type == "Premium" or AuthData.Type == "Unlimited" then statusIcon = "👑" 
        elseif AuthData.IsDev then statusIcon = "🛠️" end
    end
    
    Library:Watermark("FSSHUB " .. statusIcon)
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))
    
    -- [[ DASHBOARD ]] --
    -- Panggil ikon menggunakan Nama Kunci dari database di atas
    local ProfileTab = Window:Section("Dashboard", IconLibrary["Dashboard"])
    
    if AuthData then
        if AuthData.MOTD and AuthData.MOTD ~= "" then ProfileTab:Paragraph("📢 ANNOUNCEMENT", AuthData.MOTD) end
        
        local statusText = AuthData.IsUniversal and "⚠️ Universal Mode" or "✅ Official Script Supported"
        ProfileTab:Paragraph("Game Info", "Detected: " .. (AuthData.GameName or "Unknown") .. "\nStatus: " .. statusText)
        ProfileTab:Paragraph("User Info", "License: " .. statusIcon .. " " .. AuthData.Type .. "\nKey: " .. (AuthData.Key and string.sub(AuthData.Key, 1, 12) .. "..." or "Hidden"))
        
        local TimerLabel = ProfileTab:Label("Expiry: Syncing...")
        task.spawn(function()
            if not AuthData.Expiry or AuthData.Expiry == 0 then
                TimerLabel.Text = "Expiry: PERMANENT / DEV"
                return
            end
            while true do
                local t = os.time()
                local left = AuthData.Expiry - t
                if AuthData.Expiry > 9000000000 then 
                    TimerLabel.Text = "Expiry: PERMANENT / DEV"
                    break
                elseif left <= 0 then 
                    TimerLabel.Text = "LICENSE EXPIRED"
                else 
                    local d,h,m = math.floor(left/86400), math.floor((left%86400)/3600), math.floor((left%3600)/60)
                    TimerLabel.Text = string.format("Expires In: %dd %02dh %02dm", d, h, m)
                end
                task.wait(1)
            end
        end)
    end
    ProfileTab:Label("Credits: FingersCrows")

    -- [[ GAME FEATURES GENERATOR ]] --
    local ConfigurableItems = {} 

    if GameConfig.Tabs and type(GameConfig.Tabs) == "table" then
        for _, tabData in ipairs(GameConfig.Tabs) do
            -- [SMART ICON SYSTEM]
            -- Cek apakah nama ikon ada di IconLibrary? Jika ya, pakai ID dari sana.
            -- Jika tidak, pakai ID mentah dari script game.
            local finalIcon = IconLibrary[tabData.Icon] or tabData.Icon
            
            local Tab = Window:Section(tabData.Name, finalIcon)
            for _, element in ipairs(tabData.Elements) do
                local newItem = nil
                if element.Type == "Toggle" then
                    newItem = Tab:Toggle(element.Title, element.Default, element.Callback)
                    if element.Keybind then newItem.SetKeybind(element.Keybind) end
                elseif element.Type == "Slider" then
                    newItem = Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)
                elseif element.Type == "Dropdown" then
                    newItem = Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
                elseif element.Type == "Button" then
                    local b = Tab:Button(element.Title, element.Callback)
                    if element.Keybind then b.SetKeybind(element.Keybind) end
                elseif element.Type == "Keybind" then
                    Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then
                    Tab:Label(element.Title)
                end
                
                if newItem and newItem.Set then
                    ConfigurableItems[element.Title] = newItem
                end
            end
        end
    end
    
    -- [[ SETTINGS TAB ]] --
    local SettingsTab = Window:Section("Settings", IconLibrary["Settings"])
    
    SettingsTab:Label("Interface Configuration")
    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)}, ["Blood Red"] = {Accent = Color3.fromRGB(255, 65, 65)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do table.insert(themeNames, name) end
    
    SettingsTab:Dropdown("Theme", themeNames, "Select Theme", function(selected)
        Library:SetTheme(selected)
    end)

    SettingsTab:Slider("Menu Transparency", 0, 90, 0, function(v)
        Library:SetTransparency(v/100)
    end)

    SettingsTab:Dropdown("Watermark", {"Top Right", "Top Left", "Bottom Right", "Bottom Left"}, "Top Right", function(pos)
        if Library.SetWatermarkAlign then Library:SetWatermarkAlign(pos) end
    end)

    SettingsTab:Toggle("Show FPS & Ping", true, function(state) Library:ToggleWatermark(state) end)

    -- 2. CONFIGURATION SYSTEM
    SettingsTab:Label("Configuration System")
    local selectedConfig = "Default"
    
    local function GetConfigs()
        local list = {}
        for _, path in ipairs(listfiles(ConfigFolder)) do
            if path:sub(-5) == ".json" and not path:find("_AutoLoad") then
                table.insert(list, path:match("^.+/(.+)$"):gsub(".json", ""))
            end
        end
        if #list == 0 then table.insert(list, "Default") end
        return list
    end

    local ConfigDropdown = SettingsTab:Dropdown("Select Config", GetConfigs(), "Default", function(val) selectedConfig = val end)
    
    SettingsTab:Button("Load Config", function()
        local path = ConfigFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for title, value in pairs(data) do
                Library.flags[title] = value 
                if ConfigurableItems[title] then ConfigurableItems[title].Set(value) end
            end
            
            if Library.themeRegistry then 
               for _, item in ipairs(Library.themeRegistry) do if item.Type == "Func" then pcall(item.Func) end end 
            end
            
            Library:Notify("Config", "Loaded: " .. selectedConfig, 3)
        end
    end)

    SettingsTab:Button("Save Config", function()
        local data = Library.flags 
        writefile(ConfigFolder .. "/" .. selectedConfig .. ".json", HttpService:JSONEncode(data))
        Library:Notify("Config", "Saved: " .. selectedConfig, 3)
    end)

    SettingsTab:Button("Create/Overwrite Config", function()
        local name = selectedConfig == "Default" and "Config_" .. tostring(math.random(1000,9999)) or selectedConfig
        local data = Library.flags
        writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        Library:Notify("Config", "Saved as: " .. name, 3)
    end)

    SettingsTab:Button("Delete Config", function()
        local path = ConfigFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) and selectedConfig ~= "Default" then
            delfile(path)
            Library:Notify("Config", "Deleted: " .. selectedConfig, 3)
            selectedConfig = "Default"
        end
    end)

    -- 3. GLOBAL UTILITIES
    SettingsTab:Label("Utilities")
    SettingsTab:Button("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    
    if AuthData and AuthData.IsDev then
        SettingsTab:Button("Open Debug Console", function()
            local dbgUrl = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/modules/Debugger.lua"
            local s, m = pcall(function() return loadstring(game:HttpGet(dbgUrl .. "?t=" .. tostring(math.random(1,10000))))() end)
            if s and m then m.Show() end
        end)
    end

    SettingsTab:Keybind("Toggle UI Keybind", Enum.KeyCode.RightControl, function()
        if Library.base then 
            local main = Library.base:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)
    
    SettingsTab:Button("Unload Script", function()
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        game.StarterGui:SetCore("SendNotification", {Title = "System", Text = "Script Unloaded", Duration = 3})
        if Library.base then 
            if typeof(Library.base) == "Instance" then Library.base:Destroy() end 
            Library.base = nil 
            LibraryInstance = nil
        end
    end)
end

return UIManager
