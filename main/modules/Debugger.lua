-- [[ FSSHUB MODULE: DEV SUITE V3.0 (PRO TOOLS) ]] --
-- Features: F10 Keybind, Selectable Text, Search/Filter, Minimize

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
    Main.Size = UDim2.new(0, 650, 0, 450)
    Main.Active = true
    Main.Draggable = true 
    Main.ClipsDescendants = true 

    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Main; Stroke.Color = Color3.fromRGB(255, 50, 100); Stroke.Thickness = 2 
    local Corner = Instance.new("UICorner"); Corner.Parent = Main; Corner.CornerRadius = UDim.new(0, 8)

    -- Header
    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 8)
    Title.Size = UDim2.new(1, -100, 0, 20)
    Title.Font = Enum.Font.Code
    Title.Text = "FSSHUB DEV SUITE [TOGGLE: F10]"
    Title.TextColor3 = Color3.fromRGB(255, 50, 100)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- [[ SEARCH BAR ]] --
    local SearchBg = Instance.new("Frame")
    SearchBg.Parent = Main
    SearchBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    SearchBg.Size = UDim2.new(0.4, 0, 0, 25)
    SearchBg.Position = UDim2.new(0.55, 0, 0, 6)
    Instance.new("UICorner", SearchBg).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", SearchBg).Color = Color3.fromRGB(60,60,70)

    local SearchInput = Instance.new("TextBox")
    SearchInput.Parent = SearchBg
    SearchInput.BackgroundTransparency = 1
    SearchInput.Size = UDim2.new(1, -10, 1, 0)
    SearchInput.Position = UDim2.new(0, 5, 0, 0)
    SearchInput.Font = Enum.Font.Code
    SearchInput.Text = ""
    SearchInput.PlaceholderText = "Find/Filter Logs..."
    SearchInput.TextColor3 = Color3.fromRGB(200, 200, 200)
    SearchInput.TextSize = 12
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left

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
    MonitorFrame.Size = UDim2.new(0, 180, 1, -15)
    Instance.new("UICorner", MonitorFrame).CornerRadius = UDim.new(0, 6)

    local MonitorList = Instance.new("TextLabel")
    MonitorList.Parent = MonitorFrame
    MonitorList.BackgroundTransparency = 1
    MonitorList.Size = UDim2.new(1, -20, 1, -20)
    MonitorList.Position = UDim2.new(0, 10, 0, 10)
    MonitorList.Font = Enum.Font.Code
    MonitorList.TextSize = 11
    MonitorList.TextColor3 = Color3.fromRGB(200, 200, 200)
    MonitorList.TextXAlignment = Enum.TextXAlignment.Left
    MonitorList.TextYAlignment = Enum.TextYAlignment.Top
    MonitorList.Text = "Initializing Monitor..."

    -- [[ PANEL KANAN: LOGS ]] --
    local LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Parent = ContentHolder
    LogFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    LogFrame.Position = UDim2.new(0, 205, 0, 0)
    LogFrame.Size = UDim2.new(1, -220, 1, -15)
    LogFrame.CanvasSize = UDim2.new(0,0,0,0)
    LogFrame.ScrollBarThickness = 4
    Instance.new("UICorner", LogFrame).CornerRadius = UDim.new(0, 6)
    
    local UIList = Instance.new("UIListLayout"); UIList.Parent = LogFrame

    -- [[ LOGIC LOGGING & SEARCH ]] --
    local LogsCache = {} -- Menyimpan data log {text, color}
    
    local function RenderLogs(filterText)
        -- Bersihkan tampilan lama
        for _, v in pairs(LogFrame:GetChildren()) do
            if v:IsA("TextBox") then v:Destroy() end
        end
        
        filterText = filterText and filterText:lower() or ""
        local totalHeight = 0
        
        for _, log in ipairs(LogsCache) do
            -- Filter logic
            if filterText == "" or log.text:lower():find(filterText) then
                local Lbl = Instance.new("TextBox") -- Gunakan TextBox agar bisa Select/Copy
                Lbl.Parent = LogFrame
                Lbl.BackgroundTransparency = 1
                Lbl.Size = UDim2.new(1, -5, 0, 0)
                Lbl.AutomaticSize = Enum.AutomaticSize.Y
                Lbl.Font = Enum.Font.Code
                Lbl.TextSize = 11
                Lbl.TextColor3 = log.color
                Lbl.Text = log.text
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.TextWrapped = true
                Lbl.ClearTextOnFocus = false
                Lbl.TextEditable = false -- Read Only tapi Selectable
                
                totalHeight = totalHeight + Lbl.AbsoluteSize.Y
            end
        end
        LogFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
        LogFrame.CanvasPosition = Vector2.new(0, 99999)
    end

    local function AddLog(text, color)
        if not Main.Parent then return end
        color = color or Color3.fromRGB(255, 255, 255)
        local fullText = string.format("[%s] %s", os.date("%X"), text)
        
        table.insert(LogsCache, {text = fullText, color = color})
        
        -- Batasi cache agar tidak lag (Max 200 logs)
        if #LogsCache > 200 then table.remove(LogsCache, 1) end
        
        -- Render ulang hanya jika tidak sedang mencari (agar tidak spam refresh)
        if SearchInput.Text == "" then
            local Lbl = Instance.new("TextBox")
            Lbl.Parent = LogFrame
            Lbl.BackgroundTransparency = 1
            Lbl.Size = UDim2.new(1, -5, 0, 0)
            Lbl.AutomaticSize = Enum.AutomaticSize.Y
            Lbl.Font = Enum.Font.Code
            Lbl.TextSize = 11
            Lbl.TextColor3 = color
            Lbl.Text = fullText
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.TextWrapped = true
            Lbl.ClearTextOnFocus = false
            Lbl.TextEditable = false
            
            LogFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
            LogFrame.CanvasPosition = Vector2.new(0, 99999)
        end
    end

    -- Search Event
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        RenderLogs(SearchInput.Text)
    end)

    -- Capture Roblox Logs
    LogService.MessageOut:Connect(function(msg, type)
        local color = Color3.fromRGB(255, 255, 255)
        if type == Enum.MessageType.MessageError then color = Color3.fromRGB(255, 80, 80)
        elseif type == Enum.MessageType.MessageWarning then color = Color3.fromRGB(255, 200, 50) end
        AddLog(msg, color)
    end)

    -- [[ WINDOW CONTROLS ]] --
    local isMinimized = false
    local function ToggleMinimize()
        isMinimized = not isMinimized
        if isMinimized then
            Main:TweenSize(UDim2.new(0, 650, 0, 35), "Out", "Quad", 0.3, true)
            ContentHolder.Visible = false
        else
            Main:TweenSize(UDim2.new(0, 650, 0, 450), "Out", "Quad", 0.3, true)
            task.wait(0.2)
            ContentHolder.Visible = true
        end
    end

    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = Main; MinBtn.Text = "-"; MinBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    MinBtn.BackgroundTransparency = 1; MinBtn.Size = UDim2.new(0, 25, 0, 25)
    MinBtn.Position = UDim2.new(1, -55, 0, 5); MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 18
    MinBtn.MouseButton1Click:Connect(ToggleMinimize)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Main; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.BackgroundTransparency = 1; CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -30, 0, 5); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14
    CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

    -- [[ KEYBIND F10 ]] --
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.F10 then 
            Main.Visible = not Main.Visible
        end
    end)

    -- [[ ACTIONS ]] --
    local function CreateActionBtn(text, pos, func)
        local Btn = Instance.new("TextButton")
        Btn.Parent = Main; Btn.Size = UDim2.new(0, 60, 0, 20); Btn.Position = pos
        Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50); Btn.Text = text
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Font = Enum.Font.Code; Btn.TextSize = 10
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        Btn.MouseButton1Click:Connect(func)
    end

    CreateActionBtn("NUKE", UDim2.new(1, -120, 0, 8), function()
        AddLog("FORCE NUKE...", Color3.fromRGB(255, 0, 0))
        if getgenv().FSS_Universal_Stop then getgenv().FSS_Universal_Stop() end
        if getgenv().FSS_WaveZ_Stop then getgenv().FSS_WaveZ_Stop() end
    end)

    CreateActionBtn("RESET", UDim2.new(1, -185, 0, 8), function()
        local c = Players.LocalPlayer.Character
        if c and c:FindFirstChild("Humanoid") then
            c.Humanoid.Sit = true
            task.delay(0.1, function() c.Humanoid.Sit = false end)
            AddLog("Physics Reset.", Color3.fromRGB(255, 255, 0))
        end
    end)

    -- Monitor Loop (Simplified)
    task.spawn(function()
        while Main.Parent do
            if Main.Visible then
                local fps = math.floor(workspace:GetRealPhysicsFPS())
                local ping = 0; pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1]) end)
                local mem = math.floor(Stats:GetTotalMemoryUsageMb())
                local ws = "N/A"; local jp = "N/A"; local sit = "N/A"
                if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    ws = math.floor(Players.LocalPlayer.Character.Humanoid.WalkSpeed)
                    jp = math.floor(Players.LocalPlayer.Character.Humanoid.JumpPower)
                    sit = tostring(Players.LocalPlayer.Character.Humanoid.Sit)
                end
                
                MonitorList.Text = string.format("[SYS]\nFPS: %d\nPing: %d\nMem: %d\n\n[CHAR]\nWS: %s\nJP: %s\nSit: %s\n\n[GLOBAL]\nU_Stop: %s\nZ_Stop: %s", 
                    fps, ping, mem, ws, jp, sit, tostring(getgenv().FSS_Universal_Stop~=nil), tostring(getgenv().FSS_WaveZ_Stop~=nil))
            end
            task.wait(0.2)
        end
    end)

    AddLog("Developer Console V3.0 Ready.", Color3.fromRGB(100, 255, 100))
    AddLog("Toggle: F10 | Text Selection Enabled", Color3.fromRGB(200, 200, 200))
end

return Debugger
