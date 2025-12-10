-- [[ FSSHUB: SURVIVE WAVE Z (PREMIUM V10) ]] --
-- Updated: Icons, Watermark, & Keybinds

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load Library
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local Library = loadstring(game:HttpGet(LIB_URL))()

if not Library then return end

-- Init GUI & Watermark
Library:Init()
Library:Watermark("FSSHUB Premium | Wave Z V2.0")

local Window = Library:Window("WAVE Z | PRO")

-- State Management
getgenv().FSS_WaveZ = {
    Aimbot = false, AutoFarm = false, SafeHealth = true,
    MinHealth = 30, BringDist = 8, TargetMode = "All",
    Connections = {}
}

-- [TAB 1: AUTO FARM]
local FarmTab = Window:Section("Auto Farm", "10888331510") -- User Icon

FarmTab:Toggle("Enable Auto Farm", false, function(state)
    getgenv().FSS_WaveZ.AutoFarm = state
    
    if state then
        local conn = RunService.Heartbeat:Connect(function()
            if not getgenv().FSS_WaveZ.AutoFarm then return end
            
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            local zFolder = Workspace:FindFirstChild("ServerZombies")
            if not zFolder then return end

            local myRoot = char.HumanoidRootPart
            local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * getgenv().FSS_WaveZ.BringDist)

            for _, z in ipairs(zFolder:GetChildren()) do
                if z:GetAttribute("FSS_Target") or true then 
                    local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
                    local zHum = z:FindFirstChild("Humanoid")
                    
                    if zRoot and zHum and zHum.Health > 0 then
                        if (zRoot.Position - myRoot.Position).Magnitude < 300 then
                            zRoot.CFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
                            zRoot.AssemblyLinearVelocity = Vector3.zero
                            
                            if not z:GetAttribute("NoCol") then
                                for _, p in ipairs(z:GetChildren()) do 
                                    if p:IsA("BasePart") then p.CanCollide = false end 
                                end
                                z:SetAttribute("NoCol", true)
                            end
                        end
                    end
                end
            end
            
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)
        table.insert(getgenv().FSS_WaveZ.Connections, conn)
    end
end)

FarmTab:Dropdown("Target Mode", {"All", "Normal Only", "Boss Only"}, "All", function(val)
    getgenv().FSS_WaveZ.TargetMode = val
end)

FarmTab:Toggle("Safe Health (< 30%)", true, function(state)
    getgenv().FSS_WaveZ.SafeHealth = state
end)

FarmTab:Slider("Bring Distance", 5, 20, 8, function(val)
    getgenv().FSS_WaveZ.BringDist = val
end)

-- [TAB 2: COMBAT]
local CombatTab = Window:Section("Combat", "10888331874") -- Sword Icon

CombatTab:Toggle("Silent Aimbot", false, function(state)
    getgenv().FSS_WaveZ.Aimbot = state
    if state then
        local conn = RunService.RenderStepped:Connect(function()
            if not getgenv().FSS_WaveZ.Aimbot then return end
            
            local closest, minMag = nil, 250
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
                            if mag < minMag then 
                                minMag = mag
                                closest = head 
                            end
                        end
                    end
                end
            end
            
            if closest then 
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position) 
            end
        end)
        table.insert(getgenv().FSS_WaveZ.Connections, conn)
    end
end)

-- [TAB 3: VISUALS]
local VisTab = Window:Section("Visuals", "10888332158") -- Eye Icon

VisTab:Toggle("Zombie ESP", false, function(state)
    getgenv().FSS_WaveZ.ESP = state
    if state then
        task.spawn(function()
            while getgenv().FSS_WaveZ.ESP do
                task.wait(1)
                local zFolder = Workspace:FindFirstChild("ServerZombies")
                if zFolder then
                    for _, z in ipairs(zFolder:GetChildren()) do
                        if z:FindFirstChild("Head") and not z:FindFirstChild("FSS_ESP") then
                            local h = Instance.new("Highlight")
                            h.Name = "FSS_ESP"; h.Adornee = z
                            h.FillColor = Color3.fromRGB(140, 80, 255) 
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.6; h.OutlineTransparency = 0
                            h.Parent = z
                        end
                    end
                end
            end
        end)
    else
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if zFolder then
            for _, z in ipairs(zFolder:GetChildren()) do
                if z:FindFirstChild("FSS_ESP") then z.FSS_ESP:Destroy() end
            end
        end
    end
end)

-- [TAB 4: SETTINGS]
local SettingsTab = Window:Section("Settings", "10888332462") -- Gear Icon

SettingsTab:Keybind("Toggle Menu", Enum.KeyCode.RightControl, function()
    if Library.base then 
        local main = Library.base:FindFirstChild("FSSHUB_V10"):FindFirstChild("MainFrame")
        if main then main.Visible = not main.Visible end
    end
end)

SettingsTab:Button("Unload Script", function()
    getgenv().FSS_WaveZ.AutoFarm = false
    getgenv().FSS_WaveZ.Aimbot = false
    getgenv().FSS_WaveZ.ESP = false
    
    for _, c in pairs(getgenv().FSS_WaveZ.Connections) do
        if c then c:Disconnect() end
    end
    getgenv().FSS_WaveZ.Connections = {}
    if Library.base then Library.base:Destroy() end
end)

Library:Notify("FSSHUB", "Wave Z Module Loaded", 3)
