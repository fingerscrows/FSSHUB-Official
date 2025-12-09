-- [[ FSSHUB LIBRARY V5.1 (STABLE RELEASE) ]] --
-- Focus: Game UI Only (Tabs, Toggles, Sliders). Auth Logic removed.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local FSSHUB = {}
FSSHUB.Theme = {
    Accent = Color3.fromRGB(0, 255, 136), -- FSSHUB Green
    Background = Color3.fromRGB(18, 18, 18),
    Card = Color3.fromRGB(25, 25, 25),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(150, 150, 150),
    Outline = Color3.fromRGB(45, 45, 45),
    Error = Color3.fromRGB(255, 60, 60),
    Success = Color3.fromRGB(60, 255, 100)
}

-- STATE
FSSHUB.FolderName = "FSSHUB_V5_Data"
FSSHUB.Config = {}
FSSHUB.Connections = {}

if makefolder and not isfolder(FSSHUB.FolderName) then 
    pcall(function() makefolder(FSSHUB.FolderName) end)
end

-- [INTERNAL] UTILITIES
local function Create(class, props)
    local inst = Instance.new(class)
    local parent = props.Parent
    props.Parent = nil
    for i, v in pairs(props) do inst[i] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function GetParent()
    if gethui then 
        local s, r = pcall(gethui)
        if s and r and r:IsA("Instance") then return r end
    end
    if CoreGui then return CoreGui end
    return Players.LocalPlayer:WaitForChild("PlayerGui", 5)
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
            local target = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            TweenService:Create(frame, TweenInfo.new(0.05), {Position = target}):Play()
        end
    end)
end

-- [INTERNAL] NOTIFICATION SYSTEM
function FSSHUB:Notify(text, type, duration)
    local Parent = GetParent()
    if not Parent then return end
    
    local Screen = Parent:FindFirstChild("FSSHUB_Notify") or Create("ScreenGui", {Name = "FSSHUB_Notify", Parent = Parent, ResetOnSpawn = false, DisplayOrder = 10001})
    local Container = Screen:FindFirstChild("Container") or Create("Frame", {Name = "Container", Parent = Screen, BackgroundTransparency = 1, Size = UDim2.new(0, 300, 1, 0), Position = UDim2.new(1, -320, 0, 0)})
    
    if not Container:FindFirstChild("Layout") then
        Create("UIListLayout", {Name = "Layout", Parent = Container, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10)})
        Create("UIPadding", {Parent = Container, PaddingBottom = UDim.new(0, 50)})
    end

    local Color = type == "error" and FSSHUB.Theme.Error or FSSHUB.Theme.Accent
    local Card = Create("Frame", {
        Parent = Container, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1, Position = UDim2.new(1, 50, 0, 0) -- Start offscreen
    })
    Create("UICorner", {Parent = Card, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = Card, Color = Color, Thickness = 1.5, Transparency = 0})
    
    Create("TextLabel", {Parent = Card, Text = type == "error" and "!" or "✓", TextColor3 = Color, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 40, 1, 0), BackgroundTransparency = 1})
    Create("TextLabel", {Parent = Card, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 13, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 45, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextWrapped = true})

    TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Back), {BackgroundTransparency = 0.1, Position = UDim2.new(0, 0, 0, 0)}):Play()
    
    task.delay(duration or 3, function()
        TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {BackgroundTransparency = 1, Position = UDim2.new(1, 50, 0, 0)}):Play()
        task.wait(0.4)
        Card:Destroy()
    end)
end

