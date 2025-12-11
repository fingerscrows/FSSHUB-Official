-- [[ FSSHUB CORE V11.5 (DEBUG MODE) ]] --
-- Path: main/src/Core.lua

local Core = {}
local FILE_NAME = "FSSHUB_License.key"
Core.AuthData = nil 

local function Log(msg)
    print("[FSS-DEBUG] [Core] " .. tostring(msg))
end

-- KONFIGURASI
local API_URL = "https://script.google.com/macros/s/AKfycby0s_ataAeB1Sw1IFz0k-x3OBM7TNMfA66OKm32Fl9E0F3Nf7vRieVzx9cA8TGX0mz_/exec" 
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"
local DEFAULT_GAME = "main/scripts/Universal.lua" 

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")

local function GetGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then return info.Name end
    return "Unknown Game (" .. tostring(game.PlaceId) .. ")"
end

local function LoadUrl(path)
    Log("Fetching URL: " .. path)
    return game:HttpGet(BASE_URL .. path .. "?t=" .. tostring(os.time()))
end

local function Notify(title, text)
    pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5}) end)
end

local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN_HWID"
end

function Core.ValidateKey(input)
    Log("Validating Key...")
    if not input or #input < 5 then 
        Log("Key Invalid (Too short/nil)")
        return {valid=false} 
    end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    local hwid = GetHWID()
    local pid = game.PlaceId
    local jid = game.JobId
    local gid = game.GameId
    local gameName = GetGameName()
    local encodedName = HttpService:UrlEncode(gameName)
    
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&pid=" .. pid .. "&gid=" .. gid .. "&jid=" .. jid .. "&gn=" .. encodedName .. "&nocache=" .. tostring(os.time())
    
    Log("Sending Request to Server...")
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
   if success then
        Log("Server responded. Parsing JSON...")
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data then
            Log("JSON Parsed. Status: " .. tostring(data.status))
            if data.status == "success" then
                local rawExpiry = tonumber(data.expiry) or 0
                if rawExpiry > 9999999999 then rawExpiry = math.floor(rawExpiry / 1000) end
                
                Core.AuthData = {
                    Type = (data.info and (string.find(data.info, "Premium") or string.find(data.info, "Unlimited"))) and "Premium" or "Free",
                    Expiry = rawExpiry, 
                    Key = input,
                    GameName = gameName,
                    TargetScript = data.script, 
                    IsDev = data.message and string.find(data.message, "Dev") ~= nil,
                    MOTD = data.motd
                }
                return {valid=true, info=data.info} 
            else
                Log("Server rejected key: " .. tostring(data.message))
            end
        else
            Log("Failed to parse JSON: " .. tostring(res))
        end
    else
        Log("HTTP Request Failed: " .. tostring(res))
    end
    return {valid=false}
end

function Core.LoadGame()
    Log("Starting Game Load Sequence...")
    Notify("SYSTEM", "Checking Database...")
    
    local successManager, ManagerLib = pcall(function() return loadstring(LoadUrl("main/modules/UIManager.lua"))() end)
    if not successManager or not ManagerLib then 
        Log("CRITICAL: Failed to load UIManager")
        Notify("FATAL ERROR", "Failed to load UI Manager") 
        return 
    end
    Log("UIManager loaded.")

    local scriptPath = DEFAULT_GAME
    local isUniversal = true
    
    if Core.AuthData and Core.AuthData.TargetScript and Core.AuthData.TargetScript ~= "" then
        scriptPath = Core.AuthData.TargetScript
        isUniversal = false
    end
    
    if not Core.AuthData then Core.AuthData = {} end
    Core.AuthData.IsUniversal = isUniversal
    
    Log("Loading Game Script: " .. scriptPath)

    local successData, GameData = pcall(function() return loadstring(LoadUrl(scriptPath))() end)
    
    if not successData or type(GameData) ~= "table" then
        Log("Failed to load Target Script. Fallback to Universal.")
        Notify("WARNING", "Official Script Error. Fallback...")
        
        local successUniv, UnivData = pcall(function() return loadstring(LoadUrl(DEFAULT_GAME))() end)
        if successUniv and type(UnivData) == "table" then 
            GameData = UnivData 
            Core.AuthData.IsUniversal = true
            scriptPath = DEFAULT_GAME
        else 
            Log("CRITICAL: Universal Script also failed!")
            Notify("FATAL ERROR", "Universal Script Failed!") 
            return 
        end
    end
    
    if Core.AuthData.GameName then GameData.Name = Core.AuthData.GameName end

    Log("Calling ManagerLib.Build...")
    -- Failsafe Build call
    local buildStatus, buildErr = pcall(function()
        ManagerLib.Build(GameData, Core.AuthData)
    end)
    
    if not buildStatus then
        Log("UI Build Crashed: " .. tostring(buildErr))
    else
        Log("UI Build Success.")
    end
end

function Core.Init()
    Log("Core Initialized.")
    if isfile and isfile(FILE_NAME) then
        Log("Found saved key.")
        local saved = readfile(FILE_NAME)
        local result = Core.ValidateKey(saved)
        if result.valid then
            Log("Saved key is valid.")
            Notify("WELCOME BACK", Core.AuthData.Type .. " User")
            Core.LoadGame()
            return
        else
            Log("Saved key invalid/expired.")
        end
    end
    
    Log("Loading Auth UI...")
    local success, AuthUI = pcall(function() return loadstring(LoadUrl("main/modules/AuthUI.lua"))() end)
    if success and AuthUI then
        AuthUI.Show({
            OnSuccess = function(key)
                local result = Core.ValidateKey(key)
                if result.valid then
                    writefile(FILE_NAME, key)
                    task.spawn(function() Core.LoadGame() end)
                    return {success = true, info = result.info} 
                end
                return {success = false}
            end
        })
    else
        Log("Failed to load AuthUI module")
        Notify("ERROR", "Auth UI Failed to Load")
    end
end

return Core
