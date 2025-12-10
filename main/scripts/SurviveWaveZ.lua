-- [[ FSSHUB DATA: WAVE Z V3.0 ]] --
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local State = {
    AutoFarm = false,
    Aimbot = false,
    ESP = false,
    BringDist = 8,
    TargetMode = "All",
    Connections = {}
}

local function StartAutoFarm()
    local conn = RunService.Heartbeat:Connect(function()
        if not State.AutoFarm then return end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if not zFolder then return end
        local myRoot = char.HumanoidRootPart
        local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * State.BringDist)

        for _, z in ipairs(zFolder:GetChildren()) do
            local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
            local zHum = z:FindFirstChild("Humanoid")
            if zRoot and zHum and zHum.Health > 0 then
                if (zRoot.Position - myRoot.Position).Magnitude < 300 then
                    zRoot.CFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    zRoot.AssemblyLinearVelocity = Vector3.zero
                    if not z:GetAttribute("NoCol") then
                        for _, p in ipairs(z:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end
                        z:SetAttribute("NoCol", true)
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end)
    table.insert(State.Connections, conn)
end

local function StartAimbot()
    local conn = RunService.RenderStepped:Connect(function()
        if not State.Aimbot then return end
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
                        if mag < minMag then minMag = mag; closest = head end
                    end
                end
            end
        end
        if closest then Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position) end
    end)
    table.insert(State.Connections, conn)
end

-- Return Tabel Data (WAJIB ADA)
return {
    Name = "Wave Z Pro",
    OnUnload = function()
        State.AutoFarm = false; State.Aimbot = false; State.ESP = false
        for _, c in pairs(State.Connections) do c:Disconnect() end
    end,
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
                {Type = "Toggle", Title = "Silent Aimbot", Default = false, Callback = function(v) State.Aimbot = v; if v then StartAimbot() end end}
            }
        },
        {
            Name = "Visuals", Icon = "10888332158",
            Elements = {
                {Type = "Toggle", Title = "Zombie ESP", Default = false, Callback = function(v) State.ESP = v; if v then 
                    task.spawn(function()
                        while State.ESP do task.wait(1); local zFolder = Workspace:FindFirstChild("ServerZombies"); if zFolder then for _, z in ipairs(zFolder:GetChildren()) do if z:FindFirstChild("Head") and not z:FindFirstChild("FSS_ESP") then local h = Instance.new("Highlight"); h.Name = "FSS_ESP"; h.Adornee = z; h.FillColor = Color3.fromRGB(140, 80, 255); h.FillTransparency = 0.6; h.Parent = z end end end end
                    end)
                end end}
            }
        }
    }
}
