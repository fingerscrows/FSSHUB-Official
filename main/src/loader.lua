-- [[ FSS HUB V3.6 - SAFE LOADER (FULL OPTIMIZED) ]] --
-- Update: Smart Parent Detection (gethui), Retry System, Task Library

-- 0. TUNGGU GAME LOAD (Wajib agar tidak error GUI)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 1. KONFIGURASI UTAMA
local SECRET_SALT = "RAHASIA_FINAL_KAMU_123" -- WAJIB SAMA dengan HTML
local UPDATE_INTERVAL = 6 -- Jam                 
local DISCORD_INVITE = "https://discord.gg/28cfy5E3ag"
local FILE_NAME = "FSS_V3_Key.txt"

-- 2. DATABASE GAME
local GameList = {
    -- [Place ID / Game ID] = Link Script Raw
    ["92371631484540"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
    ["9168386959"] = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua",
}
-- Default Script jika game tidak dikenal
local UNIVERSAL_SCRIPT = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/scripts/SurviveWaveZ.lua" 

-- SERVICES
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 3. FUNGSI UTILITAS
local function GetSafeGui()
    -- Prioritas 1: gethui (Executor Modern - Hidden)
    if gethui then
        local s, r = pcall(gethui)
        if s and r and r:IsA("Instance") then return r end
    end

    -- Prioritas 2: CoreGui (System GUI)
    if CoreGui then
        local s, r = pcall(function() return CoreGui end)
        if s and r then return r end
    end

    -- Prioritas 3: PlayerGui (Fallback Terakhir)
    if LocalPlayer then
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then return pGui end
        local s, r = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 5) end)
        if s and r then return r end
    end
    
    return nil
end

local function SafeLoad(url)
    local content = nil
    local success = false
    
    -- Retry System (Coba 3x)
    for i = 1, 3 do
        local s, res = pcall(function() return game:HttpGet(url) end)
        if s then
            content = res
            success = true
            break
        else
            warn("[FSSHUB] Gagal download script, mencoba ulang... ("..i.."/3)")
            task.wait(1.5)
        end
    end
    
    if success and content then
        local loadFunc, err = loadstring(content)
        if loadFunc then
            task.spawn(loadFunc)
        else
            warn("[FSSHUB] Syntax Error pada script target: "..tostring(err))
            StarterGui:SetCore("SendNotification", {Title = "FSS HUB"; Text = "Script Error! Cek Console (F9)"; Duration = 5})
        end
    else
        StarterGui:SetCore("SendNotification", {Title = "FSS HUB Error"; Text = "Gagal koneksi ke server script!"; Duration = 5})
    end
end

-- 4. LOGIKA KEY SYSTEM (Hashing)
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

