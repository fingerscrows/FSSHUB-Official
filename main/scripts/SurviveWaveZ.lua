-- [[ FSSHUB: SURVIVE WAVE Z (V5.0 MODULAR) ]] --
-- Update: Support for Library V5.1 (Tabs & Config System)

-- 1. INITIALIZATION
if not game:IsLoaded() then game.Loaded:Wait() end

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load Library V5.1 (Main Menu Only)
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local success, Library
for i = 1, 3 do
    local s, res = pcall(function() return loadstring(game:HttpGet(LIB_URL))() end)
    if s then success = true; Library = res; break end
    task.wait(1)
end

if not success or not Library then
    return StarterGui:SetCore("SendNotification", {Title = "FSSHUB ERROR", Text = "Library Failed to Load!", Duration = 5})
end

-- 2. CREATE WINDOW
local Win = Library:Window("SURVIVE WAVE Z")

-- 3. GAME VARIABLES
local Config = {
    Dist = 10,
    Height = 1,
    AimbotRadius = 300,
    HipHeight = 0
}

-- 4. FEATURES & TABS

-- [TAB 1: COMBAT]
local Combat = Win:Section("Combat")

Combat:Toggle("Silent Aimbot", false, function(state)
    local aimbotOn = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            if not aimbotOn then return end
            
            local closest, minMag = nil, Config.AimbotRadius
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            
            local zFolder = Workspace:FindFirstChild("ServerZombies")
            if zFolder then
                for _, z in ipairs(zFolder:GetChildren()) do
                    local head = z:FindFirstChild("Head")
                    local hum = z:FindFirstChild("Humanoid")
                    if head and hum and hum.Health > 0 then
                        local pos, vis = Camera:WorldToViewportPoint(head.Position)
                        if vis then
                            local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if mag < minMag then minMag = mag; closest = head end
                        end
                    end
                end
            end
            
            if closest then Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position) end
        end)
        table.insert(FSSHUB.Connections, conn)
    end
end)

Combat:Toggle("Auto Attack", false, function(state)
    local attacking = state
    -- Cleanup Attribute
    if not state and LocalPlayer.Character then
        local gun = LocalPlayer.Character:FindFirstChildOfClass("Model")
        if gun then gun:SetAttribute("IsShooting", false) end
    end

    if state then
        task.spawn(function()
            while attacking do
                task.wait()
                if LocalPlayer.Character then
                    local gun = LocalPlayer.Character:FindFirstChildOfClass("Model")
                    if gun and gun:FindFirstChild("Handle") then
                         gun:SetAttribute("IsShooting", true)
                         if gun:FindFirstChild("Activate") then gun:Activate() end
                         local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                         if tool then tool:Activate() end
                    end
                end
            end
            -- Cleanup loop end
            if LocalPlayer.Character then
                local gun = LocalPlayer.Character:FindFirstChildOfClass("Model")
                if gun then gun:SetAttribute("IsShooting", false) end
            end
        end)
    end
end)

-- [TAB 2: MOBS]
local Mobs = Win:Section("Mobs")

Mobs:Toggle("Bring Mobs", false, function(state)
    local bring = state
    if state then
        local conn = RunService.Heartbeat:Connect(function()
            if not bring then return end
            
            local zFolder = Workspace:FindFirstChild("ServerZombies")
            if not zFolder then return end
            
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            local myPos = char.HumanoidRootPart.Position
            local targetPos = char.HumanoidRootPart.CFrame.Position + (char.HumanoidRootPart.CFrame.LookVector * Config.Dist) + Vector3.new(0, Config.Height, 0)
            
            for _, z in ipairs(zFolder:GetChildren()) do
                local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
                local zHum = z:FindFirstChild("Humanoid")
                
                -- Limit Radius 250 studs to prevent lag
                if zRoot and zHum and zHum.Health > 0 and (zRoot.Position - myPos).Magnitude < 250 then
                    zRoot.CFrame = CFrame.lookAt(targetPos, myPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    zRoot.AssemblyLinearVelocity = Vector3.zero
                    zRoot.AssemblyAngularVelocity = Vector3.zero
                    
                    if not z:GetAttribute("NoCol") then
                        for _, p in ipairs(z:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
                        z:SetAttribute("NoCol", true)
                    end
                end
            end
        end)
        table.insert(FSSHUB.Connections, conn)
    end
end)

Mobs:Slider("Distance", 5, 20, 10, function(v) Config.Dist = v end)
Mobs:Slider("Height", -5, 5, 1, function(v) Config.Height = v end)

-- [TAB 3: PLAYER]
local Player = Win:Section("Player")

Player:Toggle("Auto Loot", false, function(state)
    local loot = state
    if state then
        task.spawn(function()
            while loot do
                task.wait(0.2)
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    for _, p in ipairs(Workspace:GetChildren()) do
                        if not loot then break end
                        if p.Name == "RewardChest" or p.Name == "AmmoBox" or p.Name == "MysteryBox" or p.Name == "Pickup" then
                             if p:IsA("Model") and p.PrimaryPart then p:SetPrimaryPartCFrame(root.CFrame)
                             elseif p:IsA("Part") then p.CFrame = root.CFrame end
                        end
                    end
                end
            end
        end)
    end
end)

Player:Toggle("Auto Revive", false, function(state)
    local revive = state
    if state then
        task.spawn(function()
            while revive do
                task.wait(0.5)
                pcall(function()
                    if LocalPlayer.Character then
                         for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and plr.Character then
                                local hum = plr.Character:FindFirstChild("Humanoid")
                                if hum and hum.Health <= 0 then
                                    local prompt = plr.Character:FindFirstChild("RevivePrompt", true)
                                    if prompt then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.2)
                                        fireproximityprompt(prompt, 1, true)
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

Player:Slider("Hip Height", 0, 25, 0, function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.HipHeight = v
    end
end)

-- [TAB 4: VISUALS]
local Vis = Win:Section("Visuals")

Vis:Toggle("Zombie ESP", false, function(state)
    local esp = state
    if state then
        task.spawn(function()
            while esp do
                task.wait(1)
                local zFolder = Workspace:FindFirstChild("ServerZombies")
                if zFolder then
                    for _, z in ipairs(zFolder:GetChildren()) do
                        local head = z:FindFirstChild("Head")
                        local hum = z:FindFirstChild("Humanoid")
                        if head and hum and hum.Health > 0 and not head:FindFirstChild("ESP") then
                            local b = Instance.new("BoxHandleAdornment", head)
                            b.Name = "ESP"; b.Adornee = head; b.Size = head.Size; b.Color3 = Color3.fromRGB(255, 0, 0)
                            b.AlwaysOnTop = true; b.Transparency = 0.4; b.ZIndex = 5
                        end
                    end
                end
            end
        end)
    else
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if zFolder then
            for _, z in ipairs(zFolder:GetChildren()) do
                if z:FindFirstChild("Head") and z.Head:FindFirstChild("ESP") then z.Head.ESP:Destroy() end
            end
        end
    end
end)

-- [TAB 5: SETTINGS]
-- Library V5.1 memiliki fungsi built-in untuk config
Win:InitConfig("https://discord.gg/28cfy5E3ag")
