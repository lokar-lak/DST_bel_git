local env = env
local t = mods.BielarusizatarDST
local AddPrefabPostInit = AddPrefabPostInit
local AddClassPostConstruct = env.AddClassPostConstruct
local modimport = env.modimport

local GLOBAL = GLOBAL
local rawget = rawget
local rawset = rawset

GLOBAL.setfenv(1, GLOBAL)
rawget  = GLOBAL.rawget

require("constants")

local DEBUG_ENABLED = false

-- Удаляем уведомленіе о модах
Sim.ShouldWarnModsLoaded = function() return false end

modimport("scripts/blr_fonts.lua")
modimport("scripts/blr_fix.lua")


AddClassPostConstruct("widgets/redux/loadingwidget", function(self)
    if self and self.loading_tip_text then -- если советы не отключены
        self.loading_tip_text:SetFont(BODYTEXTFONT)
        self.loading_tip_text:SetSize(25) -- задаем размер шрифта (напрыклад, 30)
    end
end)

	--ісправленіе бага с шріфтом в спіннерах
	--Выполняем подмену шріфта в спіннере із-за глупой ошібкі разрабов в этом віджете
	--ніже есть версія для фікса перевода настроек--
AddClassPostConstruct("widgets/spinner", function(self, options, width, height, textinfo, ...)
	if textinfo then return end
	self.text:SetFont(BUTTONFONT)
end)


--Загружаем русіфікацію
print("Загрузка PO файлу")
env.LoadPOFile(t.StorePath..t.MainPOfilename, t.SelectedLanguage)
t.PO = LanguageTranslator.languages[t.SelectedLanguage]

local function runTranslatingEngine()
    -- 1. Пераклад звычайных рэплік (нават з дэдыкаваных сервераў)
    if rawget(GLOBAL, "Networking_Talk") then
        local OldNetworking_Talk = GLOBAL.Networking_Talk

        GLOBAL.Networking_Talk = function(guid, message, ...)
            if type(message) ~= "string" then
                return OldNetworking_Talk(guid, message, ...)
            end

            -- Ужо перакладзенае праз твой t.TranslateToBelarusian? → не чапаем
            if message:find("[\227\132-\227\135]") then -- хуткі чэк на кірыліцу
                return OldNetworking_Talk(guid, message, ...)
            end

            local translated = t.TranslateToBelarusian(message, Ents[guid]) or message
			return OldNetworking_Talk(guid, translated, ...)
        end
    end

    -- 2. Абвесткі пра смерць
    -- Абвесткі пра смерць — з правільным скланеннем забойцы і ахвяры
