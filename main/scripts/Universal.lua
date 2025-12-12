-- [[ FSSHUB DATA: UNIVERSAL V6.6 (FULL RESTORE) ]] --
-- Changelog: Restored all physics/visual features
-- Path: main/scripts/Universal.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

if getgenv().FSS_Universal_Stop then pcall(getgenv().FSS_Universal_Stop) end

local State = {Speed = 16, Jump = 50, InfJump = false, Noclip = false, Spinbot = false, ESP = false, Fullbright = false}
local Connections = {}

-- [[ LOGIC FUNCTIONS ]] --
local function UpdateSpeed()
    while State.SpeedEnabled do
        task.wait()
        pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed end)
    end
end

local function UpdateJump()
    while State.JumpEnabled do
        task.wait()
        pcall(function() LocalPlayer.Character.Humanoid.JumpPower = State.Jump end)
    end
end

local function ToggleNoclip(active)
    State.Noclip = active
    if active then
        local c = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end)
        table.insert(Connections, c)
    end
end

local function ToggleESP(active)
    State.ESP = active
    if active then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hl = Instance.new("Highlight", p.Character)
                hl.Name = "FSS_ESP"
                hl.FillColor = Color3.fromRGB(140, 80, 255)
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("FSS_ESP") then
                p.Character.FSS_ESP:Destroy()
            end
        end
    end
end

local function Cleanup()
    State.SpeedEnabled = false
    State.JumpEnabled = false
    State.Noclip = false
    State.ESP = false
    ToggleESP(false)
    for _, c in pairs(Connections) do c:Disconnect() end
    getgenv().FSS_Universal_Stop = nil
end

getgenv().FSS_Universal_Stop = Cleanup

return {
    Name = "Universal V6.6",
    OnUnload = Cleanup,
    Tabs = {
        {
            Name = "Player", Icon = "Player",
            Elements = {
                {Type = "Toggle", Title = "Enable WalkSpeed", Default = false, Callback = function(v) State.SpeedEnabled = v; if v then task.spawn(UpdateSpeed) end end},
                {Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16, Callback = function(v) State.Speed = v end},
                {Type = "Toggle", Title = "Enable JumpPower", Default = false, Callback = function(v) State.JumpEnabled = v; if v then task.spawn(UpdateJump) end end},
                {Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50, Callback = function(v) State.Jump = v end},
                {Type = "Toggle", Title = "Noclip", Default = false, Callback = ToggleNoclip},
            }
        },
        {
            Name = "Visuals", Icon = "Visuals",
            Elements = {
                {Type = "Toggle", Title = "Player ESP", Default = false, Callback = ToggleESP},
                {Type = "Toggle", Title = "Fullbright", Default = false, Callback = function(v) Lighting.Brightness = v and 2 or 1 end},
            }
        }
    }
}
