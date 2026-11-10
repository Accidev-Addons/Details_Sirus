
--[=[
Details API 2.0
This is a high level API for Details! Damage Meter



--]=]

--local helpers
local getCombatObject = function (segmentNumber)
	local combatObject

	--select which segment to use, use low level variables for performance
	if (segmentNumber == -1) then
		combatObject = _detalhes.tabela_overall
	elseif (segmentNumber == 0) then
		combatObject = _detalhes.tabela_vigente
	else
		combatObject = _detalhes.tabela_historico.tabelas [segmentNumber]
	end

	return combatObject
end

local getActorObjectFromCombat = function (combatObject, containerID, actorName)
	local index = combatObject [containerID]._NameIndexTable [actorName]
	return combatObject [containerID]._ActorTable [index]
end

local getUnitName = function (unitId)
	local unitName, serverName = UnitName (unitId)
	if (unitName) then
		if (serverName and serverName ~= "") then
			return unitName .. "-" .. serverName
		else
			return unitName
		end
	else
		return unitId
	end
end

--return the spell object and the spellId
local getSpellObject = function (playerObject, spellId, isLiteral)
	local parameterType = type (spellId)

	if (parameterType == "number" and isLiteral) then
		--is the id of a spell and literal, directly get the spell object
		return playerObject.spells._ActorTable [spellId], spellId

	else
		local passedSpellName
		if (parameterType == "string") then
			--passed a spell name, make the spell be in lower case
			passedSpellName = spellId:lower()

		elseif (parameterType == "number") then
			--passed a number but with literal off, transform the spellId into a spell name
			local spellName = GetSpellInfo (spellId)
			if (spellName) then
				passedSpellName = spellName:lower()
			end
		end

		if (passedSpellName) then
			for thisSpellId, spellObject in pairs (playerObject.spells._ActorTable) do
				local spellName = Details.GetSpellInfo (thisSpellId)
				if (spellName) then
					if (spellName:lower() == passedSpellName) then
						return spellObject, thisSpellId
					end
				end
			end
		end
	end
end

local getCastedAmount = function (combatObject, unitName, spellId, spellName)
	local miscPlayerObject = getActorObjectFromCombat (combatObject, 4, unitName)
	local spellCast = miscPlayerObject and miscPlayerObject.spell_cast
	if (not spellCast) then
		return 0
	end
	if (spellCast [spellId]) then
		return spellCast [spellId]
	end
	for castedSpellId, castedAmount in pairs (spellCast) do
		if (GetSpellInfo (castedSpellId) == spellName) then
			return castedAmount
		end
	end
	return 0
end

