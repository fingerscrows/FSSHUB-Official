-- [[ FSSHUB LOADER V2.0 ]] --
-- "Simplicity is the ultimate sophistication"

if not game:IsLoaded() then game.Loaded:Wait() end

local CORE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/src/Core.lua"

local function Boot()
    local success, result = pcall(function()
        return game:HttpGet(CORE_URL)
    end)

    if not success then
        game.StarterGui:SetCore("SendNotification", {
            Title = "FSSHUB Boot Failure",
            Text = "Could not reach servers. Check connection.",
            Duration = 5
        })
        return
    end

    local coreFunc, err = loadstring(result)
    if not coreFunc then
        warn("[FSSHUB] Core Syntax Error:", err)
        return
    end

    local CoreModule = coreFunc()
    if CoreModule and CoreModule.Init then
        CoreModule.Init()
    end
end

task.spawn(Boot)
