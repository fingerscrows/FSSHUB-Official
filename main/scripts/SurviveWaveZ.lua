-- [[ FSSHUB DATA: WAVE Z V6.5 (FULL VERBOSE) ]] --
-- Status: All features expanded, Icons updated to Keywords
-- Path: main/scripts/SurviveWaveZ.lua
-- Optimized by BOLT ⚡

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Load Module Utils (Dengan Cache Buster agar selalu dapat versi terbaru)
local BaseUrl = getgenv().FSSHUB_DEV_BASE or "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/main/"
local UtilsUrl = BaseUrl .. "main/modules/Utils.lua?t="..tostring(os.time())
local success, Utils = pcall(function() return loadstring(game:HttpGet(UtilsUrl))() end)

if not success or not Utils then
    game.StarterGui:SetCore("SendNotification", {Title = "Script Error", Text = "Failed to load Utils Module", Duration = 5})
    return
end

-- [[ 1. GLOBAL CLEANUP PROTECTION ]] --
-- Mencegah script berjalan ganda (double execution)
if getgenv().FSS_WaveZ_Stop then
    pcall(getgenv().FSS_WaveZ_Stop)
end

-- 2. State Variables (Pengaturan Awal)
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

-- [[ ⚡ BOLT OPTIMIZATION: ZOMBIE CACHE ]] --
local ZombieCache = {}
local ZombieFolder = nil
local ZombieFolderConn = nil
local ESPConnection = nil

local function AddToCache(child)
    if not table.find(ZombieCache, child) then
        table.insert(ZombieCache, child)
        -- If ESP is active, add it immediately
        if State.ESP and Utils.ESP then
             task.wait(0.1) -- Wait for model load
             if child.Parent then -- Verify still exists
                 Utils.ESP:Add(child, {Color = Color3.fromRGB(140, 80, 255)})
             end
        end
    end
end

local function RemoveFromCache(child)
    local idx = table.find(ZombieCache, child)
    if idx then table.remove(ZombieCache, idx) end
end

local function InitZombieFolder(folder)
    ZombieFolder = folder
    ZombieCache = {} -- Reset cache

    -- Initial population
    for _, child in ipairs(folder:GetChildren()) do
        AddToCache(child)
    end

    -- Listen for changes
    if ZombieFolderConn then ZombieFolderConn:Disconnect() end
    ZombieFolderConn = Utils:Connect(folder.ChildAdded, AddToCache)
    Utils:Connect(folder.ChildRemoved, RemoveFromCache)
end

-- Initialize if exists
local existingZombies = Workspace:FindFirstChild("ServerZombies")
if existingZombies then InitZombieFolder(existingZombies) end

-- Watch for folder spawn
Utils:Connect(Workspace.ChildAdded, function(child)
    if child.Name == "ServerZombies" then
        InitZombieFolder(child)
    end
end)


-- 3. Logic Functions (Ditulis Lengkap)

local function UpdateAutoFarm()
    if State.AutoFarm then
        local RotationOffset = CFrame.Angles(math.rad(-90), 0, 0) -- Cache rotation

        Utils:BindLoop("AutoFarm", "Heartbeat", function()
            local char = LocalPlayer.Character
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            
            if #ZombieCache == 0 then return end
            
            -- Hitung posisi target di depan pemain
            local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * State.BringDist) + Vector3.new(0, State.LevitateHeight, 0)
            local facePlayer = CFrame.lookAt(targetPos, myRoot.Position + Vector3.new(0, State.LevitateHeight, 0))
            local finalCFrame = facePlayer * RotationOffset
            
            for _, z in ipairs(ZombieCache) do
                local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
                local zHum = z:FindFirstChild("Humanoid")
                
                if zRoot and zHum and zHum.Health > 0 then
                    local validTarget = true
                    -- Filter Boss jika mode Boss aktif
                    if State.TargetMode == "Boss" and not z.Name:lower():find("boss") then 
                        validTarget = false 
                    end
                    
                    -- Teleport zombie jika dalam jangkauan
                    if validTarget and (zRoot.Position - myRoot.Position).Magnitude < 300 then
                        zRoot.CFrame = finalCFrame
                        zRoot.AssemblyLinearVelocity = Vector3.zero
                        
                        -- Matikan fisika zombie agar tidak mendorong pemain
                        if not z:GetAttribute("FSS_Physics") then
                            z.PlatformStand = true
                            for _, p in ipairs(z:GetChildren()) do 
                                if p:IsA("BasePart") then p.CanCollide = false end 
                            end
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
                if tool then 
                    tool:Activate() 
                end
            end
        end)
    else
        Utils:UnbindLoop("AutoAttack")
    end
end

local function UpdateESP()
    -- Toggle fungsi ESP di Module Utils
    if Utils.ESP then
        Utils.ESP:Toggle(State.ESP)
    end
    
    if State.ESP then
        -- Add ESP to existing cached zombies
        for _, z in ipairs(ZombieCache) do
            Utils.ESP:Add(z, {Color = Color3.fromRGB(140, 80, 255)})
        end
        -- New zombies are handled in AddToCache now
    else
        Utils.ESP:Clear()
    end
end

local function StartAimbot()
    if State.Aimbot then
        Utils:BindLoop("Aimbot", "RenderStepped", function()
            local closest, minMag = nil, 300
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            
            if #ZombieCache > 0 then
                for _, z in ipairs(ZombieCache) do
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
            
            -- Kunci kamera ke kepala target
            if closest then 
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position) 
            end
        end)
    else
        Utils:UnbindLoop("Aimbot")
    end
end

-- [[ 4. CLEANUP (VIA UTILS) ]] --
local function Cleanup()
    if Utils then 
        Utils:DeepClean() -- Membersihkan semua Loop dan ESP
    end
    getgenv().FSS_WaveZ_Stop = nil
end

getgenv().FSS_WaveZ_Stop = Cleanup

-- RETURN CONFIGURATION TABLE
return {
    Name = "Wave Z V6.5",
    OnUnload = Cleanup,
    Tabs = {
        {
            Name = "Farming", 
            Icon = "Farming", -- [UPDATED] Menggunakan Keyword
            Elements = {
                {Type = "Toggle", Title = "Enable Auto Farm", Default = false, Callback = function(v) State.AutoFarm = v; UpdateAutoFarm() end},
                {Type = "Toggle", Title = "Auto Attack", Default = false, Callback = function(v) State.AutoAttack = v; UpdateAutoAttack() end},
                {Type = "Slider", Title = "Magnet Distance", Min = 2, Max = 20, Default = 10, Callback = function(v) State.BringDist = v end},
                {Type = "Slider", Title = "Levitate Height", Min = -5, Max = 5, Default = 1, Callback = function(v) State.LevitateHeight = v end},
                {Type = "Dropdown", Title = "Target Priority", Options = {"All", "Normal", "Boss"}, Default = "All", Callback = function(v) State.TargetMode = v end}
            }
        },
        {
            Name = "Support", 
            Icon = "Support", -- [UPDATED] Menggunakan Keyword
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
            Icon = "Combat", -- [UPDATED] Menggunakan Keyword
            Elements = {
                {Type = "Toggle", Title = "Camera Lock (Aimbot)", Default = false, Callback = function(v) State.Aimbot = v; StartAimbot() end}
            }
        },
        {
            Name = "Visuals", 
            Icon = "Visuals", -- [UPDATED] Menggunakan Keyword
            Elements = {
                {Type = "Toggle", Title = "Zombie ESP", Default = false, Callback = function(v) State.ESP = v; UpdateESP() end}
            }
        }
    }
}
