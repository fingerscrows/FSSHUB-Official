-- [[ FSSHUB AUTH UI MODULE V1.0 ]] --
-- Standalone UI untuk Key System (Anti-Blank Bug)

local AuthUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

-- THEME
local Theme = {
    Bg = Color3.fromRGB(15, 15, 15),
    Accent = Color3.fromRGB(0, 255, 136),
    Text = Color3.fromRGB(240, 240, 240),
    Dim = Color3.fromRGB(120, 120, 120)
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
    
    -- Main Frame (Fixed Size & Visibility)
    local Main = Create("Frame", {
        Parent = Screen,
        BackgroundColor3 = Theme.Bg,
        Size = UDim2.new(0, 380, 0, 220),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        BackgroundTransparency = 1 -- Mulai transparan untuk animasi
    })
    
    -- Elements
    local Stroke = Create("UIStroke", {Parent = Main, Color = Theme.Accent, Thickness = 2, Transparency = 1})
    local Corner = Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 10)})
    
    local Title = Create("TextLabel", {
        Parent = Main, Text = "FSS HUB | GATEWAY", TextColor3 = Theme.Accent,
        Font = Enum.Font.GothamBold, TextSize = 22,
        Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 15),
        BackgroundTransparency = 1, TextTransparency = 1
    })
    
    local SubTitle = Create("TextLabel", {
        Parent = Main, Text = "Enter key to access script", TextColor3 = Theme.Dim,
        Font = Enum.Font.Gotham, TextSize = 12,
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1, TextTransparency = 1
    })

    local Input = Create("TextBox", {
        Parent = Main, BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        TextColor3 = Theme.Accent, PlaceholderText = "Paste Key Here...",
        Font = Enum.Font.Mono, TextSize = 14,
        Size = UDim2.new(0.8, 0, 0, 45), Position = UDim2.new(0.1, 0, 0.35, 0),
        TextTransparency = 1, BackgroundTransparency = 1
    })
    Create("UICorner", {Parent = Input, CornerRadius = UDim.new(0, 8)})
    Create("UIStroke", {Parent = Input, Color = Color3.fromRGB(50,50,50), Thickness = 1, Transparency = 1})

    -- Buttons
    local BtnContainer = Create("Frame", {
        Parent = Main, Size = UDim2.new(0.8, 0, 0, 40),
        Position = UDim2.new(0.1, 0, 0.65, 0), BackgroundTransparency = 1
    })
    local Layout = Create("UIListLayout", {Parent = BtnContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10)})

    local function MakeBtn(text, col, func)
        local Btn = Create("TextButton", {
            Parent = BtnContainer, Text = text, TextColor3 = Color3.new(0,0,0),
            BackgroundColor3 = col, Font = Enum.Font.GothamBold, TextSize = 14,
            Size = UDim2.new(0.5, -5, 1, 0), AutoButtonColor = false,
            BackgroundTransparency = 1, TextTransparency = 1
        })
        Create("UICorner", {Parent = Btn, CornerRadius = UDim.new(0, 6)})
        
        Btn.MouseButton1Click:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(0.5, -8, 0.9, 0)}):Play()
            task.wait(0.1)
            TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(0.5, -5, 1, 0)}):Play()
            func()
        end)
        return Btn
    end

    local GetKeyBtn = MakeBtn("GET KEY", Theme.Text, function()
        setclipboard("https://discord.gg/28cfy5E3ag")
        Title.Text = "LINK COPIED!"
        task.delay(2, function() Title.Text = "FSS HUB | GATEWAY" end)
    end)

    local LoginBtn = MakeBtn("LOGIN", Theme.Accent, function()
        local txt = string.gsub(Input.Text, "%s+", "")
        if txt == options.ValidKey then
            Title.Text = "SUCCESS!"
            -- Animasi Keluar
            TweenService:Create(Main, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
            task.wait(0.5)
            Screen:Destroy()
            options.OnSuccess(txt)
        else
            Title.Text = "INVALID KEY!"
            Title.TextColor3 = Color3.fromRGB(255, 50, 50)
            Stroke.Color = Color3.fromRGB(255, 50, 50)
            task.delay(1, function() 
                Title.Text = "FSS HUB | GATEWAY" 
                Title.TextColor3 = Theme.Accent
                Stroke.Color = Theme.Accent
            end)
        end
    end)

    -- ANIMASI MASUK (Fade In)
    -- Ini lebih aman daripada UIScale 0 -> 1
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad)
    TweenService:Create(Main, info, {BackgroundTransparency = 0}):Play()
    TweenService:Create(Stroke, info, {Transparency = 0}):Play()
    TweenService:Create(Title, info, {TextTransparency = 0}):Play()
    TweenService:Create(SubTitle, info, {TextTransparency = 0}):Play()
    TweenService:Create(Input, info, {TextTransparency = 0, BackgroundTransparency = 0}):Play()
    Input.UIStroke.Transparency = 0
    
    TweenService:Create(GetKeyBtn, info, {TextTransparency = 0, BackgroundTransparency = 0}):Play()
    TweenService:Create(LoginBtn, info, {TextTransparency = 0, BackgroundTransparency = 0}):Play()

    -- Draggable
    local dragging, dragInput, dragStart, startPos
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = Main.Position
        end
    end)
    Main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

return AuthUI
