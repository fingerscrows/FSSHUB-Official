-- [[ FSS HUB V3.3 - SAFE LOADER (Xeno Support) ]] --
-- Fitur: Anti-Crash CoreGui, String ID Check, & Debug Mode

-- 1. KONFIGURASI UTAMA
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" -- WAJIB SAMA dengan HTML
local UPDATE_INTERVAL = 6                  
local DISCORD_INVITE = "https://discord.gg/28cfy5E3ag"
local FILE_NAME = "FSS_V3_Key.txt"

-- 2. DATABASE GAME (String ID)
local GameList = {
    -- Masukkan Place ID dan Universe ID (Game ID) sebagai String
    ["92371631484540"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
}

-- Link Default
local UNIVERSAL_SCRIPT = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua" 

-- ---------------------------------------------------------
-- SERVICES (AMANKAN CORE GUI)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- FUNGSI MENCARI UI PARENT YANG AMAN (Anti-Crash Xeno)
local function GetSafeGui()
    -- 1. Coba gethui (Executor Modern)
    if gethui then
        local s, r = pcall(gethui)
        if s and r and r:IsA("Instance") then return r end
    end
    -- 2. Coba CoreGui dengan pcall
    local s, core = pcall(function() return game:GetService("CoreGui") end)
    if s and core then return core end
    
    -- 3. Fallback ke PlayerGui (Pasti Aman)
    if Players.LocalPlayer then
        return Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    return nil
end

local ParentTarget = GetSafeGui()
if not ParentTarget then
    -- Jika benar-benar tidak ada tempat menaruh UI (sangat jarang), stop script
    warn("[FSSHUB CRITICAL] Cannot find GUI Parent!")
    return 
end

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

-- 4. FUNGSI LOAD GAME
local function LoadGameScript()
    local PlaceID = tostring(game.PlaceId)
    local GameID = tostring(game.GameId)
    
    -- Debugging
    warn("------------------------------------------------")
    warn("[FSSHUB DEBUG] Checking ID...")
    warn("[FSSHUB DEBUG] Place ID: " .. PlaceID)
    warn("[FSSHUB DEBUG] Game ID: " .. GameID)
    warn("------------------------------------------------")
    
    local Link = GameList[PlaceID] or GameList[GameID]
    
    if Link then
        StarterGui:SetCore("SendNotification", {Title = "FSS HUB"; Text = "Game Detected! Loading..."; Duration = 5;})
        local s, err = pcall(function() loadstring(game:HttpGet(Link))() end)
        if not s then 
            warn("Script Load Error: "..tostring(err)) 
            StarterGui:SetCore("SendNotification", {Title = "FSS HUB"; Text = "Failed to load script!"; Duration = 5;})
        end
    else
        StarterGui:SetCore("SendNotification", {
            Title = "ID Unknown"; 
            Text = "Loading Default Script..."; 
            Duration = 5;
        })
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
-- Hapus UI lama di target parent
for _, v in pairs(ParentTarget:GetChildren()) do 
    if v.Name == "FSS_V3_UI" then v:Destroy() end 
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FSS_V3_UI"
ScreenGui.Parent = ParentTarget
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999 -- Pastikan di paling atas

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
