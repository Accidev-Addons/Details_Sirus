--[[ Spell Cache store all spells shown on frames and make able to change spells name, icons, etc... ]]

do

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> On The Fly SpellCache

	local _detalhes = 	_G._detalhes
	local Loc = LibStub ("AceLocale-3.0"):GetLocale ( "Details" )
	local _
	local _rawset	=	rawset
	local _setmetatable =	setmetatable
	local _GetSpellInfo =	GetSpellInfo
	local _unpack	=	unpack

	--> default container
	_detalhes.spellcache =	{}
	local unknowSpell = {Loc ["STRING_UNKNOWSPELL"], _, "Interface\\Icons\\Ability_Druid_Eclipse"} --> localize-me

	--> reset spell cache
	function _detalhes:ClearSpellCache()
		_detalhes.spellcache = _setmetatable ({},
				{__index = function (tabela, valor)
					--> should save only icon and name, other values are not used
					if (valor) then --> check if spell is valid before
						local cache = {_GetSpellInfo (valor)}
						tabela [valor] = cache
						return cache
					else
						return unknowSpell
					end

				end})

		--> default overwrites

		--> user overwrites
		-- [1] spellid [2] spellname [3] spellicon
		for index, spellTable in ipairs (_detalhes.savedCustomSpells) do
			_rawset (_detalhes.spellcache, spellTable [1], {spellTable [2], 1, spellTable [3]})
		end
	end


	local default_user_spells = {
		[1] = {name = Loc ["STRING_MELEE"], icon = [[Interface\ICONS\INV_Sword_04]]},
		[2] = {name = Loc ["STRING_AUTOSHOT"], icon = [[Interface\ICONS\INV_Weapon_Bow_07]]},
		[3] = {name = Loc ["STRING_ENVIRONMENTAL_FALLING"], icon = [[Interface\ICONS\Spell_Magic_FeatherFall]]},
		[4] = {name = Loc ["STRING_ENVIRONMENTAL_DROWNING"], icon = [[Interface\ICONS\Ability_Suffocate]]},
		[5] = {name = Loc ["STRING_ENVIRONMENTAL_FATIGUE"], icon = [[Interface\ICONS\Spell_Arcane_MindMastery]]},
		[6] = {name = Loc ["STRING_ENVIRONMENTAL_FIRE"], icon = [[Interface\ICONS\INV_SummerFest_FireSpirit]]},
		[7] = {name = Loc ["STRING_ENVIRONMENTAL_LAVA"], icon = [[Interface\ICONS\Ability_Rhyolith_Volcano]]},
		[8] = {name = Loc ["STRING_ENVIRONMENTAL_SLIME"], icon = [[Interface\ICONS\Ability_Creature_Poison_02]]},

		[59638] = {name = GetSpellInfo (59638) .. " (" .. Loc ["STRING_MIRROR_IMAGE"] .. ")"}, --> Mirror Image's Frost Bolt (mage)

		[44461] = {name = GetSpellInfo (44461) .. " (" .. Loc ["STRING_EXPLOSION"] .. ")"}, --> Living Bomb (explosion)

		[33778] = {name = GetSpellInfo (33778) .. " (Bloom)"}, --lifebloom (bloom)

		[70890] = {name = GetSpellInfo (70890) .. " (Shadow)"}, --DK Scourge Strike
		[55090] = {name = GetSpellInfo (55090) .. " (Physical)"}, --DK Scourge Strike

		[49184] = {name = GetSpellInfo (49184) .. " (Main Target)"}, --DK Howling Blast
	}

	function _detalhes:UserCustomSpellUpdate (index, name, icon)
		local t = _detalhes.savedCustomSpells [index]
		if (t) then
			t [2], t [3] = name or t [2], icon or t [3]
			return _rawset (_detalhes.spellcache, t [1], {t [2], 1, t [3]})
		else
			return false
		end
	end

	function _detalhes:UserCustomSpellReset (index)
		local t = _detalhes.savedCustomSpells [index]
		if (t) then
			local spellid = t [1]
			local name, _, icon = _GetSpellInfo (spellid)

			if (default_user_spells [spellid]) then
				name = default_user_spells [spellid].name
				icon = default_user_spells [spellid].icon or icon or [[Interface\InventoryItems\WoWUnknownItem01]]
			end

			if (not name) then
				name = "Unknown"
			end
			if (not icon) then
				icon = [[Interface\InventoryItems\WoWUnknownItem01]]
			end

			_rawset (_detalhes.spellcache, spellid, {name, 1, icon})

			t[2] = name
			t[3] = icon
		end
	end

	function _detalhes:FillUserCustomSpells()
		for spellid, t in pairs (default_user_spells) do

			local already_have
			for index, spelltable in ipairs (_detalhes.savedCustomSpells) do
				if (spelltable [1] == spellid) then
					already_have = spelltable
				end
			end

			if (not already_have) then
				local name, _, icon = GetSpellInfo (spellid)
				_detalhes:UserCustomSpellAdd (spellid, t.name or name or "Unknown", t.icon or icon or [[Interface\InventoryItems\WoWUnknownItem01]])
			end

		end

		for i = #_detalhes.savedCustomSpells, 1, -1 do
			local spelltable = _detalhes.savedCustomSpells [i]
			local spellid = spelltable [1]
			if (spellid > 10) then
				local exists = _GetSpellInfo (spellid)
				if (not exists) then
					tremove (_detalhes.savedCustomSpells, i)
				end
			end
		end
	end

	function _detalhes:UserCustomSpellAdd (spellid, name, icon)
		local is_overwrite = false
		for index, t in ipairs (_detalhes.savedCustomSpells) do
			if (t [1] == spellid) then
				t[2] = name
				t[3] = icon
				is_overwrite = true
				break
			end
		end
		if (not is_overwrite) then
			_detalhes.savedCustomSpells[#_detalhes.savedCustomSpells+1] = {spellid, name, icon}
		end
		return _rawset (_detalhes.spellcache, spellid, {name, 1, icon})
	end

	function _detalhes:UserCustomSpellRemove (index)
		local t = _detalhes.savedCustomSpells [index]
		if (t) then
			local spellid = t [1]
			local name, _, icon = _GetSpellInfo (spellid)
			if (name) then
				_rawset (_detalhes.spellcache, spellid, {name, 1, icon})
			end
			return tremove (_detalhes.savedCustomSpells, index)
		end

		return false
	end

	--> overwrite for API GetSpellInfo function
	_detalhes.getspellinfo = function (spellid) return _unpack (_detalhes.spellcache[spellid]) end
	_detalhes.GetSpellInfo = _detalhes.getspellinfo

	--> overwrite SpellInfo if the spell is a DoT, so Details.GetSpellInfo will return the name modified
	function _detalhes:SpellIsDot (spellid)
		local spellName, rank, spellIcon = _GetSpellInfo (spellid)

		if (spellName) then
			_rawset (_detalhes.spellcache, spellid, {spellName .. Loc ["STRING_DOT"], rank, spellIcon})
		else
			_rawset (_detalhes.spellcache, spellid, {"Unknown DoT Spell? " .. Loc ["STRING_DOT"], rank, [[Interface\InventoryItems\WoWUnknownItem01]]})
		end
	end




end
