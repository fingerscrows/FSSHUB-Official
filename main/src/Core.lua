-- [[ FSSHUB CORE SYSTEM V1.1 (FIXED) ]] --

local Core = {}

-- [1] CONFIGURATION
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" 
local UPDATE_INTERVAL = 6 
local FILE_NAME = "FSS_V5_Key.txt"

-- URL harus persis dengan struktur folder GitHub (Case Sensitive)
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

local MODULES = {
    AuthUI = BASE_URL .. "main/modules/AuthUI.lua",
    -- Pastikan path ini benar. Jika script universal beda file, arahkan ke file yang benar.
    -- Saat ini diarahkan ke SurviveWaveZ sebagai placeholder.
    Universal = BASE_URL .. "main/scripts/SurviveWaveZ.lua" 
}

local GAME_DB = {
    -- ID Game (String agar aman)
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
    local content = nil
    local success = false
    
    -- Retry Logic (3 Attempts)
    for i = 1, 3 do
        local s, res = pcall(function() return game:HttpGet(url) end)
        if s and res and #res > 0 then 
            content = res
            success = true
            break 
        end
        warn("[FSSHUB] Failed to load " .. name .. ". Retrying ("..i.."/3)... URL: " .. url)
        task.wait(1.5)
    end
    
    if not success then
        Notify("Connection Error", "Failed to load " .. name .. ". Check console (F9).", 10)
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
    
    -- Prioritaskan ID spesifik, fallback ke Universal
    local url = GAME_DB[id] or GAME_DB[gid] or MODULES.Universal
    
    Notify("FSS HUB", "Key Verified! Loading Scripts...", 3)
    print("[FSSHUB] Loading Game Script from: ", url)
    
    local gameScriptFunc = SafeLoad(url, "Game Script")
    if gameScriptFunc then
        task.spawn(gameScriptFunc)
    else
        Notify("Error", "Game script not found/empty.", 5)
    end
end

function Core.Init()
    local ValidKey = Core.GetValidKey()
    print("[FSSHUB] Current Valid Key: ", ValidKey) -- Debugging di Console (F9)
    
    -- Check Saved Key
    if isfile and isfile(FILE_NAME) then
        local saved = string.gsub(readfile(FILE_NAME), "%s+", "")
        if saved == ValidKey then
            print("[FSSHUB] Key Found & Valid.")
            Core.LoadGame()
            return
        else
            print("[FSSHUB] Saved key expired/invalid.")
        end
    end
    
    -- Load Auth UI
    local authLoader = SafeLoad(MODULES.AuthUI, "Auth UI")
    if authLoader then
        local AuthModule = authLoader() -- Eksekusi chunk untuk dapat return Table AuthUI
        if AuthModule and AuthModule.Show then
            AuthModule.Show({
                ValidKey = ValidKey,
                OnSuccess = function(key)
                    if writefile then writefile(FILE_NAME, key) end
                    Core.LoadGame()
                end
            })
        else
            Notify("Error", "Auth Module invalid structure.", 5)
        end
    end
end

return Core
