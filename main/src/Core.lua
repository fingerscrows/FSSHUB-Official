-- [[ FSSHUB CORE V11.2 (SMART NAMING) ]] --
-- Fitur: Override Nama Menu dengan Nama Game Asli & Status Deteksi

local Core = {}
local FILE_NAME = "FSSHUB_License.key"
Core.AuthData = nil 

-- KONFIGURASI
local API_URL = "https://script.google.com/macros/s/AKfycby0s_ataAeB1Sw1IFz0k-x3OBM7TNMfA66OKm32Fl9E0F3Nf7vRieVzx9cA8TGX0mz_/exec" 
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"
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
    if success and info then return info.Name end
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

-- Validasi Key
function Core.ValidateKey(input)
    if not input or #input < 5 then return {valid=false} end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    local hwid = GetHWID()
    local pid = game.PlaceId
    local jid = game.JobId
    local gid = game.GameId
    local gameName = GetGameName()
    local encodedName = HttpService:UrlEncode(gameName)
    
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&pid=" .. pid .. "&gid=" .. gid .. "&jid=" .. jid .. "&gn=" .. encodedName .. "&nocache=" .. math.random(1, 10000)
    
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data and data.status == "success" then
            
            local rawExpiry = tonumber(data.expiry) or 0
            if rawExpiry > 9999999999 then rawExpiry = math.floor(rawExpiry / 1000) end
            
            -- Cek Status Dev
            local isDeveloper = data.message and string.find(data.message, "Dev") ~= nil

            Core.AuthData = {
                Type = (data.info and (string.find(data.info, "Premium") or string.find(data.info, "Unlimited"))) and "Premium" or "Free",
                Expiry = rawExpiry, 
                Key = input,
                GameName = gameName, 
                TargetScript = data.script, -- Script khusus dari Cloud
                IsDev = isDeveloper
            }
            
            return {valid=true, info=data.info} 
        end
    end
    return {valid=false}
end

function Core.LoadGame()
    Notify("SYSTEM", "Checking Database...")
    
    local successManager, ManagerLib = pcall(function() return loadstring(LoadUrl("main/modules/UIManager.lua"))() end)
    if not successManager or not ManagerLib then Notify("FATAL ERROR", "Failed to load UI Manager") return end

    -- [LOGIKA PENENTUAN SCRIPT]
    local scriptPath = DEFAULT_GAME
    local isUniversal = true -- Default anggap Universal
    
    -- Jika Server memberikan script khusus, pakai itu
    if Core.AuthData and Core.AuthData.TargetScript then
        scriptPath = Core.AuthData.TargetScript
        isUniversal = false -- Tandai sebagai script resmi/support
    end
    
    -- Simpan status ke AuthData agar UIManager tau
    Core.AuthData.IsUniversal = isUniversal
    
    print("[FSSHUB] Module: " .. scriptPath .. " | Mode: " .. (isUniversal and "Universal" or "Official"))

    -- Load Data Game
    local successData, GameData = pcall(function() return loadstring(LoadUrl(scriptPath))() end)
    
    if not successData or type(GameData) ~= "table" then
        Notify("WARNING", "Module Error. Loading Universal...")
        local successUniv, UnivData = pcall(function() return loadstring(LoadUrl(DEFAULT_GAME))() end)
        if successUniv then 
            GameData = UnivData 
            Core.AuthData.IsUniversal = true -- Fallback jadi Universal
        else 
            Notify("FATAL ERROR", "Universal Script Failed!") 
            return 
        end
    end
    
    -- [OVERRIDE NAMA MENU]
    -- Selalu gunakan Nama Game Asli sebagai Judul Menu (Request User)
    -- Jadi tidak akan pernah muncul tulisan "Universal V3.1" di header
    if Core.AuthData and Core.AuthData.GameName then
        GameData.Name = Core.AuthData.GameName
    end

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
