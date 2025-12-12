-- [[ FSSHUB: UI MANAGER V7.0 (FULL DASHBOARD) ]] --
-- Changelog: Restored Dashboard Script Type & Theme Presets
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

local AutoLoadPath = ConfigFolder .. "/_AutoLoad.json"
if isfile(AutoLoadPath) then delfile(AutoLoadPath) end

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
    if not Library then return end

    local statusIcon = "👤"
    if AuthData then
        if AuthData.Type == "Premium" or AuthData.Type == "Unlimited" then statusIcon = "👑" 
        elseif AuthData.IsDev then statusIcon = "🛠️" end
    end
    
    Library:Watermark("FSSHUB " .. statusIcon)
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))
    
    -- [[ DASHBOARD RESTORED ]] --
    local ProfileTab = Window:Section("Dashboard", IconLibrary["Dashboard"])
    
    if AuthData then
        -- Announcement
        if AuthData.MOTD and AuthData.MOTD ~= "" then 
            ProfileTab:Paragraph("📢 ANNOUNCEMENT", AuthData.MOTD) 
        end
        
        -- Game Information Group
        local GameGroup = ProfileTab:Group("Game Information")
        local modeText = AuthData.IsUniversal and "⚠️ Universal Mode" or "✅ Official Support"
        GameGroup:Label("Game Name: " .. (AuthData.GameName or "Unknown"))
        GameGroup:Label("Script Type: " .. modeText)
        
        -- User Information Group
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
    if GameConfig.Tabs then
        for _, tabData in ipairs(GameConfig.Tabs) do
            local finalIcon = IconLibrary[tabData.Icon] or tabData.Icon
            local Tab = Window:Section(tabData.Name, finalIcon)
            for _, element in ipairs(tabData.Elements) do
                local newItem = nil
                -- Standard Elements (No Group)
                if element.Type == "Toggle" then newItem = Tab:Toggle(element.Title, element.Default, element.Callback)
                elseif element.Type == "Slider" then newItem = Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)
                elseif element.Type == "Dropdown" then newItem = Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
                elseif element.Type == "Button" then local b = Tab:Button(element.Title, element.Callback)
                elseif element.Type == "Keybind" then Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then Tab:Label(element.Title)
                end
                
                if newItem and element.Keybind and newItem.SetKeybind then newItem.SetKeybind(element.Keybind) end
            end
        end
    end
    
    -- [[ SETTINGS TAB (GROUPED RESTORED) ]] --
    local SettingsTab = Window:Section("Settings", IconLibrary["Settings"])
    
    -- Interface Group
    local UI_Group = SettingsTab:Group("Interface Settings")
    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do table.insert(themeNames, name) end
    
    UI_Group:Dropdown("Theme", themeNames, "Select Theme", function(selected) Library:SetTheme(selected) end)
    UI_Group:Slider("Menu Transparency", 0, 90, 0, function(v) Library:SetTransparency(v/100) end)
    UI_Group:Toggle("Show Watermark", true, function(s) Library:ToggleWatermark(s) end)
    UI_Group:Dropdown("Watermark Pos", {"Top Right", "Top Left", "Bottom Right", "Bottom Left"}, "Top Right", function(p) if Library.SetWatermarkAlign then Library:SetWatermarkAlign(p) end end)

    -- Config Group
    local Config_Group = SettingsTab:Group("Configuration System")
    local selectedConfig = "Default"
    local function GetConfigs()
        local list = {}
        for _, path in ipairs(listfiles(ConfigFolder)) do if path:sub(-5) == ".json" then table.insert(list, path:match("^.+/(.+)$"):gsub(".json", "")) end end
        if #list == 0 then table.insert(list, "Default") end
        return list
    end
    
    Config_Group:Dropdown("Select Config", GetConfigs(), "Default", function(v) selectedConfig = v end)
    Config_Group:Button("Load Config", function()
        local path = ConfigFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for title, value in pairs(data) do Library.flags[title] = value end
            if Library.themeRegistry then for _, item in ipairs(Library.themeRegistry) do if item.Type=="Func" then pcall(item.Func) end end end
            Library:Notify("Config", "Loaded", 3)
        end
    end)
    Config_Group:Button("Save Config", function()
        writefile(ConfigFolder .. "/" .. selectedConfig .. ".json", HttpService:JSONEncode(Library.flags))
        Library:Notify("Config", "Saved", 3)
    end)
    
    -- Utils Group
    local Utils_Group = SettingsTab:Group("Utilities")
    Utils_Group:Button("Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    Utils_Group:Button("Unload Script", function()
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        if Library.base then Library.base:Destroy() end
    end)
end

return UIManager
