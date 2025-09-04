local env = env
local modname = env.modname
local MODROOT = env.MODROOT
local t = mods.BielarusizatarDST

GLOBAL.setfenv(1, GLOBAL)

require("fonts")

local FONT_PREFIX = "blr_"
local FONT_POSTFIX = "__blr"

local CACHED_FONTS = {
	DEFAULTFONT      = DEFAULTFONT,
	DIALOGFONT       = DIALOGFONT,
	TITLEFONT        = TITLEFONT,
	UIFONT           = UIFONT,
	BUTTONFONT       = BUTTONFONT,
	HEADERFONT       = HEADERFONT,
	CHATFONT         = CHATFONT,
	CHATFONT_OUTLINE = CHATFONT_OUTLINE,
	NUMBERFONT       = NUMBERFONT,
	TALKINGFONT      = TALKINGFONT,
	SMALLNUMBERFONT  = SMALLNUMBERFONT,
	BODYTEXTFONT     = BODYTEXTFONT,
	--CONTROLLERS      = "fonts/controllers"..FONT_POSTFIX..".zip", alias = CONTROLLERS, disable_color = true,

	TALKINGFONT_HERMIT   = TALKINGFONT,
	TALKINGFONT_WORMWOOD = TALKINGFONT_WORMWOOD,
	--TALKINGFONT_HERMIT   = TALKINGFONT_HERMIT,
	NEWFONT = NEWFONT,
	NEWFONT_SMALL = NEWFONT_SMALL,
	NEWFONT_OUTLINE = NEWFONT_OUTLINE,
	NEWFONT_OUTLINE_SMALL = NEWFONT_OUTLINE_SMALL,
}

--Имена шрифтов, которые нужно загрузить.
local LOCALIZED = {["talkingfont"] = true,
	["stint-ucr50"] = true,
	["stint-ucr20"] = true,
	["opensans50"] = true,
	["belisaplumilla50"] = true,
	["belisaplumilla100"] = true,
	["buttonfont"] = true,
	["hammerhead50"] = true,
	["bellefair50"] = true,
	["bellefair_outline50"] = true,
	["talkingfont_wormwood"] = true,
	--["controllers"] = true,
	["spirequal"] = rawget(_G,"NEWFONT") and true or nil,
	["spirequal_small"] = rawget(_G,"NEWFONT_SMALL") and true or nil,
	["spirequal_outline"] = rawget(_G,"NEWFONT_OUTLINE") and true or nil,
	["spirequal_outline_small"] = rawget(_G,"NEWFONT_OUTLINE_SMALL") and true or nil}


