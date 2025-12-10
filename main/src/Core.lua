-- [[ FSSHUB CORE V9.5 (FIXED & ANTI-CACHE) ]] --

local Core = {}
local FILE_NAME = "FSSHUB_License.key"

-- KONFIGURASI
local API_URL = "https://script.google.com/macros/s/AKfycby0s_ataAeB1Sw1IFz0k-x3OBM7TNMfA66OKm32Fl9E0F3Nf7vRieVzx9cA8TGX0mz_/exec" 
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

-- Database Game ID
local GAME_DB = {
    [92371631484540] = "main/scripts/SurviveWaveZ.lua",
    [9168386959] = "main/scripts/SurviveWaveZ.lua"
}
local DEFAULT_GAME = "main/scripts/Universal.lua"

-- Utility: Load Url dengan Anti-Cache
local function LoadUrl(path)
    local url = BASE_URL .. path .. "?t=" .. tostring(math.random(1, 100000)) -- Anti-Cache Token
    return game:HttpGet(url)
end

local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN_HWID"
end

local function Notify(title, text)
    pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5}) end)
end

-- Validasi Key
function Core.ValidateKey(input)
    if not input or #input < 5 then return {valid=false} end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    local hwid = GetHWID()
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&nocache=" .. math.random(1, 10000)
    
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data and data.status == "success" then
            return {valid=true, info=data.info}
        end
    end
    return {valid=false}
end

-- Logika Loading Game
function Core.LoadGame()
    Notify("SYSTEM", "Initializing Engine...")

    -- 1. Load UIManager (Builder)
    local successManager, ManagerLib = pcall(function() 
        return loadstring(LoadUrl("main/modules/UIManager.lua"))() 
    end)
    
    if not successManager or not ManagerLib then 
        Notify("FATAL ERROR", "Failed to load UI Manager") 
        return 
    end

    -- 2. Tentukan Script Game
    local placeId = game.PlaceId
    local scriptPath = GAME_DB[placeId] or DEFAULT_GAME
    
    -- 3. Load Data Game
    local successData, GameData = pcall(function() 
        return loadstring(LoadUrl(scriptPath))() 
    end)
    
    -- Validasi Data Game
    if not successData or type(GameData) ~= "table" then
        warn("[FSSHUB DEBUG] Load Error on: " .. scriptPath)
        warn("[FSSHUB DEBUG] Data Type: " .. type(GameData))
        
        Notify("WARNING", "Game Script Update Required. Loading Universal...")
        
        -- Fallback ke Universal
        local successUniv, UnivData = pcall(function() 
            return loadstring(LoadUrl(DEFAULT_GAME))() 
        end)
        
        if successUniv and type(UnivData) == "table" then
            GameData = UnivData
        else
            Notify("FATAL ERROR", "Universal Script also failed!")
            return
        end
    end

    -- 4. Rakit UI
    ManagerLib.Build(GameData)
end

function Core.Init()
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
