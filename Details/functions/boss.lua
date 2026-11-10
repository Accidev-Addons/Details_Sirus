do
	local _detalhes = _detalhes

	local _math_ceil = math.ceil --> lua local
	local _pairs = pairs --> lua local
	local _unpack = unpack --> lua local

	local _GetCurrentMapAreaID = GetCurrentMapAreaID --api local

	_detalhes.EncounterInformation = {}

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> details api functions

	--> return if the player is inside a raid supported by details
	function _detalhes:IsInInstance()
		local zoneMapID = _GetCurrentMapAreaID()
		if _detalhes.EncounterInformation[zoneMapID] then
			return true
		else
			return false
		end
	end

	--> return the full table with all data for the instance
	function _detalhes:GetRaidInfoFromEncounterID(encounterID, encounterEJID)
		for id, raidTable in _pairs(_detalhes.EncounterInformation) do
			--combatlog encounter
			if encounterID then
				local ids = raidTable.encounter_ids2
				if ids then
					if ids[encounterID] then
						return raidTable
					end
				end
			end

			--encounter journal
			if encounterEJID then
				local ejids = raidTable.encounter_ids
				if ejids then
					if ejids[encounterEJID] then
						return raidTable
					end
				end
			end
		end
	end

	--> return the ids of trash mobs in the instance
	function _detalhes:GetInstanceTrashInfo(mapid)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].trash_ids
	end

	function _detalhes:GetInstanceIdFromEncounterId(encounterid)
		for id, instanceTable in _pairs(_detalhes.EncounterInformation) do
			--combatlog encounter id
			local ids = instanceTable.encounter_ids2
			if ids then
				if ids[encounterid] then
					return id
				end
			end
		end
	end

	--> return the boss table using a encounter id
	function _detalhes:GetBossEncounterDetailsFromEncounterId(mapid, encounterid)
		if not mapid then
			local bossIndex, instance
			for id, instanceTable in _pairs(_detalhes.EncounterInformation) do
				local ids = instanceTable.encounter_ids2
				if ids then
					bossIndex = ids[encounterid]
					if bossIndex then
						instance = instanceTable
						break
					end
				end
			end

			if instance then
				local bosses = instance.encounters
				if bosses then
					return bosses[bossIndex], instance
				end
			end

			return
		end

		local raid = _detalhes.EncounterInformation[mapid]
		local bossindex = raid and raid.encounter_ids2 and raid.encounter_ids2[encounterid]
		if bossindex then
			return raid.encounters[bossindex], bossindex
		end
	end

	--> return the table which contain information about the start of a encounter
	function _detalhes:GetEncounterStartInfo(mapid, encounterid)
		local bossindex = _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounter_ids and _detalhes.EncounterInformation[mapid].encounter_ids[encounterid]
		if bossindex then
			return _detalhes.EncounterInformation[mapid].encounters[bossindex] and _detalhes.EncounterInformation[mapid].encounters[bossindex].encounter_start
		end
	end

	--> return the table which contain information about the end of a encounter
	function _detalhes:GetEncounterEndInfo(mapid, encounterid)
		local bossindex = _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounter_ids and _detalhes.EncounterInformation[mapid].encounter_ids[encounterid]
		if bossindex then
			return _detalhes.EncounterInformation[mapid].encounters[bossindex] and _detalhes.EncounterInformation[mapid].encounters[bossindex].encounter_end
		end
	end

	--> return the function for the boss
	function _detalhes:GetEncounterEnd(mapid, bossindex)
		local t = _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounters[bossindex]
		if t then
			local _end = t.combat_end
			if _end then
				return _unpack(_end)
			end
		end
		return
	end

	--> generic boss find function
	function _detalhes:GetRaidBossFindFunction(mapid)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].find_boss_encounter
	end

	--> return if the boss need sync
	function _detalhes:GetEncounterEqualize(mapid, bossindex)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounters[bossindex] and _detalhes.EncounterInformation[mapid].encounters[bossindex].equalize
	end

	--> return the function for the boss
	function _detalhes:GetBossFunction(mapid, bossindex)
		local func = _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounters[bossindex] and _detalhes.EncounterInformation[mapid].encounters[bossindex].func
		if func then
			return func, _detalhes.EncounterInformation[mapid].encounters[bossindex].funcType
		end
		return
	end

	--> return the boss table with information about name, adds, spells, etc
	function _detalhes:GetBossDetails(mapid, bossindex)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounters[bossindex]
	end

	--> return a table with all boss ids from a raid instance
	function _detalhes:GetBossIds(mapid)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].boss_ids
	end

	--> return a table with all encounter names present in raid instance
	function _detalhes:GetBossNames(mapid)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].boss_names
	end

	--> return the encounter name
	function _detalhes:GetBossName(mapid, bossindex)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].boss_names[bossindex]
	end
	function _detalhes:GetBossEncounter(mapid, bossindex)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounter_ids2[bossindex]
	end

	--> same thing as GetBossDetails, just a alias
	function _detalhes:GetBossEncounterDetails(mapid, bossindex)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounters[bossindex]
	end

	--> return the wallpaper for the raid instance
	function _detalhes:GetRaidBackground(mapid)
		local bosstables = _detalhes.EncounterInformation[mapid]
		if bosstables then
			local bg = bosstables.backgroundFile
			if bg then
				return bg.file, _unpack(bg.coords)
			end
		end
	end

	--> return the icon for the raid instance
	function _detalhes:GetRaidIcon(mapid)
		return _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].icon
	end

	function _detalhes:GetBossIndex(mapid, encounterCLID, encounterName)
		local raidInfo = _detalhes.EncounterInformation[mapid]
		if raidInfo then
			local index = raidInfo.encounter_ids2[encounterCLID]
			if not index then
				for i = 1, #raidInfo.boss_names do
					if raidInfo.boss_names[i] == encounterName then
						index = i
						break
					end
				end
			end
			return index
		end
	end

	--> return the boss icon
	function _detalhes:GetBossIcon(mapid, bossindex)
		local raid = _detalhes.EncounterInformation[mapid]
		if raid and not raid.icons then
			local encounter = raid.encounters[bossindex]
			return 0, 1, 0, 1, encounter and encounter.portrait
		end
		if raid then
			local line = _math_ceil(bossindex / 4)
			local x = (bossindex -((line - 1) * 4)) / 4
			return x - 0.25, x, 0.25 * (line - 1), 0.25 * line, _detalhes.EncounterInformation[mapid].icons
		end
	end

	--> return the boss portrit
	function _detalhes:GetBossPortrait(mapid, bossindex)
		if mapid and bossindex then
			local haveIcon = _detalhes.EncounterInformation[mapid] and _detalhes.EncounterInformation[mapid].encounters[bossindex] and _detalhes.EncounterInformation[mapid].encounters[bossindex].portrait
			if haveIcon then
				return haveIcon
			end
		end

		return nil
	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> core

	function _detalhes:InstallEncounter(InstanceTable)
		_detalhes.EncounterInformation[InstanceTable.id] = InstanceTable
		return true
	end
end