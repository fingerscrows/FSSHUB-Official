-- [[ FSSHUB LOADER V5.0 (FIXED) ]] --

if not game:IsLoaded() then game.Loaded:Wait() end

local CORE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/src/Core.lua"

local success, err = pcall(function()
    local coreScript = game:HttpGet(CORE_URL)
    local coreFunc = loadstring(coreScript)
    local CoreModule = coreFunc()
    
    if CoreModule and CoreModule.Init then
        CoreModule.Init()
    else
        warn("[FSSHUB] Core Init not found!")
    end
end)

if not success then
    game.StarterGui:SetCore("SendNotification", {
        Title = "FSSHUB Error",
        Text = "Loader Failed: " .. tostring(err),
        Duration = 5
    })
end
