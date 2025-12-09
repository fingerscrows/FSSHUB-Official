-- [[ FSSHUB CORE SYSTEM V3.1 (STABLE) ]] --
-- Update: New API Endpoint & JSON Safety Check

local Core = {}

-- [1] CONFIGURATION
local FILE_NAME = "FSSHUB_V3_Auth.key"
-- URL GOOGLE APPS SCRIPT BARU KAMU
local API_URL = "https://script.google.com/macros/s/AKfycbw9JrYXbQ-nXZsF75KJRDy1dCgPl0WYDRgk3zwuE5WlYW8P5UrIrb6WyRvxB20HI7D5iQ/exec" 

local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

local MODULES = {
    AuthUI = BASE_URL .. "main/modules/AuthUI.lua",
    Universal = BASE_URL .. "main/scripts/Universal.lua" 
}

local GAME_DB = {
    -- ID Game Survive Wave Z
    ["92371631484540"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua"
}

-- SERVICES
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- [2] UTILITIES
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
    
    if not success then
        Notify("Connection Error", "Failed to load " .. name, 10)
        return nil
    end
    
    local func, err = loadstring(content)
    if not func then
        Notify("Syntax Error", name .. ": " .. tostring(err), 10)
        return nil
    end
    return func
end

-- [IMPROVED] SERVER-SIDE CHECK
function Core.ValidateKey(keyInput)
    if not keyInput or #keyInput < 5 then return false end
    
    local success, response = pcall(function()
        -- Mengirim Key ke Google untuk dicek (tambah nocache agar tidak nyangkut data lama)
        return game:HttpGet(API_URL .. "?key=" .. keyInput .. "&nocache=" .. math.random())
    end)
    
    if success then
        -- Coba decode JSON dengan aman
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
        
        if decodeSuccess and data then
            if data.status == "success" then
                return true
            end
        else
            -- Debugging jika respon bukan JSON (biasanya HTML error dari Google)
            warn("[FSSHUB DEBUG] Server Response Invalid:")
            warn(string.sub(response, 1, 100))
        end
    end
    return false
end

-- [3] MAIN LOGIC
function Core.LoadGame()
    local id = tostring(game.PlaceId)
    local gid = tostring(game.GameId)
    
    local specificScript = GAME_DB[id] or GAME_DB[gid]
    local url = specificScript or MODULES.Universal
    local scriptType = specificScript and "Game Module" or "Universal Module"
    
    Notify("AUTHENTICATED", "Welcome! Loading " .. scriptType .. "...", 4)
    
    local gameScriptFunc = SafeLoad(url, scriptType)
    if gameScriptFunc then 
        task.spawn(gameScriptFunc) 
    end
end

function Core.Init()
    -- Cek Key yang tersimpan
    if isfile and isfile(FILE_NAME) then
        local savedKey = string.gsub(readfile(FILE_NAME), "%s+", "")
        -- Validasi ulang ke server
        if Core.ValidateKey(savedKey) then
            Core.LoadGame()
            return
        end
    end
    
    -- Load Auth UI
    local authLoader = SafeLoad(MODULES.AuthUI, "Auth UI")
    if authLoader then
        local AuthModule = authLoader()
        if AuthModule and AuthModule.Show then
            AuthModule.Show({
                ValidKey = nil, -- Validasi via server callback
                OnSuccess = function(keyInput)
                    if Core.ValidateKey(keyInput) then
                        if writefile then writefile(FILE_NAME, keyInput) end
                        Core.LoadGame()
                        return true -- Beritahu UI login sukses
                    else
                        return false -- Beritahu UI login gagal
                    end
                end
            })
        end
    end
end

return Core
