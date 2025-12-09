-- [[ FSSHUB LIBRARY SOURCE V4.0 (UNIVERSAL UI) ]] --
-- Update: Added AuthWindow for Loader, Glow Effects, Enhanced Animations

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local FSSHUB = {}
FSSHUB.Theme = {
    Accent = Color3.fromRGB(0, 255, 136), -- Neon Green Signature
    Background = Color3.fromRGB(15, 15, 15),
    Card = Color3.fromRGB(25, 25, 25),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Error = Color3.fromRGB(255, 80, 80),
    Success = Color3.fromRGB(80, 255, 120),
    Outline = Color3.fromRGB(40, 40, 40)
}

-- STATE GLOBAL
FSSHUB.FolderName = "FSSHUB_WaveZ"
FSSHUB.AutoloadFile = "Autoload.txt"
FSSHUB.ConfigData = {} 
FSSHUB.Elements = {} 
FSSHUB.ActiveConnections = {}

if makefolder and not isfolder(FSSHUB.FolderName) then 
    pcall(function() makefolder(FSSHUB.FolderName) end)
end

-- [INTERNAL] UTILITIES
local function Create(class, props)
    local inst = Instance.new(class)
    for i, v in pairs(props) do inst[i] = v end
    return inst
end

local function GetSafeParent()
    if gethui then
        local s, r = pcall(gethui)
        if s and r and r:IsA("Instance") then return r end
    end
    if CoreGui then return CoreGui end
    if Players.LocalPlayer then return Players.LocalPlayer:WaitForChild("PlayerGui", 2) end
    return nil
end

local function AddStroke(parent, color, thickness)
    local stroke = Create("UIStroke", {Parent = parent, Color = color, Thickness = thickness or 1, Transparency = 0})
    return stroke
end

local function MakeDraggable(handle, frame)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local smoothPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            TweenService:Create(frame, TweenInfo.new(0.05), {Position = smoothPos}):Play()
        end
    end)
end

-- [COMPONENT] NOTIFICATION SYSTEM
function FSSHUB:Notify(text, type, duration)
    local Parent = GetSafeParent()
    if not Parent then return end
    
    local Screen = Parent:FindFirstChild("FSSHUB_Notify")
    if not Screen then
        Screen = Create("ScreenGui", {Name = "FSSHUB_Notify", Parent = Parent, ResetOnSpawn = false, DisplayOrder = 10001})
    end

    local Container = Screen:FindFirstChild("Container")
    if not Container then
        Container = Create("Frame", {Name = "Container", Parent = Screen, BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, 0), Position = UDim2.new(1, -320, 0, 0)})
        Create("UIListLayout", {Parent = Container, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10)})
        Create("UIPadding", {Parent = Container, PaddingBottom = UDim.new(0, 50)})
    end

    local Color = type == "error" and FSSHUB.Theme.Error or FSSHUB.Theme.Accent
    local Notif = Create("Frame", {
        Parent = Container, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 50), 
        BackgroundTransparency = 1, Position = UDim2.new(1, 0, 0, 0) -- Start Offscreen
    })
    Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 8)})
    AddStroke(Notif, Color, 1.5)
    
    local Icon = Create("TextLabel", {Parent = Notif, Text = type == "error" and "!" or "✓", TextColor3 = Color, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 40, 1, 0), BackgroundTransparency = 1})
    Create("TextLabel", {Parent = Notif, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 14, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 45, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextWrapped = true})

    -- Animation In
    TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {BackgroundTransparency = 0.1, Position = UDim2.new(0, 0, 0, 0)}):Play()
    
    task.delay(duration or 3, function()
        TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 1, Position = UDim2.new(1, 50, 0, 0)}):Play()
        task.wait(0.3)
        Notif:Destroy()
    end)
end

