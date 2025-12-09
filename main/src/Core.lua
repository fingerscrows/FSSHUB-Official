-- [[ FSSHUB CORE V6 (FINAL PRODUCTION) ]] --
-- Update: New GAS Endpoint & HWID System

local Core = {}
local FILE_NAME = "FSSHUB_V6.key"
-- URL GAS TERBARU ANDA
local API_URL = "https://script.google.com/macros/s/AKfycby0s_ataAeB1Sw1IFz0k-x3OBM7TNMfA66OKm32Fl9E0F3Nf7vRieVzx9cA8TGX0mz_/exec"

local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

-- Services Load
local MODULES = {
    AuthUI = BASE_URL .. "main/modules/AuthUI.lua",
    Universal = BASE_URL .. "main/scripts/Universal.lua" 
}
local GAME_DB = {
    ["92371631484540"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua"
}

-- Utility: Get HWID (Client ID)
local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN_HWID"
end

local function Notify(title, text)
    pcall(function() StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5}) end)
end

-- VALIDASI KEY KE SERVER
function Core.ValidateKey(input)
    if not input or #input < 5 then return false end
    -- Bersihkan spasi
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    local hwid = GetHWID()
    
    -- Request Verify (Mode: verify, Kirim HWID & Key)
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&nocache=" .. math.random(1, 10000)
    
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data then
            if data.status == "success" then
                return true
            else
                warn("[FSSHUB] Key Invalid: " .. tostring(data.message))
            end
        else
            warn("[FSSHUB] Server Error (Not JSON): " .. tostring(res))
        end
    else
        warn("[FSSHUB] Connection Fail")
    end
    return false
end

function Core.LoadGame()
    local id = tostring(game.PlaceId)
    local gid = tostring(game.GameId)
    local url = GAME_DB[id] or GAME_DB[gid] or MODULES.Universal
    local name = (GAME_DB[id] or GAME_DB[gid]) and "Game Script" or "Universal"
    
    Notify("ACCESS GRANTED", "Loading " .. name .. "...")
    task.spawn(function() loadstring(game:HttpGet(url))() end)
end

function Core.Init()
    -- Cek Key Tersimpan
    if isfile and isfile(FILE_NAME) then
        local saved = readfile(FILE_NAME)
        if Core.ValidateKey(saved) then
            Core.LoadGame()
            return
        end
    end
    
    -- Jika belum login, Load UI
    local uiFunc = loadstring(game:HttpGet(MODULES.AuthUI))
    if uiFunc then
        local UI = uiFunc()
        UI.Show({
            OnSuccess = function(key)
                if Core.ValidateKey(key) then
                    writefile(FILE_NAME, key)
                    Core.LoadGame()
                    return true
                end
                return false
            end
        })
    end
end

return Core
