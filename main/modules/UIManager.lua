-- [[ FSSHUB: UI MANAGER V2.0 (RE-ENGINEERED) ]] --
-- Status: Serialized, Robust, Clipboard-Ready, Auto-Save
-- Path: main/modules/UIManager.lua

local UIManager = {}
print("[FSSHUB DEBUG] UIManager Loaded")

local BaseUrl = getgenv().FSSHUB_DEV_BASE or "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/main/"
local LIB_URL = BaseUrl .. "main/lib/FSSHUB_Lib.lua"

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local StoredConfig = nil
local StoredAuth = nil
local LibraryInstance = nil
local ConfigFolder = "FSSHUB_Settings"
local ActiveConfigName = "Default" -- Track active config for Auto-Save

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

-- [HELPER: ROBUST SERIALIZER V2.0]
-- Handles: Color3, EnumItem, Vector3, Vector2, UDim2
local function Serialize(tbl)
    local output = {}
    for k, v in pairs(tbl) do
        local t = typeof(v)
        if t == "Color3" then
            output[k] = { __type = "Color3", R = v.R, G = v.G, B = v.B }
        elseif t == "EnumItem" then
            output[k] = { __type = "Enum", EnumType = tostring(v.EnumType), Name = v.Name }
        elseif t == "Vector3" then
            output[k] = { __type = "Vector3", X = v.X, Y = v.Y, Z = v.Z }
        elseif t == "Vector2" then
            output[k] = { __type = "Vector2", X = v.X, Y = v.Y }
        elseif t == "UDim2" then
            output[k] = { __type = "UDim2", XS = v.X.Scale, XO = v.X.Offset, YS = v.Y.Scale, YO = v.Y.Offset }
        elseif t == "table" then
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
            elseif v.__type == "Vector3" then
                output[k] = Vector3.new(v.X, v.Y, v.Z)
            elseif v.__type == "Vector2" then
                output[k] = Vector2.new(v.X, v.Y)
            elseif v.__type == "UDim2" then
                output[k] = UDim2.new(v.XS, v.XO, v.YS, v.YO)
            elseif v.__type == "Enum" then
                -- Robust Enum Restoration
                local enumTypeStr = tostring(v.EnumType)
                local parts = {}
                for part in string.gmatch(enumTypeStr, "[^%.]+") do table.insert(parts, part) end

                local targetEnum = Enum
                if parts[1] == "Enum" and parts[2] then
                    pcall(function() targetEnum = Enum[parts[2]] end)
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
        warn("[FSSHUB CRITICAL] Library Load Failed: " .. tostring(lib))
    end
    return nil
end

