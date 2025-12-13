-- [[ FSSHUB MODULE: DEV SUITE V4.3 (SCANNER EDITION) ]] --
-- Features: F10 Toggle, RichText Logs, Tab System, Smart Object Scanner
-- Path: main/modules/Debugger.lua

local Debugger = {}
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function Debugger.Show()
    -- Secure GUI Container Resolution
    local Parent = gethui and gethui() or CoreGui
    if Parent:FindFirstChild("FSSHUB_DevSuite") then
        Parent.FSSHUB_DevSuite:Destroy()
    end

    -- 1. MAIN UI
    local Screen = Instance.new("ScreenGui")
    Screen.Name = "FSSHUB_DevSuite"
    Screen.Parent = Parent
    Screen.ResetOnSpawn = false
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Parent = Screen
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.new(0, 700, 0, 500)
    Main.Active = true
    Main.Draggable = true 
    Main.ClipsDescendants = true 

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Color3.fromRGB(140, 80, 255)
    Stroke.Thickness = 2 

    -- Header
    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 15, 0, 10)
    Title.Size = UDim2.new(1, -100, 0, 20)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "FSSHUB DEBUGGER [F10] | V4.3"
    Title.TextColor3 = Color3.fromRGB(140, 80, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- [[ TAB SYSTEM ]] --
    local TabContainer = Instance.new("Frame")
    TabContainer.Parent = Main
    TabContainer.BackgroundTransparency = 1
    TabContainer.Position = UDim2.new(0, 250, 0, 8)
    TabContainer.Size = UDim2.new(0, 200, 0, 25)

    local CurrentTab = "Console"
    local Tabs = {}

    local function SwitchTab(tabName)
        CurrentTab = tabName
        for name, frame in pairs(Tabs) do
            frame.Visible = (name == tabName)
        end
    end

    local function CreateTabBtn(text, xOffset, tabName)
        local Btn = Instance.new("TextButton")
        Btn.Parent = TabContainer
        Btn.BackgroundTransparency = 1
        Btn.Position = UDim2.new(0, xOffset, 0, 0)
        Btn.Size = UDim2.new(0, 80, 1, 0)
        Btn.Font = Enum.Font.GothamBold
        Btn.Text = text
        Btn.TextSize = 12
        Btn.TextColor3 = Color3.fromRGB(200, 200, 200)

        Btn.MouseButton1Click:Connect(function()
            SwitchTab(tabName)
            -- Visual update for active tab could be added here
        end)
    end

    CreateTabBtn("[CONSOLE]", 0, "Console")
    CreateTabBtn("[SCANNER]", 90, "Scanner")


    -- ====================================================================
    -- [[ TAB: CONSOLE (EXISTING LOGIC) ]]
    -- ====================================================================
    local ConsoleTab = Instance.new("Frame")
    ConsoleTab.Name = "ConsoleTab"
    ConsoleTab.Parent = Main
    ConsoleTab.BackgroundTransparency = 1
    ConsoleTab.Size = UDim2.new(1, 0, 1, -40)
    ConsoleTab.Position = UDim2.new(0, 0, 0, 40)
    Tabs["Console"] = ConsoleTab

    -- Control Bar
    local ControlBar = Instance.new("Frame")
    ControlBar.Parent = ConsoleTab
    ControlBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ControlBar.Size = UDim2.new(1, -20, 0, 35)
    ControlBar.Position = UDim2.new(0, 10, 0, 0)
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

    -- Filter Buttons
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
        
        Btn.MouseButton1Click:Connect(function()
            Filters[key] = not Filters[key]
            Btn.BackgroundTransparency = Filters[key] and 0 or 0.6
            SearchInput.Text = SearchInput.Text .. " " 
            SearchInput.Text = string.sub(SearchInput.Text, 1, -2) 
        end)
    end
    CreateFilterBtn("I", Color3.fromRGB(255, 255, 255), 0, "Info")
    CreateFilterBtn("W", Color3.fromRGB(255, 200, 50), 30, "Warn")
    CreateFilterBtn("E", Color3.fromRGB(255, 80, 80), 60, "Error")

    -- Stats Toggle
    local StatsVisible = false
    local MonitorFrame = Instance.new("Frame")
    MonitorFrame.Parent = Main -- Keep Monitor on top level
    MonitorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    MonitorFrame.Size = UDim2.new(0, 200, 1, -85)
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
    ToggleStatsBtn.MouseButton1Click:Connect(function()
        StatsVisible = not StatsVisible
        MonitorFrame.Visible = StatsVisible
        ToggleStatsBtn.BackgroundColor3 = StatsVisible and Color3.fromRGB(140, 80, 255) or Color3.fromRGB(50, 50, 60)
    end)

    -- Log Scroll
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Parent = ConsoleTab
    LogScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    LogScroll.Position = UDim2.new(0, 10, 0, 45)
    LogScroll.Size = UDim2.new(1, -20, 1, -55)
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
    LogDisplay.RichText = true
    LogDisplay.Text = "Waiting for logs..."

    -- Console Data Logic (Existing)
    local LogsCache = {}
    local function EscapeXml(str)
        return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;")
    end

    local function RefreshLogs()
        local query = SearchInput.Text:lower()
        local finalStr = ""
        for _, log in ipairs(LogsCache) do
            local typePass = false
            if log.type == "Info" and Filters.Info then typePass = true end
            if log.type == "Warn" and Filters.Warn then typePass = true end
            if log.type == "Error" and Filters.Error then typePass = true end
            
            local searchPass = true
            if query ~= "" and not log.rawMsg:lower():find(query) then searchPass = false end
            
            if typePass and searchPass then
                local colorTag = ""
                local prefix = ""
                if log.type == "Info" then 
                    colorTag = '<font color="#FFFFFF">' 
                    prefix = "[INFO] "
                elseif log.type == "Warn" then 
                    colorTag = '<font color="#FFC832">'
                    prefix = "[WARN] "
                elseif log.type == "Error" then 
                    colorTag = '<font color="#FF5050">'
                    prefix = "[ERR] "
                end
                finalStr = finalStr .. string.format('<font color="#AAAAAA">%s</font> %s%s%s</font>\n', 
                    log.time, colorTag, prefix, EscapeXml(log.rawMsg))
            end
        end
        LogDisplay.Text = finalStr
        LogScroll.CanvasPosition = Vector2.new(0, 99999)
    end

    local function AddLog(msg, type)
        if not Main.Parent then return end
        local t = os.date("%X")
        local typeStr = "Info"
        if type == Enum.MessageType.MessageWarning then typeStr = "Warn"
        elseif type == Enum.MessageType.MessageError then typeStr = "Error" end
        table.insert(LogsCache, {time = t, rawMsg = msg, type = typeStr})
        if #LogsCache > 250 then table.remove(LogsCache, 1) end 
        RefreshLogs()
    end
    SearchInput:GetPropertyChangedSignal("Text"):Connect(RefreshLogs)
    LogService.MessageOut:Connect(AddLog)

    -- Copy Button (Console)
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Parent = ConsoleTab
    CopyBtn.Text = "COPY ALL"
    CopyBtn.Size = UDim2.new(0, 60, 0, 20)
    CopyBtn.Position = UDim2.new(1, -75, 0, 45) -- Relative to ConsoleTab content area? No, original was Main.
    -- Adjusting position to be inside ConsoleTab or Main?
    -- Original layout had buttons at bottom. Let's keep them at bottom of Main, but show/hide based on tab if needed.
    -- Actually, for cleanliness, let's put them inside the tab.
    CopyBtn.Position = UDim2.new(1, -75, 1, -30) -- Bottom Right of ConsoleTab
    CopyBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    CopyBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    CopyBtn.Font = Enum.Font.Code
    CopyBtn.TextSize = 10
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 4)
    CopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            local cleanText = ""
            for _, log in ipairs(LogsCache) do
                cleanText = cleanText .. string.format("[%s] [%s] %s\n", log.time, log.type:upper(), log.rawMsg)
            end
            setclipboard(cleanText)
            local oldText = LogDisplay.Text
            LogDisplay.Text = ">> COPIED CLEAN LOGS TO CLIPBOARD <<"
            task.wait(0.5)
            LogDisplay.Text = oldText
        end
    end)

    local NukeBtn = Instance.new("TextButton")
    NukeBtn.Parent = ConsoleTab
    NukeBtn.Text = "NUKE"
    NukeBtn.Size = UDim2.new(0, 60, 0, 20)
    NukeBtn.Position = UDim2.new(1, -145, 1, -30)
    NukeBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    NukeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    NukeBtn.Font = Enum.Font.Code
    NukeBtn.TextSize = 10
    Instance.new("UICorner", NukeBtn).CornerRadius = UDim.new(0, 4)
    NukeBtn.MouseButton1Click:Connect(function()
        if getgenv().FSS_Universal_Stop then getgenv().FSS_Universal_Stop() end
        if getgenv().FSS_WaveZ_Stop then getgenv().FSS_WaveZ_Stop() end
        AddLog("ALL SCRIPTS NUKED MANUALLY", Enum.MessageType.MessageError)
    end)


    -- ====================================================================
    -- [[ TAB: SCANNER (NEW LOGIC) ]]
    -- ====================================================================
    local ScannerTab = Instance.new("Frame")
    ScannerTab.Name = "ScannerTab"
    ScannerTab.Parent = Main
    ScannerTab.BackgroundTransparency = 1
    ScannerTab.Size = UDim2.new(1, 0, 1, -40)
    ScannerTab.Position = UDim2.new(0, 0, 0, 40)
    ScannerTab.Visible = false
    Tabs["Scanner"] = ScannerTab

    -- Input Bar
    local ScannerBar = Instance.new("Frame")
    ScannerBar.Parent = ScannerTab
    ScannerBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ScannerBar.Size = UDim2.new(1, -20, 0, 35)
    ScannerBar.Position = UDim2.new(0, 10, 0, 0)
    Instance.new("UICorner", ScannerBar).CornerRadius = UDim.new(0, 6)

    local PathInput = Instance.new("TextBox")
    PathInput.Parent = ScannerBar
    PathInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    PathInput.Size = UDim2.new(0, 150, 0, 25)
    PathInput.Position = UDim2.new(0, 5, 0.5, -12.5)
    PathInput.Font = Enum.Font.Code
    PathInput.Text = "workspace.ServerZombies"
    PathInput.PlaceholderText = "Target Path..."
    PathInput.TextColor3 = Color3.fromRGB(220, 220, 220)
    PathInput.TextSize = 11
    Instance.new("UICorner", PathInput).CornerRadius = UDim.new(0, 4)

    local ClassInput = Instance.new("TextBox")
    ClassInput.Parent = ScannerBar
    ClassInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ClassInput.Size = UDim2.new(0, 100, 0, 25)
    ClassInput.Position = UDim2.new(0, 160, 0.5, -12.5)
    ClassInput.Font = Enum.Font.Code
    ClassInput.Text = "Model"
    ClassInput.PlaceholderText = "ClassName..."
    ClassInput.TextColor3 = Color3.fromRGB(220, 220, 220)
    ClassInput.TextSize = 11
    Instance.new("UICorner", ClassInput).CornerRadius = UDim.new(0, 4)

    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Parent = ScannerBar
    ScanBtn.Text = "SCAN"
    ScanBtn.Size = UDim2.new(0, 50, 0, 25)
    ScanBtn.Position = UDim2.new(1, -55, 0.5, -12.5)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    ScanBtn.TextColor3 = Color3.new(1,1,1)
    ScanBtn.Font = Enum.Font.GothamBold
    ScanBtn.TextSize = 10
    Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 4)

    -- Results Container
    local ScanScroll = Instance.new("ScrollingFrame")
    ScanScroll.Parent = ScannerTab
    ScanScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    ScanScroll.Position = UDim2.new(0, 10, 0, 45)
    ScanScroll.Size = UDim2.new(1, -20, 1, -55)
    ScanScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScanScroll.ScrollBarThickness = 6
    Instance.new("UICorner", ScanScroll).CornerRadius = UDim.new(0, 6)

    local ScanResultBox = Instance.new("TextBox")
    ScanResultBox.Parent = ScanScroll
    ScanResultBox.BackgroundTransparency = 1
    ScanResultBox.Size = UDim2.new(1, -10, 1, 0)
    ScanResultBox.Position = UDim2.new(0, 5, 0, 0)
    ScanResultBox.Font = Enum.Font.Code
    ScanResultBox.TextSize = 11
    ScanResultBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    ScanResultBox.TextXAlignment = Enum.TextXAlignment.Left
    ScanResultBox.TextYAlignment = Enum.TextYAlignment.Top
    ScanResultBox.TextWrapped = false -- Allow horizontal scrolling if lines are long
    ScanResultBox.MultiLine = true
    ScanResultBox.ClearTextOnFocus = false
    ScanResultBox.TextEditable = false
    ScanResultBox.AutomaticSize = Enum.AutomaticSize.XY
    ScanResultBox.Text = "Ready to scan..."

    -- Scan Copy Button
    local ScanCopyBtn = Instance.new("TextButton")
    ScanCopyBtn.Parent = ScannerTab
    ScanCopyBtn.Text = "COPY RESULT"
    ScanCopyBtn.Size = UDim2.new(0, 80, 0, 20)
    ScanCopyBtn.Position = UDim2.new(1, -95, 1, -30)
    ScanCopyBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    ScanCopyBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    ScanCopyBtn.Font = Enum.Font.Code
    ScanCopyBtn.TextSize = 10
    Instance.new("UICorner", ScanCopyBtn).CornerRadius = UDim.new(0, 4)
    ScanCopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(ScanResultBox.Text)
            local old = ScanBtn.Text
            ScanBtn.Text = "COPIED"
            task.wait(1)
            ScanBtn.Text = old
        end
    end)

    -- [[ SCANNER ALGORITHM ]] --
    local function ResolvePath(pathStr)
        local segments = pathStr:split(".")
        local current = game
        if segments[1] == "game" then table.remove(segments, 1) end

        for _, name in ipairs(segments) do
            if current:FindFirstChild(name) then
                current = current[name]
            else
                return nil
            end
        end
        return current
    end

    local function GetOrigin()
        local char = Players.LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            return char.HumanoidRootPart.Position
        elseif workspace.CurrentCamera then
            return workspace.CurrentCamera.CFrame.Position
        end
        return nil
    end

    local function Scan()
        local pathStr = PathInput.Text
        local filterClass = ClassInput.Text
        local target = ResolvePath(pathStr)

        if not target then
            ScanResultBox.Text = "[ERROR] Target path not found: " .. pathStr
            return
        end

        local results = {}
        table.insert(results, string.format("SCAN REPORT: %s | Filter: %s", pathStr, filterClass))
        table.insert(results, string.rep("-", 50))

        local origin = GetOrigin()

        for _, child in ipairs(target:GetChildren()) do
            -- Filter Logic
            local match = false
            if filterClass == "" or filterClass == "*" then match = true end
            if child:IsA(filterClass) then match = true end

            if match then
                local info = ""
                local distStr = "N/A"

                -- Distance Calc
                local pos = nil
                if child:IsA("BasePart") then
                    pos = child.Position
                elseif child:IsA("Model") and child.PrimaryPart then
                    pos = child.PrimaryPart.Position
                elseif child:FindFirstChild("HumanoidRootPart") then
                    pos = child.HumanoidRootPart.Position
                elseif child:FindFirstChild("Handle") then -- Tool
                    pos = child.Handle.Position
                end

                if pos and origin then
                    local dist = math.floor((pos - origin).Magnitude)
                    distStr = dist .. " studs"
                end

                -- Smart Peek (Expanded)
                if child:IsA("Model") then
                    local hum = child:FindFirstChild("Humanoid")
                    if hum then
                        info = string.format("HP: %d/%d", hum.Health, hum.MaxHealth)
                    else
                        -- Generic Model check
                        info = string.format("Children: %d", #child:GetChildren())
                    end
                elseif child:IsA("BasePart") then
                    info = string.format("Size: [%.1f, %.1f, %.1f]", child.Size.X, child.Size.Y, child.Size.Z)
                elseif child:IsA("Tool") then
                    info = child:FindFirstChild("Handle") and "Has Handle" or "No Handle"
                elseif child:IsA("ValueBase") then -- StringValue, IntValue, etc.
                    info = string.format("Value: %s", tostring(child.Value))
                end

                -- Extended Value Scan (Look for price/id inside)
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA("ValueBase") and (sub.Name:lower():find("price") or sub.Name:lower():find("id") or sub.Name:lower():find("val")) then
                        info = info .. string.format(" | %s: %s", sub.Name, tostring(sub.Value))
                    end
                end

                table.insert(results, string.format("[%s] %s | Dist: %s | %s", child.ClassName, child.Name, distStr, info))
            end
        end

        if #results == 2 then
            table.insert(results, "No objects found matching criteria.")
        end

        ScanResultBox.Text = table.concat(results, "\n")
    end

    ScanBtn.MouseButton1Click:Connect(Scan)


    -- [[ GLOBAL UPDATE LOOP (MONITOR) ]] --
    task.spawn(function()
        while Main.Parent do
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
            task.wait(0.2)
        end
    end)

    -- [[ WINDOW CONTROLS ]] --
    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = Main; MinBtn.Text = "-"; MinBtn.BackgroundTransparency = 1
    MinBtn.Size = UDim2.new(0, 25, 0, 25); MinBtn.Position = UDim2.new(1, -55, 0, 8)
    MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 18; MinBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    
    local isMin = false
    MinBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        if isMin then Main:TweenSize(UDim2.new(0, 700, 0, 40), "Out", "Quad", 0.3, true)
        else Main:TweenSize(UDim2.new(0, 700, 0, 500), "Out", "Quad", 0.3, true) end
    end)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Main; CloseBtn.Text = "X"; CloseBtn.BackgroundTransparency = 1
    CloseBtn.Size = UDim2.new(0, 25, 0, 25); CloseBtn.Position = UDim2.new(1, -30, 0, 8)
    CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)

    UserInputService.InputBegan:Connect(function(i, p)
        if not p and i.KeyCode == Enum.KeyCode.F10 then Main.Visible = not Main.Visible end
    end)

    AddLog("Debugger V4.3 Loaded. Scanner Module Active.", Enum.MessageType.MessageOutput)
end

return Debugger
