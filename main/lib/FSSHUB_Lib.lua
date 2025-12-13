-- [[ FSSHUB LIBRARY: V19.0 (STABLE + INPUT) ]] --
-- Changelog: Added TextBox & Dropdown Refresh based on V18.1 (No cuts)
-- Path: main/lib/FSSHUB_Lib.lua

local library = {
    flags = {}, 
    windows = {}, 
    open = true, -- Initial state matches visible window
    keybinds = {},
    gui_objects = {},
    wm_obj = nil,
    themeRegistry = {},
    transparencyFrames = {} 
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

library.theme = {
    Main        = Color3.fromRGB(20, 20, 25),
    Sidebar     = Color3.fromRGB(15, 15, 20),
    Content     = Color3.fromRGB(25, 25, 30),
    Accent      = Color3.fromRGB(140, 80, 255), 
    Text        = Color3.fromRGB(240, 240, 240),
    TextDim     = Color3.fromRGB(150, 150, 150),
    Stroke      = Color3.fromRGB(50, 50, 60),
    ItemBg      = Color3.fromRGB(30, 30, 35),
    ItemHover   = Color3.fromRGB(45, 45, 50)
}

library.presets = {
    ["FSS Purple"] = {Accent = Color3.fromRGB(140, 80, 255)},
    ["Blood Red"]  = {Accent = Color3.fromRGB(255, 65, 65)},
    ["Ocean Blue"] = {Accent = Color3.fromRGB(0, 140, 255)},
    ["Toxic Green"]= {Accent = Color3.fromRGB(0, 255, 140)},
    ["Golden Age"] = {Accent = Color3.fromRGB(255, 215, 0)},
    ["Midnight"]   = {Accent = Color3.fromRGB(80, 80, 255), Main = Color3.fromRGB(10, 10, 15), Content = Color3.fromRGB(15, 15, 20)}
}

function library:SetTransparency(val)
    for _, obj in ipairs(self.transparencyFrames) do
        if obj and obj.Parent then
            TweenService:Create(obj, TweenInfo.new(0.2), {BackgroundTransparency = val}):Play()
        end
    end
end

function library:RegisterTheme(obj, prop, key)
    if not obj then return end
    obj[prop] = self.theme[key]
    table.insert(self.themeRegistry, {Type = "Prop", Obj = obj, Prop = prop, Key = key})
end

function library:RegisterThemeFunc(func)
    func()
    table.insert(self.themeRegistry, {Type = "Func", Func = func})
end

function library:SetTheme(themeName)
    local selected = self.presets[themeName] or self.presets["FSS Purple"]
    for k, v in pairs(selected) do self.theme[k] = v end
    for _, item in ipairs(self.themeRegistry) do
        if item.Type == "Prop" and item.Obj and item.Obj.Parent then
            item.Obj[item.Prop] = self.theme[item.Key]
        elseif item.Type == "Func" then
            pcall(item.Func)
        end
    end
end

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function UpdateKeybind(tableBinds, oldKey, newKey, callback)
    if oldKey and tableBinds[oldKey] then
        for i, func in ipairs(tableBinds[oldKey]) do
            if func == callback then table.remove(tableBinds[oldKey], i) break end
        end
    end
    if newKey then
        if not tableBinds[newKey] then tableBinds[newKey] = {} end
        table.insert(tableBinds[newKey], callback)
    end
end

local function MakeDraggable(topbarobject, object)
    local dragging, dragInput, dragStart, startPos
    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = object.Position
        end
    end)
    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(object, TweenInfo.new(0.05), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

function library:Notify(title, text, duration)
    -- Fallback if GUI isn't ready
    if not self.base then
        -- Removed CoreGui Fallback to ensure unified design
        -- pcall(function() game.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 3}) end)
        return
    end

    local Holder = self.base:FindFirstChild("FSS_Notifications")
    if not Holder then
        Holder = Create("Frame", {
            Name = "FSS_Notifications", Parent = self.base,
            -- Compact Size & Bottom Right Positioning (Roblox style)
            Size = UDim2.new(0, 220, 0.8, 0), Position = UDim2.new(1, -10, 1, -20),
            AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1
        })
        Create("UIListLayout", {
            Parent = Holder, SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 5)
        })
    end

    -- Compact Container
    local Container = Create("Frame", {
        Parent = Holder, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = false
    })

    -- Compact Main Frame
    local Main = Create("Frame", {
        Parent = Container, Size = UDim2.new(1, 0, 0, 42), -- Smaller Height
        Position = UDim2.new(1, 50, 0, 0), BackgroundColor3 = library.theme.Main
    })
    library:RegisterTheme(Main, "BackgroundColor3", "Main")

    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 6)})
    local S = Create("UIStroke", {Parent = Main, Thickness = 1, Color = library.theme.Accent})
    library:RegisterTheme(S, "Color", "Accent")

    local TTitle = Create("TextLabel", {
        Parent = Main, Text = title, Font = Enum.Font.GothamBold, TextSize = 12,
        Size = UDim2.new(1, -10, 0, 18), Position = UDim2.new(0, 10, 0, 3),
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = library.theme.Accent
    })
    library:RegisterTheme(TTitle, "TextColor3", "Accent")

    local TText = Create("TextLabel", {
        Parent = Main, Text = text, Font = Enum.Font.Gotham, TextSize = 11,
        Size = UDim2.new(1, -10, 0, 18), Position = UDim2.new(0, 10, 0, 20),
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = library.theme.Text, TextWrapped = true
    })
    library:RegisterTheme(TText, "TextColor3", "Text")

    -- [UX] Time Decay Bar (Slightly Thinner for compact mode)
    local TimerBar = Create("Frame", {
        Parent = Main,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 5,
        BackgroundColor3 = library.theme.Accent
    })
    library:RegisterTheme(TimerBar, "BackgroundColor3", "Accent")
    Create("UICorner", {Parent = TimerBar, CornerRadius = UDim.new(0, 2)})

    -- Animation Sequence
    task.spawn(function()
        TweenService:Create(Container, TweenInfo.new(0.3), {Size = UDim2.new(1,0,0,42)}):Play()
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()

        -- Start Timer Animation
        local totalDuration = duration or 3
        TweenService:Create(TimerBar, TweenInfo.new(totalDuration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

        task.wait(totalDuration)

        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, 0, 0)}):Play()
        task.wait(0.2)

        local close = TweenService:Create(Container, TweenInfo.new(0.2), {Size = UDim2.new(1,0,0,0)})
        close:Play()
        close.Completed:Wait()
        Container:Destroy()
    end)