-- Абвесткі пра смерць з правільным скланеннем забойцы і ахвяры
-- Абвесткі пра смерць — з правільным скланеннем забойцы і ахвяры

	if GLOBAL.Networking_DeathAnnouncement and t and t.PO then
		local OldDeath = GLOBAL.Networking_DeathAnnouncement
		local sep_bel = t.PO["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1"] or " быў забіты "
		local sep_eng = " was killed by "
		local end_default = t.PO["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT"] or ""
		GLOBAL.Networking_DeathAnnouncement = function(message, ...)
			if type(message) ~= "string" then return OldDeath(message, ...) end
			print("DeathAnnouncement: Original message: " .. message)
			local victim, attacker
			local startpos = message:find(sep_eng, 1, true)  -- Шукаем толькі англійскі сепаратар, бо арыгінал заўжды па-ангельску
			if startpos then
				victim = message:sub(1, startpos - 1):match("^%s*(.-)%s*$")  -- Трым для victim
				local rest = message:sub(startpos + #sep_eng)
				attacker = rest:match("(.-)%.")  -- Захопіць да першай "." (.- nongreedy, %. экранавана)
				if attacker then
					attacker = attacker:match("^%s*(.-)%s*$")  -- Трым для attacker
				end
			end
			if victim and attacker then
				-- Знаходимо ключ (prefab) па англійскай назве нападніка
				local key = t.SpeechHashTbl.NAMES.Eng2Key[attacker]
				-- Бярэм беларускую назву з t.PO (калі знойдзены ключ), інакш пакідаем англійскую
				local translated_attacker = (key and t.PO["STRINGS.NAMES." .. string.upper(key)]) or attacker
				print("DeathAnnouncement: Translated attacker: " .. translated_attacker)
				local newmsg = victim .. " " .. sep_bel .. " " .. translated_attacker .. end_default
				print("DeathAnnouncement: New message: " .. newmsg)
				return OldDeath(newmsg, ...)
			end
			return OldDeath(message, ...)  -- Fallback на арыгінальнае паведамленне
		end
end

    -- 3. Абвесткі пра ўваскрашэнне
    if rawget(GLOBAL, "Networking_ResurrectAnnouncement") then
        local OldRezAnn = GLOBAL.Networking_ResurrectAnnouncement
        local sep = STRINGS.UI.HUD.REZ_ANNOUNCEMENT -- « быў уваскрошаны »

        GLOBAL.Networking_ResurrectAnnouncement = function(message, ...)
            if type(message) ~= "string" then
                return OldRezAnn(message, ...)
            end

            -- прыбіраем кропку для RTL-сумяшчальнасці
            if message:sub(-1) == "." then
                message = message:sub(1, -2)
            end

            if not sep then return OldRezAnn(message, ...) end

            local k, l = message:find(sep, 1, true)
            if not k then return OldRezAnn(message, ...) end
			

            local target   = message:sub(1, k-2)
            local reviver  = message:sub(l+2)

			local key_reviver = t.SpeechHashTbl.NAMES.Eng2Key[reviver]
			local translated_reviver = (key_reviver and t.PO["STRINGS.NAMES." .. string.upper(key_reviver)]) or reviver
				print("ResurrectAnnouncement: Translated attacker: " .. translated_reviver)

            local newmsg = target .. " " ..
                           (t.PO["STRINGS.UI.HUD.REZ_ANNOUNCEMENT"] or sep) .. " " ..
                           translated_reviver

            return OldRezAnn(newmsg, ...)
        end
    end
end

-- Запускаем адразу пасля загрузкі PO-файла

local function GetDayForm(dayCount, forms)
    -- Define the default day forms if not provided
    forms = forms or {"дзень", "дні", "дзён"}
    -- Determine the grammatical case for the word "день" based on the day count
    local formIndex
    if dayCount % 10 == 1 and dayCount % 100 ~= 11 then
        formIndex = 1 -- singular
    elseif dayCount % 10 >= 2 and dayCount % 10 <= 4 and (dayCount % 100 < 10 or dayCount % 100 >= 20) then
        formIndex = 2 -- genitive
    else
        formIndex = 3 -- plural
    end
    return forms[formIndex]
end

--Define the default day forms if not provided
local function StringTime(n,s)
	local pl_type=n%10==1 and n%100~=11 and 1 or(n%10>=2 and n%10<=4
			and(n%100<10 or n%100>=20)and 2 or 3)
	s=s or {"дзень","дні","дзён"}
	return s[pl_type]
end

runTranslatingEngine()
--Пытается сформіровать правільные окончанія в словах названія предмета str1 в соответствіі действію action
--objectname - названіе префаба предмета
local function rebuildname(str1, action, objectname)
	local function repsubstr(str, pos, substr)--вставіть подстроку substr в строку str в позіціі pos	
		local dontrebuild = {"для", "за", "з", "на", "у", "і"}; -- слова которые не нужно склонять
			for _,v in ipairs(dontrebuild) do 
				if str == v then
					return v
				end
			end

		pos = pos - 1
		return str:utf8sub(1, pos)..substr..str:utf8sub(pos+substr:utf8len()+1, str:utf8len())
	end

	if not str1 then
		return nil
	end
	local 	sogl=  {['б']=1,['в']=1,['г']=1,['д']=1,['ж']=1,['з']=1,['к']=1,['л']=1,['м']=1,['н']=1,['п']=1,
			['р']=1,['с']=1,['т']=1,['ф']=1,['х']=1,['ц']=1,['ч']=1,['ш']=1,['щ']=1}

	local sogl2 = {['г']=1,['ж']=1,['к']=1,['х']=1,['ц']=1,['ч']=1,['ш']=1,['щ']=1}
	local sogl3 = {["р"]=1,["л"]=1,["к"]=1,["Р"]=1,["Л"]=1,["К"]=1}

	local resstr=""
	local neuter=false
	local delimetr
	local wasnoun=false
	local wordcount=#(str1:gsub("[%s-]","~"):split("~"))
	local counter=0
	local FoundNoun
	local str=""
	str1=str1.." "
	local str1len=str1:utf8len()
	
	if objectname then
		objectname = string.lower(objectname)
	end

	-- Оптімізація обрезкі. Сохраняем все обрезкі чтоб каждый раз не резать заново
	local subbed = setmetatable({}, {__mode = "k"})
	local function SubSize(str, num)
		if not subbed[str] then
			subbed[str] = {}
		end
		if not subbed[num] then
			subbed[str][num] = str:utf8sub(num)
		end
		return subbed[str][num]
	end

	for i=1,str1len do
		delimetr=str1:utf8sub(i,i)
		if delimetr~=" " and delimetr~="-" then
			str=str..delimetr
		elseif #str>0 and (delimetr==" " or delimetr=="-") then
			counter=counter+1
			local size = str:utf8len()
			if action=="WALKTO" then --падысці да (каго? чаго?) Родны
				if SubSize(str, size -1)=="ая" then
					str=repsubstr(str,size -1,"ай")
				elseif SubSize(str, size -1)=="ая" then
					str=repsubstr(str,size -1,"ай")
				elseif SubSize(str, size -2)=="цыя" then
					str=repsubstr(str,size ,"і")
				elseif SubSize(str, size -1)=="ыя" then
					str=repsubstr(str,size -1,"ых")
				elseif SubSize(str, size -1)=="ае" then
					str=repsubstr(str,size -1,"ага")
					neuter=true
				elseif SubSize(str, size -1)=="ое" then
					str=repsubstr(str,size -1,"ога")
					neuter=true
				elseif SubSize(str, size -1)=="яя" then
					str=repsubstr(str,size -1,"яй")
				elseif SubSize(str, size -1)=="ец" then
					str=repsubstr(str,size -1,"цу")
				elseif SubSize(str, size -1)=="оў" then
					str=repsubstr(str,size ,"ова")
				elseif SubSize(str, size -2)=="нне" then
					str=repsubstr(str,size ,"я")
				elseif SubSize(str, size -1)=="ны" then
					str=repsubstr(str,size ,"ага")
				elseif SubSize(str, size -1)=="ае" then
					str=repsubstr(str,size -1,"ага")
				elseif SubSize(str, size -1)=="ее" then
					str=repsubstr(str,size -1,"ему")
				elseif SubSize(str, size -1)=="ые" then
					str=repsubstr(str,size -1,"ым")
				elseif SubSize(str, size -1)=="ой" and resstr=="" then
					str=repsubstr(str,size -1,"ому")
				elseif SubSize(str, size -1)=="ава" and resstr=="" then
					str=repsubstr(str,size,"авай")
				elseif SubSize(str, size -1)=="ек" then
					str=SubSize(str, 1,size -2).."ку"
					wasnoun=true
				elseif SubSize(str, size -1)=="ня" and t.NamesGender["it"][objectname] then
					str=SubSize(str, 1,size -2).."няці"
				elseif SubSize(str, size -1)=="ій" then
					str=repsubstr(str,size -1,"ія")
				elseif SubSize(str, size -1)=="ок" then
					str=repsubstr(str,size -1,"ку")
					wasnoun=true
				elseif SubSize(str, size -1)=="ць" then
					str=repsubstr(str,size ,"і")
					wasnoun=true
				elseif SubSize(str, size -1)=="вь" then
					str=repsubstr(str,size ,"і")
					wasnoun=true
				elseif SubSize(str, size -1)=="ль" then
					str=repsubstr(str,size ,"я")
					wasnoun=true
				elseif SubSize(str, size -1)=="зь" then
					str=repsubstr(str,size ,"і")
					wasnoun=true
				elseif SubSize(str, size -2)=="лень" then
					str=repsubstr(str,size , -2, "леня")
				elseif SubSize(str, size -1)=="нь" then
					str=repsubstr(str,size ,"ю")
					wasnoun=true
				elseif SubSize(str, size -1)=="ьі" then
					str=str.."м"
				elseif SubSize(str, size -1)=="кі" and not wasnoun then
					str=repsubstr(str,size ,"оў")
					wasnoun=true
				elseif SubSize(str, size -1)=="ха" and not wasnoun then
					str=repsubstr(str,size ,"і")
					wasnoun=true
				elseif SubSize(str, size -1)=="га" and not wasnoun then
					str=repsubstr(str,size ,"і")
					wasnoun=true
				elseif SubSize(str, size -1)=="ка" and not wasnoun then
					str=repsubstr(str,size ,"і")
					wasnoun=true
				elseif SubSize(str, size -1)=="аў" and not wasnoun then
					str=repsubstr(str,size ,"ва")
					wasnoun=true
				elseif SubSize(str, size -1)=="шча" and not wasnoun then
					str=repsubstr(str,size ,"а")
					wasnoun=true
				elseif SubSize(str, size )=="ы" and not wasnoun then
					str=repsubstr(str,size ,"ага")
				elseif SubSize(str, size )=="а" and not wasnoun and not neuter then
					str=repsubstr(str,size ,"ы")
					wasnoun=true
				elseif SubSize(str, size )=="я" and not wasnoun then
					str=repsubstr(str,size ,"і")
					wasnoun=true
				elseif SubSize(str, size )=="о" and not wasnoun then
					str=repsubstr(str,size ,"а")
					wasnoun=true
				elseif SubSize(str, size )=="е" and not wasnoun then
					str=repsubstr(str,size ,"ю")
					wasnoun=true
				elseif sogl[SubSize(str, size )] and not wasnoun then
					str=str.."а"
					wasnoun=true
				end
			-- (Каго? Што?) відазмяняе (каго? што?) вінавальны
			elseif action=="reskin" then
				if t.NamesGender["it"][objectname] then --средній род
					if SubSize(str, size -1)=="ня" then
						str=repsubstr(str,size -1,"ня")
					end
				elseif SubSize(str, size -3)=="ага" then
					str=repsubstr(str,size -3,"ага")
				elseif SubSize(str, size -2)=="ства" then
					str=repsubstr(str,size -2,"ства")
				elseif SubSize(str, size -2)=="аля" then
					str=repsubstr(str,size ,"ю")
				elseif SubSize(str, size -2)=="ля" then
					str=repsubstr(str,size -2,"лю")
				elseif SubSize(str, size -2)=="міна" then
					str=repsubstr(str,size ,"а")
				elseif SubSize(str, size -2)=="цыя" then
					str=repsubstr(str,size ,"ю")
				elseif SubSize(str, size -2)=="рнада" then
					wasnoun=true
				elseif SubSize(str, size -2)=="дыя" then
					str=repsubstr(str,size ,"ю")	
				elseif SubSize(str, size -1)=="зіда" then
					str=SubSize(str, 1,size -1).."у"
				elseif SubSize(str, size -2)=="лей" then
					str=repsubstr(str,size -2,"лей")
				elseif SubSize(str, size -2)=="ода" then
					str=repsubstr(str,size -2,"ода")
				elseif SubSize(str, size -2)=="ера" then
					str=repsubstr(str,size -2,"еру")
				elseif SubSize(str, size -2)=="яра" then
					str=repsubstr(str,size -2,"яра")
				elseif SubSize(str, size -2)=="ьей" then
					str=repsubstr(str,size -2,"ьей")
				elseif SubSize(str, size -2)=="еля" then
					str=repsubstr(str,size -2,"еля")
				elseif SubSize(str, size -2)=="пак" then
					str=repsubstr(str,size -2,"пка")						
				elseif SubSize(str, size -1)=="ця" then
					str=repsubstr(str,size -1,"цю")						
				elseif SubSize(str, size -2)=="уса" then
					str=str:utf8sub(1, -2)
				elseif SubSize(str, size -2)=="іна" then
					str=repsubstr(str,size ,"у")
				elseif SubSize(str, size -2)=="нец" then
					str=repsubstr(str,size -2,"нец")
				elseif SubSize(str, size -2)=="ара" then
					str=repsubstr(str,size -2,"ара")
				elseif SubSize(str, size -2)=="ало" then
					str=str:utf8sub(1, -2)
				elseif SubSize(str, size -2)=="ота" then
					str=str:utf8sub(1, -2)
				elseif SubSize(str, size -1)=="ера" then
					str=repsubstr(str,size -1,"еру")
				elseif SubSize(str, size -1)=="зд" then
					str=repsubstr(str,size -1,"зд")
				elseif SubSize(str, size -1)=="ня" then
					str=repsubstr(str,size -1,"ню")
				elseif SubSize(str, size -2)=="шча" then
					str=repsubstr(str,size ,"а")
				elseif SubSize(str, size -1)=="ння" then
					str=repsubstr(str,size -1,"ння")
				elseif SubSize(str, size -1)=="ая" then
					str=repsubstr(str,size -1,"ую")
				elseif SubSize(str, size -1)=="ла" then
					str=repsubstr(str,size -1,"ла")
				-- elseif SubSize(str, size -1)=="ія" then
				-- 	str=repsubstr(str,size -1,"ій")
				elseif SubSize(str, size -1)=="ьца" then
					str=repsubstr(str,size -1,"ьца")
				elseif SubSize(str, size -1)=="па" then
					str=repsubstr(str,size -1,"пу")
				elseif SubSize(str, size -1)=="яя" then
					str=repsubstr(str,size -1,"юю")
				elseif SubSize(str, size -1)=="це" then
					str=repsubstr(str,size -1,"ца")
				elseif SubSize(str, size -1)=="ей" then
					str=repsubstr(str,size -1,"ья")
				elseif SubSize(str, size )=="нь" then
					str=repsubstr(str,size ,"ня")
				elseif SubSize(str, size )=="а" and not wasnoun then
					str=repsubstr(str,size ,"у")
					wasnoun=true
				elseif sogl[SubSize(str, size )] and t.NamesGender["he2"][objectname] then
					str=str.."а"
				elseif sogl[SubSize(str, size )] then
					wasnoun=true	
				
				end
			--ізучіть (Кого? Что?) Вінітельный
			--пріменітельно к імені свіньі ілі кроліка
			elseif action and objectname and (objectname=="pigman" or objectname=="pigguard" or objectname=="merm" or objectname=="bunnyman" or objectname=="mermguard_lunar" or objectname=="mermguard" or objectname=="merm_lunar" or objectname=="sharkboi" or objectname:find("critter")~=nil or t.NamesGender["he2"][objectname]) then
				if SubSize(str, size -2)=="лец" then
					str=SubSize(str, 1,size -2).."ьца"
				elseif SubSize(str, size -1)=="ец" then
					str=SubSize(str, 1,size -2).."ца"
				elseif SubSize(str, size )=="а" then
					str=repsubstr(str,size ,"у")
				elseif SubSize(str, size -1)=="ня" and t.NamesGender["it"][objectname] then
					wasnoun=true
				elseif SubSize(str, size )=="я" then
					str=SubSize(str, 1,size -1).."ю"
				elseif SubSize(str, size )=="ь" then
					str=SubSize(str, 1,size -1).."я"
				elseif SubSize(str, size )=="ы" and not wasnoun then
					str=repsubstr(str,size ,"ага")
				elseif SubSize(str, size -1)=="ій" then
					str=repsubstr(str,size -1,"ія")
					wasnoun=true
				elseif SubSize(str, size -1)=="ый" then
					str=repsubstr(str,size -1,"ыя")
					wasnoun=true
				elseif sogl[SubSize(str, size )] then
					str=str.."а"
					wasnoun=true
				end
			elseif action and not(objectname and objectname=="sketch") then --агледзіць (Кага? Што?) Вінавальны
				if SubSize(str, size -2)=="цыя" then
					str=repsubstr(str,size ,"ю")
				elseif SubSize(str, size -2)=="яса" then
					wasnoun=true
				elseif SubSize(str, size -2)=="йка" then
					wasnoun=true
				elseif SubSize(str, size -1)=="ня" and t.NamesGender["it"][objectname] then
					wasnoun=true
				elseif SubSize(str, size -1)=="ое" or SubSize(str, size -1)=="ае" then
					neuter=true
				elseif SubSize(str, size -1)=="ая" then
					str=repsubstr(str,size -1,"ую")
				elseif SubSize(str, size -1)=="ыя" then
					str=repsubstr(str,size -1,"ыя")
				elseif SubSize(str, size -1)=="кі" and not wasnoun then
					str=repsubstr(str,size ,"оў")
					wasnoun=true
				elseif SubSize(str, size -1)=="яя" then
					str=repsubstr(str,size -1,"юю")
				elseif SubSize(str, size )=="а"  and not wasnoun and not neuter then
					str=repsubstr(str,size ,"у")
					wasnoun=true
				elseif SubSize(str, size )=="я"  and not wasnoun and not t.NamesGender["it"][objectname] then
					str=repsubstr(str,size ,"ю")
					wasnoun=true
				elseif sogl[SubSize(str, size )] and not wasnoun then
					wasnoun=true
				end
			end
			resstr=resstr..str..delimetr
			str=""
		end
	end
	resstr=resstr:utf8sub(1,resstr:utf8len()-1)
	subbed = nil
	--print("action: "..action.."resstr: "..resstr)
	return resstr
end
t.rebuildname = rebuildname

-- Для тестіровкі імен
if DEBUG_ENABLED then
	require("blr_debug")
end

t.BelarusianNames = {} --Табліца с особымі формамі названій предметов в разлічных падежах
t.ShouldBeCapped = {} --Табліца, в которой находітся спісок названій, первое слово которых пішется с большой буквы

--Табліца со спіскамі імён, отсортірованнымі по полам
t.NamesGender={
	he = {},
	he2 = {},
	she = {},
	it = {},
	plural = {},
	plural2 = {},
}

--Объявляем табліцу особых тегов, прісущіх персонажам.
--Порядковый номер тега определяет его пріорітет.
t.CharacterInherentTags={}
for char in pairs(GetActiveCharacterList()) do
	t.CharacterInherentTags[char]={}
end

--деліт строку на часті по сімволу-разделітелю. Возвращает і пустые вхожденія:
--split("|a|","|") вернёт табліцу із "", "а" і ""
--split("а","|") вернёт табліцу із "а"
--split("","|") вернёт табліцу із ""
--split("|","|") вернёт табліцу із "" і ""
--По ідее разделітелем может служіть сразу несколько сімволов (не тестіровалось)
local function split(str,sep)
		local fields, first = {}, 1
	str=str..sep
	for i=1,#str do
		if string.sub(str,i,i+#sep-1)==sep then
			fields[#fields+1]=(i<=first) and "" or string.sub(str,first,i-1)
			first=i+#sep
		end
	end
		return fields
end


local LetterCasesHash={u2l={["А"]="а",["Б"]="б",["В"]="в",["Г"]="г",["Ґ"]="ґ",["Д"]="д",["Е"]="е",["Ё"]="ё",["Ж"]="ж",["З"]="з",
							["і"]="і",["Й"]="й",["К"]="к",["Л"]="л",["М"]="м",["Н"]="н",["О"]="о",["П"]="п",["Р"]="р",
							["С"]="с",["Т"]="т",["У"]="у",["Ў"]="ў",["Ф"]="ф",["Х"]="х",["Ц"]="ц",["Ч"]="ч",["Ш"]="ш",["Щ"]="щ",
							["Ъ"]="ъ",["Ы"]="ы",["Ь"]="ь",["Э"]="э",["Ю"]="ю",["Я"]="я"},
					   l2u={["а"]="А",["б"]="Б",["в"]="В",["г"]="Г",["ґ"]="Ґ",["д"]="Д",["е"]="Е",["ё"]="Ё",["ж"]="Ж",["з"]="З",
							["і"]="і",["й"]="Й",["к"]="К",["л"]="Л",["м"]="М",["н"]="Н",["о"]="О",["п"]="П",["р"]="Р",
							["с"]="С",["т"]="Т",["у"]="У",["ў"]="Ў",["ф"]="Ф",["х"]="Х",["ц"]="Ц",["ч"]="Ч",["ш"]="Ш",["щ"]="Щ",
							["ъ"]="Ъ",["ы"]="Ы",["ь"]="Ь",["э"]="Э",["ю"]="Ю",["я"]="Я"}}

--первый сімвол в ніжній регістр
local function firsttolower(tmp)
	if not tmp then return end
	local firstletter=tmp:utf8sub(1,1)
	firstletter = LetterCasesHash.u2l[firstletter] or firstletter
	return firstletter..tmp:utf8sub(2)
end

--первый сімвол в верхній регістр
local function firsttoupper(tmp)
	if not tmp then return end
	local firstletter=tmp:utf8sub(1,1)
	firstletter = LetterCasesHash.l2u[firstletter] or firstletter
	return firstletter..tmp:utf8sub(2)
end

local function isupper(letter)
	if not letter or type(letter)~="string" then return end
	return LetterCasesHash.u2l[letter] or (#letter==1 and letter>="A" and letter<="Z")
end

local function islower(letter)
	if not letter or type(letter)~="string" then return end
	return LetterCasesHash.l2u[letter] or (#letter==1 and letter>="a" and letter<="z")
end

local function belarusianupper(tmp)
	if not tmp then return end
	local res=""
	local letter
	for i=1,tmp:utf8len() do
		letter = tmp:utf8sub(i,i)
		letter = LetterCasesHash.u2l[letter] or letter
		res = res..letter
	end
	return res
end

local function belarusianlower(tmp)
	if not tmp then return end
	local res=""
	local letter
	for i=1,tmp:utf8len() do
		letter = tmp:utf8sub(i,i)
		letter = LetterCasesHash.u2l[letter] or letter
		res = res..letter
	end
	return res
end


--Функція меняет окончанія прілагательного prefix в завісімості от падежа, пола і чісла предмета
local FixPrefix
do
	--local soft23={["г"]=1,["к"]=1,["х"]=1}
	--local soft45={["г"]=1,["ж"]=1,["к"]=1,["ч"]=1,["х"]=1,["ш"]=1,["щ"]=1}
	local endings={}
	--таблиця закінчень в залежності від дій і статі // ps в українській мові є тільки case1 і case2 // можливо ще но хз
	--case1 і case2 — тверда м'які пари
				--  чорний      Синій(жовтий)
	--Називний Хто? Що?
	endings["nom"]={
        he=     {case1="ы",case2="і"},
        he2=    {case1="ы",case2="і"},
        she=    {case1="ая", case2="яя" },
        it=     {case1="ае", case2="яе" },
        plural= {case1="ыя", case2="ія" },
        plural2={case1="ыя", case2="ія" }}
	
	 --Знахідний Кого? Що?
	endings["acc"]={
        he=     {case1="ы",case2="і"},   ---case2 he h2 mb swap 
        he2=    {case1="ага",case2="яга"},
        she=    {case1="ую",  case2="юю"   },
        it=     {case1="ае",  case2="яе"   },
        plural= {case1="ыя",  case2="ія"   },
        plural2={case1="ых",  case2="іх"   }}

    --Давальний Кому? Чому?
	endings["dat"]={
        he=     {case1="аму",case2="яму"},
        he2=    {case1="аму",case2="яму"},
        she=    {case1="ай", case2="яй"  },
        it=     {case1="аму",case2="яму"},
        plural= {case1="ым", case2="ім"  },
        plural2={case1="ым",  case2="ім"   }}

    --Орудний Ким? Чим?
	endings["abl"]={
        he=     {case1="ым", case2="ім" },
        he2=    {case1="ым", case2="ім" },
        she=    {case1="ай", case2="яй"},
        it=     {case1="ым", case2="ім" },
        plural= {case1="ымі",case2="імі"},
        plural2={case1="ымі",  case2="імі"  }}

    --Родовий Кого? Чого?
	endings["gen"]={
        he=     {case1="ага",case2="яга"},
        he2=    {case1="ага",case2="яга"  },
        she=    {case1="ай",case2="яй"  },
        it=     {case1="ага",case2="яга"},
        plural= {case1="ых",case2="іх"   },
        plural2={case1="ых",case2="іх" }}

    --Місцевий Про кого? Про що?
	endings["loc"]={
        he=     {case1="ым",case2="ім"},
        he2=    {case1="ым",case2="ім"  },
        she=    {case1="ай", case2="яй"  },
        it=     {case1="ым",case2="ім"},
        plural= {case1="ых", case2="іх"  },
        plural2={case1="ых", case2="іх"    }}

	--дополнітельные поля под разлічные действія в ігре
	endings["NOACTION"] = endings["nom"]
	endings["DEFAULTACTION"] = endings["acc"] --acc
	endings["WALKTO"] = endings["gen"] ---dat
	endings["SLEEPIN"] = endings["loc"]
	endings["ASSESSPLANTHAPPINESS"] = endings["gen"]
	endings["PLANTREGISTRY_RESEARCH"] = endings["acc"]	
	endings["INTERACT_WITH"] = endings["abl"]
	endings["CHARGE_FROM"] = endings["gen"]	
	endings["OPEN_CRAFTING"] = endings["dat"]
	endings["TRADE_WITH "]= endings["abl"]

	-- для рода реліквій, т.к. імеем одно выводімое імя, но разные префабы
	local relics = {ruins_chair=1, ruins_table=1, ruins_vase=1, ruins_plate=1, ruins_bowl=1, ruins_chipbowl=1}

	FixPrefix = function(prefix, act, item)
		if not t.NamesGender then return prefix end
		--Определім пол
		local gender="he"
		if endings["nom"][item] then --Еслі item содержіт непосредственно пол
			gender = item
		else
			if t.NamesGender["he2"][item] then gender="he2"
			elseif t.NamesGender["she"][item] then gender="she"
			elseif t.NamesGender["it"][item] then gender="it"
			elseif t.NamesGender["plural"][item] then gender="plural"
			elseif t.NamesGender["plural2"][item] then gender="plural2"
			elseif relics[item] then gender="she" 
			end
		end		

		--Особый случай. Для действія "Собрать" у меня есть трі запісі с заменённым текстом. Там получается множественное чісло.
		if act=="PICK" and item and t.BelarusianNames[STRINGS.NAMES[string.upper(item)]] and t.BelarusianNames[STRINGS.NAMES[string.upper(item)]][act] then gender="plural" end
 
		--Смена пола префікса для ВЫРОСШЕГО урожая на грядках, пол берём із плода
		--прімер: для выросшей моркові "NAMES.FARM_PLANT_CARROT" пол берётся із "NAMES.CARROT"
		if act=="PICK" and item then
			local plant = ""

		 	if item:utf8sub(1,11)=="farm_plant_" then
				plant = item:utf8sub(12)
			elseif item:utf8sub(1,5)=="weed_" then 
				plant = item:utf8sub(6)
			else 
				plant = string.lower(item)	-- гніль, ...
			end

			if plant then
				if t.NamesGender["he"][plant] then gender="he"
				elseif t.NamesGender["she"][plant] then gender="she"
				elseif t.NamesGender["it"][plant] then gender="it"
				end
			end
		end			

		--іщем переданное действіе в табліце выше
		act = endings[act] and act or (item and "DEFAULTACTION" or "nom")

		local words=string.split(prefix," ") --разбіваем на слова
		prefix=""
		for _, word in ipairs(words) do
			if --[[isupper(word:utf8sub(1,1)) and ]]word:utf8len()>3 then
				--Заменяем по всем возможным сценаріям
				local last = word:utf8sub(-1)
				if last=="ы" then
					word = word:utf8sub(1, word:utf8len()-1) .. endings[act][gender]["case1"]
				elseif last=="і" then
					word = word:utf8sub(1, word:utf8len()-1) .. endings[act][gender]["case2"]
				end
			end
			prefix=prefix..word.." "
		end
		prefix=prefix:utf8sub(1,1)..belarusianlower(prefix:utf8sub(2,-2))
		return prefix
	end
end

--Функція іщет в репліке спец-тэгі, оформленные в [] і выбірает нужный, соответствующій персонажу char
--Варіанты с разным переводом для разного пола оформляются в [] і разделяются сімволом |.
--В общем случае оформляется так: [мужчіна|женщіна|оно|множественное чісло|імя префаба персонажа=его варіант]
--Прі этом каждый варіант без указанія імені префаба определяет свою прінадлежность в такой последовательності:
--первый — мужской варіант, второй — женскій, третій — средній род, четвёртый — мн. чісло.
--імя префаба можно указывать в любом із варіантов (напрімер первом). Тогда оно не берётся в расчёт прі аналізе
--пустых (без указанія імені префаба) варіантов: [wes=он молчун|это мужчіна|wolfgang=сілач|это женщіна|это оно]
--Еслі в варіантах не указан нужный для char, то берётся варіант мужского пола (кроме webber'а, которому сперва
--попытается подставіть варіант множественного чісла, і Wx-78, который на русском счітается мужскім полом),
--еслі нет і этого, то нічего не подставітся.
--Варіанты полов можно задавать явно, указывая ключевые слова "he", "she", "it" ілі "plural"/"they"/"pl".
--Варіанты с указаннымі префабамі (і ключевымі словамі) можно объедінять в группы через запятую:
--[he=мужской|willow,wendy=женскій без Уіккерботтом]
--Прімер: "Скажі[plural=те], [пріятель|мілочка|созданіе|пріятелі|wickerbottom=дамочка], почему так[ой|ая|ое|іе] грустн[ый|ая|ое|ые]?"
--Необязательный параметр talker сообщает названіе префаба говорящего. Сейчас нужен для корректной обработкі сітуаціі с Веббером
function t.ParseTranslationTags(message, char, talker, optionaltags)
    if not (message and string.find(message,"[",1,true)) then return message end
    local gender="neutral"
    local function parse(str)
        local vars=split(str,"|")
        local tags={}
        local function SelectByCustomTags(CustomTags)
            if not CustomTags then return false end
            if type(CustomTags)=="string" then return tags[CustomTags] end
            for _,tag in ipairs(CustomTags) do
                if tags[tag] then return tags[tag] end
            end
            return false
        end
        local counter=0
        for i,v in pairs(vars) do
            local vars2=split(v,"=")
            if #vars2==1 then counter=counter+1 end
            local path=(#vars2==2) and vars2[1] or
                        (((counter==1) and "he")
            or ((counter==2) and "she")
            or ((counter==3) and "it")
            or ((counter==4) and "plural")
            or ((counter==5) and "neutral")
            or ((counter>5) and nil))
            if path then
                local vars3=split(path,",")
                for _,vv in ipairs(vars3) do
                    local c=vv and vv:match("^%s*(.*%S)")
                    c=c and c:lower()
                    if c=="they" or c=="pl" then c="plural"
                    elseif c=="nog" or c=="nogender" then c="neutral"
                    elseif c=="def" then c="default" end
                    if c then tags[c]=(#vars2==2) and vars2[2] or v end
                end
            end
        end
        str=tags and (tags[char] --сначала іщем по імені
        or SelectByCustomTags(t.CharacterInherentTags[char]) --потом по особым тегам персонажа
        or tags[gender] --потом пытаемся выбрать по полу персонажа
        or SelectByCustomTags(optionaltags) --потом іщем, есть лі в варіантах дополнітельные тегі
        or tags["default"] --ілі берём дефолтный тег
        or tags["neutral"] --еслі нічего не нашлі, пытаемся выбрать нейтральный варіант
        or tags["he"] --еслі і его нет, то мужской пол (это уже неправільно, но лучше, чем нічего)
        or "") or "" --ладно, нічего, значіт нічего
        return str
    end
    local function search(part)
        part=string.sub(part,2,-2)
        if not string.find(part,"[",1,true) then
            part=parse(part)
        else
            part=parse(part:gsub("%b[]",search))
        end
        return part
    end
    --Экраніруем тег заглавной буквы (виправлено: замінюємо на плейсхолдер "<adoptcase>", щоб потім обробити тільки його, а не весь текст)
    local CaseAdoptationNeeded
    message, CaseAdoptationNeeded = message:gsub("%[adoptcase]","<adoptcase>")
    --іщем тегі-маркеры, которые нужно добавіть в спісок optionaltags
    message=message:gsub("%[marker=(.-)]",function(marker)
        if not optionaltags then optionaltags={} 
        elseif type(optionaltags)=="string" then optionaltags={optionaltags} end
        table.insert(optionaltags,marker)
        return ""
    end)
    message=message:gsub("%[adoptadjective%.(.-)%.(.-)=(.-)]",function(gender, case, adjective)
        adjective = FixPrefix(adjective, case:lower(), gender:lower())
        return adjective
    end)
    if char then
        char=char:lower()
        if char=="generic" then char="wilson" end
        if rawget(_G,"CHARACTER_GENDERS") then
            if CHARACTER_GENDERS.MALE and table.contains(CHARACTER_GENDERS.MALE, char) then gender="he"
            elseif CHARACTER_GENDERS.FEMALE and table.contains(CHARACTER_GENDERS.FEMALE, char) then gender="she"
            elseif CHARACTER_GENDERS.ROBOT and table.contains(CHARACTER_GENDERS.ROBOT, char) then gender="he"
            elseif CHARACTER_GENDERS.IT and table.contains(CHARACTER_GENDERS.IT, char) then gender="it"
            elseif CHARACTER_GENDERS.NEUTRAL and table.contains(CHARACTER_GENDERS.IT, char) then gender="neutral"
            elseif CHARACTER_GENDERS.PLURAL and table.contains(CHARACTER_GENDERS.PLURAL, char) then gender="plural" end
        end
        --Еслі это Веббер і он говоріт сам о себе, то это множественное чісло
        if char=="webber" and (not talker or talker:lower()==char) then gender="plural" end
    end
    message=search("["..message.."]") or message
    if CaseAdoptationNeeded then
        -- Виправлено: обробка тільки для плейсхолдера "<adoptcase>", щоб не змінювати регістр всього повідомлення
        message=message:gsub("([^.!? ]?)(%s*)<adoptcase>(.)",function(before, space, symbol)
            if not before or before=="" then symbol=firsttoupper(symbol) else symbol=firsttolower(symbol) end
            return((before or "")..(space or "")..(symbol or ""))
        end)
    end
    return message
end

-- Загружаем спіч
require("blr_speech")

--Подменяем названія режімов ігры
if rawget(_G, "GAME_MODES") and STRINGS.UI.GAMEMODES then
	for i,v in pairs(GAME_MODES) do
		for ii,vv in pairs(STRINGS.UI.GAMEMODES) do
			if v.text==vv then
				GAME_MODES[i].text = t.PO["STRINGS.UI.GAMEMODES."..ii] or GAME_MODES[i].text
			end
			if v.description==vv then
				GAME_MODES[i].description = t.PO["STRINGS.UI.GAMEMODES."..ii] or GAME_MODES[i].description
			end
		end
	end
end

-- cклоняем названія вещей в пожітках
function GetSkinUsableOnString(item_type, popup_txt)
	local skin_data = GetSkinData(item_type)

	local skin_str = GetSkinName(item_type)

	local usable_on_str
	if skin_data ~= nil and skin_data.base_prefab ~= nil then
		local item1_str, item2_str, item3_str
		item1_str = t.BelarusianNames[STRINGS.NAMES[string.upper(skin_data.base_prefab)]] and t.BelarusianNames[STRINGS.NAMES[string.upper(skin_data.base_prefab)]]["RESKIN"] or rebuildname(STRINGS.NAMES[string.upper(skin_data.base_prefab)], "reskin", string.upper(skin_data.base_prefab))
        if skin_data.granted_items ~= nil then
            local granted_skin_data = GetSkinData(skin_data.granted_items[1])
            if granted_skin_data ~= nil and granted_skin_data.base_prefab ~= nil then
				item2_str = t.BelarusianNames[STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)]] and t.BelarusianNames[STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)]]["RESKIN"] or rebuildname(STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)], "reskin", string.upper(granted_skin_data.base_prefab))
                if item2_str == item1_str then
                    item2_str = nil
                end
            end
            granted_skin_data = GetSkinData(skin_data.granted_items[2])
            if granted_skin_data ~= nil and granted_skin_data.base_prefab ~= nil then
				item3_str = t.BelarusianNames[STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)]] and t.BelarusianNames[STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)]]["RESKIN"] or rebuildname(STRINGS.NAMES[string.upper(granted_skin_data.base_prefab)],"reskin",string.upper(granted_skin_data.base_prefab))
                if item2_str == nil and item3_str ~= item1_str then
                    item2_str = item3_str
                    item3_str = nil
                elseif item1_str == item3_str or item2_str == item3_str then
                    item3_str = nil
                end
            end
        end
        if item2_str == nil then
            usable_on_str = subfmt(popup_txt and STRINGS.UI.SKINSSCREEN.USABLE_ON_POPUP or STRINGS.UI.SKINSSCREEN.USABLE_ON, { skin = skin_str, item = item1_str })
        elseif item3_str == nil then
            usable_on_str = subfmt(popup_txt and STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE_POPUP or STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE, { skin = skin_str, item1 = item1_str, item2 = item2_str })
        else
            usable_on_str = subfmt(popup_txt and STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE_3_POPUP or STRINGS.UI.SKINSSCREEN.USABLE_ON_MULTIPLE_3, { skin = skin_str, item1 = item1_str, item2 = item2_str, item3 = item3_str })
        end
	end

	return usable_on_str or ""
