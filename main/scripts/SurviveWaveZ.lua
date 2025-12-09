-- [[ FSSHUB: SURVIVE WAVE Z SCRIPT (FULL RESTORED & OPTIMIZED) ]] --
-- Update: Fixed Bring Mobs Lag, Restored HipHeight/Keybinds, Task Library

-- 1. SETUP & SAFETY
if not game:IsLoaded() then game.Loaded:Wait() end
local StarterGui = game:GetService("StarterGui")

-- Notifikasi Awal
StarterGui:SetCore("SendNotification", {Title = "FSSHUB", Text = "Loading Script...", Duration = 2})

-- Load Library dengan Retry System
local LibraryUrl = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local success, Library
for i=1,3 do
    local s, res = pcall(function() return loadstring(game:HttpGet(LibraryUrl))() end)
    if s then success = true; Library = res; break end
    task.wait(1)
end

if not success or not Library then
    return StarterGui:SetCore("SendNotification", {Title = "CRITICAL ERROR", Text = "Library Failed to Load!", Duration = 5})
end

-- 2. VARIABLES & SERVICES
local Win = Library:Window("FSSHUB | Survive Wave Z")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera

-- Konfigurasi Default
local Config = {
    Dist = 10,
    Height = 1,
    AimbotRadius = 300
}

-- 3. FITUR GAME
Win:Section("COMBAT")

Win:Toggle("Aimbot (Head)", false, function(t)
    local aimbotOn = t
    if t then
        local aimConnection = RunService.RenderStepped:Connect(function()
            if not aimbotOn then return end
            
            local closestHead = nil
            local minMag = Config.AimbotRadius
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            
            -- Optimasi: Cek folder langsung jika ada
            local zombieFolder = Workspace:FindFirstChild("ServerZombies")
            if zombieFolder then
                for _, zombie in ipairs(zombieFolder:GetChildren()) do
                    local head = zombie:FindFirstChild("Head")
                    local hum = zombie:FindFirstChild("Humanoid")
                    
                    if head and hum and hum.Health > 0 then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local mag = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if mag < minMag then
                                minMag = mag
                                closestHead = head
                            end
                        end
                    end
                end
            end
            
            if closestHead then 
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, closestHead.Position) 
            end
        end)
        table.insert(Library.ActiveConnections, aimConnection)
    end
end)

Win:Toggle("Auto Attack", false, function(t)
    local shootOn = t
    -- Reset atribut saat dimatikan agar animasi berhenti
    if not t and LocalPlayer.Character then 
        local gun = LocalPlayer.Character:FindFirstChildOfClass("Model")
        if gun then gun:SetAttribute("IsShooting", false) end 
    end

    if t then
        task.spawn(function()
            while shootOn do
                task.wait() -- Loop secepat mungkin (Render Speed)
                if LocalPlayer.Character then
                    local gun = LocalPlayer.Character:FindFirstChildOfClass("Model")
                    -- Cek apakah model tersebut memiliki Handle (indikasi senjata)
                    if gun and gun:FindFirstChild("Handle") then
                         gun:SetAttribute("IsShooting", true)
                         if gun:FindFirstChild("Activate") then gun:Activate() end
                         
                         -- Support untuk Tool biasa
                         local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                         if tool then tool:Activate() end
                    end
                end
            end
            -- Cleanup saat loop berhenti
            if LocalPlayer.Character then
                local gun = LocalPlayer.Character:FindFirstChildOfClass("Model")
                if gun then gun:SetAttribute("IsShooting", false) end
            end
        end)
    end
end)

Win:Section("MOBS (Optimized)")

