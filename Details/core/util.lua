-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local _detalhes = _G._detalhes
local Loc = LibStub("AceLocale-3.0"):GetLocale( "Details" )
local _
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> local pointers

local _upper = string.upper --lua local
local _ipairs = ipairs --lua local
local _pairs = pairs --lua local
local _math_floor = math.floor --lua local
local _math_min = math.min --lua local
local _math_random = math.random --lua local
local _type = type --lua local
local _string_format = string.format --lua local
local loadstring = loadstring --lua local
local _pcall = pcall
local _GetTime = GetTime

local _IsInRaid = IsInRaid --wow api local
local _IsInGroup = IsInGroup --wow api local
local _GetNumGroupMembers = GetNumGroupMembers --wow api local
local _UnitAffectingCombat = UnitAffectingCombat --wow api local
local _InCombatLockdown = InCombatLockdown --wow api local

local gump = _detalhes.gump --details local

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> details api functions

_detalhes.GetNpcIdFromGuid = DetailsFramework.GetNpcIdFromGuid

function _detalhes:GetSourceFromNpcId(npcId)
	for index, container in _ipairs(_detalhes.tabela_vigente) do
		if index <= 4 then
			local t = container._ActorTable
			for i = 1, #t do
				if _detalhes:GetNpcIdFromGuid(t[i].serial) == npcId then
					return t[i].nome
				end
			end
		end
	end
end

function _detalhes:UnpackDeathTable(t)
	local deathevents = t[1]
	local deathtime = t[2]
	local playername = t[3]
	local playerclass = t[4]
	local playermaxhealth = t[5]
	local deathtimestring = t[6]
	local lastcooldown = t.last_cooldown
	local deathcombattime = t.dead_at

	return playername, playerclass, deathtime, deathcombattime, deathtimestring, playermaxhealth, deathevents, lastcooldown
end

--> get the fractional number representing the alphabetical letter
function _detalhes:GetOrderNumber(who_name)
	return _math_random(1000, 9000) / 1000000
end

--/script print(tonumber(4/1000000)) - 4e-006
--0.000004
_detalhes.ToKFunctions = {}

