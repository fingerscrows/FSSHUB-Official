-- [[ FSSHUB MODULE: DEV SUITE V2.1 ]] --
-- Features: Minimize Button, Toggle Keybind (F9), Advanced Monitor

local Debugger = {}
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
    Main.ClipsDescendants = true -- Agar konten terpotong saat minimize

    -- Styling
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Main; Stroke.Color = Color3.fromRGB(255, 50, 100); Stroke.Thickness = 2 
    local Corner = Instance.new("UICorner"); Corner.Parent = Main; Corner.CornerRadius = UDim.new(0, 8)

    -- Header
    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 8)
    Title.Size = UDim2.new(1, -80, 0, 20)
    Title.Font = Enum.Font.Code
    Title.Text = "FSSHUB DEV SUITE [TOGGLE: F9]"
    Title.TextColor3 = Color3.fromRGB(255, 50, 100)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- [[ CONTAINER CONTENT ]] --
    local ContentHolder = Instance.new("Frame")
    ContentHolder.Name = "Content"
    ContentHolder.Parent = Main
    ContentHolder.BackgroundTransparency = 1
    ContentHolder.Size = UDim2.new(1, 0, 1, -40)
    ContentHolder.Position = UDim2.new(0, 0, 0, 40)

    -- [[ PANEL KIRI: MONITOR ]] --
    local MonitorFrame = Instance.new("Frame")
    MonitorFrame.Parent = ContentHolder
    MonitorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MonitorFrame.Position = UDim2.new(0, 15, 0, 0)
    MonitorFrame.Size = UDim2.new(0, 200, 1, -15)
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
    LogFrame.Parent = ContentHolder
    LogFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    LogFrame.Position = UDim2.new(0, 225, 0, 0)
    LogFrame.Size = UDim2.new(1, -240, 1, -15)
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

    LogService.MessageOut:Connect(function(msg, type)
        local color = Color3.fromRGB(255, 255, 255)
        if type == Enum.MessageType.MessageError then color = Color3.fromRGB(255, 80, 80)
        elseif type == Enum.MessageType.MessageWarning then color = Color3.fromRGB(255, 200, 50) end
        AddLog(msg, color)
    end)

    -- [[ MONITOR UPDATE LOOP ]] --
    task.spawn(function()
        while Main.Parent do
            if Main.Visible then
                local fps = math.floor(workspace:GetRealPhysicsFPS())
                local ping = 0
                pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1]) end)
                local mem = math.floor(Stats:GetTotalMemoryUsageMb())
                
                local plr = Players.LocalPlayer
                local char = plr.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                local ws = hum and math.floor(hum.WalkSpeed) or "N/A"
                local jp = hum and math.floor(hum.JumpPower) or "N/A"
                local sit = hum and tostring(hum.Sit) or "N/A"
                local vel = root and math.floor(root.AssemblyLinearVelocity.Magnitude) or 0
                
                local monitorText = string.format(
                    [[
[SYSTEM]
FPS: %d | Ping: %d ms
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
            end
            task.wait(0.2)
        end
    end)

    -- [[ WINDOW CONTROLS ]] --
    local isMinimized = false
    
    local function ToggleMinimize()
        isMinimized = not isMinimized
        if isMinimized then
            Main:TweenSize(UDim2.new(0, 600, 0, 35), "Out", "Quad", 0.3, true)
            ContentHolder.Visible = false
        else
            Main:TweenSize(UDim2.new(0, 600, 0, 400), "Out", "Quad", 0.3, true)
            task.wait(0.2)
            ContentHolder.Visible = true
        end
    end

    -- Tombol Minimize (-)
    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = Main
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    MinBtn.BackgroundTransparency = 1
    MinBtn.Size = UDim2.new(0, 25, 0, 25)
    MinBtn.Position = UDim2.new(1, -55, 0, 5)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 18
    MinBtn.MouseButton1Click:Connect(ToggleMinimize)

    -- Tombol Close (X)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Main
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -30, 0, 5)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

    -- [[ KEYBIND TOGGLE ]] --
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.F9 then -- Default Keybind F9
            Main.Visible = not Main.Visible
        end
    end)

    -- [[ TOMBOL ACTIONS (NUKE/RESET) ]] --
    local function CreateActionBtn(text, pos, func)
        local Btn = Instance.new("TextButton")
        Btn.Parent = Main
        Btn.Size = UDim2.new(0, 80, 0, 20)
        Btn.Position = pos
        Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        Btn.Text = text
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Font = Enum.Font.Code
        Btn.TextSize = 10
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        Btn.MouseButton1Click:Connect(func)
    end

    -- Tombol ditempatkan di Header agar tetap terlihat saat minimized
    CreateActionBtn("NUKE", UDim2.new(1, -150, 0, 8), function()
        AddLog("NUKE TRIGGERED!", Color3.fromRGB(255, 0, 0))
        if getgenv().FSS_Universal_Stop then getgenv().FSS_Universal_Stop() end
        if getgenv().FSS_WaveZ_Stop then getgenv().FSS_WaveZ_Stop() end
    end)

    CreateActionBtn("RESET", UDim2.new(1, -240, 0, 8), function()
        local c = Players.LocalPlayer.Character
        if c and c:FindFirstChild("Humanoid") then
            c.Humanoid.Sit = true
            task.delay(0.1, function() c.Humanoid.Sit = false end)
            AddLog("Physics Reset.", Color3.fromRGB(255, 255, 0))
        end
    end)

    AddLog("Developer Console V2.1 Ready.", Color3.fromRGB(100, 255, 100))
    AddLog("Press F9 to Toggle Visibility.", Color3.fromRGB(200, 200, 200))
end

return Debugger
