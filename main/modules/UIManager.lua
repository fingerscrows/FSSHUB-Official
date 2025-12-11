-- [[ FSSHUB: UI MANAGER V5.10 (DEBUG MODE) ]] --
-- Path: main/modules/UIManager.lua

local UIManager = {}
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"

local function Log(msg)
    print("[FSS-DEBUG] [UIManager] " .. tostring(msg))
end

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local StoredConfig = nil
local StoredAuth = nil
local LibraryInstance = nil
local ConfigFolder = "FSSHUB_Settings"

if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

-- AUTO-LOAD PURGE
local AutoLoadPath = ConfigFolder .. "/_AutoLoad.json"
if isfile(AutoLoadPath) then
    delfile(AutoLoadPath)
    Log("Purged Auto-Load config.")
end

local function LoadLibrary()
    if LibraryInstance then return LibraryInstance end
    Log("Fetching Library...")
    local success, lib = pcall(function() return loadstring(game:HttpGet(LIB_URL .. "?t=" .. tostring(math.random(1, 10000))))() end)
    
    if success and lib then
        Log("Library fetched. Initializing...")
        lib:Init()
        LibraryInstance = lib
        return lib
    else
        Log("Failed to fetch Library!")
    end
    return nil
end

function UIManager.Build(GameConfig, AuthData)
    Log("Build called for: " .. tostring(GameConfig.Name))
    
    StoredConfig = GameConfig
    StoredAuth = AuthData
    
    local Library = LoadLibrary()
    if not Library then 
        Log("Library is nil, aborting build.")
        return 
    end

    local statusIcon = "👤"
    if AuthData then
        if AuthData.Type == "Premium" or AuthData.Type == "Unlimited" then statusIcon = "👑" 
        elseif AuthData.IsDev then statusIcon = "🛠️" end
    end
    
    Library:Watermark("FSSHUB " .. statusIcon)
    
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name or "Script"))
    Log("Window Created.")
    
    -- DASHBOARD
    local ProfileTab = Window:Section("Dashboard", "10888331510")
    ProfileTab:Label("Status: Active")
    if AuthData then
        ProfileTab:Paragraph("User Info", "Key: " .. (AuthData.Key and string.sub(AuthData.Key, 1, 5).."..." or "Hidden"))
    end
    
    -- TABS GENERATOR
    Log("Generating Game Tabs...")
    local ConfigurableItems = {} 

    if GameConfig.Tabs and type(GameConfig.Tabs) == "table" then
        Log("Found " .. #GameConfig.Tabs .. " tabs in config.")
        for i, tabData in ipairs(GameConfig.Tabs) do
            Log("Building Tab " .. i .. ": " .. tostring(tabData.Name))
            local Tab = Window:Section(tabData.Name, tabData.Icon)
            
            if tabData.Elements then
                for _, element in ipairs(tabData.Elements) do
                    -- Log("Adding Element: " .. tostring(element.Title)) -- Uncomment for ultra-verbose
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
    else
        Log("WARNING: GameConfig.Tabs is missing or not a table!")
    end
    
    -- SETTINGS TAB
    local SettingsTab = Window:Section("Settings", "10888332462")
    SettingsTab:Label("Interface Configuration")
    
    local safePresets = Library.presets or { ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)} }
    local themeNames = {}
    for name, _ in pairs(safePresets) do table.insert(themeNames, name) end
    
    SettingsTab:Dropdown("Theme", themeNames, "Select Theme", function(selected)
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        Library:SetTheme(selected)
        if Library.base then Library.base:Destroy(); Library.base = nil end 
        Library.keybinds = {} 
        UIManager.Build(StoredConfig, StoredAuth)
    end)

    SettingsTab:Button("Unload Script", function()
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        if Library.base then Library.base:Destroy(); Library.base = nil; LibraryInstance = nil end
    end)
    
    Log("Build Complete.")
end

return UIManager