--В этой функции происходит загрузка, подключение и применение русских шрифтов
local function ApplyLocalizedFonts()
	--t.print("ApplyLocalizedFonts", CalledFrom())
	
	--UPLOAD STAGE: unload the fonts if they have been loaded
	--restoring original font variables
	DEFAULTFONT      = CACHED_FONTS.DEFAULTFONT
	DIALOGFONT       = CACHED_FONTS.DIALOGFONT
	TITLEFONT        = CACHED_FONTS.TITLEFONT
	UIFONT           = CACHED_FONTS.UIFONT
	BUTTONFONT       = CACHED_FONTS.BUTTONFONT
	HEADERFONT       = CACHED_FONTS.HEADERFONT
	CHATFONT         = CACHED_FONTS.CHATFONT
	CHATFONT_OUTLINE = CACHED_FONTS.CHATFONT_OUTLINE
	NUMBERFONT       = CACHED_FONTS.NUMBERFONT
	TALKINGFONT      = CACHED_FONTS.TALKINGFONT
	SMALLNUMBERFONT  = CACHED_FONTS.SMALLNUMBERFONT
	BODYTEXTFONT     = CACHED_FONTS.BODYTEXTFONT
	
	TALKINGFONT_WORMWOOD = CACHED_FONTS.TALKINGFONT_WORMWOOD
	TALKINGFONT_HERMIT   = CACHED_FONTS.TALKINGFONT_HERMIT
	
	NEWFONT = CACHED_FONTS.NEWFONT
	NEWFONT_SMALL = CACHED_FONTS.NEWFONT_SMALL
	NEWFONT_OUTLINE = CACHED_FONTS.NEWFONT_OUTLINE
	NEWFONT_OUTLINE_SMALL = CACHED_FONTS.NEWFONT_OUTLINE_SMALL
	
	--UPLOAD STAGE: unload the fonts if they have been loaded
	--restoring original font variables
	for FontName in pairs(LOCALIZED) do
		TheSim:UnloadFont(FONT_PREFIX..FontName)
	end
	TheSim:UnloadPrefabs({"BLR_fonts"}) --unload the general prefab of localized fonts

	--LOADING STAGE: Loading fonts again
	--t.print("Loading UAL fonts")
	--Creating a list of assets
	local LocalizedFontAssets = {}
	for FontName in pairs(LOCALIZED) do 
		table.insert(LocalizedFontAssets, Asset("FONT", MODROOT.."fonts/"..FontName..FONT_POSTFIX..".zip"))
	end

	--Create a prefab, register it and load it
	local LocalizedFontsPrefab = require("prefabs/blr_fonts")(LocalizedFontAssets)
	RegisterPrefabs(LocalizedFontsPrefab)
	TheSim:LoadPrefabs({"BLR_fonts"})

	--We generate a list of aliases associated with files
	for FontName in pairs(LOCALIZED) do
		TheSim:LoadFont(MODROOT.."fonts/"..FontName..FONT_POSTFIX..".zip", FONT_PREFIX..FontName)
	end

	--Building a table of fallbacks for subsequent connection of fonts with additional fonts
	local fallbacks = {}
	for _, v in pairs(FONTS) do
		local FontName = v.filename:sub(7, -5)
		if LOCALIZED[FontName] then
			fallbacks[FontName] = {v.alias, unpack(v.fallback)}
		end
	end
	--Associating localized characters with new English fonts
	for FontName in pairs(LOCALIZED) do
		TheSim:SetupFontFallbacks(FONT_PREFIX..FontName, fallbacks[FontName])
	end
	
	-- We enter our aliases into global font variables
	DEFAULTFONT      = FONT_PREFIX.."opensans50"
	DIALOGFONT       = FONT_PREFIX.."opensans50"
	TITLEFONT        = FONT_PREFIX.."belisaplumilla100"
	UIFONT           = FONT_PREFIX.."belisaplumilla50"
	BUTTONFONT       = FONT_PREFIX.."buttonfont"
	HEADERFONT       = FONT_PREFIX.."hammerhead50"
	CHATFONT         = FONT_PREFIX.."bellefair50"
	CHATFONT_OUTLINE = FONT_PREFIX.."bellefair_outline50"
	NUMBERFONT       = FONT_PREFIX.."stint-ucr50"
	TALKINGFONT      = FONT_PREFIX.."talkingfont"
	SMALLNUMBERFONT  = FONT_PREFIX.."stint-ucr20"
	BODYTEXTFONT     = FONT_PREFIX.."stint-ucr50"
	
	TALKINGFONT_HERMIT = FONT_PREFIX.."talkingfont"
	TALKINGFONT_WORMWOOD = FONT_PREFIX.."talkingfont_wormwood"
	--TALKINGFONT_HERMIT = FONT_PREFIX.."talkingfont_hermit"

	NEWFONT = FONT_PREFIX.."spirequal"
	NEWFONT_SMALL = FONT_PREFIX.."spirequal_small"
	NEWFONT_OUTLINE = FONT_PREFIX.."spirequal_outline"
	NEWFONT_OUTLINE_SMALL = FONT_PREFIX.."spirequal_outline_small"
	
	-- Compress the new font a little
	TheSim:AdjustFontAdvance(CHATFONT, -2.5)
	TheSim:AdjustFontAdvance(HEADERFONT, -1)
end

local _UnregisterAllPrefabs = Sim.UnregisterAllPrefabs
Sim.UnregisterAllPrefabs = function(self, ...)
	_UnregisterAllPrefabs(self, ...)
	ApplyLocalizedFonts()
end

--insert a function that connects ukrainian fonts
local _RegisterPrefabs = ModManager.RegisterPrefabs --Replace the function in which you need to load fonts and correct global font constants
ModManager.RegisterPrefabs = function(self, ...)
	_RegisterPrefabs(self, ...)
	ApplyLocalizedFonts()
end

local _Start = Start
function Start(...) 
	ApplyLocalizedFonts()
	return _Start(...)
end
