name = "Bielarusizatar DST"
version = "0.0.7"

local desc = {
	en = "\nFull translation for Don't Starve Together in Belarusan by łokar Team.\n\nVersion: "..version,
	by = "\nПоўны пераклад Don't Starve Together на беларускую ад каманды łokar.\n\n\n\t\nВерсія: "..version
}

language = language or "en"
description = desc[language] or desc["en"]

name = language == "by" and "Беларусізатар для DST" or "Belarusization for DST"

configuration_options =
{
	
	{
		name = "Only fonts",
		label = "Only fonts",
		options =	{
						{description = "Выкл", data = "default"},
						{description = "Укл.", data = "on"},
					},

		default = "default",
	
	},
}

author = "łokar" --Макс. 67 сымбаляў

forumthread = ""
api_version = 10

local icon_name = "blr_icon"
icon_atlas = "images/"..icon_name..".xml"
icon = icon_name..".tex"

priority = 2023

dont_starve_compatible = false
dst_compatible = true

client_only_mod = true

forge_compatible = true
gorge_compatible = true
