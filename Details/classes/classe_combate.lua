-- combat class object
local _detalhes = _G._detalhes
local Loc = LibStub("AceLocale-3.0"):GetLocale( "Details" )

DETAILS_TOTALS_ONLYGROUP = true

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> local pointers

local _setmetatable = setmetatable -- lua local
local _ipairs = ipairs -- lua local
local _bit_band = bit.band -- lua local
local _date = date -- lua local
local _rawget = rawget
local _math_max = math.max
local _math_floor = math.floor
local _GetTime = GetTime

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> constants

local combate = _detalhes.combate
local container_combatentes = _detalhes.container_combatentes
local class_type_dano = _detalhes.atributos.dano
local class_type_cura = _detalhes.atributos.cura
local class_type_e_energy = _detalhes.atributos.e_energy
local class_type_misc = _detalhes.atributos.misc

local REACTION_HOSTILE =	0x00000040
local CONTROL_PLAYER = 		0x00000100

--local _tempo = time()
local _tempo = _GetTime()

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> api functions

--get the start date and end date
function combate:GetDate()
	return self.data_inicio, self.data_fim
end

--set the combat date
function combate:SetDate(started, ended)
	if started and type(started) == "string" then
		self.data_inicio = started
	end

	if ended and type(ended) == "string" then
		self.data_fim = ended
	end
end

--return data for charts
function combate:GetTimeData(name)
	return self.TimeData[name]
end

function combate:GetContainer(attribute)
	return self[attribute]
end

function combate:GetRoster()
	return self.raid_roster
end

function combate:InstanceType()
	return _rawget(self, "instance_type")
end

function combate:IsTrash()
	return _rawget(self, "is_trash")
end

function combate:GetDifficulty()
	return self.is_boss and self.is_boss.diff
end

function combate:GetBossInfo()
	return self.is_boss
end

function combate:GetPhases()
	return self.PhaseData
end

function combate:GetPvPInfo()
	return self.is_pvp
end

function combate:GetArenaInfo()
	return self.is_arena
end

function combate:GetDeaths()
	return self.last_events_tables
end

