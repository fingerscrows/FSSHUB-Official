-- [[ FSSHUB CORE V10.0 (ANALYTICS & DETECTION) ]] --
-- Fitur: Auto-Detect Game Name, Server Logging, & Precise ID Tracking

local Core = {}
local FILE_NAME = "FSSHUB_License.key"
Core.AuthData = nil 

-- KONFIGURASI
local API_URL = "https://script.google.com/macros/s/AKfycby0s_ataAeB1Sw1IFz0k-x3OBM7TNMfA66OKm32Fl9E0F3Nf7vRieVzx9cA8TGX0mz_/exec" 
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

-- Database ID -> Script Path
local GAME_DB = {
    [92371631484540] = "main/scripts/SurviveWaveZ.lua",
    [9168386959] = "main/scripts/SurviveWaveZ.lua"
}
local DEFAULT_GAME = "main/scripts/Universal.lua"

-- Services
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Utility: Fetch Game Info Realtime
local function GetGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info then
        return info.Name
    end
    return "Unknown Game"
end

local function LoadUrl(path)
    return game:HttpGet(BASE_URL .. path .. "?t=" .. tostring(math.random(1, 100000)))
end

local function Notify(title, text)
    pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5}) end)
end

local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN_HWID"
end

-- Validasi Key & Kirim Analytics
function Core.ValidateKey(input)
    if not input or #input < 5 then return {valid=false} end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    local hwid = GetHWID()
    
    -- [ANALYTICS DATA]
    local pid = game.PlaceId
    local jid = game.JobId
    local gameName = GetGameName()
    local encodedName = HttpService:UrlEncode(gameName) -- Encode agar URL aman
    
    -- Kirim Data ke Server (pid, jid, gn)
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&pid=" .. pid .. "&jid=" .. jid .. "&gn=" .. encodedName .. "&nocache=" .. math.random(1, 10000)
    
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data and data.status == "success" then
            
            -- Konversi Expiry
            local rawExpiry = tonumber(data.expiry) or 0
            if rawExpiry > 9999999999 then rawExpiry = math.floor(rawExpiry / 1000) end
            
            Core.AuthData = {
                Type = (data.info and (string.find(data.info, "Premium") or string.find(data.info, "Unlimited"))) and "Premium" or "Free",
                Expiry = rawExpiry, 
                Key = input,
                GameName = gameName -- Simpan nama game asli untuk UI
            }
            
            return {valid=true, info=data.info} 
        end
    end
    return {valid=false}
end

function Core.LoadGame()
    Notify("SYSTEM", "Initializing " .. (Core.AuthData.GameName or "Game") .. "...")
    
    -- 1. Load UIManager
    local successManager, ManagerLib = pcall(function() return loadstring(LoadUrl("main/modules/UIManager.lua"))() end)
    if not successManager or not ManagerLib then Notify("FATAL ERROR", "Failed to load UI Manager") return end

    -- 2. Detect & Load Script
    local placeId = game.PlaceId
    local scriptPath = GAME_DB[placeId] or DEFAULT_GAME
    
    -- Update Config Name agar sesuai nama asli game (bukan hardcoded)
    local successData, GameData = pcall(function() return loadstring(LoadUrl(scriptPath))() end)
    
    if not successData or type(GameData) ~= "table" then
        Notify("WARNING", "Loading Universal Module...")
        local successUniv, UnivData = pcall(function() return loadstring(LoadUrl(DEFAULT_GAME))() end)
        if successUniv then GameData = UnivData else Notify("FATAL ERROR", "Universal Script Failed!") return end
    end
    
    -- Override Nama Game di Config dengan Nama Asli dari Roblox
    if Core.AuthData and Core.AuthData.GameName then
        GameData.Name = Core.AuthData.GameName
    end

    -- 3. Build UI
    ManagerLib.Build(GameData, Core.AuthData)
end

function Core.Init()
    if isfile and isfile(FILE_NAME) then
        local saved = readfile(FILE_NAME)
        local result = Core.ValidateKey(saved)
        if result.valid then
            Notify("WELCOME BACK", Core.AuthData.Type .. " User")
            Core.LoadGame()
            return
        end
    end
    
    local success, AuthUI = pcall(function() return loadstring(LoadUrl("main/modules/AuthUI.lua"))() end)
    if success and AuthUI then
        AuthUI.Show({
            OnSuccess = function(key)
                local result = Core.ValidateKey(key)
                if result.valid then
                    writefile(FILE_NAME, key)
                    Core.LoadGame()
                    return {success = true, info = result.info} 
                end
                return {success = false}
            end
        })
    else
        Notify("ERROR", "Auth UI Failed to Load")
    end
end

return Core
