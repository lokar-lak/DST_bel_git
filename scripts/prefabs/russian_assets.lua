local mods = rawget(_G, "mods") or {}
local t = mods.BielarusizatarDST

--Это подгружаем всегда
local assets =
{	
}

	table.insert(assets, Asset("ATLAS", "images/blr_icon"..(t.IsBeta and "_beta.xml" or ".xml")))

if t.CurrentTranslationType == t.TranslationTypes.Full then 
	local ass = {
		Asset("ATLAS","images/blr_mapgen.xml"),
		Asset("ATLAS","images/blr_names_wickerbottom.xml"), 
		Asset("ATLAS","images/blr_names_willow.xml"), 
		Asset("ATLAS","images/blr_names_wilson.xml"), 
		Asset("ATLAS","images/blr_names_woodie.xml"), 
		Asset("ATLAS","images/blr_names_wes.xml"), 
		Asset("ATLAS","images/blr_names_wolfgang.xml"), 
		Asset("ATLAS","images/blr_names_wendy.xml"),
		Asset("ATLAS","images/blr_names_wathgrithr.xml"),
		Asset("ATLAS","images/blr_names_webber.xml"),
		Asset("ATLAS","images/blr_names_waxwell.xml"),
		Asset("ATLAS","images/blr_names_random.xml"),
		Asset("ATLAS","images/blr_names_wx78.xml"),
		Asset("ATLAS","images/blr_names_winona.xml"),
		Asset("ATLAS","images/blr_names_wortox.xml"),
		Asset("ATLAS","images/blr_names_wormwood.xml"),
		Asset("ATLAS","images/blr_names_warly.xml"),
		Asset("ATLAS","images/blr_names_wonkey.xml"),
		Asset("ATLAS","images/blr_names_wanda.xml"),
		Asset("ATLAS","images/blr_names_wurt.xml"),
		Asset("ATLAS","images/blr_names_walter.xml"),
		--Золото
		Asset("ATLAS","images/blr_names_gold_wickerbottom.xml"), 
		Asset("ATLAS","images/blr_names_gold_willow.xml"), 
		Asset("ATLAS","images/blr_names_gold_wilson.xml"), 
		Asset("ATLAS","images/blr_names_gold_woodie.xml"), 
		Asset("ATLAS","images/blr_names_gold_wes.xml"), 
		Asset("ATLAS","images/blr_names_gold_wolfgang.xml"), 
		Asset("ATLAS","images/blr_names_gold_wendy.xml"),
		Asset("ATLAS","images/blr_names_gold_wathgrithr.xml"),
		Asset("ATLAS","images/blr_names_gold_webber.xml"),
		Asset("ATLAS","images/blr_names_gold_waxwell.xml"),
		Asset("ATLAS","images/blr_names_gold_random.xml"),
		Asset("ATLAS","images/blr_names_gold_wx78.xml"),
		Asset("ATLAS","images/blr_names_gold_winona.xml"),
		Asset("ATLAS","images/blr_names_gold_wortox.xml"),
		Asset("ATLAS","images/blr_names_gold_wormwood.xml"),
		Asset("ATLAS","images/blr_names_gold_warly.xml"),
		Asset("ATLAS","images/blr_names_gold_wonkey.xml"),
		Asset("ATLAS","images/blr_names_gold_wanda.xml"),
		Asset("ATLAS","images/blr_names_gold_wurt.xml"),
		Asset("ATLAS","images/blr_names_gold_walter.xml"),
		
		Asset("ATLAS", "images/blr_tradescreen_overflow.xml" ),
		Asset("ATLAS", "images/blr_tradescreen.xml" ),		
	}

	for _, v in ipairs(ass) do
		table.insert(assets, v)
	end
end	


return Prefab("russian_assets", function() return CreateEntity() end, assets)
