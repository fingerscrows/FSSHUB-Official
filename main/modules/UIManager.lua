-- [[ FSSHUB: UI MANAGER V8.1 (FULL INTEGRITY) ]] --
-- Status: No logic compression. All features expanded.
-- Path: main/modules/UIManager.lua

local UIManager = {}
print("[FSSHUB DEBUG] UIManager Loaded")

local BaseUrl = getgenv().FSSHUB_DEV_BASE or "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/main/"
local LIB_URL = BaseUrl .. "main/lib/FSSHUB_Lib.lua"

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local StoredConfig = nil
local StoredAuth = nil
local LibraryInstance = nil
local ConfigFolder = "FSSHUB_Settings"

-- Memastikan folder config utama ada
if not isfolder(ConfigFolder) then 
    makefolder(ConfigFolder) 
end

-- [GAME SPECIFIC FOLDER]
-- Membuat folder khusus untuk game ID ini agar config tidak tercampur
local GameFolder = ConfigFolder .. "/" .. tostring(game.GameId)
if not isfolder(GameFolder) then
    makefolder(GameFolder)
end

-- Path untuk file Auto Load
local AutoLoadFile = GameFolder .. "/_autoload.dat"

-- [DATABASE IKON TERPUSAT]
-- Ini memperbaiki masalah icon yang hilang di tab selain dashboard
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

-- [AUTO-LOAD PURGE]
-- Menghapus file auto-load lama saat script dijalankan manual (bukan dari auto-exec)
-- Ini mencegah script menyala sendiri dan stuck saat baru login
if isfile(AutoLoadFile) then
    delfile(AutoLoadFile)
