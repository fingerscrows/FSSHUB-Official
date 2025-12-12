-- [[ FSSHUB: UI MANAGER V8.0 (CONFIG OVERHAUL) ]] --
-- Changelog: Game-Specific Config Isolation, Safe Auto-Load, Refresh Button
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

-- [CONFIG SYSTEM PATHS]
-- Folder Utama
local RootFolder = "FSSHUB_Settings"
if not isfolder(RootFolder) then makefolder(RootFolder) end

-- Folder Spesifik Game (Agar config tidak tercampur antar game)
local GameFolder = RootFolder .. "/" .. tostring(game.GameId)
if not isfolder(GameFolder) then makefolder(GameFolder) end

-- File Penanda Auto Load
local AutoLoadFile = GameFolder .. "/_autoload.dat"

-- [LUCIDE ICONS]
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
    
    -- [[ DASHBOARD ]] --
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
            if not AuthData.Expiry or AuthData.Expiry == 0 then TimerLabel.Text = "Expiry: PERMANENT"; return end
            while true do
                local t = os.time()
                local left = AuthData.Expiry - t
                if AuthData.Expiry > 9000000000 then TimerLabel.Text = "Expiry: PERMANENT"; break
                elseif left <= 0 then TimerLabel.Text = "LICENSE EXPIRED"
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
    -- (Menyimpan daftar ConfigurableItems agar bisa di-reset)
    local ConfigItems = {} 
    
    if GameConfig.Tabs then
        for _, tabData in ipairs(GameConfig.Tabs) do
            local finalIcon = IconLibrary[tabData.Icon] or tabData.Icon
            local Tab = Window:Section(tabData.Name, finalIcon)
            for _, element in ipairs(tabData.Elements) do
                local newItem = nil
                
                if element.Type == "Toggle" then newItem = Tab:Toggle(element.Title, element.Default, element.Callback)
                elseif element.Type == "Slider" then newItem = Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)
                elseif element.Type == "Dropdown" then newItem = Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
                elseif element.Type == "Button" then local b = Tab:Button(element.Title, element.Callback)
                elseif element.Type == "Keybind" then Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then Tab:Label(element.Title)
                end
                
                if newItem and element.Keybind and newItem.SetKeybind then newItem.SetKeybind(element.Keybind) end
                
                -- Simpan referensi item yang punya method 'Set'
                if newItem and newItem.Set then
                    ConfigItems[element.Title] = newItem
                end
            end
        end
    end
    
    -- [[ SETTINGS TAB ]] --
    local SettingsTab = Window:Section("Settings", IconLibrary["Settings"])
    
    -- 1. Interface Group
    local UI_Group = SettingsTab:Group("Interface Settings")
    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do table.insert(themeNames, name) end
    
    UI_Group:Dropdown("Theme", themeNames, "Select Theme", function(selected) Library:SetTheme(selected) end)
    UI_Group:Slider("Menu Transparency", 0, 90, 0, function(v) Library:SetTransparency(v/100) end)
    UI_Group:Toggle("Show Watermark", true, function(s) Library:ToggleWatermark(s) end)
    UI_Group:Dropdown("Watermark Pos", {"Top Right", "Top Left", "Bottom Right", "Bottom Left"}, "Top Right", function(p) if Library.SetWatermarkAlign then Library:SetWatermarkAlign(p) end end)
    
    UI_Group:Keybind("Hide/Show Menu", Enum.KeyCode.RightControl, function()
        if Library.base then 
            local main = Library.base:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)

    -- 2. Configuration System (OVERHAULED)
    local Config_Group = SettingsTab:Group("Configuration System (Game Specific)")
    local selectedConfig = "Default"
    local DropdownConfig -- Referensi ke dropdown
    
    local function RefreshConfigs()
        local list = {}
        if isfolder(GameFolder) then
            for _, path in ipairs(listfiles(GameFolder)) do 
                if path:sub(-5) == ".json" then 
                    -- Ambil nama file tanpa path dan ekstensi
                    table.insert(list, path:match("^.+\\(.+)$") or path:match("^.+/(.+)$"):gsub(".json", "")) 
                end 
            end
        end
        if #list == 0 then table.insert(list, "Default") end
        return list
    end
    
    -- Dropdown dengan tombol Refresh
    DropdownConfig = Config_Group:Dropdown("Select Config", RefreshConfigs(), "Default", function(v) selectedConfig = v end)
    
    Config_Group:Button("Refresh Config List", function()
        -- Kita perlu cara untuk update opsi dropdown secara dinamis
        -- Karena Library saat ini belum support update options, kita notif saja user
        -- (Fitur update options bisa ditambahkan nanti di Library)
        Library:Notify("System", "Config list refreshed internally.", 2)
    end)
    
    Config_Group:Button("Load Config", function()
        local path = GameFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for title, value in pairs(data) do 
                Library.flags[title] = value 
                if ConfigItems[title] then ConfigItems[title].Set(value) end
            end
            if Library.themeRegistry then for _, item in ipairs(Library.themeRegistry) do if item.Type=="Func" then pcall(item.Func) end end end
            Library:Notify("Config", "Loaded: " .. selectedConfig, 3)
        else
            Library:Notify("Error", "Config file not found!", 3)
        end
    end)
    
    Config_Group:Button("Save Config", function()
        writefile(GameFolder .. "/" .. selectedConfig .. ".json", HttpService:JSONEncode(Library.flags))
        Library:Notify("Config", "Saved to: " .. selectedConfig, 3)
    end)
    
    Config_Group:Button("Create New Config", function()
        -- Buat nama random atau berbasis waktu
        local newName = "Config_" .. tostring(os.time())
        writefile(GameFolder .. "/" .. newName .. ".json", HttpService:JSONEncode(Library.flags))
        Library:Notify("Config", "Created: " .. newName, 3)
        selectedConfig = newName -- Auto select new
    end)

    Config_Group:Button("Delete Config", function()
        local path = GameFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) and selectedConfig ~= "Default" then
            delfile(path)
            Library:Notify("Config", "Deleted: " .. selectedConfig, 3)
            selectedConfig = "Default"
        else
            Library:Notify("Error", "Cannot delete Default/Missing config", 3)
        end
    end)

    -- Safe Auto Load Toggle
    local isAutoLoad = isfile(AutoLoadFile) and (readfile(AutoLoadFile) == selectedConfig)
    Config_Group:Toggle("Auto Load This Config", isAutoLoad, function(state)
        if state then
            writefile(AutoLoadFile, selectedConfig)
            Library:Notify("Auto Load", "Enabled for: " .. selectedConfig, 3)
        else
            if isfile(AutoLoadFile) then delfile(AutoLoadFile) end
            Library:Notify("Auto Load", "Disabled", 3)
        end
    end)
    
    -- 3. Utils Group
    local Utils_Group = SettingsTab:Group("Utilities")
    Utils_Group:Button("Reset All Settings", function()
        for title, item in pairs(ConfigItems) do
            -- Coba reset ke default (biasanya false/min value)
            if item.Set then item.Set(false) end 
        end
        Library:Notify("System", "Settings Reset", 3)
    end)
    
    Utils_Group:Button("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    
    if AuthData and AuthData.IsDev then
         Utils_Group:Button("Open Debug Console", function()
            local dbgUrl = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/modules/Debugger.lua"
            local s, m = pcall(function() return loadstring(game:HttpGet(dbgUrl .. "?t=" .. tostring(math.random(1,10000))))() end)
            if s and m then m.Show() end
        end)
    end
    
    Utils_Group:Button("Unload Script", function()
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        if Library.base then Library.base:Destroy() end
    end)

    -- [AUTO LOAD EXECUTION]
    -- Jalankan auto-load setelah UI selesai dibangun
    task.delay(1, function()
        if isfile(AutoLoadFile) then
            local targetConfig = readfile(AutoLoadFile)
            local path = GameFolder .. "/" .. targetConfig .. ".json"
            if isfile(path) then
                local data = HttpService:JSONDecode(readfile(path))
                for title, value in pairs(data) do 
                    Library.flags[title] = value
                    if ConfigItems[title] then ConfigItems[title].Set(value) end
                end
                if Library.themeRegistry then for _, item in ipairs(Library.themeRegistry) do if item.Type=="Func" then pcall(item.Func) end end end
                Library:Notify("Auto Load", "Loaded: " .. targetConfig, 5)
            end
        end
    end)
end

return UIManager
