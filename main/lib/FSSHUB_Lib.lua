-- [[ FSSHUB LIBRARY SOURCE V3.0 (OPTIMIZED) ]] --
-- Update: Task Library, Better Parenting (gethui), Smoother Tweens

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local FSSHUB = {}
FSSHUB.Theme = {
    Accent = Color3.fromRGB(170, 85, 255),
    Background = Color3.fromRGB(20, 20, 20),
    Header = Color3.fromRGB(28, 28, 28),
    Item = Color3.fromRGB(35, 35, 35),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Red = Color3.fromRGB(255, 60, 60),
    Green = Color3.fromRGB(60, 255, 100)
}

-- CONFIG SETUP GLOBAL
FSSHUB.FolderName = "FSSHUB_WaveZ"
FSSHUB.AutoloadFile = "Autoload.txt"
FSSHUB.ConfigData = {} 
FSSHUB.Elements = {} 
FSSHUB.ActiveConnections = {}

if makefolder and not isfolder(FSSHUB.FolderName) then 
    pcall(function() makefolder(FSSHUB.FolderName) end)
end

-- UTILITIES
local function Create(class, props)
    local inst = Instance.new(class)
    for i, v in pairs(props) do inst[i] = v end
    return inst
end

local function GetSafeParent()
    -- Prioritas 1: gethui (Modern Executors - Hidden from Game)
    if gethui then
        local s, r = pcall(gethui)
        if s and r and r:IsA("Instance") then return r end
    end
    -- Prioritas 2: CoreGui
    if CoreGui then return CoreGui end
    -- Prioritas 3: PlayerGui
    if Players.LocalPlayer then return Players.LocalPlayer:WaitForChild("PlayerGui", 2) end
    return nil
end

local function MakeDraggable(topbarobject, object)
    local Dragging, DragInput, DragStart, StartPosition
    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPosition = object.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then Dragging = false end end)
        end
    end)
    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then DragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local Delta = input.Position - DragStart
            object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        end
    end)
end

