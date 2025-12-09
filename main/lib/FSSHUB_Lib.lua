-- [[ FSSHUB LIBRARY V5.2 (ENHANCED) ]] --
-- Added: Dropdown Support & Better Animations

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local FSSHUB = {}
FSSHUB.Theme = {
    Accent = Color3.fromRGB(0, 255, 136),
    Background = Color3.fromRGB(18, 18, 18),
    Card = Color3.fromRGB(25, 25, 25),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Outline = Color3.fromRGB(45, 45, 45),
}

FSSHUB.Config = {}
FSSHUB.Connections = {}

-- [UTILITIES]
local function Create(class, props)
    local inst = Instance.new(class)
    local parent = props.Parent
    props.Parent = nil
    for i, v in pairs(props) do inst[i] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function GetParent()
    if gethui then return gethui() end
    if CoreGui then return CoreGui end
    return Players.LocalPlayer:WaitForChild("PlayerGui", 5)
end

function FSSHUB:Window(title)
    local Lib = {}
    local Parent = GetParent()
    
    for _, v in pairs(Parent:GetChildren()) do if v.Name == "FSSHUB_Main" then v:Destroy() end end
    
    local Screen = Create("ScreenGui", {Name = "FSSHUB_Main", Parent = Parent, ResetOnSpawn = false, DisplayOrder = 10000})
    local Main = Create("Frame", {
        Parent = Screen, BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0, 550, 0, 350),
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true
    })
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = Main, Color = FSSHUB.Theme.Accent, Thickness = 2})

    -- Header (Simple Drag)
    local Header = Create("Frame", {Parent = Main, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 45)})
    Create("TextLabel", {Parent = Header, Text = title, TextColor3 = FSSHUB.Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 18, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
    
    local CloseBtn = Create("TextButton", {Parent = Header, Text = "×", TextColor3 = Color3.fromRGB(255, 60, 60), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 45, 1, 0), Position = UDim2.new(1, -45, 0, 0)})
    CloseBtn.MouseButton1Click:Connect(function() Screen:Destroy() end)
    
    -- Draggable Logic
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = Main.Position
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local Sidebar = Create("ScrollingFrame", {Parent = Main, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(0, 140, 1, -45), Position = UDim2.new(0, 0, 0, 45), ScrollBarThickness = 0, BorderSizePixel = 0})
    Create("UIListLayout", {Parent = Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 10)})

    local Content = Create("Frame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, -150, 1, -55), Position = UDim2.new(0, 150, 0, 50)})
    local Tabs = {}

    function Lib:Section(name)
        local TabBtn = Create("TextButton", {Parent = Sidebar, Text = name, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 13, BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0.9, 0, 0, 35), AutoButtonColor = false})
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
        
        local Page = Create("ScrollingFrame", {Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ScrollBarThickness = 2, Visible = false, CanvasSize = UDim2.new(0,0,0,0)})
        local List = Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
        Create("UIPadding", {Parent = Page, PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 10)})
        
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Page.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 20) end)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false
                t.Btn.TextColor3 = FSSHUB.Theme.TextDim
                TweenService:Create(t.Btn, TweenInfo.new(0.2), {BackgroundColor3 = FSSHUB.Theme.Background}):Play()
            end
            Page.Visible = true
            TabBtn.TextColor3 = FSSHUB.Theme.Accent
            TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
        end)
        
        if #Tabs == 0 then
            Page.Visible = true
            TabBtn.TextColor3 = FSSHUB.Theme.Accent
            TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        end
        table.insert(Tabs, {Page = Page, Btn = TabBtn})

        local Elements = {}

        function Elements:Toggle(text, default, callback)
            local enabled = default or false
            FSSHUB.Config[text] = enabled
            local Btn = Create("TextButton", {Parent = Page, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 40), Text = "", AutoButtonColor = false})
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {Parent = Btn, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
            local Indicator = Create("Frame", {Parent = Btn, BackgroundColor3 = enabled and FSSHUB.Theme.Accent or FSSHUB.Theme.Outline, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0.5, -10)})
            Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 4)})

            Btn.MouseButton1Click:Connect(function()
                enabled = not enabled
                FSSHUB.Config[text] = enabled
                TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = enabled and FSSHUB.Theme.Accent or FSSHUB.Theme.Outline}):Play()
                pcall(callback, enabled)
            end)
        end

        function Elements:Slider(text, min, max, default, callback)
            local value = default or min
            local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 55)})
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {Parent = Frame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
            local ValLabel = Create("TextLabel", {Parent = Frame, Text = tostring(value), TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(0, 30, 0, 25), Position = UDim2.new(1, -40, 0, 0), BackgroundTransparency = 1})
            local SlideBar = Create("TextButton", {Parent = Frame, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 8), Position = UDim2.new(0, 10, 0, 35)})
            local Fill = Create("Frame", {Parent = Create("Frame", {Parent = SlideBar, BackgroundColor3 = FSSHUB.Theme.Outline, Size = UDim2.new(1, 0, 1, 0), Parent = SlideBar}), BackgroundColor3 = FSSHUB.Theme.Accent, Size = UDim2.new((value-min)/(max-min), 0, 1, 0)})
            
            local function Update(input)
                local percent = math.clamp((input.Position.X - SlideBar.AbsolutePosition.X) / SlideBar.AbsoluteSize.X, 0, 1)
                value = math.floor(min + ((max - min) * percent))
                ValLabel.Text = tostring(value)
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                pcall(callback, value)
            end
            SlideBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then Update(i); local c; c=UserInputService.InputChanged:Connect(function(io) if io.UserInputType==Enum.UserInputType.MouseMovement then Update(io) end end); i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then c:Disconnect() end end) end end)
        end

        -- [NEW] DROPDOWN FEATURE
        function Elements:Dropdown(text, options, default, callback)
            local expanded = false
            local selected = default or options[1]
            local DropFrame = Create("Frame", {Parent = Page, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 40), ClipsDescendants = true})
            Create("UICorner", {Parent = DropFrame, CornerRadius = UDim.new(0, 6)})
            
            local Btn = Create("TextButton", {Parent = DropFrame, Text = "", Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1})
            Create("TextLabel", {Parent = Btn, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
            local SelLabel = Create("TextLabel", {Parent = Btn, Text = selected .. " v", TextColor3 = FSSHUB.Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 12, Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -110, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1})
            
            local Container = Create("Frame", {Parent = DropFrame, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1})
            local List = Create("UIListLayout", {Parent = Container, SortOrder = Enum.SortOrder.LayoutOrder})
            
            for _, opt in pairs(options) do
                local OptBtn = Create("TextButton", {Parent = Container, Text = opt, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = FSSHUB.Theme.Card, AutoButtonColor = false})
                OptBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    SelLabel.Text = opt .. " v"
                    pcall(callback, opt)
                    expanded = false
                    TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                end)
            end
            
            Btn.MouseButton1Click:Connect(function()
                expanded = not expanded
                local h = expanded and (40 + (#options * 30)) or 40
                TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, h)}):Play()
            end)
        end
        
        function Elements:InitConfig() end -- Placeholder for consistency

        return Elements
    end
    return Lib
end
return FSSHUB
