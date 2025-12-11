-- [[ FSSHUB: UI MANAGER V5.14 (EXPIRY DEBUG) ]] --
-- Changelog: Added VERBOSE LOGGING for Expiry System
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

-- [AUTO-LOAD PURGE]
local AutoLoadPath = ConfigFolder .. "/_AutoLoad.json"
if isfile(AutoLoadPath) then
    delfile(AutoLoadPath)
end

local function LoadLibrary()
    if LibraryInstance then return LibraryInstance end
    local success, lib = pcall(function() return loadstring(game:HttpGet(LIB_URL .. "?t=" .. tostring(math.random(1, 10000))))() end)
    
    if success and lib then
        lib:Init()
        LibraryInstance = lib
        return lib
    else
        warn("[FSSHUB] Failed to fetch Library!")
    end
    return nil
end

function UIManager.Build(GameConfig, AuthData)
    print("------------------------------------------------")
    print("[FSS-DEBUG] Building UI Manager...")
    
    StoredConfig = GameConfig
    StoredAuth = AuthData
    
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
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))
    
    task.delay(0.1, function()
        Library:Watermark("FSSHUB " .. statusIcon)
    end)
    
    -- [[ DASHBOARD ]] --
    local ProfileTab = Window:Section("Dashboard", "10888331510")
    if AuthData then
        if AuthData.MOTD and AuthData.MOTD ~= "" then ProfileTab:Paragraph("📢 ANNOUNCEMENT", AuthData.MOTD) end
        
        local statusText = AuthData.IsUniversal and "⚠️ Universal Mode" or "✅ Official Script Supported"
        ProfileTab:Paragraph("Game Info", "Detected: " .. (AuthData.GameName or "Unknown") .. "\nStatus: " .. statusText)
        ProfileTab:Paragraph("User Info", "License: " .. statusIcon .. " " .. AuthData.Type .. "\nKey: " .. (AuthData.Key and string.sub(AuthData.Key, 1, 12) .. "..." or "Hidden"))
        
        local TimerLabel = ProfileTab:Label("Expiry: Syncing...")
        
        -- [[ DEBUGGING EXPIRY ]] --
        task.spawn(function()
            print("[FSS-DEBUG] Starting Expiry Logic...")
            
            -- 1. Cek Apakah AuthData Ada
            if not AuthData then
                print("[FSS-DEBUG] ERROR: AuthData is NIL")
                TimerLabel.Text = "Error: No Auth Data"
                return
            end

            -- 2. Cek Nilai Raw Expiry
            print("[FSS-DEBUG] Raw Expiry Value: ", AuthData.Expiry)
            print("[FSS-DEBUG] Raw Expiry Type: ", type(AuthData.Expiry))

            -- 3. Konversi ke Number (Jaga-jaga jika String)
            local finalExpiry = tonumber(AuthData.Expiry)
            print("[FSS-DEBUG] Converted Expiry: ", finalExpiry)

            if not finalExpiry or finalExpiry == 0 then
                print("[FSS-DEBUG] Expiry is 0 or Invalid. Stopping.")
                TimerLabel.Text = "Expiry: PERMANENT / DEV"
                return
            end

            local PERM_THRESHOLD = 9000000000 

            print("[FSS-DEBUG] Entering Loop. Current Time: ", os.time())

            while true do
                -- Stop loop jika label hancur (ganti tema/unload)
                if not TimerLabel or not TimerLabel.Visible then 
                    print("[FSS-DEBUG] Loop Stopped (Label Gone)")
                    break 
                end

                local currentTime = os.time()
                
                -- Cek Permanent
                if finalExpiry > PERM_THRESHOLD then 
                    TimerLabel.Text = "Expiry: PERMANENT LICENSE"
                    print("[FSS-DEBUG] Detected Permanent License. Loop End.")
                    break 
                end
                
                local timeLeft = finalExpiry - currentTime
                
                -- Log sekali saja jika selisih waktu aneh
                if timeLeft < -999999 then
                     print("[FSS-DEBUG] WEIRD TIME DIFF: " .. timeLeft)
                end

                if timeLeft <= 0 then 
                    TimerLabel.Text = "Status: LICENSE EXPIRED"
                else 
                    local d = math.floor(timeLeft / 86400)
                    local h = math.floor((timeLeft % 86400) / 3600)
                    local m = math.floor((timeLeft % 3600) / 60)
                    local s = math.floor(timeLeft % 60)
                    
                    -- Update Teks
                    pcall(function()
                        TimerLabel.Text = string.format("Expires: %dd %02dh %02dm %02ds", d, h, m, s)
                    end)
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
            local Tab = Window:Section(tabData.Name, tabData.Icon)
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
    local SettingsTab = Window:Section("Settings", "10888332462")
    
    SettingsTab:Label("Interface Configuration")
    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)}, ["Blood Red"] = {Accent = Color3.fromRGB(255, 65, 65)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do table.insert(themeNames, name) end
    
    SettingsTab:Dropdown("Theme", themeNames, "Select Theme", function(selected)
        Library:SetTheme(selected)
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