end

require("widgets/eventannouncer")


function t.GetFromSpeechesHash(message, char)
	local function GetMentioned(message,char)
		if not (message and t.SpeechHashTbl[char] and t.SpeechHashTbl[char]["mentioned_class"] and type(t.SpeechHashTbl[char]["mentioned_class"])=="table") then return nil end
		for i,v in pairs(t.SpeechHashTbl[char]["mentioned_class"]) do
			local mentions={string.match(message,"^"..(string.gsub(i,"%%s","(.*)")).."$")}
			if mentions and #mentions>0 then
				return v, mentions --возвращаем перевод (с незаменённымі %s) і спісок отсылок
			end
		end
		return nil
	end
	local mentions
	if not char then char = "GENERIC" end
	if message and t.SpeechHashTbl[char] then
		local umlautified = false
		-- if char=="WATHGRITHR" then
		-- 	local tmp = message:gsub("[\246ö]","o"):gsub("[\214Ö]","O") or message --подменяем і 1251 і UTF-8 версіі
		-- 	umlautified = tmp~=message
		-- 	message = tmp
		-- end
		--переводім із хеш-табліцы родного персонажа ілі Уілсона (еслі не найден родной)
		local msg = t.SpeechHashTbl[char][message] or t.SpeechHashTbl["GENERIC"][message]
		if not msg and char=="WX78" then --Тут хеш-табліца не работает, пріходітся делать перебор
			for i, v in pairs(t.SpeechHashTbl["GENERIC"]) do
				if message==i:upper() then msg = v break end
			end
		end
		--в mentions попадает табліца всех найденных замен %s, еслі оні есть
		if not msg then msg, mentions = GetMentioned(message,char) end
		if not msg then msg, mentions = GetMentioned(message,"GENERIC") end
		message = msg or message
		--еслі есть разные варіанты переводов, то выбіраем одін із ніх случайным образом
		message = (type(message)=="table") and GetRandomItem(message) or message
		if char=="WATHGRITHR" and Profile:IsWathgrithrFontEnabled() then
			message = message:gsub("о","ö"):gsub("О","Ö") or message
		end
		-- if umlautified then
		-- 	if rawget(_G, "GetSpecialCharacterPostProcess") then
		-- 		--подменяем русскіе на англійскіе, чтобы работала Umlautify
		-- 		local tmp = message:gsub("о","o"):gsub("О","O") or message
		-- 		message = GetSpecialCharacterPostProcess("wathgrithr", tmp) or message
		-- 	else
		-- 		message = message:gsub("о","ö"):gsub("О","Ö") or message
		-- 	end
		-- end
	end
	return message, mentions
end

local function GetMentioned1(message)
	for i,v in pairs(t.SpeechHashTbl.GOATMUM_CRAVING_HINTS.Eng2Be) do
		local regex=string.gsub(i,"%.","%%.")
		regex=string.gsub(regex,"{craving}","(.-)")
		regex=string.gsub(regex,"{part2}","(.+)")
		-- print(regex)
		local mentions={string.match(message,"^"..(regex).."$")}
		if mentions and #mentions>0 and  string.find(mentions[1],'%.%.%.')==nil then
			-- print(v,mentions[1])
			-- if #mentions>1 then print(mentions[2]) end
			return v, mentions --возвращаем перевод (с незаменённымі %s) і спісок отсылок
		end
	end
	return nil
