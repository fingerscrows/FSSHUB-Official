-- [[ FSSHUB LIBRARY: V11.0 (VISUAL BINDER UPDATE) ]] --
-- Fix: Visual Keybind pada Toggle & Perbaikan Input Handling

local library = {
    flags = {}, 
    windows = {}, 
    open = true,
    keybinds = {} 
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- [[ THEME ]] --
library.theme = {
    Main        = Color3.fromRGB(20, 20, 25),
    Sidebar     = Color3.fromRGB(15, 15, 20),
    Content     = Color3.fromRGB(25, 25, 30),
    Accent      = Color3.fromRGB(140, 80, 255),
    Text        = Color3.fromRGB(240, 240, 240),
    TextDim     = Color3.fromRGB(150, 150, 150),
    Stroke      = Color3.fromRGB(50, 50, 60),
    ItemBg      = Color3.fromRGB(30, 30, 35)
}

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
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
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 3})
    end)
end

-- [[ UPDATE BAGIAN WATERMARK DI FSSHUB_LIB.LUA ]] --

function library:Watermark(text)
    if not self.base then return end
    if self.base:FindFirstChild("FSS_Watermark") then self.base.FSS_Watermark:Destroy() end

    local wm = Create("Frame", {
        Name = "FSS_Watermark",
        Parent = self.base, 
        BackgroundColor3 = library.theme.Main, 
        Size = UDim2.new(0, 0, 0, 26), 
        -- Ubah Posisi ke Kanan Atas (Right Top)
        AnchorPoint = Vector2.new(1, 0), 
        Position = UDim2.new(0.99, 0, 0.01, 0), 
        BorderSizePixel = 0,
        Visible = true -- Default visible
    })
    
    Create("UICorner", {Parent = wm, CornerRadius = UDim.new(0, 4)})
    Create("UIStroke", {Parent = wm, Color = library.theme.Accent, Thickness = 1, Transparency = 0.5})
    
    local label = Create("TextLabel", {
        Parent = wm, Text = text, Font = Enum.Font.Code, TextColor3 = library.theme.Text,
        TextSize = 12, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X
    })
    
    -- Initial size update
    wm.Size = UDim2.new(0, label.AbsoluteSize.X + 20, 0, 26)
    
    -- FPS Loop
    task.spawn(function()
        while wm.Parent do
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            label.Text = text .. " | FPS: " .. fps
            wm.Size = UDim2.new(0, label.AbsoluteSize.X + 20, 0, 26)
            task.wait(1)
        end
    end)

    -- Fungsi Helper untuk Toggle Visibility
    function library:ToggleWatermark(state)
        if self.base and self.base:FindFirstChild("FSS_Watermark") then
            self.base.FSS_Watermark.Visible = state
        end
    end
end

function library:Init()
    if self.base then return self.base end
    local success, _ = pcall(function()
        if gethui then self.base = gethui()
        elseif game:GetService("CoreGui") then self.base = game:GetService("CoreGui")
        else self.base = Players.LocalPlayer:WaitForChild("PlayerGui") end
    end)
    if not success or not self.base then self.base = Players.LocalPlayer:WaitForChild("PlayerGui") end
    
    if self.base:FindFirstChild("FSSHUB_V10") then self.base.FSSHUB_V10:Destroy() end
    local gui = Create("ScreenGui", {Name = "FSSHUB_V10", Parent = self.base, ResetOnSpawn = false, IgnoreGuiInset = true})
    self.base = gui
    
    -- Global Input Handler
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode ~= Enum.KeyCode.Unknown and library.keybinds[input.KeyCode] then
            for _, bind in ipairs(library.keybinds[input.KeyCode]) do
                pcall(bind)
            end
        end
    end)

    -- Mobile Toggle
    if UserInputService.TouchEnabled then
        local ToggleFrame = Create("Frame", {
            Parent = gui, BackgroundColor3 = library.theme.Main, Size = UDim2.new(0, 40, 0, 40),
            Position = UDim2.new(0, 20, 0.5, -20)
        })
        Create("UICorner", {Parent = ToggleFrame, CornerRadius = UDim.new(0, 8)})
        Create("UIStroke", {Parent = ToggleFrame, Color = library.theme.Accent, Thickness = 2})
        local Btn = Create("TextButton", {Parent = ToggleFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "FSS", TextColor3 = library.theme.Accent, Font = Enum.Font.GothamBlack})
        Btn.MouseButton1Click:Connect(function() 
            if gui:FindFirstChild("MainFrame") then
                gui.MainFrame.Visible = not gui.MainFrame.Visible
            end
        end)
    end
    return gui
