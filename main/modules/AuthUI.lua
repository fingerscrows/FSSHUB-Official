-- Tambahkan Service di atas
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

-- Fungsi GetHWID
local function GetHWID()
    -- Mengambil ClientId unik pengguna (ini standard untuk free exploit)
    local success, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    if success then return id else return "UNKNOWN_HWID" end
end

-- ... (Di dalam fungsi MakeBtn GET KEY) ...

    MakeBtn("GET KEY", Theme.Bg, true, function(btn)
        local hwid = GetHWID()
        -- FORMAT LINK WORK.INK KAMU HARUS SEPERTI INI:
        -- Kamu harus menyetting Destination URL di Work.ink agar meneruskan parameter hwid
        -- Contoh link Work.ink: https://work.ink/123/456?hwid=
        
        -- Tapi untuk testing langsung ke GitHub Pages:
        local link = "https://fingerscrows.github.io/fsshub-official/?hwid=" .. hwid
        
        -- Jika pakai Work.ink, nanti formatnya:
        -- local link = "https://work.ink/xxx/xxx?hwid=" .. hwid
        
        setclipboard(link)
        btn.Text = "LINK COPIED!"
        task.delay(1.5, function() btn.Text = "GET KEY" end)
    end)
