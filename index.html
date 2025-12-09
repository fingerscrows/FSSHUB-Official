-- [[ FSSHUB CORE SYSTEM V1.1 (STABLE) ]] --
-- Update: Added Retry Logic, Better Error Handling, Modular Structure

local Core = {}

-- [1] CONFIGURATION
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" 
local UPDATE_INTERVAL = 6 
local FILE_NAME = "FSS_V5_Key.txt"

-- Repository Base URL (Agar mudah diganti jika pindah repo)
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"
local MODULES = {
    AuthUI = BASE_URL .. "main/modules/AuthUI.lua",
    Universal = BASE_URL .. "main/scripts/SurviveWaveZ.lua"
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
    StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 5})
end

local function SafeLoad(url, name)
    local content, success = nil, false
    -- Retry Logic (3 Attempts)
    for i = 1, 3 do
        local s, res = pcall(function() return game:HttpGet(url) end)
        if s then 
            content = res
            success = true
            break 
        end
        warn("[FSSHUB] Failed to load " .. name .. ". Retrying ("..i.."/3)...")
        task.wait(1.5)
    end
    
    if not success then
        Notify("Connection Error", "Failed to load " .. name .. ". Check internet!", 10)
        return nil
    end
    
    local func, err = loadstring(content)
    if not func then
        warn("[FSSHUB] Syntax Error in " .. name .. ": " .. tostring(err))
        Notify("Script Error", name .. " has syntax errors.", 10)
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
    local url = GAME_DB[id] or GAME_DB[gid] or MODULES.Universal
    
    Notify("FSS HUB", "Key Verified! Loading Scripts...", 3)
    
    local gameScript = SafeLoad(url, "Game Script")
    if gameScript then
        task.spawn(gameScript)
    end
end

function Core.Init()
    local ValidKey = Core.GetValidKey()
    
    -- Check Saved Key
    if isfile and isfile(FILE_NAME) then
        local saved = string.gsub(readfile(FILE_NAME), "%s+", "")
        if saved == ValidKey then
            Core.LoadGame()
            return
        end
    end
    
    -- Load Auth UI
    local authFunc = SafeLoad(MODULES.AuthUI, "Auth UI")
    if authFunc then
        local AuthModule = authFunc() -- Execute to get the Module Table
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
