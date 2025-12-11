-- [[ FSSHUB DATA: WAVE Z V5.0 (TORA FEATURES) ]] --
-- Changelog: Added Head-First Bring, Auto Loot, Auto Revive, & HipHeight

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ 1. GLOBAL CLEANUP PROTECTION ]] --
if getgenv().FSS_WaveZ_Stop then
    pcall(getgenv().FSS_WaveZ_Stop)
end

-- 2. State Variables
local State = {
    -- Toggles
    AutoFarm = false,
    AutoAttack = false,
    AutoLoot = false,
    AutoRevive = false,
    Aimbot = false,
    ESP = false,
    
    -- Settings
    BringDist = 10,
    LevitateHeight = 1, -- Tinggi melayang zombie
    TargetMode = "All",
    
    -- Cache
    Connections = {},
    ESP_Cache = {}
}

-- 3. Logic Functions

-- [AUTO FARM: HEAD-FIRST BRING]
local function StartAutoFarm()
    local conn = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end
        
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if not zFolder then return end
        
        -- Kalkulasi Posisi Target (Depan Muka + Levitasi)
        local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * State.BringDist) + Vector3.new(0, State.LevitateHeight, 0)
        local facePlayer = CFrame.lookAt(targetPos, myRoot.Position + Vector3.new(0, State.LevitateHeight, 0))
        local finalCFrame = facePlayer * CFrame.Angles(math.rad(-90), 0, 0) -- Rotasi Tidur (-90 derajat)
        
        for _, z in ipairs(zFolder:GetChildren()) do
            local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
            local zHum = z:FindFirstChild("Humanoid")
            
            if zRoot and zHum and zHum.Health > 0 then
                -- Filter Target
                local validTarget = true
                if State.TargetMode == "Boss" and not z.Name:lower():find("boss") then validTarget = false end
                
                if validTarget then
                    -- Cek Jarak (Max 300 Studs)
                    if (zRoot.Position - myRoot.Position).Magnitude < 300 then
                        -- Set Posisi & Matikan Fisika
                        zRoot.CFrame = finalCFrame
                        zRoot.AssemblyLinearVelocity = Vector3.zero
                        zRoot.AssemblyAngularVelocity = Vector3.zero
                        
                        -- Logic Fisika Zombie (Agar tidak bangun)
                        if not z:GetAttribute("FSS_Physics") then
                            z.PlatformStand = true
                            -- Matikan Collision Part Zombie
                            for _, p in ipairs(z:GetChildren()) do 
                                if p:IsA("BasePart") then p.CanCollide = false end 
                            end
                            z:SetAttribute("FSS_Physics", true)
                        end
                    end
                end
            end
        end
    end)
    table.insert(State.Connections, conn)
end

-- [AUTO ATTACK: ATTRIBUTE BYPASS]
local function StartAutoAttack()
    task.spawn(function()
        while State.AutoAttack do
            local char = LocalPlayer.Character
            if char then
                local gun = char:FindFirstChildOfClass("Tool")
                
                -- Cek apakah ada zombie hidup
                local hasTarget = false
                local zFolder = Workspace:FindFirstChild("ServerZombies")
                if zFolder then
                    for _, z in ipairs(zFolder:GetChildren()) do
                        local h = z:FindFirstChild("Humanoid")
                        if h and h.Health > 0 then hasTarget = true break end
                    end
                end

                if gun and hasTarget then
                    -- Manipulasi Attribute (Bypass Cooldown di beberapa script game)
                    gun:SetAttribute("IsShooting", true)
                    
                    if gun:FindFirstChild("Activate") then gun:Activate() end
                    gun:Activate()
                    
                    task.wait()
                    gun:SetAttribute("IsShooting", false)
                end
            end
            task.wait()
        end
    end)
end

