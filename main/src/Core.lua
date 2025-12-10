-- [[ FSSHUB CORE V8.0 (MODULAR AUTH BRIDGE) ]] --
-- Bertugas: Handle Auth -> Load Data -> Panggil UIManager

local Core = {}
local FILE_NAME = "FSSHUB_License.key"

-- KONFIGURASI SERVER (Pastikan URL ini benar)
local API_URL = "https://script.google.com/macros/s/AKfycby0s_ataAeB1Sw1IFz0k-x3OBM7TNMfA66OKm32Fl9E0F3Nf7vRieVzx9cA8TGX0mz_/exec" 
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

-- Services
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

-- Database Game ID (Untuk Modular System)
local GAME_DB = {
    [92371631484540] = BASE_URL .. "main/scripts/SurviveWaveZ.lua",
    [9168386959] = BASE_URL .. "main/scripts/SurviveWaveZ.lua"
}
local DEFAULT_GAME = BASE_URL .. "main/scripts/Universal.lua"

-- Utility
local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN_HWID"
end

local function Notify(title, text)
    pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5}) end)
end

-- [[ SISTEM VALIDASI ]] --
function Core.ValidateKey(input)
    if not input or #input < 5 then return {valid=false} end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    local hwid = GetHWID()
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&nocache=" .. math.random(1, 10000)
    
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data then
            if data.status == "success" then
                return {valid=true, info=data.info}
            end
        end
    end
    return {valid=false}
end

-- [[ LOGIKA LOADING BARU (MODULAR) ]] --
function Core.LoadGame()
    Notify("ACCESS GRANTED", "Initializing Modular Engine...")

    -- 1. Tentukan URL Script Game
    local placeId = game.PlaceId
    local gameUrl = GAME_DB[placeId] or DEFAULT_GAME
    
    -- 2. Load UIManager (Builder)
    local managerUrl = BASE_URL .. "main/modules/UIManager.lua"
    local successManager, ManagerLib = pcall(function() return loadstring(game:HttpGet(managerUrl))() end)
    
    if not successManager then 
        Notify("ERROR", "Failed to load UI Manager") 
        return 
    end

    -- 3. Load Data Game (Config Table)
    local successData, GameData = pcall(function() return loadstring(game:HttpGet(gameUrl))() end)
    
    if not successData or type(GameData) ~= "table" then
        Notify("ERROR", "Failed to load Game Data")
        -- Fallback ke Universal jika game specific error
        GameData = loadstring(game:HttpGet(DEFAULT_GAME))()
    end

    -- 4. RAKIT UI!
    ManagerLib.Build(GameData)
end

function Core.Init()
    -- Cek Key Tersimpan (Auto-Login)
    if isfile and isfile(FILE_NAME) then
        local saved = readfile(FILE_NAME)
        local result = Core.ValidateKey(saved)
        if result.valid then
            local statusMsg = (result.info and (string.find(result.info, "Premium") or string.find(result.info, "Unlimited"))) 
                              and "👑 PREMIUM MEMBER" or "⏳ ACTIVE USER"
            Notify("WELCOME BACK", statusMsg)
            Core.LoadGame()
            return
        end
    end
    
    -- Jika belum login, Load UI Auth
    local authUrl = BASE_URL .. "main/modules/AuthUI.lua"
    local authFunc = loadstring(game:HttpGet(authUrl))
    
    if authFunc then
        local AuthUI = authFunc()
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
        Notify("FATAL ERROR", "Could not load Auth UI")
    end
end

return Core