function _detalhes:UseWestNumericalSystem()
	--> short numbers
	function _detalhes:ToK(numero)
		if numero > 999999999 then
			return format("%.2f", numero/1000000000).."B"
		elseif numero > 1000000 then
			return _string_format("%.2f", numero/1000000).."M"
		elseif numero > 999 then
			return _string_format("%.1f", numero/1000).."K"
		end
		return _string_format("%.0f", numero)
	end

	function _detalhes:ToK2(numero)
		if numero > 999999999 then
			return format("%.2f", numero/1000000000).."B"
		elseif numero > 999999 then
			return _string_format("%.2f", numero/1000000).."M"
		elseif numero > 99999 then
			return _math_floor(numero/1000).."K"
		elseif numero > 999 then
			return _string_format("%.1f", (numero/1000)).."K"
		end
		return _string_format("%.0f", numero)
	end

	--> short numbers no numbers after comma
	function _detalhes:ToK0(numero)
		if numero > 999999999 then
			return format("%.2f", numero/1000000000).."B"
		elseif numero > 1000000 then
			return _string_format("%.0f", numero/1000000).."M"
		elseif numero > 1000 then
			return _string_format("%.0f", numero/1000).."K"
		end
		return _string_format("%.0f", numero)
	end

	function _detalhes:ToKMin(numero)
		if numero > 1000000 then
			return _string_format("%.2f", numero/1000000).."m"
		elseif numero > 1000 then
			return _string_format("%.1f", numero/1000).."k"
		end
		return _string_format("%.0f", numero)
	end

	function _detalhes:ToK2Min(numero)
		if numero > 999999 then
			return _string_format("%.2f", numero/1000000).."m"
		elseif numero > 99999 then
			return _math_floor(numero/1000).."k"
		elseif numero > 999 then
			return _string_format("%.1f", (numero/1000)).."k"
		end
		return _string_format("%.0f", numero)
	end

	--> short numbers no numbers after comma
	function _detalhes:ToK0Min(numero)
		if numero > 1000000 then
			return _string_format("%.0f", numero/1000000).."m"
		elseif numero > 1000 then
			return _string_format("%.0f", numero/1000).."k"
		end
		return _string_format("%.0f", numero)
	end

	--> short numbers no numbers after comma
	function _detalhes:ToKReport(numero)
		if numero > 1000000 then
			return _string_format("%.2f", numero/1000000).."M"
		elseif numero > 1000 then
			return _string_format("%.1f", numero/1000).."K"
		end
		return numero
	end

	function _detalhes:Format(n, custom)
		n = _math_floor(n)
		if custom then
			if n > 999999 then
				return _string_format(custom, n/1000000).."M"
			elseif n > 999 then
				return _string_format(custom,(n/1000))
			else
				return n
			end
		else
			return _detalhes.ToKFunctions[_detalhes.ps_abbreviation](nil, n)
		end
	end

	--> no changes
	function _detalhes:NoToK(numero)
		return _math_floor(numero)
	end

	_detalhes.comma_value = DetailsFramework.CommaValue
	function _detalhes:comma_value_raw(n)
		local left,num,right = string.match(n, "^([^%d]*%d)(%d*)(.-)$")
		return left..(num:reverse():gsub("(%d%d%d)", "%1,"):reverse())..right
	end

	wipe(_detalhes.ToKFunctions)

	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.NoToK
	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.ToK
	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.ToK2
	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.ToK0
	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.ToKMin
	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.ToK2Min
	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.ToK0Min
	_detalhes.ToKFunctions[#_detalhes.ToKFunctions+1] = _detalhes.comma_value
	--
end

--> load western as default, the proper method is loaded within the profile
_detalhes:UseWestNumericalSystem()

function _detalhes:GetCurrentToKFunction()
	return _detalhes.ToKFunctions[_detalhes.ps_abbreviation]
end

------------------------------------------------------------------------------------------------------------
--> numerical system

function _detalhes:SetNumericalSystemOverride(language)
	if not language then
		language = "auto"
	end

	_detalhes.numerical_system_symbols = language
	_detalhes:Msg("NumSystem override is now:", language)

	_detalhes:SelectNumericalSystem()
end

function _detalhes:GetNumericalSystem()
	return _detalhes.numerical_system
end

function _detalhes:SelectNumericalSystem(system)
	if not system or type(system) ~= "number" then
		system = _detalhes.numerical_system or 1
	end

	_detalhes.numerical_system = system

	_detalhes:UseWestNumericalSystem()

	_detalhes:UpdateToKFunctions()
	_detalhes:AtualizaGumpPrincipal(-1, true)
end

function _detalhes:UpdateToKFunctions()
	_detalhes.atributo_damage:UpdateSelectedToKFunction()
	_detalhes.atributo_heal:UpdateSelectedToKFunction()
	_detalhes.atributo_energy:UpdateSelectedToKFunction()
	_detalhes.atributo_misc:UpdateSelectedToKFunction()
	_detalhes.atributo_custom:UpdateSelectedToKFunction()
end

--------end of ToK functions----

		--source https://github.com/WeakAuras/WeakAuras2/blob/520951a4b49b64cb49d88c1a8542d02bbcdbe412/WeakAuras/AuraEnvironment.lua#L66
		local blockedFunctions = {
			-- Lua functions that may allow breaking out of the environment
			setfenv = true,
			getfenv = true,
			loadstring = true,
			pcall = true,
			xpcall = true,
			getglobal = true,

			-- blocked WoW API
			SendMail = true,
			SetTradeMoney = true,
			AddTradeMoney = true,
			PickupTradeMoney = true,
			PickupPlayerMoney = true,
			TradeFrame = true,
			MailFrame = true,
			EnumerateFrames = true,
			RunScript = true,
			AcceptTrade = true,
			SetSendMailMoney = true,
			EditMacro = true,
			SlashCmdList = true,
			DevTools_DumpCommand = true,
			hash_SlashCmdList = true,
			CreateMacro = true,
			SetBindingMacro = true,
			GuildDisband = true,
			GuildUninvite = true,
			securecall = true,
			DeleteCursorItem = true,
			ChatEdit_SendText = true,
			CastSpellByName = true,
			CastSpell = true,
			CastSpellByID = true,

			--additional
			setmetatable = true,
		}
		local blockedTables = {
			SlashCmdList = true,
			SendMailMailButton = true,
			SendMailMoneyGold = true,
			MailFrameTab2 = true,
			ChatFrame1 = true,
			WeakAurasOptions = true,
			WeakAurasOptionsSaved = true
		}
		local scriptLocals = {_ipairs = ipairs, _pairs = pairs, _table_sort = table.sort, _cstr = string.format, _math_floor = math.floor}
		function _detalhes:CreateScriptEnvironment()
			return setmetatable({}, {__index = function(env, key)
				if key == "_G" then
					return env
				elseif blockedFunctions[key] then
					return nil
				elseif blockedTables[key] then
					return {}
				else
					return scriptLocals[key] or _G[key]
				end
			end})
		end
		local functionFilter = _detalhes:CreateScriptEnvironment()

--> replacing data for custom texts
_detalhes.string = {}

local function_cache = {}
local arguments_cache = {}
local parameters_cache = {}

local replace_arg = function(i)
	return arguments_cache[tonumber(i)]
end
local run_function = function(str)
	--> cache functions
	local func, errortext = function_cache[str]
	if not func then
		func, errortext = loadstring(str)
		if not func then
			_detalhes:Msg("|cFFFF9900error compiling script on custom text|r: ", errortext)
			function_cache[str] = function() return 0 end
			return 0
		end
		setfenv(func, functionFilter)
		function_cache[str] = func
	end

	local okey, value = _pcall(func, parameters_cache[1], parameters_cache[2], parameters_cache[3], parameters_cache[4])
	if not okey then
		_detalhes:Msg("|cFFFF9900error on custom text|r:", value)
		return 0
	end
	return value or 0
end

function _detalhes.string.replace(str, v1, v2, v3, v4, v5, v6, v7)
	arguments_cache[1] = v1
	arguments_cache[2] = v2
	arguments_cache[3] = v3
	parameters_cache[1] = v4
	parameters_cache[2] = v5
	parameters_cache[3] = v6
	parameters_cache[4] = v7

	return(str:gsub("{data(%d+)}", replace_arg):gsub("{func(.-)}", run_function))
end

--> return if the numeric table have an object
function _detalhes:tableIN(tabela, objeto)
	for index, valor in _ipairs(tabela) do
		if valor == objeto then
			return index
		end
	end
	return false
end

_detalhes.table = {}

_detalhes.table.reverse = DetailsFramework.table.reverse

function _detalhes.table.copy(t1, t2)
	local table_deepcopy = table_deepcopy
	for key, value in _pairs(t2) do
		if type(value) == "table" then
			t1[key] = table_deepcopy(value)
		else
			t1[key] = value
		end
	end
	return t1
end

_detalhes.table.deploy = DetailsFramework.table.deploy

function _detalhes.table.overwrite(t1, t2)
	for key, value in _pairs(t2) do
		if type(value) == "table" then
			t1[key] = t1[key] or {}
			_detalhes.table.overwrite(t1[key], t2[key])
		else
			t1[key] = value
		end
	end
end

function _detalhes.table.dump(t, s, deep)
	s = s or ""
	deep = deep or 0
	local space = ""
	for i = 1, deep do
		space = space.."   "
	end

	for key, value in _pairs(t) do
		local tpe = _type(value)

		if type(key) == "function" then
			key = "#function#"
		elseif type(key) == "table" then
			key = "#table#"
		end

		if type(key) ~= "string" and type(key) ~= "number" then
			key = "unknown?"
		end

		if tpe == "table" then
			if type(key) == "number" then
				s = s..space.."["..key.."] = |cFFa9ffa9table {|r\n"
			else
				s = s..space.."[\""..key.."\"] = |cFFa9ffa9table {|r\n"
			end

			s = s.._detalhes.table.dump(value, nil, deep+1)
			s = s..space.."|cFFa9ffa9}|r\n"
		elseif tpe == "string" then
			s = s..space.."[\""..key.."\"] = '|cFFfff1c1"..value.."|r'\n"
		elseif tpe == "number" then
			s = s..space.."[\""..key.."\"] = |cFFffc1f4"..value.."|r\n"
		elseif tpe == "function" then
			s = s..space.."|cFFa9a9ff[\"|r"..key.."|cFFa9a9ff\"]|r = |cFFa9a9fffunction()|r\n"
		elseif tpe == "boolean" then
			s = s..space.."[\""..key.."\"] = |cFF99d0ff"..(value and "true" or "false").."|r\n"
		end
	end

	return s
end

function _detalhes:hex(num)
	return _string_format("%02x", num)
end

function _detalhes:percent_color(value, inverted)
	local r, g
	if value < 50 then
		r = 255
	else
		r = _math_floor(255 -(value * 2 - 100) * 255 / 100)
	end

	if value > 50 then
		g = 255
	else
		g = _math_floor((value * 2) * 255 / 100)
	end

	if inverted then
		return g/255, r/255, 0
	else
		return r/255, g/255, 0
	end
end

_detalhes.trim = DetailsFramework.trim

--> scale
function _detalhes:Scale(rangeMin, rangeMax, scaleMin, scaleMax, x)
	return 1 +(x - rangeMin) *(scaleMax - scaleMin) /(rangeMax - rangeMin)
end

_detalhes.SetFontColor = DetailsFramework.SetFontColor
_detalhes.SetFontSize = DetailsFramework.SetFontSize

--> font face
function _detalhes:SetFontFace(fontString, fontface)
	local _, size, flags = fontString:GetFont()
	fontString:SetFont(fontface, size, flags)
end

--> font outline
function _detalhes:SetFontOutline(fontString, outline)
	local fonte, size = fontString:GetFont()
	if outline then
		if _type(outline) == "boolean" and outline then
			outline = "OUTLINE"
		elseif outline == 1 then
			outline = "OUTLINE"
		elseif outline == 2 then
			outline = "THICKOUTLINE"
		end
	end

	if _detalhes.force_font_outline ~= "" then
		if _detalhes.force_font_outline == "OUTLINE" then
			outline = "OUTLINE"
		elseif _detalhes.force_font_outline == "THICKOUTLINE" then
			outline = "THICKOUTLINE"
		elseif _detalhes.force_font_outline == "MONOCHROME" then
			outline = "MONOCHROME"
		end
	end

	fontString:SetFont(fonte, size, outline)
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> internal functions

function _detalhes:HealthTick()
	if UnitExists("boss1") and IsInRaid() and IsInInstance() then
		local health =(UnitHealth("boss1") or 0) /(UnitHealthMax("boss1") or 0)
		if _detalhes.boss1_health_percent then
			if _detalhes.boss1_health_percent < health then
				return
			end
		end
		_detalhes.boss1_health_percent = health
	end
end

function _detalhes:IsGroupInCombat()
	if _IsInRaid() then
		for i = 1, _GetNumGroupMembers() do
			if _UnitAffectingCombat("raid"..i) then
				return true
			end
		end
	elseif _IsInGroup() then
		for i = 1, GetNumPartyMembers() do
			if _UnitAffectingCombat("party"..i) then
				return true
			end
		end
	end
	return false
end

--> is in combat yet?
function _detalhes:EstaEmCombate()
	_detalhes:TimeDataTick()
	_detalhes:BrokerTick()
	_detalhes:HealthTick()
	if (_detalhes.zone_type == "pvp" and _detalhes.use_battleground_server_parser) or _detalhes.zone_type == "arena" or _InCombatLockdown() then
		return true
	elseif _UnitAffectingCombat("player") or _detalhes:IsGroupInCombat() then
		return true
	end
	-- TODO
	if _detalhes.encounter_table and _detalhes.encounter_table.id == 36597 then
		if (_detalhes.debug) then
			_detalhes:Msg ("(debug) in the lich king encounter, cannot leave the combat.")
		end
		return true
	end

	if not _detalhes:CheckBossKilledByDeadCache() then
		_detalhes:SairDoCombate()
	end
end

--[[ test grayscale ]]
function _detalhes:teste_grayscale()
	local instancia = _detalhes.tabela_instancias[1]
	for i = 1, instancia.rows_created, 1 do
		local barra = instancia.barras[i]
		local red, green, blue, alpha = barra.textura:GetVertexColor()
		local grayscale = (red * 0.03 + green + blue) / 3 --> grayscale lightness method
		gump:GradientEffect(barra.textura, "texture", red, green, blue, alpha, grayscale, grayscale, grayscale, alpha, 1)
	end
end

local function frame_task(self, elapsed)
	if self.HaveGradientEffect then
		local done = false
		for index, ThisGradient in _ipairs(self.gradientes) do
			if not ThisGradient.done then
				local percent = _math_min((_GetTime() - ThisGradient.TimeStart) / ThisGradient.Duration * 100, 100)
				local red_now = ThisGradient.StartRed +(percent  * ThisGradient.OnePercentRed)
				local green_now = ThisGradient.StartGreen +(percent * ThisGradient.OnePercentGreen)
				local blue_now = ThisGradient.StartBlue +(percent  * ThisGradient.OnePercentBlue)
				local alpha_now = ThisGradient.StartAlpha +(percent  * ThisGradient.OnePercentAlpha)

				if ThisGradient.ObjectType == "frame" then
					ThisGradient.Object:SetBackdropColor(red_now, green_now, blue_now, alpha_now)
				elseif ThisGradient.ObjectType == "texture" then
					ThisGradient.Object:SetVertexColor(red_now, green_now, blue_now, alpha_now)
				end

				if percent == 100 then
					if ThisGradient.Func then
						local okey, errortext = _pcall(ThisGradient.Func, ThisGradient.FuncParam)
						if not okey then
							_detalhes:Msg("GradientEffect() end function error:", errortext)
						end
					end

					ThisGradient.done = true
					done = true
				end
			end
		end

		if done then
			local _iter = {index = 1, data = self.gradientes[1]}
			while _iter.data do
				if _iter.data.done then
					_iter.data.Object.HaveGradientEffect = false
					table.remove(self.gradientes, _iter.index)
					_iter.data = self.gradientes[_iter.index]
				else
					_iter.index = _iter.index + 1
					_iter.data = self.gradientes[_iter.index]
				end
			end

			if #self.gradientes < 1 then
				self.HaveGradientEffect = false
			end
		end
	end

	if not self.HaveGradientEffect then
		self:SetScript("OnUpdate", nil)
	end
end

function gump:GradientEffect(Object, ObjectType, StartRed, StartGreen, StartBlue, StartAlpha, EndRed, EndGreen, EndBlue, EndAlpha, Duration, EndFunction, FuncParam)
	if type(StartRed) == "table" and type(StartGreen) == "table" then
		Duration, EndFunction = StartBlue, StartAlpha
		EndRed, EndGreen, EndBlue, EndAlpha = unpack(StartGreen)
		StartRed, StartGreen, StartBlue, StartAlpha = unpack(StartRed)
	elseif type(StartRed) == "table" then
		EndRed, EndGreen, EndBlue, EndAlpha, Duration, EndFunction = StartGreen, StartBlue, StartAlpha, EndRed, EndGreen, EndBlue
		StartRed, StartGreen, StartBlue, StartAlpha = unpack(StartRed)
	elseif type(EndRed) == "table" then
		Duration, EndFunction = EndGreen, EndBlue
		EndRed, EndGreen, EndBlue, EndAlpha = unpack(EndRed)
	end

	if not EndAlpha then
		EndAlpha = 1
	end
	if not StartAlpha then
		StartAlpha = 1
	end

	if EndRed > 1 then
		EndRed = 1
	end
	if EndGreen > 1 then
		EndGreen = 1
	end
	if EndBlue > 1 then
		EndBlue = 1
	end

	local GradientFrameControl = _detalhes.listener
	GradientFrameControl.gradientes = GradientFrameControl.gradientes or {}

	for index = 1, #GradientFrameControl.gradientes do
		if GradientFrameControl.gradientes[index].Object == Object then
			GradientFrameControl.gradientes[index].done = true
		end
	end

	if EndFunction and _type(EndFunction) == "string" then
		EndFunction = loadstring(EndFunction) or false
	end

	GradientFrameControl.gradientes[#GradientFrameControl.gradientes+1] = {
		Object = Object,
		ObjectType = string.lower(ObjectType),
		Func = EndFunction,
		FuncParam = FuncParam,
		TimeStart = GetTime(),
		Duration = Duration,

		StartRed = StartRed,
		StartGreen = StartGreen,
		StartBlue = StartBlue,
		StartAlpha = StartAlpha,

		OnePercentRed = StartRed > EndRed and(StartRed - EndRed) / 100 * -1 or(EndRed - StartRed) / 100,
		OnePercentGreen = StartGreen > EndGreen and(StartGreen - EndGreen) / 100 * -1 or(EndGreen - StartGreen) / 100,
		OnePercentBlue = StartBlue > EndBlue and(StartBlue - EndBlue) / 100 * -1 or(EndBlue - StartBlue) / 100,
		OnePercentAlpha = StartAlpha > EndAlpha and(StartAlpha - EndAlpha) / 100 * -1 or(EndAlpha - StartAlpha) /100,
	}

	Object.HaveGradientEffect = true
	GradientFrameControl.HaveGradientEffect = true

	if not GradientFrameControl:GetScript("OnUpdate") then
		GradientFrameControl:SetScript("OnUpdate", frame_task)
	end
end

local df_create_flash_animation = gump.CreateFlashAnimation
local stop_flash = function(self)
	local FlashAnimation = self.FlashAnimation
	FlashAnimation:Stop()
	FlashAnimation.frame:SetAlpha(0)
end

function gump:CreateFlashAnimation(frame, onFinishFunc, onLoopFunc)
	df_create_flash_animation(self, frame, onFinishFunc, onLoopFunc)
	frame.Stop = stop_flash
end

--> todo: remove the function creation everytime this function run.

local fadingFrames = {}
local finishedFades = {}
local fadeDriver = CreateFrame("Frame")

local function FadeDriver_OnUpdate(self, elapsed)
	for frame, fadeInfo in pairs(fadingFrames) do
		fadeInfo.fadeTimer = fadeInfo.fadeTimer + elapsed
		if fadeInfo.fadeTimer < fadeInfo.timeToFade then
			frame:SetAlpha(fadeInfo.startAlpha + (fadeInfo.endAlpha - fadeInfo.startAlpha) * fadeInfo.fadeTimer / fadeInfo.timeToFade)
		else
			frame:SetAlpha(fadeInfo.endAlpha)
			fadingFrames[frame] = nil
			finishedFades[#finishedFades + 1] = fadeInfo
		end
	end
	for i = 1, #finishedFades do
		local fadeInfo = finishedFades[i]
		finishedFades[i] = nil
		local func = fadeInfo.finishedFunc
		if func then
			fadeInfo.finishedFunc = nil
			func(fadeInfo.finishedArg1)
		end
	end
	if not next(fadingFrames) then
		self:SetScript("OnUpdate", nil)
	end
end

local function FadeFrame(frame, timeToFade, startAlpha, endAlpha)
	local fadeInfo = {timeToFade = timeToFade, startAlpha = startAlpha, endAlpha = endAlpha, fadeTimer = 0}
	frame:SetAlpha(startAlpha)
	frame.fadeInfo = fadeInfo
	frame:Show()
	fadingFrames[frame] = fadeInfo
	fadeDriver:SetScript("OnUpdate", FadeDriver_OnUpdate)
end

local fade_IN_finished_func = function(frame)
	if frame.fading_in then
		frame.hidden = true
		frame.faded = true
		frame.fading_in = false
		frame:Hide()
	end
end

local fade_OUT_finished_func = function(frame)
	if frame:IsShown() and frame.fading_out then
		frame.hidden = false
		frame.faded = false
		frame.fading_out = false
	else
		frame:SetAlpha(0)
	end
end

local just_fade_func = function(frame)
	frame.hidden = false
	frame.faded = true
	frame.fading_in = false
end

local anim_OUT_alpha_func = function(frame)
	frame.fading_out = false
end

local anim_IN_alpha_func = function(frame)
	frame.fading_in = false
end

function gump:Fade(frame, tipo, velocidade, parametros)
	if _type(frame) == "table" then
		if frame.meu_id then --> ups, � uma inst�ncia
			if parametros == "barras" then --> hida todas as barras da inst�ncia
				if velocidade then
					for i = 1, frame.rows_created, 1 do
						gump:Fade(frame.barras[i], tipo, velocidade)
					end
					return
				else
					velocidade = velocidade or 0.3
					for i = 1, frame.rows_created, 1 do
						gump:Fade(frame.barras[i], tipo, 0.3+(i/10))
					end
					return
				end
			elseif parametros == "hide_barras" then --> hida todas as barras da inst�ncia
				for i = 1, frame.rows_created, 1 do
					local esta_barra = frame.barras[i]
					if esta_barra.fading_in or esta_barra.fading_out then
						esta_barra.fadeInfo.finishedFunc = nil
						FadeFrame(esta_barra, 0.01, esta_barra:GetAlpha(), esta_barra:GetAlpha())
					end
					esta_barra.hidden = true
					esta_barra.faded = true
					esta_barra.fading_in = false
					esta_barra.fading_out = false
					esta_barra:Hide()
					esta_barra:SetAlpha(0)
				end
				return
			end
		elseif frame.dframework then
			frame = frame.widget
		end
	end

	velocidade = velocidade or 0.3

	--> esse ALL aqui pode dar merda com as inst�ncias n�o ativadas
	if frame == "all" then --> todas as inst�ncias
		for _, instancia in _ipairs(_detalhes.tabela_instancias) do
			if parametros == "barras" then --> hida todas as barras da inst�ncia
				for i = 1, instancia.rows_created, 1 do
					gump:Fade(instancia.barras[i], tipo, velocidade+(i/10))
				end
			end
		end
	elseif _upper(tipo) == "IN" then
		if frame:GetAlpha() == 0 and frame.hidden and not frame.fading_out then --> ja esta escondida
			return
		elseif frame.fading_in then --> ja esta com uma anima��o, se for true
			return
		end

		if frame.fading_out then --> se tiver uma anima��o de aparecer em andamento se for true
			frame.fading_out = false
		end

		FadeFrame(frame, velocidade, frame:GetAlpha(), 0)
		frame.fading_in = true

		frame.fadeInfo.finishedFunc = fade_IN_finished_func
		frame.fadeInfo.finishedArg1 = frame
	elseif _upper(tipo) == "OUT" then --> aparecer
		if frame:GetAlpha() == 1 and not frame.hidden and not frame.fading_in then --> ja esta na tela
			return
		elseif frame.fading_out then --> j� ta com fading out
			return
		end

		if frame.fading_in then --> se tiver uma anima��o de hidar em andamento se for true
			frame.fading_in = false
		end

		frame:Show()
		FadeFrame(frame, velocidade, frame:GetAlpha(), 1.0)
		frame.fading_out = true

		frame.fadeInfo.finishedFunc = fade_OUT_finished_func
		frame.fadeInfo.finishedArg1 = frame
	elseif tipo == 0 then --> for�a o frame a ser mostrado
		frame.hidden = false
		frame.faded = false
		frame.fading_out = false
		frame.fading_in = false
		frame:Show()
		frame:SetAlpha(1)
	elseif tipo == 1 then --> for�a o frame a ser hidado
		frame.hidden = true
		frame.faded = true
		frame.fading_out = false
		frame.fading_in = false
		frame:SetAlpha(0)
		frame:Hide()
	elseif tipo == -1 then --> apenas da fade sem hidar
		if frame:GetAlpha() == 0 and frame.hidden and not frame.fading_out then --> ja esta escondida
			return
		elseif frame.fading_in then --> ja esta com uma anima��o, se for true
			return
		end

		if frame.fading_out then --> se tiver uma anima��o de aparecer em andamento se for true
			frame.fading_out = false
		end

		FadeFrame(frame, velocidade, frame:GetAlpha(), 0)
		frame.fading_in = true
		frame.fadeInfo.finishedFunc = just_fade_func
		frame.fadeInfo.finishedArg1 = frame
	elseif _upper(tipo) == "ALPHAANIM" then
		local value = velocidade
		local currentApha = frame:GetAlpha()
		frame:Show()

		if currentApha < value then
			if frame.fading_in then --> se tiver uma anima��o de hidar em andamento se for true
				frame.fading_in = false
				frame.fadeInfo.finishedFunc = nil
			end

			FadeFrame(frame, 0.3, currentApha, value)
			frame.fading_out = true

			frame.fadeInfo.finishedFunc = anim_OUT_alpha_func
			frame.fadeInfo.finishedArg1 = frame
		else
			if frame.fading_out then --> se tiver uma anima��o de hidar em andamento se for true
				frame.fading_out = false
				frame.fadeInfo.finishedFunc = nil
			end

			FadeFrame(frame, 0.3, currentApha, value)
			frame.fading_in = true

			frame.fadeInfo.finishedFunc = anim_IN_alpha_func
			frame.fadeInfo.finishedArg1 = frame
		end
	elseif _upper(tipo) == "ALPHA" then --> setando um alpha determinado
		if frame.fading_in or frame.fading_out then
			frame.fadeInfo.finishedFunc = nil
			FadeFrame(frame, velocidade, frame:GetAlpha(), frame:GetAlpha())
		end

		frame.hidden = false
		frame.faded = false
		frame.fading_in = false
		frame.fading_out = false
		frame:Show()
		frame:SetAlpha(velocidade)
	end
end

function _detalhes:name_space(barra)
		barra.texto_esquerdo:SetSize(barra:GetWidth() - barra.texto_direita:GetStringWidth() - 18, 15)
end

function _detalhes:name_space_info(barra)
	if barra.icone_secundario_ativo then
		local tamanho = barra:GetWidth() - barra.texto_direita:GetStringWidth() - 16 - barra:GetHeight()
		barra.texto_esquerdo:SetSize(tamanho-10, 15)
	else
		local tamanho = barra:GetWidth() - barra.texto_direita:GetStringWidth() - 16
		barra.texto_esquerdo:SetSize(tamanho-10, 15)
	end
end

function _detalhes:ShowTotalBar(instance, total, combat_time)
	local row1 = instance.barras[1]
	row1.minha_tabela = nil
	row1.texto_esquerdo:SetText(Loc["STRING_TOTAL"])
	row1.texto_direita:SetText(_detalhes:ToK2(total) .. " (" .. _detalhes:ToK(total / combat_time) .. ")")
	row1:SetValue(100)
	local r, g, b = unpack(instance.total_bar.color)
	row1.textura:SetVertexColor(r, g, b)
	row1.icone_classe:SetTexture(instance.total_bar.icon)
	row1.icone_classe:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
	gump:Fade(row1, "out")

	local iter_last = instance.barraS[2]
	if iter_last == instance.rows_fit_in_window then
		iter_last = iter_last - 1
	end
	return iter_last
end