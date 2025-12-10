local library = {flags = {}, windows = {}, open = true, toClose = false} -- Added toClose flag

-- [[ FSSHUB THEME CONFIGURATION ]] --
library.theme = {
    Main = Color3.fromRGB(15, 15, 20),       -- Background Utama Gelap
    Secondary = Color3.fromRGB(25, 25, 30),  -- Background Element
    Accent = Color3.fromRGB(140, 80, 255),   -- FSSHUB Purple
    Text = Color3.fromRGB(240, 240, 240),    -- Teks Putih Bersih
    TextDark = Color3.fromRGB(150, 150, 160),-- Teks Abu-abu
    Outline = Color3.fromRGB(45, 45, 55),    -- Garis Pinggir Halus
    Hover = Color3.fromRGB(35, 35, 45)       -- Efek Hover
}

--Services
local runService = game:GetService"RunService"
local tweenService = game:GetService"TweenService"
local textService = game:GetService"TextService"
local inputService = game:GetService"UserInputService"
local ui = Enum.UserInputType.MouseButton1

--Locals
local dragging, dragInput, dragStart, startPos, dragObject

--Functions
local function round(num, bracket)
	bracket = bracket or 1
	local a = math.floor(num/bracket + (math.sign(num) * 0.5)) * bracket
	if a < 0 then
		a = a + bracket
	end
	return a
end

local function keyCheck(x,x1)
	for _,v in next, x1 do
		if v == x then
			return true
		end
	end
end

local function update(input)
	local delta = input.Position - dragStart
	local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y
	dragObject:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), "Out", "Quint", 0.15, true)
end
 
-- [FIX] Rainbow Logic (Optimized & Memory Leak Proof)
local chromaColor
local rainbowTime = 5
task.spawn(function()
	while not library.toClose do -- Cek flag berhenti
		task.wait()
		chromaColor = Color3.fromHSV(tick() % rainbowTime / rainbowTime, 1, 1)
	end
end)

function library:Create(class, properties)
	properties = typeof(properties) == "table" and properties or {}
	local inst = Instance.new(class)
	for property, value in next, properties do
		inst[property] = value
	end
	return inst
end

function library:Destroy()
    library.toClose = true -- Matikan loop rainbow
    if library.base then library.base:Destroy() end
end

-- [[ WINDOW CREATION ]] --
local function createOptionHolder(holderTitle, parent, parentTable, subHolder)
	local size = subHolder and 34 or 42
	
    -- Main Frame
	parentTable.main = library:Create("ImageButton", {
		LayoutOrder = subHolder and parentTable.position or 0,
		Position = UDim2.new(0, 20 + (250 * (parentTable.position or 0)), 0, 20),
		Size = UDim2.new(0, 230, 0, size),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Main,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		ClipsDescendants = true,
		Parent = parent
	})
	
	local headerBg
	if not subHolder then
		headerBg = library:Create("ImageLabel", {
			Size = UDim2.new(1, 0, 0, size),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = parentTable.open and (subHolder and library.theme.Secondary or library.theme.Main) or library.theme.Main,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(100, 100, 100, 100),
			SliceScale = 0.04,
			Parent = parentTable.main
		})
        
        library:Create("Frame", {
            Parent = headerBg,
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = library.theme.Accent,
            BorderSizePixel = 0,
            Name = "AccentLine"
        })
	end
	
	local title = library:Create("TextLabel", {
		Size = UDim2.new(1, -30, 0, size),
        Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = holderTitle,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextColor3 = library.theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parentTable.main
	})
	
	local closeHolder = library:Create("Frame", {
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(-1, 0, 1, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Parent = title
	})
	
	local close = library:Create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -size + 14, 1, -size + 14),
		Rotation = parentTable.open and 90 or 180,
		BackgroundTransparency = 1,
		Image = "rbxassetid://4918373417",
		ImageColor3 = library.theme.TextDark,
		ScaleType = Enum.ScaleType.Fit,
		Parent = closeHolder
	})
	
	parentTable.content = library:Create("Frame", {
		Position = UDim2.new(0, 0, 0, size),
		Size = UDim2.new(1, 0, 1, -size),
		BackgroundTransparency = 1,
		Parent = parentTable.main
	})
	
	local layout = library:Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
		Parent = parentTable.content
	})
	
	layout.Changed:connect(function()
		parentTable.content.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 5)
		parentTable.main.Size = #parentTable.options > 0 and parentTable.open and UDim2.new(0, 230, 0, layout.AbsoluteContentSize.Y + size + 5) or UDim2.new(0, 230, 0, size)
	end)
	
	if not subHolder then
		library:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
			Parent = parentTable.content
		})
		
		title.InputBegan:connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				dragObject = parentTable.main
				dragging = true
				dragStart = input.Position
				startPos = dragObject.Position
			end
		end)
		title.InputChanged:connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				dragInput = input
			end
		end)
		title.InputEnded:connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end
	
	closeHolder.InputBegan:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			parentTable.open = not parentTable.open
            
			tweenService:Create(close, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Rotation = parentTable.open and 90 or 180, 
                ImageColor3 = parentTable.open and library.theme.Accent or library.theme.TextDark
            }):Play()
			
			parentTable.main:TweenSize(#parentTable.options > 0 and parentTable.open and UDim2.new(0, 230, 0, layout.AbsoluteContentSize.Y + size + 5) or UDim2.new(0, 230, 0, size), "Out", "Quint", 0.3, true)
		end
	end)

	function parentTable:SetTitle(newTitle)
		title.Text = tostring(newTitle)
	end
	
	return parentTable
