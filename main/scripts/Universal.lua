-- [[ FSSHUB GAME CONFIG: UNIVERSAL ]] --
-- Hanya berisi Logika Game & Definisi Fitur

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- State Variables (Simpan status cheat di sini)
local State = {
    Speed = 16,
    Jump = 50,
    SpeedEnabled = false,
    JumpEnabled = false
}

-- Definisi Logika Cheat (Fungsi terpisah agar rapi)
local function LoopSpeed()
    while State.SpeedEnabled do
        task.wait()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed
            end
        end)
    end
    -- Reset saat mati
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
end

-- [[ CONFIGURATION TABLE ]] --
return {
    Name = "Universal V3.0", -- Judul Window
    
    -- Cleanup Function (Dipanggil UIManager saat Unload)
    OnUnload = function()
        State.SpeedEnabled = false
        State.JumpEnabled = false
    end,

    Tabs = {
        -- [TAB 1: PLAYER]
        {
            Name = "Local Player",
            Icon = "10888331510",
            Elements = {
                {
                    Type = "Toggle",
                    Title = "Enable Speed",
                    Default = false,
                    Keybind = Enum.KeyCode.V, -- Keybind didefinisikan di data!
                    Callback = function(val)
                        State.SpeedEnabled = val
                        if val then task.spawn(LoopSpeed) end
                    end
                },
                {
                    Type = "Slider",
                    Title = "WalkSpeed Amount",
                    Min = 16, Max = 300, Default = 16,
                    Callback = function(val)
                        State.Speed = val
                    end
                },
                {
                    Type = "Button",
                    Title = "Reset Character",
                    Callback = function()
                        if LocalPlayer.Character then LocalPlayer.Character:BreakJoints() end
                    end
                }
            }
        },
        
        -- [TAB 2: VISUALS]
        {
            Name = "Visuals",
            Icon = "10888332158",
            Elements = {
                {
                    Type = "Toggle",
                    Title = "ESP Enabled",
                    Default = false,
                    Callback = function(val)
                        -- Masukkan logika ESP disini
                        print("ESP set to:", val)
                    end
                }
            }
        }
    }
}
