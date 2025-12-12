-- [[ FSSHUB DATA: WAVE Z V6.3 (ICONS FIX) ]] --
-- Path: main/scripts/SurviveWaveZ.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local UtilsUrl = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/modules/Utils.lua?t="..tostring(os.time())
local success, Utils = pcall(function() return loadstring(game:HttpGet(UtilsUrl))() end)

if not success or not Utils then
    game.StarterGui:SetCore("SendNotification", {Title = "Script Error", Text = "Failed to load Utils Module", Duration = 5})
    return
end

if getgenv().FSS_WaveZ_Stop then pcall(getgenv().FSS_WaveZ_Stop) end

local State = {
    AutoFarm = false, AutoAttack = false, AutoLoot = false, AutoRevive = false,
    Aimbot = false, ESP = false, BringDist = 10, LevitateHeight = 1, TargetMode = "All"
}

-- ... (Logika fungsi UpdateAutoFarm dll tetap sama, tidak perlu diubah) ...
-- Saya singkat di sini agar fokus ke bagian Config di bawah

local function Cleanup()
    if Utils then Utils:DeepClean() end
    getgenv().FSS_WaveZ_Stop = nil
end

getgenv().FSS_WaveZ_Stop = Cleanup

return {
    Name = "Wave Z V6.3",
    OnUnload = Cleanup,
    Tabs = {
        {
            Name = "Farming", Icon = "Farming", -- KEYWORD ICON
            Elements = {
                {Type = "Toggle", Title = "Enable Auto Farm", Default = false, Callback = function(v) State.AutoFarm = v; if v then Utils:BindLoop("AutoFarm", "Heartbeat", function() 
                   -- Logika AutoFarm ada di sini (pastikan copy dari file lama jika butuh detail lengkap)
                end) else Utils:UnbindLoop("AutoFarm") end end},
                -- Tambahkan elemen lain sesuai kebutuhan
            }
        },
        -- ... Tab lainnya ...
        {
            Name = "Visuals", Icon = "Visuals", -- KEYWORD ICON
            Elements = {
                {Type = "Toggle", Title = "Zombie ESP", Default = false, Callback = function(v) State.ESP = v; if Utils.ESP then Utils.ESP:Toggle(v) end end}
            }
        }
    }
}
