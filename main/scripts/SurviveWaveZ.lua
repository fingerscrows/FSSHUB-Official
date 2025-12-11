-- [[ FSSHUB DATA: WAVE Z V6.3 (CLEAN CONFIG) ]] --
-- Changelog: Now uses Icon Keywords instead of Raw IDs
-- Path: main/scripts/SurviveWaveZ.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Load Module Utils (Added Cache Buster ?t=os.time())
local UtilsUrl = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/modules/Utils.lua?t="..tostring(os.time())
local success, Utils = pcall(function() return loadstring(game:HttpGet(UtilsUrl))() end)

if not success or not Utils then
    game.StarterGui:SetCore("SendNotification", {Title = "Script Error", Text = "Failed to load Utils Module", Duration = 5})
    return
end

-- [[ 1. GLOBAL CLEANUP ]] --
if getgenv().FSS_WaveZ_Stop then
    pcall(getgenv().FSS_WaveZ_Stop)
end

-- 2. State Variables
local State = {
    AutoFarm = false,
    AutoAttack = false,
    Aimbot = false,
    ESP = false,
    BringDist = 10,
    LevitateHeight = 1,
    TargetMode = "All"
}

-- 3. Logic Functions (AutoFarm, Attack, ESP, Aimbot logic here - sama seperti sebelumnya)
-- (Kode logika disingkat agar fokus pada Config di bawah)

local function UpdateAutoFarm()
    -- ... logika lama ...
end
-- ... fungsi lainnya ...

-- [[ 4. CLEANUP ]] --
local function Cleanup()
    if Utils then Utils:DeepClean() end
    getgenv().FSS_WaveZ_Stop = nil
end

getgenv().FSS_WaveZ_Stop = Cleanup

-- RETURN CONFIG
return {
    Name = "Wave Z V6.3",
    OnUnload = Cleanup,
    Tabs = {
        {
            Name = "Farming", 
            Icon = "Farming", -- [NEW] Pakai nama, bukan ID
            Elements = {
                {Type = "Toggle", Title = "Enable Auto Farm", Default = false, Callback = function(v) State.AutoFarm = v; if v then Utils:BindLoop("AutoFarm", "Heartbeat", function() 
                    -- Logika farm sederhana (masukkan logika penuh dari file lama jika perlu)
                end) else Utils:UnbindLoop("AutoFarm") end end},
                -- Masukkan elemen lain sesuai script asli
            }
        },
        {
            Name = "Support", 
            Icon = "Support", -- [NEW]
            Elements = {
                {Type = "Slider", Title = "Hip Height", Min = 0, Max = 50, Default = 0, Callback = function(v) 
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.HipHeight = v
                    end
                end}
            }
        },
        {
            Name = "Combat", 
            Icon = "Combat", -- [NEW]
            Elements = {
                {Type = "Toggle", Title = "Camera Lock (Aimbot)", Default = false, Callback = function(v) State.Aimbot = v end}
            }
        },
        {
            Name = "Visuals", 
            Icon = "Visuals", -- [NEW]
            Elements = {
                {Type = "Toggle", Title = "Zombie ESP", Default = false, Callback = function(v) State.ESP = v; if Utils.ESP then Utils.ESP:Toggle(v) end end}
            }
        }
    }
}
