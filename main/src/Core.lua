-- [[ FSSHUB CORE V7.6 (VISUAL UPDATE) ]] --
-- Changelog: Mengirim info status ke AuthUI, Auto-Login Notification

local Core = {}
local FILE_NAME = "FSSHUB_V7_License.key"

-- GANTI URL INI DENGAN DEPLOYMENT GAS V7.5 TERBARU KAMU
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
    if not input or #input < 5 then return {valid=false} end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1") -- Trim spasi
    
    local hwid = GetHWID()
    
    -- Request Verify (Mode: verify, Kirim HWID & Key)
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&nocache=" .. math.random(1, 10000)
    
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data then
            if data.status == "success" then
                return {valid=true, info=data.info}
            else
                warn("[FSSHUB] Key Invalid: " .. tostring(data.message))
            end
        else
            warn("[FSSHUB] Server Error (Not JSON): " .. tostring(res))
        end
    else
        warn("[FSSHUB] Connection Fail")
    end
    return {valid=false}
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
    -- Cek Key Tersimpan (Auto-Login)
    if isfile and isfile(FILE_NAME) then
        local saved = readfile(FILE_NAME)
        local result = Core.ValidateKey(saved)
        if result.valid then
            -- Tampilkan notifikasi status (Premium/Biasa) saat auto-login
            local statusMsg = (result.info and (string.find(result.info, "Premium") or string.find(result.info, "Unlimited"))) 
                              and "👑 PREMIUM MEMBER" 
                              or ("⏳ " .. (result.info or "Active"))
            
            Notify("WELCOME BACK", statusMsg)
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
                local result = Core.ValidateKey(key)
                if result.valid then
                    writefile(FILE_NAME, key)
                    Core.LoadGame()
                    -- RETURN DATA LENGKAP KE UI AGAR BISA UBAH WARNA TOMBOL
                    return {success = true, info = result.info} 
                end
                return {success = false}
            end
        })
    end
end

return Core
