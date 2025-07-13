local env = env
local t = mods.BielarusizatarDST

GLOBAL.setfenv(1, GLOBAL)

--Для тех, кто пользуется ps4 или NACL должна быть возможность сохранять не в ини файле, а в облаке.
--Для этого дорабатываем функционал стандартного класса PlayerProfile

do 
	local USE_SETTINGS_FILE = PLATFORM ~= "PS4" and PLATFORM ~= "NACL"

	local function tobool(str)
		if not str or str:lower() == "false" then
			return false
		end
		return true
	end
	
	local function SetLocalizaitonValue(self, name, value) --Метод, сохраняющий опцию с именем name и значением value
		-- print("SetLocalizaitonValue", name, value, CalledFrom())
		if USE_SETTINGS_FILE then
			TheSim:SetSetting("translation", name, tostring(value))
		else
			self:SetValue(tostring(name), value)
			self.dirty = true
			self:Save() --Сохраняем сразу, поскольку у нас нет кнопки "применить"
		end
	end
	
	local function GetLocalizaitonValue(self, name) --Метод, возвращающий значение опции name
		-- print("GetLocalizaitonValue", name, CalledFrom())
		local USE_SETTINGS_FILE = PLATFORM ~= "PS4" and PLATFORM ~= "NACL"
		if USE_SETTINGS_FILE then
			return TheSim:GetSetting("translation", name)
		end
		return self:GetValue(name)
	end
	
	local function GetTranslationType(self)
		local val = self:GetLocalizaitonValue("translation_type")
		if not val or not tonumber(val) then
			self:SetLocalizaitonValue("translation_type", t.TranslationTypes.Full)
			return t.TranslationTypes.Full
		end
		return val
	end
	
	local function GetModTranslationEnabled(self)
		local val = self:GetLocalizaitonValue("mod_translation_type")
		if not val or not tonumber(val) then -- Фикс старых настроек
			self:SetLocalizaitonValue("mod_translation_type", t.ModTranslationTypes.Enabled)
			return t.ModTranslationTypes.Enabled
		end
		return val
	end

	--Расширяем функционал PlayerProfile дополнительной инициализацией двух методов и заданием дефолтных значений опций нашего перевода.
	--После обновления ни один из этих способов не работает, поэтому делаем тупо через require.
	local self = require "playerprofile"
	
	self.SetLocalizaitonValue = SetLocalizaitonValue
	self.GetLocalizaitonValue = GetLocalizaitonValue
	
	self.GetTranslationType = GetTranslationType
	self.GetModTranslationEnabled = GetModTranslationEnabled

	if t.IsBeta then
		if self:GetLocalizaitonValue("beta_popup") == nil then
			self:SetLocalizaitonValue("beta_popup", tostring(true))
		end

		local function ShouldWarnBeta(self)
			return tobool(self:GetLocalizaitonValue("beta_popup"))
		end

		local function SetShouldWarnBeta(self, val)
			return self:SetLocalizaitonValue("beta_popup", tostring(val))
		end

		self.ShouldWarnBeta = ShouldWarnBeta
		self.SetShouldWarnBeta = SetShouldWarnBeta
	end
end

t.CurrentTranslationType = Profile:GetTranslationType()