end

function GetMortalityStringFor(target)
	local mortalitystring = STRINGS.UI.MORTALITYSTRINGS.DEFAULT

	if target ~= nil then 
		local hands_equip = nil
		if target.replica.inventory and target.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= nil then
			hands_equip = target.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS).prefab
		end
		
		if hands_equip ~= nil and hands_equip == "voidcloth_scythe" then
			if STRINGS.UI.MORTALITYSTRINGS[string.upper(target.prefab)] then
				mortalitystring = STRINGS.UI.MORTALITYSTRINGS[string.upper(target.prefab)] .. "-c-c"
			else
				mortalitystring = "c-c-" .. STRINGS.UI.MORTALITYSTRINGS.DEFAULT
			end
		else
			mortalitystring = STRINGS.UI.MORTALITYSTRINGS[string.upper(target.prefab)] or STRINGS.UI.MORTALITYSTRINGS.DEFAULT
		end
	end	

    return mortalitystring
end

--[[
--Формірует тестовую функцію для проверкі перевода
if not rawget(_G,"test") then
	ch_nm("HE","he","he")
	ch_nm("HE2","he2","he2")
	ch_nm("SHE","she","she")
	ch_nm("IT","it","it")
	ch_nm("PLURAL","plural","plural")
	ch_nm("PLURAL2","plural2","plural2")

	local genders_reg={"he","he2","she","it","plural","plural2", --numbers
		he="he",he2="he2",she="she",it="it",plural="plural",plural2="plural2"};
	rawset(_G,"test",function(name,gender)
		print('-------------------------------------')
		if genders_reg[gender] then
			gender = genders_reg[gender]
			testname(name,gender)
			print("("..gender..")")
		else
			testname(name,"he")
			print("(he - default)")
		end
	end)
	--Прімер работы функціі: test("Пастіла","she")
	--ілі: test("Пастіла",3) --был убіт пастілой
	--ілі неправільный варіант: test("Пастіла",2) --был убіт пастіла
end
]]

--Переводіт сообщеніе на русскій, пользуясь хеш-табліцамі
--message - сообщеніе на англійском
--entity - ссылка на говорящего это сообщеніе персонажа
function t.TranslateToBelarusian(message, entity)
	t.print("t.TranslateToBelarusian", message, entity.prefab)

	if not (entity and entity.prefab and entity.components.talker and type(message)=="string") then return message end

	local new_line = string.find(message,"\n",1,true)
	if new_line ~= nil then
		local mess1 = message:sub(1, new_line - 1)
		if t.mod_phrases[mess1] then
			local mess2 = message:sub(new_line)
			return t.mod_phrases[mess1] .. mess2
		end
	elseif t.mod_phrases[message] then
		return t.mod_phrases[message]
	end

	if entity:HasTag("playerghost") then --Еслі это репліка ігрока-прівіденія
		message=string.gsub(message, "h", "у")
		return message
	end

	if entity.prefab == "quagmire_goatmum" then
		if t.SpeechHashTbl.GOATMUM_WELCOME_INTRO.Eng2Be[message] then
			return t.SpeechHashTbl.GOATMUM_WELCOME_INTRO.Eng2Be[message]
		end

		local NotTranslated=message
		local msg, mentions=GetMentioned1(message)
		message=msg or message

		if NotTranslated==message then return message end
		local part2
		local craving
		if mentions and #mentions>0 and mentions[1] then
			craving=t.SpeechHashTbl.GOATMUM_CRAVING_MAP.Eng2Be[mentions[1]]
			if #mentions>1 then
				part2=t.SpeechHashTbl.GOATMUM_CRAVING_HINTS_PART2.Eng2Be[mentions[2]]
			end
			if  #mentions==1 and craving then
				message=string.format(message,craving)
			elseif #mentions==2 and craving and part2 then
				message=string.format(message,craving,part2)
			end
		end
		return message
	elseif entity.prefab == "monkeyqueen" then -- реплікі Королевы лунной прістані
		if t.SpeechHashTbl.MONKEY_QUEEN.Eng2Be[message] then
			message = t.SpeechHashTbl.MONKEY_QUEEN.Eng2Be[message] or message
		end
	elseif entity.prefab == "mermking" then -- реплікі Короля мэрмов
		if t.SpeechHashTbl.MERM_KING.Eng2Be[message] then
			message = t.SpeechHashTbl.MERM_KING.Eng2Be[message] or message
		end
	end

	-- осмотр надгробій	
	if t.SpeechHashTbl.EPITAPHS.Eng2Be[message] then
		message = t.SpeechHashTbl.EPITAPHS.Eng2Be[message] or message
	end

	local ent = entity
	entity = entity.prefab:upper()
	if entity == "WILSON" or entity == "WONKEY" then entity = "GENERIC" end
	if entity == "MAXWELL" then entity = "WAXWELL" end
	if entity == "WIGFRID" then entity = "WATHGRITHR" end

	--Обработка сообщенія
	local function TranslateMessage(message)
		--Получаем перевод реплікі і спісок отсылок %s, еслі оні есть в репліке
		if not message then return end
		local NotTranslated=message
		local msg, mentions=t.GetFromSpeechesHash(message,entity)
		message=msg or message

		if NotTranslated==message then return (t.ParseTranslationTags(message, ent.prefab, nil, nil)) or message end

		local killerkey
		if mentions then
			if #mentions>1 then
				killerkey=t.SpeechHashTbl.NAMES.Eng2Key[mentions[2]] --Получаем ключ імені убійцы
				if not killerkey and entity=="WX78" then --тут только полный перебор, т.к. он говоріт всё в верхнем регістре
					for eng, key in pairs(t.SpeechHashTbl.NAMES.Eng2Key) do
						if eng:upper()==mentions[2] then killerkey = key break end
					end
				end
				mentions[2]=killerkey and STRINGS.NAMES[killerkey] or mentions[2]
				if killerkey then
					mentions[2]=t.BelarusianNames[mentions[2]] and t.BelarusianNames[mentions[2]]["KILL"] or rebuildname(mentions[2],"KILL",killerkey) or mentions[2]
					if not t.ShouldBeCapped[killerkey:lower()] and not table.contains(GetActiveCharacterList(), killerkey:lower()) then
						mentions[2]=firsttolower(mentions[2])
					end
					killerkey=killerkey:lower()
					if table.contains(GetActiveCharacterList(), killerkey) then killerkey=nil end
				end
			end
		end
		--Подстраіваем сообщеніе под пол персонажа
		message=(t.ParseTranslationTags(message, ent.prefab, nil, killerkey)) or message
		--Добавляем запісям віда "чісло%" дополнітельный знак % для работы функціі string.format
		message=string.gsub(message, "%d%%", "%1%%")
		--Подставляем імена, еслі оні есть
		message=string.format(message, unpack(mentions or {"","","",""}))
		if entity=="WX78" then
			message=belarusianupper(message) or message
		end
		return message
	end

	--Делім репліку на кускі із строк по переносу строкі
	--Это нужно для совместімості с модамі, которые что-то добавляют в репліку через \n
	local messages=split(message,"\n") or {message}
	message=""
	local i=1
	--Пытаемся перевесті по отдельності і парамі, потому что есть реплікі із двух строк
	while i<=#messages do
		local trans
		trans=TranslateMessage(messages[i])
		if trans~=messages[i] then --Получілі перевод реплікі
			message=message..(i>1 and "\n" or "")..trans
			if i<#messages then --Еслі репліка не последняя
				--Переводім, еслі получітся, следующую строку
				message=message..TranslateMessage("\n"..messages[i+1])
				--Собіраем оставшіеся строкі
				for k=i+2,#messages do message=message.."\n"..messages[k] end
			end
			break --выходім із цікла
		elseif i<#messages then --не получілі, пытаемся объедініть со следующей і перевесті
			trans=TranslateMessage(messages[i].."\n"..messages[i+1])
			if trans~=messages[i].."\n"..messages[i+1] then --Получілось перевесті обе
				--Добавляем перевод
				message=message..(i>1 and "\n" or "")..trans
				--Собіраем оставшіеся строкі
				for k=i+2,#messages do message=message.."\n"..messages[k] end
				break --выходім із цікла
			else--Обе не перевелісь
				message=message..(i>1 and "\n" or "")..messages[i]
				i=i+1 --переходім к следующей репліке (она отдельно ещё не проверялась)
			end
		else --это была последняя, і она не перевелась
			message=message..(i>1 and "\n" or "")..messages[i]
			break
		end
	end
	return message
end

-- --Перевод сообщенія на русскій на стороне кліента
-- local _Networking_Talk = Networking_Talk
-- function Networking_Talk(guid, message, ...)
-- 	local entity = Ents[guid]
-- 	t.print("Networking_Talk", entity, message)
-- 	message = t.TranslateToBelarusian(message, entity) or message --Переводім на русскій
-- 	return _Networking_Talk(guid, message, ...)
-- end

-- ісправленіе умлаутов Вігфрід в чате
local _Networking_Say = Networking_Say
function Networking_Say(guid, userid, name, prefab, message, ...)
	if prefab=="wathgrithr" and Profile:IsWathgrithrFontEnabled() then
		message = message:gsub("о","ö"):gsub("О","Ö"):gsub("O","Ö"):gsub("o","ö") or message
	end
	return _Networking_Say(guid, userid, name, prefab, message, ...)
end

-- --Перевод на русскій проізносімого на сервере
-- local _Talker = NetworkProxy.Talker
-- NetworkProxy.Talker = function(self, message, entity, ...)
-- 	t.print("entity", entity)
-- 	local inst = entity and entity:GetGUID() or nil
-- 	inst = inst and Ents[inst] or nil --определяем інстанс персонажа по entity

-- 	if inst and message then
-- 		message = t.TranslateToBelarusian(message, inst) or message --переводім
-- 	end

-- 	return _Talker(self, message, entity, ...)
-- end

--Сообщенія о событіях в ігре
-- AddClassPostConstruct("widgets/eventannouncer", function(self)
-- 	--Вывод любых анонсов на экран. Тут подменяем все нестандартные фразы, і не только
-- 	local _ShowNewAnnouncement = self.ShowNewAnnouncement
-- 	if _ShowNewAnnouncement then function self:ShowNewAnnouncement(announcement, ...)

-- 		local gender, player, BelarusianMessage, name, name2, killerkey

-- 		local function test(adder1,msg1,rusmsg1,adder2,msg2,rusmsg2,ending)
-- 			--print("Test:", tostring(adder1), tostring(msg1), tostring(rusmsg1), tostring(adder2), tostring(msg2), tostring(rusmsg2), tostring(ending))
-- 			if name or name2 then return end
-- 			msg1=msg1 and msg1:gsub("([.%-?])","%%%1"):gsub("%%s","(.*)") or ""
-- 			msg2=msg2 and msg2:gsub("([.%-?])","%%%1"):gsub("%%s","(.*)") or ""
-- 			name, name2=announcement:match((adder1 or "")..msg1..(adder2 or "")..msg2)
-- 			if name then BelarusianMessage=rusmsg1 end
-- 			if adder2 and name and name2 and rusmsg2 then BelarusianMessage=BelarusianMessage..rusmsg2 end
-- 			if ending and BelarusianMessage then BelarusianMessage=BelarusianMessage..ending end
-- 		end
-- 		--Проверяем голосованія
-- --			test(nil,STRINGS.VOTING.KICK.START, announcerus.VOTINGKICKSTART)
-- --			test(nil,STRINGS.VOTING.KICK.SUCCESS, announcerus.VOTINGKICKSUCCESS)
-- --			test(nil,STRINGS.VOTING.KICK.FAILURE, announcerus.VOTINGKICKFAILURE)
-- 		--Прісоедіненіе/Отсоедіненіе
-- --		--C 176665 в этіх двух ізначально есть %s
-- --		test("(.*) ",STRINGS.UI.NOTIFICATION.JOINEDGAME, announcerus.JOINEDGAME)
-- --		test("(.*) ",STRINGS.UI.NOTIFICATION.LEFTGAME, announcerus.LEFTGAME)
-- 		test(nil,STRINGS.UI.NOTIFICATION.JOINEDGAME, announcerus.JOINEDGAME)
-- 		test(nil,STRINGS.UI.NOTIFICATION.LEFTGAME, announcerus.LEFTGAME)
-- 		--Кік/Бан
-- 		test(nil,STRINGS.UI.NOTIFICATION.KICKEDFROMGAME, announcerus.KICKEDFROMGAME)
-- 		test(nil,STRINGS.UI.NOTIFICATION.BANNEDFROMGAME, announcerus.BANNEDFROMGAME)

-- 		-- Даем возможность модам переводіть аннонсы
-- 		for eng, rus in pairs(t.mod_announce) do
-- 			test(nil, eng, rus)
-- 		end

-- 		--Новый скін
-- --		test(nil,STRINGS.UI.NOTIFICATION.NEW_SKIN_ANNOUNCEMENT, announcerus.NEW_SKIN_ANNOUNCEMENT)
-- 		if not name2 then
-- 			--Реплікі о смерті
-- 			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcerus.DEATH_ANNOUNCEMENT_1,
-- 				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_MALE, announcerus.DEATH_ANNOUNCEMENT_2_MALE)
-- 			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcerus.DEATH_ANNOUNCEMENT_1,
-- 				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_FEMALE, announcerus.DEATH_ANNOUNCEMENT_2_FEMALE)
-- 			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcerus.DEATH_ANNOUNCEMENT_1,
-- 				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_ROBOT, announcerus.DEATH_ANNOUNCEMENT_2_ROBOT)
-- 			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcerus.DEATH_ANNOUNCEMENT_1,
-- 				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT, announcerus.DEATH_ANNOUNCEMENT_2_DEFAULT)
-- 			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcerus.DEATH_ANNOUNCEMENT_1, " (.*)%.$", nil, nil, ".")
-- 			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_MALE, announcerus.GHOST_DEATH_ANNOUNCEMENT_MALE)
-- 			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_FEMALE, announcerus.GHOST_DEATH_ANNOUNCEMENT_FEMALE)
-- 			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_ROBOT, announcerus.GHOST_DEATH_ANNOUNCEMENT_ROBOT)
-- 			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_DEFAULT, announcerus.GHOST_DEATH_ANNOUNCEMENT_DEFAULT)
-- 			--Репліка об ожівленіі
-- 			test("(.*) ",STRINGS.UI.HUD.REZ_ANNOUNCEMENT, announcerus.REZ_ANNOUNCEMENT, " (.*)%.$", nil, nil, ".")
-- 			if name2 then --Было обнаружено второе імя, і это сообщеніе о смерті/ожівленіі
-- 				--Переводім імя на русскій, еслі получітся
-- 				killerkey=t.SpeechHashTbl.NAMES.Eng2Key[name2] --Получаем ключ імені
-- 				if killerkey then
-- 					name2=STRINGS.NAMES[killerkey] or STRINGS.NAMES["SHENANIGANS"] --Тут переводім імя на русскій
-- 					name2=t.BelarusianNames[name2] and t.BelarusianNames[name2]["KILL"] or rebuildname(name2,"KILL",killerkey) or name2
-- 					if not t.ShouldBeCapped[killerkey:lower()] and not table.contains(GetActiveCharacterList(), killerkey:lower()) then
-- 						name2=firsttolower(name2)
-- 					end
-- 					killerkey=killerkey:lower()
-- 					if table.contains(GetActiveCharacterList(), killerkey) then killerkey=nil end
-- 				end
-- 			end
-- 		end
-- 		if name and BelarusianMessage then
-- 			announcement = string.format((t.ParseTranslationTags(BelarusianMessage, "wilson", "announce", killerkey)), name or "", name2 or "", "" ,"") or announcement
-- 		end
-- 		return _ShowNewAnnouncement(self, announcement, ...)
-- 	end end
-- end) -- для AddClassPostConstruct "widgets/eventannouncer"

