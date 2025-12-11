-- [[ FSSHUB DATA: UNIVERSAL V6.2 (CLEANED) ]] --
-- Changelog: Removed redundant 'Misc' tab (now handled globally by UIManager)
-- Path: main/scripts/Universal.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera

-- [[ 1. GLOBAL CLEANUP ]] --
if getgenv().FSS_Universal_Stop then
    pcall(getgenv().FSS_Universal_Stop)
end

-- 2. State Variables
local State = {
    -- Movement
    Speed = 16,
    Jump = 50,
    SpeedEnabled = false,
    JumpEnabled = false,
    InfJump = false,
    Noclip = false,
    Spinbot = false,
    
    -- Visuals
    Fullbright = false,
    
    -- ESP
    ESP = false,
    ESP_MaxDistance = 1500, 
    ESP_UpdateInterval = 0.5,
    ESP_TeamCheck = false,
    
    -- System
    Connections = {},
    ESP_Cache = {},
    
    -- Backup Values
    OriginalLighting = nil
}

-- 3. Logic Functions (Classic Hybrid)

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
    pcall(function() if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end)
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
    pcall(function() if LocalPlayer.Character then LocalPlayer.Character.Humanoid.JumpPower = 50 end end)
end

local function ToggleSpinbot(active)
    if active then
        task.spawn(function()
            local spin = Instance.new("BodyAngularVelocity")
            spin.Name = "FSS_Spin"
            spin.MaxTorque = Vector3.new(0, math.huge, 0)
            spin.AngularVelocity = Vector3.new(0, 50, 0)
            
            while State.Spinbot do
                pcall(function()
                    local root = LocalPlayer.Character.HumanoidRootPart
                    if root and not root:FindFirstChild("FSS_Spin") then 
                        spin:Clone().Parent = root 
                    end
                end)
                task.wait(0.5)
            end
            
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FSS_Spin") then
                    LocalPlayer.Character.HumanoidRootPart.FSS_Spin:Destroy()
                end
            end)
        end)
    end
end

local function ToggleNoclip(active)
    State.Noclip = active
    if active then
        local conn = RunService.Stepped:Connect(function()
            if State.Noclip and LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        table.insert(State.Connections, conn)
    else
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function ToggleInfJump(active)
    State.InfJump = active
    if active then
        local conn = UserInputService.JumpRequest:Connect(function()
            if State.InfJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
        table.insert(State.Connections, conn)
    end
end

local function ApplyFullbright(active)
    State.Fullbright = active
    
    if active then
        if not State.OriginalLighting then
            State.OriginalLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                FogEnd = Lighting.FogEnd
            }
        end

        task.spawn(function()
            while State.Fullbright do
                Lighting.Brightness = 1
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(170, 170, 170)
                Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 170)
                Lighting.FogEnd = 9e9
                task.wait(1)
            end
        end)
    else
        if State.OriginalLighting then
            Lighting.Brightness = State.OriginalLighting.Brightness
            Lighting.ClockTime = State.OriginalLighting.ClockTime
            Lighting.GlobalShadows = State.OriginalLighting.GlobalShadows
            Lighting.Ambient = State.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
            Lighting.FogEnd = State.OriginalLighting.FogEnd
            State.OriginalLighting = nil
        end
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local function AddVisuals(char)
        if not State.ESP then return end
        if State.ESP_TeamCheck and player.Team == LocalPlayer.Team then return end
        
        local head = char:WaitForChild("Head", 5) 
        if not head then return end 
        
        if char:FindFirstChild("FSS_ESP_Box") then char.FSS_ESP_Box:Destroy() end
        
        local hl = Instance.new("Highlight")
        hl.Name = "FSS_ESP_Box"
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(140, 80, 255)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
        hl.Parent = char
        
        local bg = Instance.new("BillboardGui")
        bg.Name = "FSS_ESP_Text"
        bg.Adornee = head
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true
        bg.Parent = head
        
        local text = Instance.new("TextLabel", bg)
        text.BackgroundTransparency = 1
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Text = player.Name
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextStrokeTransparency = 0
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        
        table.insert(State.ESP_Cache, {hl = hl, txt = text, plr = player, char = char})
    end
    
    if player.Character then AddVisuals(player.Character) end
    player.CharacterAdded:Connect(AddVisuals)
end

