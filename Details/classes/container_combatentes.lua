-- actor container file

	local _detalhes = 		_G._detalhes
	local DF = DetailsFramework
	local _

	local CONST_CLIENT_LANGUAGE = DF.ClientLanguage

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> local pointers

	local _UnitClass = UnitClass --api local
	local _IsInInstance = IsInInstance --api local
	local _UnitGUID = UnitGUID --api local

	local _setmetatable = setmetatable --lua local
	local _bit_band = bit.band --lua local
	local _table_sort = table.sort --lua local
	local _ipairs = ipairs --lua local
	local _pairs = pairs --lua local

	local AddUnique = DetailsFramework.table.addunique --framework
	local UnitGroupRolesAssigned = DetailsFramework.UnitGroupRolesAssigned --framework

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> constants

	local container_combatentes =	_detalhes.container_combatentes
	local atributo_damage =		_detalhes.atributo_damage
	local atributo_heal =			_detalhes.atributo_heal
	local atributo_energy =		_detalhes.atributo_energy
	local atributo_misc =			_detalhes.atributo_misc

	local container_damage =		_detalhes.container_type.CONTAINER_DAMAGE_CLASS
	local container_heal = 		_detalhes.container_type.CONTAINER_HEAL_CLASS
	local container_energy = 		_detalhes.container_type.CONTAINER_ENERGY_CLASS
	local container_misc = 		_detalhes.container_type.CONTAINER_MISC_CLASS

	local container_pets = {}

	--> flags
	local REACTION_HOSTILE	=	0x00000040
	local IS_GROUP_OBJECT 	= 	0x00000007
	local OBJECT_TYPE_PETGUARDIAN =	0x00003000
	local OBJECT_TYPE_PLAYER =	0x00000400


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> api functions

	function container_combatentes:GetActor (actorName)
		local index = self._NameIndexTable [actorName]
		if (index) then
			return self._ActorTable [index]
		end
	end

	function container_combatentes:GetSpellSource (spellid)
		local t = self._ActorTable
		--print ("getting the source", spellid, #t)
		for i = 1, #t do
			if (t[i].spells._ActorTable [spellid]) then
				return t[i].nome
			end
		end
	end

	function container_combatentes:GetAmount (actorName, key)
		key = key or "total"
		local index = self._NameIndexTable [actorName]
		if (index) then
			return self._ActorTable [index] [key] or 0
		else
			return 0
		end
	end

	function container_combatentes:GetTotal (key)
		local total = 0
		key = key or "total"
		for _, actor in _ipairs (self._ActorTable) do
			total = total + (actor [key] or 0)
		end

		return total
	end

	function container_combatentes:GetTotalOnRaid (key, combat)
		local total = 0
		key = key or "total"
		local roster = combat.raid_roster
		for _, actor in _ipairs (self._ActorTable) do
			if (roster [actor.nome]) then
				total = total + (actor [key] or 0)
			end
		end

		return total
	end

	function container_combatentes:ListActors()
		return _ipairs (self._ActorTable)
	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> internals

	--> build a new actor container
	function container_combatentes:NovoContainer (tipo_do_container, combat_table, combat_id)
		local _newContainer = {
			funcao_de_criacao = container_combatentes:FuncaoDeCriacao (tipo_do_container),

			tipo = tipo_do_container,

			_ActorTable = {},
			_NameIndexTable = {}
		}

		_setmetatable (_newContainer, container_combatentes)

		return _newContainer
	end

	--> try to get the actor class from name
	local function get_actor_class (novo_objeto, nome, flag, serial, self)
		--> get spec
		if (_detalhes.track_specs) then
			local have_cached = _detalhes.cached_specs [serial]
			if (have_cached) then
				novo_objeto.spec = have_cached
				--> check is didn't changed the spec:
				if (_detalhes.streamer_config.quick_detection) then
					--> validate the spec more times if on quick detection
					_detalhes:ScheduleTimer ("ReGuessSpec", 2, {novo_objeto, self})
					_detalhes:ScheduleTimer ("ReGuessSpec", 4, {novo_objeto, self})
					_detalhes:ScheduleTimer ("ReGuessSpec", 6, {novo_objeto, self})
				end
				_detalhes:ScheduleTimer ("ReGuessSpec", 15, {novo_objeto, self})
				--print (nome, "spec em cache:", have_cached)
			else
				if (_detalhes.streamer_config.quick_detection) then
					--> shoot detection early if in quick detection
					_detalhes:ScheduleTimer ("GuessSpec", 1, {novo_objeto, self, 1})
				else
					_detalhes:ScheduleTimer ("GuessSpec", 3, {novo_objeto, self, 1})
				end
			end
		end

		local _, engClass = _UnitClass (nome or "")

		if (engClass) then
			novo_objeto.classe = engClass
			return
		else
			if (flag) then
				--> conferir se o jogador � um player
				if (_bit_band (flag, OBJECT_TYPE_PLAYER) ~= 0) then
					novo_objeto.classe = "UNGROUPPLAYER"
					return
				elseif (_bit_band (flag, OBJECT_TYPE_PETGUARDIAN) ~= 0) then
					novo_objeto.classe = "PET"
					return
				end
			end

			novo_objeto.classe = "UNKNOW"
			return true
		end
	end

	--> read the actor flag
	local read_actor_flag = function (novo_objeto, dono_do_pet, serial, flag, nome)
		if (flag) then

			--> � um player
			if (_bit_band (flag, OBJECT_TYPE_PLAYER) ~= 0) then

				if (not _detalhes.ignore_nicktag) then
					novo_objeto.displayName = _detalhes:GetNickname (nome, false, true) --> serial, default, silent
				end
				if (not novo_objeto.displayName) then
					if (_detalhes.remove_realm_from_name) then

						novo_objeto.displayName = nome:gsub (("%-.*"), "")
					else
						novo_objeto.displayName = nome
					end
				end

				if (_detalhes.all_players_are_group) then
					novo_objeto.grupo = true
				end

				if ((_bit_band (flag, IS_GROUP_OBJECT) ~= 0 and novo_objeto.classe ~= "UNKNOW" and novo_objeto.classe ~= "UNGROUPPLAYER") or _detalhes:IsInCache (serial)) then
					novo_objeto.grupo = true
				else
					if (_detalhes.pvp_as_group and (_detalhes.tabela_vigente and _detalhes.tabela_vigente.is_pvp) and _detalhes.is_in_battleground) then
						novo_objeto.grupo = true
					end
				end

				if (_detalhes.is_in_arena) then

					local my_team_color = 1

					if (novo_objeto.grupo) then --> is ally
						novo_objeto.arena_ally = true
						novo_objeto.arena_team = my_team_color
					else --> is enemy
						novo_objeto.enemy = true
						novo_objeto.arena_enemy = true
						novo_objeto.arena_team = 1 - my_team_color
					end

					local arena_props = _detalhes.arena_table [nome]

					if (arena_props) then
						novo_objeto.role = arena_props.role

						if (arena_props.role == "NONE") then
							local role = UnitGroupRolesAssigned (nome)
							if (role ~= "NONE") then
								novo_objeto.role = role
							end
						end
					end

					novo_objeto.grupo = true
				end

			--> � um pet
			elseif (dono_do_pet) then
				novo_objeto.owner = dono_do_pet
				novo_objeto.ownerName = dono_do_pet.nome

				if (_IsInInstance() and _detalhes.remove_realm_from_name) then
					novo_objeto.displayName = nome:gsub (("%-.*"), ">")
				else
					novo_objeto.displayName = nome
				end

			else
				--> anything else that isn't a player or a pet
				novo_objeto.displayName = nome

			end

			--> check if is hostile
			if (_bit_band (flag, REACTION_HOSTILE) ~= 0) then

				if (_bit_band (flag, OBJECT_TYPE_PLAYER) == 0) then
					--> is hostile and isn't a player

					if (_bit_band (flag, OBJECT_TYPE_PETGUARDIAN) == 0) then
						--> isn't a pet or guardian
						novo_objeto.monster = true
					end

					if (serial and type (serial) == "string") then
						local npcID = _detalhes:GetNpcIdFromGuid (serial)
						if (npcID and not _detalhes.npcid_pool [npcID] and type (npcID) == "number") then
							_detalhes.npcid_pool [npcID] = nome
						end
					end

				end

			end
		end

	end

	local pet_blacklist = {}
	local pet_tooltip_frame = _G.DetailsPetOwnerFinder

	local find_pet_found_owner = function (ownerName, serial, nome, flag, self)
		local ownerGuid = _UnitGUID (ownerName)
		if (ownerGuid) then
			_detalhes.tabela_pets:Adicionar (serial, nome, flag, ownerGuid, ownerName, 0x00000417)
			local nome_dele, dono_nome, dono_serial, dono_flag = _detalhes.tabela_pets:PegaDono (serial, nome, flag)

			local dono_do_pet
			if (nome_dele and dono_nome) then
				nome = nome_dele
				dono_do_pet = self:PegarCombatente (dono_serial, dono_nome, dono_flag, true, nome)
			end

			return nome, dono_do_pet
		end
	end

	--> check pet owner name with correct declension for ruRU locale (from user 'denis-kam' on github)
	local find_name_declension = function (petTooltip, playerName)
		--> 2 - male, 3 - female
		for gender = 2, 3 do
			for declensionSet = 1, GetNumDeclensionSets(playerName, gender) do
				--> check genitive case of player name
				local genitive = DeclineName(playerName, gender, declensionSet)
				if petTooltip:find(genitive) then
					return true
				end
			end
		end

		return false
	end

	local find_pet_owner = function (serial, nome, flag, self)
		if (not _detalhes.tabela_vigente) then
			return
		end

		pet_tooltip_frame:SetOwner (WorldFrame, "ANCHOR_NONE")
		pet_tooltip_frame:SetHyperlink ("unit:" .. serial or "")

		local line1 = _G ["DetailsPetOwnerFinderTextLeft2"]
		local text1 = line1 and line1:GetText()
		if (text1 and text1 ~= "") then
			for playerName, _ in _pairs (_detalhes.tabela_vigente.raid_roster) do
				local pName = playerName
				playerName = playerName:gsub ("%-.*", "") --remove realm name

				--if the user client is in russian language
				--make an attempt to remove declensions from the character's name
				--this is equivalent to remove 's from the owner on enUS
				if (CONST_CLIENT_LANGUAGE == "ruRU") then
					if (find_name_declension (text1, playerName)) then
						return find_pet_found_owner (pName, serial, nome, flag, self)
					else
						if (text1:find (playerName)) then
							return find_pet_found_owner (pName, serial, nome, flag, self)
						end
					end
				else
					if (text1:find (playerName)) then
						return find_pet_found_owner (pName, serial, nome, flag, self)
					end
				end
			end
		end

		local line2 = _G ["DetailsPetOwnerFinderTextLeft3"]
		local text2 = line2 and line2:GetText()
		if (text2 and text2 ~= "") then
			for playerName, _ in _pairs (_detalhes.tabela_vigente.raid_roster) do
				local pName = playerName
				playerName = playerName:gsub ("%-.*", "") --remove realm name

				if (CONST_CLIENT_LANGUAGE == "ruRU") then
					if (find_name_declension (text2, playerName)) then
						return find_pet_found_owner (pName, serial, nome, flag, self)
					else
						if (text2:find (playerName)) then
							return find_pet_found_owner (pName, serial, nome, flag, self)
						end
					end
				else
					if (text2:find (playerName)) then
						return find_pet_found_owner (pName, serial, nome, flag, self)
					end
				end
			end
		end
	end

	function container_combatentes:PegarCombatente (serial, nome, flag, criar)
		-- print(nome)
		--[[statistics]]-- _detalhes.statistics.container_calls = _detalhes.statistics.container_calls + 1

		--> verifica se � um pet, se for confere se tem o nome do dono, se n�o tiver, precisa por
		local dono_do_pet
		serial = serial or "ns"
		nome = nome or UNKNOWN

		if (container_pets [serial]) then --> � um pet reconhecido
			--[[statistics]]-- _detalhes.statistics.container_pet_calls = _detalhes.statistics.container_pet_calls + 1
			local nome_dele, dono_nome, dono_serial, dono_flag = _detalhes.tabela_pets:PegaDono (serial, nome, flag)
			if (nome_dele and dono_nome) then
				nome = nome_dele
				dono_do_pet = self:PegarCombatente (dono_serial, dono_nome, dono_flag, true)
			end

		elseif (not pet_blacklist [serial]) then --> verifica se � um pet

			pet_blacklist [serial] = true

			--> try to find the owner
			if (flag and _bit_band (flag, OBJECT_TYPE_PETGUARDIAN) ~= 0) then

				--[[statistics]]-- _detalhes.statistics.container_unknow_pet = _detalhes.statistics.container_unknow_pet + 1
				local find_nome, find_owner = find_pet_owner (serial, nome, flag, self)
				if (find_nome and find_owner) then
					nome, dono_do_pet = find_nome, find_owner
				end
			end
		end

		--> pega o index no mapa
		local index = self._NameIndexTable [nome]
		--> retorna o actor
		if (index) then
			return self._ActorTable [index], dono_do_pet, nome

		--> n�o achou, criar
		elseif (criar) then

			local novo_objeto = self.funcao_de_criacao (_, serial, nome)
			novo_objeto.nome = nome
			novo_objeto.flag_original = flag
			novo_objeto.serial = serial

			--novo_objeto.grupo = true

			--> seta a classe default para desconhecido, assim nenhum objeto fica com classe nil
			novo_objeto.classe = "UNKNOW"

			--8/11 00:57:49.096  SPELL_DAMAGE,
			--Creature-0-2084-1220-24968-110715-00002BF677,"Archmage Modera",0x2111,0x0,
			--Creature-0-2084-1220-24968-94688-00002BF6A7,"Diseased Grub",0x10a48,0x0,
			--220128,"Frost Nova",0x10,Creature-0-2084-1220-24968-94688-00002BF6A7,0000000000000000,63802,311780,0,0,1,0,0,0,4319.26,4710.75,110,10271,-1,16,0,0,0,nil,nil,nil

					-- tipo do container
				------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

			if (self.tipo == container_damage) then --> CONTAINER DAMAGE

				get_actor_class (novo_objeto, nome, flag, serial, self)

				read_actor_flag (novo_objeto, dono_do_pet, serial, flag, nome)

				if (dono_do_pet) then
					AddUnique (dono_do_pet.pets, nome)
				end

				if (self.shadow) then
					if (novo_objeto.grupo and _detalhes.in_combat) then
						_detalhes.cache_damage_group [#_detalhes.cache_damage_group+1] = novo_objeto
					end
				end

				if (novo_objeto.classe == "UNGROUPPLAYER") then --> is a player
					if (_bit_band (flag, REACTION_HOSTILE ) ~= 0) then --> is hostile
						novo_objeto.enemy = true
					end

					--> try to guess his class
					if (self.shadow) then --> n�o executar 2x
						_detalhes:ScheduleTimer ("GuessClass", 1, {novo_objeto, self, 1})
					end
				end

			elseif (self.tipo == container_heal) then --> CONTAINER HEALING

				get_actor_class (novo_objeto, nome, flag, serial, self)
				read_actor_flag (novo_objeto, dono_do_pet, serial, flag, nome)

				if (dono_do_pet) then
					AddUnique (dono_do_pet.pets, nome)
				end

				if (self.shadow) then
					if (novo_objeto.grupo and _detalhes.in_combat) then
						_detalhes.cache_healing_group [#_detalhes.cache_healing_group+1] = novo_objeto
					end
				end

				if (novo_objeto.classe == "UNGROUPPLAYER") then --> is a player
					if (_bit_band (flag, REACTION_HOSTILE ) ~= 0) then --> is hostile
						novo_objeto.enemy = true --print (nome.." EH UM INIMIGO -> " .. engRace)
					end

					--> try to guess his class
					if (self.shadow) then --> n�o executar 2x
						_detalhes:ScheduleTimer ("GuessClass", 1, {novo_objeto, self, 1})
					end
				end


			elseif (self.tipo == container_energy) then --> CONTAINER ENERGY

				get_actor_class (novo_objeto, nome, flag, serial, self)
				read_actor_flag (novo_objeto, dono_do_pet, serial, flag, nome)

				if (dono_do_pet) then
					AddUnique (dono_do_pet.pets, nome)
				end

				if (novo_objeto.classe == "UNGROUPPLAYER") then --> is a player
					if (_bit_band (flag, REACTION_HOSTILE ) ~= 0) then --> is hostile
						novo_objeto.enemy = true
					end

					--> try to guess his class
					if (self.shadow) then --> n�o executar 2x
						_detalhes:ScheduleTimer ("GuessClass", 1, {novo_objeto, self, 1})
					end
				end

			elseif (self.tipo == container_misc) then --> CONTAINER MISC

				get_actor_class (novo_objeto, nome, flag, serial, self)
				read_actor_flag (novo_objeto, dono_do_pet, serial, flag, nome)

				if (dono_do_pet) then
					AddUnique (dono_do_pet.pets, nome)
				end

				if (novo_objeto.classe == "UNGROUPPLAYER") then --> is a player
					if (_bit_band (flag, REACTION_HOSTILE ) ~= 0) then --> is hostile
						novo_objeto.enemy = true
					end

					--> try to guess his class
					if (self.shadow) then --> n�o executar 2x
						_detalhes:ScheduleTimer ("GuessClass", 1, {novo_objeto, self, 1})
					end
				end

			end

			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- grava o objeto no mapa do container
			local size = #self._ActorTable+1
			-- print(size,665)
			self._ActorTable [size] = novo_objeto --> grava na tabela de indexes
			self._NameIndexTable [nome] = size --> grava no hash map o index deste jogador

			if (_detalhes.is_in_battleground or _detalhes.is_in_arena) then
				novo_objeto.pvp = true
			end

			if (_detalhes.debug) then
				if (_detalhes.debug_chr and nome:find (_detalhes.debug_chr) and self.tipo == 1) then
					local logLine = ""
					local when = "[" .. date ("%H:%M:%S") .. format (".%4f", GetTime()-floor (GetTime())) .. "]"
					local log = "actor created - class: " .. (novo_objeto.classe or "noclass")
					local from = debugstack (2, 1, 0)
					logLine = logLine .. when .. " " .. log .. " " .. from .. "\n"

					_detalhes_global.debug_chr_log = _detalhes_global.debug_chr_log .. logLine
				end
			end
			-- print(no)
			return novo_objeto, dono_do_pet, nome
		else
			return nil, nil, nil
		end
	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> core

	function _detalhes:UpdateContainerCombatentes()
		container_pets = _detalhes.tabela_pets.pets
		_detalhes:UpdatePetsOnParser()
	end
	function _detalhes:ClearCCPetsBlackList()
		table.wipe (pet_blacklist)
	end

	function container_combatentes:GetShadowOf (actor, set_time)
		local shadow = self._ActorTable [self._NameIndexTable [actor.nome]]
		if (not shadow) then
			shadow = self:PegarCombatente (actor.serial, actor.nome, actor.flag_original, true)
			shadow.classe = actor.classe
			shadow.spec = actor.spec
			shadow.grupo = actor.grupo
			shadow.pvp = actor.pvp
			shadow.boss = actor.boss
			shadow.boss_fight_component = actor.boss_fight_component
			shadow.fight_component = actor.fight_component
			if (set_time) then
				shadow.start_time = time() - 3
				shadow.end_time = time()
			end
		end
		return shadow
	end

	function container_combatentes:FuncaoDeCriacao (tipo)
		if (tipo == container_damage) then
			return atributo_damage.NovaTabela

		elseif (tipo == container_heal) then
			return atributo_heal.NovaTabela

		elseif (tipo == container_energy) then
			return atributo_energy.NovaTabela

		elseif (tipo == container_misc) then
			return atributo_misc.NovaTabela

		end
	end

	--> chama a fun��o para ser executada em todos os atores

	local bykey
	local sort = function (t1, t2)
		return (t1 [bykey] or 0) > (t2 [bykey] or 0)
	end

	function container_combatentes:SortByKey (key)
		assert (type (key) == "string", "Container:SortByKey() expects a keyname on parameter 1.")
		bykey = key
		_table_sort (self._ActorTable, sort)
		self:remapear()
	end

	function container_combatentes:Remap()
		return self:remapear()
	end

	function container_combatentes:remapear()
		local mapa = self._NameIndexTable
		local conteudo = self._ActorTable
		for i = 1, #conteudo do
			mapa [conteudo[i].nome] = i
		end
	end

	function _detalhes.refresh:r_container_combatentes (container, shadow)
		--> reconstr�i meta e indexes
			_setmetatable (container, _detalhes.container_combatentes)
			container.__index = _detalhes.container_combatentes
			container.funcao_de_criacao = container_combatentes:FuncaoDeCriacao (container.tipo)

		--> repara mapa
			local mapa = {}
			for i = 1, #container._ActorTable do
				mapa [container._ActorTable[i].nome] = i
			end
			container._NameIndexTable = mapa

		--> seta a shadow
			container.shadow = shadow
	end

	function _detalhes.clear:c_container_combatentes (container)
		container.__index = nil
		container.shadow = nil
		--container._NameIndexTable = nil
		container.need_refresh = nil
		container.funcao_de_criacao = nil
	end
	function _detalhes.clear:c_container_combatentes_index (container)
		container._NameIndexTable = nil
	end