function UIManager.Build(GameConfig, AuthData)
    StoredConfig = GameConfig
    StoredAuth = AuthData
    
    local Library = LoadLibrary()
    if not Library then return end

    print("[FSSHUB DEBUG] Building Window V2.0...")

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
            if not AuthData.Expiry or AuthData.Expiry == 0 or AuthData.Expiry > 9000000000 then
                TimerLabel.Text = "Expiry: PERMANENT"
                return 
            end
            while TimerLabel.Parent do
                local left = AuthData.Expiry - os.time()
                if left <= 0 then TimerLabel.Text = "LICENSE EXPIRED"; break end
                local d, h, m, s = math.floor(left/86400), math.floor((left%86400)/3600), math.floor((left%3600)/60), math.floor(left%60)
                TimerLabel.Text = string.format("Expires In: %dd %02dh %02dm %02ds", d, h, m, s)
                task.wait(1)
            end
        end)
    end
    ProfileTab:Label("Credits: FingersCrows")

    -- [[ 2. GENERATOR LOOP V2.0 ]] --
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
                    Tab:Button(element.Title, element.Callback)
                elseif element.Type == "Keybind" then 
                    newItem = Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "TextBox" then
                    newItem = Tab:TextBox(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then 
                    Tab:Label(element.Title)
                end
                
                -- Apply internal keybind if provided in config
                if newItem and element.Keybind and newItem.SetKeybind then 
                    newItem.SetKeybind(element.Keybind) 
                end
                
                -- Capture Element for Config System
                if newItem and (newItem.Set or newItem.SetKeybind) then
                    ConfigItems[element.Title] = newItem
                end
            end
        end
    end
    
    -- [[ 3. CONFIGURATION LOGIC ]] --

    -- Internal Save Function
    local function SaveConfigInternal(name)
        if not name or name == "" then return false, "Invalid Name" end
        local serializedData = Serialize(Library.flags)
        local success, encoded = pcall(function() return HttpService:JSONEncode(serializedData) end)

        if success then
            writefile(GameFolder .. "/" .. name .. ".json", encoded)
            return true, "Success"
        else
            return false, "Serialization Failed"
        end
    end

    -- Internal Load Function
    local function ApplyConfigData(data)
        for title, value in pairs(data) do
            Library.flags[title] = value

            -- Special Handling for Keybinds
            if title:sub(-8) == "_Keybind" then
                local realTitle = title:sub(1, -9)
                if ConfigItems[realTitle] and ConfigItems[realTitle].SetKeybind then
                    ConfigItems[realTitle].SetKeybind(value)
                end
            elseif ConfigItems[title] and ConfigItems[title].Set then
                ConfigItems[title].Set(value)
            end
        end

        -- Refresh Theme
        if Library.themeRegistry then
            for _, item in ipairs(Library.themeRegistry) do
                if item.Type == "Func" then pcall(item.Func) end
            end
        end
    end

    -- [[ 4. SETTINGS TAB ]] --
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
    UI_Group:Toggle("Show Notifications", true, function(state) Library.flags["Show Notifications"] = state end)
    UI_Group:Keybind("Hide/Show Menu", Enum.KeyCode.RightControl, function()
        if Library.base then 
            local m = Library.base:FindFirstChild("MainFrame"); if m then m.Visible = not m.Visible end
        end
    end)

    -- Config System UI
    local Config_Group = SettingsTab:Group("Configuration V2.0")
    local newConfigName = ""
    local importData = ""
    local ConfigDropdown
    
    local function GetConfigs()
        local list = {}
        if isfolder(GameFolder) then
            for _, path in ipairs(listfiles(GameFolder)) do 
                if path:sub(-5) == ".json" then 
                    local name = path:match("^.+\\(.+)$") or path:match("^.+/(.+)$")
                    name = name:gsub(".json", ""); table.insert(list, name)
                end 
            end
        end
        if #list == 0 then table.insert(list, "Default") end
        return list
    end
    
    ConfigDropdown = Config_Group:Dropdown("Select Config", GetConfigs(), "Default", function(v) 
        ActiveConfigName = v
    end)
    
    Config_Group:Button("Refresh List", function()
        if ConfigDropdown and ConfigDropdown.Refresh then
            ConfigDropdown.Refresh(GetConfigs(), ActiveConfigName)
            Library:Notify("System", "Refreshed", 2)
        end
    end)
    
    Config_Group:Button("Load Config", function()
        local path = GameFolder .. "/" .. ActiveConfigName .. ".json"
        if not isfile(path) then Library:Notify("Error", "File not found", 3) return end

        local s, raw = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not s then Library:Notify("Error", "Corrupt File", 3) return end

        ApplyConfigData(Deserialize(raw))
        Library:Notify("Config", "Loaded: " .. ActiveConfigName, 3)
    end)
    
    Config_Group:Button("Save / Overwrite", function()
        local s, err = SaveConfigInternal(ActiveConfigName)
        if s then Library:Notify("Config", "Saved: " .. ActiveConfigName, 3)
        else Library:Notify("Error", err, 3) end
    end)
    
    Config_Group:Label("Create New:")
    Config_Group:TextBox("Config Name", "", function(v) newConfigName = v end)
    Config_Group:Button("Create", function()
        local s, err = SaveConfigInternal(newConfigName)
        if s then
            Library:Notify("Config", "Created: " .. newConfigName, 3)
            ActiveConfigName = newConfigName
            if ConfigDropdown and ConfigDropdown.Refresh then ConfigDropdown.Refresh(GetConfigs(), newConfigName) end
        else Library:Notify("Error", err, 3) end
    end)
    
    Config_Group:Button("Delete", function()
        if ActiveConfigName == "Default" then Library:Notify("Error", "Cannot delete Default", 3) return end
        delfile(GameFolder .. "/" .. ActiveConfigName .. ".json")
        ActiveConfigName = "Default"
        if ConfigDropdown and ConfigDropdown.Refresh then ConfigDropdown.Refresh(GetConfigs(), "Default") end
        Library:Notify("Config", "Deleted", 3)
    end)

    -- Clipboard Feature
    Config_Group:Label("Sharing:")
    Config_Group:Button("Export to Clipboard", function()
        local serialized = Serialize(Library.flags)
        local s, json = pcall(function() return HttpService:JSONEncode(serialized) end)
        if s then
            setclipboard(Base64.Encode(json))
            Library:Notify("System", "Copied to Clipboard!", 3)
        else Library:Notify("Error", "Export Failed", 3) end
    end)

    Config_Group:TextBox("Import Data", "", function(v) importData = v end)
    Config_Group:Button("Import from Clipboard", function()
        if importData == "" then Library:Notify("Error", "Empty Clipboard Data", 3) return end
        local jsonStr = Base64.Decode(importData)
        if not jsonStr or jsonStr == "" then Library:Notify("Error", "Invalid Base64", 3) return end

        local s, raw = pcall(function() return HttpService:JSONDecode(jsonStr) end)
        if not s then Library:Notify("Error", "Invalid JSON", 3) return end

        ApplyConfigData(Deserialize(raw))
        Library:Notify("Config", "Imported!", 3)
    end)

    -- Auto Load
    local isAutoLoad = isfile(AutoLoadFile) and (readfile(AutoLoadFile) == ActiveConfigName)
    Config_Group:Toggle("Auto Load This Config", isAutoLoad, function(state)
        if state then writefile(AutoLoadFile, ActiveConfigName)
        else if isfile(AutoLoadFile) then delfile(AutoLoadFile) end end
    end)
    
    -- Utilities
    local Utils_Group = SettingsTab:Group("Utilities")
    Utils_Group:Button("Reset All", function()
        for _, item in pairs(ConfigItems) do if item.Set then item.Set(false) end end
        Library:Notify("System", "Reset Complete", 3)
    end)
    
    Utils_Group:Button("Rejoin Server", function() 
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) 
    end)
    
    if AuthData and AuthData.IsDev then
        Utils_Group:Button("Open Debug Console", function()
            local dbgUrl = BaseUrl .. "main/modules/Debugger.lua"
            pcall(function() loadstring(game:HttpGet(dbgUrl))().Show() end)
        end)
    end
    
    Utils_Group:Button("Unload Script", function()
        SaveConfigInternal(ActiveConfigName) -- Auto Save on manual unload
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        if Library.base then Library.base:Destroy() end
    end)

    -- [AUTO SAVE ON CLOSE]
    game:BindToClose(function()
        SaveConfigInternal(ActiveConfigName)
    end)

    task.delay(1, function() Library:Notify("Welcome", "System V2.0 Loaded", 5) end)
end

return UIManager