local function UpdateESP_Loop()
    task.spawn(function()
        while State.ESP do
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            for i = #State.ESP_Cache, 1, -1 do
                local item = State.ESP_Cache[i]
                if not item.char or not item.char.Parent or not item.plr or not item.plr.Parent then
                    if item.hl then item.hl:Destroy() end
                    if item.txt and item.txt.Parent then item.txt.Parent:Destroy() end
                    table.remove(State.ESP_Cache, i)
                else
                    if myRoot and item.txt.Parent then
                        local root = item.char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local dist = (root.Position - myRoot.Position).Magnitude
                            item.txt.Text = string.format("%s\n[%d m]", item.plr.Name, math.floor(dist))
                            
                            local isTeammate = (State.ESP_TeamCheck and item.plr.Team == LocalPlayer.Team)
                            
                            if dist > State.ESP_MaxDistance or isTeammate then
                                item.hl.Enabled = false
                                item.txt.Visible = false
                            else
                                item.hl.Enabled = true
                                item.txt.Visible = true
                            end
                        end
                    end
                end
            end
            task.wait(State.ESP_UpdateInterval)
        end
    end)
end

local function ToggleESP(active)
    State.ESP = active
    if active then
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
        local conn1 = Players.PlayerAdded:Connect(CreateESP)
        table.insert(State.Connections, conn1)
        UpdateESP_Loop()
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                if p.Character:FindFirstChild("FSS_ESP_Box") then p.Character.FSS_ESP_Box:Destroy() end
                if p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("FSS_ESP_Text") then 
                    p.Character.Head.FSS_ESP_Text:Destroy() 
                end
            end
        end
        State.ESP_Cache = {}
    end
end

-- [[ 4. DEEP CLEANUP ]] --
local function Cleanup()
    print("[FSSHUB] Universal Unload (Physics Reset)...")

    State.SpeedEnabled = false
    State.JumpEnabled = false
    State.InfJump = false
    State.Spinbot = false
    State.ESP = false
    State.Fullbright = false
    State.Noclip = false
    
    task.wait(0.1)
    
    ToggleNoclip(false)
    ApplyFullbright(false)
    ToggleESP(false)
    
    for _, c in pairs(State.Connections) do 
        if c then c:Disconnect() end 
    end
    State.Connections = {}

    -- SIT RESET (Anti-Shaking)
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if root then
            local s = root:FindFirstChild("FSS_Spin")
            if s then s:Destroy() end
            root.AssemblyAngularVelocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end

        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.AutoRotate = true 
            
            local wasSitting = hum.Sit
            hum.Sit = true
            task.delay(0.1, function()
                if hum then hum.Sit = false end
            end)
        end
        
        if Camera and hum then
            Camera.CameraSubject = hum
            Camera.CameraType = Enum.CameraType.Custom
        end
    end
    
    print("[FSSHUB] Physics Hard-Reset Complete.")
end

getgenv().FSS_Universal_Stop = Cleanup

-- 5. Return Configuration
return {
    Name = "Universal V6.2",
    OnUnload = Cleanup,

    Tabs = {
        {
            Name = "Player", Icon = "10888331510",
            Elements = {
                {Type = "Toggle", Title = "Enable WalkSpeed", Default = false, Keybind = Enum.KeyCode.V, Callback = function(v) State.SpeedEnabled = v; if v then task.spawn(UpdateSpeed) end end},
                {Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16, Callback = function(v) State.Speed = v end},
                
                {Type = "Toggle", Title = "Enable JumpPower", Default = false, Callback = function(v) State.JumpEnabled = v; if v then task.spawn(UpdateJump) end end},
                {Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50, Callback = function(v) State.Jump = v end},
                
                {Type = "Toggle", Title = "Infinite Jump", Default = false, Callback = function(v) ToggleInfJump(v) end},
                {Type = "Toggle", Title = "Noclip (Wall Hack)", Default = false, Callback = function(v) ToggleNoclip(v) end},
                {Type = "Toggle", Title = "Spinbot (Troll)", Default = false, Callback = function(v) State.Spinbot = v; ToggleSpinbot(v) end}
            }
        },
        {
            Name = "Visuals", Icon = "10888332158",
            Elements = {
                {Type = "Toggle", Title = "Player ESP (Smart)", Default = false, Callback = function(v) ToggleESP(v) end},
                {Type = "Toggle", Title = "Team Check", Default = false, Callback = function(v) State.ESP_TeamCheck = v end},
                {Type = "Slider", Title = "ESP Max Distance", Min = 100, Max = 5000, Default = 1500, Callback = function(v) State.ESP_MaxDistance = v end},
                {Type = "Toggle", Title = "Fullbright (Soft)", Default = false, Callback = ApplyFullbright},
            }
        }
    }
}
