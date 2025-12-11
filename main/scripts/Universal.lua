-- [[ FSSHUB DATA: UNIVERSAL V5.0 (OPTIMIZED & IMPROVED) ]] --
-- Changelog: Noclip Optimized, Heartbeat Speed Logic, Team Check ESP, Added FOV Changer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 1. State Variables
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
    FOV = 70,
    FOVEnabled = false,
    
    -- ESP
    ESP = false,
    ESP_MaxDistance = 1000, 
    ESP_UpdateInterval = 0.1, -- Dipercepat sedikit agar text lebih responsif
    ESP_TeamCheck = false,    -- [BARU] Fitur Team Check
    
    -- System
    Connections = {},
    StoredEffects = {},
    ESP_Cache = {}
}

-- 2. Logic Functions

-- [OPTIMIZED SPEED & JUMP] Menggunakan Heartbeat agar lebih smooth dan anti-override
local function StartMovementLoop()
    local conn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        
        if char and hum then
            -- WalkSpeed Logic
            if State.SpeedEnabled then
                if hum.WalkSpeed ~= State.Speed then
                    hum.WalkSpeed = State.Speed
                end
            end
            
            -- JumpPower Logic
            if State.JumpEnabled then
                hum.UseJumpPower = true
                if hum.JumpPower ~= State.Jump then
                    hum.JumpPower = State.Jump
                end
            end
            
            -- Spinbot Logic
            if State.Spinbot then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local spin = root:FindFirstChild("FSS_Spin")
                    if not spin then
                        spin = Instance.new("BodyAngularVelocity")
                        spin.Name = "FSS_Spin"
                        spin.MaxTorque = Vector3.new(0, math.huge, 0)
                        spin.AngularVelocity = Vector3.new(0, 50, 0)
                        spin.Parent = root
                    else
                        spin.AngularVelocity = Vector3.new(0, 50, 0)
                    end
                end
            else
                -- Cleanup Spinbot jika dimatikan saat loop berjalan
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local s = char.HumanoidRootPart:FindFirstChild("FSS_Spin")
                    if s then s:Destroy() end
                end
            end
        end
    end)
    table.insert(State.Connections, conn)
end

-- [OPTIMIZED NOCLIP] Hanya loop BasePart karakter, bukan Descendants (Lag reduction)
local function ToggleNoclip(active)
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
    end
end

-- [INF JUMP]
local function ToggleInfJump(active)
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

-- [FOV CHANGER]
local function UpdateFOV()
    local conn = RunService.RenderStepped:Connect(function()
        if State.FOVEnabled then
            Camera.FieldOfView = State.FOV
        end
    end)
    table.insert(State.Connections, conn)
end

-- [FULLBRIGHT LOGIC]
local function RestoreOriginalVisuals()
    for obj, enabled in pairs(State.StoredEffects) do
        if obj and obj.Parent then obj.Enabled = enabled end
    end
    State.StoredEffects = {}
    
    Lighting.Brightness = 1
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(0,0,0)
    Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
    Lighting.FogEnd = 100000
end

local function ApplyFullbright(active)
    State.Fullbright = active
    if active then
        if not State.StoredEffects.isSetup then
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(150, 150, 150)
            Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
            Lighting.FogEnd = 9e9
            State.StoredEffects.isSetup = true
        end

        task.spawn(function()
            while State.Fullbright do
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                for _, v in pairs(Lighting:GetChildren()) do
                    if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("ColorCorrection") then
                        if State.StoredEffects[v] == nil then State.StoredEffects[v] = v.Enabled end
                        v.Enabled = false
                    end
                end
                task.wait(1)
            end
            RestoreOriginalVisuals()
        end)
    else
        RestoreOriginalVisuals()
    end
end

