-- [[ FSSHUB MODULE: DEV SUITE V2.0 ]] --
-- Advanced Debugging Tool for Developers Only

local Debugger = {}
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

function Debugger.Show()
    -- Cek Executor GUI Root
    local Parent = gethui and gethui() or CoreGui
    if Parent:FindFirstChild("FSSHUB_DevSuite") then
        Parent.FSSHUB_DevSuite:Destroy()
    end

    -- 1. UI CONSTRUCTION
    local Screen = Instance.new("ScreenGui")
    Screen.Name = "FSSHUB_DevSuite"
    Screen.Parent = Parent
    Screen.ResetOnSpawn = false
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Parent = Screen
    Main.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.new(0, 600, 0, 400)
    Main.Active = true
    Main.Draggable = true 

    -- Styling
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Main; Stroke.Color = Color3.fromRGB(255, 50, 100); Stroke.Thickness = 2 -- Merah Dev
    local Corner = Instance.new("UICorner"); Corner.Parent = Main; Corner.CornerRadius = UDim.new(0, 8)

    -- Header
    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 8)
    Title.Size = UDim2.new(1, -30, 0, 20)
    Title.Font = Enum.Font.Code
    Title.Text = "FSSHUB DEVELOPER SUITE [ADMIN]"
    Title.TextColor3 = Color3.fromRGB(255, 50, 100)
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- [[ PANEL KIRI: MONITOR ]] --
    local MonitorFrame = Instance.new("Frame")
    MonitorFrame.Parent = Main
    MonitorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MonitorFrame.Position = UDim2.new(0, 15, 0, 40)
    MonitorFrame.Size = UDim2.new(0, 200, 1, -55)
    Instance.new("UICorner", MonitorFrame).CornerRadius = UDim.new(0, 6)

    local MonitorList = Instance.new("TextLabel")
    MonitorList.Parent = MonitorFrame
    MonitorList.BackgroundTransparency = 1
    MonitorList.Size = UDim2.new(1, -20, 1, -20)
    MonitorList.Position = UDim2.new(0, 10, 0, 10)
    MonitorList.Font = Enum.Font.Code
    MonitorList.TextSize = 12
    MonitorList.TextColor3 = Color3.fromRGB(200, 200, 200)
    MonitorList.TextXAlignment = Enum.TextXAlignment.Left
    MonitorList.TextYAlignment = Enum.TextYAlignment.Top
    MonitorList.Text = "Initializing Monitor..."

    -- [[ PANEL KANAN: LOGS ]] --
    local LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Parent = Main
    LogFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    LogFrame.Position = UDim2.new(0, 225, 0, 40)
    LogFrame.Size = UDim2.new(1, -240, 1, -55)
    LogFrame.CanvasSize = UDim2.new(0,0,0,0)
    LogFrame.ScrollBarThickness = 4
    Instance.new("UICorner", LogFrame).CornerRadius = UDim.new(0, 6)
    
    local UIList = Instance.new("UIListLayout"); UIList.Parent = LogFrame

    -- [[ FUNGSI LOGGING ]] --
    local function AddLog(text, color)
        if not Main.Parent then return end
        local Lbl = Instance.new("TextLabel")
        Lbl.Parent = LogFrame
        Lbl.BackgroundTransparency = 1
        Lbl.Size = UDim2.new(1, -5, 0, 0)
        Lbl.AutomaticSize = Enum.AutomaticSize.Y
        Lbl.Font = Enum.Font.Code
        Lbl.TextSize = 11
        Lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        Lbl.Text = string.format("[%s] %s", os.date("%X"), text)
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.TextWrapped = true
        LogFrame.CanvasPosition = Vector2.new(0, 99999)
    end

    -- Capture Output Roblox
    LogService.MessageOut:Connect(function(msg, type)
        local color = Color3.fromRGB(255, 255, 255)
        if type == Enum.MessageType.MessageError then color = Color3.fromRGB(255, 80, 80)
        elseif type == Enum.MessageType.MessageWarning then color = Color3.fromRGB(255, 200, 50) end
        AddLog(msg, color)
    end)

    -- [[ MONITOR UPDATE LOOP ]] --
    task.spawn(function()
        while Main.Parent do
            local fps = math.floor(Workspace:GetRealPhysicsFPS())
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1])
            local mem = math.floor(Stats:GetTotalMemoryUsageMb())
            
            -- Player Stats
            local plr = Players.LocalPlayer
            local char = plr.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            local ws = hum and math.floor(hum.WalkSpeed) or "N/A"
            local jp = hum and math.floor(hum.JumpPower) or "N/A"
            local sit = hum and tostring(hum.Sit) or "N/A"
            local vel = root and math.floor(root.AssemblyLinearVelocity.Magnitude) or 0
            
            -- Script Internal Stats (Ambil dari _G atau getgenv jika ada)
            -- Kita tidak bisa akses variabel lokal 'State' dari file lain secara langsung
            -- Tapi kita bisa monitor efek sampingnya.
            
            local monitorText = string.format(
                [[
[SYSTEM]
FPS: %d
Ping: %d ms
Mem: %d MB

[CHARACTER]
WalkSpeed: %s
JumpPower: %s
Sitting: %s
Velocity: %d

[GLOBAL FLAGS]
Univ_Stop: %s
WaveZ_Stop: %s
                ]], 
                fps, ping, mem, 
                ws, jp, sit, vel,
                tostring(getgenv().FSS_Universal_Stop ~= nil),
                tostring(getgenv().FSS_WaveZ_Stop ~= nil)
            )
            
            MonitorList.Text = monitorText
            task.wait(0.1)
        end
    end)

    -- [[ TOMBOL ACTIONS ]] --
    local function CreateActionBtn(text, pos, func)
        local Btn = Instance.new("TextButton")
        Btn.Parent = Main
        Btn.Size = UDim2.new(0, 80, 0, 25)
        Btn.Position = pos
        Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        Btn.Text = text
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 10
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        Btn.MouseButton1Click:Connect(func)
    end

    -- Tombol 1: Force Cleanup (Global)
    CreateActionBtn("NUKE SCRIPT", UDim2.new(1, -90, 0, 8), function()
        AddLog("Attempting Global Cleanup...", Color3.fromRGB(255, 50, 50))
        if getgenv().FSS_Universal_Stop then 
            getgenv().FSS_Universal_Stop() 
            AddLog("Universal Script Killed.", Color3.fromRGB(100, 255, 100))
        end
        if getgenv().FSS_WaveZ_Stop then 
            getgenv().FSS_WaveZ_Stop() 
            AddLog("Wave Z Script Killed.", Color3.fromRGB(100, 255, 100))
        end
    end)

    -- Tombol 2: Physics Reset Manual
    CreateActionBtn("RESET PHY", UDim2.new(1, -180, 0, 8), function()
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Sit = true
            AddLog("Physics Reset Triggered (Sit).", Color3.fromRGB(255, 200, 50))
            task.delay(0.1, function() char.Humanoid.Sit = false end)
        end
    end)
    
    -- Tombol 3: Close
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Main
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -25, 0, 375)
    CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

    AddLog("Developer Suite V2.0 Initialized.", Color3.fromRGB(100, 255, 100))
    AddLog("Monitoring Active...", Color3.fromRGB(200, 200, 200))
end

return Debugger
