-- [[ FSSHUB LIBRARY: V9 (CLEAN & STRUCTURED) ]] --
-- Fokus: Kerapian (Alignment), Native Notification, & User Experience

local library = {
    flags = {}, 
    windows = {}, 
    open = true
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- [[ THEME: CLEAN DARK ]] --
library.theme = {
    Main        = Color3.fromRGB(25, 25, 30),       -- Background Utama
    Sidebar     = Color3.fromRGB(20, 20, 25),       -- Sidebar Kiri
    Content     = Color3.fromRGB(30, 30, 35),       -- Tempat Fitur
    Accent      = Color3.fromRGB(140, 80, 255),     -- Ungu FSSHUB
    Text        = Color3.fromRGB(240, 240, 240),    -- Putih Terang
    TextDim     = Color3.fromRGB(150, 150, 150),    -- Abu-abu (Inactive)
    Stroke      = Color3.fromRGB(45, 45, 50),       -- Garis Halus
    ItemBg      = Color3.fromRGB(35, 35, 40)        -- Background Tombol/Toggle
}

-- [[ HELPER FUNCTIONS ]] --
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

-- [[ 1. NOTIFIKASI: NATIVE ROBLOX (SESUAI REQUEST) ]] --
function library:Notify(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3,
            -- Icon = "rbxassetid://..." (Opsional: Masukkan ID logomu jika mau)
        })
    end)
end

-- [[ DATA STRUCTURE (COMPATIBILITY MODE) ]] --
-- Tidak perlu ubah script game, API tetap sama
function library:Window(title)
    local windowData = {title = title, tabs = {}}
    
    function windowData:Section(name)
        local tabData = {name = name, elements = {}}
        
        function tabData:Toggle(text, default, callback)
            table.insert(tabData.elements, {type = "Toggle", text = text, default = default, callback = callback})
        end
        function tabData:Button(text, callback)
            table.insert(tabData.elements, {type = "Button", text = text, callback = callback})
        end
        function tabData:Slider(text, min, max, default, callback)
            table.insert(tabData.elements, {type = "Slider", text = text, min = min, max = max, default = default, callback = callback})
        end
        function tabData:Dropdown(text, options, default, callback)
            table.insert(tabData.elements, {type = "Dropdown", text = text, options = options, default = default, callback = callback})
        end
        
        table.insert(windowData.tabs, tabData)
        return tabData
    end
    
    table.insert(library.windows, windowData)
    return windowData
end