end

function library:Watermark(headerText)
    if not self.base then return end
    if self.base:FindFirstChild("FSS_Watermark") then self.base.FSS_Watermark:Destroy() end

    local wm = Create("Frame", {
        Name = "FSS_Watermark", Parent = self.base, 
        Size = UDim2.new(0, 0, 0, 26), AnchorPoint = Vector2.new(1, 0), 
        Position = UDim2.new(0.99, 0, 0.01, 0), BorderSizePixel = 0, Visible = true
    })
    library:RegisterTheme(wm, "BackgroundColor3", "Main")
    
    self.wm_obj = wm 
    Create("UICorner", {Parent = wm, CornerRadius = UDim.new(0, 4)})
    local stroke = Create("UIStroke", {Parent = wm, Thickness = 1, Transparency = 0.5})
    library:RegisterTheme(stroke, "Color", "Accent")
    
    local label = Create("TextLabel", {
        Parent = wm, Text = headerText, Font = Enum.Font.Code,
        TextSize = 12, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X
    })
    library:RegisterTheme(label, "TextColor3", "Text")
    
    wm.Size = UDim2.new(0, label.AbsoluteSize.X + 20, 0, 26)
    
    task.spawn(function()
        while wm.Parent do
            local fps = math.floor(1 / math.max(RunService.RenderStepped:Wait(), 0.001))
            local ping = 0; pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString():split(" ")[1]) end)
            label.Text = string.format("%s | FPS: %d | Ping: %dms | %s", headerText, fps, ping, os.date("%H:%M:%S"))

            -- Smooth Resize
            local targetSize = UDim2.new(0, label.AbsoluteSize.X + 20, 0, 26)
            TweenService:Create(wm, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()

            task.wait(1)
        end
    end)
end