--api
Details.API_Description = {
	addon = "Details! Damage Meter",
	namespaces = {
		{
			name = "Details",
			order = 1,
			api = {},
		}
	},
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> ~segments

--[=[
	Details.SegmentInfo (segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "SegmentInfo",
	desc = "Return a table containing information about the segment.",
	parameters = {
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "segmentInfo",
			type = "table",
			desc = "Table containing the following members: ",
		}
	},
	type = 0, --misc
}

function Details.SegmentInfo (segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	local segmentInfo = {

	}

	if (not combatObject) then
		return segmentInfo
	end



	return segmentInfo
end

--[=[
	Details.SegmentElapsedTime (segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "SegmentElapsedTime",
	desc = "Return the total elapsed time of a segment.",
	parameters = {
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "segmentElapsedTime",
			type = "number",
			desc = "Number representing the elapsed time of a combat.",
		}
	},
	type = 0, --misc
}

function Details.SegmentElapsedTime (segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	return combatObject:GetCombatTime()
end

--[=[
	Details.SegmentDamagingUnits (segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "SegmentDamagingUnits",
	desc = "Return a numeric (ipairs) table with name of units that inflicted damage on the segment.",
	parameters = {
		{
			name = "includePlayerUnits",
			type = "boolean",
			default = "true",
			desc = "Include names of player units, e.g. name of players in your dungeon or raid group.",
		},
		{
			name = "includeEnemyUnits",
			type = "boolean",
			default = "false",
			desc = "Include names of enemy units, e.g. name of a boss and their adds.",
		},
		{
			name = "includeFriendlyPetUnits",
			type = "boolean",
			default = "false",
			desc = "Include names of player pets.",
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitNames",
			type = "table",
			desc = "A table with unit names.",
		}
	},
	type = 1, --damage
}

local segmentUnits = function (containerID, includePlayerUnits, includeEnemyUnits, includeFriendlyPetUnits, segment)
	segment = segment or 0
	if (type (includePlayerUnits) ~= "boolean") then
		includePlayerUnits = true
	end

	local combatObject = getCombatObject (segment)

	local units = {}
	local nextIndex = 1

	if (not combatObject) then
		return units
	end

	local damageContainer = combatObject:GetContainer (containerID)
	for i = 1, #damageContainer._ActorTable do
		local playerObject = damageContainer._ActorTable [i]

		if (includePlayerUnits and playerObject.grupo) then
			units [nextIndex] = playerObject:GetName()
			nextIndex = nextIndex + 1

		elseif (includeEnemyUnits and playerObject:IsEnemy()) then
			units [nextIndex] = playerObject:GetName()
			nextIndex = nextIndex + 1

		elseif (includeFriendlyPetUnits and playerObject:IsPetOrGuardian()) then
			units [nextIndex] = playerObject:GetName()
			nextIndex = nextIndex + 1
		end
	end

	return units
end

function Details.SegmentDamagingUnits (includePlayerUnits, includeEnemyUnits, includeFriendlyPetUnits, segment)
	return segmentUnits (DETAILS_ATTRIBUTE_DAMAGE, includePlayerUnits, includeEnemyUnits, includeFriendlyPetUnits, segment)
end


--[=[
	Details.SegmentHealingUnits (segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "SegmentHealingUnits",
	desc = "Return a numeric (ipairs) table with name of units that inflicted healing on the segment.",
	parameters = {
		{
			name = "includePlayerUnits",
			type = "boolean",
			default = "true",
			desc = "Include names of player units, e.g. name of players in your dungeon or raid group.",
		},
		{
			name = "includeEnemyUnits",
			type = "boolean",
			default = "false",
			desc = "Include names of enemy units, e.g. name of a boss and their adds.",
		},
		{
			name = "includeFriendlyPetUnits",
			type = "boolean",
			default = "false",
			desc = "Include names of player pets.",
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitNames",
			type = "table",
			desc = "A table with unit names.",
		}
	},
	type = 2, --healing
}

function Details.SegmentHealingUnits (includePlayerUnits, includeEnemyUnits, includeFriendlyPetUnits, segment)
	return segmentUnits (DETAILS_ATTRIBUTE_HEAL, includePlayerUnits, includeEnemyUnits, includeFriendlyPetUnits, segment)
end

--[=[
	Details.SegmentTotalDamage (segment)
--=]=]

Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "SegmentTotalDamage",
	desc = "Query the total damage done in the segment and only by players in the group.",
	parameters = {
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "totalDamage",
			type = "number",
			desc = "Amount of damage done by players in the group.",
		}
	},
	type = 1, --damage
}

function Details.SegmentTotalDamage (segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	return floor (combatObject.totals_grupo [1])
end


--[=[
	Details.SegmentTotalHealing (segment)
--=]=]

Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "SegmentTotalHealing",
	desc = "Query the total healing done in the segment and only by players in the group.",
	parameters = {
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "totalHealing",
			type = "number",
			desc = "Amount of healing done by players in the group.",
		}
	},
	type = 2, --healing
}

function Details.SegmentTotalHealing (segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	return floor (combatObject.totals_grupo [2])
end

--[=[
	Details.SegmentPhases (segment)
--=]=]

Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "SegmentPhases",
	desc = "Return a numeric (ipairs) table with phase numbers available on the segment.",
	parameters = {
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "phaseNumbers",
			type = "table",
			desc = "A table containing numbers representing phases of the encounter, these numbers can used with UnitDamageByPhase().",
		}
	},
	type = 0, --misc
}

function Details.SegmentPhases (segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	local phases = {}

	if (not combatObject) then
		return phases
	end

	local phaseData = combatObject.PhaseData

	for phaseChangeId, phaseTable in ipairs (phaseData) do
		local phaseNumber = phaseTable [1]
		DetailsFramework.table.addunique (phases, phaseNumber)
	end

	return phases
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> unit ~information
--[=[
	Details.UnitInfo (unitId, segment)
--=]=]

Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitInfo",
	desc = "Query basic information about the unit, like class and spec.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitInfo",
			type = "table",
			desc = "A table with information about the unit, the table contains: .class, .spec, .guid, .role, .isPlayer, .isEnemy, .isPet, .isArenaFriendly, .isArenaEnemy, .arenaTeam.",
		}
	},
	type = 0, --misc
}


function Details.UnitInfo (unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	local unitInfo = {
		class = "UNKNOW", --old typo in details
		spec = 0,
		guid = "",
		role = "NONE",
		isPlayer = false,
		isEnemy = false,
		isPet = false,
		isArenaFriendly = false,
		isArenaEnemy = false,
		arenaTeam = false,
	}

	if (not combatObject) then
		return unitInfo
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, 1, unitName)
	if (not playerObject) then
		return unitInfo
	end

	unitInfo.class = playerObject.classe or "UNKNOW"
	unitInfo.spec = playerObject.spec or 0
	unitInfo.guid = playerObject.serial or ""
	unitInfo.role = playerObject.role or "NONE"
	unitInfo.isPlayer = playerObject:IsPlayer()
	unitInfo.isEnemy = playerObject:IsEnemy()
	unitInfo.isPet = playerObject:IsPetOrGuardian()
	unitInfo.isArenaFriendly = playerObject.arena_ally or false
	unitInfo.isArenaEnemy = playerObject.arena_enemy or false
	unitInfo.arenaTeam = playerObject.arena_team or false

	return unitInfo
end

--[=[
	Details.UnitTexture (unitId, segment)
--=]=]

Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitTexture",
	desc = "Query the icon and texcoords for the class and spec icon.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "textureInfo",
			type = "table",
			desc = "A table containing texture paths for class and spec icons plus the texture coordinates (texture:SetTexCoord), the table contains: .classTexture, .classLeft, .classRight, .classTop, .classBottom, .specTexture, .specLeft, .specRight, .specTop, .specBottom.",
		}
	},
	type = 0, --misc
}


