-- [[ FSSHUB CORE V6 (HWID SYSTEM) ]] --

local Core = {}
local FILE_NAME = "FSSHUB_V6.key"
local API_URL = "https://script.google.com/macros/s/AKfycbw9JrYXbQ-nXZsF75KJRDy1dCgPl0WYDRgk3zwuE5WlYW8P5UrIrb6WyRvxB20HI7D5iQ/exec"

local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

-- Fungsi Get HWID
local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN"
end

function Core.ValidateKey(input)
    if not input or #input < 5 then return false end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    local hwid = GetHWID()
    
    -- Request Verify ke Server dengan HWID
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&nocache=" .. math.random()
    
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
    if success then
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok and data.status == "success" then
            return true
        else
            if data and data.message then warn("[FSSHUB] " .. data.message) end
        end
    end
    return false
end

-- ... (Sisanya sama: Init, LoadGame, dll) ...
