-- [[ FSSHUB DATA: UNIVERSAL V4.0 (GOD MODE) ]] --
-- Fitur: ESP Player, Infinite Jump, Spinbot, & Physics Bypass

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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
    ESP_Objects = {} -- Menyimpan container ESP
}

-- 2. Logic Functions

-- [SPEED & JUMP]
local function UpdateSpeed()
    while State.SpeedEnabled do
        task.wait()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed
            end
        end)
    end
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
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
    pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end)
end

-- [INFINITE JUMP]
local function ToggleInfJump(active)
    if active then
        local conn = UserInputService.JumpRequest:Connect(function()
            if State.InfJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState("Jumping")
                end
            end
        end)
        table.insert(State.Connections, conn)
    end
end

-- [NOCLIP]
local function ToggleNoclip(active)
    if active then
        local conn = RunService.Stepped:Connect(function()
            if State.Noclip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then 
                        part.CanCollide = false 
                    end
                end
            end
        end)
        table.insert(State.Connections, conn)
    end
end

-- [SPINBOT]
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
            -- Cleanup
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FSS_Spin") then
                    LocalPlayer.Character.HumanoidRootPart.FSS_Spin:Destroy()
                end
            end)
        end)
    end
end

-- [ESP SYSTEM]
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local function AddVisuals(char)
        if not State.ESP then return end
        
        -- 1. Highlight (Chams)
        local hl = Instance.new("Highlight")
        hl.Name = "FSS_ESP_Box"
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(140, 80, 255)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.Parent = char
        
        -- 2. Text Name
        local bg = Instance.new("BillboardGui")
        bg.Name = "FSS_ESP_Text"
        bg.Adornee = char:FindFirstChild("Head")
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true
        bg.Parent = char:FindFirstChild("Head")
        
        local text = Instance.new("TextLabel", bg)
        text.BackgroundTransparency = 1
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Text = player.Name
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextStrokeTransparency = 0
        text.Font = Enum.Font.GothamBold
        text.TextSize = 14
        
        -- Cleanup saat mati/hilang
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

local function ToggleESP(active)
    if active then
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
        
        local conn = Players.PlayerAdded:Connect(CreateESP)
        table.insert(State.Connections, conn)
    else
        -- Clear ESP
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                if p.Character:FindFirstChild("FSS_ESP_Box") then p.Character.FSS_ESP_Box:Destroy() end
                if p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("FSS_ESP_Text") then 
                    p.Character.Head.FSS_ESP_Text:Destroy() 
                end
            end
        end
    end
end

-- 3. Return Configuration Table
return {
    Name = "Universal V4.0",
    
    OnUnload = function()
        State.SpeedEnabled = false
        State.JumpEnabled = false
        State.InfJump = false
        State.Noclip = false
        State.Spinbot = false
        State.ESP = false
        State.Fullbright = false
        
        -- Matikan semua koneksi
        for _, c in pairs(State.Connections) do c:Disconnect() end
        ToggleESP(false) -- Bersihkan Visual
    end,

    Tabs = {
        -- [TAB: LOCAL PLAYER]
        {
            Name = "Player",
            Icon = "10888331510",
            Elements = {
                {
                    Type = "Toggle", Title = "Enable WalkSpeed", Default = false, Keybind = Enum.KeyCode.V,
                    Callback = function(val)
                        State.SpeedEnabled = val
                        if val then task.spawn(UpdateSpeed) end
                    end
                },
                {
                    Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16,
                    Callback = function(val) State.Speed = val end
                },
                {
                    Type = "Toggle", Title = "Enable JumpPower", Default = false,
                    Callback = function(val)
                        State.JumpEnabled = val
                        if val then task.spawn(UpdateJump) end
                    end
                },
                {
                    Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50,
                    Callback = function(val) State.Jump = val end
                },
                {
                    Type = "Toggle", Title = "Infinite Jump", Default = false,
                    Callback = function(val)
                        State.InfJump = val
                        ToggleInfJump(val)
                    end
                },
                {
                    Type = "Toggle", Title = "Noclip (Wall Hack)", Default = false,
                    Callback = function(val)
                        State.Noclip = val
                        ToggleNoclip(val)
                    end
                },
                {
                    Type = "Toggle", Title = "Spinbot (Troll)", Default = false,
                    Callback = function(val)
                        State.Spinbot = val
                        ToggleSpinbot(val)
                    end
                }
            }
        },
        -- [TAB: VISUALS]
        {
            Name = "Visuals",
            Icon = "10888332158",
            Elements = {
                {
                    Type = "Toggle", Title = "Player ESP (Chams)", Default = false,
                    Callback = function(val)
                        State.ESP = val
                        ToggleESP(val)
                    end
                },
                {
                    Type = "Toggle", Title = "Fullbright (No Shadows)", Default = false,
                    Callback = function(val)
                        State.Fullbright = val
                        if val then
                            task.spawn(function()
                                while State.Fullbright do
                                    Lighting.Brightness = 2; Lighting.ClockTime = 14
                                    Lighting.GlobalShadows = false
                                    Lighting.Ambient = Color3.new(1,1,1)
                                    task.wait(1)
                                end
                            end)
                        else
                            Lighting.GlobalShadows = true
                        end
                    end
                }
            }
        },
        -- [TAB: MISC]
        {
            Name = "Misc",
            Icon = "10888332462",
            Elements = {
                {
                    Type = "Button", Title = "Rejoin Server",
                    Callback = function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                    end
                },
                {
                    Type = "Button", Title = "Server Hop (Random)",
                    Callback = function()
                        -- Logic sederhana server hop
                        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
                        for _, s in pairs(servers.data) do
                            if s.playing ~= s.maxPlayers and s.id ~= game.JobId then
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                                break
                            end
                        end
                    end
                }
            }
        }
    }
}