--Тут мы должны переделать опісаніе скелета, чтобы в него не попал русскій
-- Жуть какая. Столько кода просто для перевода скелета
-- AddPrefabPostInit("skeleton_player", function(inst)
-- 	local function reassignfn(inst) --функція переопределяет функцію. Туповато, но менять лень
-- 		inst.components.inspectable.Oldgetspecialdescription=inst.components.inspectable.getspecialdescription
-- 		function inst.components.inspectable.getspecialdescription(inst, viewer, ...)
-- 			local oldGetDescription=GetDescription
-- 			GetDescription=function(viewer1, inst1, tag)
-- 				local ret=oldGetDescription(viewer1, inst1, tag)
-- 				ret=t.ParseTranslationTags(ret, inst1.cause, nil, nil)
-- 				return ret
-- 			end
-- 			local message=inst.components.inspectable.Oldgetspecialdescription(inst, viewer, ...)
-- 			GetDescription=oldGetDescription
-- 			if not message then return message end

-- 			local player=ThePlayer
-- 			local key=player and player.prefab:upper() or "GENERIC"
-- --				local key=inst.char:upper()
-- 			local deadgender=GetGenderStrings(inst.char)
-- 			local m=STRINGS.CHARACTERS[key] and STRINGS.CHARACTERS[key].DESCRIBE and STRINGS.CHARACTERS[key].DESCRIBE.SKELETON_PLAYER and STRINGS.CHARACTERS[key].DESCRIBE.SKELETON_PLAYER[deadgender] or STRINGS.CHARACTERS.GENERIC.DESCRIBE.SKELETON_PLAYER[deadgender]
-- 			m=t.ParseTranslationTags(m, inst.cause, nil, nil)
-- 			if not m then return message end
-- 			local dead,killer=string.match(message,(string.gsub(m,"%%s","(.*)"))) --вытасківаем імена із сообщенія
-- 			if not (m and dead and killer) then return message end

-- 			dead=inst.playername or t.SpeechHashTbl.NAMES.Be2Eng[dead] or dead --переводім на англійскій імя убітого
-- 			if t.SpeechHashTbl.NAMES.Be2Eng[killer] and inst.pkname == nil then
-- 				local mentions=t.SpeechHashTbl.NAMES.Be2Eng[killer]
-- 				local killerkey=t.SpeechHashTbl.NAMES.Eng2Key[mentions] --Получаем ключ імені убійцы
-- 				t.print("[BLR DEBUG] 2302 "..killerkey)

-- 				if not killerkey and key=="WX78" then --тут только полный перебор, т.к. он говоріт всё в верхнем регістре
-- 					for eng, key in pairs(t.SpeechHashTbl.NAMES.Eng2Key) do
-- 						if eng:upper()==mentions then killerkey = key break end
-- 					end
-- 				end

-- 				mentions=killerkey and STRINGS.NAMES[killerkey] or mentions
-- 				if killerkey then
-- 					mentions=t.BelarusianNames[mentions] and t.BelarusianNames[mentions]["KILL"] or rebuildname(mentions,"KILL",killerkey) or mentions
-- 					if not t.ShouldBeCapped[killerkey:lower()] and not table.contains(GetActiveCharacterList(), killerkey:lower()) then
-- 						mentions=firsttolower(mentions)
-- 					end

-- 					killerkey=killerkey:lower()
-- 					if table.contains(GetActiveCharacterList(), killerkey) then
-- 						killerkey=nil
-- 					end
-- 				end

-- 				killer=mentions
-- 			else
-- 				killer=t.SpeechHashTbl.NAMES.Be2Eng[killer] or killer --Переводім на англійскій імя убійцы
-- 			end

-- 			message=string.format(m,dead,killer)
-- 			return message
-- 		end
-- 	end
-- 	if inst.SetSkeletonDescription and not inst.OldSetSkeletonDescription then
-- 		inst.OldSetSkeletonDescription=inst.SetSkeletonDescription
-- 		function inst.SetSkeletonDescription(inst, ...)
-- 			inst.OldSetSkeletonDescription(inst, ...)
-- 			reassignfn(inst)
-- 		end
-- 	end
-- 	if inst.OnLoad and not inst.OldOnLoad then
-- 		inst.OldOnLoad=inst.OnLoad
-- 		function inst.OnLoad(inst, ...)
-- 			inst.OldOnLoad(inst, ...)
-- 			reassignfn(inst)
-- 		end
-- 	end
-- end)

--Тут мы должны перехватывать названіе предмета у blueprint і переводіть на англійскій
-- TODO: проверіть работу AddPrefabPostInit
AddPrefabPostInit("blueprint", function(inst)
	local function reassignfn(inst)
		if inst.recipetouse then
			local name = STRINGS.NAMES[string.upper(inst.recipetouse)] or STRINGS.NAMES[inst.recipetouse]
			if name then
				name = t.SpeechHashTbl.NAMES.Be2Eng[name] or name
				inst.components.named:SetName(name.." Blueprint")
			end
		end
	end
	if inst.OnLoad and not inst.OldOnLoad then
		inst.OldOnLoad=inst.OnLoad
		function inst.OnLoad(inst, data)
			if data and data.recipetouse and not STRINGS.NAMES[string.upper(data.recipetouse)] then
				STRINGS.NAMES[string.upper(data.recipetouse)]="Прадмет з адключанай мадыфікаці"
				inst.OldOnLoad(inst, data)
				STRINGS.NAMES[string.upper(data.recipetouse)]=nil
			else
				inst.OldOnLoad(inst, data)
			end
			reassignfn(inst)
		end
	end
	reassignfn(inst)
end)

--Остальное не выполняется, еслі перевод в режіме только чата
do
	--Вешает хук на любой метод класса указанного объекта.
	--Функція fn получает в качестве параметров ссылку на объект і все параметры перехватываемого метода.
	--DoAfter определяет, выполняется лі хук до, ілі после метода.
	--Еслі функція fn выполняется до метода і возвращает результат, то этот результат счітается табліцей і распаковывается в качестве параметров орігінального метода.
	--ExecuteNow прігодітся, еслі нужно выполніть действіе сразу в момент установкі хука.
	local function SetHookFunction(obj, method, fn, DoAfter, ExecuteNow, ...)
		if obj and method and type(method)=="string" and fn and type(fn)=="function" then
			if ExecuteNow then fn(obj, ...) end
			if obj[method] then
				local Old=obj[method]
				obj[method]=function(obj, ...)
					local params={...}
					if not DoAfter then local a={fn(obj, ...)} if #a>0 then params=a end end
					Old(obj, unpack(params))
					if DoAfter then fn(obj, ...) end
				end
			end
		end
	end

	--Подменяем портреты
	local TRANSLATED_LIST = {
		wortox = true,
		warly = true,
		wanda = true,
		wurt = true,
		winona = true,
		wickerbottom = true,
		waxwell = true,
		willow = true,
		wilson = true,
		woodie = true,
		wes = true,
		wolfgang = true,
		wendy = true,
		wathgrithr = true,
		webber = true,
		wormwood = true,
		walter = true,

		random = true,
	}

	require("characterutil")

	local _SetHeroNameTexture_Grey = SetHeroNameTexture_Grey
	local _SetHeroNameTexture_Gold = SetHeroNameTexture_Gold

	function SetHeroNameTexture_Grey(w, hero, ...)
		if TRANSLATED_LIST[hero] then
			w:SetTexture("images/blr_names_"..hero..".xml", "blr_"..hero..".tex")
			return true
		end
		return _SetHeroNameTexture_Grey(w, hero, ...)
	end

	function SetHeroNameTexture_Gold(w, hero, ...)
		if TRANSLATED_LIST[hero] then
			w:SetTexture("images/blr_names_gold_"..hero..".xml", "blr_"..hero..".tex")
			return true
		end
		return _SetHeroNameTexture_Gold(w, hero, ...)
	end

	AddClassPostConstruct("screens/playerstatusscreen", function(self)
		if self.OnBecomeActive then
			local OldOnBecomeActive = self.OnBecomeActive
			function self:OnBecomeActive(...)
				local res = OldOnBecomeActive(self, ...)
					if self.player_widgets then
						for _, v in pairs(self.player_widgets) do
							if v.age and v.age.SetString then
								local OldSetString = v.age.SetString
								function v.age:SetString(str, ...)
									if str then
										str = str:gsub("(%d+)(.+)", function (days, word)
											if word~=STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAY and word~=STRINGS.UI.PLAYERSTATUSSCREEN.AGE_DAYS then return end
											return days.." "..StringTime(days)
										end)
									end
									local res = OldSetString(self, str, ...)
									return res
								end
								v.age:SetString(v.age:GetString())
							end
						end
					end
				return res
			end
		end
	end)

	AddClassPostConstruct("widgets/uiclock", function(self)
		if self._text and self._text.SetString then
			local OldSetString = self._text.SetString
			function self._text:SetString(str, ...)
				if str then
					str = str:gsub(STRINGS.UI.HUD.CLOCKSURVIVED.."(.+)(%d+)(%s+)(.+)", function (sep1, days, sep2, word)
						if word~=STRINGS.UI.HUD.CLOCKDAY and word~=STRINGS.UI.HUD.CLOCKDAYS then return end
						return StringTime(days, {"Пражыты", "Пражыта", "Пражыта"})..sep1..days..sep2..StringTime(days)
					end)
				end
				local res = OldSetString(self, str, ...)
				return res
			end
		end
	end)

	AddClassPostConstruct("widgets/playeravatarpopup", function(self)
		local _UpdateData = self.UpdateData
		function self:UpdateData(data)
			_UpdateData(self, data)
			if self.age and data.playerage then
				local newstr=self.age:GetString()
				newstr = newstr:gsub("Пражыта", StringTime(data.playerage, {"Пражыты", "Пражыта", "Пражыта"}),1)
				self.age:SetString(newstr:gsub("Дзён", StringTime(data.playerage),1))
			end
		end
	end)

	--Окно просмотра серверов, двігаем контролсы, ісправляем надпісі
	local function ServerListingScreenPost1(self)
		if self.filters then
			for i, v in pairs(self.filters) do
				if v.label and v.label.SetFont then
					v.label:SetFont(CHATFONT)
				end
				if v.spinner and v.spinner.SetFont then
					v.spinner:SetFont(CHATFONT)
				end
			end
		end
		if self.title then
			local checkstr = STRINGS.UI.SERVERLISTINGSCREEN.SERVER_LIST_TITLE_INTENT:gsub("%%s", "(.+)")
			local intentions = {}
			for key, str in pairs(STRINGS.UI.INTENTION) do intentions[str] = key end
			local OldSetString = self.title.SetString
			function self.title:SetString(str, ...)
				if str then
					local int = str:match(checkstr)
					if int and intentions[int] then
						if intentions[int]=="SOCIAL" then
							str = "Сяброўскія серверы"
						elseif intentions[int]=="COOPERATIVE" then
							str = "Камандныя серверы"
						elseif intentions[int]=="COMPETITIVE" then
							str = "Спаборныя серверы"
						elseif intentions[int]=="MADNESS" then
							str = "«Шалёныя» серверы"
						elseif intentions[int]=="ANY" then
							str = "Серверы ўсіх стыляў"
						end
					end
				end
				local res = OldSetString(self, str, ...)
				return res
			end
			self.title:SetString(self.title:GetString())
		end
		if self.sorting_spinner and self.sorting_spinner.label then
			self.sorting_spinner.label:Nudge({x=-40,y=0,z=0})
			self.sorting_spinner.label:SetRegionSize(150,50)
		end
		if self.season_description and self.season_description.text then
			local OldSetString = self.season_description.text.SetString
			if OldSetString then
				function self.season_description.text:SetString(str, ...)
					if str:find("Лета")~=nil then
						if str:find("Ранняя")~=nil then
							str=str:gsub("Ранняя","Ранняе")
						elseif str:find("Позняя")~=nil then
							str=str:gsub("Позняя","Позняе")
						end
					end
					local res = OldSetString(self, str, ...)
					return res
				end
			end
		end
	end
	AddClassPostConstruct("screens/redux/serverlistingscreen", ServerListingScreenPost1)


	do
		-- Named ігноріт перевод і отправляет сроку прям с сервера
		local NAMES_OVERRIDE = {
			moose = {STRINGS.NAMES.MOOSE1, STRINGS.NAMES.MOOSE2},
			mooseegg = { STRINGS.NAMES.MOOSEEGG1, STRINGS.NAMES.MOOSEEGG2 },
		}

		AddClassPostConstruct("components/named_replica", function(self)
			local possible_names = NAMES_OVERRIDE[self.inst]

			local function OnNameDirty(inst)
				if inst.prefab == "sketch" then
					local sketch_name = ""

					if not TheWorld.ismastersim then
						sketch_name = inst.name:gsub("(%a+)%sFigure%sSketch", "%1")
						sketch_name = "CHESSPIECE_"..sketch_name:gsub(" ", ""):upper()
						sketch_name = STRINGS.NAMES[sketch_name] or inst.name
						sketch_name = sketch_name:gsub("Фігура", "Накід фігуры")
					else
						sketch_name = inst.name:gsub("Фігура", "фігуры")
					end

					inst.name = sketch_name
				elseif possible_names ~= nil then
					inst.name = possible_names[math.random(#inst.possible_names)]
				end
			end

			self.inst:ListenForEvent("namedirty", OnNameDirty)
			self.inst:DoTaskInTime(0, OnNameDirty)
		end)
	end

	--Сохраняем непереведённый текст настроек пріватності серверов в свойствах міра (см. ніже)
	local privacy_options = {}
	for i,v in pairs(STRINGS.UI.SERVERCREATIONSCREEN.PRIVACY) do
		privacy_options[v] = i
	end

	-- перевод ServerDetailIcon HoverText
	-- согласованіе окончанія сезона, разделеніе дня
	AddClassPostConstruct("widgets/redux/serversaveslot", function(self)		
		self.cloud:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.CLOUD_SAVE_HOVER)
		self.mods:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.MODS_ICON_HOVER)
		self.pvp:SetHoverText(STRINGS.UI.SERVERLISTINGSCREEN.PVP_ICON_HOVER)

		local oldSetSaveSlot = self.SetSaveSlot
		function self:SetSaveSlot(slot, server_data)
			oldSetSaveSlot(self, slot, server_data)
			self.slot = slot

			local Levels = require "map/levels"	
			local server_data = server_data or ShardSaveGameIndex:GetSlotServerData(self.slot)
			local privacy_options = { 
				STRINGS.UI.SERVERCREATIONSCREEN.PRIVACY.PUBLIC,
				STRINGS.UI.SERVERCREATIONSCREEN.PRIVACY.FRIENDS,
				STRINGS.UI.SERVERCREATIONSCREEN.PRIVACY.LOCAL,
				STRINGS.UI.SERVERCREATIONSCREEN.PRIVACY.CLAN,
			}			

			if server_data and server_data.privacy_type then
				self.privacy:SetHoverText(privacy_options[server_data.privacy_type+1])
			end

			if server_data and server_data.playstyle then
				local playstyle_def = server_data.playstyle ~= nil and Levels.GetPlaystyleDef(server_data.playstyle) or nil

				if playstyle_def ~= nil then
					self.playstyle:SetHoverText(STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[playstyle_def.default_preset])
				end
			end

			local DayAndSeasonText = self.serverslotscreen:GetDayAndSeasonText(self.slot)
			if DayAndSeasonText:find("Лета") ~= nil then
				if DayAndSeasonText:find("Ранняя") ~= nil then
					DayAndSeasonText = DayAndSeasonText:gsub("Ранняя","Ранняе")
				elseif DayAndSeasonText:find("Позняя") ~= nil then
					DayAndSeasonText = DayAndSeasonText:gsub("Позняя","Позняе")
				end
			end
			if DayAndSeasonText:find(" Дзень") ~= nil then
				DayAndSeasonText = DayAndSeasonText:gsub(" Дзень",", Дзень")
			end

			DayAndSeasonText = firsttoupper(belarusianlower(DayAndSeasonText))

			self.day_and_season:SetString(DayAndSeasonText)
		end
	end)

	-- перевод настроек пріватності сервера
	AddClassPostConstruct("widgets/redux/serversettingstab", function(self)
		local oldUpdateSlot = self.UpdateSlot
		function self:UpdateSlot()
			oldUpdateSlot(self)
			for i,v in ipairs(self.privacy_type.buttons.buttonwidgets) do
				v.button.text:SetFont(NEWFONT)
				v.button:SetTextSize(self.privacy_type.buttons.buttonsettings.font_size-2)
			end
		end

		if self.privacy_type and self.privacy_type.buttons and self.privacy_type.buttons.buttonwidgets then
			for _,option in pairs(self.privacy_type.buttons.options) do
				if privacy_options[option.text] then
					option.text = STRINGS.UI.SERVERCREATIONSCREEN.PRIVACY[ privacy_options[option.text] ]
				end

			end
		end
	end)

	-- перевод віджета выбора свойств міра
	AddClassPostConstruct("widgets/redux/worldsettings/settingslist", function(self)
		local num_columns = 3

		function self:RefreshOptionItems()			
			local opts_text = { ["No Day"]="Без дню", ["No Dusk"]="Без вечара", ["No Night"]="Без ночы", ["Long Day"]="Доўгі дзень", 
							  ["Long Dusk"]="Доўгі вечар", ["Long Night"]="Доўгая ноч", ["Only Day"]="Толькі дзень", 
							  ["Only Dusk"]="Толькі вечар", ["Only Night"]="Толькі ноч", ["Auto"]="Аўтаматычна", ["Underground"]="Пад зямлёю" }

		    if not self.scroll_list then return end
		    self.options = self.parent_widget:GetOptions()
		    self.optionitems = {}
		    local lastgroup = nil

		    for i,v in ipairs(self.options) do
		        if v.group ~= lastgroup then
		            local wrapped_index = #self.optionitems % num_columns
		            if wrapped_index > 0 then
		                for col = wrapped_index + 1, num_columns do
		                    table.insert(self.optionitems, {is_empty = true})
		                end
		            end
					-- добавленіе і перевод заголовков
		            table.insert(self.optionitems, {heading_text = STRINGS.UI.SANDBOXMENU[t.SpeechHashTbl.SANDBOXMENU.Eng2Key[v.grouplabel]] or v.grouplabel})
		            for col = 2, num_columns do
		                table.insert(self.optionitems, {is_empty = true})
		            end
		            lastgroup = v.group
		        end
				if v.options then
					for ii,vv in pairs(v.options) do
						-- добавленіе і перевод значеній спінеров
						v.options[ii].text = opts_text[vv.text] or STRINGS.UI.SANDBOXMENU[t.SpeechHashTbl.SANDBOXMENU.Eng2Key[vv.text]] or vv.text
					end
				end
		        table.insert(self.optionitems, {option = v})
		    end
		    local wrapped_index = #self.optionitems % num_columns
		    if wrapped_index > 0 then
		        for col = wrapped_index + 1, num_columns do
		            table.insert(self.optionitems, {is_empty = true})
		        end
		    end

		    self.forceupdate = true
		    self.scroll_list:SetItemsData(self.optionitems)
		    self.forceupdate = false
		    self.scroll_list:SetPosition(self.scroll_list:CanScroll() and -15 or 0, 0)
		end
	end)

	-- расшіреніе блока опісанія стіля ігры сервера
	AddClassPostConstruct("screens/redux/playstyleselectscreen", function(self)
		local oldUpdateStyleInfo = self.UpdateStyleInfo
		function self:UpdateStyleInfo(w)
			if self and self.description and w and w.settings_desc then
				self.description:SetMultilineTruncatedString(w.settings_desc, 3, 750, nil, true, true)
			end
		end
	end)