function Details.UnitTexture (unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	local textureInfo = {
		classTexture = [[Interface\LFGFRAME\LFGROLE_BW]],
		classLeft = 0.25,
		classRight = 0.5,
		classTop = 0,
		classBottom = 1,
		specTexture = [[Interface\LFGFRAME\LFGROLE_BW]],
		specLeft = 0.25,
		specRight = 0.5,
		specTop = 0,
		specBottom = 1,
	}

	if (not combatObject) then
		return textureInfo
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, 1, unitName)
	if (not playerObject) then
		return textureInfo
	end

	local texture, left, right, top, bottom = playerObject:GetClassIcon()
	textureInfo.classTexture = texture
	textureInfo.classLeft = left
	textureInfo.classRight = right
	textureInfo.classTop = top
	textureInfo.classBottom = bottom

	local texture, left, right, top, bottom = Details:GetSpecIcon (playerObject.spec)
	textureInfo.specTexture = texture
	textureInfo.specLeft = left
	textureInfo.specRight = right
	textureInfo.specTop = top
	textureInfo.specBottom = bottom

	return textureInfo
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> ~damage

--[=[
	Details.UnitDamage (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamage",
	desc = "Query the damage of a unit.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitDamage",
			type = "number",
			desc = "Number representing the unit damage.",
		}
	},
	type = 1, --damage
}

local unitTotal = function (containerID, unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, containerID, unitName)
	if (not playerObject) then
		return 0
	end

	return floor (playerObject.total or 0)
end

function Details.UnitDamage (unitId, segment)
	return unitTotal (1, unitId, segment)
end


--[=[
	Details.UnitDamageByPhase (unitId, phaseNumber, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageByPhase",
	desc = "Query the damage of a unit but only for a specific phase of a boss encounter.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "phaseNumber",
			type = "number",
			desc = "The phase number of an encounter. Some encounters has transition phases considered 'phase 1.5'. You may query SegmentPhases() to know which phases the encounter has.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitDamage",
			type = "number",
			desc = "Number representing the unit damage on the encounter phase.",
		}
	},
	type = 1, --damage
}

