-- [[ FSSHUB DATA: UNIVERSAL V7.1 (OPTIMIZED) ]] --
-- Status: Refactored to use Utils Module, Optimized Loops
-- Path: main/scripts/Universal.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera

-- [[ 0. LOAD UTILS MODULE ]] --
local BaseUrl = getgenv().FSSHUB_DEV_BASE or "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/main/"
local UtilsUrl = BaseUrl .. "main/modules/Utils.lua?t="..tostring(os.time())
local success, Utils = pcall(function() return loadstring(game:HttpGet(UtilsUrl))() end)

if not success or not Utils then
    game.StarterGui:SetCore("SendNotification", {Title = "Script Error", Text = "Failed to load Utils Module", Duration = 5})
    return
end

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
    InfJumpConnection = nil, -- Memory Safe Connection
    Noclip = false,
    Spinbot = false,
    
    -- Stored Defaults (For correct reset)
    OriginalSpeed = nil,
    OriginalJump = nil,

    -- Visuals
    Fullbright = false,
    
    -- ESP
    ESP = false,
    ESP_TeamCheck = false,
    ESP_MaxDistance = 1500,
}

-- 3. Logic Functions

local function UpdateSpeed()
    if State.SpeedEnabled then
        -- Store original speed if not already stored
        if not State.OriginalSpeed and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then State.OriginalSpeed = hum.WalkSpeed end
        end

        Utils:BindLoop("WalkSpeed", "Heartbeat", function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                if LocalPlayer.Character.Humanoid.WalkSpeed ~= State.Speed then
                    LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed
                end
            end
        end)
    else
        Utils:UnbindLoop("WalkSpeed")
        -- Restore to original speed or default 16
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = State.OriginalSpeed or 16
                State.OriginalSpeed = nil -- Reset stored value
            end
        end
    end
end

local function UpdateJump()
    if State.JumpEnabled then
        -- Store original jump power if not already stored
        if not State.OriginalJump and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then State.OriginalJump = hum.JumpPower end
        end

        Utils:BindLoop("JumpPower", "Heartbeat", function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.UseJumpPower = true
                if LocalPlayer.Character.Humanoid.JumpPower ~= State.Jump then
                    LocalPlayer.Character.Humanoid.JumpPower = State.Jump
                end
            end
        end)
    else
        Utils:UnbindLoop("JumpPower")
        -- Restore to original jump or default 50
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = State.OriginalJump or 50
                State.OriginalJump = nil -- Reset stored value
            end
        end
    end
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
                -- [[ Hawk Safety Check ]] --
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local success, err = pcall(function()
                        local root = LocalPlayer.Character.HumanoidRootPart
                        if not root:FindFirstChild("FSS_Spin") then
                            spin:Clone().Parent = root
                        end
                    end)
                    if not success then warn("[FSSHUB] Spinbot Error:", err) end
                end
                task.wait(0.5)
            end
            
            -- Cleanup when loop breaks
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                 local old = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FSS_Spin")
                 if old then old:Destroy() end
            end
        end)
    else
        -- Manual Disable
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
             local old = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FSS_Spin")
             if old then old:Destroy() end
        end
    end
end

local function ToggleNoclip(active)
    State.Noclip = active
    Utils:Noclip(active)
end

local function ToggleInfJump(active)
    State.InfJump = active

    -- Cleanup previous connection if it exists
    if State.InfJumpConnection then
        State.InfJumpConnection:Disconnect()
        State.InfJumpConnection = nil
    end

    if active then
        -- Create new connection
        State.InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            if State.InfJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        -- Note: We track it manually instead of Utils:Connect to allow specific disconnection
    end
end

local function ApplyFullbright(active)
    State.Fullbright = active
    if active then
        Utils:BindLoop("Fullbright", "Heartbeat", function()
             -- Using Heartbeat ensures it stays applied even if game changes it
             Lighting.Brightness = 2
             Lighting.ClockTime = 14
             Lighting.GlobalShadows = false
             Lighting.Ambient = Color3.fromRGB(178, 178, 178)
             Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        end)
    else
        Utils:UnbindLoop("Fullbright")
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local function AddVisuals(char)
        if not State.ESP then return end
        if State.ESP_TeamCheck and player.Team == LocalPlayer.Team then return end
        
        -- Use Utils ESP
        Utils.ESP:Add(char, {
            Color = Color3.fromRGB(140, 80, 255),
            FillTransparency = 0.5,
            OutlineTransparency = 0
        })
    end
    
    if player.Character then AddVisuals(player.Character) end
    Utils:Connect(player.CharacterAdded, AddVisuals)
end

