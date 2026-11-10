



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> basic stuff

	local _
	local _detalhes = _G._detalhes

	--> mantain the enabled time captures
	_detalhes.timeContainer = {}
	_detalhes.timeContainer.Exec = {}

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> local pointers
	local ipairs = ipairs
	local _math_floor = math.floor
	local _pcall = pcall

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> constants

	local INDEX_NAME = 1
	local INDEX_FUNCTION = 2
	local INDEX_MATRIX = 3
	local INDEX_AUTHOR = 4
	local INDEX_VERSION = 5
	local INDEX_ICON = 6
	local INDEX_ENABLED = 7

	local DEFAULT_USER_MATRIX = {max_value = 0, last_value = 0}

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> register and unregister captures


	function _detalhes:TimeDataUpdate (index_or_name, name, func, matrix, author, version, icon, is_enabled)

		local this_capture
		if (type (index_or_name) == "number") then
			this_capture = _detalhes.savedTimeCaptures [index_or_name]
		else
			for index, t in ipairs (_detalhes.savedTimeCaptures) do
				if (t [INDEX_NAME] == index_or_name) then
					this_capture = t
				end
			end
		end

		if (not this_capture) then
			return false
		end

		if (this_capture.do_not_save) then
			return _detalhes:Msg ("This capture belongs to a plugin and cannot be edited.")
		end

		this_capture [INDEX_NAME] = name or this_capture [INDEX_NAME]
		this_capture [INDEX_FUNCTION] = func or this_capture [INDEX_FUNCTION]
		this_capture [INDEX_MATRIX] = matrix or this_capture [INDEX_MATRIX]
		this_capture [INDEX_AUTHOR] = author or this_capture [INDEX_AUTHOR]
		this_capture [INDEX_VERSION] = version or this_capture [INDEX_VERSION]
		this_capture [INDEX_ICON] = icon or this_capture [INDEX_ICON]

		if (is_enabled ~= nil) then
			this_capture [INDEX_ENABLED] = is_enabled
		end

		if (_G.DetailsOptionsWindow and _G.DetailsOptionsWindow:IsShown()) then
			_G.DetailsOptionsWindow16UserTimeCapturesFillPanel.MyObject:Refresh()
		end

		return true

	end

	--matrix = table containing {max_value = 0, last_value = 0}
	function _detalhes:TimeDataRegister (name, func, matrix, author, version, icon, is_enabled, force_no_save)

		--> check name
		if (not name) then
			return "Couldn't register the time capture, name was nil."
		end

		--> check if the name already exists
		for index, t in ipairs (_detalhes.savedTimeCaptures) do
			if (t [INDEX_NAME] == name) then
				return "Couldn't register the time capture, name already registred."
			end
		end

		--> check function
		if (not func) then
			return "Couldn't register the time capture, invalid function."
		end

		local no_save = nil
		--> passed a function means that this isn't came from a user
		--> so the plugin register the capture every time it loads.
		if (type (func) == "function") then
			no_save = true

		--> this a custom capture from a user, so we register a default user table for matrix
		elseif (type (func) == "string") then
			matrix = DEFAULT_USER_MATRIX

		end

		if (not no_save and force_no_save) then
			no_save = true
		end

		--> check matrix
		if (not matrix or type (matrix) ~= "table") then
			return "Couldn't register the time capture, matrix was invalid."
		end

		author = author or "Unknown"
		version = version or "v1.0"
		icon = icon or [[Interface\InventoryItems\WoWUnknownItem01]]

		_detalhes.savedTimeCaptures[#_detalhes.savedTimeCaptures+1] = {name, func, matrix, author, version, icon, is_enabled, do_not_save = no_save}

		if (_G.DetailsOptionsWindow and _G.DetailsOptionsWindow:IsShown()) then
			_G.DetailsOptionsWindow16UserTimeCapturesFillPanel.MyObject:Refresh()
		end

		return true

	end

	--> unregister
	function _detalhes:TimeDataUnregister (name)
		if (type (name) == "number") then
			tremove (_detalhes.savedTimeCaptures, name)
			if (_G.DetailsOptionsWindow and _G.DetailsOptionsWindow:IsShown()) then
				_G.DetailsOptionsWindow16UserTimeCapturesFillPanel.MyObject:Refresh()
			end
		else
			for index, t in ipairs (_detalhes.savedTimeCaptures) do
				if (t [INDEX_NAME] == name) then
					tremove (_detalhes.savedTimeCaptures, index)
					if (_G.DetailsOptionsWindow and _G.DetailsOptionsWindow:IsShown()) then
						_G.DetailsOptionsWindow16UserTimeCapturesFillPanel.MyObject:Refresh()
					end
					return true
				end
			end
			return false
		end
	end

	--> cleanup when logout
	function _detalhes:TimeDataCleanUpTemporary()
		local new_table = {}
		for index, t in ipairs (_detalhes.savedTimeCaptures) do
			if (not t.do_not_save) then
				new_table[#new_table+1] = t
			end
		end
		_detalhes.savedTimeCaptures = new_table
	end

	local tick_time = 0

		local functionFilter = _detalhes:CreateScriptEnvironment()

	--> starting a combat
	function _detalhes:TimeDataCreateCombatTables()

		--> create capture table
		local data_captured = {}

		--> drop the last capture exec table without wiping
		local exec = {}
		_detalhes.timeContainer.Exec = exec

		_detalhes:SendEvent ("COMBAT_CHARTTABLES_CREATING")

		--> build the exec table
		for index, t in ipairs (_detalhes.savedTimeCaptures) do
			if (t [INDEX_ENABLED]) then

				local data = {}
				data_captured [t [INDEX_NAME]] = data

				if (type (t [INDEX_FUNCTION]) == "string") then
					--> user
					local func, errortext = loadstring (t [INDEX_FUNCTION])
					if (func) then
						setfenv (func, functionFilter)
						exec[#exec+1] = { func = func, data = data, attributes = table_deepcopy (t [INDEX_MATRIX]), is_user = true }
					else
						_detalhes:Msg ("|cFFFF9900error compiling script for time data (charts)|r: ", errortext)
					end
				else
					--> plugin
					local func = t [INDEX_FUNCTION]
					setfenv (func, functionFilter)
					exec[#exec+1] = { func = func, data = data, attributes = table_deepcopy (t [INDEX_MATRIX]) }
				end

			end
		end

		_detalhes:SendEvent ("COMBAT_CHARTTABLES_CREATED")

		tick_time = 0

		--> return the capture table the to combat object
		return data_captured
	end

	local exec_user_func = function (func, attributes, data, this_second)

		local okey, result = _pcall (func, attributes)
		if (not okey) then
			_detalhes:Msg ("|cFFFF9900error on chart script function|r:", result)
			result = 0
		end

		local current = result - attributes.last_value
		data [this_second] = current

		if (current > attributes.max_value) then
			attributes.max_value = current
			data.max_value = current
		end

		attributes.last_value = result

	end

	function _detalhes:TimeDataTick()

		tick_time = tick_time + 1

		local execTable = _detalhes.timeContainer.Exec
		for index = 1, #execTable do
			local t = execTable[index]
			if (t.is_user) then
				--> by a user
				exec_user_func (t.func, t.attributes, t.data, tick_time)
			else
				--> by a plugin
				t.func (t.attributes, t.data, tick_time)
			end
		end

	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> broker dps stuff

	local ToKFunctions = _detalhes.ToKFunctions


	local get_combat_time = function()
		local combat_time = _detalhes.tabela_vigente:GetCombatTime()
		local minutos, segundos = _math_floor (combat_time / 60), _math_floor (combat_time % 60)
		if (segundos < 10) then
			segundos = "0" .. segundos
		end
		return minutos .. "m " .. segundos .. "s"
	end

	local get_position = function (attribute)
		local container = _detalhes.tabela_vigente [attribute]
		container:SortByKey ("total")

		local pos = 1
		for index, actor in ipairs (container._ActorTable) do
			if (actor.grupo) then
				if (actor.nome == _detalhes.playername) then
					return pos
				end
				pos = pos + 1
			end
		end

		return 0
	end

	local get_diff = function (attribute)
		local container = _detalhes.tabela_vigente [attribute]
		container:SortByKey ("total")

		local first
		local first_index
		for index, actor in ipairs (container._ActorTable) do
			if (actor.grupo) then
				first = actor
				first_index = index
				break
			end
		end

		if (first) then
			if (first.nome == _detalhes.playername) then
				local second
				local actors = container._ActorTable
				for i = first_index+1, #actors do
					if (actors[i].grupo) then
						second = actors[i]
						break
					end
				end

				if (second) then
					local diff = first.total - second.total
					return "+" .. ToKFunctions [_detalhes.minimap.text_format] (_, diff)
				else
					return "0"
				end
			else
				local player = container._NameIndexTable [_detalhes.playername]
				if (player) then
					player = container._ActorTable [player]
					local diff = first.total - player.total
					return "-" .. ToKFunctions [_detalhes.minimap.text_format] (_, diff)
				else
					return ToKFunctions [_detalhes.minimap.text_format] (_, first.total)
				end
			end
		else
			return "0"
		end
	end

	local get_player_ps = function (attribute)
		local player = _detalhes.tabela_vigente (attribute, _detalhes.playername)
		if (player) then
			local combat_time
			if (_detalhes.time_type == 1) then --activity time
				combat_time = player:Tempo()
			else --effective time
				combat_time = _detalhes.tabela_vigente:GetCombatTime()
			end
			if (combat_time > 0) then
				return ToKFunctions [_detalhes.minimap.text_format] (_, player.total / combat_time)
			end
		end
		return 0
	end

	local get_raid_ps = function (attribute)
		local raid_total = _detalhes.tabela_vigente.totals [attribute]
		if (raid_total) then
			return ToKFunctions [_detalhes.minimap.text_format] (_, raid_total / _detalhes.tabela_vigente:GetCombatTime())
		else
			return 0
		end
	end

	local get_player_total = function (attribute)
		local player = _detalhes.tabela_vigente (attribute, _detalhes.playername)
		if (player) then
			return ToKFunctions [_detalhes.minimap.text_format] (_, player.total)
		else
			return 0
		end
	end

	local get_damage_position = function() return get_position (1) end
	local get_heal_position = function() return get_position (2) end
	local get_damage_diff = function() return get_diff (1) end
	local get_heal_diff = function() return get_diff (2) end
	local get_player_dps = function() return get_player_ps (1) end
	local get_player_hps = function() return get_player_ps (2) end
	local get_raid_dps = function() return get_raid_ps (1) end
	local get_raid_hps = function() return get_raid_ps (2) end
	local get_player_damage = function() return get_player_total (1) end
	local get_player_heal = function() return get_player_total (2) end

	local parse_broker_text = function()
		local text = _detalhes.data_broker_text
		if (text == "") then
			return
		end

		text = text:gsub ("{dmg}", get_player_damage)
		text = text:gsub ("{rdps}", get_raid_dps)
		text = text:gsub ("{rhps}", get_raid_hps)
		text = text:gsub ("{dps}", get_player_dps)
		text = text:gsub ("{heal}", get_player_heal)
		text = text:gsub ("{hps}", get_player_hps)
		text = text:gsub ("{time}", get_combat_time)
		text = text:gsub ("{dpos}", get_damage_position)
		text = text:gsub ("{hpos}", get_heal_position)
		text = text:gsub ("{ddiff}", get_damage_diff)
		text = text:gsub ("{hdiff}", get_heal_diff)

		return text
	end

	function _detalhes:BrokerTick()
		_detalhes.databroker.text = parse_broker_text()
	end

	function _detalhes:SetDataBrokerText (text)
		if (type (text) == "string") then
			_detalhes.data_broker_text = text
			_detalhes:BrokerTick()
		elseif (text == nil or (type (text) == "boolean" and not text)) then
			_detalhes.data_broker_text = ""
			_detalhes:BrokerTick()
		end
	end