function Details.UnitDamageByPhase (unitId, phaseNumber, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	if (not phaseNumber) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local damagePhaseData = combatObject.PhaseData.damage [phaseNumber]
	if (not damagePhaseData) then
		return 0
	end

	local phaseDamage = damagePhaseData [unitName] or 0
	return floor (phaseDamage)
end

--[=[
	Details.UnitDamageInfo (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageInfo",
	desc = "Return a table with damage information.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "damageInfo",
			type = "table",
			desc = "Table containing damage information, keys are: .total, .totalWithoutPet, .damageAbsorbed, .damageTaken, .friendlyFire and .activityTime",
		}
	},
	type = 1, --damage
}

function Details.UnitDamageInfo (unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local damageInfo = {
		total = 0,
		totalWithoutPet = 0,
		damageAbsorbed = 0,
		damageTaken = 0,
		friendlyFire = 0,
		activityTime = 0,
	}

	local playerObject = getActorObjectFromCombat (combatObject, 1, unitName)
	if (not playerObject) then
		return damageInfo
	end

	damageInfo.total = floor (playerObject.total)
	damageInfo.totalWithoutPet = floor (playerObject.total_without_pet)
	damageInfo.damageAbsorbed = floor (playerObject.totalabsorbed)
	damageInfo.damageTaken = floor (playerObject.damage_taken)
	damageInfo.friendlyFire = playerObject.friendlyfire_total
	damageInfo.activityTime = playerObject:Tempo()

	return damageInfo
end




--[=[
	Details.UnitDamageBySpell (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageBySpell",
	desc = "Query the total damage done of a spell casted by the unit.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query the damage done. Accept spell names.",
			required = true,
		},
		{
			name = "isLiteral",
			type = "boolean",
			default = "true",
			desc = "Search for the spell without transforming the spellId into a spell name before the search.",
		},
		{
			name = "segment",
			default = "0",
			type = "number",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitSpellDamage",
			type = "number",
			desc = "Number representing the spell damage done.",
		}
	},
	type = 1, --damage
}

local unitBySpell = function (containerID, unitId, spellId, isLiteral, segment)
	if (type (isLiteral) ~= "boolean") then
		isLiteral = true
	end
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, containerID, unitName)
	if (not playerObject) then
		return 0
	end

	local spellObject, spellId = getSpellObject (playerObject, spellId, isLiteral)

	if (spellObject) then
		return spellObject.total
	else
		return 0
	end
end

function Details.UnitDamageBySpell (unitId, spellId, isLiteral, segment)
	return unitBySpell (1, unitId, spellId, isLiteral, segment)
end


--[=[
	Details.UnitDamageSpellInfo (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageSpellInfo",
	desc = "Return a table with the spell damage information.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query its damage information. Accept spell names.",
			required = true,
		},
		{
			name = "isLiteral",
			type = "boolean",
			default = "true",
			desc = "Search for the spell without transforming the spellId into a spell name before the search.",
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "spellDamageInfo",
			type = "table",
			desc = "Table containing damage information, keys are: '.total', '.spellId', '.count', '.name', '.casted', '.regularMin', '.regularMax', '.regularHits', '.regularDamage', '.criticalMin', '.criticalMax', '.criticalHits', '.criticalDamage'",
		}
	},
	type = 1, --damage
}

function Details.UnitDamageSpellInfo (unitId, spellId, isLiteral, segment)
	if (type (isLiteral) ~= "boolean") then
		isLiteral = true
	end
	segment = segment or 0

	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local spellInfo = {
		total = 0,
		spellId = 0,
		count = 0,
		name = "",
		casted = 0,
		regularMin = 0,
		regularMax = 0,
		regularHits = 0,
		regularDamage = 0,
		criticalMin = 0,
		criticalMax = 0,
		criticalHits = 0,
		criticalDamage = 0,
	}

	local playerObject = getActorObjectFromCombat (combatObject, 1, unitName)
	if (not playerObject) then
		return spellInfo
	end

	local spellObject, spellId = getSpellObject (playerObject, spellId, isLiteral)
	if (not spellObject) then
		return spellInfo
	end

	local spellName = GetSpellInfo (spellId)
	spellInfo.casted = getCastedAmount (combatObject, unitName, spellId, spellName)

	spellInfo.total = spellObject.total
	spellInfo.count = spellObject.counter
	spellInfo.spellId = spellId
	spellInfo.name = spellName
	spellInfo.regularMin = spellObject.n_min
	spellInfo.regularMax = spellObject.n_max
	spellInfo.regularHits = spellObject.n_amt
	spellInfo.regularDamage = spellObject.n_dmg
	spellInfo.criticalMin = spellObject.c_min
	spellInfo.criticalMax = spellObject.c_max
	spellInfo.criticalHits = spellObject.c_amt
	spellInfo.criticalDamage = spellObject.c_dmg

	return spellInfo
end

--[=[
	Details.UnitDamageSpellOnUnit (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageSpellOnUnit",
	desc = "Query the damage done of a spell into a specific target.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query its damage to an unit. Accept spell names.",
			required = true,
		},
		{
			name = "targetUnitId",
			type = "string",
			desc = "Name or ID of an unit, example: 'Thrall', 'Jaina', 'player', 'target', 'raid5'.",
			required = true,
		},
		{
			name = "isLiteral",
			type = "boolean",
			default = "true",
			desc = "Search for the spell without transforming the spellId into a spell name before the search.",
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitDamageSpellOnUnit",
			type = "number",
			desc = "Damage done by the spell into the target.",
		}
	},
	type = 1, --damage
}

local unitSpellOnUnit = function (containerID, unitId, spellId, targetUnitId, isLiteral, segment)
	if (type (isLiteral) ~= "boolean") then
		isLiteral = true
	end
	segment = segment or 0

	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)
	local playerObject = getActorObjectFromCombat (combatObject, containerID, unitName)
	if (not playerObject) then
		return 0
	end

	local spellObject, spellId = getSpellObject (playerObject, spellId, isLiteral)
	if (spellObject) then
		local targetName = getUnitName (targetUnitId)
		return spellObject.targets [targetName] or 0
	else
		return 0
	end