-- [MODE 1] AUTH WINDOW (Untuk Loader)
function FSSHUB:AuthWindow(options)
    local Auth = {}
    local Parent = GetSafeParent()
    
    -- Cleanup Old UI
    for _, v in pairs(Parent:GetChildren()) do if v.Name == "FSSHUB_Auth" then v:Destroy() end end

    local Screen = Create("ScreenGui", {Name = "FSSHUB_Auth", Parent = Parent, ResetOnSpawn = false, DisplayOrder = 9999})
    
    -- Main Card
    local Main = Create("Frame", {
        Parent = Screen, BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0, 0, 0, 0), -- Start Small
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true
    })
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 10)})
    AddStroke(Main, FSSHUB.Theme.Accent, 2)
    
    -- Animate Open
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {Size = UDim2.new(0, 380, 0, 220)}):Play()
    MakeDraggable(Main, Main)

    -- Elements
    local Title = Create("TextLabel", {Parent = Main, Text = options.Title or "AUTHENTICATION", TextColor3 = FSSHUB.Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 20, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 10), BackgroundTransparency = 1})
    local Status = Create("TextLabel", {Parent = Main, Text = options.Status or "Please enter your key below", TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 35), BackgroundTransparency = 1})

    local KeyInput = Create("TextBox", {
        Parent = Main, BackgroundColor3 = FSSHUB.Theme.Card, TextColor3 = FSSHUB.Theme.Accent,
        Font = Enum.Font.Mono, TextSize = 14, Size = UDim2.new(0.8, 0, 0, 40), Position = UDim2.new(0.1, 0, 0.35, 0),
        Text = "", PlaceholderText = "Paste Key Here..."
    })
    Create("UICorner", {Parent = KeyInput, CornerRadius = UDim.new(0, 6)})
    AddStroke(KeyInput, FSSHUB.Theme.Outline, 1)

    local BtnContainer = Create("Frame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(0.8, 0, 0, 40), Position = UDim2.new(0.1, 0, 0.65, 0)})
    Create("UIListLayout", {Parent = BtnContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10)})

    local function CreateAuthBtn(text, color, callback)
        local Btn = Create("TextButton", {
            Parent = BtnContainer, Text = text, TextColor3 = Color3.new(0,0,0), Font = Enum.Font.GothamBold, TextSize = 14,
            BackgroundColor3 = color, Size = UDim2.new(0.5, -5, 1, 0), AutoButtonColor = false
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
        
        Btn.MouseButton1Click:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(0.5, -10, 0.9, 0)}):Play()
            task.wait(0.1)
            TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(0.5, -5, 1, 0)}):Play()
            callback(KeyInput.Text)
        end)
    end

    CreateAuthBtn("GET KEY", FSSHUB.Theme.Text, function() 
        if options.GetKeyLink then 
            if setclipboard then setclipboard(options.GetKeyLink) end
            FSSHUB:Notify("Link Copied to Clipboard!", "success")
        end 
    end)

    CreateAuthBtn("LOGIN", FSSHUB.Theme.Accent, function(text)
        if options.OnLogin then
            Status.Text = "Checking..."
            Status.TextColor3 = FSSHUB.Theme.Text
            local success = options.OnLogin(text)
            if success then
                Status.Text = "Access Granted!"
                Status.TextColor3 = FSSHUB.Theme.Accent
                TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
                task.wait(0.3)
                Screen:Destroy()
            else
                Status.Text = "Invalid Key!"
                Status.TextColor3 = FSSHUB.Theme.Error
                -- Shake Effect
                for i=1,5 do Main.Position = Main.Position + UDim2.new(0, 5, 0, 0); task.wait(0.03); Main.Position = Main.Position - UDim2.new(0, 5, 0, 0); task.wait(0.03) end
            end
        end
    end)

    -- Close Button
    local Close = Create("TextButton", {Parent = Main, Text = "×", TextColor3 = FSSHUB.Theme.Error, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -30, 0, 0)})
    Close.MouseButton1Click:Connect(function() Screen:Destroy() end)
    
    return Auth
end

