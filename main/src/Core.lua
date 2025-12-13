-- [[ FSSHUB CORE V12.0 (FULL INTEGRITY) ]] --
-- Fitur: Stable Auth, Fail-safe Loading, Universal Fallback, Verbose Error Handling
-- Path: main/src/Core.lua

local Core = {}
local FILE_NAME = "FSSHUB_License.key"
Core.AuthData = nil 

-- [DEBUG HELPER]
local function DebugLog(msg)
    print("[FSSHUB DEBUG]: " .. tostring(msg))
end

DebugLog("Core Initializing...")
DebugLog("FSSHUB_DEV_BASE: " .. tostring(getgenv().FSSHUB_DEV_BASE))

-- KONFIGURASI SERVER
local API_URL = "https://script.google.com/macros/s/AKfycby0s_ataAeB1Sw1IFz0k-x3OBM7TNMfA66OKm32Fl9E0F3Nf7vRieVzx9cA8TGX0mz_/exec" 
-- Cek Mode Pengembang: Jika variabel global FSSHUB_DEV_BASE ada, gunakan itu. Jika tidak, gunakan URL default (main branch).
local BASE_URL = getgenv().FSSHUB_DEV_BASE or "https://raw.githubusercontent.com/fingerscrows/FSSHUB-Official/main/"
local DEFAULT_GAME = "main/scripts/Universal.lua" 

-- Services
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")

-- [FUNGSI BANTUAN]

-- Mengambil Nama Game dengan aman (Anti-Error jika game belum publish)
local function GetGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then 
        return info.Name 
    end
    return "Unknown Game (" .. tostring(game.PlaceId) .. ")"
end

-- Load URL dengan parameter anti-cache
-- Load URL dengan parameter anti-cache (SECURE)
local function LoadUrl(path)
    local full_url = BASE_URL .. path .. "?t=" .. tostring(os.time())
    DebugLog("Fetching: " .. full_url)

    local success, result = pcall(function()
        return game:HttpGet(full_url)
    end)

    if not success then
        warn("[SENTINEL] Network Error: " .. tostring(result))
        return nil
    end

    return result
end

-- Mengirim notifikasi ke layar pemain
local function Notify(title, text)
    pcall(function() 
        StarterGui:SetCore("SendNotification", {
            Title = title, 
            Text = text, 
            Duration = 5
        }) 
    end)
end

-- Mengambil Hardware ID (HWID) untuk keamanan
local function GetHWID()
    local s, id = pcall(function() return RbxAnalyticsService:GetClientId() end)
    return s and id or "UNKNOWN_HWID"
end

-- [[ LOGIKA VALIDASI KEY ]] --
function Core.ValidateKey(input)
    -- Cek dasar: Apakah input ada dan panjangnya cukup?
    if not input or #input < 5 then 
        return {valid = false} 
    end
    
    -- Bersihkan input dari spasi di depan/belakang (Trimming)
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")
    
    -- Siapkan data untuk dikirim ke server verifikasi
    local hwid = GetHWID()
    local pid = game.PlaceId
    local jid = game.JobId
    local gid = game.GameId
    local gameName = GetGameName()
    local encodedName = HttpService:UrlEncode(gameName)
    
    -- Susun URL Request lengkap
    local reqUrl = API_URL .. "?a=verify&k=" .. input .. "&hwid=" .. hwid .. "&pid=" .. pid .. "&gid=" .. gid .. "&jid=" .. jid .. "&gn=" .. encodedName .. "&nocache=" .. tostring(os.time())
    
    -- Kirim Request ke Google Apps Script
    local success, res = pcall(function() return game:HttpGet(reqUrl) end)
    
   if success then
        -- Decode jawaban server (JSON)
        local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
        
        if ok and data and data.status == "success" then
            
            -- Parsing Expiry Time (Konversi MS ke Detik jika perlu)
            local rawExpiry = tonumber(data.expiry) or 0
            if rawExpiry > 9999999999 then 
                rawExpiry = math.floor(rawExpiry / 1000) 
            end
            
            -- Cek apakah user adalah Developer
            local isDeveloper = false
            if data.message and string.find(data.message, "Dev") ~= nil then
                isDeveloper = true
            end

            -- Simpan Data Autentikasi ke Memori Global Core
            Core.AuthData = {
                Type = (data.info and (string.find(data.info, "Premium") or string.find(data.info, "Unlimited"))) and "Premium" or "Free",
                Expiry = rawExpiry, 
                Key = input,
                GameName = gameName,
                TargetScript = data.script, -- Script khusus dari server (jika ada)
                IsDev = isDeveloper,
                MOTD = data.motd -- Pesan pengumuman
            }
            
            return {valid = true, info = data.info} 
        end
    end
    
    return {valid = false}
