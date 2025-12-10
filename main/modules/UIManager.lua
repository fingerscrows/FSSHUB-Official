-- [[ FSSHUB: UI MANAGER (THE BUILDER) V1.1 FIXED ]] --
-- Fix: Unload Error Handler

local UIManager = {}

-- Load Library Visual (V10 Premium)
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local success, Library = pcall(function() return loadstring(game:HttpGet(LIB_URL))() end)

if not success or not Library then 
    warn("FSSHUB: Library failed to load!") 
    return UIManager 
end

-- Init Library
Library:Init()

-- Fungsi Utama: Membangun UI
function UIManager.Build(GameConfig)
    -- A. Setup Window & Watermark
    Library:Watermark("FSSHUB Premium | " .. GameConfig.Name)
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name))
    
    -- B. Loop Tabs
    for _, tabData in ipairs(GameConfig.Tabs) do
        local Tab = Window:Section(tabData.Name, tabData.Icon)
        for _, element in ipairs(tabData.Elements) do
            if element.Type == "Toggle" then
                local toggle = Tab:Toggle(element.Title, element.Default, element.Callback)
                if element.Keybind then toggle.SetKeybind(element.Keybind) end
            elseif element.Type == "Button" then
                Tab:Button(element.Title, element.Callback)
            elseif element.Type == "Slider" then
                Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)
            elseif element.Type == "Dropdown" then
                Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
            elseif element.Type == "Keybind" then
                Tab:Keybind(element.Title, element.Default, element.Callback)
            end
        end
    end
    
    -- C. Settings Tab (Fixed Unload Logic)
    local SettingsTab = Window:Section("Settings", "10888332462")
    
    SettingsTab:Keybind("Toggle Menu", Enum.KeyCode.RightControl, function()
        if Library.base and Library.base:FindFirstChild("FSSHUB_V10") then 
            local main = Library.base.FSSHUB_V10:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)
    
    SettingsTab:Button("Unload Script", function()
        -- 1. Panggil Cleanup Game
        if GameConfig.OnUnload then 
            pcall(GameConfig.OnUnload) 
        end
        
        Library:Notify("System", "Script Unloaded", 2)
        
        -- 2. Safe Destroy (Mencegah Error di Console)
        if Library.base then
            if typeof(Library.base) == "Instance" then
                Library.base:Destroy()
            elseif type(Library.base) == "table" and Library.base.Destroy then
                Library.base:Destroy()
            end
            Library.base = nil
        end
    end)

    Library:Notify("FSSHUB", GameConfig.Name .. " Loaded!", 3)
end

return UIManager
