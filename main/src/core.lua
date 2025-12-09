-- [[ FSSHUB CORE SYSTEM V1.0 ]] --
-- Mengatur logika Key System dan Deteksi Game

local Core = {}

-- KONFIGURASI
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" 
local UPDATE_INTERVAL = 6 
local FILE_NAME = "FSS_V5_Key.txt"
local REPO = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

-- URL MODULES
local AUTH_UI_URL = REPO .. "main/modules/AuthUI.lua"
local GAME_DB = {
    ["92371631484540"] = REPO .. "main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = REPO .. "main/scripts/SurviveWaveZ.lua"
}
local UNIVERSAL_SCRIPT = REPO .. "main/scripts/SurviveWaveZ.lua"

-- SERVICES
local HttpService = game:GetService("HttpService")

-- UTILS: Hashing DJB2
local function djb2Hash(str)
    local hash = 5381
    for i = 1, #str do
        local byte = string.byte(str, i)
        hash = (hash * 33) + byte
        hash = hash % 4294967296 
    end
    return string.upper(string.format("%x", hash))
end

-- UTILS: Generate Valid Key saat ini
function Core.GetValidKey()
    local now = os.time()
    local block = math.floor(math.floor(now / 3600) / UPDATE_INTERVAL)
    local hash = djb2Hash(block .. "-" .. SECRET_SALT)
    return "KEY-" .. hash
end

-- LOGIC: Run Game Script
function Core.LoadGame()
    local id = tostring(game.PlaceId)
    local gid = tostring(game.GameId)
    local url = GAME_DB[id] or GAME_DB[gid] or UNIVERSAL_SCRIPT
    
    -- Notifikasi via StarterGui (karena lib belum load)
    game.StarterGui:SetCore("SendNotification", {Title = "FSS HUB", Text = "Key Verified! Loading Game...", Duration = 3})
    
    local s, err = pcall(function() loadstring(game:HttpGet(url))() end)
    if not s then warn("[FSSHUB] Game Script Error: "..tostring(err)) end
end

-- LOGIC: Main Execution
function Core.Init()
    local ValidKey = Core.GetValidKey()
    
    -- 1. Cek File Key Tersimpan
    if isfile and isfile(FILE_NAME) then
        local saved = string.gsub(readfile(FILE_NAME), "%s+", "")
        if saved == ValidKey then
            Core.LoadGame()
            return
        end
    end
    
    -- 2. Jika Key Salah/Tidak Ada -> Load UI Auth
    -- Kita load script UI secara terpisah agar render lebih stabil
    local s, AuthModule = pcall(function() return loadstring(game:HttpGet(AUTH_UI_URL))() end)
    
    if s and AuthModule then
        AuthModule.Show({
            ValidKey = ValidKey,
            OnSuccess = function(key)
                if writefile then writefile(FILE_NAME, key) end
                Core.LoadGame()
            end
        })
    else
        warn("[FSSHUB] Failed to load AuthUI: " .. tostring(AuthModule))
    end
end

Core.Init()
