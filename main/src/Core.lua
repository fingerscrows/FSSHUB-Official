-- [[ FSSHUB CORE SYSTEM V3.3 (FULL DEBUGGER) ]] --
-- Update: Verbose Logging untuk Tracking Invalid Key

local Core = {}

-- [1] CONFIGURATION
local FILE_NAME = "FSSHUB_V3_Auth.key"
-- PASTIKAN URL INI SAMA PERSIS DENGAN YANG ADA DI INDEX.HTML
local API_URL = "https://script.google.com/macros/s/AKfycbymNkoO6T4fp0Iu1fDpN7_jC5PkwZX9TtU813gH9VbQd2jqC4y2dqbj9p_1drNM1tL_9A/exec" 

local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

local MODULES = {
    AuthUI = BASE_URL .. "main/modules/AuthUI.lua",
    Universal = BASE_URL .. "main/scripts/Universal.lua" 
}

local GAME_DB = {
    ["92371631484540"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua"
}

local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 5})
    end)
end

local function SafeLoad(url, name)
    local content, success = nil, false
    for i = 1, 3 do
        local s, res = pcall(function() return game:HttpGet(url) end)
        if s and res and #res > 0 then content = res; success = true; break end
        task.wait(1)
    end
    if not success then return nil end
    local func, err = loadstring(content)
    if not func then return nil end
    return func
end

-- [FULL DEBUG VALIDATION]
function Core.ValidateKey(keyInput)
    -- Bersihkan key dari spasi kosong yang mungkin ikut ter-copy
    keyInput = string.gsub(keyInput, "^%s*(.-)%s*$", "%1")
    
    if not keyInput or #keyInput < 5 then 
        warn("[FSSHUB DEBUG] Key terlalu pendek/kosong.")
        return false 
    end
    
    print("[FSSHUB DEBUG] Mengirim Key ke Server: '" .. keyInput .. "'")
    
    local success, response = pcall(function()
        return game:HttpGet(API_URL .. "?key=" .. keyInput .. "&nocache=" .. math.random(1, 10000))
    end)
    
    if success then
        print("[FSSHUB DEBUG] Server Menjawab: " .. tostring(response)) -- LIHAT INI DI KONSOL
        
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
        
        if decodeSuccess and data then
            if data.status == "success" then
                print("[FSSHUB DEBUG] STATUS: SUCCESS - Key Valid!")
                return true
            else
                -- INI YANG TERJADI PADA KASUS KAMU
                warn("[FSSHUB DEBUG] STATUS: GAGAL - Server menolak key.")
                warn("[FSSHUB DEBUG] Pesan Server: " .. tostring(data.message))
            end
        else
            warn("[FSSHUB DEBUG] ERROR PARSING: Respons bukan JSON valid.")
        end
    else
        warn("[FSSHUB DEBUG] KONEKSI GAGAL: " .. tostring(response))
    end
    
    return false
end

function Core.LoadGame()
    local id = tostring(game.PlaceId)
    local gid = tostring(game.GameId)
    local specificScript = GAME_DB[id] or GAME_DB[gid]
    local url = specificScript or MODULES.Universal
    local scriptType = specificScript and "Game Module" or "Universal Module"
    
    Notify("AUTHENTICATED", "Welcome! Loading " .. scriptType .. "...", 4)
    local gameScriptFunc = SafeLoad(url, scriptType)
    if gameScriptFunc then task.spawn(gameScriptFunc) end
end

function Core.Init()
    if isfile and isfile(FILE_NAME) then
        local savedKey = string.gsub(readfile(FILE_NAME), "%s+", "")
        print("[FSSHUB DEBUG] Auto-Login dengan key tersimpan: " .. savedKey)
        if Core.ValidateKey(savedKey) then
            Core.LoadGame()
            return
        else
            warn("[FSSHUB DEBUG] Key tersimpan sudah expired/salah.")
            delfile(FILE_NAME) -- Hapus key lama
        end
    end
    
    local authLoader = SafeLoad(MODULES.AuthUI, "Auth UI")
    if authLoader then
        local AuthModule = authLoader()
        if AuthModule and AuthModule.Show then
            AuthModule.Show({
                ValidKey = nil,
                OnSuccess = function(keyInput)
                    if Core.ValidateKey(keyInput) then
                        if writefile then writefile(FILE_NAME, keyInput) end
                        Core.LoadGame()
                        return true
                    else
                        return false
                    end
                end
            })
        end
    end
end

return Core
