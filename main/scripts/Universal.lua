-- [[ FSSHUB DATA: UNIVERSAL V7.0 (COMPLETE RESTORE) ]] --
-- Status: All features present, Icons fixed, No logic removed
-- Path: main/scripts/Universal.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
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
    ESP_TeamCheck = false,
    ESP_MaxDistance = 1500,
    
    -- Storage
    Connections = {},
    ESP_Cache = {}
}

-- 3. Logic Functions

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
    -- Reset to default
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
    -- Reset to default
    pcall(function() if LocalPlayer.Character then LocalPlayer.Character.Humanoid.JumpPower = 50 end end)
end

local function ToggleSpinbot(active)
    State.Spinbot = active
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
    else
        -- Force remove spin object
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FSS_Spin") then
                LocalPlayer.Character.HumanoidRootPart.FSS_Spin:Destroy()
            end
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
        -- Restore collision logic handled by game/cleanup
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
        task.spawn(function()
            while State.Fullbright do
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(178, 178, 178)
                Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
                task.wait(1)
            end
        end)
    else
        -- Reset lighting logic simplified
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local function AddVisuals(char)
        if not State.ESP then return end
        if State.ESP_TeamCheck and player.Team == LocalPlayer.Team then return end
        
        -- Tunggu Head muncul
        local head = char:WaitForChild("Head", 5) 
        if not head then return end 
        
        -- Hapus ESP lama jika ada
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
        
        table.insert(State.ESP_Cache, {hl = hl, plr = player, char = char})
    end
    
    if player.Character then AddVisuals(player.Character) end
    player.CharacterAdded:Connect(AddVisuals)
end

local function ToggleESP(active)
    State.ESP = active
    if active then
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
        local conn = Players.PlayerAdded:Connect(CreateESP)
        table.insert(State.Connections, conn)
    else
        -- Clear ESP
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("FSS_ESP_Box") then
                p.Character.FSS_ESP_Box:Destroy()
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
    ToggleSpinbot(false)
    
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
            hum.Sit = true
            task.delay(0.1, function()
                if hum and hum.Parent then hum.Sit = false end
            end)
        end
    end
    
    print("[FSSHUB] Physics Hard-Reset Complete.")
end

getgenv().FSS_Universal_Stop = Cleanup

-- 5. Return Configuration
return {
    Name = "Universal V7.0",
    OnUnload = Cleanup,

    Tabs = {
        {
            Name = "Player", 
            Icon = "Player", -- Ikon Orang
            Elements = {
                {Type = "Toggle", Title = "Enable WalkSpeed", Default = false, Keybind = Enum.KeyCode.V, Callback = function(v) State.SpeedEnabled = v; if v then task.spawn(UpdateSpeed) end end},
                {Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16, Callback = function(v) State.Speed = v end},
                
                {Type = "Toggle", Title = "Enable JumpPower", Default = false, Callback = function(v) State.JumpEnabled = v; if v then task.spawn(UpdateJump) end end},
                {Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50, Callback = function(v) State.Jump = v end},
                
                {Type = "Toggle", Title = "Infinite Jump", Default = false, Callback = function(v) ToggleInfJump(v) end},
                {Type = "Toggle", Title = "Noclip (Wall Hack)", Default = false, Callback = function(v) ToggleNoclip(v) end},
                {Type = "Toggle", Title = "Spinbot (Troll)", Default = false, Callback = function(v) ToggleSpinbot(v) end}
            }
        },
        {
            Name = "Visuals", 
            Icon = "Visuals", -- Ikon Mata
            Elements = {
                {Type = "Toggle", Title = "Player ESP (Highlight)", Default = false, Callback = ToggleESP},
                {Type = "Toggle", Title = "Team Check", Default = false, Callback = function(v) State.ESP_TeamCheck = v end},
                {Type = "Toggle", Title = "Fullbright (Light)", Default = false, Callback = ApplyFullbright},
            }
        },
        {
            Name = "Misc", 
            Icon = "Misc", -- Ikon Tambahan (Yang diminta dikembalikan)
            Elements = {
                {Type = "Button", Title = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end},
                {Type = "Button", Title = "Server Hop (Random)", Callback = function() 
                    -- Simple Hop Logic
                    local Http = game:GetService("HttpService")
                    local TPS = game:GetService("TeleportService")
                    local Api = "https://games.roblox.com/v1/games/"
                    
                    local _place = game.PlaceId
                    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
                    
                    local function ListServers(cursor)
                       local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
                       return Http:JSONDecode(Raw)
                    end
                    
                    local Server, Next; repeat
                       local Servers = ListServers(Next)
                       Server = Servers.data[1]
                       Next = Servers.nextPageCursor
                    until Server
                    
                    TPS:TeleportToPlaceInstance(_place, Server.id, LocalPlayer)
                end}
            }
        }
    }
}
