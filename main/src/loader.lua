-- [[ FSS HUB V4.1 - SMART LOADER (FIXED) ]] --
-- Update: Integrated with Fixed Library V4.1

if not game:IsLoaded() then game.Loaded:Wait() end

local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" 
local UPDATE_INTERVAL = 6 
local DISCORD_INVITE = "https://discord.gg/28cfy5E3ag"
local FILE_NAME = "FSSHUB_V4_Key.txt"
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"

local GameList = {
    ["92371631484540"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
}
local UNIVERSAL_SCRIPT = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua" 

local StarterGui = game:GetService("StarterGui")

local function SafeLoad(url)
    local content, success = nil, false
    for i = 1, 3 do
        local s, res = pcall(function() return game:HttpGet(url) end)
        if s then content = res; success = true; break end
        task.wait(1)
    end
    if success then
        local func, err = loadstring(content)
        if func then task.spawn(func) else warn("Script Error: "..tostring(err)) end
    else
        warn("Failed to load script: "..url)
    end
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

local function GetValidKey()
    local now = os.time()
    local block = math.floor(math.floor(now / 3600) / UPDATE_INTERVAL)
    local hash = djb2Hash(block .. "-" .. SECRET_SALT)
    return "KEY-" .. hash
end

local function Init()
    local s, Library = pcall(function() return loadstring(game:HttpGet(LIB_URL))() end)
    if not s or not Library then 
        return StarterGui:SetCore("SendNotification", {Title = "FSS HUB", Text = "Failed to load Library!", Duration = 5}) 
    end

    local function RunGame()
        local id = tostring(game.PlaceId)
        local gid = tostring(game.GameId)
        local scriptUrl = GameList[id] or GameList[gid] or UNIVERSAL_SCRIPT
        Library:Notify("Key Verified! Loading Script...", "success")
        task.wait(1)
        SafeLoad(scriptUrl)
    end

    local ValidKey = GetValidKey()
    if isfile and isfile(FILE_NAME) then
        local saved = string.gsub(readfile(FILE_NAME), "%s+", "")
        if saved == ValidKey then
            Library:Notify("Auto-Login Successful!", "success")
            RunGame()
            return
        end
    end

    Library:AuthWindow({
        Title = "FSS HUB | GATEWAY",
        Status = "Enter key to access script",
        GetKeyLink = DISCORD_INVITE,
        OnLogin = function(inputKey)
            local cleanInput = string.gsub(inputKey, "%s+", "")
            if cleanInput == ValidKey then
                if writefile then writefile(FILE_NAME, cleanInput) end
                RunGame()
                return true
            else
                return false
            end
        end
    })
end

Init()