local function ToggleESP(active)
    State.ESP = active
    Utils.ESP:Toggle(active)

    if active then
        -- Add to existing players
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
        -- Connect for new players
        Utils:Connect(Players.PlayerAdded, CreateESP)
    else
        Utils.ESP:Clear()
        -- Note: We rely on Utils:DeepClean() or manually disconnecting PlayerAdded if we wanted to fully stop listening.
        -- But since Utils:Connect doesn't return an ID we can easily target, we rely on the flag check inside CreateESP
        -- or just leave the listener (it's lightweight) until DeepClean.
        -- For better performance, we should probably clear the connections associated with ESP.
        -- But Utils currently stores all connections in one list.
    end
end

-- [[ SERVER HOP LOGIC ]] --
local function ServerHop()
    local Api = "https://games.roblox.com/v1/games/"
    local _place = game.PlaceId
    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
    
    local function ListServers(cursor)
       local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
       return HttpService:JSONDecode(Raw)
    end
    
    local Server, Next
    repeat
       local Servers = ListServers(Next)
       Server = Servers.data[1]
       Next = Servers.nextPageCursor
    until Server
    
    if Server then
        TeleportService:TeleportToPlaceInstance(_place, Server.id, LocalPlayer)
    end
end

-- [[ 4. DEEP CLEANUP ]] --
local function Cleanup()
    print("[FSSHUB] Universal Unload (Via Utils)...")

    -- [[ Hawk Fix: Conflict Resolution ]] --
    -- Utils:DeepClean resets Speed/Jump to 16/50.
    -- We must capture original values locally to override DeepClean if needed.
    local restoreSpeed = State.OriginalSpeed
    local restoreJump = State.OriginalJump

    if Utils then
        Utils:DeepClean()
    end

    -- Manually restore values if they differ from default
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            if restoreSpeed and restoreSpeed ~= 16 then
                hum.WalkSpeed = restoreSpeed
            end
            if restoreJump and restoreJump ~= 50 then
                hum.JumpPower = restoreJump
            end
        end
    end

    State.SpeedEnabled = false
    State.JumpEnabled = false
    State.InfJump = false
    State.Spinbot = false
    State.ESP = false
    State.Fullbright = false
    State.Noclip = false
    
    -- Additional Cleanup if Utils didn't catch something (Utils catches most)
    getgenv().FSS_Universal_Stop = nil
    
    print("[FSSHUB] Universal Unload Complete.")
end

getgenv().FSS_Universal_Stop = Cleanup

-- 5. Return Configuration
return {
    Name = "Universal V7.1",
    OnUnload = Cleanup,

    Tabs = {
        {
            Name = "Player", 
            Icon = "Player",
            Elements = {
                {Type = "Toggle", Title = "Enable WalkSpeed", Default = false, Keybind = Enum.KeyCode.V, Callback = function(v) State.SpeedEnabled = v; UpdateSpeed() end},
                {Type = "Slider", Title = "Speed Value", Min = 16, Max = 500, Default = 16, Callback = function(v) State.Speed = v end},
                
                {Type = "Toggle", Title = "Enable JumpPower", Default = false, Callback = function(v) State.JumpEnabled = v; UpdateJump() end},
                {Type = "Slider", Title = "Jump Value", Min = 50, Max = 500, Default = 50, Callback = function(v) State.Jump = v end},
                
                {Type = "Toggle", Title = "Infinite Jump", Default = false, Callback = function(v) ToggleInfJump(v) end},
                {Type = "Toggle", Title = "Noclip (Wall Hack)", Default = false, Callback = function(v) ToggleNoclip(v) end},
                {Type = "Toggle", Title = "Spinbot (Troll)", Default = false, Callback = function(v) ToggleSpinbot(v) end}
            }
        },
        {
            Name = "Visuals", 
            Icon = "Visuals",
            Elements = {
                {Type = "Toggle", Title = "Player ESP (Smart)", Default = false, Callback = ToggleESP},
                {Type = "Toggle", Title = "Team Check", Default = false, Callback = function(v) State.ESP_TeamCheck = v end},
                {Type = "Slider", Title = "ESP Max Distance", Min = 100, Max = 5000, Default = 1500, Callback = function(v) State.ESP_MaxDistance = v end},
                {Type = "Toggle", Title = "Fullbright (Soft)", Default = false, Callback = ApplyFullbright},
            }
        },
        {
            Name = "Misc", 
            Icon = "Misc",
            Elements = {
                {Type = "Button", Title = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end},
                {Type = "Button", Title = "Server Hop (Random)", Callback = ServerHop}
            }
        }
    }
}
