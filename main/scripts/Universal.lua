-- [[ FSSHUB: UNIVERSAL MODULE (V2.7) ]] --
-- Changelog: Optimized Speed/Jump Loops (Anti-Spam Property)

if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Load Library
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local Library = loadstring(game:HttpGet(LIB_URL))()

if not Library then return end

local Window = Library:Window("FSS HUB | UNIVERSAL V2.7")

-- Global Config
getgenv().FSS_Universal = {
    Speed = 16, Jump = 50, InfJump = false, Noclip = false, 
    ESP = false, ESP_Info = false, Fullbright = false, Connections = {}
}

-- [TAB 1: LOCAL PLAYER]
local PlayerTab = Window:Section("Local Player")

PlayerTab:Toggle("Enable Speed", false, function(state)
    getgenv().FSS_Universal.SpeedEnabled = state
    if state then
        task.spawn(function()
            while getgenv().FSS_Universal.SpeedEnabled do
                task.wait() -- Tunggu 1 frame
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        local hum = LocalPlayer.Character.Humanoid
                        local target = getgenv().FSS_Universal.Speed
                        -- [OPTIMASI] Hanya ubah jika nilainya beda (Mencegah Spam Network)
                        if hum.WalkSpeed ~= target then
                            hum.WalkSpeed = target
                        end
                    end
                end)
            end
        end)
    else
        pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
    end
end)

PlayerTab:Slider("WalkSpeed Value", 16, 300, 16, function(value)
    getgenv().FSS_Universal.Speed = value
end)

PlayerTab:Toggle("Enable Jump", false, function(state)
    getgenv().FSS_Universal.JumpEnabled = state
    if state then
        task.spawn(function()
            while getgenv().FSS_Universal.JumpEnabled do
                task.wait()
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        local hum = LocalPlayer.Character.Humanoid
                        local target = getgenv().FSS_Universal.Jump
                        
                        hum.UseJumpPower = true
                        -- [OPTIMASI] Hanya ubah jika nilainya beda
                        if hum.JumpPower ~= target then
                            hum.JumpPower = target
                        end
                    end
                end)
            end
        end)
    else
        pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end)
    end
end)

PlayerTab:Slider("JumpPower Value", 50, 400, 50, function(value)
    getgenv().FSS_Universal.Jump = value
end)

PlayerTab:Toggle("Infinite Jump", false, function(state)
    getgenv().FSS_Universal.InfJump = state
    if state then
        local connection = UserInputService.JumpRequest:Connect(function()
            if getgenv().FSS_Universal.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        table.insert(getgenv().FSS_Universal.Connections, connection)
    end
end)

PlayerTab:Toggle("Noclip", false, function(state)
    getgenv().FSS_Universal.Noclip = state
    if state then
        local connection = RunService.Stepped:Connect(function()
            if getgenv().FSS_Universal.Noclip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
        table.insert(getgenv().FSS_Universal.Connections, connection)
    end
end)

-- [TAB 2: VISUALS]
local VisualTab = Window:Section("Visuals")

local function CreateBillboard(char, name)
    if char:FindFirstChild("FSS_Info") then char.FSS_Info:Destroy() end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local bill = Instance.new("BillboardGui")
    bill.Name = "FSS_Info"
    bill.Adornee = head
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.StudsOffset = Vector3.new(0, 2, 0)
    bill.AlwaysOnTop = true
    
    local txt = Instance.new("TextLabel", bill)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = Color3.fromRGB(140, 80, 255)
    txt.TextStrokeTransparency = 0
    txt.TextStrokeColor3 = Color3.new(0,0,0)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 12
    txt.Text = name
    
    bill.Parent = char
    return txt
end

VisualTab:Toggle("Player ESP (Chams)", false, function(state)
    getgenv().FSS_Universal.ESP = state
    
    local function AddESP(plr)
        if plr == LocalPlayer then return end
        local function UpdateChar(char)
            if not getgenv().FSS_Universal.ESP then return end
            if char:FindFirstChild("Highlight_FSS") then char.Highlight_FSS:Destroy() end
            
            local hl = Instance.new("Highlight")
            hl.Name = "Highlight_FSS"
            hl.Adornee = char
            hl.FillColor = Color3.fromRGB(140, 80, 255)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.Parent = char
        end
        if plr.Character then UpdateChar(plr.Character) end
        plr.CharacterAdded:Connect(UpdateChar)
    end

    if state then
        for _, p in ipairs(Players:GetPlayers()) do AddESP(p) end
        Players.PlayerAdded:Connect(AddESP)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Highlight_FSS") then
                p.Character.Highlight_FSS:Destroy()
            end
        end
    end
end)

VisualTab:Toggle("Show Names & Dist", false, function(state)
    getgenv().FSS_Universal.ESP_Info = state
    if state then
        task.spawn(function()
            while getgenv().FSS_Universal.ESP_Info do
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                        local root = p.Character:FindFirstChild("HumanoidRootPart")
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        
                        if root and myRoot then
                            local dist = math.floor((root.Position - myRoot.Position).Magnitude)
                            local txtLabel = p.Character:FindFirstChild("FSS_Info") and p.Character.FSS_Info:FindFirstChild("TextLabel")
                            
                            if not txtLabel then 
                                txtLabel = CreateBillboard(p.Character, p.Name) 
                            end
                            
                            if txtLabel then
                                txtLabel.Text = p.Name .. " [" .. dist .. "m]"
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("FSS_Info") then
                p.Character.FSS_Info:Destroy()
            end
        end
    end
end)

-- [TAB 3: WORLD]
local WorldTab = Window:Section("World")

WorldTab:Toggle("Fullbright", false, function(state)
    getgenv().FSS_Universal.Fullbright = state
    if state then
        task.spawn(function()
            while getgenv().FSS_Universal.Fullbright do
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                task.wait(1)
            end
        end)
    else
        Lighting.GlobalShadows = true
    end
end)

-- [TAB 4: MISC]
local MiscTab = Window:Section("Misc")

MiscTab:Button("Server Hop (Join New)", function()
    local PlaceId = game.PlaceId
    local Api = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    
    local function ListServers(cursor)
        local Raw = game:HttpGet(Api .. ((cursor and "&cursor="..cursor) or ""))
        return HttpService:JSONDecode(Raw)
    end
    
    local Server, Next
    repeat
        local Servers = ListServers(Next)
        Server = Servers.data[math.random(1, #Servers.data)]
        Next = Servers.nextPageCursor
    until Server.playing < Server.maxPlayers and Server.id ~= game.JobId
    
    TeleportService:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
end)

MiscTab:Button("Rejoin Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- [SETTINGS]
local SettingsTab = Window:Section("Settings")
SettingsTab:Button("Unload & Cleanup", function()
    getgenv().FSS_Universal.SpeedEnabled = false
    getgenv().FSS_Universal.JumpEnabled = false
    getgenv().FSS_Universal.InfJump = false
    getgenv().FSS_Universal.Noclip = false
    getgenv().FSS_Universal.ESP = false
    getgenv().FSS_Universal.ESP_Info = false
    getgenv().FSS_Universal.Fullbright = false
    
    for _, conn in pairs(getgenv().FSS_Universal.Connections) do
        if conn then conn:Disconnect() end
    end
    getgenv().FSS_Universal.Connections = {}
    Window:Destroy()
end)

Library:Init()
