-- [[ FSSHUB LOADER V5.0 (FIXED) ]] --

if not game:IsLoaded() then game.Loaded:Wait() end

-- Hapus 'refs/heads/' dari URL agar lebih stabil di raw github
local CORE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/src/Core.lua"

local success, err = pcall(function()
    -- Ambil script sebagai chunk
    local coreScript = game:HttpGet(CORE_URL)
    local coreFunc = loadstring(coreScript)
    
    -- Jalankan chunk untuk mendapatkan Module Table (Core)
    local CoreModule = coreFunc()
    
    -- Panggil fungsi Init() dari Core
    if CoreModule and CoreModule.Init then
        CoreModule.Init()
    else
        warn("[FSSHUB] Core loaded but no Init function found!")
    end
end)

if not success then
    game.StarterGui:SetCore("SendNotification", {
        Title = "FSSHUB Error",
        Text = "Failed to run CORE: " .. tostring(err),
        Duration = 5
    })
    warn("[FSSHUB] Loader Error: " .. tostring(err))
end