function library:ToggleWatermark(state) if self.wm_obj then self.wm_obj.Visible = state end end
function library:SetWatermarkAlign(align)
    if not self.wm_obj then return end
    if align == "Top Left" then self.wm_obj.AnchorPoint = Vector2.new(0, 0); self.wm_obj.Position = UDim2.new(0.01, 0, 0.01, 0)
    elseif align == "Top Right" then self.wm_obj.AnchorPoint = Vector2.new(1, 0); self.wm_obj.Position = UDim2.new(0.99, 0, 0.01, 0)
    elseif align == "Bottom Left" then self.wm_obj.AnchorPoint = Vector2.new(0, 1); self.wm_obj.Position = UDim2.new(0.01, 0, 0.99, 0)
    elseif align == "Bottom Right" then self.wm_obj.AnchorPoint = Vector2.new(1, 1); self.wm_obj.Position = UDim2.new(0.99, 0, 0.99, 0) end
end

local function AddHover(frame)
    frame.MouseEnter:Connect(function() TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.ItemHover}):Play() end)
    frame.MouseLeave:Connect(function() TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.ItemBg}):Play() end)
end

local function CreateRipple(Parent)
    Parent.ClipsDescendants = true

    local Ripple = Instance.new("Frame")
    Ripple.Name = "Ripple"
    Ripple.Parent = Parent
    Ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ripple.BackgroundTransparency = 0.85
    Ripple.ZIndex = 9
    Ripple.BorderSizePixel = 0
    Ripple.AnchorPoint = Vector2.new(0.5, 0.5)

    local MouseLocation = UserInputService:GetMouseLocation()
    local RelativeX = MouseLocation.X - Parent.AbsolutePosition.X
    local RelativeY = MouseLocation.Y - Parent.AbsolutePosition.Y

    Ripple.Position = UDim2.new(0, RelativeX, 0, RelativeY)
    Ripple.Size = UDim2.new(0, 0, 0, 0)

    local Corner = Instance.new("UICorner", Ripple)
    Corner.CornerRadius = UDim.new(1, 0)

    local TargetSize = math.max(Parent.AbsoluteSize.X, Parent.AbsoluteSize.Y) * 2.5

    local Tween = TweenService:Create(Ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, TargetSize, 0, TargetSize),
        BackgroundTransparency = 1
    })

    Tween:Play()
    Tween.Completed:Connect(function()
        Ripple:Destroy()
    end)
end

function library:Init()
    if self.base then return self.base end
    
    local TargetParent = nil
    pcall(function() if gethui then TargetParent = gethui() end end)
    if not TargetParent then pcall(function() TargetParent = game:GetService("CoreGui") end) end
    if not TargetParent then TargetParent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    
    if TargetParent:FindFirstChild("FSSHUB_V10") then TargetParent.FSSHUB_V10:Destroy() end
    
    local gui = Create("ScreenGui", {
        Name = "FSSHUB_V10", Parent = TargetParent, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9999
    })
    
    self.base = gui
    
    if getgenv().FSS_InputConnection then getgenv().FSS_InputConnection:Disconnect(); getgenv().FSS_InputConnection = nil end
    getgenv().FSS_InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode ~= Enum.KeyCode.Unknown then
            if library.keybinds[input.KeyCode] then
                for _, bindCallback in ipairs(library.keybinds[input.KeyCode]) do pcall(bindCallback) end
            end
        end
    end)

    if UserInputService.TouchEnabled then
        local ToggleFrame = Create("Frame", {Parent = gui, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 20, 0.5, -20)})
        library:RegisterTheme(ToggleFrame, "BackgroundColor3", "Main")
        
        Create("UICorner", {Parent = ToggleFrame, CornerRadius = UDim.new(0, 8)})
        local s = Create("UIStroke", {Parent = ToggleFrame, Thickness = 2})
        library:RegisterTheme(s, "Color", "Accent")
        
        local Btn = Create("TextButton", {Parent = ToggleFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "FSS", Font = Enum.Font.GothamBlack})
        library:RegisterTheme(Btn, "TextColor3", "Accent")
        
        Btn.MouseButton1Click:Connect(function() library:Toggle() end)
    end
    
    return gui
end

function library:Toggle()
    if not self.base then return end
    local MainFrame = self.base:FindFirstChild("MainFrame")
    if not MainFrame then return end

    self.open = not self.open

    if self.open then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 550, 0, 350)}):Play()
        -- Restore children transparency if needed, but Visible handles main visibility.
    else
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        tween:Play()
        tween.Completed:Connect(function()
            if not self.open then MainFrame.Visible = false end
        end)
    end