end
	
-- [[ COMPONENT: LABEL ]] --
local function createLabel(option, parent)
	local main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = " " .. option.text,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextColor3 = library.theme.TextDark,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})
	
	setmetatable(option, {__newindex = function(t, i, v)
		if i == "Text" then
			main.Text = " " .. tostring(v)
		end
	end})
end

-- [[ COMPONENT: TOGGLE ]] --
function createToggle(option, parent)
	local main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		Text = " " .. option.text,
		TextSize = 14,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = library.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})
	
	local tickboxOutline = library:Create("ImageLabel", {
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(-1, 20, 1, -12),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = option.state and library.theme.Accent or library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = main
	})
	
	local tickboxInner = library:Create("ImageLabel", {
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = option.state and library.theme.Accent or library.theme.Main,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = tickboxOutline
	})
	
	local checkmarkHolder = library:Create("Frame", {
		Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
		Size = option.state and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = tickboxInner
	})
    
    local checkmark = library:Create("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3570695787",
        ImageColor3 = library.theme.Text,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100, 100, 100, 100),
        SliceScale = 0.04,
        Parent = checkmarkHolder
    })
	
	local inContact
	main.InputBegan:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			option:SetState(not option.state)
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not option.state then
				tweenService:Create(tickboxOutline, TweenInfo.new(0.2), {ImageColor3 = library.theme.Outline}):Play()
			end
		end
	end)
	
	main.InputEnded:connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not option.state then
				tweenService:Create(tickboxOutline, TweenInfo.new(0.2), {ImageColor3 = library.theme.Secondary}):Play()
			end
		end
	end)
	
	function option:SetState(state)
		library.flags[self.flag] = state
		self.state = state
        
        -- [FIX] Wrap Tween in pcall to prevent crash if object is not in workspace
        local sizeGoal = option.state and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 0, 0)
        pcall(function()
		    checkmarkHolder:TweenSize(sizeGoal, "Out", "Back", 0.25, true)
        end)
		
        local colorGoal = state and library.theme.Accent or library.theme.Main
        local borderGoal = state and library.theme.Accent or library.theme.Secondary
        
        pcall(function()
		    tweenService:Create(tickboxInner, TweenInfo.new(0.2), {ImageColor3 = colorGoal}):Play()
		    tweenService:Create(tickboxOutline, TweenInfo.new(0.2), {ImageColor3 = borderGoal}):Play()
        end)

		self.callback(state)
	end

	if option.state then
		delay(0.1, function() option:SetState(true) end)
	end
	
	setmetatable(option, {__newindex = function(t, i, v)
		if i == "Text" then
			main.Text = " " .. tostring(v)
		end
	end})
end

