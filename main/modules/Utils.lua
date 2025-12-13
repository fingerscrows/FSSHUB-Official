-- [[ FSSHUB MODULE: UTILS V1.2 (HAWK FIXED) ]] --
-- Fitur: Loop Manager, ESP Handler, Physics Tools, Safe Cleanup
-- Path: main/modules/Utils.lua

local Utils = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- [[ 1. LOOP & CONNECTION MANAGER ]] --
Utils.Loops = {}
Utils.Connections = {}

function Utils:BindLoop(name, type, callback)
    self:UnbindLoop(name) -- Bersihkan loop lama dengan nama yang sama
    
    local conn
    if type == "Heartbeat" then
        conn = RunService.Heartbeat:Connect(callback)
    elseif type == "RenderStepped" then
        conn = RunService.RenderStepped:Connect(callback)
    elseif type == "Stepped" then
        conn = RunService.Stepped:Connect(callback)
    end
    
    if conn then
        self.Loops[name] = conn
    end
end

function Utils:UnbindLoop(name)
    if self.Loops[name] then
        self.Loops[name]:Disconnect()
        self.Loops[name] = nil
    end
end

function Utils:Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(self.Connections, conn)
    return conn
end

function Utils:BindKey(keyCode, callback)
    local conn = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == keyCode then
            callback()
        end
    end)
    table.insert(self.Connections, conn)
    return conn
end

-- [[ 2. ESP MANAGER ]] --
Utils.ESP = {
    Cache = {},
    Enabled = false,
    Color = Color3.fromRGB(140, 80, 255)
}

function Utils.ESP:Add(model, settings)
    if not model then return end
    if self.Cache[model] then return end -- Prevent duplicate
    
    local hl = Instance.new("Highlight")
    hl.Name = "FSS_ESP"
    hl.Adornee = model
    hl.FillColor = settings.Color or self.Color
    hl.FillTransparency = settings.FillTransparency or 0.6
    hl.OutlineColor = settings.OutlineColor or Color3.new(1,1,1)
    hl.OutlineTransparency = settings.OutlineTransparency or 0.5
    hl.Parent = model
    
    -- Auto remove jika model hancur
    local conn; conn = model.AncestryChanged:Connect(function(_, parent)
        if not parent then 
            self:Remove(model)
        end
    end)

    -- Store both Highlight and Connection
    self.Cache[model] = {
        Highlight = hl,
        Connection = conn
    }
end

function Utils.ESP:Remove(model)
    local data = self.Cache[model]
    if data then
        if data.Highlight then
            data.Highlight:Destroy()
        end
        if data.Connection then
            data.Connection:Disconnect()
        end
        self.Cache[model] = nil
    end
end

function Utils.ESP:Toggle(state)
    self.Enabled = state
    for _, data in pairs(self.Cache) do
        if data.Highlight then
            data.Highlight.Enabled = state
        end
    end
end

function Utils.ESP:Clear()
    for model, _ in pairs(self.Cache) do
        self:Remove(model)
    end
    self.Cache = {}
end

-- [[ 3. PHYSICS HELPER ]] --
function Utils:Noclip(state)
    self:UnbindLoop("FSS_Noclip")
    if state then
        self:BindLoop("FSS_Noclip", "Stepped", function()
            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end)
    else
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end
end

function Utils:DeepClean()
    -- 1. Putus semua Loop
    for name, _ in pairs(self.Loops) do self:UnbindLoop(name) end
    
    -- 2. Putus semua Event
    for _, conn in ipairs(self.Connections) do 
        if conn.Connected then conn:Disconnect() end 
    end
    self.Connections = {}
    
    -- 3. Bersihkan ESP
    self.ESP:Clear()
    
    -- 4. Reset Fisika Karakter (Anti-Shaking)
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if root then
            root.AssemblyAngularVelocity = Vector3.zero
            root.AssemblyLinearVelocity = Vector3.zero
        end
        
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            
            -- Safety Check: Ensure standing before reset cycle
            if hum.Sit then
                hum.Sit = false -- Force stand
            end
            
            -- Reset Sit State with safe delay
            hum.Sit = true
            task.delay(0.1, function() 
                if hum and hum.Parent and hum.Sit then 
                    hum.Sit = false 
                end 
            end)
        end
    end
    
    print("[FSSHUB] Utils: Deep Clean Complete.")
end

return Utils
