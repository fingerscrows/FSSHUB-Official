-- [[ FSSHUB MODULE: DEBUG CONSOLE ]] --

local Debugger = {}
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")

function Debugger.Show()
    -- Cek Executor GUI Root
    local Parent = gethui and gethui() or CoreGui
    
    -- Bersihkan UI lama jika ada
    if Parent:FindFirstChild("FSSHUB_Console") then
        Parent.FSSHUB_Console:Destroy()
    end

    -- 1. UI SETUP
    local Screen = Instance.new("ScreenGui")
    Screen.Name = "FSSHUB_Console"
    Screen.Parent = Parent
    Screen.ResetOnSpawn = false
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Parent = Screen
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Size = UDim2.new(0, 500, 0, 350)
    Main.Active = true
    Main.Draggable = true 

    -- Stroke Ungu
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Main
    Stroke.Color = Color3.fromRGB(140, 80, 255)
    Stroke.Thickness = 2

    local Corner = Instance.new("UICorner")
    Corner.Parent = Main
    Corner.CornerRadius = UDim.new(0, 8)

    -- Header
    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.Size = UDim2.new(1, -20, 0, 25)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "FSSHUB | DEBUG CONSOLE"
    Title.TextColor3 = Color3.fromRGB(140, 80, 255)
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Container Log (Scrolling Frame)
    local Container = Instance.new("ScrollingFrame")
    Container.Parent = Main
    Container.Active = true
    Container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Container.BorderSizePixel = 0
    Container.Position = UDim2.new(0, 10, 0, 40)
    Container.Size = UDim2.new(1, -20, 1, -50)
    Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    Container.ScrollBarThickness = 4
    Container.ScrollBarImageColor3 = Color3.fromRGB(140, 80, 255)

    local UIList = Instance.new("UIListLayout")
    UIList.Parent = Container
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 2)

    -- Tombol Aksi
    local ButtonHolder = Instance.new("Frame")
    ButtonHolder.Parent = Main
    ButtonHolder.BackgroundTransparency = 1
    ButtonHolder.Position = UDim2.new(0, 10, 1, -35)
    ButtonHolder.Size = UDim2.new(1, -20, 0, 25)

    local function CreateButton(text, pos, callback)
        local Btn = Instance.new("TextButton")
        Btn.Parent = ButtonHolder
        Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        Btn.Size = UDim2.new(0.3, 0, 1, 0)
        Btn.Position = pos
        Btn.Font = Enum.Font.GothamBold
        Btn.Text = text
        Btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        Btn.TextSize = 12
        
        local C = Instance.new("UICorner")
        C.CornerRadius = UDim.new(0, 4)
        C.Parent = Btn
        
        Btn.MouseButton1Click:Connect(callback)
        return Btn
    end

    -- 2. LOGIC LOGGING
    local LogsCache = {} 

    local function AddLog(msg, type)
        if not Main.Parent then return end -- Stop jika GUI sudah close
        
        local Color = Color3.fromRGB(255, 255, 255)
        local Prefix = "[INFO]"
        
        if type == Enum.MessageType.MessageError then
            Color = Color3.fromRGB(255, 65, 65)
            Prefix = "[ERROR]"
        elseif type == Enum.MessageType.MessageWarning then
            Color = Color3.fromRGB(255, 215, 0)
            Prefix = "[WARN]"
        elseif type == Enum.MessageType.MessageOutput then
            Color = Color3.fromRGB(200, 200, 200)
            Prefix = "[PRINT]"
        end
        
        local Time = os.date("%X")
        local FullText = string.format("[%s] %s %s", Time, Prefix, msg)
        table.insert(LogsCache, FullText)
        
        local Label = Instance.new("TextLabel")
        Label.Parent = Container
        Label.BackgroundTransparency = 1
        Label.Size = UDim2.new(1, -5, 0, 0)
        Label.Font = Enum.Font.Code
        Label.Text = FullText
        Label.TextColor3 = Color
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextWrapped = true
        Label.AutomaticSize = Enum.AutomaticSize.Y
        
        Container.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
        Container.CanvasPosition = Vector2.new(0, UIList.AbsoluteContentSize.Y)
    end

    -- Connect ke LogService
    local conn = LogService.MessageOut:Connect(AddLog)

    -- Tombol Fungsi
    CreateButton("CLEAR", UDim2.new(0, 0, 0, 0), function()
        for _, v in pairs(Container:GetChildren()) do
            if v:IsA("TextLabel") then v:Destroy() end
        end
        LogsCache = {}
        Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    end)

    CreateButton("COPY ALL", UDim2.new(0.35, 0, 0, 0), function()
        if setclipboard then
            setclipboard(table.concat(LogsCache, "\n"))
        end
    end)

    CreateButton("CLOSE", UDim2.new(0.7, 0, 0, 0), function()
        if conn then conn:Disconnect() end
        Screen:Destroy()
    end)

    AddLog("FSSHUB Debugger Loaded.", Enum.MessageType.MessageOutput)
end

return Debugger
