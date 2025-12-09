-- [[ FSSHUB: SURVIVE WAVE Z (V5.2 OPTIMIZED) ]] --
-- Update: FPS Optimized, Smart Targeting, Dropdown Support

if not game:IsLoaded() then game.Loaded:Wait() end

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load Library V5.2
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local Library = loadstring(game:HttpGet(LIB_URL))()

if not Library then return end

local Win = Library:Window("SURVIVE WAVE Z")

-- CONFIG
local Config = {
    Dist = 8,
    Height = 0,
    AimbotRadius = 200,
    BringMode = "Closest (Anti-Lag)",
    MaxMobs = 15 -- Limit to prevent crash
}

-- [TAB 1: COMBAT]
local Combat = Win:Section("Combat")

Combat:Toggle("Silent Aimbot", false, function(state)
    getgenv().Aimbot = state
    if state then
        RunService.RenderStepped:Connect(function()
            if not getgenv().Aimbot then return end
            
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
    end
end)

Combat:Toggle("Auto Attack", false, function(state)
    getgenv().AutoAttack = state
    task.spawn(function()
        while getgenv().AutoAttack do
            task.wait(0.1) -- Optimized delay
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChildOfClass("Tool") or char:FindFirstChildOfClass("Model")
                    if tool then
                        tool:Activate()
                        if tool:FindFirstChild("Activate") then tool:Activate() end
                    end
                end
            end)
        end
    end)
end)

-- [TAB 2: MOBS]
local Mobs = Win:Section("Mobs")

Mobs:Dropdown("Bring Mode", {"Closest (Anti-Lag)", "All (Risky)"}, "Closest (Anti-Lag)", function(v)
    Config.BringMode = v
end)

Mobs:Toggle("Bring Mobs", false, function(state)
    getgenv().BringMobs = state
    if state then
        RunService.Heartbeat:Connect(function()
            if not getgenv().BringMobs then return end
            
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            local myRoot = char.HumanoidRootPart
            local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * Config.Dist) + Vector3.new(0, Config.Height, 0)
            local zFolder = Workspace:FindFirstChild("ServerZombies")
            
            if zFolder then
                local count = 0
                for _, z in ipairs(zFolder:GetChildren()) do
                    if Config.BringMode == "Closest (Anti-Lag)" and count >= Config.MaxMobs then break end
                    
                    local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
                    local zHum = z:FindFirstChild("Humanoid")
                    
                    if zRoot and zHum and zHum.Health > 0 then
                        -- Check distance: Only bring if within 300 studs to save physics calc
                        if (zRoot.Position - myRoot.Position).Magnitude < 300 then
                            zRoot.CFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
                            zRoot.AssemblyLinearVelocity = Vector3.zero
                            
                            -- Disable collision once
                            if not z:GetAttribute("NoCol") then
                                for _, p in ipairs(z:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
                                z:SetAttribute("NoCol", true)
                            end
                            count = count + 1
                        end
                    end
                end
            end
        end)
    end
end)

Mobs:Slider("Distance", 5, 20, 8, function(v) Config.Dist = v end)

-- [TAB 3: VISUALS]
local Vis = Win:Section("Visuals")

Vis:Toggle("Zombie ESP", false, function(state)
    getgenv().ESP = state
    if state then
        task.spawn(function()
            while getgenv().ESP do
                task.wait(1)
                local zFolder = Workspace:FindFirstChild("ServerZombies")
                if zFolder then
                    for _, z in ipairs(zFolder:GetChildren()) do
                        if z:FindFirstChild("Head") and not z.Head:FindFirstChild("ESP") then
                            local h = Instance.new("Highlight", z)
                            h.Name = "ESP"
                            h.FillColor = Color3.fromRGB(255, 0, 0)
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.5
                        end
                    end
                end
            end
        end)
    else
        -- Cleanup ESP
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if zFolder then
            for _, z in ipairs(zFolder:GetChildren()) do
                if z:FindFirstChild("ESP") then z.ESP:Destroy() end
            end
        end
    end
end)

-- [TAB 4: SETTINGS]
local Settings = Win:Section("Settings")
Settings:Button("Unload Script", function()
    getgenv().Aimbot = false
    getgenv().BringMobs = false
    getgenv().AutoAttack = false
    Win:Destroy()
end)
