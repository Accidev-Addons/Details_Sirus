
local UnitGroupRolesAssigned = DetailsFramework.UnitGroupRolesAssigned

--> check unloaded files:
if (
	not _G._detalhes.atributo_custom.damagedoneTooltip or
	not _G._detalhes.atributo_custom.healdoneTooltip
	) then

	local f = CreateFrame ("Frame", "DetaisCorruptInstall", UIParent)
	f:SetSize (370, 70)
	f:SetPoint ("CENTER", UIParent, "CENTER", 0, 0)
	f:SetPoint ("TOP", UIParent, "TOP", 0, -20)
	local bg = f:CreateTexture (nil, "background")
	bg:SetAllPoints (f)
	bg:SetTexture ([[Interface\AddOns\Details\images\welcome]])

	local image = f:CreateTexture (nil, "overlay")
	image:SetTexture ([[Interface\AddOns\Details\textures\DialogFrame\UI-Dialog-Icon-AlertNew]])
	image:SetSize (32, 32)

	local label = f:CreateFontString (nil, "overlay", "GameFontNormal")
	label:SetText ("Restart game client in order to finish addons updates.")
	label:SetWidth (300)
	label:SetJustifyH ("LEFT")

	local close = CreateFrame ("button", "DetaisCorruptInstall", f, "UIPanelCloseButton")
	close:SetSize (32, 32)
	close:SetPoint ("TOPRIGHT", f, "TOPRIGHT", 0, 0)

	image:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -20)
	label:SetPoint ("LEFT", image, "RIGHT", 4, 0)

	_G._detalhes.FILEBROKEN = true
end

function _G._detalhes:InstallOkey()
	if (_G._detalhes.FILEBROKEN) then
		return false
	end
	return true
end

