-- [[ FSSHUB LIBRARY: REMASTERED V8.0 ]] --
-- "Cyber-Minimalism Design Language"

local library = {flags = {}, windows = {}, open = true, toClose = false}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- [[ THEME CONFIGURATION ]] --
library.theme = {
    Main = Color3.fromRGB(18, 18, 24),       -- Background Utama (Deep Dark)
    Secondary = Color3.fromRGB(28, 28, 36),  -- Element Background
    Accent = Color3.fromRGB(140, 80, 255),   -- FSSHUB Purple (Primary)
    AccentDark = Color3.fromRGB(100, 50, 200), -- Darker Purple untuk Gradient
    Text = Color3.fromRGB(245, 245, 245),    -- Teks Putih
    TextDim = Color3.fromRGB(160, 160, 170), -- Teks Abu
    Outline = Color3.fromRGB(50, 50, 65),    -- Garis Pinggir
    Glow = Color3.fromRGB(140, 80, 255)      -- Warna Glow
}

-- [[ UTILITY FUNCTIONS ]] --
local function MakeDraggable(topbarobject, object)
	local dragging, dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        -- Gunakan Tween agar drag terasa smooth
		TweenService:Create(object, TweenInfo.new(0.05), {Position = targetPos}):Play()
	end

	topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	topbarobject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

