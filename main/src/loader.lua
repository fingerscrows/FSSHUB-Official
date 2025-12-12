-- [[ FSSHUB LOADER V9.3 (FULL INTEGRITY) ]] --
-- Flow: Loader -> Core (Auth) -> UIManager (Builder)
-- Path: main/src/loader.lua

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

-- Anti-Cache dengan os.time() untuk memastikan selalu mendapat update terbaru
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"
local CORE_URL = BASE_URL .. "main/src/Core.lua?v=" .. tostring(os.time())

local function Boot()
    -- Menggunakan pcall untuk menangani error HTTP jika GitHub down
    local success, result = pcall(function()
        return game:HttpGet(CORE_URL)
    end)

    if not success or not result or result == "" then
        game.StarterGui:SetCore("SendNotification", {
            Title = "FSSHUB Boot Failure",
            Text = "Could not reach servers. Check connection.",
            Duration = 5
        })
        warn("[FSSHUB] Failed to fetch Core: " .. tostring(result))
        return
    end

    local coreFunc, err = loadstring(result)
    if not coreFunc then
        game.StarterGui:SetCore("SendNotification", {
            Title = "FSSHUB Syntax Error",
            Text = "Core script error. Check console.",
            Duration = 5
        })
        warn("[FSSHUB] Core Syntax Error:", err)
        return
    end

    local CoreModule = coreFunc()
    if CoreModule and CoreModule.Init then
        CoreModule.Init()
    end
end

task.spawn(Boot)