Win:Toggle("Bring Mobs", false, function(t)
    local bringOn = t
    if t then
        local connection = RunService.Heartbeat:Connect(function()
            if not bringOn then return end
            
            -- Optimasi: Hindari GetDescendants. Cek folder zombie langsung.
            local zFolder = Workspace:FindFirstChild("ServerZombies")
            if not zFolder then return end

            local myChar = LocalPlayer.Character
            if not myChar then return end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end

            local myPos = myRoot.Position
            local targetPos = myRoot.CFrame.Position + (myRoot.CFrame.LookVector * Config.Dist) + Vector3.new(0, Config.Height, 0)
            
            for _, z in ipairs(zFolder:GetChildren()) do
                local zRoot = z:FindFirstChild("RootPart") or z:FindFirstChild("HumanoidRootPart")
                local zHum = z:FindFirstChild("Humanoid")
                
                -- Hanya tarik zombie dalam radius 250 stud agar game tidak crash/lag parah
                if zRoot and zHum and zHum.Health > 0 and (zRoot.Position - myPos).Magnitude < 250 then
                    -- Metode CFrame (Lebih ringan & stabil dibanding ubah State Physics)
                    zRoot.CFrame = CFrame.lookAt(targetPos, myPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    zRoot.AssemblyLinearVelocity = Vector3.zero
                    zRoot.AssemblyAngularVelocity = Vector3.zero
                    
                    -- Matikan collision zombie agar tidak menumpuk dan meledak
                    if not z:GetAttribute("NoCol") then
                        for _, p in ipairs(z:GetChildren()) do 
                            if p:IsA("BasePart") then p.CanCollide = false end 
                        end
                        z:SetAttribute("NoCol", true)
                    end
                end
            end
        end)
        table.insert(Library.ActiveConnections, connection)
    end
end)

Win:Slider("Distance", 1, 20, 10, function(v) Config.Dist = v end, false)
Win:Slider("Height", -5, 5, 1, function(v) Config.Height = v end, false)

Win:Section("PLAYER")

Win:Toggle("Auto Loot", false, function(t)
    local collectOn = t
    if t then
        task.spawn(function()
            while collectOn do
                task.wait(0.2)
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    -- Loop Workspace anak langsung (bukan descendants)
                    for _, p in ipairs(Workspace:GetChildren()) do
                        if not collectOn then break end
                        if p.Name == "RewardChest" or p.Name == "AmmoBox" or p.Name == "MysteryBox" or p.Name == "Pickup" then
                             if p:IsA("Model") and p.PrimaryPart then
                                 p:SetPrimaryPartCFrame(myRoot.CFrame)
                             elseif p:IsA("Part") or p:IsA("MeshPart") then
                                 p.CFrame = myRoot.CFrame
                             end
                        end
                    end
                end
            end
        end)
    end
end)

Win:Toggle("Auto Revive", false, function(t)
    local reviveOn = t
    if t then
        task.spawn(function()
            while reviveOn do
                task.wait(0.5)
                pcall(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                         for _, plr in ipairs(Players:GetPlayers()) do
                            if plr ~= LocalPlayer and plr.Character then
                                local tHum = plr.Character:FindFirstChild("Humanoid")
                                if tHum and tHum.Health <= 0 then
                                    -- Cari Prompt Revive
                                    local prompt = plr.Character:FindFirstChild("RevivePrompt", true)
                                    if prompt and prompt:IsA("ProximityPrompt") then
                                        -- Teleport ke teman
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                                        task.wait(0.2)
                                        -- Instant Proximity Trigger
                                        prompt.HoldDuration = 0
                                        fireproximityprompt(prompt, 1, true)
                                    end
                                end
                            end
                         end
                    end
                end)
            end
        end)
    end
end)

-- [RESTORED] HipHeight Slider
Win:Slider("HipHeight", 0, 50, 2, function(v)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.HipHeight = v
    end
end, false)

Win:Section("VISUAL")
Win:Toggle("ESP Head", false, function(t)
    local espOn = t
    if t then
        task.spawn(function()
            while espOn do
                task.wait(1)
                local zFolder = Workspace:FindFirstChild("ServerZombies")
                if zFolder then
                    for _, z in ipairs(zFolder:GetChildren()) do
                        local head = z:FindFirstChild("Head")
                        local hum = z:FindFirstChild("Humanoid")
                        if head and hum and hum.Health > 0 then
                            if not head:FindFirstChild("H_ESP") then
                                local b = Instance.new("BoxHandleAdornment", head)
                                b.Name = "H_ESP"; b.Adornee = head; b.Size = head.Size + Vector3.new(0.5, 0.5, 0.5)
                                b.Color3 = Color3.fromRGB(255, 0, 0); b.AlwaysOnTop = true; b.Transparency = 0.4; b.ZIndex = 5
                            end
                        end
                    end
                end
            end
        end)
    else
        -- Cleanup ESP saat dimatikan
        local zFolder = Workspace:FindFirstChild("ServerZombies")
        if zFolder then
            for _, z in ipairs(zFolder:GetChildren()) do
                local head = z:FindFirstChild("Head")
                if head and head:FindFirstChild("H_ESP") then head.H_ESP:Destroy() end
            end
        end
    end
end)

-- Setup Config System (Credits & Save/Load)
Win:CreateConfigSystem("https://discord.gg/28cfy5E3ag")

-- [RESTORED] UI Keybind di Menu Settings
-- Parameter ke-4 'true' memastikan keybind ini muncul di tab Settings, bukan tab Main
Win:Section("UI CONTROLS", true)
Win:Keybind("Toggle UI Menu", Enum.KeyCode.RightControl, function(key)
    if Library and Library.ToggleUI then
        Library:ToggleUI()
    end
end, true)

-- Auto Load Config Terakhir
Win:CheckAutoload()