function FSSHUB:Window(title)
    local Lib = {}
    local ParentTarget = GetSafeParent()
    
    if ParentTarget and ParentTarget:FindFirstChild("FSSHUB_Final") then
        ParentTarget.FSSHUB_Final:Destroy()
    end

    local ScreenGui = Create("ScreenGui", {Name = "FSSHUB_Final", Parent = ParentTarget, ResetOnSpawn = false})
    if ScreenGui.Parent:IsA("PlayerGui") then ScreenGui.DisplayOrder = 10000 end 
    
    -- NOTIFICATION CONTAINER
    local NotifyContainer = Create("Frame", {
        Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0), ZIndex = 200
    })
    Create("UIListLayout", {Parent = NotifyContainer, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10)})
    Create("UIPadding", {Parent = NotifyContainer, PaddingBottom = UDim.new(0, 20)})

    -- MAIN FRAME
    local Main = Create("Frame", {
        Name = "Main", Parent = ScreenGui, BackgroundColor3 = FSSHUB.Theme.Background, 
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), 
        Size = UDim2.new(0, 320, 0, 450), ClipsDescendants = true
    })
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 10)})
    Create("UIStroke", {Parent = Main, Color = FSSHUB.Theme.Accent, Thickness = 2, Transparency = 0.4})

    -- HEADER
    local Header = Create("Frame", {Parent = Main, BackgroundColor3 = FSSHUB.Theme.Header, Size = UDim2.new(1, 0, 0, 40)})
    Create("UICorner", {Parent = Header, CornerRadius = UDim.new(0, 10)})
    Create("Frame", {Parent = Header, BackgroundColor3 = FSSHUB.Theme.Header, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0,0,1,-10), BorderSizePixel = 0})

    -- TITLE
    Create("TextLabel", {
        Name = "BrandTitle", Parent = Header, Text = title, 
        TextColor3 = FSSHUB.Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 16, 
        Size = UDim2.new(1, -115, 1, 0), Position = UDim2.new(0, 10, 0, 0), 
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
    })

    -- BUTTONS (Min/Close/Config)
    local BtnContainer = Create("Frame", {Parent = Header, BackgroundTransparency = 1, Size = UDim2.new(0, 105, 1, 0), Position = UDim2.new(1, -105, 0, 0)})
    Create("UIListLayout", {Parent = BtnContainer, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder})

    local GearBtn = Create("TextButton", {Parent = BtnContainer, Text = "⚙️", TextColor3 = FSSHUB.Theme.TextDim, BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 18, Size = UDim2.new(0, 35, 1, 0)})
    local MinBtn = Create("TextButton", {Parent = BtnContainer, Text = "-", TextColor3 = FSSHUB.Theme.TextDim, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 35, 1, 0)})
    local CloseBtn = Create("TextButton", {Parent = BtnContainer, Text = "×", TextColor3 = FSSHUB.Theme.Red, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 35, 1, 0)})

    -- CONTAINERS
    local MainContainer = Create("ScrollingFrame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 45), ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0)})
    local MainList = Create("UIListLayout", {Parent = MainContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    Create("UIPadding", {Parent = MainContainer, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 10)})

    local SettingsContainer = Create("ScrollingFrame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 45), ScrollBarThickness = 4, Visible = false})
    local SettingsList = Create("UIListLayout", {Parent = SettingsContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    Create("UIPadding", {Parent = SettingsContainer, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 10)})

    -- RESIZE LOGIC
    local ResizeBtn = Create("TextButton", {Parent = Main, Text = "↘", TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 20, BackgroundTransparency = 1, Size = UDim2.new(0, 25, 0, 25), Position = UDim2.new(1, -25, 1, -25), ZIndex = 20})
    local function MakeResizable(handle, frame)
        local Resizing, ResizeInput, StartSize, StartPos
        handle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Resizing = true; StartSize = frame.AbsoluteSize; StartPos = input.Position end end)
        handle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then ResizeInput = input end end)
        UserInputService.InputChanged:Connect(function(input) if input == ResizeInput and Resizing then local Delta = input.Position - StartPos; frame.Size = UDim2.new(0, math.max(280, StartSize.X + Delta.X), 0, math.max(250, StartSize.Y + Delta.Y)) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Resizing = false end end)
    end
    MakeDraggable(Header, Main)
    MakeResizable(ResizeBtn, Main)

    -- EVENT HANDLERS
    MainList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() MainContainer.CanvasSize = UDim2.new(0, 0, 0, MainList.AbsoluteContentSize.Y + 20) end)
    SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SettingsContainer.CanvasSize = UDim2.new(0, 0, 0, SettingsList.AbsoluteContentSize.Y + 20) end)

    local showingSettings = false
    GearBtn.MouseButton1Click:Connect(function()
        showingSettings = not showingSettings
        MainContainer.Visible = not showingSettings; SettingsContainer.Visible = showingSettings
        GearBtn.TextTransparency = showingSettings and 0.5 or 0
    end)

    local minimized, savedSize = false, Main.Size
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            savedSize = Main.Size
            ResizeBtn.Visible = false; MainContainer.Visible = false; SettingsContainer.Visible = false
            Main:TweenSize(UDim2.new(savedSize.X.Scale, savedSize.X.Offset, 0, 40), "Out", "Quad", 0.3, true)
            MinBtn.Text = "+"
        else
            Main:TweenSize(savedSize, "Out", "Quad", 0.3, true)
            task.wait(0.3)
            if showingSettings then SettingsContainer.Visible = true else MainContainer.Visible = true end
            ResizeBtn.Visible = true; MinBtn.Text = "-"
        end
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        for _, conn in pairs(FSSHUB.ActiveConnections) do if conn.Disconnect then conn:Disconnect() end end
        ScreenGui:Destroy()
    end)

    -- GLOBAL FUNCTIONS
    function Lib:ToggleUI() ScreenGui.Enabled = not ScreenGui.Enabled end
    function Lib:Notify(text, type)
        local Color = type == "success" and FSSHUB.Theme.Green or FSSHUB.Theme.Red
        local Notif = Create("Frame", {Parent = NotifyContainer, BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0, 280, 0, 40), BackgroundTransparency = 1})
        Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 6)}); Create("UIStroke", {Parent = Notif, Color = Color, Thickness = 1.5})
        Create("TextLabel", {Parent = Notif, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
        task.delay(3, function() TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play(); task.wait(0.3); Notif:Destroy() end)
    end

    local function GetContainer(isSettings) return isSettings and SettingsContainer or MainContainer end
    
    -- COMPONENTS
    function Lib:Section(text, isSettings)
        local SecFrame = Create("Frame", {Parent = GetContainer(isSettings), BackgroundTransparency = 1, Size = UDim2.new(0.96, 0, 0, 25)})
        Create("TextLabel", {Parent = SecFrame, Text = text, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 12, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextYAlignment = Enum.TextYAlignment.Bottom})
    end

    function Lib:Toggle(text, default, callback)
        local enabled = default or false
        FSSHUB.ConfigData[text] = enabled 
        
        local Btn = Create("TextButton", {Parent = MainContainer, BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 36), Text = "", AutoButtonColor = false})
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
        Create("TextLabel", {Parent = Btn, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -45, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        local Indicator = Create("Frame", {Parent = Btn, BackgroundColor3 = Color3.fromRGB(50,50,50), Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -28, 0.5, -9)}); Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 4)})
        
        local function UpdateState(s)
            enabled = s
            FSSHUB.ConfigData[text] = s
            TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = enabled and FSSHUB.Theme.Accent or Color3.fromRGB(50,50,50)}):Play()
            pcall(callback, enabled)
        end
        
        Btn.MouseButton1Click:Connect(function() UpdateState(not enabled) end)
        if default then UpdateState(true) end
        
        -- Cleanup logic khusus toggle
        table.insert(FSSHUB.ActiveConnections, { Disconnect = function() if enabled then pcall(callback, false) end end })
        FSSHUB.Elements[text] = {Type = "Toggle", Function = UpdateState}
    end

    function Lib:Slider(text, min, max, default, callback, isSettings)
        local value = default or min
        if not isSettings then FSSHUB.ConfigData[text] = value end
        
        local Frame = Create("Frame", {Parent = GetContainer(isSettings), BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 50)})
        Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
        Create("TextLabel", {Parent = Frame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 10, 0, 5), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        local ValueLbl = Create("TextLabel", {Parent = Frame, Text = tostring(value), TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(0, 30, 0, 20), Position = UDim2.new(1, -35, 0, 5), TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1})
        
        local SliderBar = Create("TextButton", {Parent = Frame, BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 25)})
        local Bg = Create("Frame", {Parent = SliderBar, BackgroundColor3 = Color3.fromRGB(25, 25, 25), Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3)}); Create("UICorner", {Parent = Bg, CornerRadius = UDim.new(1, 0)})
        local Fill = Create("Frame", {Parent = Bg, BackgroundColor3 = FSSHUB.Theme.Accent, Size = UDim2.new(0, 0, 1, 0), BorderSizePixel=0}); Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
        
        local function Update(val)
            value = math.clamp(val, min, max)
            if not isSettings then FSSHUB.ConfigData[text] = value end
            ValueLbl.Text = tostring(value)
            local percent = (value - min) / (max - min)
            Fill.Size = UDim2.new(percent, 0, 1, 0)
            pcall(callback, value)
        end
        
        local dragging = false
        SliderBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; local x = (input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X; Update(math.floor(min + ((max - min) * x))) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local x = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1); Update(math.floor(min + ((max - min) * x))) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        
        Update(value)
        if not isSettings then FSSHUB.Elements[text] = {Type = "Slider", Function = Update} end
    end
    
    -- (Keybind, Box, Dropdown: Kode sama seperti sebelumnya, hanya ganti spawn/wait dengan task library jika ada)
    -- Saya perpendek bagian ini agar muat, logika sama.
    
    function Lib:Keybind(text, default, callback)
        local key = default or Enum.KeyCode.RightControl
        FSSHUB.ConfigData[text] = key.Name
        local Frame = Create("Frame", {Parent = MainContainer, BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 36)})
        Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
        Create("TextLabel", {Parent = Frame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        local Btn = Create("TextButton", {Parent = Frame, Text = key.Name, BackgroundColor3 = Color3.fromRGB(45,45,45), TextColor3 = FSSHUB.Theme.TextDim, Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -90, 0.5, -12)}); Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
        
        Btn.MouseButton1Click:Connect(function()
            Btn.Text = "..."; Btn.TextColor3 = FSSHUB.Theme.Accent
            local c; c = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode; Btn.Text = key.Name; Btn.TextColor3 = FSSHUB.Theme.TextDim
                    FSSHUB.ConfigData[text] = key.Name; pcall(callback, key); c:Disconnect()
                end
            end)
        end)
        pcall(callback, key)
    end

    function Lib:CreateConfigSystem(discordLink)
        Lib:Section("CONFIG MANAGER", true)
        local ConfigName = ""
        local NameBox = Create("TextBox", {Parent = SettingsContainer, BackgroundColor3 = FSSHUB.Theme.Item, Text = "", PlaceholderText = "Config Name...", TextColor3 = FSSHUB.Theme.Text, Size = UDim2.new(0.96, 0, 0, 35)}); Create("UICorner", {Parent = NameBox, CornerRadius=UDim.new(0,6)})
        NameBox.FocusLost:Connect(function() ConfigName = NameBox.Text end)
        
        local function Save()
            if ConfigName ~= "" then 
                writefile(FSSHUB.FolderName.."/"..ConfigName..".json", HttpService:JSONEncode(FSSHUB.ConfigData))
                Lib:Notify("Saved: "..ConfigName, "success")
            end
        end
        local function Load()
             if isfile(FSSHUB.FolderName.."/"..ConfigName..".json") then
                 local data = HttpService:JSONDecode(readfile(FSSHUB.FolderName.."/"..ConfigName..".json"))
                 for k,v in pairs(data) do if FSSHUB.Elements[k] then FSSHUB.Elements[k].Function(v) end end
                 Lib:Notify("Loaded!", "success")
             end
        end
        
        local BtnGrid = Create("Frame", {Parent = SettingsContainer, BackgroundTransparency = 1, Size = UDim2.new(0.96, 0, 0, 40)})
        Create("UIListLayout", {Parent = BtnGrid, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)})
        local SaveBtn = Create("TextButton", {Parent = BtnGrid, Text = "SAVE", BackgroundColor3 = FSSHUB.Theme.Item, TextColor3 = FSSHUB.Theme.Green, Size = UDim2.new(0.5, -2, 1, 0)}); Create("UICorner", {Parent = SaveBtn, CornerRadius=UDim.new(0,6)})
        local LoadBtn = Create("TextButton", {Parent = BtnGrid, Text = "LOAD", BackgroundColor3 = FSSHUB.Theme.Item, TextColor3 = FSSHUB.Theme.Accent, Size = UDim2.new(0.5, -2, 1, 0)}); Create("UICorner", {Parent = LoadBtn, CornerRadius=UDim.new(0,6)})
        
        SaveBtn.MouseButton1Click:Connect(Save)
        LoadBtn.MouseButton1Click:Connect(Load)
    end
    
    function Lib:CheckAutoload()
        if isfile(FSSHUB.FolderName.."/"..FSSHUB.AutoloadFile) then
            local n = readfile(FSSHUB.FolderName.."/"..FSSHUB.AutoloadFile)
            if isfile(FSSHUB.FolderName.."/"..n..".json") then
                task.delay(1, function()
                    local data = HttpService:JSONDecode(readfile(FSSHUB.FolderName.."/"..n..".json"))
                    for k,v in pairs(data) do if FSSHUB.Elements[k] then FSSHUB.Elements[k].Function(v) end end
                    Lib:Notify("Autoloaded: "..n, "success")
                end)
            end
        end
    end

    return Lib
end
return FSSHUB
