-- [[ FSSHUB: UI MANAGER V2.3 (FIXED KEYBIND) ]] --

local UIManager = {}
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local success, Library = pcall(function() return loadstring(game:HttpGet(LIB_URL .. "?t=" .. tostring(math.random(1, 10000))))() end)

if not success or not Library then 
    warn("FSSHUB: Library failed to load!") 
    return UIManager 
end

Library:Init()

function UIManager.Build(GameConfig, AuthData)
    local userStatus = (AuthData and AuthData.Type) or "Free"
    Library:Watermark("FSSHUB " .. userStatus .. " | " .. GameConfig.Name)
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name))
    
    -- [[ PROFILE TAB ]] --
    local ProfileTab = Window:Section("Profile", "10888331510")
    if AuthData then
        ProfileTab:Paragraph("User Information", "License Type: " .. AuthData.Type .. "\nGame: " .. GameConfig.Name)
        local TimerLabel = ProfileTab:Label("Expiry: Syncing...")
        task.spawn(function()
            while true do
                local currentTime = os.time()
                local timeLeft = AuthData.Expiry - currentTime
                if AuthData.Expiry > 9000000000 then
                    TimerLabel.Text = "Status: LIFETIME / UNLIMITED"
                    break
                elseif timeLeft > 0 then
                    local d = math.floor(timeLeft / 86400)
                    local h = math.floor((timeLeft % 86400) / 3600)
                    local m = math.floor((timeLeft % 3600) / 60)
                    local s = timeLeft % 60
                    TimerLabel.Text = string.format("Expires In: %dd %02dh %02dm %02ds", d, h, m, s)
                else
                    TimerLabel.Text = "LICENSE EXPIRED"
                end
                task.wait(1)
            end
        end)
    else
        ProfileTab:Paragraph("Status", "Developer Mode / No Auth Data")
    end
    ProfileTab:Paragraph("Quick Guide", "• Right Ctrl: Hide/Show Menu\n• Use [Settings] tab to Unload Script")
    ProfileTab:Label("Credits: FingersCrows & FSSHUB Team")

    -- [[ GAME TABS ]] --
    for _, tabData in ipairs(GameConfig.Tabs) do
        local Tab = Window:Section(tabData.Name, tabData.Icon)
        for _, element in ipairs(tabData.Elements) do
            if element.Type == "Toggle" then
                local t = Tab:Toggle(element.Title, element.Default, element.Callback)
                if element.Keybind then t.SetKeybind(element.Keybind) end
            elseif element.Type == "Button" then 
                local b = Tab:Button(element.Title, element.Callback)
                -- [OPTIONAL] Jika Button punya keybind di config
                if element.Keybind then b.SetKeybind(element.Keybind) end
            elseif element.Type == "Slider" then Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)
            elseif element.Type == "Dropdown" then Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
            elseif element.Type == "Keybind" then Tab:Keybind(element.Title, element.Default, element.Callback)
            elseif element.Type == "Label" then Tab:Label(element.Title) 
            end
        end
    end
    
    -- [[ SETTINGS ]] --
    local SettingsTab = Window:Section("Settings", "10888332462")
    
    SettingsTab:Toggle("Show FPS/Watermark", true, function(state)
        Library:ToggleWatermark(state)
    end)

    SettingsTab:Keybind("Toggle Menu", Enum.KeyCode.RightControl, function()
        -- [FIXED] Mencari MainFrame dengan benar di dalam FSSHUB_V10
        if Library.base then 
            -- Library.base adalah ScreenGui (FSSHUB_V10)
            local main = Library.base:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)
    
    SettingsTab:Button("Unload Script", function()
        if GameConfig.OnUnload then pcall(GameConfig.OnUnload) end
        game.StarterGui:SetCore("SendNotification", {Title = "System", Text = "Script Unloaded", Duration = 3})
        if Library.base then 
            if typeof(Library.base) == "Instance" then Library.base:Destroy() end 
            Library.base = nil 
        end
    end)

    game.StarterGui:SetCore("SendNotification", {Title = "FSSHUB", Text = GameConfig.Name .. " Loaded!", Duration = 5})
end

return UIManager