-- 5. INITIALIZE LOADER
local function InitLoader()
    local ParentTarget = GetSafeGui()
    if not ParentTarget then return warn("[FSSHUB CRITICAL] GUI Parent not found!") end
    
    -- Cek Key yang tersimpan di file
    local ValidKey, _ = GetCurrentData()
    if isfile and isfile(FILE_NAME) then
        local savedKey = readfile(FILE_NAME)
        -- Hapus spasi/newline yang mungkin ikut tersimpan
        savedKey = string.gsub(savedKey, "%s+", "")
        
        if savedKey == ValidKey then
            StarterGui:SetCore("SendNotification", {Title = "FSS HUB"; Text = "Key Valid! Auto-loading..."; Duration = 3})
            
            local PlaceID = tostring(game.PlaceId)
            local GameID = tostring(game.GameId)
            local Link = GameList[PlaceID] or GameList[GameID] or UNIVERSAL_SCRIPT
            
            SafeLoad(Link)
            return
        end
    end

    -- --- JIKA KEY TIDAK ADA / SALAH, BUILD UI ---
    
    -- Bersihkan UI lama
    for _, v in pairs(ParentTarget:GetChildren()) do 
        if v.Name == "FSS_V3_UI" then v:Destroy() end 
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FSS_V3_UI"
    ScreenGui.Parent = ParentTarget
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    -- Jika masuk PlayerGui, set DisplayOrder tinggi agar di atas UI game
    if ScreenGui.Parent:IsA("PlayerGui") then ScreenGui.DisplayOrder = 9999 end

    -- [UI CONSTRUCTION]
    local MainFrame = Instance.new("Frame"); MainFrame.Name = "MainFrame"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18); MainFrame.Position = UDim2.new(0.5, -175, 0.5, -125); MainFrame.Size = UDim2.new(0, 350, 0, 250); Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke"); MainStroke.Parent = MainFrame; MainStroke.Color = Color3.fromRGB(0, 255, 136); MainStroke.Thickness = 1.5; MainStroke.Transparency = 0.2
    
    local TopBar = Instance.new("Frame"); TopBar.Parent = MainFrame; TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TopBar.Size = UDim2.new(1, 0, 0, 40); Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)
    -- Filler untuk menutup rounded corner bawah topbar
    local TopBarFiller = Instance.new("Frame"); TopBarFiller.Parent = TopBar; TopBarFiller.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TopBarFiller.Size = UDim2.new(1, 0, 0, 10); TopBarFiller.Position = UDim2.new(0,0,1,-10); TopBarFiller.BorderSizePixel = 0
    
    local Title = Instance.new("TextLabel"); Title.Parent = TopBar; Title.Text = "FSS HUB | GATEWAY"; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.Font = Enum.Font.GothamBold; Title.Size = UDim2.new(0, 200, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.TextSize = 14
    local CloseBtn = Instance.new("TextButton"); CloseBtn.Parent = TopBar; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.Size = UDim2.new(0, 40, 1, 0); CloseBtn.Position = UDim2.new(1, -40, 0, 0); CloseBtn.BackgroundTransparency = 1; CloseBtn.TextSize = 16

    local Content = Instance.new("Frame"); Content.Parent = MainFrame; Content.BackgroundTransparency = 1; Content.Position = UDim2.new(0, 0, 0, 40); Content.Size = UDim2.new(1, 0, 1, -40)
    local InfoText = Instance.new("TextLabel"); InfoText.Parent = Content; InfoText.Text = "1. Join Discord > 2. Get Key > 3. Paste"; InfoText.TextColor3 = Color3.fromRGB(150, 150, 150); InfoText.Size = UDim2.new(1, 0, 0, 20); InfoText.Position = UDim2.new(0, 0, 0.1, 0); InfoText.BackgroundTransparency = 1; InfoText.Font = Enum.Font.Gotham; InfoText.TextSize = 13

    local KeyBox = Instance.new("TextBox"); KeyBox.Parent = Content; KeyBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10); KeyBox.Position = UDim2.new(0.1, 0, 0.25, 0); KeyBox.Size = UDim2.new(0.8, 0, 0, 45); KeyBox.Text = ""; KeyBox.PlaceholderText = "Paste Key Here..."; KeyBox.TextColor3 = Color3.fromRGB(0, 255, 136); KeyBox.Font = Enum.Font.GothamBold; KeyBox.TextSize = 14; Instance.new("UICorner", KeyBox).CornerRadius=UDim.new(0,6); Instance.new("UIStroke", KeyBox).Color=Color3.fromRGB(60,60,60)
    
    local GetKeyBtn = Instance.new("TextButton"); GetKeyBtn.Parent = Content; GetKeyBtn.Text = "GET KEY LINK"; GetKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255); GetKeyBtn.Font = Enum.Font.GothamBold; GetKeyBtn.Size = UDim2.new(0.38, 0, 0, 40); GetKeyBtn.Position = UDim2.new(0.1, 0, 0.55, 0); GetKeyBtn.TextSize = 12; Instance.new("UICorner", GetKeyBtn).CornerRadius=UDim.new(0,6)
    local EnterBtn = Instance.new("TextButton"); EnterBtn.Parent = Content; EnterBtn.Text = "UNLOCK"; EnterBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 136); EnterBtn.TextColor3 = Color3.fromRGB(20, 20, 20); EnterBtn.Font = Enum.Font.GothamBold; EnterBtn.Size = UDim2.new(0.38, 0, 0, 40); EnterBtn.Position = UDim2.new(0.52, 0, 0.55, 0); EnterBtn.TextSize = 14; Instance.new("UICorner", EnterBtn).CornerRadius=UDim.new(0,6)
    local TimerLabel = Instance.new("TextLabel"); TimerLabel.Parent = Content; TimerLabel.Text = "Checking..."; TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80); TimerLabel.Font = Enum.Font.Gotham; TimerLabel.Size = UDim2.new(0.4, 0, 0, 20); TimerLabel.Position = UDim2.new(0.55, 0, 0.85, 0); TimerLabel.BackgroundTransparency = 1; TimerLabel.TextXAlignment = Enum.TextXAlignment.Right; TimerLabel.TextSize = 12

    -- DRAG LOGIC
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end end)
    TopBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
    
    GetKeyBtn.MouseButton1Click:Connect(function() 
        if setclipboard then 
            setclipboard(DISCORD_INVITE)
            InfoText.Text = "Link Copied! Check Discord."
            InfoText.TextColor3 = Color3.fromRGB(0, 255, 136)
        else 
            InfoText.Text = "Error: Cannot copy link!"
            InfoText.TextColor3 = Color3.fromRGB(255, 50, 50)
        end 
        task.delay(3, function() 
            InfoText.Text = "1. Join Discord > 2. Get Key > 3. Paste"
            InfoText.TextColor3 = Color3.fromRGB(150, 150, 150)
        end) 
    end)

    EnterBtn.MouseButton1Click:Connect(function()
        local RealKey, _ = GetCurrentData()
        -- Hapus spasi dari input user
        local inputClean = string.gsub(KeyBox.Text, " ", "")
        
        if inputClean == RealKey then
            InfoText.Text = "Success! Loading..."
            InfoText.TextColor3 = Color3.fromRGB(0, 255, 136)
            
            -- Simpan Key
            if writefile then writefile(FILE_NAME, inputClean) end
            
            task.wait(1)
            ScreenGui:Destroy()
            
            -- Load Game
            local PlaceID = tostring(game.PlaceId)
            local GameID = tostring(game.GameId)
            local Link = GameList[PlaceID] or GameList[GameID] or UNIVERSAL_SCRIPT
            SafeLoad(Link)
        else
            InfoText.Text = "Invalid Key!"; InfoText.TextColor3 = Color3.fromRGB(255, 50, 50)
            -- Efek Getar (Shake)
            for i=1,5 do 
                MainFrame.Position = MainFrame.Position + UDim2.new(0, 4, 0, 0)
                task.wait(0.04)
                MainFrame.Position = MainFrame.Position - UDim2.new(0, 4, 0, 0)
                task.wait(0.04)
            end
        end
    end)

    -- Timer Update Loop
    task.spawn(function()
        while ScreenGui.Parent do
            local _, secondsLeft = GetCurrentData()
            if secondsLeft > 0 then
                local h = math.floor(secondsLeft / 3600)
                local m = math.floor((secondsLeft % 3600) / 60)
                local s = secondsLeft % 60
                TimerLabel.Text = string.format("Resets in: %02d:%02d:%02d", h, m, s)
            else
                TimerLabel.Text = "Key Expired!"
            end
            task.wait(1)
        end
    end)
end

-- JALANKAN LOADER
InitLoader()
