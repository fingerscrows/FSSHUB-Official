-- [[ FSS HUB V3.0 - UNIVERSAL GATEWAY ]] --
-- Fitur: Universal Loader, Secure Hash, UI UX Refined

-- 1. KONFIGURASI UTAMA
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" -- WAJIB SAMA dengan HTML
local UPDATE_INTERVAL = 6                  -- WAJIB SAMA dengan HTML (12 Jam logic)
local DISCORD_INVITE = "https://discord.gg/28cfy5E3ag"
local FILE_NAME = "FSS_V3_Key.txt"

-- 2. DATABASE GAME (Universal Loader)
-- Format: [PlaceID] = "Link Raw Script"
local GameList = {
    -- Masukkan ID Game Survive Wave Z di sini (Ganti 12345... dengan ID asli)
    [92371631484540] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
    
    -- Contoh game lain (bisa ditambah nanti)
    -- [987654321] = "https://raw.github.../BloxFruits.lua",
}

-- Link Default jika game tidak terdaftar (Bisa isi script universal seperti ESP/Walkspeed)
local UNIVERSAL_SCRIPT = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua" 

-- ---------------------------------------------------------

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- 3. SISTEM KEAMANAN (HASHING DJB2)
local function djb2Hash(str)
    local hash = 5381
    for i = 1, #str do
        local byte = string.byte(str, i)
        hash = (hash * 33) + byte
        hash = hash % 4294967296 
    end
    return string.upper(string.format("%x", hash))
end

local function GetCurrentData()
    local now = os.time()
    local totalHours = math.floor(now / 3600)
    local currentBlock = math.floor(totalHours / UPDATE_INTERVAL)
    
    local rawString = currentBlock .. "-" .. SECRET_SALT
    local hash = djb2Hash(rawString)
    local finalKey = "KEY-" .. hash
    
    local nextBlockSeconds = (currentBlock + 1) * UPDATE_INTERVAL * 3600
    local secondsLeft = nextBlockSeconds - now
    
    return finalKey, secondsLeft
end

-- 4. FUNGSI LOAD GAME OTOMATIS
local function LoadGameScript()
    local placeId = game.PlaceId
    local scriptLink = GameList[placeId] or UNIVERSAL_SCRIPT
    
    -- Notifikasi Sistem
    StarterGui:SetCore("SendNotification", {
        Title = "FSS HUB";
        Text = scriptLink == UNIVERSAL_SCRIPT and "Game Unknown, Loading Default..." or "Game Detected! Loading...";
        Duration = 5;
    })
    
    -- Load Script
    local success, err = pcall(function()
        loadstring(game:HttpGet(scriptLink))()
    end)
    
    if not success then
        StarterGui:SetCore("SendNotification", {Title = "Error"; Text = "Failed to load script!"; Duration = 5;})
        warn("FSSHUB Load Error:", err)
    end
end

-- 5. CEK AUTO LOGIN (Saved Key)
local ValidKey, _ = GetCurrentData()
if isfile and isfile(FILE_NAME) then
    if readfile(FILE_NAME) == ValidKey then
        StarterGui:SetCore("SendNotification", {Title = "FSS HUB"; Text = "Key Valid! Auto-loading..."; Duration = 3})
        print("Auto Load Success")
        LoadGameScript()
        return -- Stop render UI jika sudah login
    end
end

-- 6. MODERN UI BUILDER
-- Bersihkan UI Lama
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "FSS_V3_UI" then v:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FSS_V3_UI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125)
MainFrame.Size = UDim2.new(0, 350, 0, 250)

-- Rounded Corner & Stroke
local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 8); Corner.Parent = MainFrame
local Stroke = Instance.new("UIStroke"); Stroke.Parent = MainFrame; Stroke.Color = Color3.fromRGB(0, 255, 136); Stroke.Thickness = 1.5

-- Header
local TopBar = Instance.new("Frame"); TopBar.Parent = MainFrame; TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TopBar.Size = UDim2.new(1, 0, 0, 40); TopBar.BorderSizePixel = 0
local TopCorner = Instance.new("UICorner"); TopCorner.CornerRadius = UDim.new(0, 8); TopCorner.Parent = TopBar
local Filler = Instance.new("Frame"); Filler.Parent = TopBar; Filler.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Filler.BorderSizePixel=0; Filler.Position=UDim2.new(0,0,0.5,0); Filler.Size=UDim2.new(1,0,0.5,0)

local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "FSS HUB | GATEWAY"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Close & Mini
local function CreateCtrlBtn(text, xPos, color)
    local btn = Instance.new("TextButton")
    btn.Parent = TopBar; btn.BackgroundTransparency = 1; btn.Position = UDim2.new(1, xPos, 0, 0); btn.Size = UDim2.new(0, 40, 1, 0)
    btn.Font = Enum.Font.GothamBold; btn.Text = text; btn.TextColor3 = color; btn.TextSize = 16
    return btn
end
local CloseBtn = CreateCtrlBtn("X", -40, Color3.fromRGB(255, 80, 80))
local MiniBtn = CreateCtrlBtn("-", -80, Color3.fromRGB(200, 200, 200))

-- Content
local Content = Instance.new("Frame")
Content.Parent = MainFrame; Content.BackgroundTransparency = 1; Content.Position = UDim2.new(0, 0, 0, 40); Content.Size = UDim2.new(1, 0, 1, -40)

