-- [[ FSSHUB DATA: UNIVERSAL V3.1 ]] --
-- FILE INI TIDAK BOLEH ADA KODE UI SEPERTI 'Library:Window'
-- HANYA BOLEH BERISI LOGIKA GAME DAN RETURN TABLE

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- 1. State Variables
local State = {
    Speed = 16,
    Jump = 50,
    SpeedEnabled = false,
    JumpEnabled = false,
    Noclip = false,
    Fullbright = false,
    Connections = {}
}

-- 2. Logic Functions
local function UpdateSpeed()
    while State.SpeedEnabled do
        task.wait()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                if LocalPlayer.Character.Humanoid.WalkSpeed ~= State.Speed then
                    LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed
                end
            end
        end)
    end
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
end

local function UpdateJump()
    while State.JumpEnabled do
        task.wait()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.UseJumpPower = true
                if LocalPlayer.Character.Humanoid.JumpPower ~= State.Jump then
                    LocalPlayer.Character.Humanoid.JumpPower = State.Jump
                end
            end
        end)
    end
    pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end)
end

local function ToggleNoclip(active)
    if active then
        local conn = RunService.Stepped:Connect(function()
            if State.Noclip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
        table.insert(State.Connections, conn)
    end
end

-- 3. Return Configuration Table
return {
    Name = "Universal V3.1",
    
    OnUnload = function()
        State.SpeedEnabled = false
        State.JumpEnabled = false
        State.Noclip = false
        State.Fullbright = false
        for _, c in pairs(State.Connections) do c:Disconnect() end
    end,

    Tabs = {
        -- [TAB: LOCAL PLAYER]
        {
            Name = "Local Player",
            Icon = "10888331510",
            Elements = {
                {
                    Type = "Toggle", Title = "Enable Speed", Default = false, Keybind = Enum.KeyCode.V,
                    Callback = function(val)
                        State.SpeedEnabled = val
                        if val then task.spawn(UpdateSpeed) end
                    end
                },
                {
                    Type = "Slider", Title = "WalkSpeed", Min = 16, Max = 300, Default = 16,
                    Callback = function(val) State.Speed = val end
                },
                {
                    Type = "Toggle", Title = "Enable Jump", Default = false,
                    Callback = function(val)
                        State.JumpEnabled = val
                        if val then task.spawn(UpdateJump) end
                    end
                },
                {
                    Type = "Slider", Title = "JumpPower", Min = 50, Max = 400, Default = 50,
                    Callback = function(val) State.Jump = val end
                },
                {
                    Type = "Toggle", Title = "Noclip", Default = false,
                    Callback = function(val)
                        State.Noclip = val
                        ToggleNoclip(val)
                    end
                }
            }
        },
        -- [TAB: VISUALS]
        {
            Name = "Visuals",
            Icon = "10888332158",
            Elements = {
                {
                    Type = "Toggle", Title = "Fullbright", Default = false,
                    Callback = function(val)
                        State.Fullbright = val
                        if val then
                            task.spawn(function()
                                while State.Fullbright do
                                    Lighting.Brightness = 2; Lighting.ClockTime = 14
                                    Lighting.GlobalShadows = false
                                    task.wait(1)
                                end
                            end)
                        else
                            Lighting.GlobalShadows = true
                        end
                    end
                }
            }
        },
        -- [TAB: MISC]
        {
            Name = "Misc",
            Icon = "10888332462",
            Elements = {
                {
                    Type = "Button", Title = "Rejoin Server",
                    Callback = function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                    end
                }
            }
        }
    }
}