end

function Details.UnitDamageSpellOnUnit (unitId, spellId, targetUnitId, isLiteral, segment)
	return unitSpellOnUnit (1, unitId, spellId, targetUnitId, isLiteral, segment)
end

--[=[
	Details.UnitDamageTaken (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageTaken",
	desc = "Query the unit damage taken.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitDamageTaken",
			type = "number",
			desc = "Number representing the damage taken by the unit.",
		}
	},
	type = 1, --damage
}

function Details.UnitDamageTaken (unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, 1, unitName)
	if (not playerObject) then
		return 0
	end

	return floor (playerObject.damage_taken)
end

--[=[
	Details.UnitDamageOnUnit (unitId, targetUnitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageOnUnit",
	desc = "Query the unit damage done on another unit.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "targetUnitId",
			type = "string",
			desc = "Name or ID of an unit, example: 'Thrall', 'Jaina', 'player', 'target', 'raid5'.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitDamageOnUnit",
			type = "number",
			desc = "Number representing the damage done by the unit on the target unit.",
		}
	},
	type = 1, --damage
}

local unitOnUnit = function (containerID, unitId, targetUnitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, containerID, unitName)
	if (not playerObject) then
		return 0
	end

	local targetName = getUnitName (targetUnitId)
	return playerObject.targets [targetName] or 0
end

function Details.UnitDamageOnUnit (unitId, targetUnitId, segment)
	return unitOnUnit (1, unitId, targetUnitId, segment)
end

--[=[
	Details.UnitDamageTakenFromSpell (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamageTakenFromSpell",
	desc = "Query the unit damage taken from a spell.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query its damage to an unit. Accept spell names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitDamageTakenFromSpell",
			type = "number",
			desc = "Number representing the damage taken by the unit from a spell.",
		}
	},
	type = 1, --damage
}

