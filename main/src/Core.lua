-- [[ FSSHUB CORE SYSTEM V3.2 (ANTI-CRASH) ]] --
-- Update: Fixed JSON Crash & Added Debugger

local Core = {}

-- [1] CONFIGURATION
local FILE_NAME = "FSSHUB_V3_Auth.key"
-- MASUKKAN URL GOOGLE APPS SCRIPT BARU DARI LANGKAH 1 DI SINI:
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

-- [SERVER VALIDATION - ANTI CRASH]
function Core.ValidateKey(keyInput)
    if not keyInput or #keyInput < 5 then return false end
    
    -- Request ke Google
    local success, response = pcall(function()
        return game:HttpGet(API_URL .. "?key=" .. keyInput .. "&nocache=" .. math.random(1, 10000))
    end)
    
    if success then
        -- Coba baca sebagai JSON dengan pcall agar tidak crash
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
        
        if decodeSuccess and data then
            -- Jika sukses baca JSON
            if data.status == "success" then
                return true
            end
        else
            -- JIKA GAGAL BACA JSON (Berarti Permission Google Salah / HTML Error)
            warn("------------------------------------------------")
            warn("[FSSHUB DEBUG] CRITICAL ERROR: Server sent HTML instead of JSON!")
            warn("RESPONSE DARI GOOGLE: " .. string.sub(response, 1, 200)) -- Lihat apa isi errornya
            warn("SOLUSI: Pastikan Deployment Google Apps Script diatur ke 'ANYONE'!")
            warn("------------------------------------------------")
        end
    else
        warn("[FSSHUB DEBUG] Connection Failed: " .. tostring(response))
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
    -- Cek file yang tersimpan
    if isfile and isfile(FILE_NAME) then
        local savedKey = string.gsub(readfile(FILE_NAME), "%s+", "")
        if Core.ValidateKey(savedKey) then
            Core.LoadGame()
            return
        end
    end
    
    -- Load UI
    local authLoader = SafeLoad(MODULES.AuthUI, "Auth UI")
    if authLoader then
        local AuthModule = authLoader()
        if AuthModule and AuthModule.Show then
            AuthModule.Show({
                ValidKey = nil,
                OnSuccess = function(keyInput)
                    -- UI memanggil fungsi ini dan MENUNGGU return true/false
                    if Core.ValidateKey(keyInput) then
                        if writefile then writefile(FILE_NAME, keyInput) end
                        Core.LoadGame()
                        return true -- Kirim sinyal SUKSES ke UI
                    else
                        return false -- Kirim sinyal GAGAL ke UI
                    end
                end
            })
        end
    end
end

return Core
