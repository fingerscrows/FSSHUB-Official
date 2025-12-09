-- [[ FSSHUB CORE SYSTEM V3.0 (CLOUD SECURE) ]] --
-- Security Update: Server-Side Validation via Google Apps Script

local Core = {}

-- [1] CONFIGURATION
local FILE_NAME = "FSSHUB_V3_Auth.key"
-- MASUKKAN URL GOOGLE APPS SCRIPT ANDA DI SINI:
local API_URL = "https://script.google.com/macros/s/GANTI_DENGAN_ID_DEPLOYMENT_ANDA/exec" 

local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

local MODULES = {
    AuthUI = BASE_URL .. "main/modules/AuthUI.lua",
    Universal = BASE_URL .. "main/scripts/Universal.lua" 
}

local GAME_DB = {
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
    -- (Biarkan fungsi SafeLoad sama seperti sebelumnya)
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

-- [NEW] SERVER-SIDE CHECK
function Core.ValidateKey(keyInput)
    if not keyInput or #keyInput < 5 then return false end
    
    local success, response = pcall(function()
        -- Mengirim Key ke Google untuk dicek
        return game:HttpGet(API_URL .. "?key=" .. keyInput)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        if data.status == "success" then
            return true
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
    
    Notify("AUTHENTICATED", "Server validated! Loading " .. scriptType .. "...", 4)
    local gameScriptFunc = SafeLoad(url, scriptType)
    if gameScriptFunc then task.spawn(gameScriptFunc) end
end

function Core.Init()
    -- Cek Key yang tersimpan
    if isfile and isfile(FILE_NAME) then
        local savedKey = string.gsub(readfile(FILE_NAME), "%s+", "")
        -- Validasi ulang ke server (agar key expired tidak bisa dipakai)
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
                ValidKey = nil, -- Kita set nil karena validasi sekarang via callback di bawah
                OnSuccess = function(keyInput)
                    -- UI mengirim input user ke sini
                    if Core.ValidateKey(keyInput) then
                        if writefile then writefile(FILE_NAME, keyInput) end
                        Core.LoadGame()
                        return true -- Beri tahu UI bahwa login sukses
                    else
                        return false -- Beri tahu UI bahwa login gagal
                    end
                end
            })
        end
    end
end

return Core
