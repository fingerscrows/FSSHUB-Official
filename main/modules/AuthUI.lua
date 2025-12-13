-- [[ FSSHUB AUTH UI V7.8 (FULL INTEGRITY) ]] --
-- Fitur: Smart Input Trimming, Clipboard Support, Responsive UI
-- Path: main/modules/AuthUI.lua

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
    Outline = Color3.fromRGB(45, 45, 55),
    Premium = Color3.fromRGB(255, 215, 0) -- Warna Emas untuk Premium
}

local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN"
end

local isShaking = false
local function Shake(frame)
    if isShaking then return end
    isShaking = true

    local originalPos = frame.Position
    local intensity = 6
    local duration = 0.05

    task.spawn(function()
        for i = 1, 6 do
            local offset = (i % 2 == 0) and intensity or -intensity
            local targetPos = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + offset, originalPos.Y.Scale, originalPos.Y.Offset)
            TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Sine), {Position = targetPos}):Play()
            task.wait(duration)
        end
        TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Sine), {Position = originalPos}):Play()
        isShaking = false
    end)
end

function AuthUI.Show(options)
    -- Gunakan gethui untuk keamanan ekstra jika didukung executor
    local Parent = gethui and gethui() or CoreGui
    
    -- Hapus UI lama jika ada
    if Parent:FindFirstChild("FSSHUB_Auth") then 
        Parent.FSSHUB_Auth:Destroy() 
    end

    local Screen = Instance.new("ScreenGui")
    Screen.Name = "FSSHUB_Auth"
    Screen.Parent = Parent
    Screen.ResetOnSpawn = false
    
    local Main = Instance.new("Frame", Screen)
    Main.BackgroundColor3 = Theme.Bg
    Main.Size = UDim2.new(0, 0, 0, 0) -- Start small for pop-in
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)

    -- Pop-in Animation
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 380, 0, 240)}):Play()
    
    local Corner = Instance.new("UICorner", Main)
    Corner.CornerRadius = UDim.new(0, 12)
    
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Theme.Accent
    Stroke.Thickness = 1.5
    
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
    
    local InputCorner = Instance.new("UICorner", InputBg)
    InputCorner.CornerRadius = UDim.new(0, 8)
    
    local Input = Instance.new("TextBox", InputBg)
    Input.BackgroundTransparency = 1
    Input.Size = UDim2.new(1, -20, 1, 0)
    Input.Position = UDim2.new(0, 10, 0, 0)
    Input.TextColor3 = Theme.Accent
    Input.PlaceholderText = "Paste Key Here..."
    Input.Font = Enum.Font.Code
    Input.TextSize = 14
    Input.Text = "" -- Pastikan kosong saat mulai
    
    local function CreateBtn(text, posScale, func)
        local Btn = Instance.new("TextButton", Main)
        Btn.Text = text
        Btn.Size = UDim2.new(0.4, 0, 0, 35)
        Btn.Position = UDim2.new(posScale, 0, 0.7, 0)
        Btn.BackgroundColor3 = text == "GET KEY" and Theme.Bg or Theme.Accent
        Btn.TextColor3 = text == "GET KEY" and Theme.Text or Color3.new(1,1,1)
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 12
        
        local BtnCorner = Instance.new("UICorner", Btn)
        BtnCorner.CornerRadius = UDim.new(0, 6)
        
        if text == "GET KEY" then 
            local s = Instance.new("UIStroke", Btn)
            s.Color = Theme.Outline
            s.Thickness = 1 
        end

        -- Add Hover Feedback
        Btn.MouseEnter:Connect(function()
            local hoverColor = (text == "GET KEY") and Theme.Bg:Lerp(Color3.new(1,1,1), 0.1) or Theme.Accent:Lerp(Color3.new(1,1,1), 0.1)
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
        end)

        Btn.MouseLeave:Connect(function()
            local baseColor = (text == "GET KEY") and Theme.Bg or Theme.Accent
            TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = baseColor}):Play()
        end)
        
        local isClicking = false
        Btn.MouseButton1Click:Connect(function() 
            if isClicking then return end
            isClicking = true

            -- Add Click Feedback (Bounce)
            local originalSize = Btn.Size
            local targetSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 4, originalSize.Y.Scale, originalSize.Y.Offset - 4)

            TweenService:Create(Btn, TweenInfo.new(0.1), {Size = targetSize}):Play()
            task.wait(0.1)
            TweenService:Create(Btn, TweenInfo.new(0.1), {Size = originalSize}):Play()

            func(Btn)

            -- Wait for the restore animation to finish before allowing another click
            task.wait(0.1)
            isClicking = false
        end)
        
        return Btn
    end
    
    -- TOMBOL GET KEY
    CreateBtn("GET KEY", 0.075, function(btn)
        local hwid = GetHWID()
        local link = "https://fingerscrows.github.io/fsshub-official/?hwid=" .. hwid
        
        if setclipboard then
            setclipboard(link)
            btn.Text = "COPIED!"
            task.delay(1.5, function() btn.Text = "GET KEY" end)
        else
            -- Fallback jika setclipboard tidak support
            Input.Text = link
            btn.Text = "COPY FROM BOX"
        end
    end)
    
    -- TOMBOL LOGIN
    CreateBtn("LOGIN", 0.525, function(btn)
        -- Bersihkan spasi depan/belakang/tengah yang tidak sengaja tercopy
        local txt = Input.Text
        txt = string.gsub(txt, "^%s+", "") -- Hapus spasi depan
        txt = string.gsub(txt, "%s+$", "") -- Hapus spasi belakang
        
        local oldTxt = btn.Text
        local oldColor = btn.BackgroundColor3
        
        btn.Text = "CHECKING..."
        
        -- Panggil callback OnSuccess dari Core
        local result = options.OnSuccess(txt)
        
        if result and result.success then
            Stroke.Color = Theme.Accent
            Title.Text = "ACCESS GRANTED"
            
            -- Cek status user untuk feedback visual
            if result.info and (string.find(result.info, "Premium") or string.find(result.info, "Unlimited")) then
                btn.Text = "👑 PREMIUM"
                btn.BackgroundColor3 = Theme.Premium
                btn.TextColor3 = Color3.fromRGB(0,0,0)
                Stroke.Color = Theme.Premium
            else
                btn.Text = "WELCOME"
            end
            
            task.wait(1.5)
            Screen:Destroy()
        else
            -- Animasi jika gagal
            Shake(Main) -- Visual feedback for error

            btn.Text = oldTxt
            btn.BackgroundColor3 = oldColor
            
            Title.Text = "INVALID KEY"
            -- Tween Colors
            TweenService:Create(Stroke, TweenInfo.new(0.3), {Color = Theme.Error}):Play()
            TweenService:Create(Title, TweenInfo.new(0.3), {TextColor3 = Theme.Error}):Play()
            
            task.wait(1.5)
            
            -- Reset Tampilan
            Title.Text = "FSS HUB | GATEWAY"
            TweenService:Create(Title, TweenInfo.new(0.3), {TextColor3 = Theme.Accent}):Play()
            TweenService:Create(Stroke, TweenInfo.new(0.3), {Color = Theme.Accent}):Play()
        end
    end)
    
    -- Logic Drag (Agar UI bisa digeser)
    local dragging, dragInput, dragStart, startPos
    
    Main.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true
            dragStart = input.Position
            startPos = Main.Position 
        end 
    end)
    
    Main.InputChanged:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseMovement then 
            dragInput = input 
        end 
    end)
    
    UserInputService.InputChanged:Connect(function(input) 
        if input == dragInput and dragging then 
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X, 
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            ) 
        end 
    end)
    
    UserInputService.InputEnded:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false 
        end 
    end)
end

return AuthUI
