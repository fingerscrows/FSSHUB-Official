-- [[ FSS HUB V3.2 - ROBUST UNIVERSAL LOADER ]] --
-- Fitur: Dual ID Check (Place/Universe), String Matching, & Debugger

-- 1. KONFIGURASI UTAMA
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" -- WAJIB SAMA dengan HTML
local UPDATE_INTERVAL = 6                  
local DISCORD_INVITE = "https://discord.gg/28cfy5E3ag"
local FILE_NAME = "FSS_V3_Key.txt"

-- 2. DATABASE GAME (Gunakan String "" untuk ID agar akurat)
local GameList = {
    -- Masukkan Place ID ATAU Universe ID di sini
    -- Contoh ID Survive Wave Z (kamu bisa masukkan keduanya biar aman)
    ["92371631484540"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
    ["123456789"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
}

-- Link Default (Script yang diload jika game tidak dikenali)
local UNIVERSAL_SCRIPT = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua" 

-- ---------------------------------------------------------
-- SERVICES
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

-- 3. HELPER FUNCTIONS (HASHING)
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
    return "KEY-" .. hash, ((currentBlock + 1) * UPDATE_INTERVAL * 3600) - now
end

-- 4. FUNGSI LOAD GAME (LOGIKA BARU)
local function LoadGameScript()
    -- Ambil ID sebagai String untuk menghindari error pembulatan angka besar
    local PlaceID = tostring(game.PlaceId)
    local GameID = tostring(game.GameId)
    
    -- Debugging ke Console (Tekan F9 untuk lihat)
    warn("------------------------------------------------")
    warn("[FSSHUB DEBUG] Checking ID...")
    warn("[FSSHUB DEBUG] Place ID: " .. PlaceID)
    warn("[FSSHUB DEBUG] Game ID (Universe): " .. GameID)
    warn("------------------------------------------------")
    
    -- Cek apakah salah satu ID ada di daftar
    local Link = GameList[PlaceID] or GameList[GameID]
    
    if Link then
        StarterGui:SetCore("SendNotification", {Title = "FSS HUB"; Text = "Game Detected! Loading Script..."; Duration = 5;})
        local s, err = pcall(function() loadstring(game:HttpGet(Link))() end)
        if not s then warn("Script Load Error: "..tostring(err)) end
    else
        -- Jika tidak dikenal, beritahu user ID mereka (untuk lapor ke dev)
        StarterGui:SetCore("SendNotification", {
            Title = "ID Unknown"; 
            Text = "PID: " .. PlaceID .. "\nGID: " .. GameID; 
            Duration = 10;
        })
        warn("[FSSHUB] ID not found in GameList. Loading Universal.")
        
        -- Load Universal agar user tetap bisa main
        loadstring(game:HttpGet(UNIVERSAL_SCRIPT))()
    end
end

-- 5. CEK AUTO LOGIN
local ValidKey, _ = GetCurrentData()
if isfile and isfile(FILE_NAME) then
    if readfile(FILE_NAME) == ValidKey then
        StarterGui:SetCore("SendNotification", {Title = "FSS HUB"; Text = "Key Valid! Auto-loading..."; Duration = 3})
        LoadGameScript()
        return 
    end
end

-- 6. UI BUILDER (INTERFACE)
for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "FSS_V3_UI" then v:Destroy() end end
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "FSS_V3_UI"; ScreenGui.Parent = CoreGui; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame"); MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18); MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125); MainFrame.Size = UDim2.new(0, 350, 0, 250)
local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 8); Corner.Parent = MainFrame
local Stroke = Instance.new("UIStroke"); Stroke.Parent = MainFrame; Stroke.Color = Color3.fromRGB(0, 255, 136); Stroke.Thickness = 1.5

local TopBar = Instance.new("Frame"); TopBar.Parent = MainFrame; TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TopBar.Size = UDim2.new(1, 0, 0, 40); Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)
local Title = Instance.new("TextLabel"); Title.Parent = TopBar; Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 15, 0, 0); Title.Size = UDim2.new(0, 200, 1, 0); Title.Font = Enum.Font.GothamBold; Title.Text = "FSS HUB | GATEWAY"; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left
local CloseBtn = Instance.new("TextButton"); CloseBtn.Parent = TopBar; CloseBtn.BackgroundTransparency=1; CloseBtn.Position=UDim2.new(1,-40,0,0); CloseBtn.Size=UDim2.new(0,40,1,0); CloseBtn.Text="X"; CloseBtn.TextColor3=Color3.fromRGB(255,80,80); CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=16