--Перегоняем перевод в STRINGS
TranslateStringTable(STRINGS)

	do
		local Levels = require("map/levels")

		-- шаблоны настроек (пресеты) прі созданіі міра [для presetpopupscreen]
		-- перевод імені
		local oldGetList = Levels.GetList
		Levels.GetList = function(category, ...)		
			local ret = oldGetList(category, ...)		
			for i, data in ipairs(ret) do
				if data.text ~= nil then
					ret[i].text = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[data.data] or data.text
				end
			end		

			return ret
		end
		-- перевод опісанія [для presetpopupscreen]
		local oldGetDataForSettingsID = Levels.GetDataForSettingsID
		Levels.GetDataForSettingsID = function(data, ...)
			local ret = oldGetDataForSettingsID(data, ...)		
			ret.settings_desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[data] or ret.settings_desc

			return ret
		end

		-- імя і опісаніе стіля ігры
		local oldGetPlaystyleDef = Levels.GetPlaystyleDef
		Levels.GetPlaystyleDef = function(playstyle_id)
			local ret = oldGetPlaystyleDef(playstyle_id)		
			ret.name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[ret.default_preset] or ret.name
			ret.desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[ret.default_preset] or ret.desc

			return ret
		end
	end

	-- перевод выбранного пресета
	AddClassPostConstruct("widgets/redux/worldsettings/worldsettingsmenu", function(self)
		local Levels = require "map/levels"

		local oldGetNameForID = Levels.GetNameForID
		Levels.GetNameForID = function(levelcategory, preset)
			local ret = oldGetNameForID(levelcategory, preset)
			if ret and STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[preset] then
				ret = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[preset]
			end
			return ret
		end

		local oldGetDescForID = Levels.GetDescForID
		Levels.GetDescForID = function(levelcategory, preset)
			local ret = oldGetDescForID(levelcategory, preset)
			if ret and STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[preset] then
				ret = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC[preset]
			end
			return ret
		end
	end)

	-- перевод playstyle HoverText
	AddClassPostConstruct("widgets/redux/worldsettings/presetbox", function(self)
		local Levels = require "map/levels"
		local oldSetPlaystyleIcon = self.SetPlaystyleIcon

		function self:SetPlaystyleIcon(playstyle_id)
			oldSetPlaystyleIcon(self, playstyle_id)
			local playstyle_def = playstyle_id ~= nil and Levels.GetPlaystyleDef(playstyle_id) or nil

			if playstyle_def ~= nil then
				self.playstyle.icon:SetHoverText(STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS[playstyle_def.default_preset])
			end
		end

		-- і чтоб влезало
		self.presetdesc:SetSize(18)
		self.presetdesc:SetRegionSize(230, 160)
	end)

	--согласовываем слово "дней" с колічеством дней
	AddClassPostConstruct("widgets/worldresettimer", function(self)
		if self.countdown_message then self.countdown_message:SetSize(27) end
		SetHookFunction(self.countdown_message, "SetString", function(self, str)
			local val=tonumber((str or ""):match(" ([^ ]*)$"))
			return str..(val and " "..StringTime(val,{"секунду","секунды","секунд"}) or "")
		end, false, true, self.countdown_message and self.countdown_message:GetString())

		if self.survived_message then self.survived_message:SetSize(27) end
		self.oldStartTimer=self.StartTimer
		function self:StartTimer()
			self:oldStartTimer()
			if self.survived_message then
				local age = self.owner.Network:GetPlayerAge()
				local newmsg=self.survived_message:GetString()
				self.survived_message:SetString(newmsg:gsub("дней",StringTime(age),1))
			end
		end
		-- SetHookFunction(self.survived_message, "SetString", function(self, str)
		-- 	local val=tonumber((str or ""):match(" ([^ ]*)$"))
		-- 	return str..(val and " "..StringTime(val) or "")
		-- end, false, true, self.survived_message and self.survived_message:GetString())
	end)

end

--Дядька, продающій скіны должен склонять слова под названія вещей
AddClassPostConstruct("widgets/skincollector", function(self)
	if not self.Say then return end
	if self.text then
		self.text:SetSize(self.text.size-5)
	end
	local OldSay = self.Say
	function self:Say(text, rarity, name, number, ...)
		if type(text) == "table" then
			text = GetRandomItem(text)
		end
		if text then
			local gender = "he"
			if name then --еслі есть названіе предмета, іщем его пол
				local key = table.reverselookup(STRINGS.SKIN_NAMES, name)
				if key then
					for gen, tbl in pairs(t.NamesGender) do
						if tbl[key:lower()] then gender = gen break end
					end
					name = belarusianlower(name)
				end
--				text = string.gsub(text, "<item>", name)
			end
			if rarity then
				rarity = belarusianlower(rarity)
				text = string.gsub(text, "<rarity>", rarity) --заменім, чтобы парсілісь склоненія (ніже)
			end
			--парсім тегі
			if name or rarity then
				text = t.ParseTranslationTags(text, nil, nil, gender)
			end
		end
		return OldSay(self, text, rarity, name, number, ...)
	end
end)

-- пріменяем шріфт прі выборе скіна в меню крафта предмета
AddClassPostConstruct("widgets/redux/craftingmenu_skinselector", function(self)
	self.spinner.text:SetFont(UIFONT)
end)

--Увелічіваем область заголовка, чтобы не съедало буквы
local function postintentionpicker(self)
	if self.headertext then
		local w,h = self.headertext:GetRegionSize()
		self.headertext:SetRegionSize(w,h+10)
	end
	--Не переводітся. Значіт переводім насільно
	local intention_options={{text='Сяброўскі'},{text='Камандны'},{text='Агрэсіўны'},{text='Шалёны'},}
	for i, v in ipairs(intention_options) do
		self.buttons[i]:SetText(intention_options[i].text)
	end
end
AddClassPostConstruct("widgets/intentionpicker", postintentionpicker)
AddClassPostConstruct("widgets/redux/intentionpicker", postintentionpicker)

AddClassPostConstruct("screens/redux/caveselectscreen", function(self)
    local STR_HEADER = "З пячорамі ці без пячор?"

    local srv_desc = {
        caves = {
            title = "З пячорамі",
            desc  = "Сусвет з пячорамі вымагае большых магутнасцяў ПК, бо запускаецца на некалькіх серверах",
            -- якія англійскія назвы могуць прылятаць у кнопку
            en_titles = { "Caves", "With Caves" },
        },
        nocaves = {
            title = "Без пячор",
            desc  = "Не так весела, але і не настолькі патрабавальна для камп’ютара",
            en_titles = { "No Caves" },
        },
    }

    local function GetKeyFromWidget(w)
        local s = w and w.settings_desc
        if type(s) ~= "string" then return nil end
        if s:find("Play with Caves") then
            return "caves"
        elseif s:find("Play with no Caves") then
            return "nocaves"
        end
        return nil
    end

    local function LockButtonTextToBelarusian(btntext, key)
        if not (btntext and btntext.SetString) then return end
        if btntext._by_locked then return end
        btntext._by_locked = true

        local old = btntext.SetString
        btntext.SetString = function(textself, str, ...)
            -- калі базавы код спрабуе вярнуць англійскі тэкст — перахопліваем
            local data = srv_desc[key]
            if type(str) == "string" then
                for _, en in ipairs(data.en_titles or {}) do
                    if str == en then
                        str = data.title
                        break
                    end
                end
            end
            return old(textself, str, ...)
        end
    end

    local function ApplyTranslation(w)
        local key = GetKeyFromWidget(w)
        if not key then return false end

        local data = srv_desc[key]

        if self.description and data.desc then
            self.description:SetMultilineTruncatedString(data.desc, 3, 700, nil, true, true)
        end

        if w and w.button and w.button.text then
            -- паставіць беларускі тэкст цяпер
            w.button.text:SetString(data.title)
            -- і “замацаваць”, каб больш не вярталася ў англійскую
            LockButtonTextToBelarusian(w.button.text, key)
        end

        return true
    end

    -- РЭКУРСІЎНЫ абыход дрэва віджэтаў: шукае любыя элементы з settings_desc
    local function TraverseAndTranslate(widget)
        if not widget then return 0 end
        local hits = 0

        -- 1) сам віджэт
        if ApplyTranslation(widget) then
            hits = hits + 1
        end

        -- 2) дзеці
        local children = rawget(widget, "children")
        if type(children) == "table" then
            for _, ch in pairs(children) do
                hits = hits + TraverseAndTranslate(ch)
            end
        end

        return hits
    end

    local function KickTranslateForAWhile()
        if not (self.inst and self.inst.DoPeriodicTask) then
            TraverseAndTranslate(self)
            return
        end

        local tries = 0
        local task
        task = self.inst:DoPeriodicTask(FRAMES, function()
            tries = tries + 1
            local hits = TraverseAndTranslate(self)

            -- калі ўжо знайшлі абедзве кнопкі і замацавалі — можна спыніцца
            -- (hits>=2 часта бывае дастаткова, але пакідаем яшчэ запас)
            if hits >= 2 or tries >= 60 then
                if task then task:Cancel() end
            end
        end)
    end

    -- Абавязкова: не ламаем базавы UpdateStyleInfo, а дапаўняем яго
    local oldUpdateStyleInfo = self.UpdateStyleInfo
    function self:UpdateStyleInfo(w, ...)
        if oldUpdateStyleInfo then
            oldUpdateStyleInfo(self, w, ...)
        end
        ApplyTranslation(w)
    end

    local oldOnBecomeActive = self.OnBecomeActive
    function self:OnBecomeActive(...)
        if oldOnBecomeActive then
            oldOnBecomeActive(self, ...)
        end

        if self.headertext then
            self.headertext:SetString(STR_HEADER)
        end

        -- Самы важны момант: перакладаем некалькі кадраў запар,
        -- бо кнопкі могуць з’явіцца/перамалявацца пазней.
        KickTranslateForAWhile()
    end
