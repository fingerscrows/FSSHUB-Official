-- [[ FSSHUB LOADER V5.0 (ENTRY POINT) ]] --
-- Script ini hanya bertugas memanggil CORE system.

if not game:IsLoaded() then game.Loaded:Wait() end

local CORE_URL = "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/refs/heads/main/main/src/Core.lua"

local success, err = pcall(function()
    loadstring(game:HttpGet(CORE_URL))()
end)

if not success then
    game.StarterGui:SetCore("SendNotification", {
        Title = "FSSHUB Error",
        Text = "Failed to load CORE. Check Connection!",
        Duration = 5
    })
    warn("[FSSHUB] Loader Error: " .. tostring(err))
end

