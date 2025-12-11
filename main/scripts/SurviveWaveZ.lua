-- [[ FSSHUB DATA: WAVE Z V4.0 (REMASTERED) ]] --
-- Changelog: Global Cleanup, Event-Based ESP (No Lag), Optimized AutoFarm

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [[ 1. GLOBAL CLEANUP PROTECTION ]] --
if getgenv().FSS_WaveZ_Stop then
    pcall(getgenv().FSS_WaveZ_Stop)
end

-- 2. State Variables
local State = {
    AutoFarm = false,
    Aimbot = false,
    ESP = false,
    BringDist = 8,
    TargetMode = "All", -- All, Normal, Boss
    Connections = {},
    ESP_Cache = {}
}

-- 3. Logic Functions

-- [AUTO FARM: MAGNET / BRING MOB]
local function StartAutoFarm()
    local conn = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end
        
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if not zFolder then return end
        
        -- Target Position: Di depan pemain sejauh BringDist
        local targetCFrame = root.CFrame * CFrame.new(0, 0, -State.BringDist)
        
        for _, z in ipairs(zFolder:GetChildren()) do
            local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
            local zHum = z:FindFirstChild("Humanoid")
            
            if zRoot and zHum and zHum.Health > 0 then
                -- Filter Target Mode
                local validTarget = true
                if State.TargetMode == "Boss" and not z.Name:lower():find("boss") then validTarget = false end
                
                if validTarget then
                    -- Cek Jarak (Max 300 Studs agar tidak menarik zombie dari ujung map)
                    if (zRoot.Position - root.Position).Magnitude < 300 then
                        -- Teleport Zombie + Putar agar tidak menyerang
                        zRoot.CFrame = targetCFrame * CFrame.Angles(math.rad(-90), 0, 0) 
                        zRoot.AssemblyLinearVelocity = Vector3.zero
                        
                        -- Disable Collision (Sekali saja per zombie)
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
        
        -- Auto Attack
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end)
    table.insert(State.Connections, conn)
end

-- [COMBAT: CAMERA LOCK]
local function StartAimbot()
    local conn = RunService.RenderStepped:Connect(function()
        if not State.Aimbot then return end
        
        local closest, minMag = nil, 300 -- FOV Radius Limit
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

-- [VISUALS: OPTIMIZED ESP]
local function CreateESP(model)
    if not State.ESP then return end
    if not model:FindFirstChild("Head") then return end
    
    -- Mencegah duplicate
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
    
    -- Cleanup Otomatis jika Zombie Mati/Despawn
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
            -- 1. Pasang ke zombie yang sudah ada
            for _, z in ipairs(zFolder:GetChildren()) do
                CreateESP(z)
            end
            
            -- 2. Pasang otomatis ke zombie baru (Event Based, bukan Loop)
            local conn = zFolder.ChildAdded:Connect(function(child)
                 task.wait(0.1) -- Tunggu load sebentar
                 CreateESP(child)
            end)
            table.insert(State.Connections, conn)
        end
    else
        -- Bersihkan Semua Visual saat dimatikan
        for _, hl in ipairs(State.ESP_Cache) do
            if hl then hl:Destroy() end
        end
        State.ESP_Cache = {}
        
        -- Double Check (Manual Cleanup)
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if zFolder then
            for _, z in ipairs(zFolder:GetChildren()) do
                if z:FindFirstChild("FSS_ESP") then z.FSS_ESP:Destroy() end
            end
        end
    end
end

-- [[ 4. CLEANUP ]] --
local function Cleanup()
    print("[FSSHUB] Unloading Wave Z Script...")
    
    -- Reset State
    State.AutoFarm = false
    State.Aimbot = false
    State.ESP = false
    
    -- Hapus Visual
    ToggleESP(false)
    
    -- Putus Koneksi Loop
    for _, c in pairs(State.Connections) do c:Disconnect() end
    State.Connections = {}
    
    print("[FSSHUB] Wave Z Unloaded.")
end

getgenv().FSS_WaveZ_Stop = Cleanup

-- RETURN DATA
return {
    Name = "Wave Z V4.0",
    OnUnload = Cleanup,
    Tabs = {
        {
            Name = "Auto Farm", Icon = "10888331510",
            Elements = {
                {Type = "Toggle", Title = "Enable Auto Farm", Default = false, Callback = function(v) State.AutoFarm = v; if v then StartAutoFarm() end end},
                {Type = "Slider", Title = "Bring Distance", Min = 5, Max = 20, Default = 8, Callback = function(v) State.BringDist = v end},
                {Type = "Dropdown", Title = "Target Mode", Options = {"All", "Normal", "Boss"}, Default = "All", Callback = function(v) State.TargetMode = v end}
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