local unitTakenFromSpell = function (containerID, unitId, spellId, isLiteral, segment)
	segment = segment or 0
	if (type (isLiteral) ~= "boolean") then
		isLiteral = true
	end

	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)
	local damageContainer = combatObject:GetContainer (containerID)

	local totalDamageTaken = 0
	if (isLiteral and type (spellId) == "number") then
		for i = 1, #damageContainer._ActorTable do
			for thisSpellId, spellObject in pairs (damageContainer._ActorTable [i].spells._ActorTable) do
				if (thisSpellId == spellId) then
					totalDamageTaken = totalDamageTaken + (spellObject.targets [unitName] or 0)
				end
			end
		end
	else
		local spellName = GetSpellInfo (spellId) or spellId
		local spell_name_cache = {}
		for i = 1, #damageContainer._ActorTable do
			for thisSpellId, spellObject in pairs (damageContainer._ActorTable [i].spells._ActorTable) do
				local thisSpellName = spell_name_cache[thisSpellId]
				if thisSpellName == nil then
					thisSpellName = GetSpellInfo (thisSpellId)
					spell_name_cache[thisSpellId] = thisSpellName or false
				end
				if (thisSpellName == spellName) then
					totalDamageTaken = totalDamageTaken + (spellObject.targets [unitName] or 0)
				end
			end
		end
	end

	return totalDamageTaken
end

function Details.UnitDamageTakenFromSpell (unitId, spellId, isLiteral, segment)
	return unitTakenFromSpell (DETAILS_ATTRIBUTE_DAMAGE, unitId, spellId, isLiteral, segment)
end


--[=[
	Details.UnitDamagingSpells (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamagingSpells",
	desc = "Return a numeric (ipairs) table with spells IDs used by the unit to apply damage.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitOffinsiveSpells",
			type = "table",
			desc = "Table with spellIds of spells the unit used to apply damage.",
		}
	},
	type = 1, --damage
}

