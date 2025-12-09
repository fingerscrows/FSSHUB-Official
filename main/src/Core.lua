-- [[ FSSHUB CORE SYSTEM V2.0 (PURPLE HEART) ]] --
-- Updated: Enhanced Security & New Notification Style

local Core = {}

-- [1] CONFIGURATION
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" 
local UPDATE_INTERVAL = 6 
local FILE_NAME = "FSSHUB_V2_Auth.key" -- Nama file baru untuk membedakan versi

-- BASE URL (Sesuaikan dengan repo kamu)
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

local MODULES = {
    AuthUI = BASE_URL .. "main/modules/AuthUI.lua",
    Universal = BASE_URL .. "main/scripts/Universal.lua" 
}

local GAME_DB = {
    -- Survive Wave Z
    ["92371631484540"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = BASE_URL .. "main/scripts/SurviveWaveZ.lua"
}

-- SERVICES
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- [2] UTILITIES
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, 
            Text = text, 
            Duration = duration or 5,
            Icon = "rbxassetid://106566838686629" -- Ikon Ungu (jika ada) atau kosongkan
        })
    end)
end

local function SafeLoad(url, name)
    local content, success = nil, false
    for i = 1, 3 do
        local s, res = pcall(function() return game:HttpGet(url) end)
        if s and res and #res > 0 then content = res; success = true; break end
        warn("[FSSHUB] Retrying " .. name .. " ("..i.."/3)...")
        task.wait(1)
    end
    
    if not success then
        Notify("FSSHUB Error", "Failed to load " .. name .. ". Check console.", 10)
        return nil
    end
    
    local func, err = loadstring(content)
    if not func then
        Notify("Syntax Error", name .. ": " .. tostring(err), 10)
        return nil
    end
    return func
end

local function djb2Hash(str)
    local hash = 5381
    for i = 1, #str do
        local byte = string.byte(str, i)
        hash = (hash * 33) + byte
        hash = hash % 4294967296 
    end
    return string.upper(string.format("%x", hash))
end

function Core.GetValidKey()
    local now = os.time()
    local block = math.floor(math.floor(now / 3600) / UPDATE_INTERVAL)
    local hash = djb2Hash(block .. "-" .. SECRET_SALT)
    return "KEY-" .. hash
end

-- [3] MAIN LOGIC
function Core.LoadGame()
    local id = tostring(game.PlaceId)
    local gid = tostring(game.GameId)
    
    -- Smart Detection
    local specificScript = GAME_DB[id] or GAME_DB[gid]
    local url = specificScript or MODULES.Universal
    local scriptType = specificScript and "Game Module" or "Universal Module"
    
    Notify("ACCESS GRANTED", "Welcome to FSSHUB V2\nLoading " .. scriptType .. "...", 4)
    
    local gameScriptFunc = SafeLoad(url, scriptType)
    if gameScriptFunc then 
        task.spawn(gameScriptFunc) 
    end
end

function Core.Init()
    local ValidKey = Core.GetValidKey()
    
    -- Auto Login Logic
    if isfile and isfile(FILE_NAME) then
        local saved = string.gsub(readfile(FILE_NAME), "%s+", "")
        if saved == ValidKey then
            Core.LoadGame()
            return
        end
    end
    
    -- Load Auth UI (Jika belum login)
    local authLoader = SafeLoad(MODULES.AuthUI, "Auth UI")
    if authLoader then
        local AuthModule = authLoader()
        if AuthModule and AuthModule.Show then
            AuthModule.Show({
                ValidKey = ValidKey,
                OnSuccess = function(key)
                    if writefile then writefile(FILE_NAME, key) end
                    Core.LoadGame()
                end
            })
        end
    end
end

return Core
