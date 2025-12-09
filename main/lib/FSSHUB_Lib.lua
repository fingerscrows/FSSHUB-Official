-- [[ FSSHUB LIBRARY SOURCE V2.3 (STABLE & KEYBIND) ]] --
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

if makefolder and not isfolder(FSSHUB.FolderName) then makefolder(FSSHUB.FolderName) end

-- UTILITIES
local function Create(class, props)
    local inst = Instance.new(class)
    for i, v in pairs(props) do inst[i] = v end
    return inst
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

local function MakeResizable(handle, frame)
    local Resizing, ResizeInput, StartSize, StartPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Resizing = true; StartSize = frame.AbsoluteSize; StartPos = input.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then Resizing = false end end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then ResizeInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == ResizeInput and Resizing then
            local Delta = input.Position - StartPos
            local NewX = math.max(280, StartSize.X + Delta.X)
            local NewY = math.max(250, StartSize.Y + Delta.Y)
            frame.Size = UDim2.new(0, NewX, 0, NewY)
        end
    end)
end

function FSSHUB:Window(title)
    local Lib = {}
    
    -- [[ 1. LOGIKA PARENTING YANG PASTI MUNCUL ]] --
    -- Kita prioritaskan PlayerGui karena 100% aman dan pasti muncul di layar
    local ParentTarget = nil
    
    -- Coba ambil PlayerGui
    if Players.LocalPlayer then
        ParentTarget = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    
    -- Jika PlayerGui gagal (sangat jarang), baru coba CoreGui
    if not ParentTarget then
        ParentTarget = CoreGui
    end

    -- [[ 2. BERSIHKAN UI LAMA ]] --
    -- Hapus instance lama agar tidak menumpuk
    if ParentTarget:FindFirstChild("FSSHUB_Final") then ParentTarget.FSSHUB_Final:Destroy() end
    -- Cek juga di CoreGui kalau-kalau ada sisa
    if CoreGui:FindFirstChild("FSSHUB_Final") then CoreGui.FSSHUB_Final:Destroy() end

    -- [[ 3. BUAT GUI BARU ]] --
    local ScreenGui = Create("ScreenGui", {Name = "FSSHUB_Final", Parent = ParentTarget, ResetOnSpawn = false})
    
    -- DisplayOrder tinggi agar UI selalu di atas UI game lain
    if ScreenGui.Parent:IsA("PlayerGui") then
        ScreenGui.DisplayOrder = 10000 
    end
    
    -- NOTIFICATION CONTAINER
    local NotifyContainer = Create("Frame", {
        Parent = ScreenGui, BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0), ZIndex = 200
    })
    local NotifyList = Create("UIListLayout", {
        Parent = NotifyContainer, SortOrder = Enum.SortOrder.LayoutOrder, 
        VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10)
    })
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

    -- HEADER BUTTONS (RIGHT)
    local BtnContainer = Create("Frame", {
        Parent = Header, BackgroundTransparency = 1, 
        Size = UDim2.new(0, 105, 1, 0), Position = UDim2.new(1, -105, 0, 0)
    })
    local BtnLayout = Create("UIListLayout", {
        Parent = BtnContainer, FillDirection = Enum.FillDirection.Horizontal, 
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0)
    })

    local GearBtn = Create("TextButton", {Parent = BtnContainer, Text = "⚙️", TextColor3 = FSSHUB.Theme.TextDim, BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 18, Size = UDim2.new(0, 35, 1, 0), LayoutOrder = 1})
    local MinBtn = Create("TextButton", {Parent = BtnContainer, Text = "-", TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 35, 1, 0), LayoutOrder = 2, BackgroundTransparency = 1})
    local CloseBtn = Create("TextButton", {Parent = BtnContainer, Text = "×", TextColor3 = FSSHUB.Theme.Red, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 35, 1, 0), LayoutOrder = 3, BackgroundTransparency = 1})

    -- BRAND TITLE (LEFT)
    local BrandTitle = Create("TextLabel", {
        Name = "BrandTitle", Parent = Header, Text = title, 
        TextColor3 = FSSHUB.Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 16, 
        Size = UDim2.new(1, -115, 1, 0), Position = UDim2.new(0, 10, 0, 0), 
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, 
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    -- CONTAINERS
    local MainContainer = Create("ScrollingFrame", {
        Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), 
        Position = UDim2.new(0, 0, 0, 45), ScrollBarThickness = 6, 
        ScrollBarImageColor3 = FSSHUB.Theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = true
    })
    local MainList = Create("UIListLayout", {Parent = MainContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    Create("UIPadding", {Parent = MainContainer, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 10)})

    local SettingsContainer = Create("ScrollingFrame", {
        Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), 
        Position = UDim2.new(0, 0, 0, 45), ScrollBarThickness = 6, 
        ScrollBarImageColor3 = FSSHUB.Theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false
    })
    local SettingsList = Create("UIListLayout", {Parent = SettingsContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    Create("UIPadding", {Parent = SettingsContainer, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 10)})

    -- RESIZE
    local ResizeBtn = Create("TextButton", {
        Parent = Main, Text = "↘", TextColor3 = FSSHUB.Theme.TextDim,
        Font = Enum.Font.GothamBold, TextSize = 24, BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -30, 1, -30), 
        ZIndex = 20, AutoButtonColor = false
    })

    -- CONFIRM POPUP
    local Modal = Create("Frame", {Parent = ScreenGui, BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.6, Size = UDim2.new(1, 0, 1, 0), Visible = false, ZIndex = 100})
    local ConfirmBox = Create("Frame", {Parent = Modal, BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0, 240, 0, 130), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 101})
    Create("UICorner", {Parent = ConfirmBox, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = ConfirmBox, Color = FSSHUB.Theme.Red, Thickness = 2})
    Create("TextLabel", {Parent = ConfirmBox, Text = "Unload Script?", TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 10), ZIndex = 102})
    local PopupBtns = Create("Frame", {Parent = ConfirmBox, BackgroundTransparency = 1, Size = UDim2.new(1, -30, 0, 40), Position = UDim2.new(0, 15, 1, -50), ZIndex = 102})
    Create("UIListLayout", {Parent = PopupBtns, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    local YesBtn = Create("TextButton", {Parent = PopupBtns, Text = "YES", BackgroundColor3 = FSSHUB.Theme.Red, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(0.5, -5, 1, 0), AutoButtonColor = false, ZIndex = 103})
    Create("UICorner", {Parent = YesBtn, CornerRadius = UDim.new(0, 6)})
    local NoBtn = Create("TextButton", {Parent = PopupBtns, Text = "CANCEL", BackgroundColor3 = FSSHUB.Theme.Item, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(0.5, -5, 1, 0), AutoButtonColor = false, ZIndex = 103})
    Create("UICorner", {Parent = NoBtn, CornerRadius = UDim.new(0, 6)})

    -- LOGIC INIT
    MakeDraggable(Header, Main)
    MakeResizable(ResizeBtn, Main)
    MainList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() MainContainer.CanvasSize = UDim2.new(0, 0, 0, MainList.AbsoluteContentSize.Y + 20) end)
    SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SettingsContainer.CanvasSize = UDim2.new(0, 0, 0, SettingsList.AbsoluteContentSize.Y + 20) end)

    local showingSettings = false
    GearBtn.MouseButton1Click:Connect(function()
        showingSettings = not showingSettings
        MainContainer.Visible = not showingSettings
        SettingsContainer.Visible = showingSettings
        GearBtn.TextTransparency = showingSettings and 0.5 or 0
    end)

    local minimized = false; local preMinSize = Main.Size
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            preMinSize = Main.Size
            ResizeBtn.Visible = false; MainContainer.Visible = false; SettingsContainer.Visible = false
            local diff = preMinSize.Y.Offset - 40
            Main:TweenSizeAndPosition(UDim2.new(preMinSize.X.Scale, preMinSize.X.Offset, 0, 40), UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, Main.Position.Y.Scale, Main.Position.Y.Offset - (diff/2)), "Out", "Quad", 0.3, true)
            MinBtn.Text = "+"
        else
            local diff = preMinSize.Y.Offset - 40
            Main:TweenSizeAndPosition(preMinSize, UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, Main.Position.Y.Scale, Main.Position.Y.Offset + (diff/2)), "Out", "Quad", 0.3, true)
            wait(0.3)
            if showingSettings then SettingsContainer.Visible = true else MainContainer.Visible = true end
            ResizeBtn.Visible = true; MinBtn.Text = "-"
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function() Modal.Visible = true end)
    NoBtn.MouseButton1Click:Connect(function() Modal.Visible = false end)
    YesBtn.MouseButton1Click:Connect(function()
        for _, conn in pairs(FSSHUB.ActiveConnections) do if conn.Disconnect then conn:Disconnect() end end
        ScreenGui:Destroy()
    end)

    -- NOTIFICATION SYSTEM
    function Lib:Notify(text, type)
        local Color = type == "success" and FSSHUB.Theme.Green or FSSHUB.Theme.Red
        local Icon = type == "success" and "✓" or "!"
        local Notif = Create("Frame", {Parent = NotifyContainer, BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0, 280, 0, 40), BackgroundTransparency = 0.1})
        Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 6)})
        Create("UIStroke", {Parent = Notif, Color = Color, Thickness = 1.5})
        Create("TextLabel", {Parent = Notif, Text = Icon, TextColor3 = Color, Font = Enum.Font.GothamBold, TextSize = 20, Size = UDim2.new(0, 40, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
        Create("TextLabel", {Parent = Notif, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 40, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        Notif.BackgroundTransparency = 1
        TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 0.1}):Play()
        task.delay(3, function() TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play() wait(0.3) Notif:Destroy() end)
    end

    -- UI COMPONENTS
    local function GetContainer(isSettings) return isSettings and SettingsContainer or MainContainer end
    function Lib:Section(text, isSettings)
        local SecFrame = Create("Frame", {Parent = GetContainer(isSettings), BackgroundTransparency = 1, Size = UDim2.new(0.96, 0, 0, 20)})
        Create("TextLabel", {Parent = SecFrame, Text = text, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 12, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
    end
    function Lib:Toggle(text, default, callback)
        local enabled = default or false
        FSSHUB.ConfigData[text] = enabled 
        local ToggleBtn = Create("TextButton", {Parent = MainContainer, BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 36), Text = "", AutoButtonColor = false})
        Create("UICorner", {Parent = ToggleBtn, CornerRadius = UDim.new(0, 6)})
        Create("TextLabel", {Parent = ToggleBtn, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -45, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        local Indicator = Create("Frame", {Parent = ToggleBtn, BackgroundColor3 = enabled and FSSHUB.Theme.Accent or Color3.fromRGB(50,50,50), Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -25, 0.5, -9)})
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 4)})
        local function SetState(s)
            enabled = s
            FSSHUB.ConfigData[text] = s
            TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = enabled and FSSHUB.Theme.Accent or Color3.fromRGB(50,50,50)}):Play()
            pcall(callback, enabled)
        end
        ToggleBtn.MouseButton1Click:Connect(function() SetState(not enabled) end)
        if default then SetState(true) end
        table.insert(FSSHUB.ActiveConnections, { Disconnect = function() if enabled then pcall(callback, false) end end })
        FSSHUB.Elements[text] = {Type = "Toggle", Function = SetState}
    end
    function Lib:Slider(text, min, max, default, callback, isSettings)
        local value = default or min
        if not isSettings then FSSHUB.ConfigData[text] = value end
        local SliderFrame = Create("Frame", {Parent = GetContainer(isSettings), BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 50)})
        Create("UICorner", {Parent = SliderFrame, CornerRadius = UDim.new(0, 6)})
        Create("TextLabel", {Parent = SliderFrame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 10, 0, 5), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        local ValueLbl = Create("TextLabel", {Parent = SliderFrame, Text = tostring(value), TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(0, 30, 0, 20), Position = UDim2.new(1, -35, 0, 5), TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1})
        local Hitbox = Create("TextButton", {Parent = SliderFrame, BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 25)})
        local BarBg = Create("Frame", {Parent = Hitbox, BackgroundColor3 = Color3.fromRGB(25, 25, 25), Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), ZIndex = 2})
        Create("UICorner", {Parent = BarBg, CornerRadius = UDim.new(1, 0)})
        local Fill = Create("Frame", {Parent = BarBg, BackgroundColor3 = FSSHUB.Theme.Accent, BorderSizePixel = 0, ZIndex = 3})
        Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
        if min < 0 and max > 0 then
            local centerPos = (0 - min) / (max - min)
            Create("Frame", {Parent = BarBg, BackgroundColor3 = Color3.fromRGB(80,80,80), Size = UDim2.new(0, 2, 1, 4), Position = UDim2.new(centerPos, -1, 0, -2), ZIndex = 4, BorderSizePixel = 0})
        end
        local function UpdateVisual(val)
            value = val
            if not isSettings then FSSHUB.ConfigData[text] = val end
            local percent = (val - min) / (max - min)
            if min < 0 and max > 0 then
                local zeroPercent = (0 - min) / (max - min)
                if val >= 0 then Fill.Position = UDim2.new(zeroPercent, 0, 0, 0); Fill.Size = UDim2.new(percent - zeroPercent, 0, 1, 0)
                else Fill.Position = UDim2.new(percent, 0, 0, 0); Fill.Size = UDim2.new(zeroPercent - percent, 0, 1, 0) end
            else Fill.Position = UDim2.new(0, 0, 0, 0); Fill.Size = UDim2.new(percent, 0, 1, 0) end
            ValueLbl.Text = tostring(val)
        end
        local function UpdateLogic(input)
            local relativeX = math.clamp((input.Position.X - Hitbox.AbsolutePosition.X) / Hitbox.AbsoluteSize.X, 0, 1)
            local newValue = math.floor(min + ((max - min) * relativeX))
            if newValue ~= value then UpdateVisual(newValue); pcall(callback, newValue) end
        end
        local dragging = false
        Hitbox.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; UpdateLogic(input) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateLogic(input) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
        UpdateVisual(value)
        if not isSettings then FSSHUB.Elements[text] = {Type = "Slider", Function = function(v) UpdateVisual(v); pcall(callback, v) end} end
    end
    
    -- [[ FUNGSI KEYBIND (YANG DIMINTA) ]] --
    function Lib:Keybind(text, default, callback, isSettings)
        local key = default or Enum.KeyCode.RightControl
        if not isSettings and FSSHUB.ConfigData[text] then key = Enum.KeyCode[FSSHUB.ConfigData[text]] end
        
        local KeyFrame = Create("Frame", {Parent = GetContainer(isSettings), BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 36)})
        Create("UICorner", {Parent = KeyFrame, CornerRadius = UDim.new(0, 6)})
        Create("TextLabel", {Parent = KeyFrame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -90, 0, 36), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        
        local KeyBtn = Create("TextButton", {Parent = KeyFrame, BackgroundColor3 = Color3.fromRGB(45,45,45), Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -90, 0.5, -12), Text = key.Name, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false})
        Create("UICorner", {Parent = KeyBtn, CornerRadius = UDim.new(0, 4)})
        
        local listening = false
        KeyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            KeyBtn.Text = "..."
            KeyBtn.TextColor3 = FSSHUB.Theme.Accent
            
            local inputConn
            inputConn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    KeyBtn.Text = key.Name
                    KeyBtn.TextColor3 = FSSHUB.Theme.TextDim
                    
                    if not isSettings then FSSHUB.ConfigData[text] = key.Name end
                    pcall(callback, key)
                    
                    listening = false
                    inputConn:Disconnect()
                end
            end)
        end)
        
        -- Init callback
        pcall(callback, key)
        if not isSettings then FSSHUB.Elements[text] = {Type = "Keybind", Function = function(v) key = Enum.KeyCode[v]; KeyBtn.Text = key.Name; pcall(callback, key) end} end
    end

    function Lib:Box(text, callback)
        local BoxFrame = Create("Frame", {Parent = SettingsContainer, BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 50)})
        Create("UICorner", {Parent = BoxFrame, CornerRadius = UDim.new(0, 6)})
        Create("TextLabel", {Parent = BoxFrame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 10, 0, 5), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        local TextBox = Create("TextBox", {Parent = BoxFrame, BackgroundColor3 = Color3.fromRGB(25, 25, 25), TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.Gotham, TextSize = 14, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 25), Text = "", PlaceholderText = "Type name here...", TextXAlignment = Enum.TextXAlignment.Left})
        Create("UICorner", {Parent = TextBox, CornerRadius = UDim.new(0, 4)})
        TextBox.FocusLost:Connect(function() callback(TextBox.Text) end)
        return TextBox
    end
    function Lib:Dropdown(text, options, callback)
        local DropFrame = Create("Frame", {Parent = SettingsContainer, BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 36), ClipsDescendants = true})
        Create("UICorner", {Parent = DropFrame, CornerRadius = UDim.new(0, 6)})
        local DropBtn = Create("TextButton", {Parent = DropFrame, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0)})
        local Label = Create("TextLabel", {Parent = DropBtn, Text = text .. ": None", TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -30, 0, 36), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
        local Icon = Create("TextLabel", {Parent = DropBtn, Text = "v", TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(0, 30, 0, 36), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1})
        local open = false
        local OptionContainer = Create("Frame", {Parent = DropFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 36)})
        local OptionList = Create("UIListLayout", {Parent = OptionContainer, SortOrder = Enum.SortOrder.LayoutOrder})
        local function Refresh(newOptions)
             for _,v in pairs(OptionContainer:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
             for _, opt in pairs(newOptions) do
                local OptBtn = Create("TextButton", {Parent = OptionContainer, Text = opt, BackgroundColor3 = Color3.fromRGB(45,45,45), TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 13, Size = UDim2.new(1, 0, 0, 30), AutoButtonColor = false})
                OptBtn.MouseButton1Click:Connect(function() Label.Text = text .. ": " .. opt; callback(opt); open = false; DropFrame:TweenSize(UDim2.new(0.96, 0, 0, 36), "Out", "Quad", 0.2, true) end)
             end
        end
        Refresh(options)
        DropBtn.MouseButton1Click:Connect(function() open = not open; local contentSize = OptionList.AbsoluteContentSize.Y; DropFrame:TweenSize(open and UDim2.new(0.96, 0, 0, 36 + contentSize) or UDim2.new(0.96, 0, 0, 36), "Out", "Quad", 0.2, true) end)
        return {Refresh = Refresh, UpdateText = function(t) Label.Text = text .. ": " .. t end}
    end
    function Lib:Button(text, callback, isSettings)
        local Btn = Create("TextButton", {Parent = GetContainer(isSettings), BackgroundColor3 = FSSHUB.Theme.Item, Size = UDim2.new(0.96, 0, 0, 36), Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false})
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
        Btn.MouseButton1Click:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = FSSHUB.Theme.Accent}):Play() wait(0.1) TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = FSSHUB.Theme.Item}):Play() pcall(callback) end)
    end
    function Lib:Label(text, isSettings)
        local LabelFrame = Create("Frame", {Parent = GetContainer(isSettings), BackgroundTransparency = 1, Size = UDim2.new(0.96, 0, 0, 20)})
        Create("TextLabel", {Parent = LabelFrame, Text = text, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 13, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 1})
    end

    -- CONFIG & SETTINGS
    local CurrentConfigName, ConfigListDropdown = "", nil
    local function GetConfigs() local f={} if listfiles then for _,g in pairs(listfiles(FSSHUB.FolderName)) do local n=g:match("([^/]+)%.json$") if n then table.insert(f,n) end end end return f end
    function Lib:CreateConfigSystem(discordLink)
        Lib:Section("CONFIG MANAGER", true)
        Lib:Box("Preset Name", function(val) CurrentConfigName = val end)
        Lib:Button("Save Config", function() if CurrentConfigName~="" and writefile then local s,e=pcall(function() local j=HttpService:JSONEncode(FSSHUB.ConfigData) writefile(FSSHUB.FolderName.."/"..CurrentConfigName..".json",j) end) if s then Lib:Notify("Saved: "..CurrentConfigName, "success") ConfigListDropdown.Refresh(GetConfigs()) else Lib:Notify("Save Failed!", "error") end else Lib:Notify("Enter Name!", "error") end end, true)
        ConfigListDropdown = Lib:Dropdown("Select Preset", GetConfigs(), function(val) CurrentConfigName = val end)
        Lib:Button("Load Selected", function() if CurrentConfigName~="" and readfile and isfile(FSSHUB.FolderName.."/"..CurrentConfigName..".json") then local s,d=pcall(function() return HttpService:JSONDecode(readfile(FSSHUB.FolderName.."/"..CurrentConfigName..".json")) end) if s and d then for n,v in pairs(d) do if FSSHUB.Elements[n] then FSSHUB.Elements[n].Function(v) end end Lib:Notify("Loaded!", "success") else Lib:Notify("Load Failed!", "error") end else Lib:Notify("Not Found!", "error") end end, true)
        Lib:Button("Set Autoload", function() if CurrentConfigName~="" and writefile then writefile(FSSHUB.FolderName.."/"..FSSHUB.AutoloadFile, CurrentConfigName) Lib:Notify("Autoload Set!", "success") end end, true)
        Lib:Section("UI SETTINGS", true)
        Lib:Slider("Font Size", 10, 18, 14, function(v) for _,o in pairs(Main:GetDescendants()) do if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Name~="BrandTitle" and o.Text~="⚙️" and o.Text~="↘" and o.Text~="×" and o.Text~="-" and o.Text~="v" then o.TextSize=v end end end, true)
        Lib:Section("CREDITS", true)
        Lib:Label("Script by: FSSHUB", true)
        if discordLink then Lib:Button("Copy Discord", function() if setclipboard then setclipboard(discordLink) Lib:Notify("Link Copied!", "success") else Lib:Notify("No Clipboard!", "error") end end, true) end
    end
    function Lib:CheckAutoload()
        if readfile and isfile(FSSHUB.FolderName.."/"..FSSHUB.AutoloadFile) then
            local n=readfile(FSSHUB.FolderName.."/"..FSSHUB.AutoloadFile)
            if isfile(FSSHUB.FolderName.."/"..n..".json") then
                CurrentConfigName=n; ConfigListDropdown.UpdateText(n)
                spawn(function() wait(0.5) local s,d=pcall(function() return HttpService:JSONDecode(readfile(FSSHUB.FolderName.."/"..n..".json")) end) if s and d then for k,v in pairs(d) do if FSSHUB.Elements[k] then FSSHUB.Elements[k].Function(v) end end Lib:Notify("Autoloaded!", "success") end end)
            end
        end
    end
    return Lib
end
return FSSHUB
