-- [[ FSSHUB: UI MANAGER V5.0 (CONFIG & PERSISTENCE) ]] --
-- Changelog: Config System (Save/Load/Auto), Persistence (QueueOnTeleport)

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

-- Ensure Config Folder Exists
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

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
    StoredConfig = GameConfig
    StoredAuth = AuthData
    
    local Library = LoadLibrary()
    if not Library then warn("FSSHUB: Library Failed to Load") return end

    -- [PERSISTENCE LOGIC]
    -- Script ini akan otomatis dieksekusi ulang saat pindah server
    if syn and syn.queue_on_teleport then
        syn.queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/src/loader.lua"))()')
    elseif queue_on_teleport then
        queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/src/loader.lua"))()')
    end

    local statusIcon = "👤"
    if AuthData then
        if AuthData.Type == "Premium" or AuthData.Type == "Unlimited" then statusIcon = "👑" 
        elseif AuthData.IsDev then statusIcon = "🛠️" end
    end
    
    Library:Watermark("FSSHUB " .. statusIcon)
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))
    
    -- [[ DASHBOARD ]] --
    local ProfileTab = Window:Section("Dashboard", "10888331510")
    if AuthData then
        if AuthData.MOTD and AuthData.MOTD ~= "" then ProfileTab:Paragraph("📢 ANNOUNCEMENT", AuthData.MOTD) end
        local statusText = AuthData.IsUniversal and "⚠️ Universal Mode" or "✅ Official Script Supported"
        ProfileTab:Paragraph("Game Info", "Detected: " .. (AuthData.GameName or "Unknown") .. "\nStatus: " .. statusText)
        ProfileTab:Paragraph("User Info", "License: " .. statusIcon .. " " .. AuthData.Type .. "\nKey: " .. (AuthData.Key and string.sub(AuthData.Key, 1, 12) .. "..." or "Hidden"))
        local TimerLabel = ProfileTab:Label("Expiry: Syncing...")
        task.spawn(function()
            while true do
                local t = os.time(); local left = AuthData.Expiry - t
                if AuthData.Expiry > 9000000000 then TimerLabel.Text = "Expiry: PERMANENT / DEV"; break
                elseif left > 0 then local d,h,m = math.floor(left/86400), math.floor((left%86400)/3600), math.floor((left%3600)/60); TimerLabel.Text = string.format("Expires In: %dd %02dh %02dm", d, h, m)
                else TimerLabel.Text = "LICENSE EXPIRED" end
                task.wait(1)
            end
        end)
    end
    ProfileTab:Label("Credits: FingersCrows")

    -- [[ GAME FEATURES GENERATOR ]] --
    -- Kita simpan referensi elemen UI ke dalam tabel agar bisa di-load nanti
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
                
                -- Simpan referensi jika elemen tersebut memiliki method :Set()
                if newItem and newItem.Set then
                    ConfigurableItems[element.Title] = newItem
                end
            end
        end
    end
    
    -- [[ SETTINGS & CONFIG ]] --
    local SettingsTab = Window:Section("Settings", "10888332462")
    
    -- Config System
    SettingsTab:Label("Configuration System")
    local selectedConfig = "Default"
    local configList = listfiles(ConfigFolder)
    local configNames = {}
    
    for _, path in ipairs(configList) do
        local name = path:match("^.+/(.+)$"):gsub(".json", "")
        table.insert(configNames, name)
    end
    if #configNames == 0 then table.insert(configNames, "Default") end

    local DropdownConfig = SettingsTab:Dropdown("Select Config", configNames, "Default", function(val) selectedConfig = val end)
    
    SettingsTab:Button("Refresh Config List", function()
        local newNames = {}
        for _, path in ipairs(listfiles(ConfigFolder)) do
            local name = path:match("^.+/(.+)$"):gsub(".json", "")
            table.insert(newNames, name)
        end
        if #newNames == 0 then table.insert(newNames, "Default") end
        -- NOTE: Library perlu fitur update dropdown, tapi untuk sekarang restart UI adalah opsi termudah
        -- Atau kita bisa sekadar notif bahwa list sudah refresh di internal
        Library:Notify("Config", "List Refreshed (Reopen Menu)", 2)
    end)

    SettingsTab:Button("Load Config", function()
        local path = ConfigFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for title, value in pairs(data) do
                if ConfigurableItems[title] then
                    ConfigurableItems[title].Set(value)
                end
            end
            Library:Notify("Config", "Loaded: " .. selectedConfig, 3)
        else
            Library:Notify("Error", "Config Not Found", 3)
        end
    end)

    SettingsTab:Button("Save Config", function()
        local data = {}
        -- Ambil data dari library.flags yang otomatis terupdate
        for title, _ in pairs(ConfigurableItems) do
            data[title] = Library.flags[title]
        end
        writefile(ConfigFolder .. "/" .. selectedConfig .. ".json", HttpService:JSONEncode(data))
        Library:Notify("Config", "Saved: " .. selectedConfig, 3)
    end)

    SettingsTab:Button("Create New Config", function()
        -- Karena tidak ada TextBox input di Library versi ini, kita pakai input prompt sederhana atau nama random
        local name = "Config_" .. tostring(math.random(1000,9999))
        selectedConfig = name
        local data = {}
        for title, _ in pairs(ConfigurableItems) do data[title] = Library.flags[title] end
        writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        Library:Notify("Config", "Created: " .. name, 3)
    end)

    SettingsTab:Button("Delete Config", function()
        local path = ConfigFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) then
            delfile(path)
            Library:Notify("Config", "Deleted: " .. selectedConfig, 3)
            selectedConfig = "Default"
        end
    end)

    -- Auto Load Logic
    local AutoLoadPath = ConfigFolder .. "/_AutoLoad.json"
    local autoLoadState = false
    if isfile(AutoLoadPath) then
        local alData = HttpService:JSONDecode(readfile(AutoLoadPath))
        if alData.GameId == game.GameId and alData.Enabled then
            autoLoadState = true
            -- Auto load the config specified
            if isfile(ConfigFolder .. "/" .. alData.Config .. ".json") then
                task.spawn(function()
                    task.wait(1) -- Tunggu UI stabil
                    local data = HttpService:JSONDecode(readfile(ConfigFolder .. "/" .. alData.Config .. ".json"))
                    for title, value in pairs(data) do
                        if ConfigurableItems[title] then ConfigurableItems[title].Set(value) end
                    end
                    Library:Notify("AutoLoad", "Config Loaded", 3)
                end)
            end
        end
    end

    SettingsTab:Toggle("Auto Load This Game", autoLoadState, function(state)
        local data = {
            GameId = game.GameId,
            Config = selectedConfig,
            Enabled = state
        }
        writefile(AutoLoadPath, HttpService:JSONEncode(data))
    end)

    -- Standard Settings
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