end

function library:Window(title)
    if not self.base then self:Init() end
    
    local MainFrame = Create("Frame", {
        Name = "MainFrame", Parent = self.base, BackgroundColor3 = library.theme.Main, Size = UDim2.new(0, 550, 0, 350), 
        Position = UDim2.new(0.5, -275, 0.5, -175), BorderSizePixel = 0
    })
    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = MainFrame, Color = library.theme.Stroke, Thickness = 1})

    local Header = Create("Frame", {Parent = MainFrame, BackgroundColor3 = library.theme.Sidebar, Size = UDim2.new(1, 0, 0, 45)})
    Create("UICorner", {Parent = Header, CornerRadius = UDim.new(0, 8)})
    Create("Frame", {Parent = Header, BackgroundColor3 = library.theme.Sidebar, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0,0,1,-10), BorderSizePixel=0}) 
    
    Create("TextLabel", {
        Parent = Header, Text = title, Font = Enum.Font.GothamBold, TextColor3 = library.theme.Accent,
        TextSize = 18, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
    })
    Create("Frame", {Parent = MainFrame, BackgroundColor3 = library.theme.Stroke, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0,0,0,45), BorderSizePixel=0})

    local Sidebar = Create("ScrollingFrame", {
        Parent = MainFrame, BackgroundColor3 = library.theme.Sidebar, Size = UDim2.new(0, 160, 1, -46),
        Position = UDim2.new(0, 0, 0, 46), BorderSizePixel = 0, ScrollBarThickness = 0
    })
    Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0,0)})
    Create("UIListLayout", {Parent = Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
    Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

    local Content = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = library.theme.Main, Size = UDim2.new(1, -160, 1, -46),
        Position = UDim2.new(0, 160, 0, 46), BorderSizePixel = 0, ClipsDescendants = true
    })
    
    MakeDraggable(Header, MainFrame)
    
    local window = {tabs = {}}
    local firstTab = true

    function window:Section(name, iconId) 
        local Page = Create("ScrollingFrame", {
            Parent = Content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            ScrollBarThickness = 2, ScrollBarImageColor3 = library.theme.Accent, Visible = false
        })
        Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
        Create("UIPadding", {Parent = Page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
        
        local TabBtn = Create("TextButton", {
            Parent = Sidebar, Text = "", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, AutoButtonColor = false
        })
        
        local textOffset = 0
        local IconImg
        if iconId then
            textOffset = 25
            IconImg = Create("ImageLabel", {
                Parent = TabBtn, Image = "rbxassetid://" .. iconId, BackgroundTransparency = 1,
                Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, 5, 0.5, -9), ImageColor3 = library.theme.TextDim
            })
        end
        
        local TabLabel = Create("TextLabel", {
            Parent = TabBtn, Text = name, Font = Enum.Font.GothamMedium, TextColor3 = library.theme.TextDim,
            TextSize = 13, Size = UDim2.new(1, -textOffset, 1, 0), Position = UDim2.new(0, textOffset + 5, 0, 0),
            BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local Indicator = Create("Frame", {
            Parent = TabBtn, BackgroundColor3 = library.theme.Accent, Size = UDim2.new(0, 3, 0, 18),
            Position = UDim2.new(0, -10, 0.5, -9), Visible = false
        })
        Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(0, 2)})

        local tabObj = {page = Page, btn = TabBtn, label = TabLabel, indicator = Indicator, icon = IconImg}
        table.insert(window.tabs, tabObj)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.tabs) do
                t.page.Visible = false
                t.indicator.Visible = false
                TweenService:Create(t.label, TweenInfo.new(0.2), {TextColor3 = library.theme.TextDim}):Play()
                if t.icon then TweenService:Create(t.icon, TweenInfo.new(0.2), {ImageColor3 = library.theme.TextDim}):Play() end
            end
            Page.Visible = true
            Indicator.Visible = true
            TweenService:Create(TabLabel, TweenInfo.new(0.2), {TextColor3 = library.theme.Text}):Play()
            if tabObj.icon then TweenService:Create(tabObj.icon, TweenInfo.new(0.2), {ImageColor3 = library.theme.Text}):Play() end
        end)

        if firstTab then
            Page.Visible = true; Indicator.Visible = true; TabLabel.TextColor3 = library.theme.Text
            if tabObj.icon then tabObj.icon.ImageColor3 = library.theme.Text end
            firstTab = false
        end

        local tab = {}
        
        function tab:Label(text)
            local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 30)})
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            local Lbl = Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.GothamBold, TextColor3 = library.theme.Text, TextSize = 13, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            return Lbl
        end

        function tab:Paragraph(title, text)
            local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y})
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Create("UIPadding", {Parent = Frame, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
            Create("UIListLayout", {Parent = Frame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
            Create("TextLabel", {Parent = Frame, Text = title, Font = Enum.Font.GothamBold, TextColor3 = library.theme.Accent, TextSize = 13, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextColor3 = library.theme.TextDim, TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true})
        end

        -- [UPDATED TOGGLE WITH VISUAL BINDER]
        function tab:Toggle(text, default, callback)
            local toggled = default or false
            local boundKey = nil -- Keybind Variable

            local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 38)})
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextColor3 = library.theme.Text, TextSize = 13, Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            
            -- Checkbox
            local CheckBox = Create("Frame", {Parent = Frame, Size = UDim2.new(0, 42, 0, 22), Position = UDim2.new(1, -50, 0.5, -11), BackgroundColor3 = toggled and library.theme.Accent or Color3.fromRGB(50,50,55)})
            Create("UICorner", {Parent = CheckBox, CornerRadius = UDim.new(1, 0)})
            local Circle = Create("Frame", {Parent = CheckBox, Size = UDim2.new(0, 18, 0, 18), Position = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = library.theme.Text})
            Create("UICorner", {Parent = Circle, CornerRadius = UDim.new(1, 0)})
            
            -- [NEW] Bind Button (Small)
            local BindBtn = Create("TextButton", {
                Parent = Frame, Text = "NONE", Font = Enum.Font.Code, TextColor3 = library.theme.TextDim,
                TextSize = 10, Size = UDim2.new(0, 35, 0, 18), Position = UDim2.new(1, -95, 0.5, -9),
                BackgroundColor3 = library.theme.Main
            })
            Create("UICorner", {Parent = BindBtn, CornerRadius = UDim.new(0, 4)})

            local Btn = Create("TextButton", {Parent = Frame, Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Text = ""})
            
            local function UpdateToggle(val)
                if val ~= nil then toggled = val else toggled = not toggled end
                TweenService:Create(CheckBox, TweenInfo.new(0.2), {BackgroundColor3 = toggled and library.theme.Accent or Color3.fromRGB(50,50,55)}):Play()
                TweenService:Create(Circle, TweenInfo.new(0.2), {Position = toggled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)}):Play()
                callback(toggled)
            end
            
            -- Toggle Logic
            Btn.MouseButton1Click:Connect(function() UpdateToggle() end)
            if default then UpdateToggle(true) end
            
            -- Bind Logic
            local binding = false
            BindBtn.MouseButton1Click:Connect(function()
                binding = true
                BindBtn.Text = "..."
                BindBtn.TextColor3 = library.theme.Accent
            end)

            UserInputService.InputBegan:Connect(function(input)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false
                    boundKey = input.KeyCode
                    BindBtn.Text = boundKey.Name
                    BindBtn.TextColor3 = library.theme.TextDim
                    
                    -- Register Dynamic Bind
                    if not library.keybinds[boundKey] then library.keybinds[boundKey] = {} end
                    table.insert(library.keybinds[boundKey], function() UpdateToggle() end)
                elseif boundKey and input.KeyCode == boundKey and not binding then
                    -- Trigger via Key
                    -- Logic handled by Global Input Handler in Init
                end
            end)
            
            return {
                SetKeybind = function(key)
                    boundKey = key
                    BindBtn.Text = key.Name
                    if not library.keybinds[key] then library.keybinds[key] = {} end
                    table.insert(library.keybinds[key], function() UpdateToggle() end)
                end
            }
        end

        -- Element Lain (Button, Slider, Dropdown, Keybind Standalone) tetap sama
        -- (Silakan pakai kode element lain dari V10.5 sebelumnya jika tidak ada perubahan, 
        -- atau saya bisa kirim full jika diminta)
        
        function tab:Button(text, callback)
            local Frame = Create("TextButton", {Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 34), Text = text, Font = Enum.Font.Gotham, TextColor3 = library.theme.Text, TextSize = 13, AutoButtonColor = false})
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Frame.MouseButton1Click:Connect(function()
                TweenService:Create(Frame, TweenInfo.new(0.1), {BackgroundColor3 = library.theme.Accent}):Play()
                task.wait(0.1)
                TweenService:Create(Frame, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.ItemBg}):Play()
                callback()
            end)
        end

        function tab:Keybind(text, defaultKey, callback)
            local key = defaultKey or Enum.KeyCode.RightControl
            local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 38)})
            Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
            Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextColor3 = library.theme.Text, TextSize = 13, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
            local BindBtn = Create("TextButton", {Parent = Frame, Text = key.Name, Font = Enum.Font.Code, TextColor3 = library.theme.TextDim, TextSize = 12, Size = UDim2.new(0, 80, 0, 24), Position = UDim2.new(1, -90, 0.5, -12), BackgroundColor3 = library.theme.Main})
            Create("UICorner", {Parent = BindBtn, CornerRadius = UDim.new(0, 4)})
            local binding = false
            BindBtn.MouseButton1Click:Connect(function() binding = true; BindBtn.Text = "..."; BindBtn.TextColor3 = library.theme.Accent end)
            UserInputService.InputBegan:Connect(function(input)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false; key = input.KeyCode; BindBtn.Text = key.Name; BindBtn.TextColor3 = library.theme.TextDim
                    if not library.keybinds[key] then library.keybinds[key] = {} end
                    table.insert(library.keybinds[key], callback)
                end
            end)
            if not library.keybinds[key] then library.keybinds[key] = {} end
            table.insert(library.keybinds[key], callback)
        end
        
        function tab:Slider(text, min, max, default, callback)
             local val = default or min
             local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 48)})
             Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
             Create("TextLabel", {Parent = Frame, Text = text, Font = Enum.Font.Gotham, TextColor3 = library.theme.Text, TextSize = 13, Position = UDim2.new(0, 12, 0, 10), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
             local ValLbl = Create("TextLabel", {Parent = Frame, Text = tostring(val), Font = Enum.Font.Code, TextColor3 = library.theme.TextDim, TextSize = 12, Position = UDim2.new(1, -50, 0, 10), Size = UDim2.new(0, 40, 0, 15), BackgroundTransparency = 1})
             local BarBg = Create("Frame", {Parent = Frame, BackgroundColor3 = Color3.fromRGB(20,20,25), Size = UDim2.new(1, -24, 0, 4), Position = UDim2.new(0, 12, 0, 34)})
             Create("UICorner", {Parent = BarBg, CornerRadius = UDim.new(1, 0)})
             local Fill = Create("Frame", {Parent = BarBg, BackgroundColor3 = library.theme.Accent, Size = UDim2.new((val - min)/(max - min), 0, 1, 0)})
             Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
             local Trigger = Create("TextButton", {Parent = BarBg, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""})
             local function update(input)
                 local pos = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
                 TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
                 local newVal = math.floor(min + ((max - min) * pos))
                 ValLbl.Text = tostring(newVal)
                 callback(newVal)
             end
             local dragging = false
             Trigger.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=true; update(i) end end)
             Trigger.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=false end end)
             UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
        end

        function tab:Dropdown(text, options, default, callback)
             local isDropped = false
             local Frame = Create("Frame", {Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 36), ClipsDescendants = true})
             Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
             local Title = Create("TextLabel", {Parent = Frame, Text = text .. ": " .. (default or "..."), Font = Enum.Font.Gotham, TextColor3 = library.theme.Text, TextSize = 13, Size = UDim2.new(1, -30, 0, 36), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
             local Icon = Create("TextLabel", {Parent = Frame, Text = "v", Font = Enum.Font.GothamBold, TextColor3 = library.theme.TextDim, TextSize = 12, Size = UDim2.new(0, 30, 0, 36), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1})
             local Btn = Create("TextButton", {Parent = Frame, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = ""})
             Create("UIListLayout", {Parent = Frame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
             Create("Frame", {Parent = Frame, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, LayoutOrder = -1})
             Btn.MouseButton1Click:Connect(function()
                 isDropped = not isDropped
                 local height = isDropped and (36 + (#options * 30) + 5) or 36
                 TweenService:Create(Frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, height)}):Play()
                 Icon.Text = isDropped and "^" or "v"
             end)
             for _, opt in ipairs(options) do
                 local OptBtn = Create("TextButton", {Parent = Frame, Text = opt, Font = Enum.Font.Gotham, TextColor3 = library.theme.TextDim, TextSize = 12, Size = UDim2.new(1, -10, 0, 28), BackgroundColor3 = Color3.fromRGB(45,45,50), AutoButtonColor = false})
                 Create("UICorner", {Parent = OptBtn, CornerRadius = UDim.new(0, 4)})
                 OptBtn.MouseButton1Click:Connect(function()
                     isDropped = false; Title.Text = text .. ": " .. opt; callback(opt)
                     TweenService:Create(Frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 36)}):Play()
                     Icon.Text = "v"
                 end)
             end
        end

        return tab
    end
    return window
end

return library