-- [AUTO LOOT: MAGNET]
local function StartAutoLoot()
    task.spawn(function()
        while State.AutoLoot do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root then
                for _, p in ipairs(Workspace:GetChildren()) do
                    if not State.AutoLoot then break end
                    
                    local n = p.Name
                    -- Daftar Item yang diambil
                    if n == "RewardChest" or n == "AmmoBox" or n == "MysteryBox" or n == "Pickup" then
                        if p:IsA("Model") and p.PrimaryPart then
                            p:SetPrimaryPartCFrame(root.CFrame)
                        elseif p:IsA("BasePart") then
                            p.CFrame = root.CFrame
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- [AUTO REVIVE: HYBRID TP]
local function StartAutoRevive()
    task.spawn(function()
        while State.AutoRevive do
            task.wait(0.5)
            pcall(function()
                local char = LocalPlayer.Character
                local myRoot = char and char:FindFirstChild("HumanoidRootPart")
                local myHum = char and char:FindFirstChild("Humanoid")
                
                -- Hanya revive jika kita hidup
                if myRoot and myHum and myHum.Health > 0 then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if not State.AutoRevive then break end
                        
                        if plr ~= LocalPlayer and plr.Character then
                            local tHum = plr.Character:FindFirstChild("Humanoid")
                            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                            
                            -- Cek jika teman sekarat/down
                            if tHum and tRoot and tHum.Health <= 0 then 
                                -- Cari Prompt Revive
                                local prompt = nil
                                for _, v in pairs(plr.Character:GetDescendants()) do
                                    if v:IsA("ProximityPrompt") and v.Enabled then prompt = v break end
                                end
                                
                                if prompt then
                                    -- Teleport ke teman
                                    local oldPos = myRoot.CFrame
                                    myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
                                    myRoot.Anchored = true
                                    
                                    -- Spam Prompt
                                    local start = tick()
                                    prompt.HoldDuration = 0 -- Bypass Hold Time visual
                                    
                                    while tHum.Health <= 0 and (tick() - start < 2) and State.AutoRevive do
                                        fireproximityprompt(prompt)
                                        task.wait(0.1)
                                    end
                                    
                                    -- Kembalikan Status
                                    myRoot.Anchored = false
                                    -- Opsional: Balik ke posisi asal? (Biasanya tidak perlu di mode wave)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

-- [COMBAT: CAMERA LOCK]
local function StartAimbot()
    local conn = RunService.RenderStepped:Connect(function()
        if not State.Aimbot then return end
        
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
    table.insert(State.Connections, conn)
end

-- [VISUALS: ESP]
local function CreateESP(model)
    if not State.ESP then return end
    if not model:FindFirstChild("Head") then return end
    if model:FindFirstChild("FSS_ESP") then return end
    
    local hl = Instance.new("Highlight")
    hl.Name = "FSS_ESP"
    hl.Adornee = model
    hl.FillColor = Color3.fromRGB(140, 80, 255)
    hl.FillTransparency = 0.6
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0.5
    hl.Parent = model
    
    table.insert(State.ESP_Cache, hl)
    
    model.AncestryChanged:Connect(function(_, parent)
        if not parent then 
            for i, v in ipairs(State.ESP_Cache) do
                if v == hl then table.remove(State.ESP_Cache, i) break end
            end
        end
    end)
end

local function ToggleESP(active)
    State.ESP = active
    if active then
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if zFolder then
            for _, z in ipairs(zFolder:GetChildren()) do CreateESP(z) end
            local conn = zFolder.ChildAdded:Connect(function(child) task.wait(0.1); CreateESP(child) end)
            table.insert(State.Connections, conn)
        end
    else
        for _, hl in ipairs(State.ESP_Cache) do if hl then hl:Destroy() end end
        State.ESP_Cache = {}
    end
end

-- [[ 4. CLEANUP ]] --
local function Cleanup()
    print("[FSSHUB] Unloading Wave Z Script...")
    
    State.AutoFarm = false
    State.AutoAttack = false
    State.AutoLoot = false
    State.AutoRevive = false
    State.Aimbot = false
    State.ESP = false
    
    ToggleESP(false)
    for _, c in pairs(State.Connections) do c:Disconnect() end
    State.Connections = {}
    
    -- Reset Camera & Physics
    if Camera then Camera.CameraType = Enum.CameraType.Custom end
    
    -- Reset HipHeight
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.HipHeight = 0 -- Default Roblox
    end
    
    print("[FSSHUB] Wave Z Unloaded.")
end

getgenv().FSS_WaveZ_Stop = Cleanup

-- RETURN CONFIGURATION
return {
    Name = "Wave Z V5.0",
    OnUnload = Cleanup,
    Tabs = {
        {
            Name = "Farming", Icon = "10888331510",
            Elements = {
                {Type = "Toggle", Title = "Enable Auto Farm (Magnet)", Default = false, Callback = function(v) State.AutoFarm = v; if v then StartAutoFarm() end end},
                {Type = "Toggle", Title = "Auto Attack (Fast)", Default = false, Callback = function(v) State.AutoAttack = v; if v then StartAutoAttack() end end},
                {Type = "Toggle", Title = "Auto Collect Loot", Default = false, Callback = function(v) State.AutoLoot = v; if v then StartAutoLoot() end end},
                
                {Type = "Slider", Title = "Magnet Distance", Min = 5, Max = 20, Default = 10, Callback = function(v) State.BringDist = v end},
                {Type = "Slider", Title = "Levitate Height", Min = -5, Max = 5, Default = 1, Callback = function(v) State.LevitateHeight = v end},
                {Type = "Dropdown", Title = "Target Priority", Options = {"All", "Normal", "Boss"}, Default = "All", Callback = function(v) State.TargetMode = v end}
            }
        },
        {
            Name = "Support", Icon = "10888332462",
            Elements = {
                {Type = "Toggle", Title = "Auto Revive Teammates", Default = false, Callback = function(v) State.AutoRevive = v; if v then StartAutoRevive() end end},
                {Type = "Slider", Title = "Hip Height (Anti-Stuck)", Min = 0, Max = 50, Default = 0, Callback = function(v) 
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.HipHeight = v
                    end
                end}
            }
        },
        {
            Name = "Combat", Icon = "10888331874",
            Elements = {
                {Type = "Toggle", Title = "Camera Lock (Aimbot)", Default = false, Callback = function(v) State.Aimbot = v; if v then StartAimbot() end end}
            }
        },
        {
            Name = "Visuals", Icon = "10888332158",
            Elements = {
                {Type = "Toggle", Title = "Zombie ESP", Default = false, Callback = function(v) ToggleESP(v) end}
            }
        }
    }
}