--> start funtion
function _G._detalhes:Start()

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> row single click

	--> single click row function replace
		--damage, dps, damage taken, friendly fire
			self.row_singleclick_overwrite [1] = {true, true, true, true, self.atributo_damage.ReportSingleFragsLine, self.atributo_damage.ReportEnemyDamageTaken, self.atributo_damage.ReportSingleVoidZoneLine, self.atributo_damage.ReportSingleDTBSLine}
		--healing, hps, overheal, healing taken
			self.row_singleclick_overwrite [2] = {true, true, true, true, false, self.atributo_heal.ReportSingleDamagePreventedLine}
		--mana, rage, energy, runepower
			self.row_singleclick_overwrite [3] = {true, true, true, true}
		--cc breaks, ress, interrupts, dispells, deaths
			self.row_singleclick_overwrite [4] = {true, true, true, true, self.atributo_misc.ReportSingleDeadLine, self.atributo_misc.ReportSingleCooldownLine, self.atributo_misc.ReportSingleBuffUptimeLine, self.atributo_misc.ReportSingleDebuffUptimeLine}

		function self:ReplaceRowSingleClickFunction (attribute, sub_attribute, func)
			assert (type (attribute) == "number" and attribute >= 1 and attribute <= 4, "ReplaceRowSingleClickFunction expects a attribute index on #1 argument.")
			assert (type (sub_attribute) == "number" and sub_attribute >= 1 and sub_attribute <= 10, "ReplaceRowSingleClickFunction expects a sub attribute index on #2 argument.")
			assert (type (func) == "function", "ReplaceRowSingleClickFunction expects a function on #3 argument.")

			self.row_singleclick_overwrite [attribute] [sub_attribute] = func
			return true
		end

		self.click_to_report_color = {1, 0.8, 0, 1}

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> initialize

	--> build frames

		--> plugin container
			self:CreatePluginWindowContainer()
			self:InitializeForge() --to install into the container plugin
			self:InitializeRaidHistoryWindow()
			self:InitializeOptionsWindow()

			C_Timer:After (2, function()
				self:InitializeAuraCreationWindow()
			end)

			self:InitializeCustomDisplayWindow()
			self:InitializeAPIWindow()
			self:InitializeRunCodeWindow()
			self:InitializeMacrosWindow()

		--> custom window
			self.custom = self.custom or {}

		--> actor details window
			self.janela_info = self.gump:CriaJanelaInfo()
			self.gump:Fade (self.janela_info, 1)

		--> copy and paste window
			self:CreateCopyPasteWindow()
			self.CreateCopyPasteWindow = nil

	--> start instances
		if (self:GetNumInstancesAmount() == 0) then
			self:CriarInstancia()
		end
		self:GetLowerInstanceNumber()

	--> start time machine
		self.timeMachine:Ligar()

	--> update abbreviation shortcut

		self:UpdateToKFunctions()

	--> start instances updater

		self:CheckSwitchOnLogon()

		function _detalhes:ScheduledWindowUpdate (forced)
			if (not forced and _detalhes.in_combat) then
				return
			end
			_detalhes.scheduled_window_update = nil
			_detalhes:AtualizaGumpPrincipal (-1, true)
		end
		function _detalhes:ScheduleWindowUpdate (time, forced)
			if (_detalhes.scheduled_window_update) then
				_detalhes:CancelTimer (_detalhes.scheduled_window_update)
				_detalhes.scheduled_window_update = nil
			end
			_detalhes.scheduled_window_update = _detalhes:ScheduleTimer ("ScheduledWindowUpdate", time or 1, forced)
		end

		self:AtualizaGumpPrincipal (-1, true)
		_detalhes:RefreshUpdater()

		for index = 1, #self.tabela_instancias do
			local instance = self.tabela_instancias [index]
			if (instance:IsAtiva()) then
				self:ScheduleTimer ("RefreshBars", 1, instance)
				self:ScheduleTimer ("InstanceReset", 1, instance)
				self:ScheduleTimer ("InstanceRefreshRows", 1, instance)
			end
		end

		function self:RefreshAfterStartup()

			self:AtualizaGumpPrincipal (-1, true)

			local lower_instance = _detalhes:GetLowerInstanceNumber()

			for index = 1, #self.tabela_instancias do
				local instance = self.tabela_instancias [index]
				if (instance:IsAtiva()) then
					--> refresh wallpaper
					if (instance.wallpaper.enabled) then
						instance:InstanceWallpaper (true)
					else
						instance:InstanceWallpaper (false)
					end

					--> refresh desaturated icons if is lower instance
					if (index == lower_instance) then
						instance:DesaturateMenu()

						instance:SetAutoHideMenu (nil, nil, true)
					end

				end
			end

			--> refresh lower instance plugin icons and skin
			_detalhes.ToolBar:ReorganizeIcons()
			--> refresh skin for other windows
			if (lower_instance) then
				for i = lower_instance+1, #self.tabela_instancias do
					local instance = self:GetInstance (i)
					if (instance and instance.baseframe and instance.ativa) then
						instance:ChangeSkin()
					end
				end
			end

			self.RefreshAfterStartup = nil

			function _detalhes:CheckWallpaperAfterStartup()

				if (not _detalhes.profile_loaded) then
					return _detalhes:ScheduleTimer ("CheckWallpaperAfterStartup", 2)
				end

				for i = 1, self.instances_amount do
					local instance = self:GetInstance (i)
					if (instance and instance:IsEnabled()) then
						if (not instance.wallpaper.enabled) then
							instance:InstanceWallpaper (false)
						end

						instance.do_not_snap = true
						self.move_janela_func (instance.baseframe, true, instance, true)
						self.move_janela_func (instance.baseframe, false, instance, true)
						instance.do_not_snap = false
					end
				end
				self.CheckWallpaperAfterStartup = nil
				_detalhes.profile_loaded = nil

			end

			_detalhes:ScheduleTimer ("CheckWallpaperAfterStartup", 5)

		end
		self:ScheduleTimer ("RefreshAfterStartup", 5)


	--> start garbage collector

		self.ultima_coleta = 0
		self.intervalo_coleta = 720
		self:ScheduleRepeatingTimer ("IniciarColetaDeLixo", self.intervalo_coleta)

	--> role
		self.last_assigned_role = UnitGroupRolesAssigned ("player")

	--> start parser

		--> load parser capture options
			self:CaptureRefresh()
		--> register parser events
			FrameUtil.RegisterFrameForEvents(self.listener, {
				"PLAYER_REGEN_DISABLED",
				"PLAYER_REGEN_ENABLED",
				"UNIT_PET",
				"PARTY_MEMBERS_CHANGED",
				"RAID_ROSTER_UPDATE",
				"ZONE_CHANGED_NEW_AREA",
				"PLAYER_ENTERING_WORLD",
				"ENCOUNTER_START",
				"ENCOUNTER_END",
				"CHAT_MSG_MONSTER_YELL",
				"CHAT_MSG_BG_SYSTEM_NEUTRAL",
				"UNIT_NAME_UPDATE",
				"PLAYER_ROLES_ASSIGNED",
				"ACTIVE_TALENT_GROUP_CHANGED",
				"PLAYER_TALENT_UPDATE",
			})

			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

			self.parser_frame:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")

	--> group
		self.in_group = IsInGroup() or IsInRaid()

	--> done
		self.initializing = nil

	--> scan pets
		_detalhes:SchedulePetUpdate (1)

	--> send messages gathered on initialization
		self:ScheduleTimer ("ShowDelayMsg", 10)

	--> send instance open signal
		for index, instancia in _detalhes:ListInstances() do
			if (instancia.ativa) then
				self:SendEvent ("DETAILS_INSTANCE_OPEN", nil, instancia)
			end
		end

	--> send details startup done signal
		function self:AnnounceStartup()

			self:SendEvent ("DETAILS_STARTED", "SEND_TO_ALL")

			if (_detalhes.in_group) then
				_detalhes:SendEvent ("GROUP_ONENTER")
			else
				_detalhes:SendEvent ("GROUP_ONLEAVE")
			end

			_detalhes.last_zone_type = "INIT"
			_detalhes.parser_functions:ZONE_CHANGED_NEW_AREA()

			_detalhes.AnnounceStartup = nil

		end
		self:ScheduleTimer ("AnnounceStartup", 5)

		if (_detalhes.failed_to_load) then
			_detalhes:CancelTimer (_detalhes.failed_to_load)
			_detalhes.failed_to_load = nil
		end

	--> restore cooltip anchor position
		DetailsTooltipAnchor:Restore()

	--> check is this is the first run
		if (self.is_first_run) then
			if (#self.custom == 0) then
				_detalhes:AddDefaultCustomDisplays()
			end

			_detalhes:FillUserCustomSpells()
		end

	--> check is this is the first run of this version
		if (self.is_version_first_run) then
			_detalhes:FillUserCustomSpells()
			_detalhes:AddDefaultCustomDisplays()

			end

	local lower = _detalhes:GetLowerInstanceNumber()
	if (lower) then
		local instance = _detalhes:GetInstance (lower)
		if (instance) then

			self.gump:Fade (instance._version, 0)
			instance._version:SetText ("Details! " .. _detalhes.userversion .. " (core " .. self.realversion .. ")")
			instance._version:SetTextColor (1, 1, 1, .35)
			instance._version:SetPoint ("BOTTOMLEFT", instance.baseframe, "BOTTOMLEFT", 5, 1)

			if (instance.auto_switch_to_old) then
				instance:SwitchBack()
			end

			function _detalhes:FadeStartVersion()
				self.gump:Fade (instance._version, "in", 2)

				if (_detalhes.switch.table) then

					local have_bookmark

					for index, t in ipairs (_detalhes.switch.table) do
						if (t.atributo) then
							have_bookmark = true
							break
						end
					end

					if (not have_bookmark) then
						function _detalhes:WarningAddBookmark()
							instance._version:SetText ("right click to set bookmarks.")
							self.gump:Fade (instance._version, "out", 1)
							function _detalhes:FadeBookmarkWarning()
								self.gump:Fade (instance._version, "in", 2)
							end
							_detalhes:ScheduleTimer ("FadeBookmarkWarning", 5)
						end
						_detalhes:ScheduleTimer ("WarningAddBookmark", 2)
					end
				end

			end

			_detalhes:ScheduleTimer ("FadeStartVersion", 12)

		end
	end

	--> minimap
	pcall (_detalhes.RegisterMinimap, _detalhes)

	--> open profiler
	_detalhes:OpenProfiler()

	--> start announcers
	_detalhes:StartAnnouncers()

	--> open welcome
	if (self.is_first_run) then
		C_Timer:After (1, function() --wait details full load the rest of the systems before executing the welcome window
			_detalhes:OpenWelcomeWindow()
		end)
	end

	--> load broadcaster tools
	_detalhes:LoadFramesForBroadcastTools()

	_detalhes:BrokerTick()

	--boss mobs callbacks
	_detalhes:ScheduleTimer ("BossModsLink", 5)

	--> limit item level life for 24Hs
	local now = time()
	for guid, t in pairs (_detalhes.item_level_pool) do
		if (t.time+86400 < now) then
			_detalhes.item_level_pool [guid] = nil
		end
	end

	--> dailly reset of the cache for talents and specs.
	local today = date ("%d")
	if (_detalhes.last_day ~= today) then
		wipe (_detalhes.cached_specs)
		wipe (_detalhes.cached_talents)
	end

	--> get the player spec
	C_Timer:After (2, _detalhes.parser_functions.ACTIVE_TALENT_GROUP_CHANGED)

	_detalhes.chat_embed:CheckChatEmbed (true)


	_detalhes.AddOnStartTime = GetTime()

	--> auto run scripts
		local codeTable = _detalhes.run_code
		_detalhes.AutoRunCode = {}

		local functionFilter = _detalhes:CreateScriptEnvironment()

		--> compile and store code
		function _detalhes:RecompileAutoRunCode()
			for codeKey, code in pairs (codeTable) do
				local func, errorText = loadstring (code)
				if (func) then
					setfenv (func, functionFilter)
					_detalhes.AutoRunCode [codeKey] = func
				else
					--> if the code didn't pass, create a dummy function for it without triggering errors
					_detalhes.AutoRunCode [codeKey] = function() end
				end
			end
		end

		_detalhes:RecompileAutoRunCode()

		--> function to dispatch events
		function _detalhes:DispatchAutoRunCode (codeKey)
			local func = _detalhes.AutoRunCode [codeKey]
			_detalhes.gump:QuickDispatch (func)
		end

		--> auto run frame to dispatch scrtips for some events that details! doesn't handle
		local auto_run_code_dispatch = CreateFrame ("Frame")

		auto_run_code_dispatch:RegisterEvent ("ACTIVE_TALENT_GROUP_CHANGED")

		auto_run_code_dispatch.OnEventFunc = function (self, event)
			--> ignore events triggered more than once in a small time window
			if (auto_run_code_dispatch [event] and not auto_run_code_dispatch [event]._cancelled) then
				return
			end

			if (event == "ACTIVE_TALENT_GROUP_CHANGED") then
				--> create a trigger for the event, many times it is triggered more than once
				--> so if the event is triggered a second time, it will be ignored
				local newTimer = C_Timer:NewTicker (1, function()
					_detalhes:DispatchAutoRunCode ("on_specchanged")

					--> clear and invalidate the timer
					auto_run_code_dispatch [event]:Cancel()
					auto_run_code_dispatch [event] = nil
				end, 1)

				--> store the trigger
				auto_run_code_dispatch [event] = newTimer
			end
		end

		auto_run_code_dispatch:SetScript ("OnEvent", auto_run_code_dispatch.OnEventFunc)

		--> dispatch scripts at startup
		C_Timer:After (2, function()
			_detalhes:DispatchAutoRunCode ("on_init")
			_detalhes:DispatchAutoRunCode ("on_specchanged")
			_detalhes:DispatchAutoRunCode ("on_zonechanged")

			if (InCombatLockdown()) then
				_detalhes:DispatchAutoRunCode ("on_entercombat")
			else
				_detalhes:DispatchAutoRunCode ("on_leavecombat")
			end

			_detalhes:DispatchAutoRunCode ("on_groupchange")
		end)

end