-- [[ COMPONENT: BUTTON ]] --
function createButton(option, parent)
	local main = library:Create("TextLabel", {
		ZIndex = 2,
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = " " .. option.text,
		TextSize = 14,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = library.theme.Text,
		Parent = parent.content
	})
	
	local round = library:Create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -4, 1, -6),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = main
	})
    
    library:Create("UIStroke", {
        Parent = round,
        Color = library.theme.Outline,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
	
	local inContact
	local clicking
	main.InputBegan:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			library.flags[option.flag] = true
			clicking = true
			tweenService:Create(round, TweenInfo.new(0.1), {ImageColor3 = library.theme.Accent}):Play()
            tweenService:Create(main, TweenInfo.new(0.1), {TextColor3 = Color3.new(1,1,1)}):Play()
			option.callback()
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Hover}):Play()
		end
	end)
	
	main.InputEnded:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			clicking = false
			if inContact then
				tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Hover}):Play()
			else
				tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Secondary}):Play()
			end
            tweenService:Create(main, TweenInfo.new(0.2), {TextColor3 = library.theme.Text}):Play()
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not clicking then
				tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Secondary}):Play()
			end
		end
	end)
end

-- [[ COMPONENT: KEYBIND ]] --
local function createBind(option, parent)
	local binding
	local holding
	local loop
	local text = string.match(option.key, "Mouse") and string.sub(option.key, 1, 5) .. string.sub(option.key, 12, 13) or option.key

	local main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = " " .. option.text,
		TextSize = 14,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = library.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})
	
	local round = library:Create("ImageLabel", {
		Position = UDim2.new(1, -6, 0, 4),
		Size = UDim2.new(0, -textService:GetTextSize(text, 14, Enum.Font.GothamBold, Vector2.new(9e9, 9e9)).X - 16, 1, -8),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = main
	})
    
    library:Create("UIStroke", { Parent = round, Color = library.theme.Outline, Thickness = 1 })
	
	local bindinput = library:Create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextColor3 = library.theme.TextDark,
		Parent = round
	})
	
	local inContact
	main.InputBegan:connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not binding then
				tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Hover}):Play()
			end
		end
	end)
	 
	main.InputEnded:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			binding = true
			bindinput.Text = "..."
			tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Accent}):Play()
            bindinput.TextColor3 = Color3.new(1,1,1)
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not binding then
				tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Secondary}):Play()
			end
		end
	end)
	
	inputService.InputBegan:connect(function(input)
		if inputService:GetFocusedTextBox() then return end
		if (input.KeyCode.Name == option.key or input.UserInputType.Name == option.key) and not binding then
			if option.hold then
				loop = runService.Heartbeat:connect(function()
					if binding then
						option.callback(true)
						loop:Disconnect()
						loop = nil
					else
						option.callback()
					end
				end)
			else
				option.callback()
			end
		elseif binding then
			local key
			pcall(function() if not keyCheck(input.KeyCode, blacklistedKeys) then key = input.KeyCode end end)
			pcall(function() if keyCheck(input.UserInputType, whitelistedMouseinputs) and not key then key = input.UserInputType end end)
			key = key or option.key
			option:SetKey(key)
		end
	end)
	
	inputService.InputEnded:connect(function(input)
		if input.KeyCode.Name == option.key or input.UserInputType.Name == option.key or input.UserInputType.Name == "MouseMovement" then
			if loop then
				loop:Disconnect()
				loop = nil
				option.callback(true)
			end
		end
	end)
	
	function option:SetKey(key)
		binding = false
		if loop then loop:Disconnect(); loop = nil end
		self.key = key or self.key
		self.key = self.key.Name or self.key
		library.flags[self.flag] = self.key
		if string.match(self.key, "Mouse") then
			bindinput.Text = string.sub(self.key, 1, 5) .. string.sub(self.key, 12, 13)
		else
			bindinput.Text = self.key
		end
        
		tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Secondary}):Play()
        bindinput.TextColor3 = library.theme.TextDark
		round.Size = UDim2.new(0, -textService:GetTextSize(bindinput.Text, 14, Enum.Font.GothamBold, Vector2.new(9e9, 9e9)).X - 16, 1, -8)	
	end
end

