-- [[ FSSHUB: UI MANAGER (THE BUILDER) ]] --
-- Bertugas menerjemahkan Data Game menjadi Tampilan Visual

local UIManager = {}

-- 1. Load Library Visual (V10 Premium)
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local Library = loadstring(game:HttpGet(LIB_URL))()

-- Init Library
Library:Init()

-- Fungsi Utama: Membangun UI berdasarkan Skema Data
function UIManager.Build(GameConfig)
    -- A. Setup Window & Watermark
    Library:Watermark("FSSHUB Premium | " .. GameConfig.Name)
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name))
    
    -- B. Loop setiap Tab dalam Config
    for _, tabData in ipairs(GameConfig.Tabs) do
        local Tab = Window:Section(tabData.Name, tabData.Icon)
        
        -- C. Loop setiap Elemen dalam Tab
        for _, element in ipairs(tabData.Elements) do
            
            -- [TOGGLE]
            if element.Type == "Toggle" then
                local toggle = Tab:Toggle(element.Title, element.Default, element.Callback)
                
                -- Auto Keybind Support jika ada di config
                if element.Keybind then
                    toggle.SetKeybind(element.Keybind)
                end

            -- [BUTTON]
            elseif element.Type == "Button" then
                Tab:Button(element.Title, element.Callback)

            -- [SLIDER]
            elseif element.Type == "Slider" then
                Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)

            -- [DROPDOWN]
            elseif element.Type == "Dropdown" then
                Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
                
            -- [KEYBIND - STANDALONE]
            elseif element.Type == "Keybind" then
                Tab:Keybind(element.Title, element.Default, element.Callback)
                
            -- [LABEL/SECTION]
            elseif element.Type == "Label" then
                -- Jika library punya fitur label, masukkan sini. 
                -- Jika tidak, bisa diabaikan atau buat dummy button.
            end
        end
    end
    
    -- D. Tambahkan Tab Settings Otomatis (Global)
    local SettingsTab = Window:Section("Settings", "10888332462")
    
    SettingsTab:Keybind("Toggle Menu", Enum.KeyCode.RightControl, function()
        if Library.base then 
            local main = Library.base:FindFirstChild("FSSHUB_V10"):FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)
    
    SettingsTab:Button("Unload Script", function()
        -- Panggil fungsi cleanup khusus game jika ada
        if GameConfig.OnUnload then GameConfig.OnUnload() end
        
        Library:Notify("System", "Script Unloaded", 2)
        if Library.base then Library.base:Destroy() end
    end)

    Library:Notify("FSSHUB", GameConfig.Name .. " Loaded!", 3)
end

return UIManager
