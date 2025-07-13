env._G = GLOBAL

mods = _G.rawget(_G, "mods")
if not mods then
	mods = {}
	_G.rawset(_G, "mods", mods)
end
_G.mods = mods

PrefabFiles = {
	"russian_assets"
}

local IsBeta = modinfo.is_beta
local SteamID = "3508511660"

mods.BielarusizatarDST = {
	modinfo = modinfo,
	
	StorePath = MODROOT,
	
	mod_phrases = {},
	mod_announce = {},
	
	debug = nil,
	print = function(...) if mods.BielarusizatarDST.debug then print("[RLP_DEBUG]", ...)  end end,
	
	UpdateLogFileName = "updatelog.txt",
	MainPOfilename = "DST.po",
	ModsPOfilename = "MODS.po",
	TranslationTypes = {Full = "1", FontsOnly = "0"},
	ModTranslationTypes = {Enabled = "1", Disabled = "0"},
	CurrentTranslationType = nil,
	IsModTranslEnabled = nil,
	SteamID = SteamID,
	SteamURL = "http://steamcommunity.com/sharedfiles/filedetails/?id="..SteamID,
	DiscordURL = "https://discord.gg/eHEgH3xSF8",
	SelectedLanguage = "by",

	--Скланенне
	AdjectiveCaseTags = {
		nominative = "nom", --Назоўны	Хто/што
		accusative = "acc", --Вінавальны	Каго/што
		dative = "dat",		--Давальны		Каму/чаму
		ablative = "abl",	--Творны	Кім/чым
		genitive = "gen",	--Родны	Каго/чаго
		vocative = "voc",	--Клічны
		locative = "loc",	--Месны	Аб кім/аб чым
		instrumental = "ins"--unused
	},
	DefaultActionCase = "accusative",

	IsBeta = IsBeta,
}

print("About to load BielarusizatarDST ver. ", modinfo.version)

modimport("scripts/rlp_main.lua")