-- [[ COMPONENT: SLIDER ]] --
local function createSlider(option, parent)
	local main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		Parent = parent.content
	})
	
	local title = library:Create("TextLabel", {
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = " " .. option.text,
		TextSize = 14,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = library.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})
	
	local slider = library:Create("ImageLabel", {
		Position = UDim2.new(0, 10, 0, 32),
		Size = UDim2.new(1, -20, 0, 6),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.06,
		Parent = main
	})
	
	local fill = library:Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Accent, 
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.06,
		Parent = slider
	})
	
	local circle = library:Create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 0.5, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.new(1,1,1),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 1,
		Parent = slider
	})
	
	local valueRound = library:Create("ImageLabel", {
		Position = UDim2.new(1, -6, 0, 2),
		Size = UDim2.new(0, -50, 0, 20),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = main
	})
    library:Create("UIStroke", { Parent = valueRound, Color = library.theme.Outline, Thickness = 1 })
	
	local inputvalue = library:Create("TextBox", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = option.value,
		TextColor3 = library.theme.Text,
		TextSize = 12,
		TextWrapped = true,
		Font = Enum.Font.Code,
		Parent = valueRound
	})
	
	if option.min >= 0 then
		fill.Size = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 1, 0)
	else
		fill.Position = UDim2.new((0 - option.min) / (option.max - option.min), 0, 0, 0)
		fill.Size = UDim2.new(option.value / (option.max - option.min), 0, 1, 0)
	end
	
	local sliding
	local inContact
    
	main.InputBegan:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			tweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(3, 0, 3, 0)}):Play()
			sliding = true
			option:SetValue(option.min + ((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X) * (option.max - option.min))
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
            tweenService:Create(circle, TweenInfo.new(0.2), {Size = UDim2.new(2.5, 0, 2.5, 0)}):Play()
		end
	end)
	
	inputService.InputChanged:connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and sliding then
			option:SetValue(option.min + ((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X) * (option.max - option.min))
		end
	end)

	main.InputEnded:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
            tweenService:Create(circle, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			inputvalue:ReleaseFocus()
            if not sliding then
                tweenService:Create(circle, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            end
		end
	end)

	inputvalue.FocusLost:connect(function()
		option:SetValue(tonumber(inputvalue.Text) or option.value)
	end)

	function option:SetValue(value)
		value = round(value, option.float)
		value = math.clamp(value, self.min, self.max)
		circle:TweenPosition(UDim2.new((value - self.min) / (self.max - self.min), 0, 0.5, 0), "Out", "Quint", 0.1, true)
		if self.min >= 0 then
			fill:TweenSize(UDim2.new((value - self.min) / (self.max - self.min), 0, 1, 0), "Out", "Quint", 0.1, true)
		else
			fill:TweenPosition(UDim2.new((0 - self.min) / (self.max - self.min), 0, 0, 0), "Out", "Quint", 0.1, true)
			fill:TweenSize(UDim2.new(value / (self.max - self.min), 0, 1, 0), "Out", "Quint", 0.1, true)
		end
		library.flags[self.flag] = value
		self.value = value
		inputvalue.Text = value
		self.callback(value)
	end
end

-- [[ COMPONENT: LIST / DROPDOWN ]] --
local function createList(option, parent, holder)
	local valueCount = 0
	
	local main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		Parent = parent.content
	})
	
	local round = library:Create("ImageLabel", {
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = main
	})
    library:Create("UIStroke", { Parent = round, Color = library.theme.Outline, Thickness = 1 })
	
	local title = library:Create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 12),
		BackgroundTransparency = 1,
		Text = option.text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextColor3 = library.theme.TextDark,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})
	
	local listvalue = library:Create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 22),
		Size = UDim2.new(1, -24, 0, 16),
		BackgroundTransparency = 1,
		Text = option.value,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextColor3 = library.theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})
	
	library:Create("ImageLabel", {
		Position = UDim2.new(1, -24, 0.5, -8),
		Size = UDim2.new(0, 16, 0, 16),
		Rotation = 90,
		BackgroundTransparency = 1,
		Image = "rbxassetid://4918373417",
		ImageColor3 = library.theme.TextDark,
		ScaleType = Enum.ScaleType.Fit,
		Parent = round
	})
	
	option.mainHolder = library:Create("ImageButton", {
		ZIndex = 3,
		Size = UDim2.new(0, 240, 0, 52),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageTransparency = 1,
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Visible = false,
		Parent = library.base
	})
    
    library:Create("UIStroke", { Parent = option.mainHolder, Color = library.theme.Accent, Thickness = 1 })
	
	local content = library:Create("ScrollingFrame", {
		ZIndex = 3,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarImageColor3 = library.theme.Accent,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = option.mainHolder
	})
	
	library:Create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		Parent = content
	})
	
	local layout = library:Create("UIListLayout", {
		Parent = content
	})
	
	layout.Changed:connect(function()
		option.mainHolder.Size = UDim2.new(0, 240, 0, (valueCount > 4 and (4 * 36) or layout.AbsoluteContentSize.Y) + 12)
		content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
	
	local inContact
	round.InputBegan:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			if library.activePopup then library.activePopup:Close() end
			local position = main.AbsolutePosition
            
			option.mainHolder.Position = UDim2.new(0, position.X - 5, 0, position.Y - 10)
			option.open = true
			option.mainHolder.Visible = true
			library.activePopup = option
			
			tweenService:Create(option.mainHolder, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0, position.X - 5, 0, position.Y - 4)}):Play()
			
            for _,label in next, content:GetChildren() do
				if label:IsA"TextLabel" then
					tweenService:Create(label, TweenInfo.new(0.3), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
				end
			end
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Hover}):Play()
		end
	end)
	
	round.InputEnded:connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not option.open then
				tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Secondary}):Play()
			end
		end
	end)
	
	function option:AddValue(value)
		valueCount = valueCount + 1
		local label = library:Create("TextLabel", {
			ZIndex = 3,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = library.theme.Secondary,
			BorderSizePixel = 0,
			Text = "    " .. value,
			TextSize = 13,
			TextTransparency = self.open and 0 or 1,
			Font = Enum.Font.GothamSemibold,
			TextColor3 = library.theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = content
		})
		
		local inContact
		local clicking
		label.InputBegan:connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				clicking = true
				tweenService:Create(label, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.Accent, TextColor3 = Color3.new(1,1,1)}):Play()
				self:SetValue(value)
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				inContact = true
				if not clicking then
					tweenService:Create(label, TweenInfo.new(0.1), {BackgroundColor3 = library.theme.Hover}):Play()
				end
			end
		end)
		
		label.InputEnded:connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				clicking = false
				tweenService:Create(label, TweenInfo.new(0.2), {BackgroundColor3 = library.theme.Secondary, TextColor3 = library.theme.Text}):Play()
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				inContact = false
				if not clicking then
					tweenService:Create(label, TweenInfo.new(0.1), {BackgroundColor3 = library.theme.Secondary}):Play()
				end
			end
		end)
	end

	if not table.find(option.values, option.value) then
		option:AddValue(option.value)
	end
	
	for _, value in next, option.values do
		option:AddValue(tostring(value))
	end
	
	function option:RemoveValue(value)
		for _,label in next, content:GetChildren() do
			if label:IsA"TextLabel" and label.Text == "	" .. value then
				label:Destroy()
				valueCount = valueCount - 1
				break
			end
		end
		if self.value == value then
			self:SetValue("")
		end
	end
	
	function option:SetValue(value)
		library.flags[self.flag] = tostring(value)
		self.value = tostring(value)
		listvalue.Text = self.value
		self.callback(value)
        self:Close()
	end
	
	function option:Close()
		library.activePopup = nil
		self.open = false
		local position = main.AbsolutePosition
		tweenService:Create(round, TweenInfo.new(0.2), {ImageColor3 = library.theme.Secondary}):Play()
		tweenService:Create(self.mainHolder, TweenInfo.new(0.2), {ImageTransparency = 1, Position = UDim2.new(0, position.X - 5, 0, position.Y -10)}):Play()
		for _,label in next, content:GetChildren() do
			if label:IsA"TextLabel" then
				tweenService:Create(label, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
			end
		end
		delay(0.2, function()
			if not self.open then
				self.mainHolder.Visible = false
			end
		end)
	end

	return option
end

-- [[ COMPONENT: TEXTBOX ]] --
local function createBox(option, parent)
	local main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		Parent = parent.content
	})
	
	local outline = library:Create("ImageLabel", {
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.new(1, -12, 1, -12),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Outline,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = main
	})
	
	local round = library:Create("ImageLabel", {
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = outline
	})
	
	local title = library:Create("TextLabel", {
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 12),
		BackgroundTransparency = 1,
		Text = option.text,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextColor3 = library.theme.TextDark,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})
	
	local inputvalue = library:Create("TextBox", {
		Position = UDim2.new(0, 12, 0, 22),
		Size = UDim2.new(1, -24, 0, 20),
		BackgroundTransparency = 1,
		Text = option.value,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextColor3 = library.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = main
	})
	
	local focused
	inputvalue.Focused:connect(function()
		focused = true
		tweenService:Create(outline, TweenInfo.new(0.2), {ImageColor3 = library.theme.Accent}):Play()
	end)
	
	inputvalue.FocusLost:connect(function(enter)
		focused = false
		tweenService:Create(outline, TweenInfo.new(0.2), {ImageColor3 = library.theme.Outline}):Play()
		option:SetValue(inputvalue.Text, enter)
	end)
	
	function option:SetValue(value, enter)
		library.flags[self.flag] = tostring(value)
		self.value = tostring(value)
		inputvalue.Text = self.value
		self.callback(value, enter)
	end
