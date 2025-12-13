-- [[ FSSHUB DATA: UNIVERSAL V7.2 (HAWK STABLE) ]] --
-- Status: HAWK Optimized (Safe Toggles, No Leaks)
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
    Noclip = false,
    Spinbot = false,
    
    -- Visuals
    Fullbright = false,
    
    -- ESP
    ESP = false,
    ESP_TeamCheck = false,
    ESP_MaxDistance = 1500,

    -- Internal State
    OriginalSpeed = nil,
    OriginalJump = nil,
    InfJumpConnection = nil,
    ESPConnection = nil,
}

-- Track character changes to reset original values
Utils:Connect(LocalPlayer.CharacterAdded, function()
    State.OriginalSpeed = nil
    State.OriginalJump = nil
end)

-- 3. Logic Functions

local function UpdateSpeed()
    if State.SpeedEnabled then
        Utils:BindLoop("WalkSpeed", "Heartbeat", function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local hum = LocalPlayer.Character.Humanoid

                -- Capture original speed if not yet captured
                if not State.OriginalSpeed then
                    State.OriginalSpeed = hum.WalkSpeed
                end

                if hum.WalkSpeed ~= State.Speed then
                    hum.WalkSpeed = State.Speed
                end
            end
        end)
    else
        Utils:UnbindLoop("WalkSpeed")
        -- HAWK: Removed pcall, added manual safety check
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hum = LocalPlayer.Character.Humanoid
            if State.OriginalSpeed then
                hum.WalkSpeed = State.OriginalSpeed
                State.OriginalSpeed = nil
            else
                hum.WalkSpeed = 16 -- Fallback
            end
        end
    end
end

local function UpdateJump()
    if State.JumpEnabled then
        Utils:BindLoop("JumpPower", "Heartbeat", function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                local hum = LocalPlayer.Character.Humanoid
                hum.UseJumpPower = true

                -- Capture original jump if not yet captured
                if not State.OriginalJump then
                    State.OriginalJump = hum.JumpPower
                end

                if hum.JumpPower ~= State.Jump then
                    hum.JumpPower = State.Jump
                end
            end
        end)
    else
        Utils:UnbindLoop("JumpPower")
        -- HAWK: Removed pcall, added manual safety check
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local hum = LocalPlayer.Character.Humanoid
            if State.OriginalJump then
                hum.JumpPower = State.OriginalJump
                State.OriginalJump = nil
            else
                hum.JumpPower = 50 -- Fallback
            end
        end
    end
end

local function ToggleSpinbot(active)
    State.Spinbot = active
    if active then
        -- HAWK: Replaced task.spawn/while loop with Utils:BindLoop to prevent zombies
        Utils:BindLoop("Spinbot", "Heartbeat", function()
            local char = LocalPlayer.Character
            if not char then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                -- Recreate BodyAngularVelocity if missing
                if not root:FindFirstChild("FSS_Spin") then
                    local spin = Instance.new("BodyAngularVelocity")
                    spin.Name = "FSS_Spin"
                    spin.MaxTorque = Vector3.new(0, math.huge, 0)
                    spin.AngularVelocity = Vector3.new(0, 50, 0)
                    spin.Parent = root
                end
            end
        end)
    else
        Utils:UnbindLoop("Spinbot")
        -- Safe Cleanup
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local existing = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FSS_Spin")
            if existing then existing:Destroy() end
        end
    end
end

local function ToggleNoclip(active)
    State.Noclip = active
    Utils:Noclip(active)
end

local function ToggleInfJump(active)
    State.InfJump = active

    -- HAWK: Cleanup old connection first
    if State.InfJumpConnection then
        State.InfJumpConnection:Disconnect()
        State.InfJumpConnection = nil
    end

    if active then
        -- We do NOT use Utils:Connect here because we need to manually manage this specific connection
        -- for toggling. Utils:Connect stores it in a global list which is hard to pick from.
        State.InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            if State.InfJump and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end
end

local function ApplyFullbright(active)
    State.Fullbright = active
    if active then
        Utils:BindLoop("Fullbright", "Heartbeat", function()
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

    -- HAWK: Cleanup PlayerAdded connection to prevent stacking listeners
    if State.ESPConnection then
        State.ESPConnection:Disconnect()
        State.ESPConnection = nil
    end

    if active then
        -- Add to existing players
        for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end

        -- Connect for new players manually
        State.ESPConnection = Players.PlayerAdded:Connect(CreateESP)
    else
        Utils.ESP:Clear()
    end
end

-- [[ SERVER HOP LOGIC ]] --
local function ServerHop()
    local Api = "https://games.roblox.com/v1/games/"
    local _place = game.PlaceId
    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=100"
    
    local function ListServers(cursor)
       local success, result = pcall(function()
           return game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
       end)

       if not success then
           warn("[HAWK] ServerHop Http Failed: " .. tostring(result))
           return nil
       end

       return HttpService:JSONDecode(result)
    end
    
    local Server, Next
    repeat
       local Servers = ListServers(Next)
       if not Servers then return end -- Fail safe

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

    -- Clean specific toggles first
    if State.InfJumpConnection then
        State.InfJumpConnection:Disconnect()
        State.InfJumpConnection = nil
    end

    if State.ESPConnection then
        State.ESPConnection:Disconnect()
        State.ESPConnection = nil
    end

    if Utils then
        Utils:DeepClean()
    end

    State.SpeedEnabled = false
    State.JumpEnabled = false
    State.InfJump = false
    State.Spinbot = false
    State.ESP = false
    State.Fullbright = false
    State.Noclip = false
    
    getgenv().FSS_Universal_Stop = nil
    
    print("[FSSHUB] Universal Unload Complete.")
end

getgenv().FSS_Universal_Stop = Cleanup

-- 5. Return Configuration
return {
    Name = "Universal V7.2",
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
