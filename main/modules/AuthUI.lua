-- [[ FSSHUB AUTH UI V7 (HWID LINK) ]] --
local AuthUI = {}
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Theme = {
    Bg = Color3.fromRGB(15, 15, 20),
    Accent = Color3.fromRGB(140, 80, 255),
    Text = Color3.fromRGB(240, 240, 240),
    Error = Color3.fromRGB(255, 65, 65),
    Outline = Color3.fromRGB(45, 45, 55)
}

local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN"
end

function AuthUI.Show(options)
    local Parent = gethui and gethui() or CoreGui
    if Parent:FindFirstChild("FSSHUB_Auth") then Parent.FSSHUB_Auth:Destroy() end

    local Screen = Instance.new("ScreenGui")
    Screen.Name = "FSSHUB_Auth"
    Screen.Parent = Parent
    Screen.ResetOnSpawn = false
    
    local Main = Instance.new("Frame", Screen)
    Main.BackgroundColor3 = Theme.Bg
    Main.Size = UDim2.new(0, 380, 0, 240)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local Corner = Instance.new("UICorner", Main); Corner.CornerRadius = UDim.new(0, 12)
    local Stroke = Instance.new("UIStroke", Main); Stroke.Color = Theme.Accent; Stroke.Thickness = 1.5
    
    local Title = Instance.new("TextLabel", Main)
    Title.Text = "FSS HUB | GATEWAY"
    Title.TextColor3 = Theme.Accent
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 24
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 20)
    Title.BackgroundTransparency = 1
    
    local InputBg = Instance.new("Frame", Main)
    InputBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    InputBg.Size = UDim2.new(0.85, 0, 0, 45)
    InputBg.Position = UDim2.new(0.075, 0, 0.38, 0)
    Instance.new("UICorner", InputBg).CornerRadius = UDim.new(0, 8)
    
    local Input = Instance.new("TextBox", InputBg)
    Input.BackgroundTransparency = 1
    Input.Size = UDim2.new(1, -20, 1, 0)
    Input.Position = UDim2.new(0, 10, 0, 0)
    Input.TextColor3 = Theme.Accent
    Input.PlaceholderText = "Paste Key Here..."
    Input.Font = Enum.Font.Code
    Input.TextSize = 14
    
    local function CreateBtn(text, posScale, func)
        local Btn = Instance.new("TextButton", Main)
        Btn.Text = text
        Btn.Size = UDim2.new(0.4, 0, 0, 35)
        Btn.Position = UDim2.new(posScale, 0, 0.7, 0)
        Btn.BackgroundColor3 = text == "GET KEY" and Theme.Bg or Theme.Accent
        Btn.TextColor3 = text == "GET KEY" and Theme.Text or Color3.new(1,1,1)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 12
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
        if text == "GET KEY" then 
            local s = Instance.new("UIStroke", Btn); s.Color = Theme.Outline; s.Thickness = 1 
        end
        Btn.MouseButton1Click:Connect(function() func(Btn) end)
        return Btn
    end
    
    -- TOMBOL GET KEY
    CreateBtn("GET KEY", 0.075, function(btn)
        local hwid = GetHWID()
        local link = "https://fingerscrows.github.io/fsshub-official/?hwid=" .. hwid
        
        setclipboard(link)
        btn.Text = "COPIED!"
        task.delay(1.5, function() btn.Text = "GET KEY" end)
    end)
    
    -- TOMBOL LOGIN
    CreateBtn("LOGIN", 0.525, function(btn)
        local txt = string.gsub(Input.Text, "%s+", "")
        local oldTxt = btn.Text
        btn.Text = "CHECKING..."
        
        local valid = options.OnSuccess(txt)
        
        if valid then
            Title.Text = "SUCCESS!"
            Stroke.Color = Theme.Accent
            btn.Text = "ALLOWED"
            task.wait(0.5)
            Screen:Destroy()
        else
            btn.Text = oldTxt
            Title.Text = "INVALID KEY"
            Stroke.Color = Theme.Error
            Title.TextColor3 = Theme.Error
            task.wait(1.5)
            Title.Text = "FSS HUB | GATEWAY"
            Title.TextColor3 = Theme.Accent
            Stroke.Color = Theme.Accent
        end
    end)
    
    local dragging, dragInput, dragStart, startPos
    Main.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = Main.Position end end)
    Main.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

return AuthUI