-- [MODE 2] MAIN WINDOW (Untuk Game Menu)
function FSSHUB:Window(title)
    local Lib = {}
    local Parent = GetSafeParent()
    
    if Parent:FindFirstChild("FSSHUB_Main") then Parent.FSSHUB_Main:Destroy() end
    local Screen = Create("ScreenGui", {Name = "FSSHUB_Main", Parent = Parent, ResetOnSpawn = false, DisplayOrder = 10000})

    local Main = Create("Frame", {
        Parent = Screen, BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0, 500, 0, 350),
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true
    })
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
    AddStroke(Main, FSSHUB.Theme.Accent, 2)
    MakeDraggable(Main, Main)

    -- Sidebar (Tabs)
    local Sidebar = Create("Frame", {Parent = Main, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(0, 140, 1, 0)})
    Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0, 8)})
    Create("Frame", {Parent = Sidebar, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BorderSizePixel=0}) -- Filler
    
    local TabContainer = Create("ScrollingFrame", {Parent = Sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 50), ScrollBarThickness=0})
    Create("UIListLayout", {Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    
    -- Content Area
    local ContentArea = Create("Frame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, -150, 1, -50), Position = UDim2.new(0, 145, 0, 45)})
    
    -- Title
    Create("TextLabel", {Parent = Sidebar, Text = "FSS HUB", TextColor3 = FSSHUB.Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 22, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1})
    Create("TextLabel", {Parent = Main, Text = title, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 14, Size = UDim2.new(1, -150, 0, 40), Position = UDim2.new(0, 145, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})

    -- Navigation Logic
    local Tabs = {}
    local FirstTab = true

    function Lib:Section(name) -- Actually creates a Tab
        local TabBtn = Create("TextButton", {
            Parent = TabContainer, Text = name, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamMedium, TextSize = 14,
            BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0.9, 0, 0, 35), AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
        
        local TabFrame = Create("ScrollingFrame", {
            Parent = ContentArea, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 2, Visible = false, CanvasSize = UDim2.new(0,0,0,0)
        })
        Create("UIListLayout", {Parent = TabFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
        Create("UIPadding", {Parent = TabFrame, PaddingRight = UDim.new(0, 5)})
        
        -- Auto Canvas Resize
        TabFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabFrame.CanvasSize = UDim2.new(0, 0, 0, TabFrame.UIListLayout.AbsoluteContentSize.Y + 20)
        end)

        -- Tab Switching Logic
        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Frame.Visible = false
                t.Btn.TextColor3 = FSSHUB.Theme.TextDim
                t.Btn.BackgroundColor3 = FSSHUB.Theme.Background
            end
            TabFrame.Visible = true
            TabBtn.TextColor3 = FSSHUB.Theme.Accent
            TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        end)
        
        if FirstTab then
            FirstTab = false
            TabFrame.Visible = true
            TabBtn.TextColor3 = FSSHUB.Theme.Accent
            TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        end
        
        table.insert(Tabs, {Frame = TabFrame, Btn = TabBtn})
        
        -- Tab Elements
        local TabLib = {}
        
        function TabLib:Toggle(text, default, callback)
            local toggled = default or false
            local Btn = Create("TextButton", {Parent = TabFrame, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 40), Text = "", AutoButtonColor = false})
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {Parent = Btn, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
            
            local Status = Create("Frame", {Parent = Btn, BackgroundColor3 = toggled and FSSHUB.Theme.Accent or Color3.fromRGB(50,50,50), Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0.5, -10)}); Create("UICorner", {Parent = Status, CornerRadius = UDim.new(0, 4)})

            Btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                TweenService:Create(Status, TweenInfo.new(0.2), {BackgroundColor3 = toggled and FSSHUB.Theme.Accent or Color3.fromRGB(50,50,50)}):Play()
                pcall(callback, toggled)
            end)
            if default then pcall(callback, true) end
        end

        function TabLib:Button(text, callback)
            local Btn = Create("TextButton", {Parent = TabFrame, Text = text, BackgroundColor3 = FSSHUB.Theme.Card, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamBold, TextSize = 13, Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false})
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
            Btn.MouseButton1Click:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = FSSHUB.Theme.Accent, TextColor3 = Color3.new(0,0,0)}):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = FSSHUB.Theme.Card, TextColor3 = FSSHUB.Theme.Text}):Play()
                pcall(callback)
            end)
        end
        
        function TabLib:Slider(text, min, max, default, callback)
            local val = default or min
            local Frame = Create("Frame", {Parent = TabFrame, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 55)}); Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {Parent = Frame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 10, 0, 5), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
            local ValLbl = Create("TextLabel", {Parent = Frame, Text = tostring(val), TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(0, 30, 0, 20), Position = UDim2.new(1, -40, 0, 5), BackgroundTransparency = 1})
            
            local Bar = Create("TextButton", {Parent = Frame, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 10), Position = UDim2.new(0, 10, 0, 35)})
            local Bg = Create("Frame", {Parent = Bar, BackgroundColor3 = Color3.fromRGB(40,40,40), Size = UDim2.new(1, 0, 1, 0)}); Create("UICorner", {Parent = Bg, CornerRadius = UDim.new(1, 0)})
            local Fill = Create("Frame", {Parent = Bar, BackgroundColor3 = FSSHUB.Theme.Accent, Size = UDim2.new((val-min)/(max-min), 0, 1, 0)}); Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
            
            local function Update(input)
                local p = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                val = math.floor(min + ((max - min) * p))
                ValLbl.Text = tostring(val)
                Fill.Size = UDim2.new(p, 0, 1, 0)
                pcall(callback, val)
            end
            
            local dragging
            Bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; Update(i) end end)
            UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
        end

        return TabLib
    end

    -- Toggle UI Global
    function Lib:ToggleUI() Screen.Enabled = not Screen.Enabled end
    
    -- Config System
    function Lib:CreateConfigSystem(discord)
        local Tab = Lib:Section("Settings")
        Tab:Button("Copy Discord Link", function() if setclipboard then setclipboard(discord) FSSHUB:Notify("Copied!", "success") end end)
        Tab:Button("Unload Script", function() Screen:Destroy(); for _, c in pairs(FSSHUB.ActiveConnections) do c:Disconnect() end end)
    end

    return Lib
end

return FSSHUB