local InfoText = Instance.new("TextLabel")
InfoText.Parent = Content
InfoText.BackgroundTransparency = 1
InfoText.Position = UDim2.new(0, 0, 0.1, 0)
InfoText.Size = UDim2.new(1, 0, 0, 20)
InfoText.Font = Enum.Font.Gotham
-- INSTRUKSI FUNNELING BARU
InfoText.Text = "1. Join Discord  >  2. Get Key  >  3. Paste" 
InfoText.TextColor3 = Color3.fromRGB(150, 150, 150)
InfoText.TextSize = 13

local KeyBox = Instance.new("TextBox")
KeyBox.Parent = Content
KeyBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
KeyBox.Position = UDim2.new(0.1, 0, 0.25, 0)
KeyBox.Size = UDim2.new(0.8, 0, 0, 45)
KeyBox.Font = Enum.Font.GothamBold
KeyBox.PlaceholderText = "Paste Key Here..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(0, 255, 136)
KeyBox.TextSize = 16
local BoxStroke = Instance.new("UIStroke"); BoxStroke.Parent=KeyBox; BoxStroke.Color=Color3.fromRGB(60,60,60); BoxStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
local BoxCorner = Instance.new("UICorner"); BoxCorner.CornerRadius=UDim.new(0,6); BoxCorner.Parent=KeyBox

-- Tombol Aksi
local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Parent = Content
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
GetKeyBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
GetKeyBtn.Size = UDim2.new(0.38, 0, 0, 40)
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.Text = "DISCORD / KEY"
GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyBtn.TextSize = 12
local GkCorner = Instance.new("UICorner"); GkCorner.CornerRadius=UDim.new(0,6); GkCorner.Parent=GetKeyBtn

local EnterBtn = Instance.new("TextButton")
EnterBtn.Parent = Content
EnterBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 136) 
EnterBtn.Position = UDim2.new(0.52, 0, 0.55, 0)
EnterBtn.Size = UDim2.new(0.38, 0, 0, 40)
EnterBtn.Font = Enum.Font.GothamBold
EnterBtn.Text = "UNLOCK"
EnterBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
EnterBtn.TextSize = 14
local EnCorner = Instance.new("UICorner"); EnCorner.CornerRadius=UDim.new(0,6); EnCorner.Parent=EnterBtn

-- Footer (Timer)
local TimerLabel = Instance.new("TextLabel")
TimerLabel.Parent = Content; TimerLabel.BackgroundTransparency = 1; TimerLabel.Position = UDim2.new(0.55, 0, 0.85, 0); TimerLabel.Size = UDim2.new(0.4, 0, 0, 20)
TimerLabel.Font = Enum.Font.Gotham; TimerLabel.Text = "Checking..."; TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80); TimerLabel.TextSize = 12; TimerLabel.TextXAlignment = Enum.TextXAlignment.Right

-- 7. LOGIKA INTERAKSI & FUNNELING
-- Fungsi Draggable
local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    handle.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
    UserInputService.InputChanged:Connect(function(input) if input==dragInput and dragging then update(input) end end)
end
MakeDraggable(MainFrame, TopBar)

-- Minimize Logic
local isMini = false
MiniBtn.MouseButton1Click:Connect(function()
    isMini = not isMini
    if isMini then
        Content.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 350, 0, 40)}):Play()
        MiniBtn.Text = "+"
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 350, 0, 250)}):Play()
        wait(0.2); Content.Visible = true; MiniBtn.Text = "-"
    end
end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- LOGIKA COPY LINK (FUNNELING DISCORD)
GetKeyBtn.MouseButton1Click:Connect(function()
    TweenService:Create(GetKeyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
    wait(0.1)
    TweenService:Create(GetKeyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()

    local clipboardFunc = setclipboard or toclipboard or set_clipboard or (Synapse and Synapse.write_clipboard)
    if clipboardFunc then
        clipboardFunc(DISCORD_INVITE)
        InfoText.Text = "Discord Link Copied! Check #get-key."
        InfoText.TextColor3 = Color3.fromRGB(0, 255, 136)
    else
        InfoText.Text = "Can't Copy! Join Discord Manually."
        InfoText.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
    
    delay(4, function()
        InfoText.Text = "1. Join Discord  >  2. Get Key  >  3. Paste"
        InfoText.TextColor3 = Color3.fromRGB(150, 150, 150)
    end)
end)

-- LOGIKA UNLOCK (DENGAN UNIVERSAL LOADER)
EnterBtn.MouseButton1Click:Connect(function()
    local RealKey, _ = GetCurrentData()
    local input = string.gsub(KeyBox.Text, " ", "")
    
    if input == RealKey then
        InfoText.Text = "Access Granted! Loading..."
        InfoText.TextColor3 = Color3.fromRGB(0, 255, 136)
        
        -- Save Key
        if writefile then writefile(FILE_NAME, input) end
        
        wait(1)
        ScreenGui:Destroy()
        
        -- Panggil Loader
        LoadGameScript()
        
    else
        InfoText.Text = "Incorrect or Expired Key!"
        InfoText.TextColor3 = Color3.fromRGB(255, 50, 50)
        for i=1,5 do MainFrame.Position=MainFrame.Position+UDim2.new(0,4,0,0); wait(0.04); MainFrame.Position=MainFrame.Position-UDim2.new(0,4,0,0); wait(0.04) end
    end
end)

-- Update Timer Loop
task.spawn(function()
    while ScreenGui.Parent do
        local _, secondsLeft = GetCurrentData()
        if secondsLeft > 0 then
            local h = math.floor(secondsLeft / 3600)
            local m = math.floor((secondsLeft % 3600) / 60)
            local s = secondsLeft % 60
            TimerLabel.Text = string.format("Resets in: %02d:%02d:%02d", h, m, s)
        else
            TimerLabel.Text = "Key Expired! Refresh Link."
        end
        wait(1)
    end
end)
