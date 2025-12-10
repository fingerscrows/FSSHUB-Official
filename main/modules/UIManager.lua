-- [[ FSSHUB: UI MANAGER V2.0 (PROFILE TAB & ANTI-CACHE) ]] --
-- Bertugas: Membangun UI dari Data Game + Menampilkan Profil User

local UIManager = {}

-- 1. Load Library Visual (V10.5 Premium)
-- Menggunakan timestamp (?t=...) agar selalu memuat versi terbaru (Anti-Cache)
local LIB_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/main/lib/FSSHUB_Lib.lua"
local success, Library = pcall(function() return loadstring(game:HttpGet(LIB_URL .. "?t=" .. tostring(math.random(1, 10000))))() end)

if not success or not Library then 
    warn("FSSHUB: Library failed to load! Check FSSHUB_Lib.lua for errors.") 
    return UIManager 
end

-- Init Library
Library:Init()

-- Fungsi Utama: Membangun UI
-- Parameter 'AuthData' dikirim dari Core.lua
function UIManager.Build(GameConfig, AuthData)
    
    -- Setup Watermark dengan Status User
    local userStatus = (AuthData and AuthData.Type) or "Free"
    Library:Watermark("FSSHUB " .. userStatus .. " | " .. GameConfig.Name)
    
    -- Buat Window Utama
    local Window = Library:Window("FSSHUB | " .. string.upper(GameConfig.Name))
    
    -- [[ TAB 1: PROFILE & STATUS (AUTO GENERATED) ]] --
    -- Tab ini otomatis dibuat paling depan
    local ProfileTab = Window:Section("Profile", "10888331510") -- Icon User
    
    if AuthData then
        -- Tampilkan Info User
        ProfileTab:Paragraph("User Information", 
            "License Type: " .. AuthData.Type .. "\n" ..
            "Current Game: " .. GameConfig.Name
        )
        
        -- LABEL UNTUK COUNTDOWN TIMER
        local TimerLabel = ProfileTab:Label("Expiry: Syncing...")
        
        -- Logic Countdown (Realtime)
        task.spawn(function()
            while true do
                -- Hitung selisih waktu (Pastikan Core mengirim Expiry dalam detik)
                local currentTime = os.time()
                local timeLeft = AuthData.Expiry - currentTime
                
                -- Jika waktu sangat besar (misal perm key), anggap Unlimited
                if AuthData.Expiry > 9000000000 then
                    TimerLabel.Text = "Status: LIFETIME / UNLIMITED"
                    break
                elseif timeLeft > 0 then
                    local d = math.floor(timeLeft / 86400)
                    local h = math.floor((timeLeft % 86400) / 3600)
                    local m = math.floor((timeLeft % 3600) / 60)
                    local s = timeLeft % 60
                    
                    -- Update teks label
                    TimerLabel.Text = string.format("Expires In: %dd %02dh %02dm %02ds", d, h, m, s)
                else
                    TimerLabel.Text = "LICENSE EXPIRED"
                end
                
                task.wait(1) -- Update setiap 1 detik
            end
        end)
    else
        -- Jika tidak ada data Auth (misal bypass/dev mode)
        ProfileTab:Paragraph("Status", "Developer Mode / No Auth Data")
    end
    
    -- Petunjuk Penggunaan
    ProfileTab:Paragraph("Quick Guide", 
        "• Press [Right Ctrl] to Hide/Show Menu\n" ..
        "• Use [Settings] tab to Unload Script safely\n" ..
        "• Join Discord for updates & support"
    )
    
    ProfileTab:Label("Credits: FingersCrows & FSSHUB Team")

    -- [[ TAB 2+: GAME FEATURES (DARI CONFIG) ]] --
    -- Loop data dari Game Script (Universal/Wave Z)
    for _, tabData in ipairs(GameConfig.Tabs) do
        local Tab = Window:Section(tabData.Name, tabData.Icon)
        
        for _, element in ipairs(tabData.Elements) do
            
            -- Toggle
            if element.Type == "Toggle" then
                local toggle = Tab:Toggle(element.Title, element.Default, element.Callback)
                if element.Keybind then
                    toggle.SetKeybind(element.Keybind)
                end

            -- Button
            elseif element.Type == "Button" then
                Tab:Button(element.Title, element.Callback)

            -- Slider
            elseif element.Type == "Slider" then
                Tab:Slider(element.Title, element.Min, element.Max, element.Default, element.Callback)

            -- Dropdown
            elseif element.Type == "Dropdown" then
                Tab:Dropdown(element.Title, element.Options, element.Default, element.Callback)
                
            -- Keybind (Standalone)
            elseif element.Type == "Keybind" then
                Tab:Keybind(element.Title, element.Default, element.Callback)
                
            -- Label (Manual dari Config)
            elseif element.Type == "Label" then
                Tab:Label(element.Title)
            end
        end
    end
    
    -- [[ TAB TERAKHIR: SETTINGS (GLOBAL) ]] --
    local SettingsTab = Window:Section("Settings", "10888332462")
    
    SettingsTab:Keybind("Toggle Menu", Enum.KeyCode.RightControl, function()
        if Library.base and Library.base:FindFirstChild("FSSHUB_V10") then 
            local main = Library.base.FSSHUB_V10:FindFirstChild("MainFrame")
            if main then main.Visible = not main.Visible end
        end
    end)
    
    SettingsTab:Button("Unload Script", function()
        -- 1. Panggil Cleanup khusus Game (jika ada)
        if GameConfig.OnUnload then 
            pcall(GameConfig.OnUnload) 
        end
        
        -- 2. Hapus UI dengan aman
        game.StarterGui:SetCore("SendNotification", {Title = "System", Text = "Script Unloaded", Duration = 3})
        
        if Library.base then
            if typeof(Library.base) == "Instance" then
                Library.base:Destroy()
            elseif type(Library.base) == "table" and Library.base.Destroy then
                Library.base:Destroy()
            end
            Library.base = nil
        end
    end)

    game.StarterGui:SetCore("SendNotification", {Title = "FSSHUB", Text = GameConfig.Name .. " Loaded!", Duration = 5})
end

return UIManager