-- [[ RENDERER: V9 CLEAN DESIGN ]] --
function library:Init()
    -- 1. Setup ScreenGui
    local success, _ = pcall(function()
        if gethui then self.base = gethui()
        elseif game:GetService("CoreGui") then self.base = game:GetService("CoreGui")
        else self.base = Players.LocalPlayer:WaitForChild("PlayerGui") end
    end)
    if not success or not self.base then self.base = Players.LocalPlayer:WaitForChild("PlayerGui") end

    if self.base:FindFirstChild("FSSHUB_V9") then self.base.FSSHUB_V9:Destroy() end
    
    local gui = Create("ScreenGui", {Name = "FSSHUB_V9", Parent = self.base, ResetOnSpawn = false, IgnoreGuiInset = true})
    self.base = gui

    -- 2. Render Setiap Window
    for _, winData in ipairs(library.windows) do
        
        -- MAIN CONTAINER (Lebih Rapi)
        local MainFrame = Create("Frame", {
            Parent = gui, BackgroundColor3 = library.theme.Main, Size = UDim2.new(0, 500, 0, 320),
            Position = UDim2.new(0.5, -250, 0.5, -160), BorderSizePixel = 0
        })
        Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 8)})
        Create("UIStroke", {Parent = MainFrame, Color = library.theme.Stroke, Thickness = 1}) -- Outline Halus

        -- HEADER (Judul)
        local Header = Create("Frame", {
            Parent = MainFrame, BackgroundColor3 = library.theme.Sidebar, Size = UDim2.new(1, 0, 0, 40), BorderSizePixel = 0
        })
        Create("UICorner", {Parent = Header, CornerRadius = UDim.new(0, 8)})
        -- Tutup corner bawah header agar rata
        Create("Frame", {Parent = Header, BackgroundColor3 = library.theme.Sidebar, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0,0,1,-10), BorderSizePixel=0})
        
        Create("TextLabel", {
            Parent = Header, Text = winData.title, Font = Enum.Font.GothamBold, TextColor3 = library.theme.Accent,
            TextSize = 16, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 15, 0, 0), 
            BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
        })
        
        -- Garis Pemisah Header
        Create("Frame", {Parent = MainFrame, BackgroundColor3 = library.theme.Stroke, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0,0,0,40), BorderSizePixel=0})

        -- SIDEBAR (Kiri)
        local Sidebar = Create("ScrollingFrame", {
            Parent = MainFrame, BackgroundColor3 = library.theme.Sidebar, Size = UDim2.new(0, 130, 1, -41),
            Position = UDim2.new(0, 0, 0, 41), BorderSizePixel = 0, ScrollBarThickness = 0
        })
        Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0, 0)}) -- Kotak saja
        Create("UIListLayout", {Parent = Sidebar, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
        Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})

        -- CONTENT AREA (Kanan)
        local Content = Create("Frame", {
            Parent = MainFrame, BackgroundColor3 = library.theme.Main, Size = UDim2.new(1, -130, 1, -41),
            Position = UDim2.new(0, 130, 0, 41), BorderSizePixel = 0, ClipsDescendants = true
        })
        -- Rounded Corner untuk Content Area (Optional aesthetic)
        local ContentCornerFix = Create("Frame", {Parent = MainFrame, BackgroundColor3 = library.theme.Main, Size = UDim2.new(0, 20, 1, -41), Position = UDim2.new(0, 130, 0, 41), BorderSizePixel=0})

        MakeDraggable(Header, MainFrame)
        
        -- LOGIC TAB & ELEMEN
        local firstTab = true
        local tabsUI = {} 
        
        for _, tabData in ipairs(winData.tabs) do
            -- 1. Buat Container Tab (Halaman)
            local Page = Create("ScrollingFrame", {
                Parent = Content, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                ScrollBarThickness = 2, ScrollBarImageColor3 = library.theme.Accent, Visible = false
            })
            Create("UIListLayout", {Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)})
            Create("UIPadding", {Parent = Page, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10)})
            
            -- 2. Buat Tombol Tab di Sidebar
            local TabBtn = Create("TextButton", {
                Parent = Sidebar, Text = tabData.name, Font = Enum.Font.GothamMedium, TextColor3 = library.theme.TextDim,
                TextSize = 13, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, AutoButtonColor = false
            })
            -- Indikator Aktif (Garis kecil di kiri tombol tab)
            local Indicator = Create("Frame", {
                Parent = TabBtn, BackgroundColor3 = library.theme.Accent, Size = UDim2.new(0, 2, 0, 16),
                Position = UDim2.new(0, -5, 0.5, -8), Visible = false
            })

            table.insert(tabsUI, {page = Page, btn = TabBtn, indicator = Indicator})

            TabBtn.MouseButton1Click:Connect(function()
                for _, t in ipairs(tabsUI) do
                    t.page.Visible = false
                    t.indicator.Visible = false
                    TweenService:Create(t.btn, TweenInfo.new(0.2), {TextColor3 = library.theme.TextDim}):Play()
                end
                Page.Visible = true
                Indicator.Visible = true
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3 = library.theme.Text}):Play()
            end)

            if firstTab then
                Page.Visible = true; Indicator.Visible = true; TabBtn.TextColor3 = library.theme.Text
                firstTab = false
            end

            -- 3. Render Elemen di Dalam Tab
            for _, el in ipairs(tabData.elements) do
                
                -- [[ TOGGLE ]] --
                if el.type == "Toggle" then
                    local toggled = el.default or false
                    local Frame = Create("Frame", {
                        Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 36)
                    })
                    Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
                    
                    Create("TextLabel", {
                        Parent = Frame, Text = el.text, Font = Enum.Font.Gotham, TextColor3 = library.theme.Text,
                        TextSize = 13, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0),
                        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    
                    local CheckBox = Create("Frame", {
                        Parent = Frame, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0.5, -10),
                        BackgroundColor3 = toggled and library.theme.Accent or Color3.fromRGB(50,50,55)
                    })
                    Create("UICorner", {Parent = CheckBox, CornerRadius = UDim.new(0, 4)})
                    
                    local Btn = Create("TextButton", {Parent = Frame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""})
                    
                    Btn.MouseButton1Click:Connect(function()
                        toggled = not toggled
                        TweenService:Create(CheckBox, TweenInfo.new(0.2), {BackgroundColor3 = toggled and library.theme.Accent or Color3.fromRGB(50,50,55)}):Play()
                        el.callback(toggled)
                    end)
                    if el.default then el.callback(true) end

                -- [[ BUTTON ]] --
                elseif el.type == "Button" then
                    local Frame = Create("TextButton", {
                        Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 32),
                        Text = el.text, Font = Enum.Font.Gotham, TextColor3 = library.theme.Text, TextSize = 13,
                        AutoButtonColor = false
                    })
                    Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
                    
                    Frame.MouseButton1Click:Connect(function()
                        TweenService:Create(Frame, TweenInfo.new(0.1), {BackgroundColor3 = library.theme.Accent}):Play()
                        task.wait(0.1)
                        TweenService:Create(Frame, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.ItemBg}):Play()
                        el.callback()
                    end)

                -- [[ SLIDER ]] --
                elseif el.type == "Slider" then
                    local val = el.default or el.min
                    local Frame = Create("Frame", {
                        Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 46)
                    })
                    Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
                    
                    Create("TextLabel", {
                        Parent = Frame, Text = el.text, Font = Enum.Font.Gotham, TextColor3 = library.theme.Text,
                        TextSize = 13, Position = UDim2.new(0, 10, 0, 8), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    
                    local ValLbl = Create("TextLabel", {
                        Parent = Frame, Text = tostring(val), Font = Enum.Font.Code, TextColor3 = library.theme.TextDim,
                        TextSize = 12, Position = UDim2.new(1, -40, 0, 8), Size = UDim2.new(0, 30, 0, 15), BackgroundTransparency = 1
                    })
                    
                    local BarBg = Create("Frame", {
                        Parent = Frame, BackgroundColor3 = Color3.fromRGB(20,20,25), Size = UDim2.new(1, -20, 0, 4),
                        Position = UDim2.new(0, 10, 0, 32)
                    })
                    Create("UICorner", {Parent = BarBg, CornerRadius = UDim.new(1, 0)})
                    
                    local Fill = Create("Frame", {
                        Parent = BarBg, BackgroundColor3 = library.theme.Accent, Size = UDim2.new((val - el.min)/(el.max - el.min), 0, 1, 0)
                    })
                    Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})
                    
                    local Trigger = Create("TextButton", {Parent = BarBg, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = ""})
                    
                    local function update(input)
                        local pos = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
                        TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)}):Play()
                        local newVal = math.floor(el.min + ((el.max - el.min) * pos))
                        ValLbl.Text = tostring(newVal)
                        el.callback(newVal)
                    end
                    
                    local dragging = false
                    Trigger.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=true; update(i) end end)
                    Trigger.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging=false end end)
                    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)

                -- [[ DROPDOWN (Clean) ]] --
                elseif el.type == "Dropdown" then
                    local isDropped = false
                    local Frame = Create("Frame", {
                        Parent = Page, BackgroundColor3 = library.theme.ItemBg, Size = UDim2.new(1, 0, 0, 36), ClipsDescendants = true
                    })
                    Create("UICorner", {Parent = Frame, CornerRadius = UDim.new(0, 6)})
                    
                    local Title = Create("TextLabel", {
                        Parent = Frame, Text = el.text .. ": " .. (el.default or "..."), Font = Enum.Font.Gotham, 
                        TextColor3 = library.theme.Text, TextSize = 13, Size = UDim2.new(1, -30, 0, 36), 
                        Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
                    })
                    
                    local Icon = Create("TextLabel", {
                        Parent = Frame, Text = "v", Font = Enum.Font.GothamBold, TextColor3 = library.theme.TextDim,
                        TextSize = 12, Size = UDim2.new(0, 30, 0, 36), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1
                    })
                    
                    local Btn = Create("TextButton", {Parent = Frame, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Text = ""})
                    Create("UIListLayout", {Parent = Frame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
                    -- Spacer agar list tidak menimpa header dropdown
                    Create("Frame", {Parent = Frame, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1, LayoutOrder = -1})
                    
                    Btn.MouseButton1Click:Connect(function()
                        isDropped = not isDropped
                        local height = isDropped and (36 + (#el.options * 30) + 5) or 36
                        TweenService:Create(Frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, height)}):Play()
                        Icon.Text = isDropped and "^" or "v"
                    end)
                    
                    for _, opt in ipairs(el.options) do
                        local OptBtn = Create("TextButton", {
                            Parent = Frame, Text = opt, Font = Enum.Font.Gotham, TextColor3 = library.theme.TextDim,
                            TextSize = 12, Size = UDim2.new(1, -10, 0, 28), BackgroundColor3 = Color3.fromRGB(45,45,50),
                            AutoButtonColor = false
                        })
                        Create("UICorner", {Parent = OptBtn, CornerRadius = UDim.new(0, 4)})
                        OptBtn.MouseButton1Click:Connect(function()
                            isDropped = false
                            Title.Text = el.text .. ": " .. opt
                            el.callback(opt)
                            TweenService:Create(Frame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 36)}):Play()
                            Icon.Text = "v"
                        end)
                    end
                end
            end
        end
    end
    
    -- Mobile Toggle Button
    if UserInputService.TouchEnabled then
        local ToggleFrame = Create("Frame", {
            Parent = gui, BackgroundColor3 = library.theme.Main, Size = UDim2.new(0, 40, 0, 40),
            Position = UDim2.new(0, 20, 0.5, -20)
        })
        Create("UICorner", {Parent = ToggleFrame, CornerRadius = UDim.new(0, 8)})
        Create("UIStroke", {Parent = ToggleFrame, Color = library.theme.Accent, Thickness = 2})
        local Btn = Create("TextButton", {Parent = ToggleFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "FSS", TextColor3 = library.theme.Accent, Font = Enum.Font.GothamBlack})
        Btn.MouseButton1Click:Connect(function() 
            gui.FSSHUB_V9.Frame.Visible = not gui.FSSHUB_V9.Frame.Visible 
        end)
    end
end

return library
