-- [[ FSSHUB: SURVIVE WAVE Z SCRIPT ]] --

-- LOAD LIBRARY
-- Pastikan LINK INI benar mengarah ke FSSHUB_Lib.lua (Raw)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"))()
local Win = Library:Window("FSSHUB | Survive Wave Z")

-- SERVICES & VARS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local dist, height = 10, 1

-- [[ GAME FEATURES ]] --

Win:Section("COMBAT")
Win:Toggle("Aimbot (Head)", false, function(t)
    local aimbotOn = t
    if t then
        local aimConnection = RunService.RenderStepped:Connect(function()
            if not aimbotOn then return end
            local closestHead, minMag = nil, math.huge
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            if Workspace:FindFirstChild("ServerZombies") then
                for _, v in pairs(Workspace.ServerZombies:GetDescendants()) do
                    if v.Name == "Head" and v.Parent:FindFirstChild("Humanoid") and v.Parent.Humanoid.Health > 0 then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(v.Position)
                        if onScreen then
                            local mag = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if mag < minMag and mag < 300 then minMag = mag; closestHead = v end
                        end
                    end
                end
            end
            if closestHead then Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestHead.Position) end
        end)
        table.insert(Library.ActiveConnections, aimConnection)
    end
end)

Win:Toggle("Auto Attack", false, function(t)
    local shootOn = t
    if not t then if LocalPlayer.Character then local g = LocalPlayer.Character:FindFirstChildOfClass("Model"); if g then g:SetAttribute("IsShooting", false) end end end
    if t then
        spawn(function()
            while shootOn do
                task.wait()
                if LocalPlayer.Character then
                    local gun = LocalPlayer.Character:FindFirstChildOfClass("Model")
                    if gun and Workspace:FindFirstChild("ServerZombies") then
                        gun:SetAttribute("IsShooting", true)
                        if gun:FindFirstChild("Activate") then gun:Activate() end
                        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool"); if tool then tool:Activate() end
                        task.wait(); gun:SetAttribute("IsShooting", false)
                    end
                end
            end
        end)
    end
end)

Win:Section("MOBS")
Win:Toggle("Bring Mobs", false, function(t)
    local bringOn = t
    if t then
        local connection = RunService.Heartbeat:Connect(function()
            if not bringOn then return end
            pcall(function()
                local zFolder = Workspace:FindFirstChild("ServerZombies") or Workspace
                for _,z in pairs(zFolder:GetDescendants()) do
                    if z.Name=="Humanoid" and z.Health>0 and z.RootPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local myRoot = LocalPlayer.Character.HumanoidRootPart; local zRoot = z.RootPart
                        local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * dist) + Vector3.new(0, height, 0)
                        zRoot.CFrame = CFrame.lookAt(targetPos, myRoot.Position) * CFrame.Angles(math.rad(-90), 0, 0)
                        zRoot.Anchored = false; z.PlatformStand = true; z:ChangeState(Enum.HumanoidStateType.Physics)
                        zRoot.AssemblyLinearVelocity = Vector3.new(0,0,0); zRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
                        for _, p in pairs(z.Parent:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
                    end
                end
            end)
        end)
        table.insert(Library.ActiveConnections, connection)
    else
        pcall(function()
            local zFolder = Workspace:FindFirstChild("ServerZombies") or Workspace
            for _,z in pairs(zFolder:GetDescendants()) do
                if z.Name=="Humanoid" and z.RootPart then z.PlatformStand = false; z:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end
        end)
    end
end)
Win:Slider("Distance", 1, 20, 10, function(v) dist = v end, false)
Win:Slider("Height", -5, 5, 1, function(v) height = v end, false)

Win:Section("PLAYER")
Win:Toggle("Auto Loot", false, function(t)
    local collectOn = t
    if t then
        spawn(function()
            while collectOn do
                task.wait()
                for _,p in pairs(Workspace:GetChildren()) do
                    if not collectOn then break end
                    local n = p.Name
                    if (n == "RewardChest" or n == "AmmoBox" or n == "MysteryBox" or n == "Pickup" or (p:IsA("Part") and not p.Anchored and n~="CharacterImpact")) then
                         pcall(function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then p.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame end end)
                    end
                end
            end
        end)
    end
end)

Win:Toggle("Auto Revive", false, function(t)
    local reviveOn = t
    if t then
        spawn(function()
            while reviveOn do
                task.wait(0.2) 
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                         for _, plr in pairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and plr.Character then
                                local tHum = plr.Character:FindFirstChild("Humanoid")
                                if tHum and tHum.Health <= 0 then
                                    local prompt = nil
                                    for _, v in pairs(plr.Character:GetDescendants()) do if v:IsA("ProximityPrompt") then prompt = v break end end
                                    if prompt then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = (prompt.Parent and prompt.Parent.CFrame or plr.Character.HumanoidRootPart.CFrame) + Vector3.new(0,3,0)
                                        task.wait(0.2); prompt.HoldDuration = 0; fireproximityprompt(prompt, 1, true)
                                    end
                                end
                            end
                         end
                    end
                end)
            end
        end)
    end
end)
Win:Slider("HipHeight", 2, 50, 2, function(v) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.HipHeight = v end end, false)

Win:Section("VISUAL")
Win:Toggle("ESP Head", false, function(t)
    local espOn = t
    if t then
        spawn(function()
            while espOn do
                task.wait(0.5)
                if Workspace:FindFirstChild("ServerZombies") then
                    for _, z in pairs(Workspace.ServerZombies:GetDescendants()) do
                        if z.Name == "Head" and z.Parent:FindFirstChild("Humanoid") and z.Parent.Humanoid.Health > 0 then
                            if not z:FindFirstChild("H_ESP") then
                                local b = Instance.new("BoxHandleAdornment", z); b.Name = "H_ESP"; b.Adornee = z; b.Size = z.Size; b.Color3 = Color3.new(1,0,0); b.AlwaysOnTop = true; b.Transparency = 0.5; b.ZIndex = 5
                            end
                        end
                    end
                end
            end
        end)
    else
        if Workspace:FindFirstChild("ServerZombies") then for _, z in pairs(Workspace.ServerZombies:GetDescendants()) do if z:FindFirstChild("H_ESP") then z.H_ESP:Destroy() end end end
    end
end)

-- SETUP SETTINGS
Win:CreateConfigSystem("https://discord.gg/28cfy5E3ag")
Win:CheckAutoload()

-- [[ PERBAIKAN: TOGGLE HIDE UI (RIGHT CTRL) ]] --
local ToggleKey = Enum.KeyCode.RightControl
local LibName = "FSSHUB_Final" -- Nama UI di Library
local UIVisible = true

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == ToggleKey then
        UIVisible = not UIVisible
        
        -- Cari UI dengan metode yang lebih kuat (Support gethui)
        local TargetUI = nil
        
        -- Coba cari di hidden UI service (gethui)
        if gethui then
            TargetUI = gethui():FindFirstChild(LibName)
        end
        
        -- Jika tidak ketemu (atau executor tidak support gethui), cari di CoreGui standar
        if not TargetUI then
            TargetUI = game:GetService("CoreGui"):FindFirstChild(LibName)
        end
        
        -- Terakhir, cari di PlayerGui (untuk executor mobile tertentu)
        if not TargetUI then
            TargetUI = LocalPlayer.PlayerGui:FindFirstChild(LibName)
        end
        
        if TargetUI then
            TargetUI.Enabled = UIVisible
        end
    end
end)

-- Notifikasi info Keybind
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "FSSHUB Loaded";
    Text = "Press [Right Ctrl] to Hide/Show Menu";
    Duration = 5;
})