function combate:GetPlayerDeaths(deadPlayerName)
	local allDeaths = self:GetDeaths()
	local deaths = {}

	for i = 1, #allDeaths do
		local thisDeath = allDeaths[i]
		local thisPlayerName = thisDeath[3]
		if (deadPlayerName == thisPlayerName) then
			deaths[#deaths+1] = thisDeath
		end
	end

	return deaths
end
function combate:GetCombatId()
	return self.combat_id
end

function combate:GetCombatNumber()
	return self.combat_counter
end

--return the name of the encounter or enemy
function combate:GetCombatName(try_find)
	if self.is_pvp then
		return self.is_pvp.name
	elseif self.is_boss then
		return self.is_boss.encounter
	elseif _rawget(self, "is_trash") then
		return Loc["STRING_SEGMENT_TRASH"]
	else
		if self.enemy then
			return self.enemy
		end

		if try_find then
			return _detalhes:FindEnemy()
		end
	end

	return Loc["STRING_UNKNOW"]
end

DETAILS_SEGMENTID_OVERALL = -1
DETAILS_SEGMENTID_CURRENT = 0

--enum segments type
DETAILS_SEGMENTTYPE_GENERIC = 0

DETAILS_SEGMENTTYPE_OVERALL = 1

DETAILS_SEGMENTTYPE_DUNGEON_TRASH = 5
DETAILS_SEGMENTTYPE_DUNGEON_BOSS = 6

DETAILS_SEGMENTTYPE_RAID_TRASH = 7
DETAILS_SEGMENTTYPE_RAID_BOSS = 8

DETAILS_SEGMENTTYPE_PVP_ARENA = 20
DETAILS_SEGMENTTYPE_PVP_BATTLEGROUND = 21

function combate:GetCombatType()
	--> arena
	local arenaInfo = self.is_arena
	if arenaInfo then
		return DETAILS_SEGMENTTYPE_PVP_ARENA
	end

	--> battleground
	local battlegroundInfo = self.is_pvp
	if battlegroundInfo then
		return DETAILS_SEGMENTTYPE_PVP_BATTLEGROUND
	end

	--> dungeon or raid
	local instanceType = self.instance_type
	if instanceType == "party" then
		local bossEncounter =  self.is_boss
		if bossEncounter then
			return DETAILS_SEGMENTTYPE_DUNGEON_BOSS
		else
			return DETAILS_SEGMENTTYPE_DUNGEON_TRASH
		end
	elseif instanceType == "raid" then
		local bossEncounter =  self.is_boss
		if bossEncounter then
			return DETAILS_SEGMENTTYPE_RAID_BOSS
		else
			return DETAILS_SEGMENTTYPE_RAID_TRASH
		end
	end

	--> overall data
	if self == _detalhes.tabela_overall then
		return DETAILS_SEGMENTTYPE_OVERALL
	end

	return DETAILS_SEGMENTTYPE_GENERIC
end

--return a numeric table with all actors on the specific containter
function combate:GetActorList(container)
	return self[container]._ActorTable
end

function combate:GetActor(container, name)
	local index = self[container] and self[container]._NameIndexTable[name]
	if index then
		return self[container]._ActorTable[index]
	end
	return nil
end
combate.__call = combate.GetActor

--return the combat time in seconds
function combate:GetFormatedCombatTime()
	local time = self:GetCombatTime()
	local m, s = _math_floor(time/60), _math_floor(time%60)
	return m, s
end

function combate:GetCombatTime()
	if self.end_time then
		return _math_max(self.end_time - self.start_time, 0.1)
	elseif self.start_time and _detalhes.in_combat and self ~= _detalhes.tabela_overall then
		return _math_max(_GetTime() - self.start_time, 0.1)
	else
		return 0.1
	end
end

function combate:GetStartTime()
	return self.start_time
end

function combate:SetStartTime(t)
	self.start_time = t
end

function combate:GetEndTime()
	return self.end_time
end

function combate:SetEndTime(t)
	self.end_time = t
end

--return the total of a specific attribute
local power_table = {0, 1, 3, 6, 0}

function combate:GetTotal(attribute, subAttribute, onlyGroup)
	if attribute == 1 or attribute == 2 then
		if onlyGroup then
			return self.totals_grupo[attribute]
		else
			return self.totals[attribute]
		end
	elseif attribute == 3 then
		if subAttribute == 5 then --> resources
			return self.totals.resources or 0
		end
		if onlyGroup then
			return self.totals_grupo[attribute][power_table[subAttribute]]
		else
			return self.totals[attribute][power_table[subAttribute]]
		end
	elseif attribute == 4 then
		local subName = _detalhes:GetInternalSubAttributeName(attribute, subAttribute)
		if onlyGroup then
			return self.totals_grupo[attribute][subName]
		else
			return self.totals[attribute][subName]
		end
	end

	return 0
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> internals

function combate:CreateNewCombatTable()
	return combate:NovaTabela()
end

local new_totals = function()
	return {0, 0, {[0] = 0, [1] = 0, [3] = 0, [6] = 0}, {cc_break = 0, ress = 0, interrupt = 0, dispell = 0, dead = 0, cooldowns_defensive = 0, buff_uptime = 0, debuff_uptime = 0}}
end

--class constructor
function combate:NovaTabela(iniciada, _tabela_overall, combatId, ...)
	local esta_tabela = {true, true, true, true, true}

	esta_tabela[1] = container_combatentes:NovoContainer(_detalhes.container_type.CONTAINER_DAMAGE_CLASS, esta_tabela, combatId) --> Damage
	esta_tabela[2] = container_combatentes:NovoContainer(_detalhes.container_type.CONTAINER_HEAL_CLASS, esta_tabela, combatId) --> Healing
	esta_tabela[3] = container_combatentes:NovoContainer(_detalhes.container_type.CONTAINER_ENERGY_CLASS, esta_tabela, combatId) --> Energies
	esta_tabela[4] = container_combatentes:NovoContainer(_detalhes.container_type.CONTAINER_MISC_CLASS, esta_tabela, combatId) --> Misc
	esta_tabela[5] = container_combatentes:NovoContainer(_detalhes.container_type.CONTAINER_DAMAGE_CLASS, esta_tabela, combatId) --> place holder for customs

	_setmetatable(esta_tabela, combate)

	_detalhes.combat_counter = _detalhes.combat_counter + 1
	esta_tabela.combat_counter = _detalhes.combat_counter

	--> try discover if is a pvp combat
	local who_serial, who_name, who_flags, alvo_serial, alvo_name, alvo_flags = ...
	if who_serial then --> aqui ir� identificar o boss ou o oponente
		if alvo_name and _bit_band(alvo_flags, REACTION_HOSTILE) ~= 0 then --> tentando pegar o inimigo pelo alvo
			esta_tabela.contra = alvo_name
			if _bit_band(alvo_flags, CONTROL_PLAYER) ~= 0 then
				esta_tabela.pvp = true --> o alvo � da fac��o oposta ou foi dado mind control
			end
		elseif who_name and _bit_band(who_flags, REACTION_HOSTILE) ~= 0 then --> tentando pegar o inimigo pelo who caso o mob � quem deu o primeiro hit
			esta_tabela.contra = who_name
			if _bit_band(who_flags, CONTROL_PLAYER) ~= 0 then
				esta_tabela.pvp = true --> o who � da fac��o oposta ou foi dado mind control
			end
		else
			esta_tabela.pvp = true --> se ambos s�o friendly, seria isso um PVP entre jogadores da mesma fac��o?
		end
	end

	--> start/end time(duration)
	esta_tabela.data_fim = 0
	esta_tabela.data_inicio = 0

	--> record deaths
	esta_tabela.last_events_tables = {}

	--> last events from players
	esta_tabela.player_last_events = {}

	--> players in the raid
	esta_tabela.raid_roster = {}

	--> frags
	esta_tabela.frags = {}

	--> time data container
	esta_tabela.TimeData = _detalhes:TimeDataCreateCombatTables()
	esta_tabela.PhaseData = {{1, 1}, damage = {}, heal = {}, damage_section = {}, heal_section = {}} --[1] phase number[2] phase started

	-- a tabela sem o tempo de inicio � a tabela descartavel do inicio do addon
	if iniciada then
		--esta_tabela.start_time = _tempo
		esta_tabela.start_time = _GetTime()
		esta_tabela.end_time = nil
	else
		esta_tabela.start_time = 0
		esta_tabela.end_time = nil
	end

	-- o container ir� armazenar as classes de dano -- cria um novo container de indexes de seriais de jogadores --par�metro 1 classe armazenada no container, par�metro 2 = flag da classe
	esta_tabela[1].need_refresh = true
	esta_tabela[2].need_refresh = true
	esta_tabela[3].need_refresh = true
	esta_tabela[4].need_refresh = true
	esta_tabela[5].need_refresh = true

	if _tabela_overall then --> link � a tabela de combate do overall
		esta_tabela[1].shadow = _tabela_overall[1]
		esta_tabela[2].shadow = _tabela_overall[2]
		esta_tabela[3].shadow = _tabela_overall[3]
		esta_tabela[4].shadow = _tabela_overall[4]
	end

	esta_tabela.totals = new_totals()
	esta_tabela.totals.voidzone_damage = 0
	esta_tabela.totals.frags_total = 0
	esta_tabela.totals_grupo = new_totals()

	return esta_tabela
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> core

function combate:CreateLastEventsTable(player_name)
	local t = {}
	for i = 1, _detalhes.deadlog_events do
		t[i] = {}
	end
	t.n = 1
	self.player_last_events[player_name] = t
	return t
end

--trava o tempo dos jogadores ap�s o t�rmino do combate.
function combate:TravarTempos()
	if self[1] then
		for _, jogador in _ipairs(self[1]._ActorTable) do --> damage
			if jogador:Iniciar() then -- retorna se ele esta com o dps ativo
				jogador:TerminarTempo()
				jogador:Iniciar(false) --trava o dps do jogador
			else
				if jogador.start_time == 0 then
					jogador.start_time = _tempo
				end
				if not jogador.end_time then
					jogador.end_time = _tempo
				end
			end
		end
	end

	if self[2] then
		for _, jogador in _ipairs(self[2]._ActorTable) do --> healing
			if jogador:Iniciar() then -- retorna se ele esta com o dps ativo
				jogador:TerminarTempo()
				jogador:Iniciar(false) --trava o dps do jogador
			else
				if jogador.start_time == 0 then
					jogador.start_time = _tempo
				end
				if not jogador.end_time then
					jogador.end_time = _tempo
				end
			end
		end
	end
end

function combate:seta_data(tipo)
	if tipo == _detalhes._detalhes_props.DATA_TYPE_START then
		self.data_inicio = _date("%H:%M:%S")
	elseif tipo == _detalhes._detalhes_props.DATA_TYPE_END then
		self.data_fim = _date("%H:%M:%S")
	end
end

function combate:seta_tempo_decorrido()
	--self.end_time = _tempo
	self.end_time = _GetTime()
end

function _detalhes.refresh:r_combate(tabela_combate, shadow)
	_setmetatable(tabela_combate, _detalhes.combate)
	tabela_combate.shadow = shadow
end

function _detalhes.clear:c_combate(tabela_combate)
	tabela_combate.shadow = nil
end


combate.__add = function(combate1, combate2)
	local all_containers = {combate2[class_type_dano]._ActorTable, combate2[class_type_cura]._ActorTable, combate2[class_type_e_energy]._ActorTable, combate2[class_type_misc]._ActorTable}
	local custom_combat
	if combate1 ~= _detalhes.tabela_overall then
		custom_combat = combate1
	end

	for class_type, actor_container in _ipairs(all_containers) do
		for _, actor in _ipairs(actor_container) do
			local shadow

			if class_type == class_type_dano then
				shadow = _detalhes.atributo_damage:r_connect_shadow(actor, true, custom_combat)
			elseif class_type == class_type_cura then
				shadow = _detalhes.atributo_heal:r_connect_shadow(actor, true, custom_combat)
			elseif class_type == class_type_e_energy then
				shadow = _detalhes.atributo_energy:r_connect_shadow(actor, true, custom_combat)
			elseif class_type == class_type_misc then
				shadow = _detalhes.atributo_misc:r_connect_shadow(actor, true, custom_combat)
			end

			shadow.boss_fight_component = actor.boss_fight_component or shadow.boss_fight_component
			shadow.fight_component = actor.fight_component or shadow.fight_component
			shadow.grupo = actor.grupo or shadow.grupo
		end
	end

	return combate1
end

function _detalhes:UpdateCombat()
	_tempo = _detalhes._tempo
end