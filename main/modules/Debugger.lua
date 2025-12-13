-- [[ FSSHUB MODULE: DEV SUITE V4.3 (OPTIMIZED) ]] --
-- Features: F10 Toggle, Optimized Logs (table.concat), Smooth Drag, Auto-Cleanup
-- Path: main/modules/Debugger.lua

local Debugger = {}
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

function Debugger.Show()
    -- Secure GUI Container Resolution
    local Parent = gethui and gethui() or CoreGui

    -- Cleanup Existing
    if Parent:FindFirstChild("FSSHUB_DevSuite") then
        Parent.FSSHUB_DevSuite:Destroy()
    end

    -- 1. MAIN UI SETUP
    local Screen = Instance.new("ScreenGui")
    Screen.Name = "FSSHUB_DevSuite"
    Screen.Parent = Parent
    Screen.ResetOnSpawn = false
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Connections = {} -- Store connections for cleanup

    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Parent = Screen
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.new(0, 700, 0, 500)
    Main.Active = true
    Main.ClipsDescendants = true 

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Color3.fromRGB(140, 80, 255)
    Stroke.Thickness = 2 

    -- [[ SMOOTH DRAG HANDLER ]] --
    local Dragging, DragInput, DragStart, StartPos

    table.insert(Connections, Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end))

    table.insert(Connections, Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            Main.Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
            )
        end
    end))

    -- Header
    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 10)
    Title.Size = UDim2.new(1, -100, 0, 20)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "FSSHUB DEBUGGER [F10] | V4.3 (HAWK)"
    Title.TextColor3 = Color3.fromRGB(140, 80, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- [[ CONTROL BAR ]] --
    local ControlBar = Instance.new("Frame")
    ControlBar.Parent = Main
    ControlBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ControlBar.Size = UDim2.new(1, -20, 0, 35)
    ControlBar.Position = UDim2.new(0, 10, 0, 40)
    Instance.new("UICorner", ControlBar).CornerRadius = UDim.new(0, 6)

    -- Search Box
    local SearchInput = Instance.new("TextBox")
    SearchInput.Parent = ControlBar
    SearchInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    SearchInput.Size = UDim2.new(0, 180, 0, 25)
    SearchInput.Position = UDim2.new(0, 5, 0.5, -12.5)
    SearchInput.Font = Enum.Font.Code
    SearchInput.PlaceholderText = "Search Logs..."
    SearchInput.Text = ""
    SearchInput.TextColor3 = Color3.fromRGB(220, 220, 220)
    SearchInput.TextSize = 12
    Instance.new("UICorner", SearchInput).CornerRadius = UDim.new(0, 4)

    -- Filter Buttons Logic
    local Filters = {Info = true, Warn = true, Error = true}
    
    local function CreateFilterBtn(text, color, xOffset, key)
        local Btn = Instance.new("TextButton")
        Btn.Parent = ControlBar
        Btn.Size = UDim2.new(0, 25, 0, 25)
        Btn.Position = UDim2.new(0, 190 + xOffset, 0.5, -12.5)
        Btn.BackgroundColor3 = color
        Btn.Text = text
        Btn.TextColor3 = Color3.new(0,0,0)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 11
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        
        table.insert(Connections, Btn.MouseButton1Click:Connect(function()
            Filters[key] = not Filters[key]
            Btn.BackgroundTransparency = Filters[key] and 0 or 0.6
            SearchInput.Text = SearchInput.Text .. " " 
            SearchInput.Text = string.sub(SearchInput.Text, 1, -2) 
        end))
    end

    CreateFilterBtn("I", Color3.fromRGB(255, 255, 255), 0, "Info")
    CreateFilterBtn("W", Color3.fromRGB(255, 200, 50), 30, "Warn")
    CreateFilterBtn("E", Color3.fromRGB(255, 80, 80), 60, "Error")

    -- [[ MONITOR PANEL (HIDDEN BY DEFAULT) ]] --
    local StatsVisible = false
    local MonitorFrame = Instance.new("Frame")
    MonitorFrame.Parent = Main
    MonitorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MonitorFrame.Size = UDim2.new(0, 200, 1, -85) -- Side Panel
    MonitorFrame.Position = UDim2.new(1, -210, 0, 80)
    MonitorFrame.Visible = false
    MonitorFrame.ZIndex = 10
    Instance.new("UICorner", MonitorFrame).CornerRadius = UDim.new(0, 6)
    local MStroke = Instance.new("UIStroke", MonitorFrame)
    MStroke.Color = Color3.fromRGB(60,60,70); MStroke.Thickness = 1

    local MonitorText = Instance.new("TextLabel")
    MonitorText.Parent = MonitorFrame
    MonitorText.BackgroundTransparency = 1
    MonitorText.Size = UDim2.new(1, -20, 1, -20)
    MonitorText.Position = UDim2.new(0, 10, 0, 10)
    MonitorText.Font = Enum.Font.Code
    MonitorText.TextSize = 11
    MonitorText.TextColor3 = Color3.fromRGB(200, 200, 200)
    MonitorText.TextXAlignment = Enum.TextXAlignment.Left
    MonitorText.TextYAlignment = Enum.TextYAlignment.Top
    MonitorText.Text = "Loading Stats..."

    -- Toggle Monitor Button
    local ToggleStatsBtn = Instance.new("TextButton")
    ToggleStatsBtn.Parent = ControlBar
    ToggleStatsBtn.Text = "STATS"
    ToggleStatsBtn.Size = UDim2.new(0, 50, 0, 25)
    ToggleStatsBtn.Position = UDim2.new(0, 290, 0.5, -12.5)
    ToggleStatsBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    ToggleStatsBtn.TextColor3 = Color3.new(1,1,1)
    ToggleStatsBtn.Font = Enum.Font.GothamBold
    ToggleStatsBtn.TextSize = 10
    Instance.new("UICorner", ToggleStatsBtn).CornerRadius = UDim.new(0, 4)
    
    table.insert(Connections, ToggleStatsBtn.MouseButton1Click:Connect(function()
        StatsVisible = not StatsVisible
        MonitorFrame.Visible = StatsVisible
        ToggleStatsBtn.BackgroundColor3 = StatsVisible and Color3.fromRGB(140, 80, 255) or Color3.fromRGB(50, 50, 60)
    end))

    -- [[ LOG CONTAINER (RICHTEXT ENABLED) ]] --
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Parent = Main
    LogScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    LogScroll.Position = UDim2.new(0, 10, 0, 85)
    LogScroll.Size = UDim2.new(1, -20, 1, -95)
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogScroll.ScrollBarThickness = 6
    Instance.new("UICorner", LogScroll).CornerRadius = UDim.new(0, 6)

    local LogDisplay = Instance.new("TextBox")
    LogDisplay.Name = "LogDisplay"
    LogDisplay.Parent = LogScroll
    LogDisplay.BackgroundTransparency = 1
    LogDisplay.Size = UDim2.new(1, -10, 1, 0)
    LogDisplay.Position = UDim2.new(0, 5, 0, 0)
    LogDisplay.Font = Enum.Font.Code
    LogDisplay.TextSize = 12
    LogDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
    LogDisplay.TextXAlignment = Enum.TextXAlignment.Left
    LogDisplay.TextYAlignment = Enum.TextYAlignment.Top
    LogDisplay.TextWrapped = true
    LogDisplay.MultiLine = true
    LogDisplay.ClearTextOnFocus = false
    LogDisplay.TextEditable = false 
    LogDisplay.AutomaticSize = Enum.AutomaticSize.Y
    LogDisplay.RichText = true -- AKTIFKAN WARNA
    LogDisplay.Text = "Waiting for logs..."

    -- [[ DATA MANAGEMENT ]] --
    local LogsCache = {}
    
    -- Fungsi Helper untuk Escape karakter XML agar tidak merusak RichText
    local function EscapeXml(str)
        return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;")
    end

    local function RefreshLogs()
        local query = SearchInput.Text:lower()
        local buffer = {}
        
        for _, log in ipairs(LogsCache) do
            -- Filter Logic
            local typePass = false
            if log.type == "Info" and Filters.Info then typePass = true end
            if log.type == "Warn" and Filters.Warn then typePass = true end
            if log.type == "Error" and Filters.Error then typePass = true end
            
            -- Search Logic (Cari di raw text, bukan yang sudah di-format)
            local searchPass = true
            if query ~= "" and not log.rawMsg:lower():find(query) then searchPass = false end
            
            if typePass and searchPass then
                -- Format Warna menggunakan RichText
                local colorTag = ""
                local prefix = ""
                
                if log.type == "Info" then 
                    colorTag = '<font color="#FFFFFF">' 
                    prefix = "[INFO] "
                elseif log.type == "Warn" then 
                    colorTag = '<font color="#FFC832">' -- Kuning
                    prefix = "[WARN] "
                elseif log.type == "Error" then 
                    colorTag = '<font color="#FF5050">' -- Merah
                    prefix = "[ERR] "
                end
                
                -- Optimization: Use table.insert instead of string concatenation
                table.insert(buffer, string.format('<font color="#AAAAAA">%s</font> %s%s%s</font>',
                    log.time, colorTag, prefix, EscapeXml(log.rawMsg)))
            end
        end
        -- Optimization: table.concat is much faster
        LogDisplay.Text = table.concat(buffer, "\n")
        LogScroll.CanvasPosition = Vector2.new(0, 99999)
    end

    local function AddLog(msg, type)
        -- Safety: Check if UI is still alive
        if not Main or not Main.Parent then return end

        local t = os.date("%X")
        local typeStr = "Info"
        if type == Enum.MessageType.MessageWarning then typeStr = "Warn"
        elseif type == Enum.MessageType.MessageError then typeStr = "Error" end
        
        table.insert(LogsCache, {time = t, rawMsg = msg, type = typeStr})
        if #LogsCache > 250 then table.remove(LogsCache, 1) end 
        
        RefreshLogs()
    end

    table.insert(Connections, SearchInput:GetPropertyChangedSignal("Text"):Connect(RefreshLogs))

    -- Global Log Listener (Will be cleaned up on Destroy)
    table.insert(Connections, LogService.MessageOut:Connect(AddLog))

    -- [[ MONITOR UPDATE LOOP ]] --
    -- Replaced while loop with RunService for better lifecycle management
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        if not Main or not Main.Parent then return end -- Safety break

        if Main.Visible and StatsVisible then
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            local ping = 0; pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1]) end)
            local mem = math.floor(Stats:GetTotalMemoryUsageMb())

            local ws, jp, sit, rootPos, vel = "N/A", "N/A", "N/A", "N/A", 0
            local char = Players.LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum then
                    ws = math.floor(hum.WalkSpeed)
                    jp = math.floor(hum.JumpPower)
                    sit = tostring(hum.Sit)
                end
                if root then
                    rootPos = string.format("%d, %d, %d", math.floor(root.Position.X), math.floor(root.Position.Y), math.floor(root.Position.Z))
                    vel = math.floor(root.AssemblyLinearVelocity.Magnitude)
                end
            end

            local activeFlags = ""
            if getgenv().FSS_Universal_Stop then activeFlags = activeFlags .. "[UNI] " end
            if getgenv().FSS_WaveZ_Stop then activeFlags = activeFlags .. "[WVZ] " end
            if activeFlags == "" then activeFlags = "None" end

            MonitorText.Text = string.format(
[[[SYSTEM]
FPS:  %d
Ping: %d ms
Mem:  %d MB

[CHARACTER]
WalkSpeed: %s
JumpPower: %s
Sitting:   %s
Velocity:  %d
Position:  %s

[SCRIPTS]
Active: %s]], 
            fps, ping, mem, ws, jp, sit, vel, rootPos, activeFlags)
        end
    end))

    -- [[ WINDOW CONTROLS ]] --
    local function CreateBtn(text, pos, func, color)
        local B = Instance.new("TextButton")
        B.Parent = Main
        B.Text = text
        B.Size = UDim2.new(0, 60, 0, 20)
        B.Position = pos
        B.BackgroundColor3 = Color3.fromRGB(40,40,50)
        B.TextColor3 = color or Color3.new(1,1,1)
        B.Font = Enum.Font.Code
        B.TextSize = 10
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
        table.insert(Connections, B.MouseButton1Click:Connect(func))
    end

    -- Copy All (Hapus tag rich text sebelum copy agar bersih)
    CreateBtn("COPY ALL", UDim2.new(1, -75, 0, 45), function()
        if setclipboard then
            local cleanText = ""
            for _, log in ipairs(LogsCache) do
                cleanText = cleanText .. string.format("[%s] [%s] %s\n", log.time, log.type:upper(), log.rawMsg)
            end
            setclipboard(cleanText)
            
            local oldText = LogDisplay.Text
            LogDisplay.Text = ">> COPIED CLEAN LOGS TO CLIPBOARD <<"
            task.delay(0.5, function()
                if LogDisplay and LogDisplay.Parent then
                    LogDisplay.Text = oldText
                end
            end)
        end
    end, Color3.fromRGB(100, 255, 100))

    CreateBtn("NUKE", UDim2.new(1, -145, 0, 45), function()
        if getgenv().FSS_Universal_Stop then getgenv().FSS_Universal_Stop() end
        if getgenv().FSS_WaveZ_Stop then getgenv().FSS_WaveZ_Stop() end
        AddLog("ALL SCRIPTS NUKED MANUALLY", Enum.MessageType.MessageError)
    end, Color3.fromRGB(255, 80, 80))

    -- Minimize & Close
    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = Main; MinBtn.Text = "-"; MinBtn.BackgroundTransparency = 1
    MinBtn.Size = UDim2.new(0, 25, 0, 25); MinBtn.Position = UDim2.new(1, -55, 0, 8)
    MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 18; MinBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    
    local isMin = false
    table.insert(Connections, MinBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        if isMin then Main:TweenSize(UDim2.new(0, 700, 0, 40), "Out", "Quad", 0.3, true)
        else Main:TweenSize(UDim2.new(0, 700, 0, 500), "Out", "Quad", 0.3, true) end
    end))

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Main; CloseBtn.Text = "X"; CloseBtn.BackgroundTransparency = 1
    CloseBtn.Size = UDim2.new(0, 25, 0, 25); CloseBtn.Position = UDim2.new(1, -30, 0, 8)
    CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    table.insert(Connections, CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end))

    -- Global Keybind Listener
    table.insert(Connections, UserInputService.InputBegan:Connect(function(i, p)
        if not p and i.KeyCode == Enum.KeyCode.F10 then
            if Main then Main.Visible = not Main.Visible end
        end
    end))

    -- [[ AUTO CLEANUP SYSTEM ]] --
    Screen.Destroying:Connect(function()
        print("[FSSHUB] Debugger UI Destroyed. Cleaning up " .. #Connections .. " connections...")
        for _, conn in ipairs(Connections) do
            if conn.Connected then conn:Disconnect() end
        end
        Connections = {}
    end)

    AddLog("Debugger V4.3 Loaded. Hawk Optimized.", Enum.MessageType.MessageOutput)
end

return Debugger
