-- [[ FSSHUB DATA: UNIVERSAL V6.5 (CLEAN CONFIG) ]] --
-- Changelog: Now uses Icon Keywords
-- Path: main/scripts/Universal.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

if getgenv().FSS_Universal_Stop then
    pcall(getgenv().FSS_Universal_Stop)
end

local State = {
    Speed = 16,
    Jump = 50,
    ESP = false,
    Fullbright = false
}

-- ... Logika fungsi UpdateSpeed, ToggleESP, dll (sama seperti sebelumnya) ...

local function Cleanup()
    -- ... logika cleanup lama ...
    getgenv().FSS_Universal_Stop = nil
end

getgenv().FSS_Universal_Stop = Cleanup

return {
    Name = "Universal V6.5",
    OnUnload = Cleanup,

    Tabs = {
        {
            Name = "Player", 
            Icon = "Player", -- [NEW] Keyword
            Elements = {
                {Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16, Callback = function(v) State.Speed = v end},
                {Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50, Callback = function(v) State.Jump = v end},
            }
        },
        {
            Name = "Visuals", 
            Icon = "Visuals", -- [NEW] Keyword
            Elements = {
                {Type = "Toggle", Title = "Player ESP", Default = false, Callback = function(v) end}, -- Masukkan logika callback asli
                {Type = "Toggle", Title = "Fullbright", Default = false, Callback = function(v) end},
            }
        }
    }
}