-- [MAIN] WINDOW FUNCTION
function FSSHUB:Window(title)
    local Lib = {}
    local Parent = GetParent()
    
    -- Cleanup Old GUI
    for _, v in pairs(Parent:GetChildren()) do if v.Name == "FSSHUB_Main" then v:Destroy() end end
    
    local Screen = Create("ScreenGui", {Name = "FSSHUB_Main", Parent = Parent, ResetOnSpawn = false, DisplayOrder = 10000})

    -- Main Container
    local Main = Create("Frame", {
        Parent = Screen, BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0, 550, 0, 350),
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), ClipsDescendants = true
    })
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = Main, Color = FSSHUB.Theme.Accent, Thickness = 2})

    -- Header (Draggable)
    local Header = Create("Frame", {Parent = Main, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 45)})
    Create("TextLabel", {Parent = Header, Text = title, TextColor3 = FSSHUB.Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 18, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 15, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1})
    
    local CloseBtn = Create("TextButton", {Parent = Header, Text = "×", TextColor3 = FSSHUB.Theme.Error, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 24, Size = UDim2.new(0, 45, 1, 0), Position = UDim2.new(1, -45, 0, 0)})
    CloseBtn.MouseButton1Click:Connect(function() 
        for _, c in pairs(FSSHUB.Connections) do c:Disconnect() end
        Screen:Destroy() 
    end)
    MakeDraggable(Header, Main)

    -- Sidebar (For Tabs)
    local Sidebar = Create("ScrollingFrame", {
        Parent = Main, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(0, 140, 1, -45), 
        Position = UDim2.new(0, 0, 0, 45), ScrollBarThickness = 0, BorderSizePixel = 0
    })
    Create("UIListLayout", {Parent = Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center})
    Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 10)})

    -- Content Area
    local Content = Create("Frame", {Parent = Main, BackgroundTransparency = 1, Size = UDim2.new(1, -150, 1, -55), Position = UDim2.new(0, 150, 0, 50)})
    
    local Tabs = {}
    local FirstTab = true

    function Lib:Section(name) -- Adds a Tab
        local TabBtn = Create("TextButton", {
            Parent = Sidebar, Text = name, TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 13,
            BackgroundColor3 = FSSHUB.Theme.Background, Size = UDim2.new(0.9, 0, 0, 35), AutoButtonColor = false
        })
        Create("UICorner", {Parent = TabBtn, CornerRadius = UDim.new(0, 6)})
        
        -- The Page
        local Page = Create("ScrollingFrame", {
            Parent = Content, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), 
            ScrollBarThickness = 3, Visible = false, CanvasSize = UDim2.new(0,0,0,0)
        })
        local List = Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
        Create("UIPadding", {Parent = Page, PaddingRight = UDim.new(0, 5)})
        
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 20)
        end)

        -- Tab Selection Logic
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

        if FirstTab then
            FirstTab = false
            Page.Visible = true
            TabBtn.TextColor3 = FSSHUB.Theme.Accent
            TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        end

        table.insert(Tabs, {Page = Page, Btn = TabBtn})

        -- TAB ELEMENTS
        local Elements = {}
        
        function Elements:Toggle(text, default, callback)
            local enabled = default or false
            FSSHUB.Config[text] = enabled
            
            local Btn = Create("TextButton", {
                Parent = Page, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 40), 
                Text = "", AutoButtonColor = false
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {
                Parent = Btn, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, 
                TextSize = 13, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), 
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
            })
            
            local Indicator = Create("Frame", {
                Parent = Btn, BackgroundColor3 = enabled and FSSHUB.Theme.Accent or FSSHUB.Theme.Outline, 
                Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0.5, -10)
            })
            Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 4)})

            local function Update(val)
                enabled = val
                FSSHUB.Config[text] = val
                TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = val and FSSHUB.Theme.Accent or FSSHUB.Theme.Outline}):Play()
                pcall(callback, val)
            end

            Btn.MouseButton1Click:Connect(function() Update(not enabled) end)
            if default then Update(true) end
            
            -- Save for config system
            FSSHUB.Config[text] = enabled
            return {
                Set = Update
            }
        end

        function Elements:Slider(text, min, max, default, callback)
            local value = default or min
            FSSHUB.Config[text] = value
            
            local Frame = Create("Frame", {
                Parent = Page, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 55)
            })
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            
            Create("TextLabel", {
                Parent = Frame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, 
                TextSize = 13, Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 10, 0, 0), 
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
            })
            
            local ValLabel = Create("TextLabel", {
                Parent = Frame, Text = tostring(value), TextColor3 = FSSHUB.Theme.TextDim, Font = Enum.Font.Gotham, 
                TextSize = 12, Size = UDim2.new(0, 30, 0, 25), Position = UDim2.new(1, -40, 0, 0), 
                BackgroundTransparency = 1
            })
            
            local SlideBar = Create("TextButton", {
                Parent = Frame, Text = "", BackgroundTransparency = 1, 
                Size = UDim2.new(1, -20, 0, 8), Position = UDim2.new(0, 10, 0, 35)
            })
            local BarBg = Create("Frame", {Parent = SlideBar, BackgroundColor3 = FSSHUB.Theme.Outline, Size = UDim2.new(1, 0, 1, 0)})
            Create("UICorner", {Parent = BarBg, CornerRadius = UDim.new(1, 0)})
            local Fill = Create("Frame", {Parent = BarBg, BackgroundColor3 = FSSHUB.Theme.Accent, Size = UDim2.new((value-min)/(max-min), 0, 1, 0)})
            Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
            
            local function Update(input)
                local percent = math.clamp((input.Position.X - SlideBar.AbsolutePosition.X) / SlideBar.AbsoluteSize.X, 0, 1)
                local newVal = math.floor(min + ((max - min) * percent))
                value = newVal
                FSSHUB.Config[text] = newVal
                ValLabel.Text = tostring(newVal)
                Fill.Size = UDim2.new(percent, 0, 1, 0)
                pcall(callback, newVal)
            end
            
            local dragging
            SlideBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true; Update(i) end end)
            UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
        end
        
        function Elements:Button(text, callback)
            local Btn = Create("TextButton", {
                Parent = Page, Text = text, BackgroundColor3 = FSSHUB.Theme.Card, TextColor3 = FSSHUB.Theme.Text,
                Font = Enum.Font.GothamBold, TextSize = 13, Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
            Btn.MouseButton1Click:Connect(function()
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = FSSHUB.Theme.Accent, TextColor3 = Color3.new(0,0,0)}):Play()
                task.wait(0.1)
                TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = FSSHUB.Theme.Card, TextColor3 = FSSHUB.Theme.Text}):Play()
                pcall(callback)
            end)
        end
        
        function Elements:Keybind(text, default, callback)
            local key = default or Enum.KeyCode.RightControl
            FSSHUB.Config[text] = key.Name
            
            local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = FSSHUB.Theme.Card, Size = UDim2.new(1, 0, 0, 40)})
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {
                Parent = Frame, Text = text, TextColor3 = FSSHUB.Theme.Text, Font = Enum.Font.GothamMedium, 
                TextSize = 13, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), 
                TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
            })
            
            local Btn = Create("TextButton", {
                Parent = Frame, Text = key.Name, BackgroundColor3 = FSSHUB.Theme.Outline, TextColor3 = FSSHUB.Theme.TextDim,
                Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -90, 0.5, -12)
            })
            Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 4)})
            
            Btn.MouseButton1Click:Connect(function()
                Btn.Text = "..."
                Btn.TextColor3 = FSSHUB.Theme.Accent
                local input = UserInputService.InputBegan:Wait()
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    Btn.Text = key.Name
                    Btn.TextColor3 = FSSHUB.Theme.TextDim
                    FSSHUB.Config[text] = key.Name
                    pcall(callback, key)
                end
            end)
            
            -- Init
            pcall(callback, key)
        end

        return Elements
    end
    
    -- CONFIG SYSTEM (Built-in)
    function Lib:InitConfig(discord)
        local Tab = Lib:Section("Settings")
        
        Tab:Button("Save Config (Default)", function()
            if writefile then
                writefile(FSSHUB.FolderName.."/default.json", HttpService:JSONEncode(FSSHUB.Config))
                FSSHUB:Notify("Config Saved!", "success")
            end
        end)
        
        Tab:Button("Load Config (Default)", function()
            if isfile and isfile(FSSHUB.FolderName.."/default.json") then
                FSSHUB:Notify("Config Loaded! (Restart script to apply)", "success")
            else
                FSSHUB:Notify("No Config Found", "error")
            end
        end)
        
        if discord then
            Tab:Button("Join Discord", function()
                if setclipboard then setclipboard(discord) end
                FSSHUB:Notify("Discord Link Copied!", "success")
            end)
        end
        
        Tab:Button("Unload Script", function()
            Screen:Destroy()
            for _, c in pairs(FSSHUB.Connections) do c:Disconnect() end
        end)
    end
    
    return Lib
end

return FSSHUB