end

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
    
    local Library = LoadLibrary()
    if not Library then 
        game.StarterGui:SetCore("SendNotification", {Title = "Error", Text = "Library failed to load.", Duration = 5})
        return 
    end

    print("[FSSHUB DEBUG] Building Window...")

    local statusIcon = "👤"
    if AuthData then
        if AuthData.Type == "Premium" or AuthData.Type == "Unlimited" then statusIcon = "👑" 
        elseif AuthData.IsDev then statusIcon = "🛠️" end
    end
    
    Library:Watermark("FSSHUB " .. statusIcon)
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))
    
    -- [[ 1. DASHBOARD TAB ]] --
    local ProfileTab = Window:Section("Dashboard", IconLibrary["Dashboard"])
    
    if AuthData then
        -- Announcement Section
        if AuthData.MOTD and AuthData.MOTD ~= "" then 
            ProfileTab:Paragraph("📢 ANNOUNCEMENT", AuthData.MOTD) 
        end
        
        -- Game Info Group
        local GameGroup = ProfileTab:Group("Game Information")
        local modeText = AuthData.IsUniversal and "⚠️ Universal Mode" or "✅ Official Support"
        
        GameGroup:Label("Game Name: " .. (AuthData.GameName or "Unknown"))
        GameGroup:Label("Script Type: " .. modeText)
        
        -- User Info Group
        local UserGroup = ProfileTab:Group("User Information")
        UserGroup:Label("License Type: " .. statusIcon .. " " .. AuthData.Type)
        UserGroup:Label("Access Key: " .. (AuthData.Key and string.sub(AuthData.Key, 1, 12) .. "..." or "Hidden"))
        
        -- Expiry Countdown
        local TimerLabel = UserGroup:Label("Expiry: Syncing...")
        
        task.spawn(function()
            -- Safety check untuk data expiry
            if not AuthData.Expiry or AuthData.Expiry == 0 then 
                TimerLabel.Text = "Expiry: PERMANENT"
                return 
            end
            
            while true do
                local t = os.time()
                local left = AuthData.Expiry - t
                
                -- Cek ambang batas permanent (Tahun 2255+)
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

    -- [[ 2. GAME FEATURES GENERATOR ]] --
    -- Kita simpan referensi item agar bisa diakses oleh Config System
    local ConfigItems = {} 
    
    if GameConfig.Tabs then
        for _, tabData in ipairs(GameConfig.Tabs) do
            -- Icon Resolution: Check database or use raw input
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
                    local b = Tab:Button(element.Title, element.Callback)
                elseif element.Type == "Keybind" then 
                    newItem = Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then 
                    Tab:Label(element.Title)
                end
                
                -- Apply Keybind jika ada di config table
                if newItem and element.Keybind and newItem.SetKeybind then 
                    newItem.SetKeybind(element.Keybind) 
                end
                
                -- Simpan ke ConfigItems jika elemen ini bisa di-set valuenya (Toggle/Slider/Dropdown)
                if newItem and newItem.Set then
                    ConfigItems[element.Title] = newItem
                end
            end
        end
    end
    
    -- [[ 3. SETTINGS TAB ]] --
    local SettingsTab = Window:Section("Settings", IconLibrary["Settings"])
    
    -- Interface Group
    local UI_Group = SettingsTab:Group("Interface Settings")
    
    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do 
        table.insert(themeNames, name) 
    end
    
    UI_Group:Dropdown("Theme", themeNames, "Select Theme", function(selected) 
        Library:SetTheme(selected) 
    end)
    
    UI_Group:Slider("Menu Transparency", 0, 90, 0, function(v) 
        Library:SetTransparency(v/100) 
    end)
    
    UI_Group:Toggle("Show Watermark", true, function(s) 
        Library:ToggleWatermark(s) 
    end)
    
    UI_Group:Dropdown("Watermark Pos", {"Top Right", "Top Left", "Bottom Right", "Bottom Left"}, "Top Right", function(p) 
        if Library.SetWatermarkAlign then 
            Library:SetWatermarkAlign(p) 
        end 
    end)
    
    UI_Group:Keybind("Hide/Show Menu", Enum.KeyCode.RightControl, function()
        if Library.base then 
            local main = Library.base:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)

    -- Config Group (Sistem Baru)
    local Config_Group = SettingsTab:Group("Configuration System (Game Specific)")
    local selectedConfig = "Default"
    local newConfigName = ""
    local ConfigDropdown -- Referensi ke objek dropdown untuk refresh
    
    local function GetConfigs()
        local list = {}
        if isfolder(GameFolder) then
            for _, path in ipairs(listfiles(GameFolder)) do 
                if path:sub(-5) == ".json" then 
                    -- Ambil nama file saja
                    local name = path:match("^.+\\(.+)$") or path:match("^.+/(.+)$")
                    name = name:gsub(".json", "")
                    table.insert(list, name) 
                end 
            end
        end
        if #list == 0 then table.insert(list, "Default") end
        return list
    end
    
    -- Dropdown Config
    ConfigDropdown = Config_Group:Dropdown("Select Config", GetConfigs(), "Default", function(v) 
        selectedConfig = v 
    end)
    
    Config_Group:Button("Refresh List", function()
        -- Fitur Refresh: Update isi dropdown secara manual
        if ConfigDropdown and ConfigDropdown.Refresh then
            local newList = GetConfigs()
            ConfigDropdown.Refresh(newList, selectedConfig)
            Library:Notify("System", "Config list refreshed.", 2)
        end
    end)
    
    Config_Group:Button("Load Config", function()
        local path = GameFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            
            -- Load ke Library Flags (Memory)
            for title, value in pairs(data) do 
                Library.flags[title] = value 
                -- Load ke UI Visual (Slider/Toggle bergerak)
                if ConfigItems[title] then 
                    ConfigItems[title].Set(value) 
                end
            end
            
            -- Refresh visual element jika menggunakan registry (Update warna tema jika ikut tersimpan)
            if Library.themeRegistry then 
                for _, item in ipairs(Library.themeRegistry) do 
                    if item.Type == "Func" then pcall(item.Func) end 
                end 
            end
            
            Library:Notify("Config", "Loaded: " .. selectedConfig, 3)
        else
            Library:Notify("Error", "Config file not found!", 3)
        end
    end)
    
    Config_Group:Button("Save / Overwrite Config", function()
        -- Menyimpan seluruh flags library ke file
        writefile(GameFolder .. "/" .. selectedConfig .. ".json", HttpService:JSONEncode(Library.flags))
        Library:Notify("Config", "Saved: " .. selectedConfig, 3)
    end)
    
    -- Create New Config Section
    Config_Group:Label("Create New Config:")
    Config_Group:TextBox("New Config Name", "", function(val) 
        newConfigName = val 
    end)
    
    Config_Group:Button("Create Config", function()
        if newConfigName == "" then 
            Library:Notify("Error", "Please enter a name first!", 3) 
            return 
        end
        
        writefile(GameFolder .. "/" .. newConfigName .. ".json", HttpService:JSONEncode(Library.flags))
        Library:Notify("Config", "Created: " .. newConfigName, 3)
        
        -- Auto Refresh Dropdown dan pilih config baru
        if ConfigDropdown and ConfigDropdown.Refresh then
            selectedConfig = newConfigName
            local list = GetConfigs()
            ConfigDropdown.Refresh(list, newConfigName)
        end
    end)

    Config_Group:Button("Delete Selected Config", function()
        local path = GameFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) and selectedConfig ~= "Default" then
            delfile(path)
            Library:Notify("Config", "Deleted: " .. selectedConfig, 3)
            
            -- Reset ke Default setelah delete
            selectedConfig = "Default"
            if ConfigDropdown and ConfigDropdown.Refresh then
                local list = GetConfigs()
                ConfigDropdown.Refresh(list, "Default")
            end
        else
            Library:Notify("Error", "Cannot delete Default/Missing", 3)
        end
    end)
    
    -- Auto Load Feature
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
    
    -- 3. Utilities Group
    local Utils_Group = SettingsTab:Group("Utilities")
    
    Utils_Group:Button("Reset All Features", function()
        for title, item in pairs(ConfigItems) do
            -- Matikan semua toggle / reset slider ke min
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
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        if Library.base then Library.base:Destroy() end
    end)
end

return UIManager