end)


AddClassPostConstruct("widgets/recipepopup", function(self) --Уменьшаем шріфт опісанія рецепта в попапе рецептов
	if self.name and self.Refresh and not self.horizontal then --Перехватываем вывод названія, проверяем, вмещается лі оно, і еслі нужно, меняем его размер

		if not self.OldRefresh then
			self.OldRefresh=self.Refresh
			function self.Refresh(self,...)
				self:OldRefresh(...)
				if not self.name then return end
				if self.button and self.button.image then
					self.button.image:SetScale(.60, .7)
				end
				if self.bg and self.bg.light_box then
					self.bg.light_box:SetPosition(30, -42)
				end

				if (self.skins_options and #self.skins_options == 1) or not self.skins_options then
					self.contents:SetPosition(-75,-20,0)
					self.name:SetPosition(320, 157, 0)
					self.button:SetPosition(320, -95, 0)
					self.teaser:SetPosition(320, -90, 0)
				else
					self.name:SetPosition(320, 182, 0)
				end
				if not self.name.OldSetTruncatedString then
					self.name.OldSetTruncatedString = self.name.SetTruncatedString
					if self.name.OldSetTruncatedString then
						local function NewSetTruncatedString(self1,str, maxwidth, maxcharsperline, ellipses)
							maxcharsperline = 17
							maxwidth = maxwidth + 30
							local maxlines = 2
							self.name.SetTruncatedString=self.name.OldSetTruncatedString
							self.name:SetMultilineTruncatedString(str, maxlines, maxwidth, maxcharsperline, ellipses)
							self.name.SetTruncatedString=NewSetTruncatedString
						end
						self.name.SetTruncatedString=NewSetTruncatedString
					end
				end
				if self.desc then
					self.desc:SetSize(28)
					self.desc:SetRegionSize(64*3+30,130)
					if not self.desc.OldSetMultilineTruncatedString then
						self.desc.OldSetMultilineTruncatedString = self.desc.SetMultilineTruncatedString
						if self.desc.OldSetMultilineTruncatedString then
							self.desc.SetMultilineTruncatedString=function(self1,str, maxlines, maxwidth, maxcharsperline, ellipses)
								maxcharsperline = 24
								maxlines = 3
								self.desc.OldSetMultilineTruncatedString(self1,str, maxlines, maxwidth, maxcharsperline, ellipses)
							end
						end
					end
				end

			end
		end
	end
end)

AddClassPostConstruct("widgets/quagmire_recipepopup", function(self) --Для горга то же самое
	local _Refresh = self.Refresh or function(...) end

	function self:Refresh(...)
		_Refresh(self, ...)

		if self.desc then
			self.desc:SetSize(28)
			--Перезапісмываем строку
			self.desc:SetString("")
			self.desc:SetMultilineTruncatedString(STRINGS.RECIPE_DESC[string.upper(self.recipe.product) or "ERROR!"], 2, 320, nil, true)
		end
	end
end)

do
	local translations = {
		["Cancel"] = "Скасаваць",
		["Random"] = "Выпадкова",
		["Write it!"] = "Напісаць!",
	}

	AddClassPostConstruct("widgets/writeablewidget", function(self)
		if self.menu and self.menu.items then
			for i,v in pairs(self.menu.items) do
				if v.text and translations[v.text:GetString()] then
					v.text:SetString(translations[v.text:GetString()])
				end
			end
		end
	end)
end

--сочетаем слово "День" с колічеством дней
AddClassPostConstruct("widgets/truescrolllist", function(self)
	local months = {Jan="Студ.",Feb="Люты",Mar="Сак.",Apr="Крас.",May="Трав.",Jun="Чэрв.",Jul="Ліп.",Aug="Жнів.",Sept="Вер.",Oct="Каст.",Nov="Ліст.",Dec="Снеж."}
	local list={["day.tex"]=1,
				["season.tex"]=1,
				["season_start.tex"]=1,
				["world_size.tex"]=1,
				["world_branching.tex"]=1,
				["world_loop.tex"]=1,
				["world_map.tex"]=1,
				["world_start.tex"]=1,
				["starting_variety.tex"]=1,
				["winter.tex"]=1,
				["summer.tex"]=1,
				["autumn.tex"]=1,
				["spring.tex"]=1}

	local oldupdate_fn=self.update_fn
	self.update_fn=function(context, widget, data, index)
		oldupdate_fn(context, widget, data, index)
		if widget.opt_spinner and widget.opt_spinner.spinner.options then
			if data and data.option and data.option.image then
				if list[data.option.image] then
					widget.opt_spinner.image:SetTexture("images/blr_mapgen.xml", "rus_"..data.option.image)
					widget.opt_spinner.image:SetSize(50,50)
				end
			end
		end
		--[[if data and data.item_type and widget.text then
			local x, y = widget.text:GetRegionSize()
			widget.text:SetRegionSize(x+30, y+20)   -- По неізвестной прічіне затрагівает і вкладку "Магазін", тем самым смещая опісаніе "Сундуков" левее @Нікіта
		end]]
		if data and data.days_survived and widget.DAYS_LIVED then
			local Text = require "widgets/text"
			widget.DAYS_LIVED:SetTruncatedString((data.days_survived or STRINGS.UI.MORGUESCREEN.UNKNOWN_DAYS).." "..StringTime(data.days_survived), widget.DAYS_LIVED._align.maxwidth, widget.DAYS_LIVED._align.maxchars, true)
		end
		if data and data.playerage and widget.PLAYER_AGE then
			local Text = require "widgets/text"
			local age_str = (data.playerage or STRINGS.UI.MORGUESCREEN.UNKNOWN_DAYS).." "..StringTime(tonumber(data.playerage))
			widget.PLAYER_AGE:SetTruncatedString(age_str, widget.PLAYER_AGE._align.maxwidth, widget.PLAYER_AGE._align.maxchars, true)
			if widget.SEEN_DATE and not widget.SEEN_DATE.BLRFixed then
				local OldSetString = widget.SEEN_DATE.SetString
				if OldSetString then
					function widget.SEEN_DATE:SetString(s, ...)
						s = s:gsub("(.-) (%d-), (%d-)",function(m, d, y)
							if not months[m] then return end
							return d.." "..months[m].." "..y
						end) or s
						local res = OldSetString(self, s, ...)
						return res
					end
					widget.SEEN_DATE.BLRFixed = true
					widget.SEEN_DATE:SetString(widget.SEEN_DATE:GetString())
				end
			end
		end
	end
end)


--Слеталі шріфты у кнопок выбора в первом слоте
local function serversettingstabpost(self)
	for i,wgt in ipairs(self.privacy_type.buttons.buttonwidgets) do
		wgt.button:SetFont(NEWFONT)
	end
end
AddClassPostConstruct("widgets/serversettingstab", serversettingstabpost)

do
	-- ісправленія інтерфейса
	local TEMPLATES = require "widgets/redux/templates"
	local oldLabelSpinner = TEMPLATES.LabelSpinner	
	function TEMPLATES.LabelSpinner(labeltext, spinnerdata, width_label, width_spinner, height, spacing, font, font_size, horiz_offset, ...)
		local ActiveScreen = "none"
		if TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name then ActiveScreen = TheFrontEnd:GetActiveScreen().name end
		-- if ActiveScreen == "MultiplayerMainScreen" then
		local width_label = width_label and width_label+14 or 220
		local font_size = font_size or 22
		local horiz_offset = horiz_offset and horiz_offset+10 or 0
		local width_spinner = width_spinner and width_spinner-10 or 150

		-- 	return oldLabelSpinner(labeltext, spinnerdata, width_label, width_spinner, height, spacing, font, font_size, horiz_offset, ...)
		-- else
		return oldLabelSpinner(labeltext, spinnerdata, width_label, width_spinner, height, spacing, font, font_size, horiz_offset, ...)
		-- end
	end

	local oldLabelNumericSpinner = TEMPLATES.LabelNumericSpinner	
	function TEMPLATES.LabelNumericSpinner(labeltext, min, max, width_label, width_spinner, height, spacing, font, font_size, horiz_offset, ...)
		local ActiveScreen = "none"
		if TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name then ActiveScreen = TheFrontEnd:GetActiveScreen().name end
		-- if ActiveScreen == "MultiplayerMainScreen" then
		local width_label = width_label+14 or 220
		local font_size = font_size or 22
		local horiz_offset = horiz_offset and horiz_offset+10 or 0
		local width_spinner = width_spinner and width_spinner-10 or 150

		-- 	return oldLabelNumericSpinner(labeltext, min, max, width_label, width_spinner, height, spacing, font, font_size, horiz_offset, ...)
		-- else
		return oldLabelNumericSpinner(labeltext, min, max, width_label, width_spinner, height, spacing, font, font_size, horiz_offset, ...)
		-- end
	end

	local oldOptionsLabelCheckbox = TEMPLATES.OptionsLabelCheckbox	
	function TEMPLATES.OptionsLabelCheckbox(onclick, labeltext, checked, width_label, width_button, height, checkbox_size, spacing, font, font_size, horiz_offset, ...)
		local ActiveScreen = "none"
		if TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name then ActiveScreen = TheFrontEnd:GetActiveScreen().name end
		-- if ActiveScreen == "MultiplayerMainScreen" then
		local font_size = font_size or 22
		local horiz_offset = horiz_offset and horiz_offset+10 or 0

		-- 	return oldOptionsLabelCheckbox(onclick, labeltext, checked, width_label, width_button, height, checkbox_size, spacing, font, font_size, horiz_offset, ...)
		-- else
		return oldOptionsLabelCheckbox(onclick, labeltext, checked, width_label, width_button, height, checkbox_size, spacing, font, font_size, horiz_offset, ...)
		-- end
	end


	local oldCurlyWindow = TEMPLATES.CurlyWindow	
	function TEMPLATES.CurlyWindow(sizeX, sizeY, title_text, bottom_buttons, button_spacing, body_text)
		local w = oldCurlyWindow(sizeX, sizeY, title_text, bottom_buttons, button_spacing, body_text)

		if title_text then
			w.title:SetRegionSize(680, 50)
            w.title:SetSize(35)
        end  

	    if body_text then
	    	w.body:SetSize(24)
	    end

		return w
	end
end

AddClassPostConstruct("screens/redux/optionsscreen", function(self)
	local function UpdateSpinners(items)
		self.screenFlashSpinner.options = { { text = STRINGS.UI.OPTIONS.DEFAULT, data = 1 }, { text = STRINGS.UI.OPTIONS.DIM, data = 2 } , { text = STRINGS.UI.OPTIONS.DIMMEST, data = 3 } }
		self.screenFlashSpinner:SetSelectedIndex(self.screenFlashSpinner.selectedIndex)
		for _, item in pairs(items) do
			if item.options then -- Проверяем чайлда спінер он ілі нет
				local opts = item.options
				if #opts == 2 and opts[1].data == false then
					--Настройкі рюкзака тоже булеан. Проверяем
					local txt = item ~= self.integratedbackpackSpinner and
					{
						STRINGS.UI.OPTIONS.DISABLED,
						STRINGS.UI.OPTIONS.ENABLED,
					}
					or
					{
						STRINGS.UI.OPTIONS.INTEGRATEDBACKPACK_DISABLED,
						STRINGS.UI.OPTIONS.INTEGRATEDBACKPACK_ENABLED,
					}

					opts[1].text = txt[1]
					opts[2].text = txt[2]

					--Обновляем і текст
					item:SetSelectedIndex(item.selectedIndex)
				end
			end
		end
	end

	if self.right_spinners then
		UpdateSpinners(self.right_spinners)
	end
	if self.left_spinners then
		UpdateSpinners(self.left_spinners)
	end

	if self.title then
		self.title.big:SetString("Параметры гульні")
	end
end) 

AddClassPostConstruct("screens/redux/scrapbookscreen", function(self)
	local Text = require "widgets/text"
	function Text:SetString(str)
		if str ~= nil then
			if t.PO["STRINGS.SCRAPBOOK.DATA_USES"] and string.match(str,"^(%d*)"..t.PO["STRINGS.SCRAPBOOK.DATA_USES"].."$") then 
				local splitstr = split(str, " ")
				str = splitstr[1] .. StringTime(splitstr[1],{"УЖЫЦЦЕ"," УЖЫЦЦЯ"," УЖЫЦЦЯЎ"}) or str
			elseif t.PO["STRINGS.SCRAPBOOK.DATA_DAYS"] and string.match(str,"^(%d*)%s"..t.PO["STRINGS.SCRAPBOOK.DATA_DAYS"].."$") then
				local splitstr = split(str, " ")
				str = splitstr[1] .. StringTime(splitstr[1],{" ДЗЕНЬ"," ДНІ"," ДЗЁН"}) or str
			elseif t.PO["STRINGS.SCRAPBOOK.DATA_STACK"] and string.match(str,"^(%d*)%s"..t.PO["STRINGS.SCRAPBOOK.DATA_STACK"].."$") then
				local splitstr = split(str, " ")
				str = splitstr[1] .. StringTime(splitstr[1],{" ШТУКА"," ШТУКІ"," ШТУК"}) or str
			end

		    self.string = str
		    self.inst.TextWidget:SetString(str or "")
		end
	end
end)

env.AddClassPostConstruct("widgets/itemselector", function(self)
	self.banner:SetTexture("images/blr_tradescreen.xml", "banner0_small.tex")
	self.title:Hide()
end)

do
	local function PatchTradeOverflowImg(file, override)
		env.AddClassPostConstruct(file, function(self)
			local name = override or "title"
			self[name]:SetTexture("images/blr_tradescreen_overflow.xml", "TradeInnSign.tex")
		end)
	end

	PatchTradeOverflowImg("screens/tradescreen")
	PatchTradeOverflowImg("screens/crowgamescreen")
	PatchTradeOverflowImg("screens/snowbirdgamescreen")
	PatchTradeOverflowImg("screens/redbirdgamescreen")
	PatchTradeOverflowImg("screens/crowkidgamescreen")
end

-- env.modimport("scripts/mod_translator.lua")

--Подменяем імена персонажей, создаваемых с консолі в ігре.
local OldSetPrefabName = EntityScript.SetPrefabName
function EntityScript:SetPrefabName(name, ...)
	OldSetPrefabName(self,name, ...)
	if not self.entity:HasTag("player") then return end
	self.name=t.SpeechHashTbl.NAMES.Be2Eng[self.name] or self.name
end

--Новая версія функціі, выдающей качество предмета
local _GetAdjective = EntityScript.GetAdjective
function EntityScript:GetAdjective()
    local str = _GetAdjective(self)
    if str and self.prefab and ThePlayer then
        local player = ThePlayer
        local act = player.components.playercontroller:GetLeftMouseAction() --Получаем текущее действіе
        if act then act = act.action.id or "NOACTION" else act = "NOACTION" end
        str = FixPrefix(str,act,self.prefab) --склоняем окончаніе префікса
        if act ~= "NOACTION" then --еслі есть действіе, то нужно сделать с маленькой буквы
            str = firsttolower(str)
        end
    end
    return str
end

--Фікс для hoverer, передающій в GetDisplayName действіе, еслі оно есть
AddClassPostConstruct("widgets/hoverer", function(self)
    if not self.OnUpdate then return end
    local OldOnUpdate=self.OnUpdate
    function self:OnUpdate(...)
        local changed = false
        local OldlmbtargetGetDisplayName
        local lmb = self.owner and self.owner.components and self.owner.components.playercontroller and self.owner.components.playercontroller:GetLeftMouseAction()
        if lmb and lmb.target and lmb.target.GetDisplayName then
            changed = true
            OldlmbtargetGetDisplayName = lmb.target.GetDisplayName
            lmb.target.GetDisplayName = function(self)
                return OldlmbtargetGetDisplayName(self, lmb)
            end
        end
        OldOnUpdate(self, ...)
        if changed then
            lmb.target.GetDisplayName = OldlmbtargetGetDisplayName
        end
    end
end)

local _GetDisplayName = EntityScript.GetDisplayName --сохраняем старую функцію, выводящую названіе предмета
function EntityScript:GetDisplayName(act, ...) --Подмена функціі, выводящей названіе предмета. В ней реалізовано склоненіе в завісімості от действія (переменная аct)
    -- Fox: В старой верссіі act не передавался. Баг?
    local name = _GetDisplayName(self, act, ...)  -- Виправлено: _GetDisplayName (було *)
    local player = ThePlayer
    -- if not player then return name end --Еслі не удалось получіть instance ігрока, то возвращаем імя на англ. і выходім
    -- local act=player.components.playercontroller:GetLeftMouseAction() --Получаем текущее действіе
    if self:HasTag("player") then
        if STRINGS.NAMES[self.prefab:upper()] then
            --Пытаемся перевесті імя на русскій, еслі это кукла, а не ігрок
            if not(self.userid and (type(self.userid)=="string") and #self.userid>0)
            and name==t.SpeechHashTbl.NAMES.Be2Eng[STRINGS.NAMES[self.prefab:upper()] ] then
                name=STRINGS.NAMES[t.SpeechHashTbl.NAMES.Eng2Key[name] ]
                act=act and act.action.id or "DEFAULT"
                name=(t.BelarusianNames[name] and (t.BelarusianNames[name][act] or t.BelarusianNames[name]["DEFAULTACTION"] or t.BelarusianNames[name]["DEFAULT"])) or rebuildname(name,act,self.prefab) or name
            end
        end
        return name
    end
    local itisblueprint=false
    if name:sub(-10)==" Blueprint" then --Особое ісключітельное напісаніе для чертежей
        name=name:sub(1,-11)
        name=t.SpeechHashTbl.NAMES.Eng2Key[name] and STRINGS.NAMES[t.SpeechHashTbl.NAMES.Eng2Key[name]] or name
        itisblueprint=true
    end
    --Проверім, есть лі префікс мокрості, засушенності ілі дымленія
    local Prefix=nil
    if STRINGS.WET_PREFIX then
        for i,v in pairs(STRINGS.WET_PREFIX) do
            if type(v)=="string" and v~="" and string.sub(name,1,#v)==v then Prefix=v break end
        end
        if string.sub(name,1,#STRINGS.WITHEREDITEM)==STRINGS.WITHEREDITEM then Prefix=STRINGS.WITHEREDITEM
        elseif string.sub(name,1,#STRINGS.SMOLDERINGITEM)==STRINGS.SMOLDERINGITEM then Prefix=STRINGS.SMOLDERINGITEM
        end
        --Солім блюда правільно
        local puresalt = STRINGS.NAMES.QUAGMIRE_SALTED_FOOD_FMT:utf8sub(1,7)
        if string.sub(name,1,#puresalt)==puresalt then Prefix=puresalt end
        if Prefix then --Нашлі префікс. Меняем его і удаляем із імені для его дальнейшей корректной обработкі
            name=string.sub(name,#Prefix+2)--Убіраем префікс із імені
            if act then
                Prefix=FixPrefix(Prefix,act.action and act.action.id or "NOACTION",self.prefab)
                --Еслі есть действіе, значіт нужно сделать с маленькой буквы
                Prefix=firsttolower(Prefix)
            else
                Prefix=FixPrefix(Prefix,"NOACTION",self.prefab)
                if self:GetAdjective() then
                    Prefix=firsttolower(Prefix)
                end
            end
        end
    end
    -- перевод растеній на грядке
    local isSeed = false
    if self:HasTag("farm_plant") and self.components and self.components.growable then
        -- определяем степень роста
        local stage_data = self.components.growable:GetCurrentStageData()
        if stage_data.inspect_str and stage_data.inspect_str then
            local seed_name = ""
            local farm_plant_seed_bel = ""
            local knowsseed = false
            local knowsplantname = false
            local knowsweedname = false
            local player_is_farmplantidentifier = (ThePlayer ~= nil and ThePlayer:HasTag("farmplantidentifier"))
            local plant_stage = stage_data.inspect_str -- узнаём состояніе роста
            -- проверяем іследованность сорняка
            if self.weed_def and self.weed_def.plantregistryinfo then
                local plantregistryinfo = self.weed_def.plantregistryinfo
                local registry_key = self:GetPlantRegistryKey()
                knowsweedname = ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)
                --print("knowsweedname="..tostring(knowsweedname))
            end
            if self.plant_def then
                -- проверяем іследованность растенія
                if self.plant_def.plantregistryinfo then
                    local plantregistryinfo = self.plant_def.plantregistryinfo
                    local registry_key = self:GetPlantRegistryKey()
                    knowsseed = ThePlantRegistry:KnowsSeed(registry_key, plantregistryinfo)
                    knowsplantname = ThePlantRegistry:KnowsPlantName(registry_key, plantregistryinfo)
                    --print("knowsseed="..tostring(knowsseed).." knowsplantname="..tostring(knowsplantname).." player_is_farmplantidentifier="..tostring(player_is_farmplantidentifier))
                end
                -- форміруем імя семені
                if plant_stage == "SEED" and self.plant_def.seed then
                    isSeed = true
                    seed_name = string.upper(self.plant_def.seed) -- определяем семя
                    if (player_is_farmplantidentifier or (knowsseed and knowsplantname)) and not self.plant_def.is_randomseed then -- еслі ісследовано
                        seed_name = "KNOWN_"..seed_name  -- Виправлено: _ замість *
                    end
                    if STRINGS.NAMES[seed_name] ~= nil then
                        seed_name=STRINGS.NAMES[seed_name] -- определяем названіе на русском
                    end
                    if act then --еслі есть действіе
                        -- выбіраем варіант склоненія по действію для імені семені
                        if t.BelarusianNames[seed_name] ~= nil and (t.BelarusianNames[seed_name][act.action and act.action.id] or t.BelarusianNames[seed_name]["DEFAULTACTION"]) ~= nil then
                            seed_name = t.BelarusianNames[seed_name][act.action and act.action.id] or t.BelarusianNames[seed_name]["DEFAULTACTION"]
                            seed_name = firsttolower(seed_name)
                        end
                        -- выбіраем варіант склоненія по действію для farm_plant_seed (слово "посаженные")
                        if t.BelarusianNames["Пасаджаныя {seed}"] ~= nil and (t.BelarusianNames["Пасаджаныя {seed}"][act.action and act.action.id] or t.BelarusianNames["Пасаджаныя {seed}"]["DEFAULTACTION"]) ~= nil then
                            farm_plant_seed_bel = t.BelarusianNames["Пасаджаныя {seed}"][act.action and act.action.id] or t.BelarusianNames["Пасаджаныя {seed}"]["DEFAULTACTION"]
                        end
                    end
                    name = (farm_plant_seed_bel or "Посаженные").." "..seed_name
                end
            end
            -- склоняем префікс прі намоканіі
            if Prefix and act then
                -- ще растущіе сорнякі і растенія
                if (self.prefab:utf8sub(1,4) == "weed" and plant_stage ~= "FULL_WEED" and not (player_is_farmplantidentifier or knowsweedname)) or (self.prefab:utf8sub(1,4) == "farm" and plant_stage == "GROWING" and not (player_is_farmplantidentifier or knowsplantname)) then
                    Prefix = FixPrefix(Prefix,act.action and act.action.id or "NOACTION","farm_plant_unknown")
                -- только посаженные семена
                elseif (self.prefab:utf8sub(1,4) == "farm" and plant_stage == "SEED") then
                    Prefix = FixPrefix(Prefix,act.action and act.action.id or "NOACTION","farm_plant_seed")
                -- гніль
                elseif (self.prefab:utf8sub(1,4) == "farm" and plant_stage == "ROTTEN") then
                    Prefix = FixPrefix(Prefix,act.action and act.action.id or "NOACTION","spoiled_food")
                else
                    Prefix = FixPrefix(Prefix,act.action and act.action.id or "NOACTION",self.prefab)
                end
            end
        end
    end
    if name and self.prefab then
        if self.prefab=="pigman" then
            name=t.SpeechHashTbl.PIGNAMES.Eng2Be[name] or name
        elseif self.prefab=="pigguard" then
            name=t.SpeechHashTbl.PIGNAMES.Eng2Be[name] or name
        elseif self.prefab=="bunnyman" then
            name=t.SpeechHashTbl.BUNNYMANNAMES.Eng2Be[name] or name
        elseif self.prefab=="quagmire_swampig" then
            name=t.SpeechHashTbl.SWAMPIGNAMES.Eng2Be[name] or name
        elseif self.prefab=="merm" then
            name=t.SpeechHashTbl.MERMNAMES.Eng2Be[name] or name
        elseif self.prefab=="mermguard" then
            name=t.SpeechHashTbl.MERMNAMES.Eng2Be[name] or name
        elseif self.prefab=="merm_lunar" then
            name=t.SpeechHashTbl.MERMNAMES.Eng2Be[name] or name	
        elseif self.prefab=="mermguard_lunar" then
            name=t.SpeechHashTbl.MERMNAMES.Eng2Be[name] or name		
		elseif self.prefab=="sharkboi" then
            name=t.SpeechHashTbl.SHARKBOINAMES.Eng2Be[name] or name
        end
    end
    if act then --Еслі есть действіе
        act=act.action.id
        if not itisblueprint then
            if t.BelarusianNames[name] then
                name=t.BelarusianNames[name][act] or t.BelarusianNames[name]["DEFAULTACTION"] or t.BelarusianNames[name]["DEFAULT"] or rebuildname(name,act,self.prefab) or "NAME"
            else
                if not isSeed then
                    name=rebuildname(name,act,self.prefab)
                end
            end
            if (not self.prefab or self.prefab~="pigman" and self.prefab~="pigguard" and self.prefab~="bunnyman" and self.prefab~="mermguard" and self.prefab~="merm_lunar" and self.prefab~="mermguard_lunar" and self.prefab~="sharkboi" and self.prefab~="merm" and self.prefab~="quagmire_trader_merm" and self.prefab~="quagmire_trader_merm2" and self.prefab~="quagmire_swampigelder" and self.prefab~="quagmire_goatmum" and self.prefab~="quagmire_goatkid" and self.prefab~="quagmire_swampig")
            and not t.ShouldBeCapped[self.prefab] and name and type(name)=="string" and #name>0 then
                --меняем первый сімвол названія предмета в ніжній регістр
                name=firsttolower(name)
            end
        else name="рысунак прадмета \""..name.."\"" end -- Виправлено: лапки
    else --Еслі нет действія
        if itisblueprint then name="Рысунак прадмета \""..name.."\"" end -- Виправлено: лапки
        if not t.ShouldBeCapped[self.prefab] and (self:GetAdjective() or Prefix) then
            name=firsttolower(name)
        end
    end
    if Prefix then
        name=Prefix.." "..name
    end
    if act and name then
        if act=="SLEEPIN" or act=="JUMPIN" then
            name=Prefix and "ва "..name or "у "..name
        end
        if act=="OPEN_CRAFTING" and self.prefab and (self.prefab == "madscience_lab" or self.prefab == "wintersfeastoven") then
            name=Prefix and "ва "..name or "у "..name
        end
    end
    if act and act=="INTERACT_WITH" and name then name="з "..name end --Чтобы не было фразы "Поговоріть с" с надетой шляпой садовніка
    return name
end

AddClassPostConstruct("components/playercontroller", function(self)
	--Переопределяем функцію, выводящую "Создать ...", когда устанавлівается на землю крафт-предмет тіпа палаткі.
	--В старой функціі у Klei ошібка. Нужно заменіть self.player_recipe на self.placer_recipe
	local OldGetHoverTextOverride = self.GetHoverTextOverride
	if OldGetHoverTextOverride then
		function self:GetHoverTextOverride(...)
			if self.placer_recipe then
				local name = STRINGS.NAMES[string.upper(self.placer_recipe.name)]
				local act = "BUILD"
				if name then
					if t.BelarusianNames[name] then
						name = t.BelarusianNames[name][act] or t.BelarusianNames[name]["DEFAULTACTION"] or t.BelarusianNames[name]["DEFAULT"] or rebuildname(name,act) or STRINGS.UI.HUD.HERE
					else
						name = rebuildname(name,act) or STRINGS.UI.HUD.HERE
					end
				else
					name = STRINGS.UI.HUD.HERE
				end
				if not t.ShouldBeCapped[self.placer_recipe.name] and name and type(name)=="string" and #name>0 then
					--меняем первый сімвол названія предмета в ніжній регістр
					name = firsttolower(name)
				end
				return STRINGS.UI.HUD.BUILD.. " " .. name
--				local res = OldGetHoverTextOverride(self, ...)
--				return res
			end
		end
	end
end)

if DEBUG_ENABLED then
	t.ModLoaded()
end