local Content = Instance.new("Frame"); Content.Parent = MainFrame; Content.BackgroundTransparency = 1; Content.Position = UDim2.new(0, 0, 0, 40); Content.Size = UDim2.new(1, 0, 1, -40)
local InfoText = Instance.new("TextLabel"); InfoText.Parent = Content; InfoText.BackgroundTransparency = 1; InfoText.Position = UDim2.new(0, 0, 0.1, 0); InfoText.Size = UDim2.new(1, 0, 0, 20); InfoText.Font = Enum.Font.Gotham; InfoText.Text = "1. Join Discord > 2. Get Key > 3. Paste"; InfoText.TextColor3 = Color3.fromRGB(150, 150, 150); InfoText.TextSize = 13

local KeyBox = Instance.new("TextBox"); KeyBox.Parent = Content; KeyBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10); KeyBox.Position = UDim2.new(0.1, 0, 0.25, 0); KeyBox.Size = UDim2.new(0.8, 0, 0, 45); KeyBox.Font = Enum.Font.GothamBold; KeyBox.PlaceholderText = "Paste Key Here..."; KeyBox.Text = ""; KeyBox.TextColor3 = Color3.fromRGB(0, 255, 136); KeyBox.TextSize = 16; Instance.new("UICorner", KeyBox).CornerRadius=UDim.new(0,6); Instance.new("UIStroke", KeyBox).Color=Color3.fromRGB(60,60,60)
local GetKeyBtn = Instance.new("TextButton"); GetKeyBtn.Parent = Content; GetKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); GetKeyBtn.Position = UDim2.new(0.1, 0, 0.55, 0); GetKeyBtn.Size = UDim2.new(0.38, 0, 0, 40); GetKeyBtn.Font = Enum.Font.GothamBold; GetKeyBtn.Text = "GET KEY LINK"; GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255); GetKeyBtn.TextSize = 12; Instance.new("UICorner", GetKeyBtn).CornerRadius=UDim.new(0,6)
local EnterBtn = Instance.new("TextButton"); EnterBtn.Parent = Content; EnterBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 136); EnterBtn.Position = UDim2.new(0.52, 0, 0.55, 0); EnterBtn.Size = UDim2.new(0.38, 0, 0, 40); EnterBtn.Font = Enum.Font.GothamBold; EnterBtn.Text = "UNLOCK"; EnterBtn.TextColor3 = Color3.fromRGB(20, 20, 20); EnterBtn.TextSize = 14; Instance.new("UICorner", EnterBtn).CornerRadius=UDim.new(0,6)

-- Footer (Timer)
local TimerLabel = Instance.new("TextLabel"); TimerLabel.Parent = Content; TimerLabel.BackgroundTransparency = 1; TimerLabel.Position = UDim2.new(0.55, 0, 0.85, 0); TimerLabel.Size = UDim2.new(0.4, 0, 0, 20); TimerLabel.Font = Enum.Font.Gotham; TimerLabel.Text = "Checking..."; TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80); TimerLabel.TextSize = 12; TimerLabel.TextXAlignment = Enum.TextXAlignment.Right

-- LOGIC UI
local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = frame.Position end end)
    handle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end
MakeDraggable(MainFrame, TopBar)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

GetKeyBtn.MouseButton1Click:Connect(function()
    if setclipboard then setclipboard(DISCORD_INVITE); InfoText.Text = "Link Copied! Check Discord."; InfoText.TextColor3 = Color3.fromRGB(0, 255, 136) else InfoText.Text = "Error Copying Link!"; InfoText.TextColor3 = Color3.fromRGB(255, 50, 50) end
    delay(3, function() InfoText.Text = "1. Join Discord > 2. Get Key > 3. Paste"; InfoText.TextColor3 = Color3.fromRGB(150, 150, 150) end)
end)

EnterBtn.MouseButton1Click:Connect(function()
    local RealKey, _ = GetCurrentData()
    -- Hapus spasi agar input lebih toleran
    local inputClean = string.gsub(KeyBox.Text, " ", "")
    if inputClean == RealKey then
        InfoText.Text = "Success! Loading..."
        InfoText.TextColor3 = Color3.fromRGB(0, 255, 136)
        if writefile then writefile(FILE_NAME, inputClean) end
        wait(1)
        ScreenGui:Destroy()
        LoadGameScript()
    else
        InfoText.Text = "Invalid Key!"; InfoText.TextColor3 = Color3.fromRGB(255, 50, 50)
        for i=1,5 do MainFrame.Position=MainFrame.Position+UDim2.new(0,4,0,0); wait(0.04); MainFrame.Position=MainFrame.Position-UDim2.new(0,4,0,0); wait(0.04) end
    end
end)

-- TIMER LOOP
task.spawn(function()
    while ScreenGui.Parent do
        local _, secondsLeft = GetCurrentData()
        if secondsLeft > 0 then
            local h = math.floor(secondsLeft / 3600); local m = math.floor((secondsLeft % 3600) / 60); local s = secondsLeft % 60
            TimerLabel.Text = string.format("Resets in: %02d:%02d:%02d", h, m, s)
        else
            TimerLabel.Text = "Key Expired! Refresh Link."
        end
        wait(1)
    end
end)