end

-- [[ COMPONENT: COLOR PICKER (Simplied) ]] --
local function createColorPickerWindow(option)
	option.mainHolder = library:Create("ImageButton", {
		ZIndex = 3,
		Size = UDim2.new(0, 240, 0, 180),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageTransparency = 1,
		ImageColor3 = library.theme.Secondary,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = library.base
	})
    library:Create("UIStroke", { Parent = option.mainHolder, Color = library.theme.Outline, Thickness = 1 })
    
	local hue, sat, val = Color3.toHSV(option.color)
	hue, sat, val = hue == 0 and 1 or hue, sat + 0.005, val - 0.005

    option.hue = library:Create("ImageLabel", {
		ZIndex = 3, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -100, 0, 22),
		BackgroundTransparency = 1, Image = "rbxassetid://3570695787", ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(100, 100, 100, 100), SliceScale = 0.04, Parent = option.mainHolder
	})
	local Gradient = library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.157, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(0.323, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.488, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.817, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}), Parent = option.hue
	})
	option.hueSlider = library:Create("Frame", {
		ZIndex = 3, Position = UDim2.new(1 - hue, 0, 0, 0), Size = UDim2.new(0, 2, 1, 0),
		BackgroundTransparency = 1, BackgroundColor3 = library.theme.Text, BorderColor3 = library.theme.Text, Parent = option.hue
	})

    option.satval = library:Create("ImageLabel", {
		ZIndex = 3, Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -100, 1, -42),
		BackgroundTransparency = 1, BackgroundColor3 = Color3.fromHSV(hue, 1, 1), BorderSizePixel = 0,
		Image = "rbxassetid://4155801252", ImageTransparency = 1, ClipsDescendants = true, Parent = option.mainHolder
	})

	option.visualize2 = library:Create("ImageLabel", {
		ZIndex = 3, Position = UDim2.new(1, -8, 0, 8), Size = UDim2.new(0, -80, 0, 80),
		BackgroundTransparency = 1, Image = "rbxassetid://3570695787", ImageColor3 = option.color,
		ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(100, 100, 100, 100), SliceScale = 0.04, Parent = option.mainHolder
	})
    
	return option
