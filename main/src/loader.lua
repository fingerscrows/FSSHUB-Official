-- [[ FSSHUB LOADER V9.2 (ALWAYS FRESH) ]] --
-- Flow: Loader -> Core (Auth) -> UIManager (Builder)
-- Path: main/src/loader.lua

if not game:IsLoaded() then game.Loaded:Wait() end

-- Gunakan os.time() agar URL selalu unik setiap detik (Anti-Cache Total)
local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"
local CORE_URL = BASE_URL .. "main/src/Core.lua?v=" .. tostring(os.time())

local function Boot()
    local success, result = pcall(function()
        return game:HttpGet(CORE_URL)
    end)

    if not success or not result or result == "" then
        game.StarterGui:SetCore("SendNotification", {
            Title = "FSSHUB Network Error",
            Text = "Gagal terhubung ke GitHub. Cek koneksi internet/VPN.",
            Duration = 5
        })
        warn("[FSSHUB] Failed to fetch Core: " .. tostring(result))
        return
    end

    local coreFunc, err = loadstring(result)
    if not coreFunc then
        game.StarterGui:SetCore("SendNotification", {
            Title = "FSSHUB Syntax Error",
            Text = "Terjadi kesalahan pada script Core. Cek Console (F9).",
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
