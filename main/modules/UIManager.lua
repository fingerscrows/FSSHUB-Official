-- [[ FSSHUB: UI MANAGER V2.5 (SAFE MODE) ]] --
-- Fitur: Anti-Crash jika Script Game tidak memiliki Tabs

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
    local gameName = (AuthData and AuthData.GameName) or GameConfig.Name or "Unknown"
    
    Library:Watermark("FSSHUB " .. userStatus .. " | " .. gameName)
    
    -- Judul Window (Safe Check)
    local windowTitle = GameConfig.Name or "FSSHUB LOADING..."
    local Window = Library:Window("FSSHUB | " .. string.upper(windowTitle))
    
    -- [[ TAB 1: DASHBOARD ]] --
    local ProfileTab = Window:Section("Dashboard", "10888331510")
    
    if AuthData then
        local statusText = "✅ Official Script Supported"
        if AuthData.IsUniversal then statusText = "⚠️ Universal Mode" end
        
        -- [DIAGNOSTIC INFO]
        if not GameConfig.Tabs then
            statusText = "❌ ERROR: NO TABS FOUND!"
        end

        ProfileTab:Paragraph("Game Info", 
            "Detected: " .. (AuthData.GameName or "Unknown") .. "\n" ..
            "Status: " .. statusText
        )
        
        ProfileTab:Paragraph("User Info", 
            "License: " .. AuthData.Type .. "\n" ..
            "Key: " .. (AuthData.Key and string.sub(AuthData.Key, 1, 12) .. "..." or "Hidden")
        )

        local TimerLabel = ProfileTab:Label("Expiry: Syncing...")
        task.spawn(function()
            while true do
                local currentTime = os.time()
                local timeLeft = AuthData.Expiry - currentTime
                if AuthData.Expiry > 9000000000 then
                    TimerLabel.Text = "Expiry: PERMANENT / DEV"
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
        ProfileTab:Paragraph("Status", "Dev Mode / Bypass")
    end
    
    ProfileTab:Label("Credits: FingersCrows")

    -- [[ TAB 2+: GAME FEATURES (SAFE LOOP) ]] --
    -- [FIX] Cek apakah Tabs ada isinya sebelum looping
    if GameConfig.Tabs and type(GameConfig.Tabs) == "table" then
        for _, tabData in ipairs(GameConfig.Tabs) do
            local Tab = Window:Section(tabData.Name, tabData.Icon)
            for _, element in ipairs(tabData.Elements) do
                if element.Type == "Toggle" then
                    local t = Tab:Toggle(element.Title, element.Default, element.Callback)
                    if element.Keybind then t.SetKeybind(element.Keybind) end
                elseif element.Type == "Button" then 
                    local b = Tab:Button(element.Title, element.Callback)
                    if element.Keybind then b.SetKeybind(element.Keybind) end
                elseif element.Type == "Slider" then Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)
                elseif element.Type == "Dropdown" then Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
                elseif element.Type == "Keybind" then Tab:Keybind(element.Title, element.Default, element.Callback)
                elseif element.Type == "Label" then Tab:Label(element.Title) 
                end
            end
        end
    else
        -- Jika Tabs Kosong, Tampilkan Pesan Error
        ProfileTab:Paragraph("⚠️ SYSTEM ERROR", "Script berhasil di-load, tapi tidak ada fitur (Tabs) yang ditemukan.\nCek console (F9) untuk detail.")
    end
    
    -- [[ SETTINGS ]] --
    local SettingsTab = Window:Section("Settings", "10888332462")
    
    SettingsTab:Toggle("Show FPS/Watermark", true, function(state)
        Library:ToggleWatermark(state)
    end)

    if AuthData and AuthData.IsDev then
        SettingsTab:Button("Open Debug Console [DEV]", function()
            local dbgUrl = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/modules/Debugger.lua"
            local s, m = pcall(function() return loadstring(game:HttpGet(dbgUrl .. "?t=" .. tostring(math.random(1,10000))))() end)
            if s and m then m.Show() end
        end)
    end

    SettingsTab:Keybind("Toggle Menu", Enum.KeyCode.RightControl, function()
        if Library.base then 
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

    game.StarterGui:SetCore("SendNotification", {Title = "FSSHUB", Text = "UI Loaded!", Duration = 5})
end

return UIManager
