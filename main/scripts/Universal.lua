-- [[ FSSHUB: UNIVERSAL MODULE (V1.0) ]] --
-- Dibuat untuk kompatibilitas maksimal di berbagai game

if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Load Library (Menggunakan Lib yang sudah ada)
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local Library = loadstring(game:HttpGet(LIB_URL))()

if not Library then return end

local Window = Library:Window("FSS HUB | UNIVERSAL")

-- Global Config & State
getgenv().FSS_Universal = {
    Speed = 16,
    Jump = 50,
    InfJump = false,
    Noclip = false,
    ESP = false,
    Fullbright = false,
    Connections = {} -- Table untuk menyimpan koneksi agar bisa dibersihkan (Memory Management)
}

-- [TAB 1: LOCAL PLAYER]
local PlayerTab = Window:Section("Local Player")

-- WalkSpeed Logic (Loop agar tidak di-reset game)
PlayerTab:Toggle("Enable Speed", false, function(state)
    getgenv().FSS_Universal.SpeedEnabled = state
    if state then
        task.spawn(function()
            while getgenv().FSS_Universal.SpeedEnabled do
                task.wait()
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.WalkSpeed = getgenv().FSS_Universal.Speed
                    end
                end)
            end
        end)
    else
        pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
    end
end)

PlayerTab:Slider("WalkSpeed Value", 16, 200, 16, function(value)
    getgenv().FSS_Universal.Speed = value
end)

-- JumpPower Logic
PlayerTab:Toggle("Enable Jump", false, function(state)
    getgenv().FSS_Universal.JumpEnabled = state
    if state then
        task.spawn(function()
            while getgenv().FSS_Universal.JumpEnabled do
                task.wait()
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.UseJumpPower = true
                        LocalPlayer.Character.Humanoid.JumpPower = getgenv().FSS_Universal.Jump
                    end
                end)
            end
        end)
    else
        pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end)
    end
end)

PlayerTab:Slider("JumpPower Value", 50, 300, 50, function(value)
    getgenv().FSS_Universal.Jump = value
end)

-- Infinite Jump
PlayerTab:Toggle("Infinite Jump", false, function(state)
    getgenv().FSS_Universal.InfJump = state
    if state then
        local connection = UserInputService.JumpRequest:Connect(function()
            if getgenv().FSS_Universal.InfJump then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        table.insert(getgenv().FSS_Universal.Connections, connection)
    else
        -- Logic pemutusan koneksi ada di sistem Unload nanti
    end
end)

-- Noclip (Stepped Event)
PlayerTab:Toggle("Noclip", false, function(state)
    getgenv().FSS_Universal.Noclip = state
    if state then
        local connection = RunService.Stepped:Connect(function()
            if getgenv().FSS_Universal.Noclip and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        table.insert(getgenv().FSS_Universal.Connections, connection)
    end
end)

-- [TAB 2: VISUALS]
local VisualTab = Window:Section("Visuals")

VisualTab:Toggle("Player ESP", false, function(state)
    getgenv().FSS_Universal.ESP = state
    
    local function AddESP(plr)
        if plr == LocalPlayer then return end
        local function UpdateChar(char)
            if not getgenv().FSS_Universal.ESP then return end
            if char:FindFirstChild("Highlight_FSS") then char.Highlight_FSS:Destroy() end
            
            local hl = Instance.new("Highlight")
            hl.Name = "Highlight_FSS"
            hl.Adornee = char
            hl.FillColor = Color3.fromRGB(0, 255, 136) -- Warna Tema FSSHUB
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
        -- Hapus ESP jika dimatikan
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("Highlight_FSS") then
                p.Character.Highlight_FSS:Destroy()
            end
        end
    end
end)

-- [TAB 3: WORLD & UTILITY]
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
        Lighting.GlobalShadows = true -- Reset simple
    end
end)

-- [TAB 4: SETTINGS]
local SettingsTab = Window:Section("Settings")

SettingsTab:Button("Unload & Clean Up", function()
    -- Matikan semua flag global
    getgenv().FSS_Universal.SpeedEnabled = false
    getgenv().FSS_Universal.JumpEnabled = false
    getgenv().FSS_Universal.InfJump = false
    getgenv().FSS_Universal.Noclip = false
    getgenv().FSS_Universal.ESP = false
    getgenv().FSS_Universal.Fullbright = false
    
    -- Putuskan semua koneksi event
    for _, conn in pairs(getgenv().FSS_Universal.Connections) do
        if conn then conn:Disconnect() end
    end
    getgenv().FSS_Universal.Connections = {}
    
    -- Hapus GUI
    Window:Destroy()
end)