end

function library:Window(title)
    if not self.base then self:Init() end
    
    self.transparencyFrames = {} 
    self.themeRegistry = {}
    
    local MainFrame = Create("Frame", {
        Name = "MainFrame", Parent = self.base, Size = UDim2.new(0, 550, 0, 350), 
        Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
        ClipsDescendants = true -- Prevent content bleeding during open/close animations
    })
    library:RegisterTheme(MainFrame, "BackgroundColor3", "Main")
    table.insert(library.transparencyFrames, MainFrame)
    
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
    local MainStroke = Create("UIStroke", {Parent = MainFrame, Thickness = 1})
    library:RegisterTheme(MainStroke, "Color", "Stroke")

    Create("TextButton", {Parent = MainFrame, BackgroundTransparency = 1, Text = "", Size = UDim2.new(0,0,0,0), Modal = true})

    local Header = Create("Frame", {Parent = MainFrame, Size = UDim2.new(1, 0, 0, 45)})
    library:RegisterTheme(Header, "BackgroundColor3", "Sidebar")
    table.insert(library.transparencyFrames, Header)
    Create("UICorner", {Parent = Header, CornerRadius = UDim.new(0, 8)})
    
    -- [UX] Glassy Gradient for Header
    local H_Grad = Create("UIGradient", {
        Parent = Header,
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9), -- Slight white tint at top
            NumberSequenceKeypoint.new(1, 1)    -- Fully transparent at bottom
        })
    })

    local HeaderLine = Create("Frame", {Parent = Header, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0,0,1,-10), BorderSizePixel=0}) 
    library:RegisterTheme(HeaderLine, "BackgroundColor3", "Sidebar")
    table.insert(library.transparencyFrames, HeaderLine)
    
    local Title = Create("TextLabel", {
        Parent = Header, Text = title, Font = Enum.Font.GothamBold,
        TextSize = 18, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
    })
    library:RegisterTheme(Title, "TextColor3", "Accent")
    
    local Sep = Create("Frame", {Parent = MainFrame, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0,0,0,45), BorderSizePixel=0})
    library:RegisterTheme(Sep, "BackgroundColor3", "Stroke")

    local Sidebar = Create("ScrollingFrame", {
        Parent = MainFrame, Size = UDim2.new(0, 160, 1, -46),
        Position = UDim2.new(0, 0, 0, 46), BorderSizePixel = 0, ScrollBarThickness = 0
    })
    library:RegisterTheme(Sidebar, "BackgroundColor3", "Sidebar")
    table.insert(library.transparencyFrames, Sidebar)

    -- [UX] Subtle Gradient for Sidebar consistency
    local S_Grad = Create("UIGradient", {
        Parent = Sidebar,
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.95), -- Very subtle tint
            NumberSequenceKeypoint.new(1, 1)
        })
    })
    
    Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0,0)})
    Create("UIListLayout", {Parent = Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

    local Content = Create("Frame", {
        Parent = MainFrame, Size = UDim2.new(1, -160, 1, -46),
        Position = UDim2.new(0, 160, 0, 46), BorderSizePixel = 0, ClipsDescendants = true
    })
    library:RegisterTheme(Content, "BackgroundColor3", "Main")
    table.insert(library.transparencyFrames, Content)
    
    MakeDraggable(Header, MainFrame)
    
    local window = {tabs = {}}
    local firstTab = true

    function window:Section(name, iconId) 
        local Page = Create("ScrollingFrame", {
            Parent = Content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            ScrollBarThickness = 6, ScrollBarImageColor3 = library.theme.Accent, Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.None, 
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })
        library:RegisterTheme(Page, "ScrollBarImageColor3", "Accent")
        
        local List = Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Create("UIPadding", {Parent = Page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
        
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 20)
        end)
        
        local TabBtn = Create("TextButton", {Parent = Sidebar, Text = "", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, AutoButtonColor = false})
        local textOffset = 0
        local IconImg
        if iconId and iconId ~= "" then
            textOffset = 25
            IconImg = Create("ImageLabel", {Parent = TabBtn, Image = "rbxassetid://" .. iconId, BackgroundTransparency = 1, Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 5, 0.5, -9)})
        end
        
        local TabLabel = Create("TextLabel", {
            Parent = TabBtn, Text = name, Font = Enum.Font.GothamMedium,
            TextSize = 13, Size = UDim2.new(1, -textOffset, 1, 0), Position = UDim2.new(0, textOffset + 5, 0, 0),
            BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local Indicator = Create("Frame", {
            Parent = TabBtn, Size = UDim2.new(0, 3, 0, 18),
            Position = UDim2.new(0, -10, 0.5, -9), Visible = false
        })
        library:RegisterTheme(Indicator, "BackgroundColor3", "Accent")
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 2)})

        local tabObj = {page = Page, btn = TabBtn, label = TabLabel, indicator = Indicator, icon = IconImg, active = false}
        table.insert(window.tabs, tabObj)

        local function UpdateTabVisuals()
            for _, t in ipairs(window.tabs) do
                if t.active then
                    t.page.Visible = true; t.indicator.Visible = true
                    t.label.TextColor3 = library.theme.Text
                    if t.icon then t.icon.ImageColor3 = library.theme.Text end
                    t.page.CanvasSize = UDim2.new(0, 0, 0, t.page.UIListLayout.AbsoluteContentSize.Y + 20)

                    -- Slide Up Animation
                    t.page.Position = UDim2.new(0, 0, 0, 20)
                    TweenService:Create(t.page, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()
                else
                    t.page.Visible = false; t.indicator.Visible = false
                    t.label.TextColor3 = library.theme.TextDim
                    if t.icon then t.icon.ImageColor3 = library.theme.TextDim end
                end
            end
        end
        library:RegisterThemeFunc(UpdateTabVisuals)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.tabs) do t.active = false end
            tabObj.active = true
            UpdateTabVisuals()
        end)

        if firstTab then
            tabObj.active = true
            task.delay(0.1, UpdateTabVisuals)
            firstTab = false
        end

        local tab = {}

        function tab:Group(title)
            local group = {}
            local expanded = true
            
            local HeaderFrame = Create("Frame", {Parent = Page, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1})
            local HeaderBtn = Create("TextButton", {Parent = HeaderFrame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false})
            
            local Title = Create("TextLabel", {Parent = HeaderBtn, Text = title, Font = Enum.Font.GothamBold, TextSize = 12, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            library:RegisterTheme(Title, "TextColor3", "Accent")
            
            local Arrow = Create("TextLabel", {Parent = HeaderBtn, Text = "v", Font = Enum.Font.GothamBold, TextSize = 12, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -25, 0, 0), BackgroundTransparency = 1})
            library:RegisterTheme(Arrow, "TextColor3", "TextDim")
            
            local Container = Create("Frame", {Parent = Page, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true})
            local GList = Create("UIListLayout", {Parent = Container, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
            Create("UIPadding", {Parent = Container, PaddingLeft = UDim.new(0, 10)})
            
            GList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if expanded then Container.Size = UDim2.new(1, 0, 0, GList.AbsoluteContentSize.Y + 5) end
            end)
            
            HeaderBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                Arrow.Text = expanded and "v" or ">"
                local targetH = expanded and (GList.AbsoluteContentSize.Y + 5) or 0
                TweenService:Create(Container, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetH)}):Play()
            end)
            
            function group:Toggle(t, d, c) return tab:Toggle(t, d, c, Container) end
            function group:Button(t, c) return tab:Button(t, c, Container) end
            function group:Slider(t, min, max, d, c) return tab:Slider(t, min, max, d, c, Container) end
            function group:Dropdown(t, o, d, c) return tab:Dropdown(t, o, d, c, Container) end
            function group:Label(t) return tab:Label(t, Container) end
            function group:Keybind(t, d, c) return tab:Keybind(t, d, c, Container) end
            function group:TextBox(t, d, c) return tab:TextBox(t, d, c, Container) end
            
            return group
        end
        
        -- [NEW FEATURE] TEXTBOX ELEMENT
        function tab:TextBox(text, default, callback, parent)
            local target = parent or Page
            local value = default or ""
            if library.flags[text] ~= nil then value = library.flags[text] end
            
            local Frame = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 38)})
            library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg")
            AddHover(Frame)
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            
            local T = Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextSize = 13, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            library:RegisterTheme(T, "TextColor3", "Text")
            
            local InputBg = Create("Frame", {Parent = Frame, Size = UDim2.new(0, 100, 0, 24), Position = UDim2.new(1, -110, 0.5, -12), BackgroundColor3 = library.theme.Main})
            library:RegisterTheme(InputBg, "BackgroundColor3", "Main")
            Create("UICorner", {Parent = InputBg, CornerRadius = UDim.new(0, 4)})
            
            local Input = Create("TextBox", {Parent = InputBg, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = value, Font = Enum.Font.Code, TextSize = 12, ClearTextOnFocus = false})
            library:RegisterTheme(Input, "TextColor3", "TextDim")
            
            Input.FocusLost:Connect(function(enter)
                value = Input.Text
                library.flags[text] = value
                if callback then pcall(function() callback(value) end) end
            end)
            
            return { Set = function(v) Input.Text = v; value = v; library.flags[text] = v end }
        end
        
        function tab:Label(text, parent)
            local target = parent or Page
            local Frame = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 30)})
            library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg")
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            local T = Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextSize = 13, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            library:RegisterTheme(T, "TextColor3", "Text")
            return T
        end

        function tab:Paragraph(title, content)
            local Frame = Create("Frame", {Parent = Page, Size = UDim2.new(1, 0, 0, 60)})
            library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg")
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            local T = Create("TextLabel", {Parent = Frame, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            library:RegisterTheme(T, "TextColor3", "Accent")
            local C = Create("TextLabel", {Parent = Frame, Text = content, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 25), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
            library:RegisterTheme(C, "TextColor3", "Text")
        end

        function tab:Toggle(text, default, callback, parent)
            local target = parent or Page
            local toggled = default or false
            if library.flags[text] ~= nil then toggled = library.flags[text] end
            
            local Frame = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 38)})
            library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg")
            AddHover(Frame)
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            
            local T = Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextSize = 13, Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            library:RegisterTheme(T, "TextColor3", "Text")
            
            local CheckBox = Create("Frame", {Parent = Frame, Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -50, 0.5, -11)})
            Create("UICorner", {Parent = CheckBox, CornerRadius = UDim.new(1, 0)})
            local Circle = Create("Frame", {Parent = CheckBox, Size = UDim2.new(0, 18, 0, 18)})
            library:RegisterTheme(Circle, "BackgroundColor3", "Text")
            Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1, 0)})
            
            local Btn = Create("TextButton", {Parent = Frame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5})
            
            local function UpdateVisuals()
                local targetColor = toggled and library.theme.Accent or Color3.fromRGB(50,50,55)
                local targetPos = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                TweenService:Create(CheckBox, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
                TweenService:Create(Circle, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
            end
            library:RegisterThemeFunc(UpdateVisuals)

            local firstSet = true
            local function SetState(val)
                toggled = val
                library.flags[text] = val
                UpdateVisuals()

                -- State Change Notification
                if not firstSet then
                     local status = val and "Enabled" or "Disabled"
                     library:Notify(text, "Feature has been " .. status, 2)
                end
                firstSet = false

                pcall(function() callback(toggled) end)
            end
            Btn.MouseButton1Click:Connect(function()
                CreateRipple(Frame)
                SetState(not toggled)
            end)
            if library.flags[text] ~= nil then SetState(library.flags[text]) elseif default then SetState(true) else library.flags[text] = false end
            
            local BindBtn = Create("TextButton", {Parent = Frame, Text = "NONE", Font = Enum.Font.Code, TextSize = 10, Size = UDim2.new(0, 35, 0, 18), Position = UDim2.new(1, -95, 0.5, -9), BackgroundColor3 = library.theme.Main, ZIndex = 10})
            library:RegisterTheme(BindBtn, "TextColor3", "TextDim"); library:RegisterTheme(BindBtn, "BackgroundColor3", "Main")
            Create("UICorner", {Parent = BindBtn, CornerRadius = UDim.new(0, 4)})
            
            local bindFlag = text .. "_Bind"
            local function SetBind(key) 
                boundKey = key; BindBtn.Text = key.Name; library.flags[bindFlag] = key.Name 
                UpdateKeybind(library.keybinds, nil, key, function() SetState(not toggled) end) 
            end
            if library.flags[bindFlag] then local s,k = pcall(function() return Enum.KeyCode[library.flags[bindFlag]] end); if s and k then SetBind(k) end end
            BindBtn.MouseButton1Click:Connect(function() local c; c = UserInputService.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Keyboard then c:Disconnect(); SetBind(i.KeyCode) end end) end)
            
            return { Set = SetState }
        end

        function tab:Button(text, callback, parent)
            local target = parent or Page
            local Frame = Create("TextButton", {Parent = target, Size = UDim2.new(1, 0, 0, 34), Text = text, Font = Enum.Font.Gotham, TextSize = 13, AutoButtonColor = false})
            library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg")
            library:RegisterTheme(Frame, "TextColor3", "Text")
            AddHover(Frame)
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Frame.MouseButton1Click:Connect(function() 
                CreateRipple(Frame)
                TweenService:Create(Frame, TweenInfo.new(0.1), {BackgroundColor3 = library.theme.Accent}):Play()
                task.wait(0.1)
                TweenService:Create(Frame, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.ItemHover}):Play()
                pcall(callback) 
            end)
            return { SetKeybind = function() end }
        end
        
        function tab:Slider(text, min, max, default, callback, parent)
            local target = parent or Page
            local val = default or min
            if library.flags[text] ~= nil then val = library.flags[text] end
            library.flags[text] = val
            
            local Frame = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 48)})
            library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg")
            AddHover(Frame)
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            local T = Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextSize = 13, Position = UDim2.new(0, 12, 0, 10), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            library:RegisterTheme(T, "TextColor3", "Text")
            local ValLbl = Create("TextLabel", {Parent = Frame, Text = tostring(val), Font = Enum.Font.Code, TextSize = 12, Position = UDim2.new(1, -50, 0, 10), Size = UDim2.new(0, 40, 0, 15), BackgroundTransparency = 1})
            library:RegisterTheme(ValLbl, "TextColor3", "TextDim")
            
            local BarBg = Create("Frame", {Parent = Frame, BackgroundColor3 = Color3.fromRGB(20,20,25), Size = UDim2.new(1, -24, 0, 4), Position = UDim2.new(0, 12, 0, 34)})
            Create("UICorner", {Parent = BarBg, CornerRadius = UDim.new(1, 0)})
            local Fill = Create("Frame", {Parent = BarBg, Size = UDim2.new(0, 0, 1, 0)})
            library:RegisterTheme(Fill, "BackgroundColor3", "Accent")
            Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
            
            local Dot = Create("Frame", {Parent = BarBg, Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 1})
            library:RegisterTheme(Dot, "BackgroundColor3", "Text")
            Create("UICorner", {Parent = Dot, CornerRadius = UDim.new(1, 0)})
            
            local Trigger = Create("TextButton", {Parent = Frame, Size = UDim2.new(1, -24, 0, 24), Position = UDim2.new(0, 12, 0, 24), BackgroundTransparency = 1, Text = ""})
            
            Trigger.MouseEnter:Connect(function()
                TweenService:Create(Dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2.new(0, 14, 0, 14)}):Play()
            end)
            Trigger.MouseLeave:Connect(function()
                TweenService:Create(Dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2.new(0, 10, 0, 10)}):Play()
            end)
            
            local function Update(v)
                val = math.clamp(v, min, max); library.flags[text] = val
                local pct = (val - min) / (max - min)
                TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                TweenService:Create(Dot, TweenInfo.new(0.1), {Position = UDim2.new(pct, 0, 0.5, 0)}):Play()
                ValLbl.Text = tostring(val)
                pcall(function() callback(val) end)
            end
            Update(val)
            
            local dragging
            Trigger.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; Dot.BackgroundTransparency=0; local p = math.clamp((i.Position.X - BarBg.AbsolutePosition.X)/BarBg.AbsoluteSize.X, 0, 1); Update(math.floor(min + ((max-min)*p))) end end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false; Dot.BackgroundTransparency=1 end end)
            UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local p = math.clamp((i.Position.X - BarBg.AbsolutePosition.X)/BarBg.AbsoluteSize.X, 0, 1); Update(math.floor(min + ((max-min)*p))) end end)
            return { Set = Update }
        end

        -- [UPDATED] Dropdown with Refresh & Verbose Logic
        function tab:Dropdown(text, options, default, callback, parent)
             local target = parent or Page
             local isDropped = false; if library.flags[text] ~= nil then default = library.flags[text] end; library.flags[text] = default
             
             local Frame = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 36), ClipsDescendants = true})
             library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg"); AddHover(Frame); Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
             local Header = Create("Frame", {Parent = Frame, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Name = "Header"})
             local Title = Create("TextLabel", {Parent = Header, Text = text..": "..(default or "None"), Font = Enum.Font.Gotham, TextColor3 = library.theme.Text, TextSize = 13, Size = UDim2.new(1, -30, 0, 36), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
             library:RegisterTheme(Title, "TextColor3", "Text")
             local Icon = Create("TextLabel", {Parent = Header, Text = "v", Font = Enum.Font.GothamBold, TextColor3 = library.theme.TextDim, TextSize = 12, Size = UDim2.new(0, 30, 0, 36), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1})
             library:RegisterTheme(Icon, "TextColor3", "TextDim")
             local Btn = Create("TextButton", {Parent = Header, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = ""})
             local OptionContainer = Create("Frame", {Parent = Frame, Size = UDim2.new(1, 0, 1, -36), Position = UDim2.new(0, 0, 0, 36), BackgroundTransparency = 1}); Create("UIListLayout", {Parent = OptionContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
             
             local function Set(opt) library.flags[text] = opt; Title.Text = text..": "..opt; pcall(function() callback(opt) end); isDropped = false; TweenService:Create(Frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 36)}):Play(); Icon.Text = "v" end
             
             local function BuildOptions(opts)
                 for _, c in ipairs(OptionContainer:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                 for _, opt in ipairs(opts) do 
                    local B = Create("TextButton", {Parent = OptionContainer, Text = opt, Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(45,45,50), AutoButtonColor = false}); 
                    library:RegisterTheme(B, "TextColor3", "TextDim"); Create("UICorner", {Parent = B, CornerRadius = UDim.new(0, 4)}); 

                    B.MouseEnter:Connect(function()
                        TweenService:Create(B, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.ItemHover, TextColor3 = library.theme.Text}):Play()
                    end)
                    B.MouseLeave:Connect(function()
                        TweenService:Create(B, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45,45,50), TextColor3 = library.theme.TextDim}):Play()
                    end)

                    B.MouseButton1Click:Connect(function() Set(opt) end) 
                 end
             end
             BuildOptions(options)

             Btn.MouseButton1Click:Connect(function() isDropped = not isDropped; local h = isDropped and (36 + (#options * 30) + 10) or 36; TweenService:Create(Frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, h)}):Play(); Icon.Text = isDropped and "^" or "v" end)
             return { Set = Set, Refresh = function(newOpts, newDef) options = newOpts; default = newDef or options[1]; BuildOptions(options); Set(default) end }
        end
        
        function tab:Keybind(text, defaultKey, callback, parent)
             local target = parent or Page
             local Frame = Create("Frame", {Parent = target, Size = UDim2.new(1, 0, 0, 38)})
             library:RegisterTheme(Frame, "BackgroundColor3", "ItemBg"); AddHover(Frame); Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
             local T = Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextSize = 13, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
             library:RegisterTheme(T, "TextColor3", "Text")
             local BindBtn = Create("TextButton", {Parent = Frame, Text = "NONE", Font = Enum.Font.Code, TextSize = 12, Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -90, 0.5, -12), BackgroundColor3 = library.theme.Main})
             library:RegisterTheme(BindBtn, "TextColor3", "TextDim"); library:RegisterTheme(BindBtn, "BackgroundColor3", "Main"); Create("UICorner", {Parent = BindBtn, CornerRadius = UDim.new(0, 4)})
             local bindFlag = text.."_Keybind"; local function SetBind(k) BindBtn.Text = k.Name; library.flags[bindFlag] = k.Name; UpdateKeybind(library.keybinds, nil, k, callback) end
             if defaultKey then UpdateKeybind(library.keybinds, nil, defaultKey, callback) end; if library.flags[bindFlag] then local s,k=pcall(function() return Enum.KeyCode[library.flags[bindFlag]] end); if s and k then SetBind(k) end end
             BindBtn.MouseButton1Click:Connect(function() local c; c=UserInputService.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Keyboard then c:Disconnect(); SetBind(i.KeyCode) end end) end)
             return { SetKeybind = SetBind }
        end

        return tab
    end
    return window
end

return library
