-- [[ FSSHUB LOADER V9.1 (SECURE MODULAR) ]] --
-- Flow: Loader -> Core (Auth) -> UIManager (Builder)
-- Path: main/src/loader.lua

if not game:IsLoaded() then game.Loaded:Wait() end

-- Anti-Cache dengan ?v=random untuk memastikan selalu mendapat update terbaru
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"
local CORE_URL = BASE_URL .. "main/src/Core.lua?v=" .. tostring(math.random(1, 10000))

local function Boot()
    -- Menggunakan pcall untuk menangani error HTTP jika GitHub down
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
        game.StarterGui:SetCore("SendNotification", {
            Title = "FSSHUB Error",
            Text = "Core script syntax error. Check console.",
            Duration = 5
        })
        return
    end

    local CoreModule = coreFunc()
    if CoreModule and CoreModule.Init then
        CoreModule.Init()
    end
end

task.spawn(Boot)
