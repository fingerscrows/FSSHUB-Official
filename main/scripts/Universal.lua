-- [[ FSSHUB DATA: UNIVERSAL V4.7 (ESP & VISUAL CONTROL) ]] --
-- Fitur: God Mode, Smart ESP (Jarak & Interval), Clean Fullbright

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- 1. State Variables
local State = {
    Speed = 16,
    Jump = 50,
    SpeedEnabled = false,
    JumpEnabled = false,
    InfJump = false,
    Noclip = false,
    Spinbot = false,
    Fullbright = false,
    ESP = false,
    Connections = {},
    
    -- [BARU] Kontrol ESP
    ESP_MaxDistance = 800, -- Jarak maksimum default
    ESP_UpdateInterval = 0.5, -- Interval update default
    
    StoredEffects = {},
    ESP_Cache = {}
}

-- 2. Logic Functions

local function UpdateSpeed()
    while State.SpeedEnabled do
        task.wait()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed
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
                LocalPlayer.Character.Humanoid.JumpPower = State.Jump
            end
        end)
    end
    pcall(function() if LocalPlayer.Character then LocalPlayer.Character.Humanoid.JumpPower = 50 end end)
end

local function ToggleInfJump(active)
    if active then
        local conn = UserInputService.JumpRequest:Connect(function()
            if State.InfJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState("Jumping") end
            end
        end)
        table.insert(State.Connections, conn)
    end
end

local function ToggleNoclip(active)
    if active then
        local conn = RunService.Stepped:Connect(function()
            if State.Noclip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
        table.insert(State.Connections, conn)
    end
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
                    if root and not root:FindFirstChild("FSS_Spin") then spin:Clone().Parent = root end
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

-- [FULLBRIGHT LOGIC (RESTORE VISUAL)]
local function RestoreOriginalVisuals()
    -- Restore Efek yang disembunyikan
    for obj, enabled in pairs(State.StoredEffects) do
        if obj and obj.Parent then obj.Enabled = enabled end
    end
    State.StoredEffects = {}

    -- Restore Global Lighting (Minimal)
    Lighting.Brightness = 1
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.new(0,0,0)
    Lighting.OutdoorAmbient = Color3.new(0,0,0)
    Lighting.FogEnd = 100000 -- Nilai default yang aman
end

local function ApplyFullbright(active)
    State.Fullbright = active
    
    if active then
        -- Simpan nilai saat ini sebelum diubah (jika belum pernah disimpan)
        if not State.StoredEffects.isSetup then
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(0.5,0.5,0.5) -- Lebih moderat
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
            Lighting.FogEnd = 9e9
        end

        task.spawn(function()
            while State.Fullbright do
                Lighting.Brightness = 1.5 -- Tidak terlalu terang (turun dari 2)
                Lighting.ClockTime = 14
                
                -- Matikan Efek Post-Processing yang bikin Gloomy
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
        -- Restore visual dilakukan oleh loop saat State.Fullbright menjadi false
    end
end

-- [ESP SYSTEM]
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local function AddVisuals(char)
        if not State.ESP then return end
        
        -- Cek apakah Head sudah ada (tanpa delay)
        local head = char:FindFirstChild("Head") 
        if not head then return end 
        
        local hl = Instance.new("Highlight")
        hl.Name = "FSS_ESP_Box"
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(140, 80, 255)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0
        -- [FIX CHAMS UTAMA] Harus AlwaysOnTop untuk tembus tembok
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
        
        char.AncestryChanged:Connect(function(_, parent)
            if not parent then 
                hl:Destroy()
                bg:Destroy()
            end
        end)
    end
    
    if player.Character then AddVisuals(player.Character) end
    player.CharacterAdded:Connect(AddVisuals)
end

local function UpdateESP_Loop()
    -- Loop dengan interval yang ditentukan user
    task.spawn(function()
        while State.ESP do
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then task.wait(1) end

            for i, item in ipairs(State.ESP_Cache) do
                if item.char and item.char.Parent and item.txt.Parent then
                    local root = item.char:FindFirstChild("HumanoidRootPart")
                    
                    if root and myRoot then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        item.txt.Text = string.format("%s\n[%d m]", item.plr.Name, math.floor(dist))
                        
                        -- [KONTROL JARAK] Matikan Chams/ESP jika terlalu jauh
                        if dist > State.ESP_MaxDistance then
                            item.hl.Enabled = false
                            item.txt.Visible = false
                        else
                            item.hl.Enabled = true
                            item.txt.Visible = true
                        end
                    else
                        -- Jika karakter hilang, biarkan loop Heartbeat menghapus dari cache
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

-- 3. Return Configuration Table
return {
    Name = "Universal V4.7",
    
    OnUnload = function()
        State.SpeedEnabled = false
        State.JumpEnabled = false
        State.InfJump = false
        State.Noclip = false
        State.Spinbot = false
        State.ESP = false
        
        if State.Fullbright then ApplyFullbright(false) end
        
        for _, c in pairs(State.Connections) do c:Disconnect() end
        ToggleESP(false)
    end,

    Tabs = {
        {
            Name = "Player", Icon = "10888331510",
            Elements = {
                {Type = "Toggle", Title = "Enable WalkSpeed", Default = false, Keybind = Enum.KeyCode.V, Callback = function(v) State.SpeedEnabled = v; if v then task.spawn(UpdateSpeed) end end},
                {Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16, Callback = function(v) State.Speed = v end},
                {Type = "Toggle", Title = "Enable JumpPower", Default = false, Callback = function(v) State.JumpEnabled = v; if v then task.spawn(UpdateJump) end end},
                {Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50, Callback = function(v) State.Jump = v end},
                {Type = "Toggle", Title = "Infinite Jump", Default = false, Callback = function(v) State.InfJump = v; ToggleInfJump(v) end},
                {Type = "Toggle", Title = "Noclip (Wall Hack)", Default = false, Callback = function(v) State.Noclip = v; ToggleNoclip(v) end},
                {Type = "Toggle", Title = "Spinbot (Troll)", Default = false, Callback = function(v) State.Spinbot = v; ToggleSpinbot(v) end}
            }
        },
        {
            Name = "Visuals", Icon = "10888332158",
            Elements = {
                {Type = "Toggle", Title = "Player ESP (Smart)", Default = false, Callback = function(v) State.ESP = v; ToggleESP(v) end},
                -- [BARU] SLIDER JARAK
                {Type = "Slider", Title = "ESP Max Distance (Studs)", Min = 100, Max = 2000, Default = 800, Callback = function(v) State.ESP_MaxDistance = v end},
                -- [BARU] SLIDER INTERVAL UPDATE
                {Type = "Slider", Title = "ESP Update Interval (Sec)", Min = 0.1, Max = 2, Default = 0.5, Callback = function(v) State.ESP_UpdateInterval = v end},
                {
                    Type = "Toggle", Title = "Fullbright (Anti-Gloomy)", Default = false,
                    Callback = ApplyFullbright
                }
            }
        },
        {
            Name = "Misc", Icon = "10888332462",
            Elements = {
                {Type = "Button", Title = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end},
                {Type = "Button", Title = "Server Hop", Callback = function() 
                    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
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