-- [[ NOTIFICATION SYSTEM ]] --
function library:Notify(title, text, duration)
    -- Pastikan container notifikasi ada
    if not self.notifContainer then
        self.notifContainer = Create("Frame", {
            Parent = self.base,
            Size = UDim2.new(0, 300, 1, 0),
            Position = UDim2.new(1, -320, 0, 0), -- Pojok Kanan
            BackgroundTransparency = 1,
            ZIndex = 100
        })
        Create("UIListLayout", {
            Parent = self.notifContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 10)
        })
        Create("UIPadding", {
            Parent = self.notifContainer,
            PaddingBottom = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 10)
        })
    end

    local NotifFrame = Create("Frame", {
        Parent = self.notifContainer,
        Size = UDim2.new(1, 0, 0, 0), -- Mulai dari tinggi 0 untuk animasi
        BackgroundColor3 = library.theme.Secondary,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    
    local Corner = Create("UICorner", {Parent = NotifFrame, CornerRadius = UDim.new(0, 8)})
    local Stroke = Create("UIStroke", {Parent = NotifFrame, Color = library.theme.Accent, Thickness = 1.5, Transparency = 0.5})
    
    local TitleLabel = Create("TextLabel", {
        Parent = NotifFrame,
        Text = title,
        Font = Enum.Font.GothamBlack,
        TextColor3 = library.theme.Accent,
        TextSize = 14,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local DescLabel = Create("TextLabel", {
        Parent = NotifFrame,
        Text = text,
        Font = Enum.Font.Gotham,
        TextColor3 = library.theme.Text,
        TextSize = 12,
        Position = UDim2.new(0, 15, 0, 30),
        Size = UDim2.new(1, -30, 0, 30),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextTransparency = 1 -- Mulai invisible
    })

    -- Animasi Masuk (Expand Height -> Fade In Text)
    TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 70)}):Play()
    task.delay(0.2, function()
        TweenService:Create(DescLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    end)

    -- Animasi Keluar
    task.delay(duration or 4, function()
        TweenService:Create(DescLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        local tweenOut = TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function() NotifFrame:Destroy() end)
    end)
end

-- [[ MAIN WINDOW CREATION ]] --
function library:Window(title)
    local window = {tabs = {}}
    
    -- Main Container (Modern Box)
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = self.base,
        BackgroundColor3 = library.theme.Main,
        Size = UDim2.new(0, 550, 0, 350), -- Sedikit lebih lebar
        Position = UDim2.new(0.5, -275, 0.5, -175),
        BorderSizePixel = 0,
        ClipsDescendants = false -- Biar glow effect kelihatan
    })

    Create("UICorner", {Parent = MainFrame, CornerRadius = UDim.new(0, 10)})
    
    -- Glow Effect (Shadow)
    local Shadow = Create("ImageLabel", {
        Parent = MainFrame,
        Image = "rbxassetid://6015897843", -- Shadow Asset
        ImageColor3 = library.theme.Accent,
        ImageTransparency = 0.6,
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        ZIndex = -1
    })

    -- Sidebar (Kiri)
    local Sidebar = Create("Frame", {
        Parent = MainFrame,
        BackgroundColor3 = library.theme.Secondary,
        Size = UDim2.new(0, 140, 1, 0),
        BorderSizePixel = 0
    })
    Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0, 10)})
    -- Tutup sudut kanan sidebar agar rata dengan konten
    local Filler = Create("Frame", {
        Parent = Sidebar,
        BackgroundColor3 = library.theme.Secondary,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        BorderSizePixel = 0
    })

    -- Title / Logo Area
    local LogoText = Create("TextLabel", {
        Parent = Sidebar,
        Text = "FSS HUB",
        Font = Enum.Font.GothamBlack,
        TextColor3 = library.theme.Accent,
        TextSize = 22,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1
    })

    -- Tab Container
    local TabContainer = Create("ScrollingFrame", {
        Parent = Sidebar,
        Size = UDim2.new(1, 0, 1, -60),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0
    })
    Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    Create("UIPadding", {Parent = TabContainer, PaddingLeft = UDim.new(0, 10)})

    -- Content Area (Kanan)
    local ContentArea = Create("Frame", {
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -150, 1, -20),
        Position = UDim2.new(0, 150, 0, 10),
        ClipsDescendants = true
    })

    -- Drag Logic
    MakeDraggable(Sidebar, MainFrame)
    
    -- Mobile Toggle
    if UserInputService.TouchEnabled then
        local ToggleBtn = Create("ImageButton", {
            Parent = self.base,
            Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(0, 20, 0.5, -25),
            BackgroundColor3 = library.theme.Secondary,
            Image = "rbxassetid://3570695787", -- Ganti logo jika ada
            ImageColor3 = library.theme.Accent
        })
        Create("UICorner", {Parent = ToggleBtn, CornerRadius = UDim.new(1, 0)})
        Create("UIStroke", {Parent = ToggleBtn, Color = library.theme.Accent, Thickness = 2})
        
        ToggleBtn.MouseButton1Click:Connect(function()
            MainFrame.Visible = not MainFrame.Visible
        end)
    end

    -- [[ TAB FUNCTION ]] --
    function window:Section(name) -- Mengganti nama fungsi agar kompatibel dengan script lamamu
        local tab = {active = false}
        local tabContent = Create("ScrollingFrame", {
            Parent = ContentArea,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = library.theme.Accent,
            Visible = false
        })
        Create("UIListLayout", {
            Parent = tabContent,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6)
        })
        Create("UIPadding", {Parent = tabContent, PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 5)})

        -- Tab Button di Sidebar
        local tabBtn = Create("TextButton", {
            Parent = TabContainer,
            Text = name,
            Font = Enum.Font.GothamBold,
            TextColor3 = library.theme.TextDim,
            TextSize = 13,
            Size = UDim2.new(1, -20, 0, 35),
            BackgroundColor3 = library.theme.Main,
            AutoButtonColor = false,
            BackgroundTransparency = 1
        })
        Create("UICorner", {Parent = tabBtn, CornerRadius = UDim.new(0, 6)})
        
        -- Logic Pindah Tab
        tabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(window.tabs) do
                t.content.Visible = false
                TweenService:Create(t.btn, TweenInfo.new(0.3), {TextColor3 = library.theme.TextDim, BackgroundTransparency = 1}):Play()
            end
            tabContent.Visible = true
            TweenService:Create(tabBtn, TweenInfo.new(0.3), {TextColor3 = library.theme.Text, BackgroundTransparency = 0.8}):Play()
        end)

        -- Jika ini tab pertama, otomatis aktif
        if #window.tabs == 0 then
            tabContent.Visible = true
            tabBtn.TextColor3 = library.theme.Text
            tabBtn.BackgroundTransparency = 0.8
        end

        table.insert(window.tabs, {content = tabContent, btn = tabBtn})

        -- [[ COMPONENTS ]] --
        
        -- TOGGLE
        function tab:Toggle(text, default, callback)
            local toggled = default or false
            local toggleFrame = Create("Frame", {
                Parent = tabContent,
                BackgroundColor3 = library.theme.Secondary,
                Size = UDim2.new(1, 0, 0, 40)
            })
            Create("UICorner", {Parent = toggleFrame, CornerRadius = UDim.new(0, 8)})
            
            local title = Create("TextLabel", {
                Parent = toggleFrame,
                Text = text,
                Font = Enum.Font.GothamSemibold,
                TextColor3 = library.theme.Text,
                TextSize = 13,
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local switchBg = Create("Frame", {
                Parent = toggleFrame,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -55, 0.5, -10),
                BackgroundColor3 = toggled and library.theme.Accent or library.theme.Main
            })
            Create("UICorner", {Parent = switchBg, CornerRadius = UDim.new(1, 0)})
            
            local switchCircle = Create("Frame", {
                Parent = switchBg,
                Size = UDim2.new(0, 16, 0, 16),
                Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = library.theme.Text
            })
            Create("UICorner", {Parent = switchCircle, CornerRadius = UDim.new(1, 0)})

            local btn = Create("TextButton", {
                Parent = toggleFrame,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = ""
            })

            btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                -- Animasi Switch
                local targetPos = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                local targetColor = toggled and library.theme.Accent or library.theme.Main
                
                TweenService:Create(switchCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = targetPos}):Play()
                TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
                
                callback(toggled)
            end)
            
            -- Trigger callback default jika aktif
            if default then callback(true) end
        end

        -- BUTTON
        function tab:Button(text, callback)
            local btnFrame = Create("Frame", {
                Parent = tabContent,
                BackgroundColor3 = library.theme.Secondary,
                Size = UDim2.new(1, 0, 0, 40)
            })
            Create("UICorner", {Parent = btnFrame, CornerRadius = UDim.new(0, 8)})

            local btn = Create("TextButton", {
                Parent = btnFrame,
                Text = text,
                Font = Enum.Font.GothamBold,
                TextColor3 = library.theme.Text,
                TextSize = 13,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1
            })

            -- Hover & Click Effect
            btn.MouseEnter:Connect(function()
                TweenService:Create(btnFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btnFrame, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.Secondary}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                -- Efek tekan
                local originalSize = btnFrame.Size
                TweenService:Create(btnFrame, TweenInfo.new(0.05), {Size = UDim2.new(0.98, 0, 0, 38)}):Play()
                task.wait(0.05)
                TweenService:Create(btnFrame, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = originalSize}):Play()
                callback()
            end)
        end

        -- SLIDER
        function tab:Slider(text, min, max, default, callback)
            local value = default or min
            local sliderFrame = Create("Frame", {
                Parent = tabContent,
                BackgroundColor3 = library.theme.Secondary,
                Size = UDim2.new(1, 0, 0, 50)
            })
            Create("UICorner", {Parent = sliderFrame, CornerRadius = UDim.new(0, 8)})

            local title = Create("TextLabel", {
                Parent = sliderFrame,
                Text = text,
                Font = Enum.Font.GothamSemibold,
                TextColor3 = library.theme.Text,
                TextSize = 13,
                Position = UDim2.new(0, 15, 0, 10),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local valLabel = Create("TextLabel", {
                Parent = sliderFrame,
                Text = tostring(value),
                Font = Enum.Font.Code,
                TextColor3 = library.theme.TextDim,
                TextSize = 12,
                Position = UDim2.new(1, -60, 0, 10),
                Size = UDim2.new(0, 45, 0, 15),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local sliderBar = Create("Frame", {
                Parent = sliderFrame,
                BackgroundColor3 = library.theme.Main,
                Size = UDim2.new(1, -30, 0, 6),
                Position = UDim2.new(0, 15, 0, 35)
            })
            Create("UICorner", {Parent = sliderBar, CornerRadius = UDim.new(1, 0)})

            local fill = Create("Frame", {
                Parent = sliderBar,
                BackgroundColor3 = library.theme.Accent,
                Size = UDim2.new((value - min)/(max - min), 0, 1, 0)
            })
            Create("UICorner", {Parent = fill, CornerRadius = UDim.new(1, 0)})

            local interact = Create("TextButton", {
                Parent = sliderBar,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = ""
            })

            local dragging = false
            local function update(input)
                local pos = UDim2.new(math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1), 0, 1, 0)
                TweenService:Create(fill, TweenInfo.new(0.1), {Size = pos}):Play()
                
                local newVal = math.floor(min + ((max - min) * pos.X.Scale))
                valLabel.Text = tostring(newVal)
                callback(newVal)
            end

            interact.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            
            interact.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input)
                end
            end)
        end
        
        -- DROPDOWN
        function tab:Dropdown(text, options, default, callback)
            local isDropped = false
            local dropFrame = Create("Frame", {
                Parent = tabContent,
                BackgroundColor3 = library.theme.Secondary,
                Size = UDim2.new(1, 0, 0, 40),
                ClipsDescendants = true
            })
            Create("UICorner", {Parent = dropFrame, CornerRadius = UDim.new(0, 8)})
            
            local title = Create("TextLabel", {
                Parent = dropFrame,
                Text = text .. ": " .. (default or "Select"),
                Font = Enum.Font.GothamSemibold,
                TextColor3 = library.theme.Text,
                TextSize = 13,
                Size = UDim2.new(1, -40, 0, 40),
                Position = UDim2.new(0, 15, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local arrow = Create("ImageLabel", {
                Parent = dropFrame,
                Image = "rbxassetid://6031091004", -- Arrow Icon
                ImageColor3 = library.theme.TextDim,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -30, 0, 10),
                BackgroundTransparency = 1
            })

            local btn = Create("TextButton", {
                Parent = dropFrame,
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                Text = ""
            })
            
            local listLayout = Create("UIListLayout", {
                Parent = dropFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 2)
            })
            
            -- Padding untuk title agar tidak tertutup item list
            local titlePad = Create("Frame", {
                Parent = dropFrame,
                Name = "TitlePad",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundTransparency = 1,
                LayoutOrder = -1
            })

            btn.MouseButton1Click:Connect(function()
                isDropped = not isDropped
                local targetHeight = isDropped and (40 + (#options * 32) + 5) or 40
                TweenService:Create(dropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                TweenService:Create(arrow, TweenInfo.new(0.3), {Rotation = isDropped and 180 or 0}):Play()
            end)
            
            for _, opt in ipairs(options) do
                local optBtn = Create("TextButton", {
                    Parent = dropFrame,
                    Text = opt,
                    Font = Enum.Font.Gotham,
                    TextColor3 = library.theme.TextDim,
                    TextSize = 12,
                    Size = UDim2.new(1, -20, 0, 30),
                    BackgroundColor3 = library.theme.Main,
                    BackgroundTransparency = 0.5,
                    AutoButtonColor = false
                })
                Create("UICorner", {Parent = optBtn, CornerRadius = UDim.new(0, 6)})
                
                optBtn.MouseButton1Click:Connect(function()
                    callback(opt)
                    title.Text = text .. ": " .. opt
                    isDropped = false
                    TweenService:Create(dropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                    TweenService:Create(arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
                end)
            end
        end

        return tab
    end

    return window
end

-- [[ INIT FUNCTION ]] --
function library:Init()
    -- Cek Parenting yang aman
    local success, _ = pcall(function()
        if gethui then
            self.base = gethui()
        elseif game:GetService("CoreGui") then
            self.base = game:GetService("CoreGui")
        else
            self.base = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    
    if not success or not self.base then
        self.base = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Hapus UI lama jika ada
    if self.base:FindFirstChild("FSSHUB_UI_V8") then
        self.base.FSSHUB_UI_V8:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FSSHUB_UI_V8"
    gui.Parent = self.base
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true -- Fullscreen
    
    self.base = gui -- Redirect base ke ScreenGui yang baru dibuat
    
    return self.base
end

return library