end

local function createColor(option, parent, holder)
	option.main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = " " .. option.text,
		TextSize = 14,
		Font = Enum.Font.GothamSemibold,
		TextColor3 = library.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})
	
	local colorBoxOutline = library:Create("ImageLabel", {
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(-1, 24, 1, -12),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = library.theme.Outline,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = option.main
	})
	
	option.visualize = library:Create("ImageLabel", {
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = option.color,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.04,
		Parent = colorBoxOutline
	})
    
    option.main.InputBegan:connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
            if not option.mainHolder then createColorPickerWindow(option) end
            if library.activePopup then library.activePopup:Close() end
            option.open = true
            option.mainHolder.Visible = true
            library.activePopup = option
            
             tweenService:Create(option.mainHolder, TweenInfo.new(0.2), {ImageTransparency = 0}):Play()
        end
    end)
    
    function option:SetColor(newColor)
		self.visualize.ImageColor3 = newColor
		library.flags[self.flag] = newColor
		self.color = newColor
		self.callback(newColor)
	end
    
    function option:Close()
        library.activePopup = nil
		self.open = false
        if self.mainHolder then
            self.mainHolder.Visible = false
        end
    end
end

-- [[ COMPONENT: FOLDER / SECTION ]] --
local function loadOptions(option, holder)
	for _,newOption in next, option.options do
		if newOption.type == "label" then
			createLabel(newOption, option)
		elseif newOption.type == "toggle" then
			createToggle(newOption, option)
		elseif newOption.type == "button" then
			createButton(newOption, option)
		elseif newOption.type == "list" then
			createList(newOption, option, holder)
		elseif newOption.type == "box" then
			createBox(newOption, option)
		elseif newOption.type == "bind" then
			createBind(newOption, option)
		elseif newOption.type == "slider" then
			createSlider(newOption, option)
		elseif newOption.type == "color" then
			createColor(newOption, option, holder)
		elseif newOption.type == "folder" then
			newOption:init()
		end
	end