end

-- [[ LOGIKA LOAD GAME (SISTEM UTAMA) ]] --
function Core.LoadGame()
    Notify("SYSTEM", "Checking Database...")
    
    -- 1. Load UI Manager (Wajib berhasil)
    local successManager, ManagerLib = pcall(function() return loadstring(LoadUrl("main/modules/UIManager.lua"))() end)
    
    if not successManager or not ManagerLib then 
        DebugLog("CRITICAL ERROR loading UI Manager: " .. tostring(ManagerLib))
        Notify("FATAL ERROR", "Failed to load UI Manager. Check connection.") 
        return 
    end

    -- 2. Tentukan Script Mana yang Dipakai
    local scriptPath = DEFAULT_GAME
    local isUniversal = true
    
    -- Cek apakah server memberikan script khusus untuk game ini
    if Core.AuthData and Core.AuthData.TargetScript and Core.AuthData.TargetScript ~= "" then
        scriptPath = Core.AuthData.TargetScript
        isUniversal = false
    end
    
    -- Pastikan AuthData ada (untuk jaga-jaga)
    if not Core.AuthData then Core.AuthData = {} end
    Core.AuthData.IsUniversal = isUniversal
    
    DebugLog("Target Module: " .. scriptPath .. " | Mode: " .. (isUniversal and "Universal" or "Official"))

    -- 3. Load Script Game
    local successData, GameData = pcall(function() return loadstring(LoadUrl(scriptPath))() end)
    
    -- 4. Validasi Hasil Load & Fallback System
    -- Jika script game gagal diload (error syntax/404), switch ke Universal
    if not successData or type(GameData) ~= "table" then
        DebugLog("Failed to load module: " .. scriptPath .. " Error: " .. tostring(GameData))
        warn("[FSSHUB] Failed to load module: " .. scriptPath)
        Notify("WARNING", "Official Script Error. Fallback to Universal...")
        
        -- Coba load universal
        local successUniv, UnivData = pcall(function() return loadstring(LoadUrl(DEFAULT_GAME))() end)
        
        if successUniv and type(UnivData) == "table" then 
            GameData = UnivData 
            Core.AuthData.IsUniversal = true
            scriptPath = DEFAULT_GAME
        else 
            DebugLog("Universal Script Failed: " .. tostring(UnivData))
            Notify("FATAL ERROR", "Universal Script Failed! Script stopped.") 
            return 
        end
    end
    
    -- 5. Override Nama Menu (Agar sesuai nama game asli)
    if Core.AuthData.GameName then
        GameData.Name = Core.AuthData.GameName
    end

    -- 6. Bangun UI (Build Interface)
    -- Menggunakan pcall agar jika UI error, script tidak crash total
    local buildSuccess, err = pcall(function()
        ManagerLib.Build(GameData, Core.AuthData)
    end)
    
    if not buildSuccess then
        DebugLog("UI Build Error: " .. tostring(err))
        warn("[FSSHUB] UI Build Error: ", err)
        Notify("UI ERROR", "Check console (F9) for details")
    end
end

-- [[ FUNGSI INISIALISASI (BOOT) ]] --
function Core.Init()
    -- Cek apakah ada Key tersimpan di file
    if isfile and isfile(FILE_NAME) then
        local saved = readfile(FILE_NAME)
        local result = Core.ValidateKey(saved)
        
        if result.valid then
            Notify("WELCOME BACK", Core.AuthData.Type .. " User")
            Core.LoadGame()
            return
        end
    end
    
    -- Jika tidak ada key / key expired, load Auth UI
    local success, AuthUI = pcall(function() return loadstring(LoadUrl("main/modules/AuthUI.lua"))() end)
    
    if success and AuthUI then
        -- SENTINEL: Wrap UI Show in pcall to prevent crash
        local uiSuccess, uiErr = pcall(function()
            AuthUI.Show({
                OnSuccess = function(key)
                    -- Callback saat tombol Login ditekan di AuthUI
                    local result = Core.ValidateKey(key)
                    
                    if result.valid then
                        -- Simpan key baru ke file
                        writefile(FILE_NAME, key)

                        -- Load Game dalam thread baru agar UI Auth bisa tertutup mulus
                        task.spawn(function()
                            Core.LoadGame()
                        end)

                        return {success = true, info = result.info}
                    end
                    
                    return {success = false}
                end
            })
        end)

        if not uiSuccess then
            warn("[SENTINEL] UI Error: " .. tostring(uiErr))
            Notify("UI ERROR", "Auth UI crashed. Check console.")
        end
    else
        Notify("ERROR", "Auth UI Failed to Load. Re-execute script.")
    end
end

return Core
