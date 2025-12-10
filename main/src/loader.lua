-- [[ FSSHUB LOADER V8 (Modular Architecture) ]] --

local BASE_URL = "https://raw.githubusercontent.com/fingerscrows/fsshub-official/main/"

-- 1. Load UIManager (The Builder)
local ManagerFunc = game:HttpGet(BASE_URL .. "main/modules/UIManager.lua") -- Simpan UIManager di folder modules
local UIManager = loadstring(ManagerFunc)()

-- 2. Tentukan Game Script mana yang dipakai
local GameScriptUrl = BASE_URL .. "main/scripts/Universal.lua" -- Logic deteksi game ID ada disini

-- 3. Load Data Game
local GameDataFunc = game:HttpGet(GameScriptUrl)
local GameData = loadstring(GameDataFunc)()

-- 4. BUILD UI!
UIManager.Build(GameData)