end

-- [[ MAIN FUNCTIONS ]] --
local function getFnctions(parent)
	function parent:AddLabel(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.type = "label"
		option.position = #self.options
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddToggle(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.state = typeof(option.state) == "boolean" and option.state or false
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "toggle"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.state
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddButton(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "button"
		option.position = #self.options
		option.flag = option.flag or option.text
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddBind(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.key = (option.key and option.key.Name) or option.key or "F"
		option.hold = typeof(option.hold) == "boolean" and option.hold or false
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "bind"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.key
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddSlider(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.min = typeof(option.min) == "number" and option.min or 0
		option.max = typeof(option.max) == "number" and option.max or 0
		option.value = math.clamp(typeof(option.value) == "number" and option.value or option.min, option.min, option.max)
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.float = typeof(option.value) == "number" and option.float or 1
		option.type = "slider"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.value
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddList(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.values = typeof(option.values) == "table" and option.values or {}
		option.value = tostring(option.value or option.values[1] or "")
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.open = false
		option.type = "list"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.value
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddBox(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.value = tostring(option.value or "")
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "box"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.value
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddColor(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.color = option.color or Color3.new(1, 1, 1)
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.open = false
		option.type = "color"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.color
		table.insert(self.options, option)
		return option
	end
	
	function parent:AddFolder(title)
		local option = {}
		option.title = tostring(title)
		option.options = {}
		option.open = false
		option.type = "folder"
		option.position = #self.options
		table.insert(self.options, option)
		getFnctions(option)
		function option:init()
			createOptionHolder(self.title, parent.content, self, true)
			loadOptions(self, parent)
		end
		return option
	end
    
    function parent:Section(title) return parent:AddFolder(title) end
    function parent:Toggle(text, state, callback) return parent:AddToggle({text=text, state=state, callback=callback}) end
    function parent:Button(text, callback) return parent:AddButton({text=text, callback=callback}) end
    function parent:Slider(text, min, max, val, callback) return parent:AddSlider({text=text, min=min, max=max, value=val, callback=callback}) end
    function parent:Dropdown(text, values, val, callback) return parent:AddList({text=text, values=values, value=val, callback=callback}) end
end

function library:CreateWindow(title)
	local window = {title = tostring(title), options = {}, open = true, canInit = true, init = false, position = #self.windows}
	getFnctions(window)
    function window:Window(t) self.title = t; return self end 
	table.insert(library.windows, window)
	return window
end

function library:Window(title)
    return library:CreateWindow(title)
end

function library:Init()
	self.base = self.base or self:Create("ScreenGui")
	if syn and syn.protect_gui then syn.protect_gui(self.base)
	elseif get_hidden_gui then get_hidden_gui(self.base)
	elseif gethui then gethui(self.base)
	else self.base.Parent = game:GetService"CoreGui" end
	
	self.base.Name = "FSSHUB_UI"
    self.base.ResetOnSpawn = false 
	
	for _, window in next, self.windows do
		if window.canInit and not window.init then
			window.init = true
			createOptionHolder(window.title, self.base, window)
			loadOptions(window)
		end
	end
	return self.base
end

inputService.InputBegan:connect(function(input)
	if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
		if library.activePopup then
			if input.Position.X < library.activePopup.mainHolder.AbsolutePosition.X or input.Position.X > library.activePopup.mainHolder.AbsolutePosition.X + library.activePopup.mainHolder.AbsoluteSize.X or 
               input.Position.Y < library.activePopup.mainHolder.AbsolutePosition.Y or input.Position.Y > library.activePopup.mainHolder.AbsolutePosition.Y + library.activePopup.mainHolder.AbsoluteSize.Y then
				library.activePopup:Close()
			end
		end
	end
end)

inputService.InputChanged:connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

return library