-- [ESP SYSTEM IMPROVED]
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local function AddVisuals(char)
        if not State.ESP then return end
        
        -- Team Check
        if State.ESP_TeamCheck and player.Team == LocalPlayer.Team then return end
        
        local head = char:WaitForChild("Head", 5) 
        if not head then return end 
        
        -- Hapus ESP lama jika ada (prevent duplicate)
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
            
            -- Clean Cache (Hapus entry yang invalid)
            for i = #State.ESP_Cache, 1, -1 do
                local item = State.ESP_Cache[i]
                if not item.char or not item.char.Parent or not item.plr or not item.plr.Parent then
                    if item.hl then item.hl:Destroy() end
                    if item.txt and item.txt.Parent then item.txt.Parent:Destroy() end
                    table.remove(State.ESP_Cache, i)
                end
            end

            for _, item in ipairs(State.ESP_Cache) do
                if myRoot and item.char and item.txt.Parent then
                    local root = item.char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        item.txt.Text = string.format("%s\n[%d m]", item.plr.Name, math.floor(dist))
                        
                        -- Visibility Check berdasarkan Jarak & Team Check Realtime
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
            task.wait(State.ESP_UpdateInterval)
        end
    end)
end

local function ToggleESP(active)
    if active then
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
        
        local conn1 = Players.PlayerAdded:Connect(CreateESP)
        table.insert(State.Connections, conn1)
        
        UpdateESP_Loop()
    else
        -- Bersihkan semua Visual
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

-- Init Global Loops
StartMovementLoop()

-- 3. Return Configuration Table
return {
    Name = "Universal V5.0",
    
    OnUnload = function()
        State.SpeedEnabled = false
        State.JumpEnabled = false
        State.InfJump = false
        State.Noclip = false
        State.Spinbot = false
        State.ESP = false
        State.FOVEnabled = false
        
        if State.Fullbright then ApplyFullbright(false) end
        
        -- Restore Camera FOV
        Camera.FieldOfView = 70
        
        -- Disconnect semua event (Heartbeat, RenderStepped, Input)
        for _, c in pairs(State.Connections) do c:Disconnect() end
        ToggleESP(false)
    end,

    Tabs = {
        {
            Name = "Player", Icon = "10888331510",
            Elements = {
                {Type = "Toggle", Title = "Enable WalkSpeed", Default = false, Keybind = Enum.KeyCode.V, Callback = function(v) State.SpeedEnabled = v end},
                {Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16, Callback = function(v) State.Speed = v end},
                
                {Type = "Toggle", Title = "Enable JumpPower", Default = false, Callback = function(v) State.JumpEnabled = v end},
                {Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50, Callback = function(v) State.Jump = v end},
                
                {Type = "Toggle", Title = "Infinite Jump", Default = false, Callback = function(v) State.InfJump = v; ToggleInfJump(v) end},
                {Type = "Toggle", Title = "Noclip (Wall Hack)", Default = false, Callback = function(v) State.Noclip = v; ToggleNoclip(v) end},
                {Type = "Toggle", Title = "Spinbot (Troll)", Default = false, Callback = function(v) State.Spinbot = v end}
            }
        },
        {
            Name = "Visuals", Icon = "10888332158",
            Elements = {
                {Type = "Toggle", Title = "Player ESP (Smart)", Default = false, Callback = function(v) State.ESP = v; ToggleESP(v) end},
                {Type = "Toggle", Title = "Team Check", Default = false, Callback = function(v) State.ESP_TeamCheck = v end}, -- [BARU]
                
                {Type = "Slider", Title = "ESP Max Distance", Min = 100, Max = 5000, Default = 1000, Callback = function(v) State.ESP_MaxDistance = v end},
                
                {Type = "Toggle", Title = "Fullbright", Default = false, Callback = ApplyFullbright},
                
                -- [BARU] FOV Changer Controls
                {Type = "Toggle", Title = "Enable FOV Changer", Default = false, Callback = function(v) 
                    State.FOVEnabled = v 
                    if v then UpdateFOV() else Camera.FieldOfView = 70 end 
                end},
                {Type = "Slider", Title = "Field of View", Min = 30, Max = 120, Default = 70, Callback = function(v) State.FOV = v end},
            }
        },
        {
            Name = "Misc", Icon = "10888332462",
            Elements = {
                {Type = "Button", Title = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end},
                {Type = "Button", Title = "Server Hop (Low Player)", Callback = function() 
                    local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
                    for _, s in pairs(servers.data) do
                        if s.playing ~= s.maxPlayers and s.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer); break
                        end
                    end
                end}
            }
        }
    }
}
