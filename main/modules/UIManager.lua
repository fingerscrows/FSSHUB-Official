-- [[ FSSHUB: UI MANAGER V8.2 (EVOLUTION) ]] --
-- Status: Config System Robustness + Clipboard Sharing
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
local GameFolder = ConfigFolder .. "/" .. tostring(game.GameId)
if not isfolder(GameFolder) then
    makefolder(GameFolder)
end

-- Path untuk file Auto Load
local AutoLoadFile = GameFolder .. "/_autoload.dat"

-- [DATABASE IKON TERPUSAT]
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

-- [HELPER: BASE64 ENCODER/DECODER]
local Base64 = {}
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function Base64.Encode(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
function Base64.Decode(data)
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',b64chars:find(x)-1
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- [HELPER: DATA SERIALIZER]
-- Menangani tipe data Roblox (Color3, EnumItem) yang tidak support JSON
local function Serialize(tbl)
    local output = {}
    for k, v in pairs(tbl) do
        if typeof(v) == "Color3" then
            output[k] = { __type = "Color3", R = v.R, G = v.G, B = v.B }
        elseif typeof(v) == "EnumItem" then
            output[k] = { __type = "Enum", EnumType = tostring(v.EnumType), Name = v.Name }
        elseif typeof(v) == "table" then
            output[k] = Serialize(v)
        else
            output[k] = v
        end
    end
    return output
end

local function Deserialize(tbl)
    local output = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" and v.__type then
            if v.__type == "Color3" then
                output[k] = Color3.new(v.R, v.G, v.B)
            elseif v.__type == "Enum" then
                -- Parse EnumType (e.g., "Enum.KeyCode" -> Enum.KeyCode)
                local enumTypeStr = tostring(v.EnumType)
                local mainEnum = Enum

                -- Simple clean logic to find the Enum container
                local parts = {}
                for part in string.gmatch(enumTypeStr, "[^%.]+") do
                    table.insert(parts, part)
                end

                -- Usually it's "Enum.KeyCode" or just "KeyCode"
                local targetEnum = Enum
                if parts[1] == "Enum" and parts[2] then
                    targetEnum = Enum[parts[2]]
                elseif parts[1] then
                    pcall(function() targetEnum = Enum[parts[1]] end)
                end

                if targetEnum then
                    pcall(function() output[k] = targetEnum[v.Name] end)
                end
            end
        elseif type(v) == "table" then
            output[k] = Deserialize(v)
        else
            output[k] = v
        end
    end
    return output
end

-- [AUTO-LOAD PURGE]
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
            
            while true do
                if not TimerLabel.Parent then break end
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

    -- [[ 2. GAME FEATURES GENERATOR ]] --
    local ConfigItems = {} 
    
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
                    local b = Tab:Button(element.Title, element.Callback)
                elseif element.Type == "Keybind" then 
                    Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then 
                    Tab:Label(element.Title)
                end
                
                if newItem and element.Keybind and newItem.SetKeybind then 
                    newItem.SetKeybind(element.Keybind) 
                end
                
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

    UI_Group:Toggle("Show Notifications", true, function(state)
        Library.flags["Show Notifications"] = state
    end)
    
    UI_Group:Keybind("Hide/Show Menu", Enum.KeyCode.RightControl, function()
        if Library.base then 
            local main = Library.base:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)

    -- [[ EVOLVED CONFIGURATION SYSTEM ]] --
    local Config_Group = SettingsTab:Group("Configuration System (Robust)")
    local selectedConfig = "Default"
    local newConfigName = ""
    local importData = ""
    local ConfigDropdown
    
    local function GetConfigs()
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
    
    ConfigDropdown = Config_Group:Dropdown("Select Config", GetConfigs(), "Default", function(v) 
        selectedConfig = v 
    end)
    
    Config_Group:Button("Refresh List", function()
        if ConfigDropdown and ConfigDropdown.Refresh then
            local newList = GetConfigs()
            ConfigDropdown.Refresh(newList, selectedConfig)
            Library:Notify("System", "Config list refreshed.", 2)
        end
    end)
    
    -- [CORE FUNCTION: LOAD]
    Config_Group:Button("Load Config", function()
        local path = GameFolder .. "/" .. selectedConfig .. ".json"
        if not isfile(path) then
            Library:Notify("Error", "Config file not found!", 3)
            return
        end

        local content = readfile(path)
        local success, rawData = pcall(function() return HttpService:JSONDecode(content) end)

        if not success or not rawData then
            Library:Notify("Error", "Failed to parse JSON (Corrupt File)", 5)
            print("[FSSHUB ERROR] JSON Decode Failed: ", rawData)
            return
        end

        local data = Deserialize(rawData)

        -- Apply settings
        for title, value in pairs(data) do
            Library.flags[title] = value
            if ConfigItems[title] then
                ConfigItems[title].Set(value)
            end
        end

        if Library.themeRegistry then
            for _, item in ipairs(Library.themeRegistry) do
                if item.Type == "Func" then pcall(item.Func) end
            end
        end

        Library:Notify("Config", "Loaded: " .. selectedConfig, 3)
    end)
    
    -- [CORE FUNCTION: SAVE]
    Config_Group:Button("Save / Overwrite Config", function()
        local serializedData = Serialize(Library.flags)
        local success, encoded = pcall(function() return HttpService:JSONEncode(serializedData) end)

        if not success then
            Library:Notify("Error", "Failed to serialize data!", 4)
            print("[FSSHUB ERROR] JSON Encode Failed: ", encoded)
            return
        end

        writefile(GameFolder .. "/" .. selectedConfig .. ".json", encoded)
        Library:Notify("Config", "Saved: " .. selectedConfig, 3)
    end)
    
    -- [CREATE NEW]
    Config_Group:Label("Management:")
    Config_Group:TextBox("New Config Name", "", function(val) 
        newConfigName = val 
    end)
    
    Config_Group:Button("Create New", function()
        if newConfigName == "" then 
            Library:Notify("Error", "Please enter a name first!", 3) 
            return 
        end
        
        local serializedData = Serialize(Library.flags)
        writefile(GameFolder .. "/" .. newConfigName .. ".json", HttpService:JSONEncode(serializedData))
        Library:Notify("Config", "Created: " .. newConfigName, 3)
        
        if ConfigDropdown and ConfigDropdown.Refresh then
            selectedConfig = newConfigName
            ConfigDropdown.Refresh(GetConfigs(), newConfigName)
        end
    end)

    Config_Group:Button("Delete Selected", function()
        local path = GameFolder .. "/" .. selectedConfig .. ".json"
        if isfile(path) and selectedConfig ~= "Default" then
            delfile(path)
            Library:Notify("Config", "Deleted: " .. selectedConfig, 3)
            
            selectedConfig = "Default"
            if ConfigDropdown and ConfigDropdown.Refresh then
                ConfigDropdown.Refresh(GetConfigs(), "Default")
            end
        else
            Library:Notify("Error", "Cannot delete Default/Missing", 3)
        end
    end)
    
    -- [SHARE / CLIPBOARD]
    Config_Group:Label("Share Configuration:")

    Config_Group:Button("Export to Clipboard", function()
        local serializedData = Serialize(Library.flags)
        local success, json = pcall(function() return HttpService:JSONEncode(serializedData) end)

        if success then
            local encoded = Base64.Encode(json)
            setclipboard(encoded)
            Library:Notify("System", "Config copied to clipboard!", 3)
        else
            Library:Notify("Error", "Export Failed", 3)
        end
    end)

    Config_Group:TextBox("Import Data (Paste Here)", "", function(val)
        importData = val
    end)

    Config_Group:Button("Import from Clipboard", function()
        if importData == "" then
            Library:Notify("Error", "Paste config data first!", 3)
            return
        end

        -- 1. Base64 Decode
        local jsonStr = Base64.Decode(importData)
        if not jsonStr or jsonStr == "" then
            Library:Notify("Error", "Invalid Base64 Data", 3)
            return
        end

        -- 2. JSON Decode
        local s, rawData = pcall(function() return HttpService:JSONDecode(jsonStr) end)
        if not s then
            Library:Notify("Error", "Invalid Config Format", 3)
            return
        end

        -- 3. Deserialize & Load
        local data = Deserialize(rawData)
        for title, value in pairs(data) do
            Library.flags[title] = value
            if ConfigItems[title] then
                ConfigItems[title].Set(value)
            end
        end

        Library:Notify("Config", "Imported Successfully!", 3)
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

    task.delay(1, function()
        Library:Notify("Welcome", "Script loaded successfully!", 5)
    end)
end

return UIManager
