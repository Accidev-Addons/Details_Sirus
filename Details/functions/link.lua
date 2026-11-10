	local _detalhes = _G._detalhes
	local L = LibStub ("AceLocale-3.0"):GetLocale ( "Details" )

	--lua locals
	local pairs = pairs
	local ipairs = ipairs
	local type = type
	local tonumber = tonumber

	--templates

	local UnitGroupRolesAssigned = DetailsFramework.UnitGroupRolesAssigned

	_detalhes:GetFramework():InstallTemplate ("button", "DETAILS_FORGE_TEXTENTRY_TEMPLATE", {
		backdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}, --edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1,
		backdropcolor = {0, 0, 0, .1},
	})

	local CONST_BUTTON_TEMPLATE = _detalhes:GetFramework():InstallTemplate ("button", "DETAILS_FORGE_BUTTON_TEMPLATE", {
		width = 140,
	},
	"DETAILS_PLUGIN_BUTTON_TEMPLATE")

	local CONST_BUTTONSELECTED_TEMPLATE = _detalhes:GetFramework():InstallTemplate ("button", "DETAILS_FORGE_BUTTONSELECTED_TEMPLATE", {
		width = 140,
	},
	"DETAILS_PLUGIN_BUTTONSELECTED_TEMPLATE")


	------------------------------------------------------------------------------------------------------------------

	--> get the total of damage and healing of this phase
	function _detalhes:OnCombatPhaseChanged()

		local current_combat = _detalhes:GetCurrentCombat()
		local current_phase = current_combat.PhaseData [#current_combat.PhaseData][1]

		local phase_damage_container = current_combat.PhaseData.damage [current_phase]
		local phase_healing_container = current_combat.PhaseData.heal [current_phase]

		local phase_damage_section = current_combat.PhaseData.damage_section
		local phase_healing_section = current_combat.PhaseData.heal_section

		if (not phase_damage_container) then
			phase_damage_container = {}
			current_combat.PhaseData.damage [current_phase] = phase_damage_container
		end
		if (not phase_healing_container) then
			phase_healing_container = {}
			current_combat.PhaseData.heal [current_phase] = phase_healing_container
		end

		for index, damage_actor in ipairs (_detalhes.cache_damage_group) do
			local phase_damage = damage_actor.total - (phase_damage_section [damage_actor.nome] or 0)
			phase_damage_section [damage_actor.nome] = damage_actor.total
			phase_damage_container [damage_actor.nome] = (phase_damage_container [damage_actor.nome] or 0) + phase_damage
		end

		for index, healing_actor in ipairs (_detalhes.cache_healing_group) do
			local phase_heal = healing_actor.total - (phase_healing_section [healing_actor.nome] or 0)
			phase_healing_section [healing_actor.nome] = healing_actor.total
			phase_healing_container [healing_actor.nome] = (phase_healing_container [healing_actor.nome] or 0) + phase_heal
		end

	end

	function _detalhes:BossModsLink()
		local set_encounter_phase = function (phase)
			_detalhes:OnCombatPhaseChanged()
			_detalhes.encounter_table.phase = phase
			local cur_combat = _detalhes:GetCurrentCombat()
			local time = cur_combat:GetCombatTime()
			if (time > 5) then
				cur_combat.PhaseData[#cur_combat.PhaseData+1] = {phase, time}
			end
			_detalhes:SendEvent ("COMBAT_ENCOUNTER_PHASE_CHANGED", nil, phase)
		end

		if (_G.DBM) then
			local dbm_callback_phase = function (event, msg, ...)

				local mod = _detalhes.encounter_table.DBM_Mod

				if (not mod) then
					for index, tmod in ipairs (DBM.Mods) do
						if (tmod.inCombat) then
							_detalhes.encounter_table.DBM_Mod = tmod
							mod = tmod
							break
						end
					end
				end

				local phase = mod and mod.vb and mod.vb.phase
				if (phase and _detalhes.encounter_table.phase ~= phase) then
					set_encounter_phase (phase)
				end
			end

			local dbm_callback_pull = function (event, mod, delay, synced)
				_detalhes.encounter_table.DBM_Mod = mod
				_detalhes.encounter_table.DBM_ModTime = time()
			end
			DBM:RegisterCallback("DBM_Announce", dbm_callback_phase)
			DBM:RegisterCallback("DBM_Pull", dbm_callback_pull)
		end

		if (BigWigsLoader and not _G.DBM) then
			function _detalhes:BigWigs_Message (event, module, key, text, ...)

				if (key == "stages") then
					local phase = text:gsub (".*%s", "")
					phase = tonumber (phase)

					if (phase and type (phase) == "number" and _detalhes.encounter_table.phase ~= phase) then
						set_encounter_phase (phase)
					end

				end
			end

			if (BigWigsLoader.RegisterMessage) then
				BigWigsLoader.RegisterMessage (_detalhes, "BigWigs_Message")
			end
		end


		_detalhes:CreateCallbackListeners()
	end

	--removido do plugin Encounter Details
	function _detalhes:CreateCallbackListeners()

		local current_encounter = false
		local current_table_dbm = {}
		local current_table_bigwigs = {}

		local event_frame = Details:CreateEventListener()
		
		function event_frame:OnDetailsEvent (event, ...)
			if (event == "COMBAT_ENCOUNTER_START") then
				local encounterID, encounterName, difficultyID, raidSize = ...
				current_encounter = encounterID
			elseif event == "COMBAT_ENCOUNTER_END" or event == "COMBAT_PLAYER_LEAVE" then
				if (current_encounter) then
					if (_G.DBM) then
						local db = _detalhes.boss_mods_timers
						for spell, timer_table in pairs (current_table_dbm) do
							if (not db.encounter_timers_dbm [timer_table[1]]) then
								timer_table.id = current_encounter
								db.encounter_timers_dbm [timer_table[1]] = timer_table
							end
						end
					end
					if (BigWigs) then
						local db = _detalhes.boss_mods_timers
						for timer_id, timer_table in pairs (current_table_bigwigs) do
							if (not db.encounter_timers_bw [timer_id]) then
								timer_table.id = current_encounter
								db.encounter_timers_bw [timer_id] = timer_table
							end
						end
					end
				end

				current_encounter = false
				wipe (current_table_dbm)
				wipe (current_table_bigwigs)
			end
		end

		_detalhes:RegisterEvent(event_frame, "COMBAT_ENCOUNTER_START")
		_detalhes:RegisterEvent(event_frame, "COMBAT_ENCOUNTER_END")
		_detalhes:RegisterEvent(event_frame, "COMBAT_PLAYER_LEAVE")

		if (_G.DBM) then
			local dbm_timer_callback = function (bar_type, id, msg, timer, icon, bartype, spellId, colorId, modid)
				local spell = tostring (spellId)
				if (spell and not current_table_dbm [spell]) then
					current_table_dbm [spell] = {spell, id, msg, timer, icon, bartype, spellId, colorId, modid}
				end
			end
			DBM:RegisterCallback ("DBM_TimerStart", dbm_timer_callback)
		end
		function _detalhes:RegisterBigWigsCallBack()
			if (BigWigsLoader) then
				function _detalhes:BigWigs_StartBar (event, module, spellid, bar_text, time, icon, ...)
					spellid = tostring (spellid)
					if (not current_table_bigwigs [spellid]) then
						current_table_bigwigs [spellid] = {(type (module) == "string" and module) or (module and module.moduleName) or "", spellid or "", bar_text or "", time or 0, icon or ""}
					end
				end
				if (BigWigsLoader.RegisterMessage) then
					BigWigsLoader.RegisterMessage (_detalhes, "BigWigs_StartBar")
				end
			end
		end
		_detalhes:ScheduleTimer ("RegisterBigWigsCallBack", 5)
	end


	local SplitLoadFrame = CreateFrame ("Frame")
	local MiscContainerNames = {
		"dispell_spells",
		"cooldowns_defensive_spells",
		"debuff_uptime_spells",
		"buff_uptime_spells",
		"interrupt_spells",
		"cc_done_spells",
		"cc_break_spells",
		"ress_spells",
	}
	local SplitLoadFunc = function (self, deltaTime)
		--which container it will iterate on this tick
		local container = _detalhes.tabela_vigente [SplitLoadFrame.NextActorContainer] and _detalhes.tabela_vigente [SplitLoadFrame.NextActorContainer]._ActorTable

		if (not container) then
			if (_detalhes.debug) then
				_detalhes:Msg ("(debug) finished index spells.")
			end
			SplitLoadFrame:SetScript ("OnUpdate", nil)
			return
		end

		local inInstance = IsInInstance()
		local isEncounter = _detalhes.tabela_vigente.is_boss
		local encounterID = isEncounter and isEncounter.id

		--get the actor
		local actorToIndex = container [SplitLoadFrame.NextActorIndex]

		--no actor? go to the next container
		if (not actorToIndex) then
			SplitLoadFrame.NextActorIndex = 1
			SplitLoadFrame.NextActorContainer = SplitLoadFrame.NextActorContainer + 1

			--finished all the 4 container? kill the process
			if (SplitLoadFrame.NextActorContainer == 5) then
				SplitLoadFrame:SetScript ("OnUpdate", nil)
				if (_detalhes.debug) then
					_detalhes:Msg ("(debug) finished index spells.")
				end
				return
			end
		else
			--++
			SplitLoadFrame.NextActorIndex = SplitLoadFrame.NextActorIndex + 1

			--get the class name or the actor name in case the actor isn't a player
			local source
			if (inInstance) then
				source = RAID_CLASS_COLORS [actorToIndex.classe] and _detalhes.classstring_to_classid [actorToIndex.classe] or actorToIndex.nome
			else
				source = RAID_CLASS_COLORS [actorToIndex.classe] and _detalhes.classstring_to_classid [actorToIndex.classe]
			end

			--if found a valid actor
			if (source) then
				--if is damage, heal or energy
				if (SplitLoadFrame.NextActorContainer == 1 or SplitLoadFrame.NextActorContainer == 2 or SplitLoadFrame.NextActorContainer == 3) then
					--get the spell list in the spells container
					local spellList = actorToIndex.spells and actorToIndex.spells._ActorTable
					if (spellList) then

						local SpellPool = _detalhes.spell_pool
						local EncounterSpellPool = _detalhes.encounter_spell_pool

						for spellID, _ in pairs (spellList) do
							if (not SpellPool [spellID]) then
								SpellPool [spellID] = source
							end
							if (encounterID and not EncounterSpellPool [spellID]) then
								if (actorToIndex:IsEnemy()) then
									EncounterSpellPool [spellID] = {encounterID, source}
								end
							end
						end
					end

				--if is a misc container
				elseif (SplitLoadFrame.NextActorContainer == 4) then
					for _, containerName in ipairs (MiscContainerNames) do
						--check if the actor have this container
						if (actorToIndex [containerName]) then
							local spellList = actorToIndex [containerName]._ActorTable
							if (spellList) then

								local SpellPool = _detalhes.spell_pool
								local EncounterSpellPool = _detalhes.encounter_spell_pool

								for spellID, _ in pairs (spellList) do
									if (not SpellPool [spellID]) then
										SpellPool [spellID] = source
									end
									if (encounterID and not EncounterSpellPool [spellID]) then
										if (actorToIndex:IsEnemy()) then
											EncounterSpellPool [spellID] = {encounterID, source}
										end
									end
								end
							end
						end
					end

					--spells the actor casted
					if (actorToIndex.spell_cast) then
						local SpellPool = _detalhes.spell_pool
						local EncounterSpellPool = _detalhes.encounter_spell_pool

						for spellID, _ in pairs (actorToIndex.spell_cast) do
							if (not SpellPool [spellID]) then
								SpellPool [spellID] = source
							end
							if (encounterID and not EncounterSpellPool [spellID]) then
								if (actorToIndex:IsEnemy()) then
									EncounterSpellPool [spellID] = {encounterID, source}
								end
							end
						end
					end
				end
			end
		end
	end

	function _detalhes.StoreSpells()
		if (_detalhes.debug) then
			_detalhes:Msg ("(debug) started to index spells.")
		end
		SplitLoadFrame:SetScript ("OnUpdate", SplitLoadFunc)
		SplitLoadFrame.NextActorContainer = 1
		SplitLoadFrame.NextActorIndex = 1
	end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> forge

	function _detalhes:InitializeForge()
		local DetailsForgePanel = _detalhes.gump:CreateSimplePanel (UIParent, 960, 600, "Details! " .. L["STRING_SPELLLIST"], "DetailsForgePanel")
		DetailsForgePanel.Frame = DetailsForgePanel
		DetailsForgePanel.__name = L["STRING_SPELLLIST"]
		DetailsForgePanel.real_name = "DETAILS_FORGE"
		DetailsForgePanel.__icon = [[Interface\AddOns\Details\textures\Minimap\Vehicle-HammerGold-3]]
		DetailsPluginContainerWindow.EmbedPlugin (DetailsForgePanel, DetailsForgePanel, true)

		function DetailsForgePanel.RefreshWindow()
			_detalhes:OpenForge()
		end
	end

	function _detalhes:OpenForge()

		if (not DetailsForgePanel or not DetailsForgePanel.Initialized) then

			local fw = _detalhes:GetFramework()
			local lower = string.lower

			DetailsForgePanel.Initialized = true

			--main frame
			local f = DetailsForgePanel or _detalhes.gump:CreateSimplePanel (UIParent, 960, 600, "Details! " .. L["STRING_SPELLLIST"], "DetailsForgePanel")
			f:SetPoint ("CENTER", UIParent, "CENTER")
			f:SetFrameStrata ("HIGH")
			f:SetToplevel (true)
			f:SetMovable (true)
			f.Title:SetTextColor (1, .8, .2)

			if (not _detalhes:GetTutorialCVar ("FORGE_TUTORIAL")) then
				local tutorialFrame = CreateFrame ("Frame", "$parentTutorialFrame", f)
				tutorialFrame:SetPoint ("CENTER", f, "CENTER")
				tutorialFrame:SetFrameStrata ("DIALOG")
				tutorialFrame:SetSize (400, 300)
				tutorialFrame:SetBackdrop ({bgFile = [[Interface\AddOns\Details\images\background]], tile = true, tileSize = 16,
				insets = {left = 0, right = 0, top = 0, bottom = 0}, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize=1})
				tutorialFrame:SetBackdropColor (0, 0, 0, 1)

				tutorialFrame.Title = _detalhes.gump:CreateLabel (tutorialFrame, L["STRING_FORGE_TUTORIAL_TITLE"], 12, "orange")
				tutorialFrame.Desc = _detalhes.gump:CreateLabel (tutorialFrame, L["STRING_FORGE_TUTORIAL_DESC"], 12)
				tutorialFrame.Desc.width = 370
				tutorialFrame.Example = _detalhes.gump:CreateLabel (tutorialFrame, L["STRING_FORGE_TUTORIAL_VIDEO"], 12)

				tutorialFrame.Title:SetPoint ("TOP", tutorialFrame, "TOP", 0, -5)
				tutorialFrame.Desc:SetPoint ("TOPLEFT", tutorialFrame, "TOPLEFT", 10, -45)
				tutorialFrame.Example:SetPoint ("TOPLEFT", tutorialFrame, "TOPLEFT", 10, -110)

				local editBox = _detalhes.gump:CreateTextEntry (tutorialFrame, function()end, 375, 20, nil, nil, nil)
				editBox:SetPoint ("TOPLEFT", tutorialFrame.Example, "BOTTOMLEFT", 0, -10)
				editBox:SetText ([[https://www.youtube.com/watch?v=om0k1Yj2pEw]])
				editBox:SetTemplate (_detalhes.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))

				local closeButton = _detalhes.gump:CreateButton (tutorialFrame, function() _detalhes:SetTutorialCVar ("FORGE_TUTORIAL", true); tutorialFrame:Hide() end, 80, 20, L["STRING_OPTIONS_CHART_CLOSE"])
				closeButton:SetPoint ("BOTTOM", tutorialFrame, "BOTTOM", 0, 10)
				closeButton:SetTemplate (_detalhes.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
			end

			--modules
			local all_modules = {}
			local spell_already_added = {}

			f:SetScript ("OnHide", function()
				for _, module in ipairs (all_modules) do
					if (module.data) then
						wipe (module.data)
					end
				end
				wipe (spell_already_added)
			end)

			_detalhes:FormatBackground (f)

			local no_func = function()end
			local nothing_to_show = {}
			local add_filter_box = function (w, previousEntry, labelText, entryName)
				local label = w:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
				label:SetText (labelText .. ": ")
				if (previousEntry) then
					label:SetPoint ("LEFT", previousEntry.widget, "RIGHT", 20, 0)
				else
					label:SetPoint ("LEFT", w, "LEFT", 5, 0)
				end
				local entry = fw:CreateTextEntry (w, nil, 120, 20, "entry", entryName)
				entry:SetHook ("OnTextChanged", function() f:refresh() end)
				entry:SetPoint ("LEFT", label, "RIGHT", 2, 0)
				entry:SetTemplate (_detalhes.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
				return entry
			end
			local current_module
			local buttons = {}

			function f:InstallModule (module)
				if (module and type (module) == "table") then
					all_modules[#all_modules+1] = module
				end
			end

			local all_players_module = {
				name = L["STRING_FORGE_BUTTON_PLAYERS"],
				desc = L["STRING_FORGE_BUTTON_PLAYERS_DESC"],
				filters_widgets = function()
					if (not DetailsForgeAllPlayersFilterPanel) then
						local w = CreateFrame ("Frame", "DetailsForgeAllPlayersFilterPanel", f)
						w:SetSize (600, 20)
						w:SetPoint ("TOPLEFT", f, "TOPLEFT", 164, -40)
						add_filter_box (w, nil, L["STRING_FORGE_FILTER_PLAYERNAME"], "DetailsForgeAllPlayersNameFilter")
					end
					return DetailsForgeAllPlayersFilterPanel
				end,
				search = function()
					local t = {}
					local filter = DetailsForgeAllPlayersNameFilter:GetText()
					for _, actor in ipairs (_detalhes:GetCombat("current"):GetActorList (DETAILS_ATTRIBUTE_DAMAGE)) do
						if (actor:IsGroupPlayer()) then
							if (filter ~= "") then
								filter = lower (filter)
								local actor_name = lower (actor:name())
								if (actor_name:find (filter)) then
									t [#t+1] = actor
								end
							else
								t [#t+1] = actor
							end
						end
					end
					return t
				end,
				header = {
					{name = L["STRING_FORGE_HEADER_INDEX"], width = 40, type = "text", func = no_func},
					{name = L["STRING_FORGE_HEADER_NAME"], width = 150, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_CLASS"], width = 100, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_GUID"], width = 230, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_FLAG"], width = 100, type = "entry", func = no_func},
				},
				fill_panel = false,
				fill_gettotal = function (self) return #self.module.data end,
				fill_fillrows = function (index, self)
					local data = self.module.data [index]
					if (data) then
						return {
							index,
							data:name() or "",
							data:class() or "",
							data.serial or "",
							"0x" .. _detalhes:hex (data.flag_original)
						}
					else
						return nothing_to_show
					end
				end,
				fill_name = "DetailsForgeAllPlayersFillPanel",
			}

			-----------------------------------------------
			local all_pets_module = {
				name = L["STRING_FORGE_BUTTON_PETS"],
				desc = L["STRING_FORGE_BUTTON_PETS_DESC"],
				filters_widgets = function()
					if (not DetailsForgeAllPetsFilterPanel) then
						local w = CreateFrame ("Frame", "DetailsForgeAllPetsFilterPanel", f)
						w:SetSize (600, 20)
						w:SetPoint ("TOPLEFT", f, "TOPLEFT", 164, -40)
						local entry = add_filter_box (w, nil, L["STRING_FORGE_FILTER_PETNAME"], "DetailsForgeAllPetsNameFilter")
						entry = add_filter_box (w, entry, L["STRING_FORGE_FILTER_OWNERNAME"], "DetailsForgeAllPetsOwnerFilter")
					end
					return DetailsForgeAllPetsFilterPanel
				end,
				search = function()
					local t = {}
					local filter_petname = DetailsForgeAllPetsNameFilter:GetText()
					local filter_ownername = DetailsForgeAllPetsOwnerFilter:GetText()
					for _, actor in ipairs (_detalhes:GetCombat("current"):GetActorList (DETAILS_ATTRIBUTE_DAMAGE)) do
						if (actor.owner) then
							local can_add = true
							if (filter_petname ~= "") then
								filter_petname = lower (filter_petname)
								local actor_name = lower (actor:name())
								if (not actor_name:find (filter_petname)) then
									can_add = false
								end
							end
							if (filter_ownername ~= "") then
								filter_ownername = lower (filter_ownername)
								local actor_name = lower (actor.ownerName)
								if (not actor_name:find (filter_ownername)) then
									can_add = false
								end
							end
							if (can_add) then
								t [#t+1] = actor
							end
						end
					end
					return t
				end,
				header = {
					{name = L["STRING_FORGE_HEADER_INDEX"], width = 40, type = "text", func = no_func},
					{name = L["STRING_FORGE_HEADER_NAME"], width = 150, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_OWNER"], width = 150, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_NPCID"], width = 60, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_GUID"], width = 100, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_FLAG"], width = 100, type = "entry", func = no_func},
				},
				fill_panel = false,
				fill_gettotal = function (self) return #self.module.data end,
				fill_fillrows = function (index, self)
					local data = self.module.data [index]
					if (data) then
						return {
							index,
							data:name():gsub ("(<).*(>)", "") or "",
							data.ownerName or "",
							_detalhes:GetNpcIdFromGuid (data.serial),
							data.serial or "",
							"0x" .. _detalhes:hex (data.flag_original)
						}
					else
						return nothing_to_show
					end
				end,
				fill_name = "DetailsForgeAllPetsFillPanel",
			}



			-----------------------------------------------

			local all_enemies_module = {
				name = L["STRING_FORGE_BUTTON_ENEMIES"],
				desc = L["STRING_FORGE_BUTTON_ENEMIES_DESC"],
				filters_widgets = function()
					if (not DetailsForgeAllEnemiesFilterPanel) then
						local w = CreateFrame ("Frame", "DetailsForgeAllEnemiesFilterPanel", f)
						w:SetSize (600, 20)
						w:SetPoint ("TOPLEFT", f, "TOPLEFT", 164, -40)
						add_filter_box (w, nil, L["STRING_FORGE_FILTER_ENEMYNAME"], "DetailsForgeAllEnemiesNameFilter")
					end
					return DetailsForgeAllEnemiesFilterPanel
				end,
				search = function()
					local t = {}
					local filter = DetailsForgeAllEnemiesNameFilter:GetText()
					for _, actor in ipairs (_detalhes:GetCombat("current"):GetActorList (DETAILS_ATTRIBUTE_DAMAGE)) do
						if (actor:IsNeutralOrEnemy()) then
							if (filter ~= "") then
								filter = lower (filter)
								local actor_name = lower (actor:name())
								if (actor_name:find (filter)) then
									t [#t+1] = actor
								end
							else
								t [#t+1] = actor
							end
						end
					end
					return t
				end,
				header = {
					{name = L["STRING_FORGE_HEADER_INDEX"], width = 40, type = "text", func = no_func},
					{name = L["STRING_FORGE_HEADER_NAME"], width = 150, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_NPCID"], width = 60, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_GUID"], width = 230, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_FLAG"], width = 100, type = "entry", func = no_func},
				},
				fill_panel = false,
				fill_gettotal = function (self) return #self.module.data end,
				fill_fillrows = function (index, self)
					local data = self.module.data [index]
					if (data) then
						return {
							index,
							data:name(),
							_detalhes:GetNpcIdFromGuid (data.serial),
							data.serial or "",
							"0x" .. _detalhes:hex (data.flag_original)
						}
					else
						return nothing_to_show
					end
				end,
				fill_name = "DetailsForgeAllEnemiesFillPanel",
			}

			-----------------------------------------------

			local spell_open_aura_creator = function (row)
				local data = all_modules [2].data [row]
				local spellid = data[1]
				local spellname, _, spellicon = GetSpellInfo (spellid)
				_detalhes:OpenAuraPanel (spellid, spellname, spellicon, data[3])
			end

			local spell_encounter_open_aura_creator = function (row)
				local data = all_modules [1].data [row]
				local spellID = data[1]
				local encounterID  = data [2]

				local spellname, _, spellicon = GetSpellInfo (spellID)

				_detalhes:OpenAuraPanel (spellID, spellname, spellicon, encounterID)
			end

			local all_spells_module = {
				name = L["STRING_FORGE_BUTTON_ALLSPELLS"],
				desc = L["STRING_FORGE_BUTTON_ALLSPELLS_DESC"],
				filters_widgets = function()
					if (not DetailsForgeAllSpellsFilterPanel) then
						local w = CreateFrame ("Frame", "DetailsForgeAllSpellsFilterPanel", f)
						w:SetSize (600, 20)
						w:SetPoint ("TOPLEFT", f, "TOPLEFT", 164, -40)
						local entry = add_filter_box (w, nil, L["STRING_FORGE_FILTER_SPELLNAME"], "DetailsForgeAllSpellsNameFilter")
						entry = add_filter_box (w, entry, L["STRING_FORGE_FILTER_CASTERNAME"], "DetailsForgeAllSpellsCasterFilter")
					end
					return DetailsForgeAllSpellsFilterPanel
				end,
				search = function()
					local t = {}
					local filter_caster = DetailsForgeAllSpellsCasterFilter:GetText()
					local filter_name = DetailsForgeAllSpellsNameFilter:GetText()
					local lower_FilterCaster = lower (filter_caster)
					local lower_FilterSpellName = lower (filter_name)
					wipe (spell_already_added)

					local SpellPoll = _detalhes.spell_pool
					for spellID, className in pairs (SpellPoll) do

						if (type (spellID) == "number" and spellID > 12) then

							local can_add = true

							if (lower_FilterCaster ~= "") then
								--class name are stored as numbers for players and string for non-player characters
								local classNameOriginal = className
								if (type (className) == "number") then
									className = _detalhes.classid_to_classstring [className]
									className = lower (className)
								else
									className = lower (className)
								end

								if (not className:find (lower_FilterCaster)) then
									can_add = false
								else
									className = classNameOriginal
								end
							end

							if (can_add	) then
								if (filter_name ~= "") then
									local spellName = GetSpellInfo (spellID)
									if (spellName) then
										spellName = lower (spellName)
										if (not spellName:find (lower_FilterSpellName)) then
											can_add = false
										end
									else
										can_add = false
									end
								end
							end

							if (can_add) then
								t[#t+1] = {spellID, _detalhes.classid_to_classstring [className] or className}
							end

						end
					end

					return t
				end,
				header = {
					{name = L["STRING_FORGE_HEADER_INDEX"], width = 40, type = "text", func = no_func},
					{name = L["STRING_FORGE_HEADER_ICON"], width = 40, type = "texture"},
					{name = L["STRING_FORGE_HEADER_NAME"], width = 150, type = "entry", func = no_func, onenter = function(self) GameTooltip:SetOwner (self.widget, "ANCHOR_TOPLEFT"); _detalhes:GameTooltipSetSpellByID (self.id); GameTooltip:Show() end, onleave = function(self) GameTooltip:Hide() end},
					{name = L["STRING_FORGE_HEADER_SPELLID"], width = 100, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_SCHOOL"], width = 60, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_CASTER"], width = 120, type = "entry", func = no_func},
					-- {name = L["STRING_FORGE_HEADER_EVENT"], width = 180, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_CREATEAURA"], width = 86, type = "button", func = spell_open_aura_creator, icon = [[Interface\AddOns\WeakAuras\Media\Textures\icon]], notext = true, iconalign = "center"},
				},
				fill_panel = false,
				fill_gettotal = function (self) return #self.module.data end,
				fill_fillrows = function (index, self)
					local data = self.module.data [index]
					if (data) then
						local spellName, _, spellIcon = GetSpellInfo (data[1])
						local classColor = RAID_CLASS_COLORS [data[2]] and RAID_CLASS_COLORS [data[2]].colorStr or "FFFFFFFF"
						return {
							index,
							spellIcon,
							{text = spellName or "", id = data[1] or 1},
							data[1] or "",
							_detalhes:GetSpellSchoolFormatedName (_detalhes.spell_school_cache [spellName]) or "",
							"|c" .. classColor .. data[2] .. "|r",
							""
						}
					else
						return nothing_to_show
					end
				end,
				fill_name = "DetailsForgeAllSpellsFillPanel",
			}


			-----------------------------------------------


			local encounter_spells_module = {
				name = L["STRING_FORGE_BUTTON_ENCOUNTERSPELLS"],
				desc = L["STRING_FORGE_BUTTON_ENCOUNTERSPELLS_DESC"],
				filters_widgets = function()
					if (not DetailsForgeEncounterBossSpellsFilterPanel) then

						local w = CreateFrame ("Frame", "DetailsForgeEncounterBossSpellsFilterPanel", f)
						w:SetSize (600, 20)
						w:SetPoint ("TOPLEFT", f, "TOPLEFT", 164, -40)
						local entry = add_filter_box (w, nil, L["STRING_FORGE_FILTER_SPELLNAME"], "DetailsForgeEncounterSpellsNameFilter")
						entry = add_filter_box (w, entry, L["STRING_FORGE_FILTER_CASTERNAME"], "DetailsForgeEncounterSpellsCasterFilter")
						entry = add_filter_box (w, entry, L["STRING_FORGE_FILTER_ENCOUNTERNAME"], "DetailsForgeEncounterSpellsEncounterFilter")
					end
					return DetailsForgeEncounterBossSpellsFilterPanel
				end,
				search = function()
					local t = {}

					local filter_name = DetailsForgeEncounterSpellsNameFilter:GetText()
					local filter_caster = DetailsForgeEncounterSpellsCasterFilter:GetText()
					local filter_encounter = DetailsForgeEncounterSpellsEncounterFilter:GetText()

					local lower_FilterCaster = lower (filter_caster)
					local lower_FilterSpellName = lower (filter_name)
					local lower_FilterEncounterName = lower (filter_encounter)

					wipe (spell_already_added)

					local SpellPoll = _detalhes.encounter_spell_pool
					for spellID, spellTable in pairs (SpellPoll) do
						if (spellID > 12) then

							local encounterID = spellTable [1]
							local enemyName = spellTable [2]
							local bossDetails, bossIndex = _detalhes:GetBossEncounterDetailsFromEncounterId (nil, encounterID)

							local can_add = true

							if (lower_FilterCaster ~= "") then
								if (not lower (enemyName):find (lower_FilterCaster)) then
									can_add = false
								end
							end

							if (can_add	) then
								if (filter_name ~= "") then
									local spellName = GetSpellInfo (spellID)
									if (spellName) then
										spellName = lower (spellName)
										if (not spellName:find (lower_FilterSpellName)) then
											can_add = false
										end
									else
										can_add = false
									end
								end
							end

							if (can_add and bossDetails) then
								local encounterName = bossDetails.boss
								if (filter_encounter ~= "" and encounterName and encounterName ~= "") then
									encounterName = lower (encounterName)
									if (not encounterName:find (lower_FilterEncounterName)) then
										can_add = false
									end
								end
							end

							if (can_add) then
								t[#t+1] = {spellID, encounterID, enemyName, bossDetails and bossDetails.boss or "--x--x--"}
							end
						end
					end

					return t
				end,

				header = {
					{name = L["STRING_FORGE_HEADER_INDEX"], width = 40, type = "text", func = no_func},
					{name = L["STRING_FORGE_HEADER_ICON"], width = 40, type = "texture"},
					{name = L["STRING_FORGE_HEADER_NAME"], width = 151, type = "entry", func = no_func, onenter = function(self) GameTooltip:SetOwner (self.widget, "ANCHOR_TOPLEFT"); _detalhes:GameTooltipSetSpellByID (self.id); GameTooltip:Show() end, onleave = function(self) GameTooltip:Hide() end},
					{name = L["STRING_FORGE_HEADER_SPELLID"], width = 55, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_SCHOOL"], width = 70, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_CASTER"], width = 80, type = "entry", func = no_func},
					{name = "", width = 1, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_ENCOUNTERNAME"], width = 120, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_CREATEAURA"], width = 100, type = "button", func = spell_encounter_open_aura_creator, icon = [[Interface\AddOns\WeakAuras\Media\Textures\icon]], notext = true, iconalign = "center"},
				},

				fill_panel = false,
				fill_gettotal = function (self) return #self.module.data end,
				fill_fillrows = function (index, self)
					local data = self.module.data [index]
					if (data) then


						local spellName, _, spellIcon = GetSpellInfo (data[1])

						return {
							index,
							spellIcon,
							{text = spellName or "", id = data[1] or 1},
							data[1] or "",
							_detalhes:GetSpellSchoolFormatedName (_detalhes.spell_school_cache [spellName]) or "",
							data[3] .. "|r",
							"",
							data[4],
						}
					else
						return nothing_to_show
					end
				end,
				fill_name = "DetailsForgeEncounterBossSpellsFillPanel",
			}


			-----------------------------------------------

			local npc_ids_module = {
				name = "Npc IDs",
				desc = "Show a list of known npc IDs",
				filters_widgets = function()
					if (not DetailsForgeEncounterNpcIDsFilterPanel) then

						local w = CreateFrame ("Frame", "DetailsForgeEncounterNpcIDsFilterPanel", f)
						w:SetSize (600, 20)
						w:SetPoint ("TOPLEFT", f, "TOPLEFT", 164, -40)
						--npc name filter
						add_filter_box (w, nil, "Npc Name", "DetailsForgeEncounterNpcIDsFilter")
					end
					return DetailsForgeEncounterNpcIDsFilterPanel
				end,
				search = function()
					local t = {}

					local filter_name = DetailsForgeEncounterNpcIDsFilter:GetText()
					local lower_FilterNpcName = lower (filter_name)

					local npcPool = _detalhes.npcid_pool
					for npcID, npcName in pairs (npcPool) do
						local can_add = true

						if (lower_FilterNpcName ~= "") then
							if (not lower (npcName):find (lower_FilterNpcName)) then
								can_add = false
							end
						end

						if (can_add) then
							t[#t+1] = {npcID, npcName}
						end
					end
					table.sort (t, DetailsFramework.SortOrder2R)

					return t
				end,

				header = {
					{name = L["STRING_FORGE_HEADER_INDEX"], width = 40, type = "text", func = no_func},
					{name = "NpcID", width = 100, type = "entry", func = no_func},
					{name = "Npc Name", width = 400, type = "entry", func = no_func},
				},

				fill_panel = false,
				fill_gettotal = function (self) return #self.module.data end,
				fill_fillrows = function (index, self)
					local data = self.module.data [index]
					if (data) then

						return {
							index,
							data[1],
							data[2]
						}
					else
						return nothing_to_show
					end
				end,
				fill_name = "DetailsForgeNpcIDsFillPanel",
			}

			-----------------------------------------------

			local dbm_open_aura_creator = function (row)
				local data = all_modules [4].data [row]

				local spellname, spellicon, _
				if (type (data [7]) == "number") then
					spellname, _, spellicon = GetSpellInfo (data [7])
				else
					if (data [7]) then
						local spellid = data[7]:gsub ("ej", "")
						spellid = tonumber (spellid)
						local title, description, depth, abilityIcon, displayInfo, siblingID, nextSectionID, filteredByDifficulty, link, startsOpen, flag1, flag2, flag3, flag4 = DetailsFramework.EncounterJournal.EJ_GetSectionInfo (spellid)
						spellname, spellicon = title, abilityIcon
					else
						return
					end
				end

				_detalhes:OpenAuraPanel (data[2], spellname, spellicon, data.id, DETAILS_WA_TRIGGER_DBM_TIMER, DETAILS_WA_AURATYPE_TEXT, {dbm_timer_id = data[2], spellid = data[7], text = "Next " .. spellname .. " In", text_size = 72, icon = spellicon})
			end

			local dbm_timers_module = {
				name = L["STRING_FORGE_BUTTON_DBMTIMERS"],
				desc = L["STRING_FORGE_BUTTON_DBMTIMERS_DESC"],
				filters_widgets = function()
					if (not DetailsForgeDBMBarsFilterPanel) then
						local w = CreateFrame ("Frame", "DetailsForgeDBMBarsFilterPanel", f)
						w:SetSize (600, 20)
						w:SetPoint ("TOPLEFT", f, "TOPLEFT", 164, -40)
						local entry = add_filter_box (w, nil, L["STRING_FORGE_FILTER_BARTEXT"], "DetailsForgeDBMBarsTextFilter")
						entry = add_filter_box (w, entry, L["STRING_FORGE_FILTER_ENCOUNTERNAME"], "DetailsForgeDBMBarsEncounterFilter")
					end
					return DetailsForgeDBMBarsFilterPanel
				end,
				search = function()
					local t = {}
					local filter_barname = DetailsForgeDBMBarsTextFilter:GetText()
					local filter_encounter = DetailsForgeDBMBarsEncounterFilter:GetText()

					local lower_FilterBarName = lower (filter_barname)
					local lower_FilterEncounterName = lower (filter_encounter)

					local source = _detalhes.boss_mods_timers.encounter_timers_dbm or {}

					for key, timer in pairs (source) do
						local can_add = true
						if (lower_FilterBarName ~= "") then
							if (not lower (timer [3]):find (lower_FilterBarName)) then
								can_add = false
							end
						end
						if (lower_FilterEncounterName ~= "") then
							local bossDetails, bossIndex = _detalhes:GetBossEncounterDetailsFromEncounterId (nil, timer.id)
							local encounterName = bossDetails and bossDetails.boss
							if (encounterName and encounterName ~= "") then
								encounterName = lower (encounterName)
								if (not encounterName:find (lower_FilterEncounterName)) then
									can_add = false
								end
							end
						end

						if (can_add) then
							t [#t+1] = timer
						end
					end
					return t
				end,
				header = {
					{name = L["STRING_FORGE_HEADER_INDEX"], width = 40, type = "text", func = no_func},
					{name = L["STRING_FORGE_HEADER_ICON"], width = 40, type = "texture"},
					{name = L["STRING_FORGE_HEADER_BARTEXT"], width = 150, type = "entry", func = no_func, onenter = function(self) GameTooltip:SetOwner (self.widget, "ANCHOR_TOPLEFT"); _detalhes:GameTooltipSetSpellByID (self.id); GameTooltip:Show() end, onleave = function(self) GameTooltip:Hide() end},
					{name = L["STRING_FORGE_HEADER_ID"], width = 130, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_SPELLID"], width = 50, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_TIMER"], width = 40, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_ENCOUNTERID"], width = 80, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_ENCOUNTERNAME"], width = 110, type = "entry", func = no_func},
					{name = L["STRING_FORGE_HEADER_CREATEAURA"], width = 80, type = "button", func = dbm_open_aura_creator, icon = [[Interface\AddOns\WeakAuras\Media\Textures\icon]], notext = true, iconalign = "center"},
				},

				fill_panel = false,
				fill_gettotal = function (self) return #self.module.data end,
				fill_fillrows = function (index, self)
					local data = self.module.data [index]
					if (data) then
						local encounter_id = data.id
						local bossDetails, bossIndex = _detalhes:GetBossEncounterDetailsFromEncounterId (nil, data.id)
						local bossName = bossDetails and bossDetails.boss or "--x--x--"

						local abilityID = tonumber (data [7])
						local spellName, _, spellIcon
						if (abilityID) then
							if (abilityID > 0) then
								spellName, _, spellIcon = GetSpellInfo (abilityID)
							end
						end

						return {
							index,
							spellIcon,
							{text = data[3] or "", id = abilityID and abilityID > 0 and abilityID or 0},
							data[2] or "",
							data[7] or "",
							data[4] or "0",
							tostring (encounter_id) or "0",
							bossName,
						}
					else
						return nothing_to_show
					end
				end,
				fill_name = "DetailsForgeDBMBarsFillPanel",
			}

			-----------------------------------------------



			local select_module = function (a, b, module_number)

				if (current_module ~= module_number) then
					local module = all_modules [current_module]
					if (module) then
						local filters = module.filters_widgets()
						filters:Hide()
						local fill_panel = module.fill_panel
						fill_panel:Hide()
					end
				end

				for index, button in ipairs (buttons) do
					button:SetTemplate (CONST_BUTTON_TEMPLATE)
				end
				buttons[module_number]:SetTemplate (CONST_BUTTONSELECTED_TEMPLATE)

				local module = all_modules [module_number]
				if (module) then
					current_module = module_number

					local fillpanel = module.fill_panel
					if (not fillpanel) then
						fillpanel = fw:NewFillPanel (f, module.header, module.fill_name, nil, 740, 481, module.fill_gettotal, module.fill_fillrows, false)
						fillpanel:SetPoint (170, -80)
						fillpanel.module = module

						local background = fillpanel:CreateTexture (nil, "background")
						background:SetAllPoints()
						background:SetTexture (0, 0, 0, 0.2)

						module.fill_panel = fillpanel
					end

					local filters = module.filters_widgets()
					filters:Show()

					local data = module.search()
					module.data = data

					fillpanel:Show()
					fillpanel:Refresh()

					for o = 1, #fillpanel.scrollframe.lines do
						for i = 1, #fillpanel.scrollframe.lines [o].entry_inuse do
							--> text entry
							fillpanel.scrollframe.lines [o].entry_inuse [i]:SetTemplate (fw:GetTemplate ("button", "DETAILS_FORGE_TEXTENTRY_TEMPLATE"))
						end
					end
				end
			end

			function f:refresh()
				select_module (nil, nil, current_module)
			end

			f.SelectModule = select_module

			f:InstallModule (encounter_spells_module)
			f:InstallModule (all_spells_module)

			f:InstallModule (npc_ids_module)

			f:InstallModule (dbm_timers_module)

			f:InstallModule (all_players_module)
			f:InstallModule (all_enemies_module)
			f:InstallModule (all_pets_module)

			local brackets = {
				[4] = true,
				[5] = true
			}
			local lastButton

			for i = 1, #all_modules do
				local module = all_modules [i]
				local b = fw:CreateButton (f, select_module, 140, 20, module.name, i)
				b.tooltip = module.desc

				b:SetTemplate (CONST_BUTTON_TEMPLATE)
				b:SetIcon ([[Interface\BUTTONS\UI-GuildButton-PublicNote-Up]], nil, nil, nil, nil, {1, 1, 1, 0.7})
				b:SetWidth (140)

				if (lastButton) then
					if (brackets [i]) then
						b:SetPoint ("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -23)
					else
						b:SetPoint ("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -8)
					end
				else
					b:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, (i*16*-1) - 67)
				end

				lastButton = b
				buttons[#buttons+1] = b
			end

			select_module (nil, nil, 1)

		end

		DetailsForgePanel:Show()

		--do a refresh on the panel
		if (DetailsForgePanel.FirstRun) then
			DetailsForgePanel:refresh()
		else
			DetailsForgePanel.FirstRun = true
		end

		DetailsPluginContainerWindow.OpenPlugin (DetailsForgePanel)

	end

	--_detalhes:ScheduleTimer ("OpenForge", 3)

----------------------------------------------------------------------------------------------------------------------------------

--framename:
-- DeathRecapFrame
-- OpenDeathRecapUI()
-- Blizzard_DeathRecap

local textAlpha = 0.9

local on_deathrecap_line_enter = function (self)
	if (self.spellid) then
		GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
		_detalhes:GameTooltipSetSpellByID (self.spellid)
		self:SetBackdropColor (.3, .3, .3, .2)
		GameTooltip:Show()
		self.backgroundTextureOverlay:Show()
		self.timeAt:SetAlpha (1)
		self.sourceName:SetAlpha (1)
		self.amount:SetAlpha (1)
		self.lifePercent:SetAlpha (1)
	end
end
local on_deathrecap_line_leave = function (self)
	GameTooltip:Hide()
	self:SetBackdropColor (.3, .3, .3, 0)
	self.backgroundTextureOverlay:Hide()
	self.timeAt:SetAlpha (textAlpha)
	self.sourceName:SetAlpha (textAlpha)
	self.amount:SetAlpha (textAlpha)
	self.lifePercent:SetAlpha (textAlpha)
end

local create_deathrecap_line = function (parent, n)
	local line = CreateFrame ("Button", "DetailsDeathRecapLine" .. n, parent)
	line:SetPoint ("TOPLEFT", parent, "TOPLEFT", 10, (-24 * n) - 17)
	line:SetPoint ("TOPRIGHT", parent, "TOPRIGHT", -10, (-24 * n) - 17)
	--line:SetBackdrop ({bgFile = [[Interface\AddOns\Details\images\background]], tile = true, tileSize = 16,
	--insets = {left = 0, right = 0, top = 0, bottom = 0}})
	line:SetScript ("OnEnter", on_deathrecap_line_enter)
	line:SetScript ("OnLeave", on_deathrecap_line_leave)

	line:SetSize (300, 21)

	if (n % 2 == 0) then
		--line:SetBackdropColor (0, 0, 0, 0)
	else
		--line:SetBackdropColor (.3, .3, .3, 0)
	end

	local timeAt = line:CreateFontString (nil, "overlay", "GameFontNormal")
	local backgroundTexture = line:CreateTexture (nil, "border")
	local backgroundTextureOverlay = line:CreateTexture (nil, "artwork")
	local spellIcon = line:CreateTexture (nil, "overlay")
	local spellIconBorder = line:CreateTexture (nil, "overlay")
	spellIcon:SetDrawLayer ("overlay", 1)
	spellIconBorder:SetDrawLayer ("overlay", 2)
	local sourceName = line:CreateFontString (nil, "overlay", "GameFontNormal")
	local amount = line:CreateFontString (nil, "overlay", "GameFontNormal")
	local lifePercent = line:CreateFontString (nil, "overlay", "GameFontNormal")

	--grave icon
	local graveIcon = line:CreateTexture (nil, "overlay")
	graveIcon:SetTexture ([[Interface\MINIMAP\POIIcons]])
	graveIcon:SetTexCoord (146/256, 160/256, 0/512, 18/512)
	graveIcon:SetPoint ("LEFT", line, "LEFT", 11, 0)
	graveIcon:SetSize (14, 18)

	--spell icon
	spellIcon:SetSize (19, 19)
	spellIconBorder:SetTexture ([[Interface\ENCOUNTERJOURNAL\LootTab]])
	spellIconBorder:SetTexCoord (6/256, 38/256, 49/128, 81/128)
	spellIconBorder:SetSize (20, 20)
	spellIconBorder:SetPoint ("TOPLEFT", spellIcon, "TOPLEFT", 0, 0)

	--locations
	timeAt:SetPoint ("LEFT", line, "LEFT", 2, 0)
	spellIcon:SetPoint ("LEFT", line, "LEFT", 50, 0)
	sourceName:SetPoint ("LEFT", line, "LEFT", 82, 0)
	amount:SetPoint ("LEFT", line, "LEFT", 240, 0)
	lifePercent:SetPoint ("LEFT", line, "LEFT", 320, 0)

	--text colors
	_detalhes.gump:SetFontColor (amount, "red")
	_detalhes.gump:SetFontColor (timeAt, "gray")
	_detalhes.gump:SetFontColor (sourceName, "yellow")

	_detalhes.gump:SetFontSize (sourceName, 10)

	--text alpha
	timeAt:SetAlpha (textAlpha)
	sourceName:SetAlpha (textAlpha)
	amount:SetAlpha (textAlpha)
	lifePercent:SetAlpha (textAlpha)

	--text setup
	amount:SetWidth (85)
	amount:SetJustifyH ("RIGHT")
	lifePercent:SetWidth (42)
	lifePercent:SetJustifyH ("RIGHT")

	backgroundTexture:SetTexCoord (0, 1, 0, 1)
	backgroundTexture:SetVertexColor (.1, .1, .1, .3)


	--top border
	local TopFader = line:CreateTexture (nil, "border")
	TopFader:SetTexCoord (0, 1, 0, 1)
	TopFader:SetVertexColor (.1, .1, .1, .3)
	TopFader:SetPoint ("BOTTOMLEFT", backgroundTexture, "TOPLEFT", 0, -0)
	TopFader:SetPoint ("BOTTOMRIGHT", backgroundTexture, "TOPRIGHT", 0, -0)
	TopFader:SetHeight (32)
	TopFader:Hide()
	line.TopFader = TopFader

	if (n == 10) then
		--bottom fader
		local backgroundTexture2 = line:CreateTexture (nil, "border")
		backgroundTexture2:SetTexCoord (0, 1, 0, 1)
		backgroundTexture2:SetVertexColor (.1, .1, .1, .3)
		backgroundTexture2:SetPoint ("TOPLEFT", backgroundTexture, "BOTTOMLEFT", 0, 0)
		backgroundTexture2:SetPoint ("TOPRIGHT", backgroundTexture, "BOTTOMRIGHT", 0, 0)
		backgroundTexture2:SetHeight (32)

		--_detalhes.gump:SetFontColor (amount, "red")
		_detalhes.gump:SetFontSize (amount, 14)
		_detalhes.gump:SetFontSize (lifePercent, 14)
		backgroundTexture:SetVertexColor (.2, .1, .1, .3)

	end

	--backgroundTexture:SetAllPoints()
	backgroundTexture:SetPoint ("TOPLEFT", 0, 1)
	backgroundTexture:SetPoint ("BOTTOMRIGHT", 0, -1)
	backgroundTexture:SetDesaturated (true)
	backgroundTextureOverlay:SetTexture ([[Interface\AdventureMap\AdventureMap]])
	backgroundTextureOverlay:SetTexCoord (460/1024, 659/1024, 330/1024, 350/1024)
	backgroundTextureOverlay:SetAllPoints()
	backgroundTextureOverlay:SetDesaturated (true)
	backgroundTextureOverlay:SetAlpha (0.5)
	backgroundTextureOverlay:Hide()

	line.timeAt = timeAt
	line.spellIcon = spellIcon
	line.sourceName = sourceName
	line.amount = amount
	line.lifePercent = lifePercent
	line.backgroundTexture = backgroundTexture
	line.backgroundTextureOverlay = backgroundTextureOverlay
	line.graveIcon = graveIcon

	if (n == 10) then
		graveIcon:Show()
		line.timeAt:Hide()
	else
		graveIcon:Hide()
	end

	return line
end

local OpenDetailsDeathRecapAtSegment = function (segment)
	_detalhes.OpenDetailsDeathRecap (segment)
end

function _detalhes.BuildDeathTableFromRecap (recapID)
	local events = C_DeathRecap.GetRecapEvents(recapID)

	--check if it is a valid recap
	if (not events or #events <= 0) then
		DeathRecapFrame.Unavailable:Show()
		return
	end

	--build an death log using details format
	local _, playerClass = UnitClass("player")
	ArtificialDeathLog = {
		{}, --deathlog events
		(events [1] and events [1].timestamp) or (DeathRecapFrame and DeathRecapFrame.DeathTimeStamp) or 0, --time of death
		UnitName ("player"),
		playerClass,
		UnitHealthMax ("player"),
		"0m 0s", --formated fight time
		["dead"] = true,
		["last_cooldown"] = false,
		["dead_at"] = 0,
		n = 1
	}

	for i = 1, #events do
		local evtData = events [i]

		local ev = {
			true,
			evtData.spellID or 0,
			evtData.damage or 0,
			evtData.timestamp or 0,
			evtData.unitHealth or 0,
			evtData.casterName or "--x--x--",
			0, --absorbed (not in C_DeathRecap)
			0, --school (not in C_DeathRecap)
			evtData.critical or false,
			nil, --overkill (not in C_DeathRecap)
			not evtData.spellID and {nil, evtData.spellName, evtData.texture},
		}

		ArtificialDeathLog[1][#ArtificialDeathLog[1]+1] = ev
		ArtificialDeathLog.n = ArtificialDeathLog.n + 1
	end

	return ArtificialDeathLog
end

function _detalhes.GetDeathRecapFromChat()
	-- /dump ChatFrame1:GetMessageInfo (i)
	-- /dump ChatFrame1:GetNumMessages()
	local chat1 = ChatFrame1
	local recapIDFromChat
	if (chat1) then
		local numLines = chat1:GetNumMessages()
		for i = numLines, 1, -1 do
			local text = chat1:GetMessageInfo (i)
			if (text) then
				if (text:find ("Hdeath:%d")) then
					local recapID = text:match ("|Hdeath:(%d+)|h")
					if (recapID) then
						recapIDFromChat = tonumber (recapID)
					end
					break
				end
			end
		end
	end

	if (recapIDFromChat) then
		_detalhes.OpenDetailsDeathRecap (nil, recapIDFromChat, true)
		return
	end
end

function _detalhes.OpenDetailsDeathRecap (segment, RecapID, fromChat)

		if (not _detalhes.death_recap.enabled) then
			if (Details.DeathRecap and Details.DeathRecap.Lines) then
				for i = 1, 10 do
					Details.DeathRecap.Lines [i]:Hide()
				end
				for i, button in ipairs (Details.DeathRecap.Segments) do
					button:Hide()
				end
			end

			return
		end

		DeathRecapFrame.Recap1:Hide()
		DeathRecapFrame.Recap2:Hide()
		DeathRecapFrame.Recap3:Hide()
		DeathRecapFrame.Recap4:Hide()
		DeathRecapFrame.Recap5:Hide()

		if (not Details.DeathRecap) then
			Details.DeathRecap = CreateFrame ("Frame", "DetailsDeathRecap", DeathRecapFrame)
			Details.DeathRecap:SetAllPoints()

			DeathRecapFrame.Title:SetText (DeathRecapFrame.Title:GetText() .. " (by Details!)")

			--lines
			Details.DeathRecap.Lines = {}
			for i = 1, 10 do
				Details.DeathRecap.Lines [i] = create_deathrecap_line (Details.DeathRecap, i)
			end

			--segments
			Details.DeathRecap.Segments = {}
			for i = 5, 1, -1 do
				local segmentButton = CreateFrame ("button", "DetailsDeathRecapSegmentButton" .. i, Details.DeathRecap)

				segmentButton:SetSize (16, 20)
				segmentButton:SetPoint ("TOPRIGHT", DeathRecapFrame, "TOPRIGHT", (-abs (i-6) * 22) - 10, -5)

				local text = segmentButton:CreateFontString (nil, "overlay", "GameFontNormal")
				segmentButton.text = text
				text:SetText ("#" .. i)
				text:SetPoint ("CENTER")
				_detalhes.gump:SetFontColor (text, "silver")

				segmentButton:SetScript ("OnClick", function()
					OpenDetailsDeathRecapAtSegment (i)
				end)
				tinsert (Details.DeathRecap.Segments, i, segmentButton)
			end
		end

		for i = 1, 10 do
			Details.DeathRecap.Lines [i]:Hide()
		end

		--segment to use
		local death = _detalhes.tabela_vigente.last_events_tables

		--see if this segment has a death for the player
		local foundPlayer = false
		for index = #death, 1, -1 do
			if (death [index] [3] == _detalhes.playername) then
				foundPlayer = true
				break
			end
		end

		--in case a combat has been created after the player death, the death won't be at the current segment
		if (not foundPlayer) then
			local segmentHistory = _detalhes:GetCombatSegments()
			for i = 1, 2 do
				local segment = segmentHistory [1]
				if (segment and segment ~= _detalhes.tabela_vigente) then
					if (_detalhes.tabela_vigente.start_time - 3 < segment.end_time) then
						death = segment.last_events_tables
					end
				end
			end
		end

		--segments
		if (_detalhes.death_recap.show_segments) then
			local buttonsInUse = {}
			for i, button in ipairs (Details.DeathRecap.Segments) do
				if (_detalhes.tabela_historico.tabelas [i]) then
					button:Show()
					buttonsInUse[#buttonsInUse+1] = button
					_detalhes.gump:SetFontColor (button.text, "silver")
				else
					button:Hide()
				end
			end

			local buttonsInUse2 = {}
			for i = #buttonsInUse, 1, -1 do
				buttonsInUse2[#buttonsInUse2+1] = buttonsInUse[i]
			end
			for i = 1, #buttonsInUse2 do
				local button = buttonsInUse2 [i]
				button:ClearAndSetPoint ("TOPRIGHT", DeathRecapFrame, "TOPRIGHT", (-i * 22) - 10, -5)
			end

			if (not segment) then
				_detalhes.gump:SetFontColor (Details.DeathRecap.Segments [1].text, "orange")
			else
				_detalhes.gump:SetFontColor (Details.DeathRecap.Segments [segment].text, "orange")
				death = _detalhes.tabela_historico.tabelas [segment] and _detalhes.tabela_historico.tabelas [segment].last_events_tables
			end

		else
			for i, button in ipairs (Details.DeathRecap.Segments) do
				button:Hide()
			end
		end

		--if couldn't find the requested log from details!, so, import the log from the blizzard death recap
		--or if the player cliced on the chat link for the recap
		local ArtificialDeathLog
		if (not death or RecapID) then
			if (segment) then
				--nop, the player requested a death log from details it self but the log does not exists
				DeathRecapFrame.Unavailable:Show()
				return
			end

			--get the death events from the blizzard's recap
			ArtificialDeathLog = _detalhes.BuildDeathTableFromRecap (RecapID)
		end

		DeathRecapFrame.Unavailable:Hide()

		--get the relevance config
		local relevanceTime = _detalhes.death_recap.relevance_time

		local t
		if (ArtificialDeathLog) then
			t = ArtificialDeathLog
		else
			for index = #death, 1, -1 do
				if (death [index] [3] == _detalhes.playername) then
					t = death [index]
					break
				end
			end
		end

		if (t) then
			local events = t [1]
			local timeOfDeath = t [2]

			local BiggestDamageHits = {}
			for i = #events, 1, -1 do
				BiggestDamageHits[#BiggestDamageHits+1] = events[i]
			end
			table.sort (BiggestDamageHits, function (t1, t2)
				return t1[3] > t2[3]
			end)
			for i = #BiggestDamageHits, 1, -1 do
				if (BiggestDamageHits [i][4] + relevanceTime < timeOfDeath) then
					tremove (BiggestDamageHits, i)
				end
			end

			--verifica se o evento que matou o jogador esta na lista, se nao, adiciona no primeiro index do BiggestDamageHits
			local hitKill
			for i = #events, 1, -1 do
				local event = events [i]
				local evType = event [1]
				if (type (evType) == "boolean" and evType) then
					hitKill = event
					break
				end
			end
			if (hitKill) then
				local haveHitKill = false
				for index, t in ipairs (BiggestDamageHits) do
					if (t == hitKill) then
						haveHitKill = true
						break
					end
				end
				if (not haveHitKill) then
					tinsert (BiggestDamageHits, 1, hitKill)
				end
			end

			--tem menos que 10 eventos com grande dano dentro dos ultimos 5 segundos
			--precisa preencher com danos pequenos

			--print ("1 BiggestDamageHits:", #BiggestDamageHits)

			if (#BiggestDamageHits < 10) then
				for i = #events, 1, -1 do
					local event = events [i]
					local evType = event [1]
					if (type (evType) == "boolean" and evType) then
						local alreadyHave = false
						for index, t in ipairs (BiggestDamageHits) do
							if (t == event) then
								alreadyHave = true
								break
							end
						end
						if (not alreadyHave) then
							BiggestDamageHits[#BiggestDamageHits+1] = event
							if (#BiggestDamageHits == 10) then
								break
							end
						end
					end
				end
			else
				--encurta a tabela em no maximo 10 eventos
				while (#BiggestDamageHits > 10) do
					tremove (BiggestDamageHits, 11)
				end
			end

			if (#BiggestDamageHits == 0) then
				if (not fromChat) then
					_detalhes.GetDeathRecapFromChat()
					return
				end
			end

			table.sort (BiggestDamageHits, function (t1, t2)
				return t1[4] > t2[4]
			end)

			local events = BiggestDamageHits

			local maxHP = t [5]
			local lineIndex = 10

			--for i = #events, 1, -1 do
			for i, event in ipairs (events) do
				local event = events [i]

				local evType = event [1]
				local hp = min (floor (event [5] / maxHP * 100), 100)
				local spellName, _, spellIcon = _detalhes.GetSpellInfo (event [2])
				local amount = event [3]
				local eventTime = event [4]
				local source = event [6]

				local customSpellInfo = event [11]

				--print ("3 loop", i, type (evType), evType)

				if (type (evType) == "boolean" and evType) then

					local line = Details.DeathRecap.Lines [lineIndex]
					--print ("4 loop", i, line)
					if (line) then
						line.timeAt:SetText (format ("%.1f", eventTime - timeOfDeath) .. "s")
						line.spellIcon:SetTexture (spellIcon or customSpellInfo and customSpellInfo [3] or "")
						line.TopFader:Hide()
						--line.spellIcon:SetTexCoord (.1, .9, .1, .9)
						--line.sourceName:SetText ("|cFFC6B0D9" .. source .. "|r")

						--parse source and cut the length of the string after setting the spellname and source
						local sourceClass = _detalhes:GetClass (source)
						local sourceSpec = _detalhes:GetSpec (source)

						if (not sourceClass) then
							local combat = Details:GetCurrentCombat()
							if (combat) then
								local sourceActor = combat:GetActor (1, source)
								if (sourceActor) then
									sourceClass = sourceActor.classe
								end
							end
						end

						if (not sourceSpec) then
							local combat = Details:GetCurrentCombat()
							if (combat) then
								local sourceActor = combat:GetActor (1, source)
								if (sourceActor) then
									sourceSpec = sourceActor.spec
								end
							end
						end

						--> remove real name or owner name
						source = _detalhes:GetOnlyName (source)
						--> remove owner name
						source = source:gsub ((" <.*"), "")

						--> if a player?
						if (_detalhes.player_class [sourceClass]) then
							source = _detalhes:AddClassOrSpecIcon (source, sourceClass, sourceSpec, 16, true)

						elseif (sourceClass == "PET") then
							source = _detalhes:AddClassOrSpecIcon (source, sourceClass)

						end

						--> remove the dot signal from the spell name
						if (not spellName) then
							spellName = customSpellInfo and customSpellInfo [2] or "*?*"
							if (spellName:find (STRING_ENVIRONMENTAL_DAMAGE_FALLING)) then
								if (UnitName ("player") == "Elphaba") then
									spellName = "Gravity Won!, Elphaba..."
									source = ""
								else
									source = "Gravity"
								end
								--/run for a,b in pairs (_G) do if (type (b)=="string" and b:find ("Falling")) then print (a,b) end end
							end
						end

						spellName = spellName:gsub (L["STRING_DOT"], "")
						spellName = spellName:gsub ("[*] ", "")
						--print ("link.lua", L["STRING_DOT"], spellName, spellName:find (L["STRING_DOT"]), spellName:gsub (L["STRING_DOT"], ""))
						source = source or ""

						line.sourceName:SetText (spellName .. " (" .. "|cFFC6B0D9" .. source .. "|r" .. ")")
						DetailsFramework:TruncateText (line.sourceName, 185)

						if (amount > 1000) then
							--line.amount:SetText ("-" .. _detalhes:ToK (amount))
							line.amount:SetText ("-" .. amount)
						else
							line.amount:SetText ("-" .. floor (amount))
						end

						line.lifePercent:SetText (hp .. "%")
						line.spellid = event [2]

						line:Show()

						if (_detalhes.death_recap.show_life_percent) then
							line.lifePercent:Show()
							line.amount:SetPoint ("LEFT", line, "LEFT", 240, 0)
							line.lifePercent:SetPoint ("LEFT", line, "LEFT", 320, 0)
						else
							line.lifePercent:Hide()
							line.amount:SetPoint ("LEFT", line, "LEFT", 280, 0)
							--line.lifePercent:SetPoint ("LEFT", line, "LEFT", 320, 0)
						end
					end

					lineIndex = lineIndex - 1
				end
			end

			local lastLine = Details.DeathRecap.Lines [lineIndex + 1]
			if (lastLine) then
				lastLine.TopFader:Show()
			end

			DeathRecapFrame.Unavailable:Hide()
		else
			if (not fromChat) then
				_detalhes.GetDeathRecapFromChat()
			end
		end

end


hooksecurefunc(DeathRecapFrame, "OpenRecap", function(self, recapID)
	if self:IsShown() then
		_detalhes.OpenDetailsDeathRecap(nil, recapID)
	end
end)




------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> general macros

function _detalhes:OpenPlayerDetails (window)

	window = window or 1

	local instance = _detalhes:GetInstance (window)
	if (instance) then
		local display, subDisplay = instance:GetDisplay()
		if (display == 1) then
			instance:AbreJanelaInfo (Details:GetPlayer (false, 1))
		elseif (display == 2) then
			instance:AbreJanelaInfo (Details:GetPlayer (false, 2))
		end
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> extra buttons at the death options (release, death recap)

local detailsOnDeathMenu = CreateFrame ("Frame", "DetailsOnDeathMenu", UIParent)
detailsOnDeathMenu:SetHeight (30)

detailsOnDeathMenu:RegisterEvent ("PLAYER_REGEN_ENABLED")
DetailsFramework:ApplyStandardBackdrop (detailsOnDeathMenu)
detailsOnDeathMenu:SetAlpha (0.75)

--disable text
detailsOnDeathMenu.disableLabel = _detalhes.gump:CreateLabel (detailsOnDeathMenu, "you can disable this at /details > Raid Tools", 9)

detailsOnDeathMenu.warningLabel = _detalhes.gump:CreateLabel (detailsOnDeathMenu, "", 11)
detailsOnDeathMenu.warningLabel.textcolor = "red"
detailsOnDeathMenu.warningLabel:SetPoint ("BOTTOMLEFT", detailsOnDeathMenu, "BOTTOMLEFT", 5, 2)
detailsOnDeathMenu.warningLabel:Hide()

detailsOnDeathMenu:SetScript ("OnEvent", function (self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then --event == "ENCOUNTER_END" or
		C_Timer:After (0.5, detailsOnDeathMenu.ShowPanel)
	end
end)

function detailsOnDeathMenu.OpenEncounterBreakdown()
	if (not _detalhes:GetPlugin ("DETAILS_PLUGIN_ENCOUNTER_DETAILS")) then
		detailsOnDeathMenu.warningLabel.text = "Encounter Breakdown plugin is disabled! Please enable it in the Addon Control Panel."
		detailsOnDeathMenu.warningLabel:Show()
		C_Timer:After (5, function()
			detailsOnDeathMenu.warningLabel:Hide()
		end)
	end

	Details:OpenPlugin ("Encounter Breakdown")

	GameCooltip2:Hide()
end

function detailsOnDeathMenu.OpenPlayerEndurance()
	if (not _detalhes:GetPlugin ("DETAILS_PLUGIN_DEATH_GRAPHICS")) then
		detailsOnDeathMenu.warningLabel.text = "Advanced Death Logs plugin is disabled! Please enable it (or download) in the Addon Control Panel."
		detailsOnDeathMenu.warningLabel:Show()
		C_Timer:After (5, function()
			detailsOnDeathMenu.warningLabel:Hide()
		end)
	end

	DetailsPluginContainerWindow.OnMenuClick (nil, nil, "DETAILS_PLUGIN_DEATH_GRAPHICS", true)

	C_Timer:After (0, function()
		local a = Details_DeathGraphsModeEnduranceButton and Details_DeathGraphsModeEnduranceButton.MyObject:Click()
	end)

	GameCooltip2:Hide()
end

function detailsOnDeathMenu.OpenPlayerSpells()

	local window1 = Details:GetWindow (1)
	local window2 = Details:GetWindow (2)
	local window3 = Details:GetWindow (3)
	local window4 = Details:GetWindow (4)

	local assignedRole = UnitGroupRolesAssigned ("player")
	if (assignedRole == "HEALER") then
		if (window1 and window1:GetDisplay() == 2) then
			Details:OpenPlayerDetails(1)

		elseif (window2 and window2:GetDisplay() == 2) then
			Details:OpenPlayerDetails(2)

		elseif (window3 and window3:GetDisplay() == 2) then
			Details:OpenPlayerDetails(3)

		elseif (window4 and window4:GetDisplay() == 2) then
			Details:OpenPlayerDetails(4)

		else
			Details:OpenPlayerDetails (1)
		end
	else
		if (window1 and window1:GetDisplay() == 1) then
			Details:OpenPlayerDetails(1)

		elseif (window2 and window2:GetDisplay() == 1) then
			Details:OpenPlayerDetails(2)

		elseif (window3 and window3:GetDisplay() == 1) then
			Details:OpenPlayerDetails(3)

		elseif (window4 and window4:GetDisplay() == 1) then
			Details:OpenPlayerDetails(4)

		else
			Details:OpenPlayerDetails (1)
		end
	end

	GameCooltip2:Hide()
end

--encounter breakdown button
detailsOnDeathMenu.breakdownButton = _detalhes.gump:CreateButton (detailsOnDeathMenu, detailsOnDeathMenu.OpenEncounterBreakdown, 120, 20, "Encounter Breakdown", "breakdownButton")
detailsOnDeathMenu.breakdownButton:SetTemplate (_detalhes.gump:GetTemplate ("button", "DETAILS_PLUGINPANEL_BUTTON_TEMPLATE"))
detailsOnDeathMenu.breakdownButton:SetPoint ("TOPLEFT", detailsOnDeathMenu, "TOPLEFT", 5, -5)
detailsOnDeathMenu.breakdownButton:Hide()

local on_death_button_options = function()
	GameCooltip:SetOption ("MyAnchor", "TOP")
	GameCooltip:SetOption ("RelativeAnchor", "BOTTOM")
	GameCooltip:SetOption ("WidthAnchorMod", 0)
	GameCooltip:SetOption ("HeightAnchorMod", -13)
	GameCooltip:SetOption ("TextSize", 10)
	GameCooltip:SetOption ("FixedWidth", 220)
end

detailsOnDeathMenu.breakdownButton.CoolTip = {
	Type = "tooltip",
	BuildFunc = function()
		GameCooltip2:Preset (2)
		GameCooltip2:AddLine ("Show a panel with:")
		GameCooltip2:AddLine ("- Player Damage Taken")
		GameCooltip2:AddLine ("- Damage Taken by Spell")
		GameCooltip2:AddLine ("- Enemy Damage Taken")
		GameCooltip2:AddLine ("- Player Deaths")
		GameCooltip2:AddLine ("- Interrupts and Dispells")
		GameCooltip2:AddLine ("- Damage Done Chart")
		GameCooltip2:AddLine ("- Damage Per Phase")
		GameCooltip2:AddLine ("- Weakauras Tool")

		if (not _detalhes:GetPlugin ("DETAILS_PLUGIN_ENCOUNTER_DETAILS")) then
			GameCooltip2:AddLine ("Encounter Breakdown plugin is disabled in the Addon Control Panel.", "", 1, "red")
		end

	end, --> called when user mouse over the frame
	FixedValue = "none",
	ShowSpeed = .5,
	Options = on_death_button_options,
}
GameCooltip2:CoolTipInject (detailsOnDeathMenu.breakdownButton)

--player endurance button
detailsOnDeathMenu.enduranceButton = _detalhes.gump:CreateButton (detailsOnDeathMenu, detailsOnDeathMenu.OpenPlayerEndurance, 120, 20, "Player Endurance", "enduranceButton")
detailsOnDeathMenu.enduranceButton:SetTemplate (_detalhes.gump:GetTemplate ("button", "DETAILS_PLUGINPANEL_BUTTON_TEMPLATE"))
detailsOnDeathMenu.enduranceButton:SetPoint ("TOPLEFT", detailsOnDeathMenu.breakdownButton, "TOPRIGHT", 2, 0)
detailsOnDeathMenu.enduranceButton:Hide()

detailsOnDeathMenu.enduranceButton.CoolTip = {
	Type = "tooltip",
	BuildFunc = function()
		GameCooltip2:Preset (2)
		GameCooltip2:AddLine ("Open Player Endurance Breakdown")
		GameCooltip2:AddLine ("")
		GameCooltip2:AddLine ("Player endurance is calculated using the amount of player deaths.")
		GameCooltip2:AddLine ("By default the plugin register the three first player deaths on each encounter to calculate who is under performing.")

		--GameCooltip2:AddLine (" ")

		if (not _detalhes:GetPlugin ("DETAILS_PLUGIN_DEATH_GRAPHICS")) then
			GameCooltip2:AddLine ("Advanced Death Logs plugin is disabled or not installed, check the Addon Control Panel or download it from the Twitch APP.", "", 1, "red")
		end

	end, --> called when user mouse over the frame
	FixedValue = "none",
	ShowSpeed = .5,
	Options = on_death_button_options,
}
GameCooltip2:CoolTipInject (detailsOnDeathMenu.enduranceButton)

--spells
detailsOnDeathMenu.spellsButton = _detalhes.gump:CreateButton (detailsOnDeathMenu, detailsOnDeathMenu.OpenPlayerSpells, 48, 20, "Spells", "SpellsButton")
detailsOnDeathMenu.spellsButton:SetTemplate (_detalhes.gump:GetTemplate ("button", "DETAILS_PLUGINPANEL_BUTTON_TEMPLATE"))
detailsOnDeathMenu.spellsButton:SetPoint ("TOPLEFT", detailsOnDeathMenu.enduranceButton, "TOPRIGHT", 2, 0)
detailsOnDeathMenu.spellsButton:Hide()

detailsOnDeathMenu.spellsButton.CoolTip = {
	Type = "tooltip",
	BuildFunc = function()
		GameCooltip2:Preset (2)
		GameCooltip2:AddLine ("Open your player Details! breakdown.")

	end, --> called when user mouse over the frame
	FixedValue = "none",
	ShowSpeed = .5,
	Options = on_death_button_options,
}
GameCooltip2:CoolTipInject (detailsOnDeathMenu.spellsButton)

function detailsOnDeathMenu.CanShowPanel()
	if (StaticPopup_Visible ("DEATH")) then
		if (not _detalhes.on_death_menu) then
			return
		end

		--> check if the player just wiped in an encounter
		if (IsInRaid()) then
			local isInInstance = IsInInstance()
			if (isInInstance) then
				if (_detalhes.in_combat or _detalhes:IsGroupInCombat()) then
					C_Timer:After (0.5, detailsOnDeathMenu.ShowPanel)
					return false
				end

				return true
			end
		end
	end
end

function detailsOnDeathMenu.ShowPanel()
	if (not detailsOnDeathMenu.CanShowPanel()) then
		return
	end

	if (ElvUI) then
		detailsOnDeathMenu:SetPoint ("TOPLEFT", StaticPopup1, "BOTTOMLEFT", 0, -1)
		detailsOnDeathMenu:SetPoint ("TOPRIGHT", StaticPopup1, "BOTTOMRIGHT", 0, -1)
	else
		detailsOnDeathMenu:SetPoint ("TOPLEFT", StaticPopup1, "BOTTOMLEFT", 4, 2)
		detailsOnDeathMenu:SetPoint ("TOPRIGHT", StaticPopup1, "BOTTOMRIGHT", -4, 2)
	end

	detailsOnDeathMenu.breakdownButton:Show()
	detailsOnDeathMenu.enduranceButton:Show()
	detailsOnDeathMenu.spellsButton:Show()

	detailsOnDeathMenu:Show()

	detailsOnDeathMenu:SetHeight (30)

	if (not _detalhes:GetTutorialCVar ("DISABLE_ONDEATH_PANEL")) then
		detailsOnDeathMenu.disableLabel:Show()
		detailsOnDeathMenu.disableLabel:SetPoint ("BOTTOMLEFT", detailsOnDeathMenu, "BOTTOMLEFT", 5, 1)
		detailsOnDeathMenu.disableLabel.color = "gray"
		detailsOnDeathMenu.disableLabel.alpha = 0.5
		detailsOnDeathMenu:SetHeight (detailsOnDeathMenu:GetHeight() + 10)

		if (math.random (1, 3) == 3) then
			_detalhes:SetTutorialCVar ("DISABLE_ONDEATH_PANEL", true)
		end
	end
end

hooksecurefunc ("StaticPopup_Hide", function (which, data)
	if (which == "DEATH") then
		detailsOnDeathMenu:Hide()
	end
end)



--endd
