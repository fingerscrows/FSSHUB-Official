-- [[ FSSHUB MODULE: DEV SUITE V4.0 (ULTIMATE) ]] --
-- Features: F10 Keybind, Full Text Selection, Copy All, Filters (Info/Warn/Error), Search

local Debugger = {}
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

function Debugger.Show()
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
    Title.Text = "FSSHUB DEBUGGER [F10] | V4.0"
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
    SearchInput.Size = UDim2.new(0, 200, 0, 25)
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
        Btn.Size = UDim2.new(0, 30, 0, 25)
        Btn.Position = UDim2.new(0, 215 + xOffset, 0.5, -12.5)
        Btn.BackgroundColor3 = color
        Btn.Text = text
        Btn.TextColor3 = Color3.new(0,0,0)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 11
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        
        Btn.MouseButton1Click:Connect(function()
            Filters[key] = not Filters[key]
            Btn.BackgroundTransparency = Filters[key] and 0 or 0.6
            -- Trigger Refresh Log
            SearchInput.Text = SearchInput.Text .. " " 
            SearchInput.Text = string.sub(SearchInput.Text, 1, -2) 
        end)
    end

    CreateFilterBtn("I", Color3.fromRGB(255, 255, 255), 0, "Info")
    CreateFilterBtn("W", Color3.fromRGB(255, 200, 50), 35, "Warn")
    CreateFilterBtn("E", Color3.fromRGB(255, 80, 80), 70, "Error")

    -- [[ LOG CONTAINER (SINGLE TEXTBOX FOR SELECTION) ]] --
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Parent = Main
    LogScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    LogScroll.Position = UDim2.new(0, 10, 0, 85)
    LogScroll.Size = UDim2.new(1, -20, 1, -125) -- Sisa ruang untuk monitor bawah
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogScroll.ScrollBarThickness = 6
    Instance.new("UICorner", LogScroll).CornerRadius = UDim.new(0, 6)

    -- INI KUNCINYA: Satu TextBox besar agar bisa select text sepuasnya
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
    LogDisplay.TextEditable = false -- Read Only
    LogDisplay.AutomaticSize = Enum.AutomaticSize.Y
    LogDisplay.Text = "Waiting for logs..."

    -- [[ DATA MANAGEMENT ]] --
    local LogsCache = {}
    
    local function RefreshLogs()
        local query = SearchInput.Text:lower()
        local finalStr = ""
        
        for _, log in ipairs(LogsCache) do
            -- Filter Type Check
            local typePass = false
            if log.type == "Info" and Filters.Info then typePass = true end
            if log.type == "Warn" and Filters.Warn then typePass = true end
            if log.type == "Error" and Filters.Error then typePass = true end
            
            -- Search Check
            local searchPass = true
            if query ~= "" and not log.msg:lower():find(query) then searchPass = false end
            
            if typePass and searchPass then
                -- Kita pakai RichText manual simple untuk tagging tipe
                local prefix = ""
                if log.type == "Info" then prefix = "[INFO] "
                elseif log.type == "Warn" then prefix = "[WARN] "
                elseif log.type == "Error" then prefix = "[ERR] "
                end
                
                finalStr = finalStr .. log.time .. " " .. prefix .. log.msg .. "\n"
            end
        end
        LogDisplay.Text = finalStr
        -- Scroll to bottom
        LogScroll.CanvasPosition = Vector2.new(0, 99999)
    end

    local function AddLog(msg, type)
        if not Main.Parent then return end
        local t = os.date("%X")
        local typeStr = "Info"
        if type == Enum.MessageType.MessageWarning then typeStr = "Warn"
        elseif type == Enum.MessageType.MessageError then typeStr = "Error" end
        
        table.insert(LogsCache, {time = t, msg = msg, type = typeStr})
        if #LogsCache > 300 then table.remove(LogsCache, 1) end -- Limit memory
        
        RefreshLogs()
    end

    SearchInput:GetPropertyChangedSignal("Text"):Connect(RefreshLogs)
    LogService.MessageOut:Connect(AddLog)

    -- [[ BOTTOM MONITOR ]] --
    local MonitorBar = Instance.new("Frame")
    MonitorBar.Parent = Main
    MonitorBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MonitorBar.Position = UDim2.new(0, 10, 1, -35)
    MonitorBar.Size = UDim2.new(1, -20, 0, 25)
    Instance.new("UICorner", MonitorBar).CornerRadius = UDim.new(0, 4)
    
    local MonitorText = Instance.new("TextLabel")
    MonitorText.Parent = MonitorBar
    MonitorText.BackgroundTransparency = 1
    MonitorText.Size = UDim2.new(1, -10, 1, 0)
    MonitorText.Position = UDim2.new(0, 10, 0, 0)
    MonitorText.Font = Enum.Font.Code
    MonitorText.TextSize = 11
    MonitorText.TextColor3 = Color3.fromRGB(150, 255, 150)
    MonitorText.TextXAlignment = Enum.TextXAlignment.Left
    
    task.spawn(function()
        while Main.Parent do
            if Main.Visible then
                local fps = math.floor(workspace:GetRealPhysicsFPS())
                local mem = math.floor(Stats:GetTotalMemoryUsageMb())
                local uStop = getgenv().FSS_Universal_Stop and "YES" or "NO"
                MonitorText.Text = string.format("FPS: %d | Mem: %d MB | Univ_Active: %s", fps, mem, uStop)
            end
            task.wait(0.5)
        end
    end)

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
        B.MouseButton1Click:Connect(func)
    end

    -- Copy All
    CreateBtn("COPY ALL", UDim2.new(1, -75, 0, 45), function()
        if setclipboard then
            setclipboard(LogDisplay.Text)
            local old = LogDisplay.Text
            LogDisplay.Text = ">> COPIED TO CLIPBOARD <<"
            task.wait(0.5)
            LogDisplay.Text = old
        end
    end, Color3.fromRGB(100, 255, 100))

    -- Force Nuke
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

    -- Toggle F10
    UserInputService.InputBegan:Connect(function(i, p)
        if not p and i.KeyCode == Enum.KeyCode.F10 then Main.Visible = not Main.Visible end
    end)

    AddLog("Debugger V4.0 Loaded. Press F10 to Toggle.", Enum.MessageType.MessageOutput)
end

return Debugger