local unitSpellList = function (containerID, unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return {}
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, containerID, unitName)
	if (not playerObject) then
		return {}
	end

	local unitSpells = playerObject.spells._ActorTable
	local resultTable = {}
	for spellId, spellObject in pairs (unitSpells) do
		resultTable [#resultTable + 1] = spellId
	end

	return resultTable
end

function Details.UnitDamagingSpells (unitId, segment)
	return unitSpellList (1, unitId, segment)
end

--[=[
	Details.UnitDamagingTargets (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamagingTargets",
	desc = "Return a numeric (ipairs) table with names of targets the unit inflicted damage. You may query the amount of damage with Details.UnitDamageOnUnit( unitId, targetName ).",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "offensiveTargetNames",
			type = "table",
			desc = "Table containing names of all offensive targets of the unit.",
		}
	},
	type = 1, --damage
}

local unitTargets = function (containerID, unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)
	local offensiveTargetNames = {}

	local playerObject = getActorObjectFromCombat (combatObject, containerID, unitName)
	if (not playerObject) then
		return offensiveTargetNames
	end

	for targetName, _ in pairs (playerObject.targets) do
		offensiveTargetNames [#offensiveTargetNames + 1] = targetName
	end

	return offensiveTargetNames
end

function Details.UnitDamagingTargets (unitId, segment)
	return unitTargets (1, unitId, segment)
end


--[=[
	Details.UnitDamagingPets (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitDamagingPets",
	desc = "Return a numeric (ipairs) table with all pet names the unit used to apply damage. Individual pet information can be queried with Details.UnitDamage( petName ).",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "petNames",
			type = "table",
			desc = "Table containing names of all pets the unit used to apply damage.",
		}
	},
	type = 1, --damage
}

local unitPets = function (containerID, unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)
	local petNames = {}

	local playerObject = getActorObjectFromCombat (combatObject, containerID, unitName)
	if (not playerObject) then
		return petNames
	end

	for i = 1, #playerObject.pets do
		petNames [#petNames + 1] = playerObject.pets [i]
	end

	return petNames
end

function Details.UnitDamagingPets (unitId, segment)
	return unitPets (1, unitId, segment)
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> ~healing


--[=[
	Details.UnitHealing (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealing",
	desc = "Query the healing done of a unit.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitHealingDone",
			type = "number",
			desc = "Number representing the unit healing.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealing (unitId, segment)
	return unitTotal (2, unitId, segment)
end


--[=[
	Details.UnitHealingInfo (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingInfo",
	desc = "Return a table with healing information.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "healingInfo",
			type = "table",
			desc = "Table containing damage information, keys are: .total, .totalWithoutPet, .totalOverhealWithoutPet, .overhealing, .absorbed, .healingEnemy, .healingTaken, .activityTime",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingInfo (unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local healingInfo = {
		total = 0,
		totalWithoutPet = 0,
		totalOverhealWithoutPet = 0,
		overhealing = 0,
		absorbed = 0,
		healingEnemy = 0,
		healingTaken = 0,
		activityTime = 0,
	}

	local playerObject = getActorObjectFromCombat (combatObject, 2, unitName)
	if (not playerObject) then
		return healingInfo
	end

	healingInfo.total = floor (playerObject.total)
	healingInfo.totalWithoutPet = floor (playerObject.total_without_pet)
	healingInfo.totalOverhealWithoutPet = floor (playerObject.totalover_without_pet)
	healingInfo.overhealing = floor (playerObject.totalover)
	healingInfo.absorbed = floor (playerObject.totalabsorb)
	healingInfo.healingEnemy = floor (playerObject.heal_enemy_amt)
	healingInfo.healingTaken = floor (playerObject.healing_taken)
	healingInfo.activityTime = playerObject:Tempo()

	return healingInfo
end



--[=[
	Details.UnitHealingBySpell (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingBySpell",
	desc = "Query the total healing done of a spell casted by the unit.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query the healing done. Accept spell names.",
			required = true,
		},
		{
			name = "isLiteral",
			type = "boolean",
			default = "true",
			desc = "Search for the spell without transforming the spellId into a spell name before the search.",
		},
		{
			name = "segment",
			default = "0",
			type = "number",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitSpellHealing",
			type = "number",
			desc = "Number representing the spell healing done.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingBySpell (unitId, spellId, isLiteral, segment)
	return unitBySpell (2, unitId, spellId, isLiteral, segment)
end




--[=[
	Details.UnitHealingSpellInfo (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingSpellInfo",
	desc = "Return a table with the spell healing information.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query its healing information. Accept spell names.",
			required = true,
		},
		{
			name = "isLiteral",
			type = "boolean",
			default = "true",
			desc = "Search for the spell without transforming the spellId into a spell name before the search.",
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "spellHealingInfo",
			type = "table",
			desc = "Table containing damage information, keys are: '.total', '.spellId', '.count', '.name', '.casted', '.regularMin', '.regularMax', '.regularAmount', '.regularDamage', '.criticalMin', '.criticalMax', '.criticalAmount', '.criticalDamage'",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingSpellInfo (unitId, spellId, isLiteral, segment)
	if (type (isLiteral) ~= "boolean") then
		isLiteral = true
	end
	segment = segment or 0

	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local spellInfo = {
		total = 0,
		spellId = 0,
		count = 0,
		name = "",
		casted = 0,
		regularMin = 0,
		regularMax = 0,
		regularHits = 0,
		regularHealing = 0,
		criticalMin = 0,
		criticalMax = 0,
		criticalHits = 0,
		criticalHealing = 0,
	}

	local playerObject = getActorObjectFromCombat (combatObject, 2, unitName)
	if (not playerObject) then
		return spellInfo
	end

	local spellObject, spellId = getSpellObject (playerObject, spellId, isLiteral)
	if (not spellObject) then
		return spellInfo
	end

	local spellName = GetSpellInfo (spellId)
	spellInfo.casted = getCastedAmount (combatObject, unitName, spellId, spellName)

	spellInfo.total = spellObject.total
	spellInfo.count = spellObject.counter
	spellInfo.spellId = spellId
	spellInfo.name = spellName
	spellInfo.regularMin = spellObject.n_min
	spellInfo.regularMax = spellObject.n_max
	spellInfo.regularHits = spellObject.n_amt
	spellInfo.regularHealing = spellObject.n_curado
	spellInfo.criticalMin = spellObject.c_min
	spellInfo.criticalMax = spellObject.c_max
	spellInfo.criticalHits = spellObject.c_amt
	spellInfo.criticalHealing = spellObject.c_curado

	return spellInfo
end


--[=[
	Details.UnitHealingSpellOnUnit (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingSpellOnUnit",
	desc = "Query the healing done of a spell into a specific target.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query its healing done to an unit. Accept spell names.",
			required = true,
		},
		{
			name = "targetUnitId",
			type = "string",
			desc = "Name or ID of an unit, example: 'Thrall', 'Jaina', 'player', 'target', 'raid5'.",
			required = true,
		},
		{
			name = "isLiteral",
			type = "boolean",
			default = "true",
			desc = "Search for the spell without transforming the spellId into a spell name before the search.",
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitHealingSpellOnUnit",
			type = "number",
			desc = "Healing done by the spell into the target.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingSpellOnUnit (unitId, spellId, targetUnitId, isLiteral, segment)
	return unitSpellOnUnit (2, unitId, spellId, targetUnitId, isLiteral, segment)
end



--[=[
	Details.UnitHealingTaken (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingTaken",
	desc = "Query the unit healing taken.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitHealingTaken",
			type = "number",
			desc = "Number representing the healing taken by the unit.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingTaken (unitId, segment)
	segment = segment or 0
	local combatObject = getCombatObject (segment)

	if (not combatObject) then
		return 0
	end

	local unitName = getUnitName (unitId)

	local playerObject = getActorObjectFromCombat (combatObject, 2, unitName)
	if (not playerObject) then
		return 0
	end

	return floor (playerObject.healing_taken)
end



--[=[
	Details.UnitHealingOnUnit (unitId, targetUnitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingOnUnit",
	desc = "Query the unit healing done on another unit.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "targetUnitId",
			type = "string",
			desc = "Name or ID of an unit, example: 'Thrall', 'Jaina', 'player', 'target', 'raid5'.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitHealingOnUnit",
			type = "number",
			desc = "Number representing the healing done by the unit on the target unit.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingOnUnit (unitId, targetUnitId, segment)
	return unitOnUnit (2, unitId, targetUnitId, segment)
end




--[=[
	Details.UnitHealingTakenFromSpell (unitId, spellId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingTakenFromSpell",
	desc = "Query the unit healing taken from a spell.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "spellId",
			type = "number",
			desc = "Id of a spell to query its healing to an unit. Accept spell names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitHealingTakenFromSpell",
			type = "number",
			desc = "Number representing the healing taken by the unit from a spell.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingTakenFromSpell (unitId, spellId, isLiteral, segment)
	return unitTakenFromSpell (DETAILS_ATTRIBUTE_HEAL, unitId, spellId, isLiteral, segment)
end



--[=[
	Details.UnitHealingSpells (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingSpells",
	desc = "Return a numeric (ipairs) table with spells IDs used by the unit to apply healing.",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "unitHealingSpells",
			type = "table",
			desc = "Table with spellIds of spells the unit used to apply healing.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingSpells (unitId, segment)
	return unitSpellList (2, unitId, segment)
end


--[=[
	Details.UnitHealingTargets (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingTargets",
	desc = "Return a numeric (ipairs) table with names of targets the unit applied heal. You may query the amount of damage with Details.UnitHealingOnUnit( unitId, targetName ).",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "healingTargetNames",
			type = "table",
			desc = "Table containing names of all targets the unit applied heal.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingTargets (unitId, segment)
	return unitTargets (2, unitId, segment)
end



--[=[
	Details.UnitHealingPets (unitId, segment)
--=]=]
Details.API_Description.namespaces[1].api[#Details.API_Description.namespaces[1].api+1] = {
	name = "UnitHealingPets",
	desc = "Return a numeric (ipairs) table with all pet names the unit used to apply healing. Individual pet information can be queried with Details.UnitHealing( petName ).",
	parameters = {
		{
			name = "unitId",
			type = "string",
			desc = "The ID of an unit, example: 'player', 'target', 'raid5'. Accept unit names.",
			required = true,
		},
		{
			name = "segment",
			type = "number",
			default = "0",
			desc = "Which segment to retrive data, default value is zero (current segment). Use -1 for overall data or value from 1 to 25 for other segments.",
		},
	},
	returnValues = {
		{
			name = "petNames",
			type = "table",
			desc = "Table containing names of all pets the unit used to apply heal.",
		}
	},
	type = 2, --healing
}

function Details.UnitHealingPets (unitId, segment)
	return unitPets (2, unitId, segment)
end

--stop auto complete: doo ende endp elsez
