-- [[ FSSHUB AUTH UI MODULE V2.0 (MODERN PURPLE) ]] --
-- Update: Rebrand to Deep Purple Theme & Enhanced UX

local AuthUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- [[ THEME CONFIGURATION ]] --
local Theme = {
    Bg = Color3.fromRGB(15, 15, 20),         -- Dark Blue-ish Grey (Match Lib)
    Accent = Color3.fromRGB(140, 80, 255),   -- FSSHUB Purple
    Text = Color3.fromRGB(240, 240, 240),    -- White
    Dim = Color3.fromRGB(150, 150, 160),     -- Grey Text
    Error = Color3.fromRGB(255, 65, 65),     -- Red Error
    Outline = Color3.fromRGB(45, 45, 55)     -- Subtle Outline
}

local function Create(class, props)
    local inst = Instance.new(class)
    for i, v in pairs(props) do inst[i] = v end
    return inst
end

local function GetParent()
    if gethui then return gethui() end
    if CoreGui then return CoreGui end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function AuthUI.Show(options)
    local Parent = GetParent()
    if Parent:FindFirstChild("FSSHUB_Auth") then Parent.FSSHUB_Auth:Destroy() end

    local Screen = Create("ScreenGui", {Name = "FSSHUB_Auth", Parent = Parent, ResetOnSpawn = false, DisplayOrder = 10000})
    
    -- Main Container
    local Main = Create("Frame", {
        Parent = Screen, BackgroundColor3 = Theme.Bg,
        Size = UDim2.new(0, 380, 0, 240), Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundTransparency = 1
    })

    -- Auto Scale for Mobile
    local Scale = Create("UIScale", {Parent = Main, Scale = 1})
    if Workspace.CurrentCamera.ViewportSize.Y < 500 then
        Scale.Scale = 0.85 
    end
    
    -- Styling (Shadow & Stroke)
    local Stroke = Create("UIStroke", {Parent = Main, Color = Theme.Accent, Thickness = 1.5, Transparency = 1})
    Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 12)})
    
    -- Title Section
    local Title = Create("TextLabel", {
        Parent = Main, Text = "FSS HUB | GATEWAY", 
        TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 24, 
        Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 20), 
        BackgroundTransparency = 1, TextTransparency = 1
    })
    
    local SubTitle = Create("TextLabel", {
        Parent = Main, Text = "Authenticate to access the ecosystem", 
        TextColor3 = Theme.Dim, Font = Enum.Font.GothamMedium, TextSize = 12, 
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 50), 
        BackgroundTransparency = 1, TextTransparency = 1
    })

    -- Input Box
    local InputBg = Create("Frame", {
        Parent = Main, BackgroundColor3 = Color3.fromRGB(25, 25, 30),
        Size = UDim2.new(0.85, 0, 0, 45), Position = UDim2.new(0.075, 0, 0.38, 0),
        BackgroundTransparency = 1
    })
    Create("UICorner", {Parent = InputBg, CornerRadius = UDim.new(0, 8)})
    local InputStroke = Create("UIStroke", {Parent = InputBg, Color = Theme.Outline, Thickness = 1, Transparency = 1})

    local Input = Create("TextBox", {
        Parent = InputBg, BackgroundTransparency = 1, TextColor3 = Theme.Accent, 
        PlaceholderText = "Paste your key here...", PlaceholderColor3 = Color3.fromRGB(80, 80, 90),
        Font = Enum.Font.Code, TextSize = 14, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        TextTransparency = 1
    })

    -- Input Focus Animation
    Input.Focused:Connect(function() TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play() end)
    Input.FocusLost:Connect(function() TweenService:Create(InputStroke, TweenInfo.new(0.2), {Color = Theme.Outline}):Play() end)

    -- Buttons
    local BtnContainer = Create("Frame", {Parent = Main, Size = UDim2.new(0.85, 0, 0, 40), Position = UDim2.new(0.075, 0, 0.7, 0), BackgroundTransparency = 1})
    Create("UIListLayout", {Parent = BtnContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10)})

    local function MakeBtn(text, col, outline, func)
        local Btn = Create("TextButton", {
            Parent = BtnContainer, Text = text, TextColor3 = col == Theme.Accent and Color3.new(1,1,1) or Theme.Text, 
            BackgroundColor3 = col, Font = Enum.Font.GothamBold, TextSize = 13,
            Size = UDim2.new(0.5, -5, 1, 0), AutoButtonColor = false, BackgroundTransparency = 1, TextTransparency = 1
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 8)})
        if outline then Create("UIStroke", {Parent = Btn, Color = Theme.Outline, Thickness = 1, Transparency = 1}) end
        
        Btn.MouseButton1Click:Connect(function()
            -- Click Animation
            TweenService:Create(Btn, TweenInfo.new(0.05), {Size = UDim2.new(0.5, -8, 0.9, 0)}):Play()
            task.wait(0.05)
            TweenService:Create(Btn, TweenInfo.new(0.05), {Size = UDim2.new(0.5, -5, 1, 0)}):Play()
            func()
        end)
        return Btn
    end

    local GetKeyBtn = MakeBtn("GET KEY", Theme.Bg, true, function()
        setclipboard("https://discord.gg/28cfy5E3ag")
        Title.Text = "LINK COPIED!"
        Title.TextColor3 = Theme.Text
        task.delay(1.5, function() 
            Title.Text = "FSS HUB | GATEWAY"
            Title.TextColor3 = Theme.Accent
        end)
    end)

    local LoginBtn = MakeBtn("AUTHENTICATE", Theme.Accent, false, function()
        local txt = string.gsub(Input.Text, "%s+", "")
        if txt == options.ValidKey then
            Title.Text = "ACCESS GRANTED"
            Title.TextColor3 = Theme.Accent
            Stroke.Color = Theme.Accent
            TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
            task.wait(0.5)
            Screen:Destroy()
            options.OnSuccess(txt)
        else
            -- Error Shake
            Title.Text = "INVALID KEY"
            Title.TextColor3 = Theme.Error
            Stroke.Color = Theme.Error
            for i = 1, 6 do
                Main.Position = UDim2.new(0.5, math.random(-5, 5), 0.5, 0)
                task.wait(0.03)
            end
            Main.Position = UDim2.new(0.5, 0, 0.5, 0)
            
            task.delay(1.5, function() 
                Title.Text = "FSS HUB | GATEWAY" 
                Title.TextColor3 = Theme.Accent
                Stroke.Color = Theme.Accent
            end)
        end
    end)

    -- [[ INTRO ANIMATION ]] --
    local info = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    
    TweenService:Create(Main, info, {BackgroundTransparency = 0}):Play()
    TweenService:Create(Stroke, info, {Transparency = 0}):Play()
    
    task.wait(0.1)
    TweenService:Create(Title, info, {TextTransparency = 0, Position = UDim2.new(0, 0, 0, 20)}):Play()
    TweenService:Create(SubTitle, info, {TextTransparency = 0, Position = UDim2.new(0, 0, 0, 50)}):Play()
    
    task.wait(0.1)
    TweenService:Create(InputBg, info, {BackgroundTransparency = 0}):Play()
    TweenService:Create(InputStroke, info, {Transparency = 0}):Play()
    TweenService:Create(Input, info, {TextTransparency = 0}):Play()
    
    task.wait(0.1)
    for _, btn in pairs(BtnContainer:GetChildren()) do
        if btn:IsA("TextButton") then
            TweenService:Create(btn, info, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
            if btn:FindFirstChild("UIStroke") then
                 TweenService:Create(btn.UIStroke, info, {Transparency = 0}):Play()
            end
        end
    end

    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
    Main.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
    Main.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

return AuthUI
