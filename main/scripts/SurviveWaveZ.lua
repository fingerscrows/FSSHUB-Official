-- [[ FSSHUB DATA: WAVE Z V6.0 (MODULAR) ]] --
-- Changelog: Integrated Utils Module for cleaner logic & better stability
-- Path: main/scripts/SurviveWaveZ.lua

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load Module Utils (Added Cache Buster for Safety)
local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/modules/Utils.lua?t="..tostring(math.random(1,10000))))()

-- [[ 1. GLOBAL CLEANUP PROTECTION ]] --
if getgenv().FSS_WaveZ_Stop then
    pcall(getgenv().FSS_WaveZ_Stop)
end

-- 2. State Variables
local State = {
    AutoFarm = false,
    AutoAttack = false,
    AutoLoot = false,
    AutoRevive = false,
    Aimbot = false,
    ESP = false,
    
    BringDist = 10,
    LevitateHeight = 1,
    TargetMode = "All"
}

-- 3. Logic Functions

local function UpdateAutoFarm()
    if State.AutoFarm then
        Utils:BindLoop("AutoFarm", "Heartbeat", function()
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            
            local zFolder = Workspace:FindFirstChild("ServerZombies")
            if not zFolder then return end
            
            -- Target Logic
            local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * State.BringDist) + Vector3.new(0, State.LevitateHeight, 0)
            local facePlayer = CFrame.lookAt(targetPos, myRoot.Position + Vector3.new(0, State.LevitateHeight, 0))
            local finalCFrame = facePlayer * CFrame.Angles(math.rad(-90), 0, 0)
            
            for _, z in ipairs(zFolder:GetChildren()) do
                local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
                local zHum = z:FindFirstChild("Humanoid")
                
                if zRoot and zHum and zHum.Health > 0 then
                    local validTarget = true
                    if State.TargetMode == "Boss" and not z.Name:lower():find("boss") then validTarget = false end
                    
                    if validTarget and (zRoot.Position - myRoot.Position).Magnitude < 300 then
                        zRoot.CFrame = finalCFrame
                        zRoot.AssemblyLinearVelocity = Vector3.zero
                        
                        if not z:GetAttribute("FSS_Physics") then
                            z.PlatformStand = true
                            for _, p in ipairs(z:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
                            z:SetAttribute("FSS_Physics", true)
                        end
                    end
                end
            end
        end)
    else
        Utils:UnbindLoop("AutoFarm")
    end
end

local function UpdateAutoAttack()
    if State.AutoAttack then
        Utils:BindLoop("AutoAttack", "Heartbeat", function()
            if LocalPlayer.Character then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end)
    else
        Utils:UnbindLoop("AutoAttack")
    end
end

local function UpdateESP()
    Utils.ESP:Toggle(State.ESP)
    
    if State.ESP then
        -- Listener untuk zombie baru
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if zFolder then
            -- Add Existing
            for _, z in ipairs(zFolder:GetChildren()) do Utils.ESP:Add(z, {Color = Color3.fromRGB(140, 80, 255)}) end
            
            -- Add New (Menggunakan Utils.Connect agar otomatis putus saat unload)
            Utils:Connect(zFolder.ChildAdded, function(child)
                task.wait(0.1)
                Utils.ESP:Add(child, {Color = Color3.fromRGB(140, 80, 255)})
            end)
        end
    else
        Utils.ESP:Clear()
    end
end

local function StartAimbot()
    if State.Aimbot then
        Utils:BindLoop("Aimbot", "RenderStepped", function()
            local closest, minMag = nil, 300
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
    else
        Utils:UnbindLoop("Aimbot")
    end
end

-- [[ 4. CLEANUP (VIA UTILS) ]] --
local function Cleanup()
    Utils:DeepClean() -- Satu baris ini membersihkan SEMUA (Loop, Event, ESP, Physics)
    getgenv().FSS_WaveZ_Stop = nil
end

getgenv().FSS_WaveZ_Stop = Cleanup

-- RETURN CONFIG
return {
    Name = "Wave Z V6.0",
    OnUnload = Cleanup,
    Tabs = {
        {
            Name = "Farming", Icon = "10888331510",
            Elements = {
                {Type = "Toggle", Title = "Enable Auto Farm", Default = false, Callback = function(v) State.AutoFarm = v; UpdateAutoFarm() end},
                {Type = "Toggle", Title = "Auto Attack", Default = false, Callback = function(v) State.AutoAttack = v; UpdateAutoAttack() end},
                {Type = "Slider", Title = "Magnet Distance", Min = 2, Max = 20, Default = 10, Callback = function(v) State.BringDist = v end},
                {Type = "Slider", Title = "Levitate Height", Min = -5, Max = 5, Default = 1, Callback = function(v) State.LevitateHeight = v end},
                {Type = "Dropdown", Title = "Target Priority", Options = {"All", "Normal", "Boss"}, Default = "All", Callback = function(v) State.TargetMode = v end}
            }
        },
        {
            Name = "Support", Icon = "10888332462",
            Elements = {
                {Type = "Slider", Title = "Hip Height", Min = 0, Max = 50, Default = 0, Callback = function(v) 
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.HipHeight = v
                    end
                end}
            }
        },
        {
            Name = "Combat", Icon = "10888331874",
            Elements = {
                {Type = "Toggle", Title = "Camera Lock (Aimbot)", Default = false, Callback = function(v) State.Aimbot = v; StartAimbot() end}
            }
        },
        {
            Name = "Visuals", Icon = "10888332158",
            Elements = {
                {Type = "Toggle", Title = "Zombie ESP", Default = false, Callback = function(v) State.ESP = v; UpdateESP() end}
            }
        }
    }
}
