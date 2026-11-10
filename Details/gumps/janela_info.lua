--errors ~pet

local _detalhes = 		_G._detalhes
local Loc = LibStub ("AceLocale-3.0"):GetLocale ( "Details" )
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

local gump = 			_detalhes.gump
local _
--lua locals
--local _string_len = string.len
local _math_floor = math.floor
local _ipairs = ipairs
local _pairs = pairs
local _type = type
local _table_sort = table.sort
--api locals
local _CreateFrame = CreateFrame
local _GetTime = GetTime
local _GetSpellInfo = _detalhes.getspellinfo
local _GetCursorPosition = GetCursorPosition
local _unpack = unpack

local sub_atributos = _detalhes.sub_atributos

local info = _detalhes.janela_info
local container3_bars_pointFunc

local SummaryWidgets = {}
local CurrentTab = "Summary"
local IconTexCoord = {5/64, 59/64, 5/64, 59/64}

local CONST_BAR_HEIGHT = 20
local CONST_TARGET_HEIGHT = 18

local PLAYER_DETAILS_WINDOW_WIDTH = 890
local PLAYER_DETAILS_WINDOW_HEIGHT = 574

local PLAYER_DETAILS_STATUSBAR_HEIGHT = 20
local PLAYER_DETAILS_STATUSBAR_ALPHA = 1

local containerSettings = {
	spells = {
		width = 419,
		height = 290,
		point = {"TOPLEFT", DetailsPlayerDetailsWindow, "TOPLEFT", 2, -76},
		scrollHeight = 264,
	},
	targets = {
		width = 418,
		height = 150,
		point = {"BOTTOMLEFT", DetailsPlayerDetailsWindow, "BOTTOMLEFT", 2, 6 + PLAYER_DETAILS_STATUSBAR_HEIGHT},
	},
}

local spellInfoSettings = {
	width = 430,
	amount = 6,
}

_detalhes.player_details_tabs = {}
info.currentTabsInUse =  {}
------------------------------------------------------------------------------------------------------------------------------
--self = instancia
--jogador = classe_damage ou classe_heal

function Details:GetBreakdownTabsInUse()
	return info.currentTabsInUse
end

function Details:GetBreakdownTabByName(tabName, tablePool)
	tablePool = tablePool or _detalhes.player_details_tabs
	for index = 1, #tablePool do
		local tab = tablePool[index]
		if (tab.tabname == tabName) then
			return tab, index
		end
	end
end

--return the combat being used to show the data in the opened breakdown window
function Details:GetCombatFromBreakdownWindow()
	return info.instancia and info.instancia.showing
end

--return the window that requested to open the player breakdown window
function Details:GetActiveWindowFromBreakdownWindow()
	return info.instancia
end

--return if the breakdown window is showing damage or heal
function Details:GetDisplayTypeFromBreakdownWindow()
	return info.atributo, info.sub_atributo
end

--return the actor object in use by the breakdown window
function Details:GetPlayerObjectFromBreakdownWindow()
	return info.jogador
end

function Details:GetBreakdownWindow()
	return Details.janela_info
end

--english alias
--window object from Details:GetWindow(n) and playerObject from Details:GetPlayer(playerName, attribute)
function Details:OpenPlayerBreakdown (windowObject, playerObject)
	windowObject:AbreJanelaInfo (playerObject)
end

function _detalhes:AbreJanelaInfo (jogador, from_att_change, refresh, ShiftKeyDown, ControlKeyDown)

	if (not _detalhes.row_singleclick_overwrite [self.atributo] or not _detalhes.row_singleclick_overwrite [self.atributo][self.sub_atributo]) then
		_detalhes:FechaJanelaInfo()
		return
	elseif (_type (_detalhes.row_singleclick_overwrite [self.atributo][self.sub_atributo]) == "function") then
		if (from_att_change) then
			_detalhes:FechaJanelaInfo()
			return
		end
		return _detalhes.row_singleclick_overwrite [self.atributo][self.sub_atributo] (_, jogador, self, ShiftKeyDown, ControlKeyDown)
	end

	if (self.modo == _detalhes._detalhes_props["MODO_RAID"]) then
		_detalhes:FechaJanelaInfo()
		return
	end

	--> _detalhes.info_jogador armazena o jogador que esta sendo mostrado na janela de detalhes
	if (info.jogador and info.jogador == jogador and self and info.atributo and self.atributo == info.atributo and self.sub_atributo == info.sub_atributo and not refresh) then
		_detalhes:FechaJanelaInfo() --> se clicou na mesma barra ent�o fecha a janela de detalhes
		return
	elseif (not jogador) then
		_detalhes:FechaJanelaInfo()
		return
	end

	if (info.barras1) then
		for index, barra in _ipairs (info.barras1) do
			barra.other_actor = nil
		end
	end

	if (info.barras2) then
		for index, barra in _ipairs (info.barras2) do
			barra.icone:SetTexture (nil)
			barra.icone:SetTexCoord (0, 1, 0, 1)
		end
	end

	--> passar os par�metros para dentro da tabela da janela.

	info.ativo = true --> sinaliza o addon que a janela esta aberta
	info.atributo = self.atributo --> instancia.atributo -> grava o atributo (damage, heal, etc)
	info.sub_atributo = self.sub_atributo --> instancia.sub_atributo -> grava o sub atributo (damage done, dps, damage taken, etc)
	info.jogador = jogador --> de qual jogador (objeto classe_damage)
	info.instancia = self --> salva a refer�ncia da inst�ncia que pediu o info

	info.target_text = Loc ["STRING_TARGETS"] .. ":"
	info.target_persecond = false

	info.mostrando = nil

	local nome = info.jogador.nome --> nome do jogador
	local atributo_nome = sub_atributos[info.atributo].lista [info.sub_atributo] .. " " .. Loc ["STRING_ACTORFRAME_REPORTOF"] --> // nome do atributo // precisa ser o sub atributo correto???

	--> removendo o nome da realm do jogador
	if (nome:find ("-")) then
		nome = nome:gsub (("-.*"), "")
	end

	if (info.instancia.atributo == 1 and info.instancia.sub_atributo == 6) then --> enemy
		atributo_nome = sub_atributos [info.atributo].lista [1] .. " " .. Loc ["STRING_ACTORFRAME_REPORTOF"]
	end

	info.nome:SetText (nome)
	info.atributo_nome:SetText (atributo_nome)

	local serial = jogador.serial
	local avatar
	if (serial ~= "") then
		avatar = NickTag:GetNicknameTable (serial)

	end

	if (avatar and avatar [1]) then
		info.nome:SetText ((not _detalhes.ignore_nicktag and avatar [1]) or nome)
	end

	if (avatar and avatar [2]) then

		info.avatar:SetTexture (avatar [2])
		info.avatar_bg:SetTexture (avatar [4])
		if (avatar [5]) then
			info.avatar_bg:SetTexCoord (unpack (avatar [5]))
		end
		if (avatar [6]) then
			info.avatar_bg:SetVertexColor (unpack (avatar [6]))
		end

		info.avatar_nick:SetText (avatar [1] or nome)
		info.avatar_attribute:SetText (atributo_nome)

		info.avatar_attribute:SetPoint ("CENTER", info.avatar_nick, "CENTER", 0, 14)
		info.avatar:Show()
		info.avatar_bg:Show()
		info.avatar_bg:SetAlpha (.65)
		info.avatar_nick:Show()
		info.avatar_attribute:Show()
		info.nome:Hide()
		info.atributo_nome:Hide()

	else

		info.avatar:Hide()
		info.avatar_bg:Hide()
		info.avatar_nick:Hide()
		info.avatar_attribute:Hide()

		info.nome:Show()
		info.atributo_nome:Show()
	end

	info.atributo_nome:SetPoint ("CENTER", info.nome, "CENTER", 0, 14)

	info.no_targets:Hide()
	info.no_targets.text:Hide()
	gump:TrocaBackgroundInfo (info)

	gump:HidaAllBarrasInfo()
	gump:HidaAllBarrasAlvo()
	gump:HidaAllDetalheInfo()

	gump:JI_AtualizaContainerBarras (-1)

	local classe = jogador.classe

	if (not classe) then
		classe = "monster"
	end

	--info.classe_icone:SetTexture ("Interface\\AddOns\\Details\\images\\"..classe:lower()) --> top left
	info.classe_icone:SetTexture ("Interface\\AddOns\\Details\\images\\classes") --> top left
	info.SetClassIcon (jogador, classe)

	if (_detalhes.player_details_window.skin == "WoWClassic") then
		if (jogador.grupo and IsInRaid() and not avatar) then
			for i = 1, GetNumGroupMembers() do
				local playerName, realmName = UnitName ("raid" .. i)
				if (realmName and realmName ~= "") then
					playerName = playerName .. "-" .. realmName
				end
				if (playerName == jogador.nome) then
					SetPortraitTexture (info.classe_icone, "raid" .. i)
					info.classe_icone:SetTexCoord (0, 1, 0, 1)
					break
				end
			end
		end
	end

	info:ShowTabs()
	gump:Fade (info, 0)

	--check which tab was selected and reopen that tab
	if (info.selectedTab == "Summary") then
		return jogador:MontaInfo()
	else
		--open tab
		for index = 1, #_detalhes.player_details_tabs do
			local tab = _detalhes.player_details_tabs [index]
			if (tab:condition (info.jogador, info.atributo, info.sub_atributo)) then
				if (tab.tabname == info.selectedTab) then
					--_detalhes.player_details_tabs [index]:Click()
					--_detalhes.player_details_tabs [index].onclick()
					_detalhes.player_details_tabs [index]:OnShowFunc()
				end
			end
		end
	end
end

-- for beta todo: info background need a major rewrite
local set_right_panel_layout = function (tipo)
	info.bg1_sec_texture:SetTexture (.05, .05, .05, .4)
	info.bg3_sec_texture:Show()
	info.bg2_sec_texture:Show()
	info.tipo = tipo
	for i = 1, spellInfoSettings.amount do
		info ["right_background" .. i]:Hide()
	end
end

local set_taken_layout = function()
	set_right_panel_layout (2)
	info.targets:SetText (Loc ["STRING_TARGETS"] .. ":")
	info.no_targets:Show()
	info.no_targets.text:Show()
	info.apoio_icone_esquerdo:Hide()
	info.apoio_icone_direito:Hide()
	info.report_direita:Show()
end

function gump:TrocaBackgroundInfo()

	info.bg3_sec_texture:Hide()
	info.bg2_sec_texture:Hide()

	info.apoio_icone_esquerdo:Show()
	info.apoio_icone_direito:Show()

	info.report_direita:Hide()

	for i = 1, spellInfoSettings.amount do
		info ["right_background" .. i]:Show()
	end

	if (info.atributo == 1) then --> DANO

		if (info.sub_atributo == 1 or info.sub_atributo == 2) then --> damage done / dps
			info.bg1_sec_texture:SetTexture (nil)
			info.tipo = 1

			if (info.sub_atributo == 2) then
				info.targets:SetText (Loc ["STRING_TARGETS"] .. " " .. Loc ["STRING_ATTRIBUTE_DAMAGE_DPS"] .. ":")
				info.target_persecond = true
			else
				info.targets:SetText (Loc ["STRING_TARGETS"] .. ":")
			end

		elseif (info.sub_atributo == 3) then --> damage taken
			set_taken_layout()

		elseif (info.sub_atributo == 4) then --> friendly fire
			set_right_panel_layout (3)
			info.targets:SetText (Loc ["STRING_SPELLS"] .. ":")

			info.apoio_icone_esquerdo:Hide()
			info.apoio_icone_direito:Hide()
			info.report_direita:Show()

		elseif (info.sub_atributo == 6) then --> enemies
			set_right_panel_layout (3)
			info.targets:SetText (Loc ["STRING_DAMAGE_TAKEN_FROM"])
		end

	elseif (info.atributo == 2) then --> HEALING
		if (info.sub_atributo == 1 or info.sub_atributo == 2 or info.sub_atributo == 3) then --> damage done / dps
			info.bg1_sec_texture:SetTexture (nil)
			info.tipo = 1

			if (info.sub_atributo == 3) then
				info.targets:SetText (Loc ["STRING_OVERHEALED"] .. ":")
				info.target_text = Loc ["STRING_OVERHEALED"] .. ":"
			elseif (info.sub_atributo == 2) then
				info.targets:SetText (Loc ["STRING_TARGETS"] .. " " .. Loc ["STRING_ATTRIBUTE_HEAL_HPS"] .. ":")
				info.target_persecond = true
			else
				info.targets:SetText (Loc ["STRING_TARGETS"] .. ":")
			end

		elseif (info.sub_atributo == 4) then --> Healing taken
			set_taken_layout()
		end

	elseif (info.atributo == 3) then --> REGEN
		info.bg1_sec_texture:SetTexture (nil)
		info.tipo = 2
		info.targets:SetText ("Цели :") -- todo

	elseif (info.atributo == 4) then --> MISC
		info.bg1_sec_texture:SetTexture (nil)
		info.tipo = 2

		info.targets:SetText (Loc ["STRING_TARGETS"] .. ":")
	end
end

--> self � qualquer coisa que chamar esta fun��o
------------------------------------------------------------------------------------------------------------------------------
-- � chamado pelo click no X e pelo reset do historico
function _detalhes:FechaJanelaInfo (fromEscape)
	if (info.ativo) then --> se a janela tiver aberta
		--janela_info:Hide()
		if (fromEscape) then
			gump:Fade (info, "in")
		else
			gump:Fade (info, 1)
		end
		info.ativo = false --> sinaliza o addon que a janela esta agora fechada

		--_detalhes.info_jogador.detalhes = nil
		info.jogador = nil
		info.atributo = nil
		info.sub_atributo = nil
		info.instancia = nil

		info.nome:SetText ("")
		info.atributo_nome:SetText ("")

		gump:JI_AtualizaContainerBarras (-1) --> reseta o frame das barras
	end
end

--> esconde todas as barras das skills na janela de info
------------------------------------------------------------------------------------------------------------------------------
function gump:HidaAllBarrasInfo()
	local barras = _detalhes.janela_info.barras1
	for index = 1, #barras, 1 do
		barras [index]:Hide()
		barras [index].textura:SetStatusBarColor (1, 1, 1, 1)
		barras [index].on_focus = false
	end
end

--> esconde todas as barras dos alvos do jogador
------------------------------------------------------------------------------------------------------------------------------
function gump:HidaAllBarrasAlvo()
	local barras = _detalhes.janela_info.barras2
	for index = 1, #barras, 1 do
		barras [index]:Hide()
	end
end

--> esconde as 5 barras a direita na janela de info
------------------------------------------------------------------------------------------------------------------------------
function gump:HidaAllDetalheInfo()
	for i = 1, spellInfoSettings.amount do
		gump:HidaDetalheInfo (i)
	end
	for _, barra in _ipairs (info.barras3) do
		barra:Hide()
	end
	_detalhes.janela_info.spell_icone:SetTexture ("")
end


--> seta os scripts da janela de informa��es
local mouse_down_func = function (self, button)
	if (button == "LeftButton") then
		info:StartMoving()
		info.isMoving = true
	elseif (button == "RightButton" and not self.isMoving) then
		_detalhes:FechaJanelaInfo()
	end
end

local mouse_up_func = function (self, button)
	if (info.isMoving) then
		info:StopMovingOrSizing()
		info.isMoving = false
	end
end

------------------------------------------------------------------------------------------------------------------------------
local function seta_scripts (este_gump)

	--> Janela
	este_gump:SetScript ("OnMouseDown", mouse_down_func)
	este_gump:SetScript ("OnMouseUp", mouse_up_func)

	este_gump.container_barras.gump:SetScript ("OnMouseDown", mouse_down_func)
	este_gump.container_barras.gump:SetScript ("OnMouseUp", mouse_up_func)

	este_gump.container_detalhes:SetScript ("OnMouseDown", mouse_down_func)
	este_gump.container_detalhes:SetScript ("OnMouseUp", mouse_up_func)

	este_gump.container_alvos.gump:SetScript ("OnMouseDown", mouse_down_func)
	este_gump.container_alvos.gump:SetScript ("OnMouseUp", mouse_up_func)

	--> bot�o fechar
	este_gump.close_button:SetScript ("OnClick", function (self)
		_detalhes:FechaJanelaInfo()
	end)
end



------------------------------------------------------------------------------------------------------------------------------
function gump:HidaDetalheInfo (index)
	local info = _detalhes.janela_info.grupos_detalhes [index]
	info.nome:SetText ("")
	info.nome2:SetText ("")
	info.dano:SetText ("")
	info.dano_porcento:SetText ("")
	info.dano_media:SetText ("")
	info.dano_dps:SetText ("")
	info.bg:Hide()
end

--> cria a barra de detalhes a direita da janela de informa��es
------------------------------------------------------------------------------------------------------------------------------

local detalhe_infobg_onenter = function (self)
	gump:Fade (self.overlay, "OUT")
	gump:Fade (self.reportar, "OUT")
end

local detalhe_infobg_onleave = function (self)
	gump:Fade (self.overlay, "IN")
	gump:Fade (self.reportar, "IN")
end

local detalhes_inforeport_onenter = function (self)
	gump:Fade (self:GetParent().overlay, "OUT")
	gump:Fade (self, "OUT")
end
local detalhes_inforeport_onleave = function (self)
	gump:Fade (self:GetParent().overlay, "IN")
	gump:Fade (self, "IN")
end

function gump:CriaDetalheInfo (index)
	local info = {}

	info.bg = _CreateFrame ("StatusBar", "DetailsPlayerDetailsWindow_DetalheInfoBG" .. index, _detalhes.janela_info.container_detalhes)
	info.bg:EnableMouse(true)
	info.bg:SetStatusBarTexture ("Interface\\AddOns\\Details\\images\\bar_detalhes2")
	info.bg:SetStatusBarColor (1, 1, 1, .84)
	info.bg:SetMinMaxValues (0, 100)
	info.bg:SetValue (100)
	info.bg:SetSize (320, 47)

	info.nome = info.bg:CreateFontString (nil, "OVERLAY", "GameFontNormal")
	info.nome2 = info.bg:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
	info.dano = info.bg:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
	info.dano_porcento = info.bg:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
	info.dano_media = info.bg:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
	info.dano_dps = info.bg:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")

	info.bg.overlay = info.bg:CreateTexture ("DetailsPlayerDetailsWindow_DetalheInfoBG_Overlay" .. index, "ARTWORK")
	info.bg.overlay:SetTexture ("Interface\\AddOns\\Details\\images\\overlay_detalhes")
	info.bg.overlay:SetWidth (341)
	info.bg.overlay:SetHeight (61)
	info.bg.overlay:SetPoint ("TOPLEFT", info.bg, "TOPLEFT", -7, 6)
	gump:Fade (info.bg.overlay, 1)

	info.bg.reportar = gump:NewDetailsButton (info.bg, nil, nil, _detalhes.Reportar, _detalhes.janela_info, 10+index, 16, 16,
	"Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", nil, "DetailsJanelaInfoReport1")
	info.bg.reportar:SetPoint ("BOTTOMLEFT", info.bg.overlay, "BOTTOMRIGHT",  -33, 10)
	gump:Fade (info.bg.reportar, 1)

	info.bg:SetScript ("OnEnter", detalhe_infobg_onenter)
	info.bg:SetScript ("OnLeave", detalhe_infobg_onleave)

	info.bg.reportar:SetScript ("OnEnter", detalhes_inforeport_onenter)
	info.bg.reportar:SetScript ("OnLeave", detalhes_inforeport_onleave)

	info.bg_end = info.bg:CreateTexture ("DetailsPlayerDetailsWindow_DetalheInfoBG_bg_end" .. index, "BACKGROUND")
	info.bg_end:SetHeight (47)
	info.bg_end:SetTexture ("Interface\\AddOns\\Details\\images\\bar_detalhes2_end")

	_detalhes.janela_info.grupos_detalhes [index] = info
end

function info:SetDetailInfoConfigs (texture, color, x, y)
	for i = 1, spellInfoSettings.amount do
		if (texture) then
			info.grupos_detalhes [i].bg:SetStatusBarTexture (texture)
		end

		if (color) then
			local texture = info.grupos_detalhes [i].bg:GetStatusBarTexture()
			texture:SetVertexColor (unpack (color))
		end

		if (x or y) then
			gump:SetaDetalheInfoAltura (i, x, y)
		end
	end
end

--> determina qual a pocis�o que a barra de detalhes vai ocupar
------------------------------------------------------------------------------------------------------------------------------
function gump:SetaDetalheInfoAltura (index, xmod, ymod)
	local info = _detalhes.janela_info.grupos_detalhes [index]

	local altura = {-10, -63, -118, -173, -228, -279}


	altura = altura [index]

	local background

	local y = -74 - ((index-1) * 79.5)

	if (index == 1) then
		_detalhes.janela_info.right_background1:SetPoint ("TOPLEFT", _detalhes.janela_info, "TOPLEFT", 357 + (xmod or 0), y)
		background = _detalhes.janela_info.right_background1

	elseif (index == 2) then
		_detalhes.janela_info.right_background2:SetPoint ("TOPLEFT", _detalhes.janela_info, "TOPLEFT", 357 + (xmod or 0), y)
		background = _detalhes.janela_info.right_background2

	elseif (index == 3) then
		_detalhes.janela_info.right_background3:SetPoint ("TOPLEFT", _detalhes.janela_info, "TOPLEFT", 357 + (xmod or 0), y)
		background = _detalhes.janela_info.right_background3

	elseif (index == 4) then
		_detalhes.janela_info.right_background4:SetPoint ("TOPLEFT", _detalhes.janela_info, "TOPLEFT", 357 + (xmod or 0), y)
		background = _detalhes.janela_info.right_background4

	elseif (index == 5) then
		_detalhes.janela_info.right_background5:SetPoint ("TOPLEFT", _detalhes.janela_info, "TOPLEFT", 357 + (xmod or 0), y)
		background = _detalhes.janela_info.right_background5

	elseif (index == 6) then
		_detalhes.janela_info.right_background6:SetPoint ("TOPLEFT", _detalhes.janela_info, "TOPLEFT", 357 + (xmod or 0), y)
		background = _detalhes.janela_info.right_background6

	end

	background:SetHeight (75)

	--3 textos da esquerda e direita
	local y = -3
	local x = 3
	local right = -1

	info.nome:SetPoint ("TOPLEFT", background, "TOPLEFT", x, y + (-2))
	info.dano:SetPoint ("TOPLEFT", background, "TOPLEFT", x, y + (-24))
	info.dano_media:SetPoint ("TOPLEFT", background, "TOPLEFT", x, y + (-44))

	info.nome2:SetPoint ("TOPRIGHT", background, "TOPRIGHT", -x + right,  y + (-2))
	info.dano_porcento:SetPoint ("TOPRIGHT", background, "TOPRIGHT", -x + right, y + (-24))
	info.dano_dps:SetPoint ("TOPRIGHT", background, "TOPRIGHT", -x + right, y + (-44))

	info.bg:SetPoint ("TOPLEFT", background, "TOPLEFT", 1, -1)
	info.bg:SetHeight (background:GetHeight() - 2)
	info.bg:SetWidth (background:GetWidth())

	info.bg_end:SetPoint ("LEFT", info.bg, "LEFT", info.bg:GetValue()*2.19, 0)
	info.bg_end:SetHeight (background:GetHeight()+2)
	info.bg_end:SetWidth (6)
	info.bg_end:SetAlpha (.75)

	info.bg.overlay:SetWidth (background:GetWidth() + 24)
	info.bg.overlay:SetHeight (background:GetHeight() + 16)

	info.bg:Hide()
end

--> seta o conte�do da barra de detalhes
------------------------------------------------------------------------------------------------------------------------------
function gump:SetaDetalheInfoTexto (index, p, arg1, arg2, arg3, arg4, arg5, arg6)
	local info = _detalhes.janela_info.grupos_detalhes [index]

	if (p) then
		if (_type (p) == "table") then
			info.bg:SetValue (p.p)
			info.bg:SetStatusBarColor (p.c[1], p.c[2], p.c[3], p.c[4] or 1)
		else
			info.bg:SetValue (p)
			info.bg:SetStatusBarColor (1, 1, 1, .5)
		end

		info.bg_end:Show()
		info.bg_end:SetPoint ("LEFT", info.bg, "LEFT", (info.bg:GetValue() * (info.bg:GetWidth( ) / 100)) - 3, 0) -- 2.19
		info.bg:Show()
	end

	if (info.IsPet) then
		info.bg.PetIcon:Hide()
		info.bg.PetText:Hide()
		info.bg.PetDps:Hide()
		gump:Fade (info.bg.overlay, "IN")
		info.IsPet = false
	end

	if (arg1) then
		info.nome:SetText (arg1)
	end

	if (arg2) then
		info.dano:SetText (arg2)
	end

	if (arg3) then
		info.dano_porcento:SetText (arg3)
	end

	if (arg4) then
		info.dano_media:SetText (arg4)
	end

	if (arg5) then
		info.dano_dps:SetText (arg5)
	end

	if (arg6) then
		info.nome2:SetText (arg6)
	end

	info.nome:Show()
	info.dano:Show()
	info.dano_porcento:Show()
	info.dano_media:Show()
	info.dano_dps:Show()
	info.nome2:Show()

end

--> cria as 5 caixas de detalhes infos que ser�o usados
------------------------------------------------------------------------------------------------------------------------------
local function cria_barras_detalhes()
	_detalhes.janela_info.grupos_detalhes = {}
	for i = 1, spellInfoSettings.amount do
		gump:CriaDetalheInfo (i)
		gump:SetaDetalheInfoAltura (i)
	end
end


--> cria os textos em geral da janela info
------------------------------------------------------------------------------------------------------------------------------
local function cria_textos (este_gump, SWW)
	este_gump.nome = este_gump:CreateFontString (nil, "OVERLAY", "QuestFont_Large")
	este_gump.nome:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 105, -54)

	este_gump.atributo_nome = este_gump:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")

	este_gump.targets = SWW:CreateFontString (nil, "OVERLAY", "QuestFont_Large")
	este_gump.targets:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 24, -273)
	este_gump.targets:SetText (Loc ["STRING_TARGETS"] .. ":")

	este_gump.avatar = este_gump:CreateTexture (nil, "ARTWORK")
	este_gump.avatar_bg = este_gump:CreateTexture (nil, "BORDER")
	este_gump.avatar_attribute = este_gump:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
	este_gump.avatar_nick = este_gump:CreateFontString (nil, "OVERLAY", "QuestFont_Large")

	este_gump.avatar:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 60, -10)
	este_gump.avatar_bg:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 60, -12)
	este_gump.avatar_bg:SetSize (275, 60)

	este_gump.avatar_nick:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 195, -54)

	este_gump.avatar:Hide()
	este_gump.avatar_bg:Hide()
	este_gump.avatar_nick:Hide()

end


--> esquerdo superior
local function cria_container_barras (este_gump, SWW)

	local container_barras_window = _CreateFrame ("ScrollFrame", "Details_Info_ContainerBarrasScroll", SWW)
	local container_barras = _CreateFrame ("Frame", "Details_Info_ContainerBarras", container_barras_window)

	container_barras:SetAllPoints (container_barras_window)
	container_barras:SetWidth (300)
	container_barras:SetHeight (150)
	container_barras:EnableMouse (true)
	container_barras:SetMovable (true)

	container_barras_window:SetWidth (300)
	container_barras_window:SetHeight (145)
	container_barras_window:SetScrollChild (container_barras)
	container_barras_window:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 21, -76)

	container_barras_window:SetScript ("OnSizeChanged", function (self)
		container_barras:SetSize (self:GetSize())
	end)

	gump:NewScrollBar (container_barras_window, container_barras, 6, -17)
	container_barras_window.slider:Altura (117)
	container_barras_window.slider:cimaPoint (0, 1)
	container_barras_window.slider:baixoPoint (0, -3)

	container_barras_window.ultimo = 0

	container_barras_window.gump = container_barras
	--container_barras_window.slider = slider_gump
	este_gump.container_barras = container_barras_window

end

function gump:JI_AtualizaContainerBarras (amt)

	local container = _detalhes.janela_info.container_barras

	if (amt >= 9 and container.ultimo ~= amt) then
		local tamanho = (CONST_BAR_HEIGHT + 1) * amt
		container.gump:SetHeight (tamanho)
		container.slider:Update()
		container.ultimo = amt

	elseif (amt < 8 and container.slider.ativo) then
		container.slider:Update (true)
		container.gump:SetHeight (140)
		container.ultimo = 0
	end
end

function gump:JI_AtualizaContainerAlvos (amt)

	local container = _detalhes.janela_info.container_alvos

	if (amt >= 6 and container.ultimo ~= amt) then
		local tamanho = (CONST_TARGET_HEIGHT + 1) * amt
		container.gump:SetHeight (tamanho)
		container.slider:Update()
		container.ultimo = amt

	elseif (amt <= 5 and container.slider.ativo) then
		container.slider:Update (true)
		container.gump:SetHeight (100)
		container.ultimo = 0
	end
end

--> container direita
local function cria_container_detalhes (este_gump, SWW)
	local container_detalhes = _CreateFrame ("Frame", "Details_Info_ContainerDetalhes", SWW)

	container_detalhes:SetPoint ("TOPRIGHT", este_gump, "TOPRIGHT", -74, -76)
	container_detalhes:SetWidth (220)
	container_detalhes:SetHeight (270)
	container_detalhes:EnableMouse (true)
	container_detalhes:SetResizable (false)
	container_detalhes:SetMovable (true)

	este_gump.container_detalhes = container_detalhes
end

--> esquerdo inferior
local function cria_container_alvos (este_gump, SWW)
	local container_alvos_window = _CreateFrame ("ScrollFrame", "Details_Info_ContainerAlvosScroll", SWW)
	local container_alvos = _CreateFrame ("Frame", "Details_Info_ContainerAlvos", container_alvos_window)

	container_alvos:SetAllPoints (container_alvos_window)
	container_alvos:SetWidth (300)
	container_alvos:SetHeight (100)
	container_alvos:EnableMouse (true)
	container_alvos:SetMovable (true)

	container_alvos_window:SetWidth (300)
	container_alvos_window:SetHeight (100)
	container_alvos_window:SetScrollChild (container_alvos)
	container_alvos_window:SetPoint ("BOTTOMLEFT", este_gump, "BOTTOMLEFT", 20, 6) --56 default

	container_alvos_window:SetScript ("OnSizeChanged", function (self)
		container_alvos:SetSize (self:GetSize())
	end)

	gump:NewScrollBar (container_alvos_window, container_alvos, 7, 4)
	container_alvos_window.slider:Altura (88)
	container_alvos_window.slider:cimaPoint (0, 1)
	container_alvos_window.slider:baixoPoint (0, -3)

	container_alvos_window.gump = container_alvos
	este_gump.container_alvos = container_alvos_window
end


local default_icon_change = function (jogador, classe)
	if (classe ~= "UNKNOW" and classe ~= "UNGROUPPLAYER") then
		info.classe_icone:SetTexCoord (_detalhes.class_coords [classe][1], _detalhes.class_coords [classe][2], _detalhes.class_coords [classe][3], _detalhes.class_coords [classe][4])
		if (jogador.enemy) then
			if (_detalhes.faction_against == "Horde") then
				info.nome:SetTextColor (1, 91/255, 91/255, 1)
			else
				info.nome:SetTextColor (151/255, 215/255, 1, 1)
			end
		else
			info.classe_iconePlus:SetTexture()
			info.nome:SetTextColor (1, 1, 1, 1)
		end
	else
		if (jogador.enemy) then
			if (_detalhes.class_coords [_detalhes.faction_against]) then
				info.classe_icone:SetTexCoord (_unpack (_detalhes.class_coords [_detalhes.faction_against]))
				if (_detalhes.faction_against == "Horde") then
					info.nome:SetTextColor (1, 91/255, 91/255, 1)
				else
					info.nome:SetTextColor (151/255, 215/255, 1, 1)
				end
			else
				info.nome:SetTextColor (1, 1, 1, 1)
			end
		else
			info.classe_icone:SetTexCoord (_detalhes.class_coords ["MONSTER"][1], _detalhes.class_coords ["MONSTER"][2], _detalhes.class_coords ["MONSTER"][3], _detalhes.class_coords ["MONSTER"][4])
		end
		info.classe_iconePlus:SetTexture()
	end
end

function _detalhes:InstallPDWSkin (skin_name, func)
	if (not skin_name) then
		return false -- sem nome
	elseif (_detalhes.playerdetailwindow_skins [skin_name]) then
		return false -- ja existe
	end

	_detalhes.playerdetailwindow_skins [skin_name] = func
	return true
end

function _detalhes:ApplyPDWSkin (skin_name)

--already built
	if (not DetailsPlayerDetailsWindow.Loaded) then
		if (skin_name) then
			_detalhes.player_details_window.skin = skin_name
		end
		return
	end

--hide extra frames
	local window = DetailsPlayerDetailsWindow
	if (window.extra_frames) then
		for framename, frame in _pairs (window.extra_frames) do
			frame:Hide()
		end
	end

--apply default first
	local default_skin = _detalhes.playerdetailwindow_skins ["WoWClassic"]
	pcall (default_skin.func)

--than do the change
	if (not skin_name) then
		skin_name = _detalhes.player_details_window.skin
	end

	local skin = _detalhes.playerdetailwindow_skins [skin_name]
	if (skin) then
		local successful, errortext = pcall (skin.func)
		if (not successful) then
			_detalhes:Msg ("error occurred on skin call():", errortext)
			local former_skin = _detalhes.playerdetailwindow_skins [_detalhes.player_details_window.skin]
			pcall (former_skin.func)
		else
			_detalhes.player_details_window.skin = skin_name
		end
	else
		_detalhes:Msg ("skin not found.")
	end

	if (info and info:IsShown() and info.jogador and info.jogador.classe) then
		info.SetClassIcon (info.jogador, info.jogador.classe)
	end

	_detalhes:ApplyRPSkin (skin_name)
end

function _detalhes:SetPlayerDetailsWindowTexture (texture)
	DetailsPlayerDetailsWindow.bg1:SetTexture (texture)
end

function _detalhes:SetPDWBarConfig (texture)
	local window = DetailsPlayerDetailsWindow

	if (texture) then
		_detalhes.player_details_window.bar_texture = texture
		local texture = SharedMedia:Fetch ("statusbar", texture)

		for _, bar in _ipairs (window.barras1) do
			bar.textura:SetStatusBarTexture (texture)
		end
		for _, bar in _ipairs (window.barras2) do
			bar.textura:SetStatusBarTexture (texture)
		end
		for _, bar in _ipairs (window.barras3) do
			bar.textura:SetStatusBarTexture (texture)
		end
	end
end

local default_skin = function()
	local window = DetailsPlayerDetailsWindow
	window.bg1:SetTexture ([[Interface\AddOns\Details\images\info_window_background]])
	window.bg1:SetSize (1024, 512)
	window.bg1:SetAlpha (1)
	window.bg1:SetVertexColor (1, 1, 1)
	window:SetBackdrop (nil)
	window:SetBackdropColor (1, 1, 1, 1)
	window:SetBackdropBorderColor (1, 1, 1, 1)
	window.bg_icone_bg:Show()
	window.bg_icone:Show()

	window.leftbars1_backgound:SetPoint ("TOPLEFT", window.container_barras, "TOPLEFT", -3, 3)
	window.leftbars1_backgound:SetPoint ("BOTTOMRIGHT", window.container_barras, "BOTTOMRIGHT", 3, -3)
	window.leftbars2_backgound:SetPoint ("TOPLEFT", window.container_alvos, "TOPLEFT", -3, 23)
	window.leftbars2_backgound:SetPoint ("BOTTOMRIGHT", window.container_alvos, "BOTTOMRIGHT", 3, 0)
	window.leftbars1_backgound:SetAlpha (1)
	window.leftbars2_backgound:SetAlpha (1)
	window.right_background1:SetAlpha (1)
	window.right_background2:SetAlpha (1)
	window.right_background3:SetAlpha (1)
	window.right_background4:SetAlpha (1)
	window.right_background5:SetAlpha (1)

	window.close_button:GetNormalTexture():SetDesaturated (false)

	window.title_string:ClearAndSetPoint ("CENTER", window, "CENTER")
	window.title_string:SetPoint ("TOP", window, "TOP", 0, -18)
	window.title_string:SetParent (window)
	window.title_string:SetTextColor (.890, .729, .015, 1)

	window.classe_icone:SetParent (window)
	window.classe_icone:SetPoint ("TOPLEFT", window, "TOPLEFT", 4, 0)
	window.classe_icone:SetWidth (64)
	window.classe_icone:SetHeight (64)
	window.classe_icone:SetDrawLayer ("BACKGROUND", 1)
	window.classe_icone:SetAlpha (1)

	window.close_button:SetWidth (32)
	window.close_button:SetHeight (32)
	window.close_button:SetPoint ("TOPRIGHT", window, "TOPRIGHT", 5, -8)

	window.options_button:SetPoint ("TOPRIGHT", window, "TOPRIGHT", -26, -16)
	window.options_button:SetSize (16, 16)

	window.avatar:SetParent (window)

	_detalhes:SetPDWBarConfig ("Skyline")

	--bar container
	window.container_barras:SetSize (300, 145)
	window.container_barras:SetPoint ("TOPLEFT", window, "TOPLEFT", 20, -76)

	--target container
	window.container_alvos:SetPoint ("BOTTOMLEFT", window, "BOTTOMLEFT", 20, 6)
	window.container_alvos:SetSize (300, 100)

	--icons
	window.SetClassIcon = default_icon_change
	window.apoio_icone_direito:SetBlendMode ("BLEND")
	window.apoio_icone_esquerdo:SetBlendMode ("BLEND")

	--texts
	window.targets:SetPoint ("TOPLEFT", window, "TOPLEFT", 24, -273)
	window.nome:SetPoint ("TOPLEFT", window, "TOPLEFT", 105, -54)

	--report button
	window.topleft_report:SetPoint ("BOTTOMLEFT", window.container_barras, "TOPLEFT",  33, 3)

	--no targets texture
	window.no_targets:SetPoint ("BOTTOMLEFT", window, "BOTTOMLEFT", 20, 6)
	window.no_targets:SetSize (301, 100)
	window.no_targets:SetAlpha (1)

	--right panel textures
	window.bg2_sec_texture:SetPoint ("TOPLEFT", window.bg1_sec_texture, "TOPLEFT", 8, 0)
	window.bg2_sec_texture:SetPoint ("BOTTOMRIGHT", window.bg1_sec_texture, "BOTTOMRIGHT", -30, 0)

	window.bg3_sec_texture:SetPoint ("TOPLEFT", window.bg2_sec_texture, "TOPLEFT", 0, 0)
	window.bg3_sec_texture:SetPoint ("BOTTOMRIGHT", window.bg2_sec_texture, "BOTTOMRIGHT", 0, 0)
	window.bg3_sec_texture:SetTexture (0, 0, 0, 1)

	--the 5 spell details blocks
	for i, infoblock in _ipairs (_detalhes.janela_info.grupos_detalhes) do
		infoblock.bg:SetSize (219, 47) --219 original
	end
	local xLocation = {-85, -136, -191, -246, -301, -356}
	local heightTable = {43, 48, 48, 48, 48, 48}

	for i = 1, spellInfoSettings.amount do
		window ["right_background" .. i]:SetPoint ("TOPLEFT", window, "TOPLEFT", 357, xLocation [i]) --357 original
		window ["right_background" .. i]:SetSize (220, heightTable [i]) --220
	end

	--info container
	info:SetDetailInfoConfigs ("Interface\\AddOns\\Details\\images\\bar_detalhes2", {1, 1, 1, 0.5}, 0, 0)

	window.bg1_sec_texture:SetPoint ("TOPLEFT", window.bg1, "TOPLEFT", 348, -86)
	window.bg1_sec_texture:SetHeight (262)
	window.bg1_sec_texture:SetWidth (264)

	--container bars 3
	local x_start = 61
	local y_start = -10
	local janela = window.container_detalhes

	container3_bars_pointFunc = function (barra, index)
		local y = (index-1) * 17
		y = y*-1
		barra:SetPoint ("LEFT", janela, "LEFT", x_start, 0)
		barra:SetPoint ("RIGHT", janela, "RIGHT", 65, 0)
		barra:SetPoint ("TOP", janela, "TOP", 0, y+y_start)
	end

	for index, barra in _ipairs (window.barras3) do
		local y = (index-1) * 17
		y = y*-1
		barra:SetPoint ("LEFT", janela, "LEFT", x_start, 0)
		barra:SetPoint ("RIGHT", janela, "RIGHT", 65, 0)
		barra:SetPoint ("TOP", janela, "TOP", 0, y+y_start)
	end

	--scrollbar
	window.container_barras.cima:SetNormalTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Up")
	window.container_barras.cima:SetPushedTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Down")
	window.container_barras.cima:SetDisabledTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Disabled")
	window.container_barras.cima:GetNormalTexture():ClearAndSetPoint ("CENTER", window.container_barras.cima, "CENTER", 0, 0)
	window.container_barras.cima:GetPushedTexture():ClearAndSetPoint ("CENTER", window.container_barras.cima, "CENTER", 0, 0)
	window.container_barras.cima:GetDisabledTexture():ClearAndSetPoint ("CENTER", window.container_barras.cima, "CENTER", 0, 0)
	window.container_barras.cima:SetSize (29, 32)
	window.container_barras.cima:SetBackdrop (nil)

	window.container_barras.baixo:SetNormalTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Up")
	window.container_barras.baixo:SetPushedTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Down")
	window.container_barras.baixo:SetDisabledTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Disabled")
	window.container_barras.baixo:GetNormalTexture():ClearAndSetPoint ("CENTER", window.container_barras.baixo, "CENTER", 0, 0)
	window.container_barras.baixo:GetPushedTexture():ClearAndSetPoint ("CENTER", window.container_barras.baixo, "CENTER", 0, 0)
	window.container_barras.baixo:GetDisabledTexture():ClearAndSetPoint ("CENTER", window.container_barras.baixo, "CENTER", 0, 0)
	window.container_barras.baixo:SetSize (29, 32)
	window.container_barras.baixo:SetBackdrop (nil)

	window.container_barras.slider:SetBackdrop (nil)

	window.container_barras.slider:Altura (117)
	window.container_barras.slider:cimaPoint (0, 1)
	window.container_barras.slider:baixoPoint (0, -3)
	window.container_barras.slider.thumb:SetTexture ("Interface\\Buttons\\UI-ScrollBar-Knob")
	window.container_barras.slider.thumb:SetTexCoord (0, 1, 0, 1)
	window.container_barras.slider.thumb:SetSize (29, 30)
	window.container_barras.slider.thumb:SetVertexColor (1, 1, 1, 1)

	--
	window.container_alvos.cima:SetNormalTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Up")
	window.container_alvos.cima:SetPushedTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Down")
	window.container_alvos.cima:SetDisabledTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Disabled")
	window.container_alvos.cima:GetNormalTexture():ClearAndSetPoint ("CENTER", window.container_alvos.cima, "CENTER", 0, 0)
	window.container_alvos.cima:GetPushedTexture():ClearAndSetPoint ("CENTER", window.container_alvos.cima, "CENTER", 0, 0)
	window.container_alvos.cima:GetDisabledTexture():ClearAndSetPoint ("CENTER", window.container_alvos.cima, "CENTER", 0, 0)
	window.container_alvos.cima:SetSize (29, 32)
	window.container_alvos.cima:SetBackdrop (nil)

	window.container_alvos.baixo:SetNormalTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Up")
	window.container_alvos.baixo:SetPushedTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Down")
	window.container_alvos.baixo:SetDisabledTexture ("Interface\\BUTTONS\\UI-ScrollBar-ScrollUpButton-Disabled")
	window.container_alvos.baixo:GetNormalTexture():ClearAndSetPoint ("CENTER", window.container_alvos.baixo, "CENTER", 0, 0)
	window.container_alvos.baixo:GetPushedTexture():ClearAndSetPoint ("CENTER", window.container_alvos.baixo, "CENTER", 0, 0)
	window.container_alvos.baixo:GetDisabledTexture():ClearAndSetPoint ("CENTER", window.container_alvos.baixo, "CENTER", 0, 0)
	window.container_alvos.baixo:SetSize (29, 32)
	window.container_alvos.baixo:SetBackdrop (nil)

	window.container_alvos.slider:SetBackdrop (nil)

	window.container_alvos.slider:Altura (88)
	window.container_alvos.slider:cimaPoint (0, 1)
	window.container_alvos.slider:baixoPoint (0, -3)

	window.container_alvos.slider.thumb:SetTexture ("Interface\\Buttons\\UI-ScrollBar-Knob")
	window.container_alvos.slider.thumb:SetTexCoord (0, 1, 0, 1)
	window.container_alvos.slider.thumb:SetSize (29, 30)
	window.container_alvos.slider.thumb:SetVertexColor (1, 1, 1, 1)

end
_detalhes:InstallPDWSkin ("WoWClassic", {func = default_skin, author = "Accidev", version = "v1.0", desc = "Default skin."})

local elvui_skin = function()
	local window = DetailsPlayerDetailsWindow
	window.bg1:SetTexture ([[Interface\AddOns\Details\images\background]], true)
	window.bg1:SetAlpha (0.7)
	window.bg1:SetVertexColor (0.27, 0.27, 0.27)
	window.bg1:SetVertTile (true)
	window.bg1:SetHorizTile (true)
	window.bg1:SetSize (PLAYER_DETAILS_WINDOW_WIDTH, PLAYER_DETAILS_WINDOW_HEIGHT)

	window:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
	window:SetBackdropColor (1, 1, 1, 1)
	window:SetBackdropBorderColor (0, 0, 0, 1)
	window.bg_icone_bg:Hide()
	window.bg_icone:Hide()
	local bgs_alpha = 0.6

	window.leftbars1_backgound:SetPoint ("TOPLEFT", window.container_barras, "TOPLEFT", -2, 3)
	window.leftbars1_backgound:SetPoint ("BOTTOMRIGHT", window.container_barras, "BOTTOMRIGHT", 3, -3)
	window.leftbars2_backgound:SetPoint ("TOPLEFT", window.container_alvos, "TOPLEFT", -2, 23)
	window.leftbars2_backgound:SetPoint ("BOTTOMRIGHT", window.container_alvos, "BOTTOMRIGHT", 4, 0)

	window.leftbars1_backgound:SetAlpha (bgs_alpha)
	window.leftbars2_backgound:SetAlpha (bgs_alpha)

	window.right_background1:SetAlpha (bgs_alpha)
	window.right_background2:SetAlpha (bgs_alpha)
	window.right_background3:SetAlpha (bgs_alpha)
	window.right_background4:SetAlpha (bgs_alpha)
	window.right_background5:SetAlpha (bgs_alpha)

	window.close_button:GetNormalTexture():SetDesaturated (true)

	local titlebar = window.extra_frames ["ElvUITitleBar"]
	if (not titlebar) then
		titlebar = _detalhes:CreateWindowTitleBar (window)
		window.extra_frames ["ElvUITitleBar"] = titlebar

		local name_bg_texture = window:CreateTexture (nil, "background")
		name_bg_texture:SetTexture ([[Interface\PetBattles\_PetBattleHorizTile]], true)
		name_bg_texture:SetHorizTile (true)
		name_bg_texture:SetTexCoord (0, 1, 126/256, 19/256)
		name_bg_texture:SetPoint ("TOPLEFT", window, "TOPLEFT", 2, -22)
		--name_bg_texture:SetPoint ("TOPRIGHT", window, "TOPRIGHT", -2, -22)
		name_bg_texture:SetPoint ("BOTTOMRIGHT", window, "BOTTOMRIGHT")
		name_bg_texture:SetHeight (54)
		name_bg_texture:SetVertexColor (0, 0, 0, 0.2)
		window.extra_frames ["ElvUINameTexture"] = name_bg_texture
	else
		titlebar:Show()
		window.extra_frames ["ElvUINameTexture"]:Show()
	end

	window.title_string:ClearAndSetPoint ("CENTER", window, "CENTER")
	window.title_string:SetPoint ("TOP", window, "TOP", 0, -7)
	window.title_string:SetParent (titlebar)
	window.title_string:SetTextColor (.8, .8, .8, 1)

	window.classe_icone:SetParent (titlebar)
	window.classe_icone:SetDrawLayer ("overlay")
	window.classe_icone:SetPoint ("TOPLEFT", window, "TOPLEFT", 2, -25)
	window.classe_icone:SetWidth (49)
	window.classe_icone:SetHeight (49)
	window.classe_icone:SetAlpha (1)

	window.close_button:SetWidth (20)
	window.close_button:SetHeight (20)
	window.close_button:SetPoint ("TOPRIGHT", window, "TOPRIGHT", 0, -3)

	window.options_button:SetPoint ("TOPRIGHT", window, "TOPRIGHT", -17, -7)
	window.options_button:SetSize (12, 12)

	window.avatar:SetParent (titlebar)

	--bar container
	window.container_barras:SetPoint (unpack (containerSettings.spells.point))
	window.container_barras:SetSize (containerSettings.spells.width, containerSettings.spells.height)

	--target container
	window.container_alvos:SetPoint (unpack (containerSettings.targets.point))
	window.container_alvos:SetSize (containerSettings.targets.width, containerSettings.targets.height)

	--texts
	window.targets:SetPoint ("TOPLEFT", window.container_alvos, "TOPLEFT", 3, 18)
	window.nome:SetPoint ("TOPLEFT", window, "TOPLEFT", 105, -48)

	--report button
	window.topleft_report:SetPoint ("BOTTOMLEFT", window.container_barras, "TOPLEFT",  43, 2)

	--icons
	window.apoio_icone_direito:SetBlendMode ("ADD")
	window.apoio_icone_esquerdo:SetBlendMode ("ADD")

	--no targets texture
	window.no_targets:SetPoint ("BOTTOMLEFT", window, "BOTTOMLEFT", 3, 6)
	window.no_targets:SetSize (418, 150)
	window.no_targets:SetAlpha (0.4)

	--right panel textures
	window.bg2_sec_texture:SetPoint ("TOPLEFT", window.bg1_sec_texture, "TOPLEFT", 7, 0)
	window.bg2_sec_texture:SetPoint ("BOTTOMRIGHT", window.bg1_sec_texture, "BOTTOMRIGHT", -30, 0)

	window.bg3_sec_texture:SetPoint ("TOPLEFT", window.bg2_sec_texture, "TOPLEFT", 0, 0)
	window.bg3_sec_texture:SetPoint ("BOTTOMRIGHT", window.bg2_sec_texture, "BOTTOMRIGHT", 0, 0)
	window.bg3_sec_texture:SetTexture (0, 0, 0, 0.3)

	--the 5 spell details blocks - not working
	for i, infoblock in _ipairs (_detalhes.janela_info.grupos_detalhes) do
		infoblock.bg:SetSize (330, 47)
	end
	local xLocation = {-85, -136, -191, -246, -301}
	local heightTable = {50, 50, 50, 50, 50, 48}

	for i = 1, spellInfoSettings.amount do
		window ["right_background" .. i]:SetPoint ("TOPLEFT", window, "TOPLEFT", 351, xLocation [i])
		window ["right_background" .. i]:SetSize (spellInfoSettings.width, heightTable [i])

	end

	--seta configs dos 5 blocos da direita
	info:SetDetailInfoConfigs ("Interface\\AddOns\\Details\\images\\bar_serenity", {1, 1, 1, 0.35}, -6 + 100, 0)

	window.bg1_sec_texture:SetPoint ("TOPLEFT", window.bg1, "TOPLEFT", 446, -86)
	-- vstavka 337
	window.bg1_sec_texture:SetWidth (410)
	window.bg1_sec_texture:SetHeight (362)

	--container 3 bars
	local x_start = 56
	local y_start = -10

	local janela = window.container_detalhes

	container3_bars_pointFunc = function (barra, index)
		local y = (index-1) * 17
		y = y*-1

		barra:SetPoint ("LEFT", info.bg1_sec_texture, "LEFT", 0, 0)
		barra:SetPoint ("RIGHT", info.bg1_sec_texture, "RIGHT", 0, 0)

		--barra:SetPoint ("LEFT", janela, "LEFT", x_start, 0)
		--barra:SetPoint ("RIGHT", janela, "RIGHT", 62, 0)
		barra:SetPoint ("TOP", janela, "TOP", 0, y+y_start)
	end

	for index, barra in _ipairs (window.barras3) do
		local y = (index-1) * 17
		y = y*-1
		barra:SetPoint ("LEFT", janela, "LEFT", x_start, 0)
		barra:SetPoint ("RIGHT", janela, "RIGHT", 62, 0)
		barra:SetPoint ("TOP", janela, "TOP", 0, y+y_start)
	end

	--scrollbar
	do
		--get textures
		local normalTexture = window.container_barras.cima:GetNormalTexture()
		local pushedTexture = window.container_barras.cima:GetPushedTexture()
		local disabledTexture = window.container_barras.cima:GetDisabledTexture()

		--set the new textures
		normalTexture:SetTexture ([[Interface\Buttons\Arrow-Up-Up]])
		pushedTexture:SetTexture ([[Interface\Buttons\Arrow-Up-Down]])
		disabledTexture:SetTexture ([[Interface\Buttons\Arrow-Up-Disabled]])

		normalTexture:SetPoint ("TOPLEFT", window.container_barras.cima, "TOPLEFT", 1, 0)
		normalTexture:SetPoint ("BOTTOMRIGHT", window.container_barras.cima, "BOTTOMRIGHT", 1, 0)
		pushedTexture:SetPoint ("TOPLEFT", window.container_barras.cima, "TOPLEFT", 1, 0)
		pushedTexture:SetPoint ("BOTTOMRIGHT", window.container_barras.cima, "BOTTOMRIGHT", 1, 0)
		disabledTexture:SetPoint ("TOPLEFT", window.container_barras.cima, "TOPLEFT", 1, 0)
		disabledTexture:SetPoint ("BOTTOMRIGHT", window.container_barras.cima, "BOTTOMRIGHT", 1, 0)

		disabledTexture:SetAlpha (0.5)

		window.container_barras.cima:SetSize (16, 16)
		window.container_barras.cima:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]]})
		window.container_barras.cima:SetBackdropColor (0, 0, 0, 0.3)
		window.container_barras.cima:SetBackdropBorderColor (0, 0, 0, 1)
	end

	do
		--get textures
		local normalTexture = window.container_barras.baixo:GetNormalTexture()
		local pushedTexture = window.container_barras.baixo:GetPushedTexture()
		local disabledTexture = window.container_barras.baixo:GetDisabledTexture()

		--set the new textures
		normalTexture:SetTexture ([[Interface\Buttons\Arrow-Down-Up]])
		pushedTexture:SetTexture ([[Interface\Buttons\Arrow-Down-Down]])
		disabledTexture:SetTexture ([[Interface\Buttons\Arrow-Down-Disabled]])

		normalTexture:SetPoint ("TOPLEFT", window.container_barras.baixo, "TOPLEFT", 1, -4)
		normalTexture:SetPoint ("BOTTOMRIGHT", window.container_barras.baixo, "BOTTOMRIGHT", 1, -4)

		pushedTexture:SetPoint ("TOPLEFT", window.container_barras.baixo, "TOPLEFT", 1, -4)
		pushedTexture:SetPoint ("BOTTOMRIGHT", window.container_barras.baixo, "BOTTOMRIGHT", 1, -4)

		disabledTexture:SetPoint ("TOPLEFT", window.container_barras.baixo, "TOPLEFT", 1, -4)
		disabledTexture:SetPoint ("BOTTOMRIGHT", window.container_barras.baixo, "BOTTOMRIGHT", 1, -4)

		disabledTexture:SetAlpha (0.5)

		window.container_barras.baixo:SetSize (16, 16)
		window.container_barras.baixo:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]]})
		window.container_barras.baixo:SetBackdropColor (0, 0, 0, 0.3)
		window.container_barras.baixo:SetBackdropBorderColor (0, 0, 0, 1)
	end

	window.container_barras.slider:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]]})
	window.container_barras.slider:SetBackdropColor (0, 0, 0, 0.35)
	window.container_barras.slider:SetBackdropBorderColor (0, 0, 0, 1)

	window.container_barras.slider:Altura (containerSettings.spells.scrollHeight)
	window.container_barras.slider:cimaPoint (0, 13)
	window.container_barras.slider:baixoPoint (0, -13)

	window.container_barras.slider.thumb:SetTexture ([[Interface\AddOns\Details\images\icons2]])
	window.container_barras.slider.thumb:SetTexCoord (482/512, 492/512, 104/512, 120/512)
	window.container_barras.slider.thumb:SetSize (12, 12)
	window.container_barras.slider.thumb:SetVertexColor (0.6, 0.6, 0.6, 0.95)

	--


	do
		local f = window.container_alvos

		--get textures
		local normalTexture = f.cima:GetNormalTexture()
		local pushedTexture = f.cima:GetPushedTexture()
		local disabledTexture = f.cima:GetDisabledTexture()

		--set the new textures
		normalTexture:SetTexture ([[Interface\Buttons\Arrow-Up-Up]])
		pushedTexture:SetTexture ([[Interface\Buttons\Arrow-Up-Down]])
		disabledTexture:SetTexture ([[Interface\Buttons\Arrow-Up-Disabled]])

		normalTexture:SetPoint ("TOPLEFT", f.cima, "TOPLEFT", 1, 0)
		normalTexture:SetPoint ("BOTTOMRIGHT", f.cima, "BOTTOMRIGHT", 1, 0)
		pushedTexture:SetPoint ("TOPLEFT", f.cima, "TOPLEFT", 1, 0)
		pushedTexture:SetPoint ("BOTTOMRIGHT", f.cima, "BOTTOMRIGHT", 1, 0)
		disabledTexture:SetPoint ("TOPLEFT", f.cima, "TOPLEFT", 1, 0)
		disabledTexture:SetPoint ("BOTTOMRIGHT", f.cima, "BOTTOMRIGHT", 1, 0)

		disabledTexture:SetAlpha (0.5)

		f.cima:SetSize (16, 16)
		f.cima:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]]})
		f.cima:SetBackdropColor (0, 0, 0, 0.3)
		f.cima:SetBackdropBorderColor (0, 0, 0, 1)
	end

	do
		local f = window.container_alvos

		--get textures
		local normalTexture = f.baixo:GetNormalTexture()
		local pushedTexture = f.baixo:GetPushedTexture()
		local disabledTexture = f.baixo:GetDisabledTexture()

		--set the new textures
		normalTexture:SetTexture ([[Interface\Buttons\Arrow-Down-Up]])
		pushedTexture:SetTexture ([[Interface\Buttons\Arrow-Down-Down]])
		disabledTexture:SetTexture ([[Interface\Buttons\Arrow-Down-Disabled]])

		normalTexture:SetPoint ("TOPLEFT", f.baixo, "TOPLEFT", 1, -4)
		normalTexture:SetPoint ("BOTTOMRIGHT", f.baixo, "BOTTOMRIGHT", 1, -4)

		pushedTexture:SetPoint ("TOPLEFT", f.baixo, "TOPLEFT", 1, -4)
		pushedTexture:SetPoint ("BOTTOMRIGHT", f.baixo, "BOTTOMRIGHT", 1, -4)

		disabledTexture:SetPoint ("TOPLEFT", f.baixo, "TOPLEFT", 1, -4)
		disabledTexture:SetPoint ("BOTTOMRIGHT", f.baixo, "BOTTOMRIGHT", 1, -4)

		disabledTexture:SetAlpha (0.5)

		f.baixo:SetSize (16, 16)
		f.baixo:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]]})
		f.baixo:SetBackdropColor (0, 0, 0, 0.3)
		f.baixo:SetBackdropBorderColor (0, 0, 0, 1)
	end

	window.container_alvos.slider:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]]})
	window.container_alvos.slider:SetBackdropColor (0, 0, 0, 0.35)
	window.container_alvos.slider:SetBackdropBorderColor (0, 0, 0, 1)

	window.container_alvos.slider:Altura (137)
	window.container_alvos.slider:cimaPoint (0, 13)
	window.container_alvos.slider:baixoPoint (0, -13)

	window.container_alvos.slider.thumb:SetTexture ([[Interface\AddOns\Details\images\icons2]])
	window.container_alvos.slider.thumb:SetTexCoord (482/512, 492/512, 104/512, 120/512)
	window.container_alvos.slider.thumb:SetSize (12, 12)
	window.container_alvos.slider.thumb:SetVertexColor (0.6, 0.6, 0.6, 0.95)

	--class icon
	window.SetClassIcon = function (player, class)
		if (player.spellicon) then
			window.classe_icone:SetTexture(player.spellicon)
			window.classe_icone:SetTexCoord(.1, .9, .1, .9)
	
		elseif (player.spec) then

		-- if (player.spec) then
			window.classe_icone:SetTexture ([[Interface\AddOns\Details\images\spec_icons_normal_alpha]])
			window.classe_icone:SetTexCoord (_unpack (_detalhes.class_specs_coords [player.spec]))
			--esta_barra.icone_classe:SetVertexColor (1, 1, 1)
		else
			local coords = CLASS_ICON_TCOORDS [class]
			if (coords) then
				info.classe_icone:SetTexture ([[Interface\Glues\CHARACTERCREATE\UI-CHARACTERCREATE-CLASSES]])
				local l, r, t, b = unpack (coords)
				info.classe_icone:SetTexCoord (l+0.01953125, r-0.01953125, t+0.01953125, b-0.01953125)
			else

				local c = _detalhes.class_coords ["MONSTER"]
				info.classe_icone:SetTexture ("Interface\\AddOns\\Details\\images\\classes")
				info.classe_icone:SetTexCoord (c[1], c[2], c[3], c[4])
			end
		end
	end
end
_detalhes:InstallPDWSkin ("ElvUI", {func = elvui_skin, author = "Accidev", version = "v1.0", desc = "Skin compatible with ElvUI addon."})

--> search key: ~create ~inicio ~start
function gump:CriaJanelaInfo()

	--> cria a janela em si
	local este_gump = info
	este_gump.Loaded = true

	este_gump:SetFrameStrata ("HIGH")
	este_gump:SetToplevel (true)

	este_gump.extra_frames = {}

	--> fehcar com o esc
	tinsert (UISpecialFrames, este_gump:GetName())

	--> propriedades da janela
	este_gump:SetPoint ("CENTER", UIParent)

	este_gump:SetWidth (PLAYER_DETAILS_WINDOW_WIDTH)
	este_gump:SetHeight (PLAYER_DETAILS_WINDOW_HEIGHT)

	este_gump:EnableMouse (true)
	este_gump:SetResizable (false)
	este_gump:SetMovable (true)

	este_gump.SummaryWindowWidgets = CreateFrame ("Frame", "DetailsPlayerDetailsWindowSummaryWidgets", este_gump)
	local SWW = este_gump.SummaryWindowWidgets
	SWW:SetAllPoints()
	SummaryWidgets[#SummaryWidgets+1] = SWW

	local scaleBar = Details.gump:CreateScaleBar (este_gump, Details.player_details_window)
	este_gump:SetScale (Details.player_details_window.scale)

	--> joga a janela para a global
	_detalhes.janela_info = este_gump

	--> icone da classe no canto esquerdo superior
	este_gump.classe_icone = este_gump:CreateTexture (nil, "BACKGROUND")
	este_gump.classe_icone:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 4, 0)
	este_gump.classe_icone:SetWidth (64)
	este_gump.classe_icone:SetHeight (64)
	este_gump.classe_icone:SetDrawLayer ("BACKGROUND", 1)
	--> complemento do icone
	este_gump.classe_iconePlus = este_gump:CreateTexture (nil, "BACKGROUND")
	este_gump.classe_iconePlus:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 4, 0)
	este_gump.classe_iconePlus:SetWidth (64)
	este_gump.classe_iconePlus:SetHeight (64)
	este_gump.classe_iconePlus:SetDrawLayer ("BACKGROUND", 2)

	--> top left
	este_gump.bg1 = este_gump:CreateTexture ("DetailsPSWBackground", "BORDER")
	este_gump.bg1:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", 0, 0)
	este_gump.bg1:SetDrawLayer ("BORDER", 1)

	--> bot�o de fechar
	este_gump.close_button = _CreateFrame ("Button", nil, este_gump, "UIPanelCloseButton")
	este_gump.close_button:SetWidth (32)
	este_gump.close_button:SetHeight (32)
	este_gump.close_button:SetPoint ("TOPRIGHT", este_gump, "TOPRIGHT", 5, -8)
	este_gump.close_button:SetText ("X")
	este_gump.close_button:SetFrameLevel (este_gump:GetFrameLevel()+5)


	--> �cone da magia selecionada para mais detalhes
	este_gump.bg_icone_bg = este_gump:CreateTexture (nil, "ARTWORK")
	este_gump.bg_icone_bg:SetPoint ("TOPRIGHT", este_gump, "TOPRIGHT",  -15, -12)
	este_gump.bg_icone_bg:SetTexture ("Interface\\AddOns\\Details\\images\\icone_bg_fundo")
	este_gump.bg_icone_bg:SetDrawLayer ("ARTWORK", -1)
	este_gump.bg_icone_bg:Show()

	este_gump.bg_icone = este_gump:CreateTexture (nil, "OVERLAY")
	este_gump.bg_icone:SetPoint ("TOPRIGHT", este_gump, "TOPRIGHT",  -15, -12)
	este_gump.bg_icone:SetTexture ("Interface\\AddOns\\Details\\images\\icone_bg")
	este_gump.bg_icone:Show()

	--> bot�o de op��es
	local open_options = function()
		_detalhes:OpenOptionsWindow (info.instancia, false, 6)
		_detalhes:OpenOptionsWindow (info.instancia, false, 6)
	end
	este_gump.options_button = gump:CreateButton (este_gump, open_options, 16, 16, nil, nil, nil, [[Interface\Buttons\UI-OptionsButton]])
	este_gump.options_button:SetPoint ("TOPRIGHT", este_gump, "TOPRIGHT", -26, -16)
	este_gump.options_button:SetAlpha (0.5)
--	este_gump.options_button.button:GetNormalTexture():SetDesaturated (true)
	este_gump.options_button.tooltip = "Select Skin"

	--> desativando o bot�o de config
	este_gump.options_button:Hide()

	--> titulo
	gump:NewLabel (este_gump, este_gump, nil, "title_string", Loc ["STRING_PLAYER_DETAILS"], "GameFontHighlightLeft", 12, {227/255, 186/255, 4/255})
	este_gump.title_string:SetPoint ("CENTER", este_gump, "CENTER")
	este_gump.title_string:SetPoint ("TOP", este_gump, "TOP", 0, -18)

	este_gump.spell_icone = este_gump:CreateTexture (nil, "ARTWORK")
	este_gump.spell_icone:SetPoint ("BOTTOMRIGHT", este_gump.bg_icone, "BOTTOMRIGHT",  -19, 2)
	este_gump.spell_icone:SetWidth (35)
	este_gump.spell_icone:SetHeight (34)
	este_gump.spell_icone:SetDrawLayer ("ARTWORK", 0)
	este_gump.spell_icone:Show()
	este_gump.spell_icone:SetTexCoord (4/64, 60/64, 4/64, 60/64)

	--> coisinhas do lado do icone
	este_gump.apoio_icone_esquerdo = este_gump:CreateTexture (nil, "ARTWORK")
	este_gump.apoio_icone_direito = este_gump:CreateTexture (nil, "ARTWORK")
	este_gump.apoio_icone_esquerdo:SetTexture ("Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs")
	este_gump.apoio_icone_direito:SetTexture ("Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs")

	local apoio_altura = 13/256
	este_gump.apoio_icone_esquerdo:SetTexCoord (0, 1, 0, apoio_altura)
	este_gump.apoio_icone_direito:SetTexCoord (0, 1, apoio_altura+(1/256), apoio_altura+apoio_altura)

	este_gump.apoio_icone_esquerdo:SetPoint ("BOTTOMRIGHT", este_gump.bg_icone, "BOTTOMLEFT",  42, 0)
	este_gump.apoio_icone_direito:SetPoint ("BOTTOMLEFT", este_gump.bg_icone, "BOTTOMRIGHT",  -17, 0)

	este_gump.apoio_icone_esquerdo:SetWidth (64)
	este_gump.apoio_icone_esquerdo:SetHeight (13)
	este_gump.apoio_icone_direito:SetWidth (64)
	este_gump.apoio_icone_direito:SetHeight (13)


-------------------------------------------------

	local alpha_bgs = 1

	-- backgrounds das 5 boxes do lado direito
		local right_background_X = 457
		local right_background_Y = {-85, -136, -191, -246, -301}

		for i = 1, spellInfoSettings.amount do
			local right_background1 = CreateFrame ("Frame", "DetailsPlayerDetailsWindow_right_background" .. i, SWW)
			right_background1:EnableMouse (false)
			right_background1:SetPoint ("TOPLEFT", este_gump, "TOPLEFT", right_background_X, right_background_Y [i])
			right_background1:SetSize (220, 43)
			Details.gump:ApplyStandardBackdrop (right_background1)
			este_gump ["right_background" .. i] = right_background1
		end

	-- fundos especiais de friendly fire e outros
		este_gump.bg1_sec_texture = SWW:CreateTexture ("DetailsPlayerDetailsWindow_BG1_SEC_Texture", "BORDER")
		este_gump.bg1_sec_texture:SetDrawLayer ("BORDER", 4)
		este_gump.bg1_sec_texture:SetPoint ("TOPLEFT", este_gump.bg1, "TOPLEFT", 450, -86)
		este_gump.bg1_sec_texture:SetHeight (462)
		-- vstavka 300
		este_gump.bg1_sec_texture:SetWidth (264)

		este_gump.bg2_sec_texture = SWW:CreateTexture ("DetailsPlayerDetailsWindow_BG2_SEC_Texture", "BORDER")
		este_gump.bg2_sec_texture:SetDrawLayer ("BORDER", 3)
		este_gump.bg2_sec_texture:SetPoint ("TOPLEFT", este_gump.bg1_sec_texture, "TOPLEFT", 8, 0)
		este_gump.bg2_sec_texture:SetPoint ("BOTTOMRIGHT", este_gump.bg1_sec_texture, "BOTTOMRIGHT", -30, 0)
		este_gump.bg2_sec_texture:Hide()

		este_gump.bg3_sec_texture = SWW:CreateTexture ("DetailsPlayerDetailsWindow_BG3_SEC_Texture", "BORDER")
		este_gump.bg3_sec_texture:SetDrawLayer ("BORDER", 2)
		este_gump.bg3_sec_texture:SetPoint ("TOPLEFT", este_gump.bg2_sec_texture, "TOPLEFT", 0, 0)
		este_gump.bg3_sec_texture:SetPoint ("BOTTOMRIGHT", este_gump.bg2_sec_texture, "BOTTOMRIGHT", 0, 0)
		--este_gump.bg3_sec_texture:SetTexture (0, 0, 0, 1)
		este_gump.bg3_sec_texture:Hide()

		este_gump.no_targets = SWW:CreateTexture ("DetailsPlayerDetailsWindow_no_targets", "overlay")
		este_gump.no_targets:SetPoint ("BOTTOMLEFT", este_gump, "BOTTOMLEFT", 20, 6)
		este_gump.no_targets:SetSize (301, 100)
		este_gump.no_targets:SetTexture ([[Interface\QUESTFRAME\UI-QUESTLOG-EMPTY-TOPLEFT]])
		este_gump.no_targets:SetTexCoord (0.015625, 1, 0.01171875, 0.390625)
		este_gump.no_targets:SetDesaturated (true)
		este_gump.no_targets:SetAlpha (.7)
		este_gump.no_targets.text = SWW:CreateFontString (nil, "overlay", "GameFontNormal")
		este_gump.no_targets.text:SetPoint ("CENTER", este_gump.no_targets, "CENTER")
		este_gump.no_targets.text:SetText (Loc ["STRING_NO_TARGET_BOX"])
		este_gump.no_targets.text:SetTextColor (1, 1, 1, .4)
		este_gump.no_targets:Hide()

	--> cria os textos da janela
	cria_textos (este_gump, SWW)

	--> cria o frama que vai abrigar as barras das habilidades
	cria_container_barras (este_gump, SWW)

	--> cria o container que vai abrirgar as 5 barras de detalhes
	cria_container_detalhes (este_gump, SWW)

	--> cria o container onde vai abrigar os alvos do jogador
	cria_container_alvos (este_gump, SWW)

	local leftbars1_backgound = CreateFrame ("Frame", "DetailsPlayerDetailsWindow_Left_SpellsBackground", SWW)
	leftbars1_backgound:EnableMouse (false)
	leftbars1_backgound:SetSize (303, 149)
	leftbars1_backgound:SetAlpha (alpha_bgs)
	leftbars1_backgound:SetFrameLevel (SWW:GetFrameLevel())
	Details.gump:ApplyStandardBackdrop (leftbars1_backgound)
	este_gump.leftbars1_backgound = leftbars1_backgound

	local leftbars2_backgound = CreateFrame ("Frame", "DetailsPlayerDetailsWindow_Left_TargetBackground", SWW)
	leftbars2_backgound:EnableMouse (false)
	leftbars2_backgound:SetSize (303, 122)
	leftbars2_backgound:SetAlpha (alpha_bgs)
	leftbars2_backgound:SetFrameLevel (SWW:GetFrameLevel())
	Details.gump:ApplyStandardBackdrop (leftbars2_backgound)
	este_gump.leftbars2_backgound = leftbars2_backgound

	leftbars1_backgound:SetPoint ("TOPLEFT", este_gump.container_barras, "TOPLEFT", -3, 3)
	leftbars1_backgound:SetPoint ("BOTTOMRIGHT", este_gump.container_barras, "BOTTOMRIGHT", 3, -3)
	leftbars2_backgound:SetPoint ("TOPLEFT", este_gump.container_alvos, "TOPLEFT", -3, 23)
	leftbars2_backgound:SetPoint ("BOTTOMRIGHT", este_gump.container_alvos, "BOTTOMRIGHT", 3, 0)

	--> cria as 5 barras de detalhes a direita da janela
	cria_barras_detalhes()

	--> seta os scripts dos frames da janela
	seta_scripts (este_gump)

	--> vai armazenar os objetos das barras de habilidade
	este_gump.barras1 = {}

	--> vai armazenar os objetos das barras de alvos
	este_gump.barras2 = {}

	--> vai armazenar os objetos das barras da caixa especial da direita
	este_gump.barras3 = {}

	este_gump.SetClassIcon = default_icon_change

	--> bot�o de reportar da caixa da esquerda, onde fica as barras principais
	este_gump.report_esquerda = gump:NewDetailsButton (SWW, este_gump, nil, _detalhes.Reportar, este_gump, 1, 16, 16,
	"Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", nil, "DetailsJanelaInfoReport2")
	--este_gump.report_esquerda:SetPoint ("BOTTOMLEFT", este_gump.container_barras, "TOPLEFT",  281, 3)
	este_gump.report_esquerda:SetPoint ("BOTTOMLEFT", este_gump.container_barras, "TOPLEFT",  33, 3)
	este_gump.report_esquerda:SetFrameLevel (este_gump:GetFrameLevel()+2)
	este_gump.topleft_report = este_gump.report_esquerda

	--> bot�o de reportar da caixa dos alvos
	este_gump.report_alvos = gump:NewDetailsButton (SWW, este_gump, nil, _detalhes.Reportar, este_gump, 3, 16, 16,
	"Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", nil, "DetailsJanelaInfoReport3")
	este_gump.report_alvos:SetPoint ("BOTTOMRIGHT", este_gump.container_alvos, "TOPRIGHT",  -2, -1)
	este_gump.report_alvos:SetFrameLevel (3) --> solved inactive problem

	--> bot�o de reportar da caixa da direita, onde est�o os 5 quadrados
	este_gump.report_direita = gump:NewDetailsButton (SWW, este_gump, nil, _detalhes.Reportar, este_gump, 2, 16, 16,
	"Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", "Interface\\COMMON\\VOICECHAT-ON", nil, "DetailsJanelaInfoReport4")
	este_gump.report_direita:SetPoint ("TOPRIGHT", este_gump, "TOPRIGHT",  -10, -70)
	este_gump.report_direita:Show()

	--> statusbar
	local statusBar = CreateFrame ("Frame", nil, este_gump)
	statusBar:SetPoint ("BOTTOMLEFT", este_gump, "BOTTOMLEFT")
	statusBar:SetPoint ("BOTTOMRIGHT", este_gump, "BOTTOMRIGHT")
	statusBar:SetHeight (PLAYER_DETAILS_STATUSBAR_HEIGHT)
	DetailsFramework:ApplyStandardBackdrop (statusBar)
	statusBar:SetAlpha (PLAYER_DETAILS_STATUSBAR_ALPHA)

	statusBar.Text = DetailsFramework:CreateLabel (statusBar)
	statusBar.Text:SetPoint ("LEFT", 2, 0)

	function este_gump:SetStatusbarText (text, fontSize, fontColor)
		if (not text) then
			este_gump:SetStatusbarText ("Details! Damage Meter | Use '/details stats' for statistics", 10, "gray")
			return
		end
		statusBar.Text.text = text
		statusBar.Text.fontsize = fontSize
		statusBar.Text.fontcolor = fontColor
	end

	--set default text
	este_gump:SetStatusbarText()

	--> apply default skin
	_detalhes:ApplyPDWSkin()

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> tabs

	local red = "FFFFAAAA"
	local green = "FFAAFFAA"

	--> tabs:
	--> tab default

	local iconTableSummary = {
		texture = [[Interface\AddOns\Details\images\icons]],
		coords = {238/512, 255/512, 0, 18/512},
		width = 16,
		height = 16,
	}

	_detalhes:CreatePlayerDetailsTab ("Summary", Loc ["STRING_SPELLS"], --[1] tab name [2] localized name
			function (tabOBject, playerObject) --[2] condition
				if (playerObject) then
					return true
				else
					return false
				end
			end,
			nil, --[3] fill function
			function() --[4] onclick
				for _, tab in _ipairs (_detalhes.player_details_tabs) do
					tab.frame:Hide()
				end
			end,
			nil, --[5] oncreate
			iconTableSummary --icon table
	)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> ~auras

	local auras_tab_create = function (tab, frame)
		local DF = _detalhes.gump
		local scroll_line_amount = 22
		local scroll_width = 410
		local scrollHeight = 445
		local scroll_line_height = 19
		local text_size = 10

		local debuffScrollStartX = 445

		local headerOffsetsBuffs = {
			--buff label, uptime, applications, refreshes, wa
			6, 190, 290, 336, 380
		}

		local headerOffsetsDebuffs = {
			--debuff label, uptime, applications, refreshes, wa
			426, 630, 729, 775, 820
		}

		local line_onenter = function (self)
			GameTooltip:SetOwner (self, "ANCHOR_TOPRIGHT")
			_detalhes:GameTooltipSetSpellByID (self.spellID)
			GameTooltip:Show()
			self:SetBackdropColor (1, 1, 1, .2)
		end

		local line_onleave = function (self)
			GameTooltip:Hide()
			self:SetBackdropColor (unpack (self.BackgroundColor))
		end

		local line_onclick = function (self)

		end

		--buff scroll
		--icon - name - applications - refreshes - uptime
		--

		local wa_button = function (self, mouseButton, spellID, auraType)
			if spellID then
			local spellName, _, spellIcon = GetSpellInfo (spellID)
			_detalhes:OpenAuraPanel (spellID, spellName, spellIcon, nil, auraType == "BUFF" and 4 or 2, 1)
			else
				print("У вас не установлен аддон WeakAuras")
			end
		end

		local scroll_createline = function (self, index)
			local line = CreateFrame ("button", "$parentLine" .. index, self)
			line:SetPoint ("TOPLEFT", self, "TOPLEFT", 1, -((index-1)*(scroll_line_height+1)))
			line:SetSize (scroll_width -2, scroll_line_height)
			line:SetScript ("OnEnter", line_onenter)
			line:SetScript ("OnLeave", line_onleave)
			line:SetScript ("OnClick", line_onclick)

			line:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
			line:SetBackdropColor (0, 0, 0, 0.2)

			local icon = line:CreateTexture ("$parentIcon", "overlay")
			icon:SetSize (scroll_line_height -2 , scroll_line_height - 2)
			local name = line:CreateFontString ("$parentName", "overlay", "GameFontNormal")
			local uptime = line:CreateFontString ("$parentName", "overlay", "GameFontNormal")
			local apply = line:CreateFontString ("$parentName", "overlay", "GameFontNormal")
			local refresh = line:CreateFontString ("$parentName", "overlay", "GameFontNormal")

			local waButton = DF:CreateButton (line, wa_button, 18, 18)
			waButton:SetIcon ([[Interface\AddOns\WeakAuras\Media\Textures\icon]])

			DF:SetFontSize (name, text_size)
			DF:SetFontSize (uptime, text_size)
			DF:SetFontSize (apply, text_size)
			DF:SetFontSize (refresh, text_size)

			icon:SetPoint ("LEFT", line, "LEFT", 2, 0)
			name:SetPoint ("LEFT", icon, "RIGHT", 2, 0)
			uptime:SetPoint ("LEFT", line, "LEFT", 186, 0)
			apply:SetPoint ("LEFT", line, "LEFT", 276, 0)
			refresh:SetPoint ("LEFT", line, "LEFT", 322, 0)
			waButton:SetPoint ("LEFT", line, "LEFT", 372, 0)

			line.Icon = icon
			line.Name = name
			line.Uptime = uptime
			line.Apply = apply
			line.Refresh = refresh
			line.WaButton = waButton

			name:SetJustifyH ("LEFT")
			uptime:SetJustifyH ("LEFT")

			apply:SetJustifyH ("CENTER")
			refresh:SetJustifyH ("CENTER")
			apply:SetWidth (26)
			refresh:SetWidth (26)

			return line
		end

		local line_bg_color = {{1, 1, 1, .1}, {1, 1, 1, 0}}

		local scroll_buff_refresh = function (self, data, offset, total_lines)

			local haveWA = _G.WeakAuras

			for i = 1, total_lines do
				local index = i + offset
				local aura = data [index]

				if (aura) then
					local line = self:GetLine (i)
					line.spellID = aura.spellID
					line.Icon:SetTexture (aura [1])

					line.Icon:SetTexCoord (.1, .9, .1, .9)

					line.Name:SetText (aura [2])
					line.Uptime:SetText (DF:IntegerToTimer (aura [3]) .. " (|cFFBBAAAA" .. floor (aura [6]) .. "%|r)")
					line.Apply:SetText (aura [4])
					line.Refresh:SetText (aura [5])

					if (haveWA) then
						line.WaButton:SetClickFunction (wa_button, aura.spellID, line.AuraType)
					else
						line.WaButton:Disable()
					end

					if (i%2 == 0) then
						line:SetBackdropColor (unpack (line_bg_color [1]))
						line.BackgroundColor = line_bg_color [1]
					else
						line:SetBackdropColor (unpack (line_bg_color [2]))
						line.BackgroundColor = line_bg_color [2]
					end
				end
			end
		end

		local create_titledesc_frame = function (anchorWidget, desc)
			local f = CreateFrame ("Button", nil, frame)
			f:SetSize (40, 20)
			f:SetPoint ("CENTER", anchorWidget, "CENTER")
			f:SetScript ("OnEnter", function()
				GameTooltip:SetOwner (f, "ANCHOR_TOPRIGHT")
				GameTooltip:AddLine (desc)
				GameTooltip:Show()
			end)
			f:SetScript ("OnLeave", function()
				GameTooltip:Hide()
			end)
			return f
		end



		local buffLabel = DF:CreateLabel (frame, Loc["Buff Name"])
		buffLabel:SetPoint (headerOffsetsBuffs[1], -10)
		local uptimeLabel = DF:CreateLabel (frame, Loc["Uptime"])
		uptimeLabel:SetPoint (headerOffsetsBuffs[2], -10)

		local appliedLabel = DF:CreateLabel (frame, "A")
		appliedLabel:SetPoint (headerOffsetsBuffs[3], -10)
		create_titledesc_frame (appliedLabel.widget, Loc["applications"])

		local refreshedLabel = DF:CreateLabel (frame, "R")
		refreshedLabel:SetPoint (headerOffsetsBuffs[4], -10)
		create_titledesc_frame (refreshedLabel.widget, Loc["refreshes"])

		local waLabel = DF:CreateLabel (frame, "WA")
		waLabel:SetPoint (headerOffsetsBuffs[5], -10)
		create_titledesc_frame (waLabel.widget, Loc["create weak aura"])

		local buffScroll = DF:CreateScrollBox (frame, "$parentBuffUptimeScroll", scroll_buff_refresh, {}, scroll_width, scrollHeight, scroll_line_amount, scroll_line_height)
		buffScroll:SetPoint ("TOPLEFT", frame, "TOPLEFT", 5, -30)
		for i = 1, scroll_line_amount do
			local line = buffScroll:CreateLine (scroll_createline)
			line.AuraType = "BUFF"
		end
		DF:ReskinSlider (buffScroll)
		tab.BuffScroll = buffScroll

		--debuff scroll
		--icon - name - applications - refreshes - uptime
		--

		local debuffLabel = DF:CreateLabel (frame, Loc["Debuff Name"])
		debuffLabel:SetPoint (headerOffsetsDebuffs[1], -10)
		local uptimeLabel2 = DF:CreateLabel (frame, Loc["Uptime"])
		uptimeLabel2:SetPoint (headerOffsetsDebuffs[2], -10)

		local appliedLabel2 = DF:CreateLabel (frame, "A")
		appliedLabel2:SetPoint (headerOffsetsDebuffs[3], -10)
		create_titledesc_frame (appliedLabel2.widget, Loc["applications"])

		local refreshedLabel2 = DF:CreateLabel (frame, "R")
		refreshedLabel2:SetPoint (headerOffsetsDebuffs[4], -10)
		create_titledesc_frame (refreshedLabel2.widget, Loc["refreshes"])

		local waLabel2 = DF:CreateLabel (frame, "WA")
		waLabel2:SetPoint (headerOffsetsDebuffs[5], -10)
		create_titledesc_frame (waLabel2.widget, Loc["create weak aura"])



		local debuffScroll = DF:CreateScrollBox (frame, "$parentDebuffUptimeScroll", scroll_buff_refresh, {}, scroll_width, scrollHeight, scroll_line_amount, scroll_line_height)
		debuffScroll:SetPoint ("TOPLEFT", frame, "TOPLEFT", debuffScrollStartX, -30)
		for i = 1, scroll_line_amount do
			local line = debuffScroll:CreateLine (scroll_createline)
			line.AuraType = "DEBUFF"
		end
		DF:ReskinSlider (debuffScroll)

		tab.DebuffScroll = debuffScroll
	end

	local auras_tab_fill = function (tab, player, combat)

		local miscActor = combat:GetActor (4, player:name())
		local combatTime = combat:GetCombatTime()

		do --buffs
			local newAuraTable = {}
			if (miscActor and miscActor.buff_uptime_spells) then
				for spellID, spellObject in _pairs (miscActor.buff_uptime_spells._ActorTable) do
					local spellName, _, spellIcon = GetSpellInfo (spellID)
					newAuraTable[#newAuraTable+1] = {spellIcon, spellName, spellObject.uptime, spellObject.appliedamt, spellObject.refreshamt, spellObject.uptime/combatTime*100, spellID = spellID}
				end
			end
			_table_sort (newAuraTable, _detalhes.Sort3)
			tab.BuffScroll:SetData (newAuraTable)
			tab.BuffScroll:Refresh()
		end

		do --debuffs
			local newAuraTable = {}
			if (miscActor and miscActor.debuff_uptime_spells) then
				for spellID, spellObject in _pairs (miscActor.debuff_uptime_spells._ActorTable) do
					local spellName, _, spellIcon = GetSpellInfo (spellID)
					newAuraTable[#newAuraTable+1] = {spellIcon, spellName, spellObject.uptime, spellObject.appliedamt, spellObject.refreshamt, spellObject.uptime/combatTime*100, spellID = spellID}
				end
			end
			_table_sort (newAuraTable, _detalhes.Sort3)
			tab.DebuffScroll:SetData (newAuraTable)
			tab.DebuffScroll:Refresh()
		end
	end

	local iconTableAuras = {
		texture = [[Interface\AddOns\Details\images\icons]],
		coords = {257/512, 278/512, 0/512, 19/512},
		width = 16,
		height = 16,
	}

	_detalhes:CreatePlayerDetailsTab ("Auras", --[1] tab name
		Loc["Auras"],  --[2] localized name
		function (tabOBject, playerObject)  --[2] condition
			return true
		end,

		auras_tab_fill, --[3] fill function

		nil, --[4] onclick

		auras_tab_create, --[5] oncreate
		iconTableAuras --icon table
	)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> ~compare

		local target_texture = [[Interface\Icons\Ability_Hunter_SniperShot]]
		local empty_text = ""

		local plus = red .. "-"
		local minor = green .. "+"

		local bar_color = {.5, .5, .5, .4} -- bar of the second and 3rd player
		local bar_color_on_enter = {.9, .9, .9, .9}

		local frame_backdrop = {edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]], tileSize = 64, tile = true}
		local frame_backdrop_color = {0, 0, 0, 0.35}
		local frame_backdrop_border_color = {0, 0, 0, 0}

		local spell_compare_frame_width = {298, 225, 226}
		local spell_compare_frame_height = 200
		local target_compare_frame_height = 142

		local faction_spells = {
			[31803] = 53742, [53742] = 31803,
			[42463] = 53739, [53739] = 42463,
			[31804] = 53733, [53733] = 31804,
			[31893] = 53719, [53719] = 31893,
			[32221] = 53718, [53718] = 32221,
			[31898] = 53726, [53726] = 31898,
			[32220] = 53725, [53725] = 32220,
		}

		local xLocation = 2
		local yLocation = -20
		local targetBars = 9

		local clear_compare_bar = function (bar)
			bar [1]:SetTexture (nil)
			bar [2].lefttext:SetText (empty_text)
			bar [2].lefttext:SetTextColor (.5, .5, .5, 1)
			bar [2].righttext:SetText ("")
			bar [2].righttext2:SetText ("")
			bar [2]:SetValue (0)
			bar [2]:SetBackdropColor (1, 1, 1, 0)
		end

		local percent_diff = function (value, base)
			local percent = _math_floor ((value - base) / base * 100)
			if (percent > 999) then
				return "" .. 999
			end
			return percent
		end

		local sorted_targets = function (actor)
			local pool = {}
			for target_name, amount in _pairs (actor.targets) do
				pool [#pool+1] = {target_name, amount}
			end
			_table_sort (pool, _detalhes.Sort2)
			return pool
		end

		local fill_compare_target_bar = function (bar, other_player, other_pool, target_name, amount)
			local total, target_index
			if (other_player) then
				for index, t in _ipairs (other_pool) do
					if (t[1] == target_name) then
						total, target_index = t[2], index
						break
					end
				end
			end

			if (not total) then
				clear_compare_bar (bar)
				bar [3][4] = nil
				return
			end

			bar [1]:SetTexture (target_texture)
			bar [1]:SetDesaturated (true)
			bar [1]:SetAlpha (.7)

			bar [2].lefttext:SetText (target_index .. ". " .. target_name)
			bar [2].lefttext:SetTextColor (1, 1, 1, 1)
			bar [2].righttext2:SetText (_detalhes:ToK2Min (total))
			if (amount > total) then
				bar [2].righttext:SetText (" |c" .. minor .. percent_diff (amount, total) .. "%|r")
			else
				bar [2].righttext:SetText (" |c" .. plus .. percent_diff (total, amount) .. "%|r")
			end
			bar [2]:SetValue (100)

			bar [3][1] = other_player.nome
			bar [3][2] = target_name
			bar [3][3] = total
			bar [3][4] = other_player
		end

		local fill_compare_targets = function (self, player, other_players, target_pool)

			local offset = FauxScrollFrame_GetOffset (self)

			local frame2 = DetailsPlayerComparisonTarget2
			local frame3 = DetailsPlayerComparisonTarget3


			if (not target_pool [1]) then
				for i = 1, targetBars do
					local bar = self.bars [i]
					local bar_2 = frame2.bars [i]
					local bar_3 = frame3.bars [i]

					clear_compare_bar (bar)
					bar [3][4] = nil
					clear_compare_bar (bar_2)
					bar_2 [3][4] = nil
					clear_compare_bar (bar_3)
					bar_3 [3][4] = nil
				end

				return
			end

			local top = target_pool [1] [2]

			local player_2 = other_players [1]
			local player_2_target_pool = player_2 and sorted_targets (player_2)

			local player_3 = other_players [2]
			local player_3_target_pool = player_3 and sorted_targets (player_3)

			for i = 1, targetBars do
				local bar = self.bars [i]
				local bar_2 = frame2.bars [i]
				local bar_3 = frame3.bars [i]

				local index = i + offset
				local data = target_pool [index]

				if (data) then --[name] [total]

					local target_name = data [1]

					bar [1]:SetTexture (target_texture)
					bar [1]:SetDesaturated (true)
					bar [1]:SetAlpha (.7)

					bar [2].lefttext:SetText (index .. ". " .. target_name)
					bar [2].lefttext:SetTextColor (1, 1, 1, 1)
					bar [2].righttext:SetText (_detalhes:ToK2Min (data [2])) -- .. " (" .. _math_floor (data [2] / total * 100) .. "%)"
					bar [2]:SetValue (data [2] / top * 100)
					--bar [2]:SetValue (100)
					bar [3][1] = player.nome --name
					bar [3][2] = target_name
					bar [3][3] = data [2] --total
					bar [3][4] = player

					fill_compare_target_bar (bar_2, player_2, player_2_target_pool, target_name, data [2])
					fill_compare_target_bar (bar_3, player_3, player_3_target_pool, target_name, data [2])

				else
					clear_compare_bar (bar)
					bar [3][4] = nil
					clear_compare_bar (bar_2)
					bar_2 [3][4] = nil
					clear_compare_bar (bar_3)
					bar_3 [3][4] = nil
				end
			end

		end

		local sorted_spells_with_pets = function (actor, container)
			local spells_sorted = {}
			for spellid, spelltable in _pairs (actor.spells._ActorTable) do
				spells_sorted [#spells_sorted+1] = {spelltable, spelltable.total}
			end
			for petIndex, petName in _ipairs (actor:Pets()) do
				local petActor = container:PegarCombatente (nil, petName)
				if (petActor) then
					for _spellid, _skill in _pairs (petActor:GetActorSpells()) do
						spells_sorted [#spells_sorted+1] = {_skill, _skill.total, petName}
					end
				end
			end
			_table_sort (spells_sorted, _detalhes.Sort2)
			return spells_sorted
		end

		local spell_index_map = function (spells_sorted)
			local map = {}
			for index, spelltable in _ipairs (spells_sorted) do
				map [spelltable[1].id] = index
			end
			return map
		end

		local fill_compare_spell_bar = function (bar, other_player, other_spell_info, data, spellid, name, icon, petName, container)
			local spell = other_player and (other_player.spells._ActorTable [spellid] or other_player.spells._ActorTable [faction_spells [spellid]])

			if (not spell and petName and other_player) then
				for _petIndex, _petName in _ipairs (other_player:Pets()) do
					if (_petName:gsub (" <.*", "") == petName:gsub (" <.*", "")) then
						local petActor = container:PegarCombatente (nil, _petName)
						spell = petActor and petActor.spells._ActorTable [spellid]
						name = name .. " (|cFFCCBBBB" .. _petName:gsub (" <.*", "") .. "|r)"
					end
				end
			end

			bar [3][4] = spell and spell.id
			if (not spell) then
				return clear_compare_bar (bar)
			end

			bar [1]:SetTexture (spell.id == spellid and icon or select (3, _GetSpellInfo (spell.id)))
			bar [1]:SetTexCoord (unpack (IconTexCoord))
			bar [2].lefttext:SetText (other_spell_info [spell.id] .. ". " .. (spell.id == spellid and name or _GetSpellInfo (spell.id)))
			bar [2].lefttext:SetTextColor (1, 1, 1, 1)
			bar [2]:SetStatusBarColor (unpack (bar_color))
			bar [2]:SetBackdropColor (1, 1, 1, 0.1)

			if (data [2] > spell.total and spell.total > 0) then
				bar [2].righttext2:SetText (_detalhes:ToK2Min (spell.total))
				bar [2].righttext:SetText (" |c" .. minor .. percent_diff (data [2], spell.total) .. "%|r")
			elseif (data [2] <= spell.total and data [2] > 0) then
				bar [2].righttext2:SetText (_detalhes:ToK2Min (spell.total))
				bar [2].righttext:SetText (" |c" .. plus .. percent_diff (spell.total, data [2]) .. "%|r")
			else
				bar [2].righttext2:SetText ("0")
				bar [2].righttext:SetText ("+0%")
			end

			bar [2]:SetValue (100)
			bar [3][1] = spell.counter
			bar [3][2] = spell.total / spell.counter
			bar [3][3] = _math_floor (spell.c_amt / spell.counter * 100)
		end

		local fill_compare_actors = function (self, player, other_players)

			local container = info.instancia.showing [player.tipo]
			local spells_sorted = sorted_spells_with_pets (player, container)

			self.player = player:Name()

			local offset = FauxScrollFrame_GetOffset (self)

			local top = spells_sorted [1] and spells_sorted [1] [2] or 0

			local frame2 = DetailsPlayerComparisonBox2
			local frame3 = DetailsPlayerComparisonBox3

			local player_2, player_3 = other_players [1], other_players [2]
			local player_2_spell_info, player_3_spell_info

			if (player_2) then
				frame2.player = player_2:Name()
				player_2_spell_info = spell_index_map (sorted_spells_with_pets (player_2, container))
				frame2.NoPLayersToShow:Hide()
				frame3.NoPLayersToShow:Hide()
			else
				frame2.NoPLayersToShow:Show()
				frame3.NoPLayersToShow:Show()
			end

			if (player_3) then
				frame3.player = player_3:Name()
				player_3_spell_info = spell_index_map (sorted_spells_with_pets (player_3, container))
			end

			for i = 1, 12 do
				local bar = self.bars [i]
				local index = i + offset

				--main player spells
				local data = spells_sorted [index]

				if (data) then --if exists

					--main player - seta no primeiro box
						local spellid = data [1].id
						local name, _, icon = _GetSpellInfo (spellid)
						if (not name) then
							--no spell found? - tbc problem
							return
						end
						local petName = data [3]

						bar [1]:SetTexture (icon) --bar[1] = spellicon bar[2] = statusbar
						bar [1]:SetTexCoord (unpack (IconTexCoord)) --bar[1] = spellicon bar[2] = statusbar

						bar [2]:SetBackdropColor (1, 1, 1, 0.1)

						if (petName) then
							bar [2].lefttext:SetText (index .. ". " .. name .. " (|cFFCCBBBB" .. petName:gsub (" <.*", "") .. "|r)")
						else
							bar [2].lefttext:SetText (index .. ". " .. name)
						end
						bar [2].lefttext:SetTextColor (1, 1, 1, 1)
						bar [2].righttext:SetText (_detalhes:ToK2Min (data [2])) -- .. " (" .. _math_floor (data [2] / total * 100) .. "%)"
						bar [2]:SetValue (data [2] / top * 100)
						--bar [2]:SetValue (100)
						bar [3][1] = data [1].counter --tooltip hits
						bar [3][2] = data [2] / data [1].counter --tooltip average
						bar [3][3] = _math_floor (data [1].c_amt / data [1].counter * 100) --tooltip critical
						bar [3][4] = spellid

					fill_compare_spell_bar (frame2.bars [i], player_2, player_2_spell_info, data, spellid, name, icon, petName, container)
					fill_compare_spell_bar (frame3.bars [i], player_3, player_3_spell_info, data, spellid, name, icon, petName, container)
				else
					clear_compare_bar (bar)
					local bar_2 = frame2.bars [i]
					clear_compare_bar (bar_2)
					local bar_3 = frame3.bars [i]
					clear_compare_bar (bar_3)
				end

			end

		end

		local refresh_comparison_box = function (self)
			--atualiza a scroll
			fill_compare_actors (self, self.tab.player, self.tab.players)
			FauxScrollFrame_Update (self, self.tab.spells_amt, 12, 15)
			self:Show()
		end

		local refresh_target_box = function (self)

			local target_pool = sorted_targets (self.tab.player)

			FauxScrollFrame_Update (self, #target_pool, targetBars, 14)
			self:Show()

			fill_compare_targets (self, self.tab.player, self.tab.players, target_pool)
		end

		local compare_fill = function (tab, player, combat)
			local players_to_compare = tab.players

			local defaultPlayerName = _detalhes:GetOnlyName (player:Name())
			DetailsPlayerComparisonBox1.name_label:SetText (defaultPlayerName)

			local label2 = _G ["DetailsPlayerComparisonBox2"].name_label
			local label3 = _G ["DetailsPlayerComparisonBox3"].name_label

			local label2_percent = _G ["DetailsPlayerComparisonBox2"].name_label_percent
			local label3_percent = _G ["DetailsPlayerComparisonBox3"].name_label_percent

			if (players_to_compare [1]) then
				local playerName = _detalhes:GetOnlyName (players_to_compare [1]:Name())
				label2:SetText (playerName)
				label2_percent:SetText (defaultPlayerName .. " %")
			else
				label2:SetText ("")
				label2_percent:SetText ("")
			end
			if (players_to_compare [2]) then
				local playerName = _detalhes:GetOnlyName (players_to_compare [2]:Name())
				label3:SetText (playerName)
				label3_percent:SetText (defaultPlayerName .. " %")
			else
				label3:SetText ("")
				label3_percent:SetText ("")
			end

			refresh_comparison_box (DetailsPlayerComparisonBox1)
			refresh_target_box (DetailsPlayerComparisonTarget1)

		end

		local target_skills = function (actor, target_name)
			local skills = {}
			for spellid, spell in _pairs (actor.spells._ActorTable) do
				local amount = spell.targets [target_name]
				if (amount) then
					skills [#skills+1] = {spellid, amount}
				end
			end
			_table_sort (skills, _detalhes.Sort2)
			return skills
		end

		local fill_target_tooltip_row = function (tooltip, index, spell, other_skills, name, icon)
			local bar = tooltip.bars [index] or tooltip:CreateBar (index)
			for this_index, this_spell in _ipairs (other_skills) do
				if (spell [1] == this_spell [1]) then
					bar [1]:SetTexture (icon)
					bar [1]:SetTexCoord (unpack (IconTexCoord))
					bar [2].lefttext:SetText (this_index .. ". " .. name)
					bar [2].bg:Show()
					bar [2].righttext2:SetText (_detalhes:ToK2Min (this_spell [2]))
					if (spell [2] > this_spell [2]) then
						bar [2].righttext:SetText (" |c" .. minor .. percent_diff (spell [2], this_spell [2]) .. "%|r")
					else
						bar [2].righttext:SetText (" |c" .. plus .. percent_diff (this_spell [2], spell [2]) .. "%|r")
					end
					bar [2]:SetValue (100)
					return true
				end
			end
			bar [1]:SetTexture (nil)
			bar [2].lefttext:SetText ("")
			bar [2].righttext:SetText ("")
			bar [2].righttext2:SetText ("")
			bar [2].bg:Hide()
		end

		local on_enter_target = function (self)

			local frame1 = DetailsPlayerComparisonTarget1
			local frame2 = DetailsPlayerComparisonTarget2
			local frame3 = DetailsPlayerComparisonTarget3

			local bar1 = frame1.bars [self.index]
			local bar2 = frame2.bars [self.index]
			local bar3 = frame3.bars [self.index]

			local player_1 = bar1 [3] [4]
			if (not player_1) then
				return
			end
			local player_2 = bar2 [3] [4]
			local player_3 = bar3 [3] [4]

			local target_name = bar1 [3] [2]

			frame1.tooltip:SetPoint ("BOTTOMLEFT", bar1[2], "TOPLEFT", -18, 5)
			frame2.tooltip:SetPoint ("BOTTOMLEFT", bar2[2], "TOPLEFT", -18, 5)
			frame3.tooltip:SetPoint ("BOTTOMLEFT", bar3[2], "TOPLEFT", -18, 5)


			local player_1_skills = target_skills (player_1, target_name)
			local player_1_top = player_1_skills [1] and player_1_skills [1][2] or 0
			bar1 [2]:SetStatusBarColor (1, 1, 1, 1)

			local player_2_skills = player_2 and target_skills (player_2, target_name)
			if (player_2) then
				bar2 [2]:SetStatusBarColor (unpack (bar_color_on_enter))
			end

			local player_3_skills = player_3 and target_skills (player_3, target_name)
			if (player_3) then
				bar3 [2]:SetStatusBarColor (unpack (bar_color_on_enter))
			end

			-- build tooltip
			frame1.tooltip:Reset()
			frame2.tooltip:Reset()
			frame3.tooltip:Reset()

			frame1.tooltip:Show()
			frame2.tooltip:Show()
			frame3.tooltip:Show()

			local frame2_gotresults = false
			local frame3_gotresults = false

			for index, spell in _ipairs (player_1_skills) do
				local bar = frame1.tooltip.bars [index]
				if (not bar) then
					bar = frame1.tooltip:CreateBar()
				end

				local name, _, icon = _GetSpellInfo (spell[1])
				bar [1]:SetTexture (icon)
				bar [1]:SetTexCoord (unpack (IconTexCoord)) --bar[1] = spellicon bar[2] = statusbar
				bar [2].lefttext:SetText (index .. ". " .. name)
				bar [2].righttext:SetText (_detalhes:ToK2Min (spell [2]))
				bar [2]:SetValue (spell [2]/player_1_top*100)
				--bar [2]:SetValue (100)
				bar [2].bg:Show()

				if (player_2 and fill_target_tooltip_row (frame2.tooltip, index, spell, player_2_skills, name, icon)) then
					frame2_gotresults = true
				end

				if (player_3 and fill_target_tooltip_row (frame3.tooltip, index, spell, player_3_skills, name, icon)) then
					frame3_gotresults = true
				end

			end

			frame1.tooltip:SetHeight ( (#player_1_skills*15) + 2)
			frame2.tooltip:SetHeight ( (#player_1_skills*15) + 2)
			frame3.tooltip:SetHeight ( (#player_1_skills*15) + 2)

			if (not frame2_gotresults) then
				frame2.tooltip:Hide()
			end
			if (not frame3_gotresults) then
				frame3.tooltip:Hide()
			end

		end

		local leave_compare_bars = function (index, frame1, frame2, frame3)
			frame1.bars [index][2]:SetStatusBarColor (.5, .5, .5, 1)
			frame2.bars [index][2]:SetStatusBarColor (unpack (bar_color))
			frame3.bars [index][2]:SetStatusBarColor (unpack (bar_color))
			frame1.tooltip:Hide()
			frame2.tooltip:Hide()
			frame3.tooltip:Hide()
		end

		local on_leave_target = function (self)
			leave_compare_bars (self.index, DetailsPlayerComparisonTarget1, DetailsPlayerComparisonTarget2, DetailsPlayerComparisonTarget3)
		end

		local fill_compare_tooltip = function (frame, bar, player_misc, spellid, hits, average, critical, player1_uptime, player1_casts)
			local tooltip = frame.tooltip
			local data = bar [3]
			local COMPARE_UNKNOWNDATA = "-"

			bar [2]:SetStatusBarColor (unpack (bar_color_on_enter))
			bar [2].icon:SetTexCoord (.1, .9, .1, .9)

			tooltip.hits_label3:SetText (data [1])
			if (hits > data [1]) then
				tooltip.hits_label2:SetText (" |c" .. minor .. percent_diff (hits, data [1]) .. "%|r")
			else
				tooltip.hits_label2:SetText (" |c" .. plus .. percent_diff (data [1], hits) .. "%|r")
			end

			tooltip.average_label3:SetText (_detalhes:ToK2Min (data [2]))
			if (average > data [2]) then
				tooltip.average_label2:SetText (" |c" .. minor .. percent_diff (average, data [2]) .. "%|r")
			else
				tooltip.average_label2:SetText (" |c" .. plus .. percent_diff (data [2], average) .. "%|r")
			end

			tooltip.crit_label3:SetText (data [3] .. "%")
			if (critical > data [3]) then
				tooltip.crit_label2:SetText (" |c" .. minor .. percent_diff (critical, data [3]) .. "%|r")
			else
				local down = _math_floor ((data [3] - critical) / math.max (critical, 0.1) * 100)
				if (down > 999) then
					down = "" .. 999
				end
				tooltip.crit_label2:SetText (" |c" .. plus .. down .. "%|r")
			end

			if (not player_misc) then
				tooltip.casts_label3:SetText (COMPARE_UNKNOWNDATA)
				tooltip.casts_label2:SetText (COMPARE_UNKNOWNDATA)
				tooltip.uptime_label3:SetText (COMPARE_UNKNOWNDATA)
				tooltip.uptime_label2:SetText (COMPARE_UNKNOWNDATA)
				return tooltip:Show()
			end

			local this_spellid = data [4] or spellid

			local spell = player_misc.debuff_uptime_spells and player_misc.debuff_uptime_spells._ActorTable and player_misc.debuff_uptime_spells._ActorTable [this_spellid]
			if (spell and spell.uptime) then
				tooltip.uptime_label3:SetText (_math_floor (spell.uptime/60) .. "m" .. _math_floor (spell.uptime%60) .. "s")
				if (not player1_uptime) then
					tooltip.uptime_label2:SetText ("0%|r")
				elseif (player1_uptime > spell.uptime) then
					tooltip.uptime_label2:SetText ("|c" .. minor .. percent_diff (player1_uptime, spell.uptime) .. "%|r")
				else
					tooltip.uptime_label2:SetText ("|c" .. plus .. percent_diff (spell.uptime, player1_uptime) .. "%|r")
				end
				_detalhes.gump:SetFontColor (tooltip.uptime_label3, "white")
				_detalhes.gump:SetFontColor (tooltip.uptime_label2, "white")
			else
				tooltip.uptime_label3:SetText (COMPARE_UNKNOWNDATA)
				tooltip.uptime_label2:SetText (COMPARE_UNKNOWNDATA)
				_detalhes.gump:SetFontColor (tooltip.uptime_label3, "gray")
				_detalhes.gump:SetFontColor (tooltip.uptime_label2, "gray")
			end

			local amt_casts = player_misc.spell_cast and player_misc.spell_cast [this_spellid]
			if (not amt_casts) then
				local spellname = GetSpellInfo (this_spellid)
				for casted_spellid, amount in _pairs (player_misc.spell_cast or {}) do
					if (GetSpellInfo (casted_spellid) == spellname) then
						amt_casts = amount
						break
					end
				end
			end

			if (amt_casts) then
				tooltip.casts_label3:SetText (amt_casts)
				if (not player1_casts) then
					tooltip.casts_label2:SetText (COMPARE_UNKNOWNDATA)
				elseif (player1_casts > amt_casts) then
					tooltip.casts_label2:SetText (" |c" .. minor .. percent_diff (player1_casts, amt_casts) .. "%|r")
				else
					tooltip.casts_label2:SetText (" |c" .. plus .. percent_diff (amt_casts, player1_casts) .. "%|r")
				end
				_detalhes.gump:SetFontColor (tooltip.casts_label3, "white")
				_detalhes.gump:SetFontColor (tooltip.casts_label2, "white")
			else
				tooltip.casts_label3:SetText ("?")
				tooltip.casts_label2:SetText ("?")
				_detalhes.gump:SetFontColor (tooltip.casts_label3, "gray")
				_detalhes.gump:SetFontColor (tooltip.casts_label2, "gray")
			end

			tooltip:Show()
		end

		local on_enter = function (self)

			local frame1 = DetailsPlayerComparisonBox1
			local frame2 = DetailsPlayerComparisonBox2
			local frame3 = DetailsPlayerComparisonBox3

			local bar1 = frame1.bars [self.index]
			local bar2 = frame2.bars [self.index]
			local bar3 = frame3.bars [self.index]

			frame1.tooltip:SetPoint ("BOTTOMLEFT", bar1[2], "TOPLEFT", -18, 5)
			frame2.tooltip:SetPoint ("BOTTOMLEFT", bar2[2], "TOPLEFT", -18, 5)
			frame3.tooltip:SetPoint ("BOTTOMLEFT", bar3[2], "TOPLEFT", -18, 5)

			local spellid = bar1[3][4]
			local player1 = frame1.player
			local player2 = frame2.player
			local player3 = frame3.player

			local hits = bar1[3][1]
			local average = bar1[3][2]
			local critical = bar1[3][3]

			local player1_misc = info.instancia.showing (4, player1)
			local player2_misc = info.instancia.showing (4, player2)
			local player3_misc = info.instancia.showing (4, player3)

			local player1_uptime
			local player1_casts

			local COMPARE_FIRSTPLAYER_PERCENT = "100%"
			local COMPARE_UNKNOWNDATA = "-"

			if (bar1[2].righttext:GetText()) then
				bar1[2]:SetStatusBarColor (1, 1, 1, 1)
				bar1[2].icon:SetTexCoord (.1, .9, .1, .9)

				frame1.tooltip.hits_label3:SetText (hits)
				frame1.tooltip.average_label3:SetText (_detalhes:ToK2Min (average))
				frame1.tooltip.crit_label3:SetText (critical .. "%")

				--2 = far left text (percent comparison)
				--3 = total in numbers

				_detalhes.gump:SetFontColor (frame1.tooltip.hits_label2, "gray")
				_detalhes.gump:SetFontColor (frame1.tooltip.average_label2, "gray")
				_detalhes.gump:SetFontColor (frame1.tooltip.crit_label2, "gray")
				_detalhes.gump:SetFontColor (frame1.tooltip.casts_label2, "gray")
				_detalhes.gump:SetFontColor (frame1.tooltip.uptime_label2, "gray")

				frame1.tooltip.hits_label2:SetText (COMPARE_FIRSTPLAYER_PERCENT)
				frame1.tooltip.average_label2:SetText (COMPARE_FIRSTPLAYER_PERCENT)
				frame1.tooltip.crit_label2:SetText (COMPARE_FIRSTPLAYER_PERCENT)

				if (player1_misc) then

					--uptime
					local spell = player1_misc.debuff_uptime_spells and player1_misc.debuff_uptime_spells._ActorTable and player1_misc.debuff_uptime_spells._ActorTable [spellid]
					if (spell) then
						local minutos, segundos = _math_floor (spell.uptime/60), _math_floor (spell.uptime%60)
						player1_uptime = spell.uptime
						frame1.tooltip.uptime_label3:SetText (minutos .. "m" .. segundos .. "s")
						frame1.tooltip.uptime_label2:SetText (COMPARE_FIRSTPLAYER_PERCENT)
						_detalhes.gump:SetFontColor (frame1.tooltip.uptime_label2, "gray")
						_detalhes.gump:SetFontColor (frame1.tooltip.uptime_label3, "white")
					else
						frame1.tooltip.uptime_label3:SetText (COMPARE_UNKNOWNDATA)
						frame1.tooltip.uptime_label2:SetText (COMPARE_UNKNOWNDATA)
						_detalhes.gump:SetFontColor (frame1.tooltip.uptime_label2, "gray")
						_detalhes.gump:SetFontColor (frame1.tooltip.uptime_label3, "gray")
					end

					--total casts
					local amt_casts = player1_misc.spell_cast and player1_misc.spell_cast [spellid]
					if (amt_casts) then
						frame1.tooltip.casts_label3:SetText (amt_casts)
						frame1.tooltip.casts_label2:SetText (COMPARE_FIRSTPLAYER_PERCENT)

						_detalhes.gump:SetFontColor (frame1.tooltip.casts_label3, "white")

						player1_casts = amt_casts
					else
						local spellname = GetSpellInfo (spellid)
						local extra_search_found
						for casted_spellid, amount in _pairs (player1_misc.spell_cast or {}) do
							local casted_spellname = GetSpellInfo (casted_spellid)
							if (casted_spellname == spellname) then
								frame1.tooltip.casts_label3:SetText (amount)
								frame1.tooltip.casts_label2:SetText (COMPARE_FIRSTPLAYER_PERCENT)

								_detalhes.gump:SetFontColor (frame1.tooltip.casts_label3, "white")

								player1_casts = amount
								extra_search_found = true
								break
							end
						end

						if (not extra_search_found) then
							frame1.tooltip.casts_label3:SetText ("?")
							frame1.tooltip.casts_label2:SetText ("?")

							_detalhes.gump:SetFontColor (frame1.tooltip.casts_label3, "silver")
							_detalhes.gump:SetFontColor (frame1.tooltip.casts_label2, "silver")
						end
					end
				else
					frame1.tooltip.uptime_label3:SetText (COMPARE_UNKNOWNDATA)
					frame1.tooltip.uptime_label2:SetText (COMPARE_UNKNOWNDATA)
					_detalhes.gump:SetFontColor (frame1.tooltip.uptime_label2, "gray")
					_detalhes.gump:SetFontColor (frame1.tooltip.uptime_label3, "gray")

					frame1.tooltip.casts_label3:SetText ("?")
					frame1.tooltip.casts_label2:SetText ("?")
					_detalhes.gump:SetFontColor (frame1.tooltip.casts_label3, "gray")
					_detalhes.gump:SetFontColor (frame1.tooltip.casts_label2, "gray")
				end

				frame1.tooltip:Show()
			end

			if (bar2[2].righttext:GetText()) then
				fill_compare_tooltip (frame2, bar2, player2_misc, spellid, hits, average, critical, player1_uptime, player1_casts)
			end

			if (bar3[2].righttext:GetText()) then
				fill_compare_tooltip (frame3, bar3, player3_misc, spellid, hits, average, critical, player1_uptime, player1_casts)
			end
		end

		local on_leave = function (self)
			leave_compare_bars (self.index, DetailsPlayerComparisonBox1, DetailsPlayerComparisonBox2, DetailsPlayerComparisonBox3)
		end

		local compare_create = function (tab, frame)

			local create_bar_text = function (bar, point, x)
				local text = bar:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
				text:SetFont (SharedMedia:Fetch ("font", "Arial Narrow"), 11)
				text:SetPoint (point, bar, point, x, 0)
				text:SetJustifyH (point)
				text:SetTextColor (1, 1, 1, 1)
				return text
			end

			local create_bar = function (name, parent, index, main, is_target)
				local y = ((index-1) * -15) - 7

				local spellicon = parent:CreateTexture (nil, "overlay")
				spellicon:SetSize (14, 14)
				spellicon:SetPoint ("TOPLEFT", parent, "TOPLEFT", 4, y)
				spellicon:SetTexture ([[Interface\InventoryItems\WoWUnknownItem01]])

				local bar = CreateFrame ("StatusBar", name, parent)
				bar:EnableMouse(true)
				bar.index = index
				bar:SetPoint ("TOPLEFT", spellicon, "TOPRIGHT", 0, 0)
				bar:SetPoint ("TOPRIGHT", parent, "TOPRIGHT", -4, y)
				bar:SetStatusBarTexture ([[Interface\AddOns\Details\images\bar_serenity]])
				bar:SetStatusBarColor (.5, .5, .5, 1)
				bar:SetAlpha (ALPHA_BLEND_AMOUNT)

				bar:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
				bar:SetBackdropColor (1, 1, 1, 0.1)

				bar:SetMinMaxValues (0, 100)
				bar:SetValue (100)
				bar:SetHeight (14)
				bar.icon = spellicon
				bar.icon:SetTexCoord(0, 1, 0, 1)
				if (is_target) then
					bar:SetScript ("OnEnter", on_enter_target)
					bar:SetScript ("OnLeave", on_leave_target)
				else
					bar:SetScript ("OnEnter", on_enter)
					bar:SetScript ("OnLeave", on_leave)
				end

				bar.lefttext = create_bar_text (bar, "LEFT", 4)
				bar.lefttext:SetNonSpaceWrap (true)
				bar.lefttext:SetWordWrap (false)
				if (main) then
					bar.lefttext:SetWidth (180)
				else
					bar.lefttext:SetWidth (110)
				end

				bar.righttext = create_bar_text (bar, "RIGHT", -2)
				bar.righttext2 = create_bar_text (bar, "RIGHT", -42)

				parent.bars[#parent.bars+1] = {spellicon, bar, {0, 0, 0}}
			end

			local create_tooltip = function (name)
				local tooltip = CreateFrame ("Frame", name, UIParent)

				_detalhes.gump:CreateBorder (tooltip)

				tooltip:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]], tileSize = 64, tile = true})
				tooltip:SetBackdropColor (0, 0, 0, 1)
				tooltip:SetBackdropBorderColor (0, 0, 0, 1)
				tooltip:SetSize (275, 77)
				tooltip:SetFrameStrata ("tooltip")

				local y = -3
				local x_start = 2

				local background = tooltip:CreateTexture (nil, "border")
				background:SetTexture ([[Interface\SPELLBOOK\Spellbook-Page-1]])
				background:SetTexCoord (.6, 0.1, 0, 0.64453125)
				background:SetVertexColor (0, 0, 0, 0.2)
				background:SetPoint ("TOPLEFT", tooltip, "TOPLEFT", 0, 0)
				background:SetPoint ("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", 0, 0)

				local label_rows = {{"casts", "Применений:"}, {"hits", "Попаданий:"}, {"average", "Среднее:"}, {"crit", "Крит:"}, {"uptime", "Длительность:"}}
				for i, row in _ipairs (label_rows) do
					local key, ypos = row [1], -2 - ((i-1) * 12) + (y * (i-1))

					local label = tooltip:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
					label:SetPoint ("TOPLEFT", tooltip, "TOPLEFT", x_start, ypos)
					label:SetText (row [2])
					label:SetJustifyH ("LEFT")
					tooltip [key .. "_label"] = label

					local label2 = tooltip:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
					label2:SetPoint ("TOPRIGHT", tooltip, "TOPRIGHT", -x_start, ypos)
					label2:SetText ("0")
					label2:SetJustifyH ("RIGHT")
					tooltip [key .. "_label2"] = label2

					local label3 = tooltip:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
					label3:SetPoint ("TOPRIGHT", tooltip, "TOPRIGHT", -x_start - 46, ypos)
					label3:SetText ("0")
					label3:SetJustifyH ("RIGHT")
					tooltip [key .. "_label3"] = label3
				end

				local bg_texture = [[Interface\AddOns\Details\images\bar_background]]
				local bg_alpha = 1
				local bg_height = 12
				local colors = {{26/255, 26/255, 26/255}, {19/255, 19/255, 19/255}, {26/255, 26/255, 26/255}, {34/255, 39/255, 42/255}, {42/255, 51/255, 60/255}}

				for i = 1, 5 do
					local bg_line1 = tooltip:CreateTexture (nil, "artwork")
					bg_line1:SetTexture (bg_texture)
					bg_line1:SetPoint ("TOPLEFT", tooltip, "TOPLEFT", 0, -2 + (((i-1) * 12) * -1) + (y * (i-1)) + 2)
					bg_line1:SetPoint ("TOPRIGHT", tooltip, "TOPRIGHT", -0, -2 + (((i-1) * 12) * -1)  + (y * (i-1)) + 2)
					bg_line1:SetHeight (bg_height + 4)
					bg_line1:SetAlpha (bg_alpha)
					bg_line1:SetVertexColor (unpack (colors[i]))
				end

				return tooltip
			end

			local create_tooltip_target = function (name)
				local tooltip = CreateFrame ("Frame", name, UIParent)
				tooltip:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]], tileSize = 64, tile = true})
				tooltip:SetBackdropColor (0, 0, 0, 1)
				tooltip:SetBackdropBorderColor (0, 0, 0, 1)
				tooltip:SetSize (175, 67)
				tooltip:SetFrameStrata ("tooltip")
				tooltip.bars = {}

				_detalhes.gump:CreateBorder (tooltip)

				function tooltip:Reset()
					for index, bar in _ipairs (tooltip.bars) do
						bar [1]:SetTexture (nil)
						bar [2].lefttext:SetText ("")
						bar [2].righttext:SetText ("")
						bar [2].righttext2:SetText ("")
						bar [2]:SetValue (0)
						bar [2].bg:Hide()
					end
				end

				local bars_colors = {{19/255, 19/255, 19/255}, {26/255, 26/255, 26/255}}

				function tooltip:CreateBar (index)

					if (index) then
						if (index > #tooltip.bars+1) then
							for i = #tooltip.bars+1, index-1 do
								tooltip:CreateBar()
							end
						end
					end

					local index = #tooltip.bars + 1
					local y = ((index-1) * -15) - 2
					local parent = tooltip

					local spellicon = parent:CreateTexture (nil, "overlay")
					spellicon:SetSize (14, 14)
					spellicon:SetPoint ("TOPLEFT", parent, "TOPLEFT", 1, y)
					spellicon:SetTexture ([[Interface\InventoryItems\WoWUnknownItem01]])

					local bar = CreateFrame ("StatusBar", name .. "Bar" .. index, parent)
					bar.index = index
					bar:SetPoint ("TOPLEFT", spellicon, "TOPRIGHT", 0, 0)
					bar:SetPoint ("TOPRIGHT", parent, "TOPRIGHT", -1, y)
					bar:SetStatusBarTexture ([[Interface\AddOns\Details\images\bar_serenity]])
					bar:SetStatusBarColor (unpack (bar_color))
					bar:SetMinMaxValues (0, 100)
					bar:SetValue (0)
					bar:SetHeight (14)
					bar.icon = spellicon
					bar.icon:SetTexCoord(0, 1, 0, 1)

					bar.lefttext = create_bar_text (bar, "LEFT", 2)
					bar.lefttext:SetNonSpaceWrap (true)
					bar.lefttext:SetWordWrap (false)

					if (name:find ("1")) then
						bar.lefttext:SetWidth (110)
					else
						bar.lefttext:SetWidth (80)
					end

					bar.righttext = create_bar_text (bar, "RIGHT", -2)
					bar.righttext2 = create_bar_text (bar, "RIGHT", -46)

					local bg_line1 = bar:CreateTexture (nil, "artwork")
					bg_line1:SetTexture ([[Interface\AddOns\Details\images\bar_background]])
					bg_line1:SetAllPoints()
					bg_line1:SetAlpha (0.7)
					bg_line1:SetVertexColor (_unpack (bars_colors [2]))
					bar.bg = bg_line1

					local object = {spellicon, bar}
					tooltip.bars[#tooltip.bars+1] = object
					return object
				end

				local background = tooltip:CreateTexture (nil, "artwork")
				background:SetTexture ([[Interface\SPELLBOOK\Spellbook-Page-1]])
				background:SetTexCoord (.6, 0.1, 0, 0.64453125)
				background:SetVertexColor (0, 0, 0, 0.6)
				background:SetPoint ("TOPLEFT", tooltip, "TOPLEFT", 2, -4)
				background:SetPoint ("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -4, 2)

				return tooltip
			end

			local frame1 = CreateFrame ("scrollframe", "DetailsPlayerComparisonBox1", frame, "FauxScrollFrameTemplate")
			frame1:SetScript ("OnVerticalScroll", function (self, offset) FauxScrollFrame_OnVerticalScroll (self, offset, 14, refresh_comparison_box) end)
			frame1:SetSize (spell_compare_frame_width[1], spell_compare_frame_height)
			frame1:SetPoint ("TOPLEFT", frame, "TOPLEFT", xLocation, yLocation)
			_detalhes.gump:ReskinSlider (frame1)

			frame1:SetBackdrop (frame_backdrop)
			frame1:SetBackdropColor (unpack (frame_backdrop_color))
			frame1:SetBackdropBorderColor (unpack (frame_backdrop_border_color))

			--override backdrop settings and use the framework defaults
			Details.gump:ApplyStandardBackdrop (frame1)

			frame1.bars = {}
			frame1.tab = tab
			frame1.tooltip = create_tooltip ("DetailsPlayerComparisonBox1Tooltip")
			frame1.tooltip:SetWidth (spell_compare_frame_width[1])

			local playername1 = frame1:CreateFontString (nil, "overlay", "GameFontNormal")
			playername1:SetPoint ("BOTTOMLEFT", frame1, "TOPLEFT", 2, 0)
			playername1:SetText ("Player 1")
			frame1.name_label = playername1

			--criar as barras do frame1
			for i = 1, 12 do
				create_bar ("DetailsPlayerComparisonBox1Bar"..i, frame1, i, true)
			end

			--cria o box dos targets
			local target1 = CreateFrame ("scrollframe", "DetailsPlayerComparisonTarget1", frame, "FauxScrollFrameTemplate")
			target1:SetScript ("OnVerticalScroll", function (self, offset) FauxScrollFrame_OnVerticalScroll (self, offset, 14, refresh_target_box) end)
			target1:SetSize (spell_compare_frame_width[1], target_compare_frame_height)
			target1:SetPoint ("TOPLEFT", frame1, "BOTTOMLEFT", 0, -10)
			_detalhes.gump:ReskinSlider (target1)

			target1:SetBackdrop (frame_backdrop)
			target1:SetBackdropColor (unpack (frame_backdrop_color))
			target1:SetBackdropBorderColor (unpack (frame_backdrop_border_color))
			target1.bars = {}
			target1.tab = tab
			target1.tooltip = create_tooltip_target ("DetailsPlayerComparisonTarget1Tooltip")
			target1.tooltip:SetWidth (spell_compare_frame_width[1])

			--override backdrop settings and use the framework defaults
			Details.gump:ApplyStandardBackdrop (target1)

			--criar as barras do target1
			for i = 1, targetBars do
				create_bar ("DetailsPlayerComparisonTarget1Bar"..i, target1, i, true, true)
			end

--------------------------------------------

			local previous_box = frame1
			for n = 2, 3 do
				local box = CreateFrame ("Frame", "DetailsPlayerComparisonBox" .. n, frame)
				box:SetPoint ("TOPLEFT", previous_box, "TOPRIGHT", n == 2 and 27 or 5, 0)
				box:SetSize (spell_compare_frame_width[n], spell_compare_frame_height)
				box:SetBackdrop (frame_backdrop)
				box:SetBackdropColor (unpack (frame_backdrop_color))
				box:SetBackdropBorderColor (unpack (frame_backdrop_border_color))
				Details.gump:ApplyStandardBackdrop (box)

				box.bars = {}
				box.tooltip = create_tooltip ("DetailsPlayerComparisonBox" .. n .. "Tooltip")
				box.tooltip:SetWidth (spell_compare_frame_width[n])

				local playername = box:CreateFontString (nil, "overlay", "GameFontNormal")
				playername:SetPoint ("BOTTOMLEFT", box, "TOPLEFT", 2, 0)
				playername:SetText ("Player " .. n)
				box.name_label = playername

				local playername_percent = box:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
				playername_percent:SetPoint ("BOTTOMRIGHT", box, "TOPRIGHT", -2, 0)
				playername_percent:SetText ("Player 1 %")
				playername_percent:SetTextColor (.6, .6, .6)
				box.name_label_percent = playername_percent

				local noPLayersToShow = box:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
				noPLayersToShow:SetPoint ("CENTER")
				noPLayersToShow:SetText (Loc["There's no more players to compare (with the same class/spec)"])
				noPLayersToShow:SetSize (spell_compare_frame_width[2] - 10, spell_compare_frame_height)
				noPLayersToShow:SetJustifyH ("CENTER")
				noPLayersToShow:SetJustifyV ("CENTER")
				_detalhes.gump:SetFontSize (noPLayersToShow, 14)
				_detalhes.gump:SetFontColor (noPLayersToShow, "gray")
				box.NoPLayersToShow = noPLayersToShow

				for i = 1, 12 do
					create_bar ("DetailsPlayerComparisonBox" .. n .. "Bar" .. i, box, i)
				end

				local target = CreateFrame ("Frame", "DetailsPlayerComparisonTarget" .. n, frame)
				target:SetSize (spell_compare_frame_width[n], target_compare_frame_height)
				target:SetPoint ("TOPLEFT", box, "BOTTOMLEFT", 0, -10)
				target:SetBackdrop (frame_backdrop)
				target:SetBackdropColor (unpack (frame_backdrop_color))
				target:SetBackdropBorderColor (unpack (frame_backdrop_border_color))
				Details.gump:ApplyStandardBackdrop (target)
				target.bars = {}
				target.tooltip = create_tooltip_target ("DetailsPlayerComparisonTarget" .. n .. "Tooltip")
				target.tooltip:SetWidth (spell_compare_frame_width[n])

				for i = 1, targetBars do
					create_bar ("DetailsPlayerComparisonTarget" .. n .. "Bar" .. i, target, i, nil, true)
				end

				previous_box = box
			end
		end


		-- ~compare
		local iconTableCompare = {
			texture = [[Interface\AddOns\Details\images\icons]],
			--coords = {363/512, 381/512, 0/512, 17/512},
			coords = {383/512, 403/512, 0/512, 15/512},
			width = 16,
			height = 14,
		}

		_detalhes:CreatePlayerDetailsTab ("Compare", Loc ["STRING_INFO_TAB_COMPARISON"], --[1] tab name [2] localized name
			function (tabOBject, playerObject)  --[2] condition

				if (info.atributo > 2) then
					return false
				end

				local class = playerObject.classe
				local my_spells = {}
				local my_spells_total = 0
				--> build my spell list
				for spellid, _ in _pairs (playerObject.spells._ActorTable) do
					my_spells [spellid] = true
					my_spells_total = my_spells_total + 1
				end

				tabOBject.players = {}
				tabOBject.player = playerObject
				tabOBject.spells_amt = my_spells_total

				for index, actor in _ipairs (info.instancia.showing [info.atributo]._ActorTable) do
					if (actor.classe == class and actor ~= playerObject) then

						local same_spells = 0
						for spellid, _ in _pairs (actor.spells._ActorTable) do
							if (my_spells [spellid] or my_spells [faction_spells [spellid]]) then
								same_spells = same_spells + 1
							end
						end

						local match_percentage = same_spells / max (my_spells_total, 0.000001) * 100

						if (match_percentage > 30) then
							tabOBject.players[#tabOBject.players+1] = actor
						end
					end
				end

				if (#tabOBject.players > 0) then
					--tutorial flash
					local blink = _detalhes:GetTutorialCVar ("DETAILS_INFO_TUTORIAL2") or 0
					if (type (blink) == "number" and blink < 10) then

						if (not tabOBject.FlashAnimation) then
							local flashAnimation = tabOBject:CreateTexture (nil, "overlay")
							flashAnimation:SetPoint ("TOPLEFT", tabOBject.widget, "TOPLEFT", 1, -1)
							flashAnimation:SetPoint ("BOTTOMRIGHT", tabOBject.widget, "BOTTOMRIGHT", -1, 1)
							flashAnimation:SetTexture (1, 1, 1)

							local flashHub = DetailsFramework:CreateAnimationHub (flashAnimation, function() flashAnimation:Show() end, function() flashAnimation:Hide() end)
							DetailsFramework:CreateAnimation (flashHub, "alpha", 1, 1, 0, 0.3)
							DetailsFramework:CreateAnimation (flashHub, "alpha", 2, 1, 0.45, 0)
							flashHub:SetLooping ("REPEAT")

							tabOBject.FlashAnimation = flashHub
						end

						_detalhes:SetTutorialCVar ("DETAILS_INFO_TUTORIAL2", blink+1)

						tabOBject.FlashAnimation:Play()
					end

					return true
				end

				--return false
				return true --debug?
			end,

			compare_fill, --[3] fill function

			nil, --[4] onclick

			compare_create, --[5] oncreate
			iconTableCompare --icon table
		)

		-- ~compare ~newcompare
		-- ~compare





	-- ~tab ~tabs
		function este_gump:ShowTabs()
			local tabsShown = 0
			local secondRowIndex = 1
			local breakLine = 6 --th tab it'll start the second line

			for index = 1, #_detalhes.player_details_tabs do

				local tab = _detalhes.player_details_tabs [index]

				if (tab:condition (info.jogador, info.atributo, info.sub_atributo)) then
					tab:Show()
					tabsShown = tabsShown + 1

					tab:ClearAllPoints()

					--get the button width
					local buttonTemplate = gump:GetTemplate ("button", "DETAILS_TAB_BUTTON_TEMPLATE")
					local buttonWidth = buttonTemplate.width + 1

					tab:SetSize (buttonTemplate.width, buttonTemplate.height)
					if (tabsShown >= breakLine) then --next row of icons
						tab:SetPoint ("BOTTOMRIGHT", info, "TOPRIGHT",  -514 + (buttonWidth * (secondRowIndex)), -50)
						secondRowIndex = secondRowIndex + 1
					else
						tab:SetPoint ("BOTTOMRIGHT", info, "TOPRIGHT", -514 + (buttonWidth * tabsShown), -72)
					end

					tab:SetAlpha (0.8)
				else
					tab.frame:Hide()
					tab:Hide()
				end
			end

			if (tabsShown < 2) then
				_detalhes.player_details_tabs[1]:SetPoint ("BOTTOMLEFT", info.container_barras, "TOPLEFT",  490 - (94 * (1-0)), 1)
			end

			--selected by default
			_detalhes.player_details_tabs[1]:Click()
		end

		este_gump:SetScript ("OnHide", function (self)
			_detalhes:FechaJanelaInfo()
			for _, tab in _ipairs (_detalhes.player_details_tabs) do
				tab:Hide()
				tab.frame:Hide()
			end
		end)

	este_gump.tipo = 1 --> tipo da janela // 1 = janela normal

	return este_gump

end

info.selectedTab = "Summary"

_detalhes.player_details_tabs = {}

function _detalhes:CreatePlayerDetailsTab (tabname, localized_name, condition, fillfunction, onclick, oncreate, iconSettings)
	if (not tabname) then
		tabname = "unnamed"
	end

	--create a button for the tab
	local newTabButton = gump:CreateButton (info, onclick, 20, 20)
	newTabButton:SetTemplate ("DETAILS_TAB_BUTTON_TEMPLATE")
	if (tabname == "Summary") then
		newTabButton:SetTemplate ("DETAILS_TAB_BUTTONSELECTED_TEMPLATE")
	end
	newTabButton:SetText (localized_name)
	newTabButton:SetFrameStrata ("HIGH")
	newTabButton:SetFrameLevel (info:GetFrameLevel()+1)
	newTabButton:Hide()

	newTabButton.condition = condition
	newTabButton.tabname = tabname
	newTabButton.localized_name = localized_name
	newTabButton.onclick = onclick
	newTabButton.fillfunction = fillfunction
	newTabButton.last_actor = {}

	newTabButton.frame = CreateFrame ("Frame", "DetailsPDWTabFrame" .. tabname, UIParent)
	newTabButton.frame:SetParent (info)
	newTabButton.frame:SetFrameStrata ("HIGH")
	newTabButton.frame:SetFrameLevel (info:GetFrameLevel()+5)
	newTabButton.frame:EnableMouse (true)

	if (iconSettings) then
		local texture = iconSettings.texture
		local coords = iconSettings.coords
		local width = iconSettings.width
		local height = iconSettings.height

		local overlay, textdistance, leftpadding, textheight, short_method --nil

		newTabButton:SetIcon (texture, width, height, "overlay", coords, overlay, textdistance, leftpadding, textheight, short_method)
		if (iconSettings.desaturated) then
			newTabButton.icon:SetDesaturated (true)
		end
	end

	if (newTabButton.fillfunction) then
		newTabButton.frame:SetScript ("OnShow", function()
			if (newTabButton.last_actor == info.jogador) then
				return
			end
			newTabButton.last_actor = info.jogador
			newTabButton:fillfunction (info.jogador, info.instancia.showing)
		end)
	end

	if (oncreate) then
		oncreate (newTabButton, newTabButton.frame)
	end

	newTabButton.frame:SetBackdrop({
		edgeFile = [[Interface\Buttons\WHITE8X8]],
		edgeSize = 1,
		bgFile = [[Interface\AddOns\Details\images\background]],
		tileSize = 64,
		tile = true,
		insets = {left = 0, right = 0, top = 0, bottom = 0}}
	)

	newTabButton.frame:SetBackdropColor (0, 0, 0, 0.3)
	newTabButton.frame:SetBackdropBorderColor (.3, .3, .3, 0)

	newTabButton.frame:SetPoint ("TOPLEFT", info.container_barras, "TOPLEFT", 0, 2)
	newTabButton.frame:SetPoint ("BOTTOMRIGHT", info, "BOTTOMRIGHT", -3, 3)
	newTabButton.frame:SetSize (569, 274)

	newTabButton.frame:Hide()

	_detalhes.player_details_tabs [#_detalhes.player_details_tabs+1] = newTabButton

	if (not onclick) then
		--> hide all tabs
		newTabButton.OnShowFunc = function (self)
			self = self.MyObject or self

			for _, tab in _ipairs (_detalhes.player_details_tabs) do
				tab.frame:Hide()
				tab:SetTemplate ("DETAILS_TAB_BUTTON_TEMPLATE")
			end

			self:SetTemplate ("DETAILS_TAB_BUTTONSELECTED_TEMPLATE")
			self.frame:Show()
			info.selectedTab = self.tabname
		end

		newTabButton:SetScript ("OnClick", newTabButton.OnShowFunc)
	else
		--> custom
		newTabButton.OnShowFunc = function (self)
			self = self.MyObject or self

			for _, tab in _ipairs (_detalhes.player_details_tabs) do
				tab.frame:Hide()
				tab:SetTemplate ("DETAILS_TAB_BUTTON_TEMPLATE")
			end

			self:SetTemplate ("DETAILS_TAB_BUTTONSELECTED_TEMPLATE")

			info.selectedTab = self.tabname

			--run onclick func
			local result, errorText = pcall (self.onclick)
			if (not result) then
				print (errorText)
			end
		end

		newTabButton:SetScript ("OnClick", newTabButton.OnShowFunc)
	end

	newTabButton:SetScript ("PostClick", function (self)
		CurrentTab = self.tabname or self.MyObject.tabname

		if (CurrentTab ~= "Summary") then
			for _, widget in _ipairs (SummaryWidgets) do
				widget:Hide()
			end
		else
			for _, widget in _ipairs (SummaryWidgets) do
				widget:Show()
			end
		end
	end)
	return newTabButton, newTabButton.frame

end

local box_report_line = function (caixa, isFirst)
	local linha = ""
	local nome2 = caixa.nome2:GetText()
	if (nome2 and nome2 ~= "") then
		if (isFirst) then
			linha = linha..nome2.." / "
		else
			linha = linha..caixa.nome:GetText().." "..nome2.." / "
		end
	end
	local dano = caixa.dano:GetText()
	if (dano and dano ~= "") then
		linha = linha..dano.." / "
	end
	local media = caixa.dano_media:GetText()
	if (media and media ~= "") then
		linha = linha..media.." / "
	end
	local dano_dps = caixa.dano_dps:GetText()
	if (dano_dps and dano_dps ~= "") then
		linha = linha..dano_dps.." / "
	end
	local dano_porcento = caixa.dano_porcento:GetText()
	if (dano_porcento and dano_porcento ~= "") then
		linha = linha..dano_porcento.." "
	end
	return linha
end

function _detalhes.janela_info:monta_relatorio (botao)

	local atributo = info.atributo
	local sub_atributo = info.sub_atributo
	local player = info.jogador
	local instancia = info.instancia

	local amt = _detalhes.report_lines

	if (not player) then
		_detalhes:Msg ("Player not found.")
		return
	end

	local report_lines

	if (botao == 1) then --> bot�o da esquerda


		if (atributo == 1 and sub_atributo == 4) then --> friendly fire
			report_lines = {"Details!: " .. player.nome .. " " .. Loc ["STRING_ATTRIBUTE_DAMAGE_FRIENDLYFIRE"] .. ":"}

		elseif (atributo == 1 and sub_atributo == 3) then --> damage taken
			report_lines = {"Details!: " .. player.nome .. " " .. Loc ["STRING_ATTRIBUTE_DAMAGE_TAKEN"] .. ":"}

		else
		--	report_lines = {"Details! " .. Loc ["STRING_ACTORFRAME_SPELLSOF"] .. " " .. player.nome .. " (" .. _detalhes.sub_atributos [atributo].lista [sub_atributo] .. ")"}
			report_lines = {"Details!: " .. player.nome .. " - " .. _detalhes.sub_atributos [atributo].lista [sub_atributo] .. ""}

		end

		for index, barra in _ipairs (info.barras1) do
			if (barra:IsShown()) then
				local spellid = barra.show
				if (atributo == 1 and sub_atributo == 4) then --> friendly fire
					report_lines [#report_lines+1] = barra.texto_esquerdo:GetText() .. ": " .. barra.texto_direita:GetText()

				elseif (type (spellid) == "number" and spellid > 10) then
					local link = GetSpellLink (spellid)
					report_lines [#report_lines+1] = index .. ". " .. link .. ": " .. barra.texto_direita:GetText()
				else
					local spellname = barra.texto_esquerdo:GetText():gsub ((".*%."), "")
					spellname = spellname:gsub ("|c%x%x%x%x%x%x%x%x", "")
					spellname = spellname:gsub ("|r", "")
					report_lines [#report_lines+1] = index .. ". " .. spellname .. ": " .. barra.texto_direita:GetText()
				end
			end
			if (index == amt) then
				break
			end
		end

	elseif (botao == 3) then --> bot�o dos alvos

		if (atributo == 1 and sub_atributo == 3) then
			print (Loc ["STRING_ACTORFRAME_NOTHING"])
			return
		end

		report_lines = {"Details! " .. Loc ["STRING_ACTORFRAME_REPORTTARGETS"] .. " " .. _detalhes.sub_atributos [1].lista [1] .. " " .. Loc ["STRING_ACTORFRAME_REPORTOF"] .. " " .. player.nome}

		for index, barra in _ipairs (info.barras2) do
			if (barra:IsShown()) then
				report_lines [#report_lines+1] = barra.texto_esquerdo:GetText().." -> ".. barra.texto_direita:GetText()
			end
			if (index == amt) then
				break
			end
		end

	elseif (botao == 2) then --> bot�o da direita

			--> diferentes tipos de amostragem na caixa da direita
		     --dano                       --damage done                 --dps                                 --heal
		if ((atributo == 1 and (sub_atributo == 1 or sub_atributo == 2)) or (atributo == 2 and sub_atributo ~= 4)) then
			if (not player.detalhes) then
				print (Loc ["STRING_ACTORFRAME_NOTHING"])
				return
			end
			local nome = _GetSpellInfo (player.detalhes)
			report_lines = {"Details! " .. Loc ["STRING_ACTORFRAME_REPORTTO"] .. " " .. _detalhes.sub_atributos [atributo].lista [sub_atributo] .. " " .. Loc ["STRING_ACTORFRAME_REPORTOF"] .. " " .. player.nome,
			Loc ["STRING_ACTORFRAME_SPELLDETAILS"] .. ": " .. nome}

			for i = 1, 5 do

				--> pega os dados dos quadrados --> Aqui mostra o resumo de todos os quadrados...
				local caixa = info.grupos_detalhes [i]
				if (caixa.bg:IsShown()) then

					report_lines [#report_lines+1] = box_report_line (caixa, i == 1)

				end

				if (i == amt) then
					break
				end

			end

			--dano                       --damage tanken (mostra as magias que o alvo usou)
		elseif ( (atributo == 1 and (sub_atributo == 3 or sub_atributo == 4)) or atributo == 3 or atributo == 2) then
			if (player.detalhes) then
				report_lines = {"Details! " .. Loc ["STRING_ACTORFRAME_REPORTTO"] .. " " .. _detalhes.sub_atributos [atributo].lista [1] .. " " .. Loc ["STRING_ACTORFRAME_REPORTOF"] .. " " .. player.detalhes.. " " .. Loc ["STRING_ACTORFRAME_REPORTAT"] .. " " .. player.nome}
				for index, barra in _ipairs (info.barras3) do
					if (barra:IsShown()) then
						report_lines [#report_lines+1] = barra.texto_esquerdo:GetText().." ....... ".. barra.texto_direita:GetText()
					end
					if (index == amt) then
						break
					end
				end
			else
				report_lines = {}
			end
		end

	elseif (botao >= 11) then --> primeira caixa dos detalhes

		botao =  botao - 10

		local nome = _GetSpellInfo (player.detalhes)
		local spelllink = GetSpellLink (player.detalhes)
		if (spelllink) then
			nome = spelllink
		end

		if (not nome) then
			nome = ""
		end
		report_lines = {"Details! " .. Loc ["STRING_ACTORFRAME_REPORTTO"] .. " " .. _detalhes.sub_atributos [atributo].lista [sub_atributo].. " " .. Loc ["STRING_ACTORFRAME_REPORTOF"] .. " " .. player.nome,
		Loc ["STRING_ACTORFRAME_SPELLDETAILS"] .. ": " .. nome}

		local caixa = info.grupos_detalhes [botao]

		local linha = box_report_line (caixa, botao == 1)

		--> remove a cor da school
		linha = linha:gsub ("|c%x?%x?%x?%x?%x?%x?%x?%x?", "")
		linha = linha:gsub ("|r", "")

		report_lines [#report_lines+1] = linha

	end

	--local report_lines = {"Details! Relatorio para ".._detalhes.sub_atributos [self.atributo].lista [self.sub_atributo]}


	--> pega o conte�do da janela da direita

	return instancia:envia_relatorio (report_lines)
end

local row_backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		insets = {left = 0, right = 0, top = 0, bottom = 0}}
local row_backdrop_onleave = {bgFile = "", edgeFile = "", tile = true, tileSize = 16, edgeSize = 32,
		insets = {left = 1, right = 1, top = 0, bottom = 1}}

local row_on_enter = function (self)
	if (info.fading_in or info.faded) then
		return
	end

	self.mouse_over = true

	for index, block in _pairs (_detalhes.janela_info.grupos_detalhes) do
		detalhe_infobg_onleave (block.bg)
	end

	--> aumenta o tamanho da barra
	self:SetHeight (CONST_BAR_HEIGHT + 1)
	--> poe a barra com alfa 1 ao inv�s de 0.9
	self:SetAlpha(1)

	--> troca a cor da barra enquanto o mouse estiver em cima dela
	self:SetBackdrop (row_backdrop)
	self:SetBackdropColor (0.8, 0.8, 0.8, 0.3)

	if (self.isAlvo) then --> monta o tooltip do alvo
		--> talvez devesse escurecer a janela no fundo... pois o tooltip � transparente e pode confundir
		GameTooltip:SetOwner (self, "ANCHOR_TOPRIGHT")
		
		if (self.spellid == "enemies") then --> damage taken enemies
			if (not self.minha_tabela or not self.minha_tabela:MontaTooltipDamageTaken (self, self._index, info.instancia)) then  -- > poderia ser aprimerado para uma tailcall
				return
			end
			GameTooltip:Show()
			self:SetHeight (CONST_TARGET_HEIGHT + 1)
			return
		end

		if (not self.minha_tabela or not self.minha_tabela:MontaTooltipAlvos (self, self._index, info.instancia)) then  -- > poderia ser aprimerado para uma tailcall
			return
		end

	elseif (self.isMain) then

		if (IsShiftKeyDown()) then
			if (type (self.show) == "number") then
				GameTooltip:SetOwner (self, "ANCHOR_TOPRIGHT")
				GameTooltip:AddLine (Loc ["ABILITY_ID"] .. ": " .. self.show)
				GameTooltip:Show()
			end
		end

		if (self.show == 98021) then
			GameTooltip:SetOwner (self, "ANCHOR_TOPLEFT")
			GameTooltip:AddLine (Loc ["STRING_SPIRIT_LINK_TOTEM_DESC"])
			GameTooltip:Show()
		end

		--> da zoom no icone
		self.icone:SetWidth (CONST_BAR_HEIGHT + 2)
		self.icone:SetHeight (CONST_BAR_HEIGHT + 2)
		--> poe a alfa do icone em 1.0
		self.icone:SetAlpha (1)

		--> mostrar temporariamente o conteudo da barra nas caixas de detalhes
		if (not info.mostrando) then --> n�o esta mostrando nada na direita
			info.mostrando = self --> agora o mostrando � igual a esta barra
			info.mostrando_mouse_over = true --> o conteudo da direta esta sendo mostrado pq o mouse esta passando por cima do bagulho e n�o pq foi clicado
			info.showing = self._index --> diz  o index da barra que esta sendo mostrado na direita

			info.jogador.detalhes = self.show --> minha tabela = jogador = jogador.detales = spellid ou nome que esta sendo mostrado na direita
			info.jogador:MontaDetalhes (self.show, self, info.instancia) --> passa a spellid ou nome e a barra
		end
	end
end

local row_on_leave = function (self)
	if (self.fading_in or self.faded or not self:IsShown() or self.hidden) then
		return
	end

	self.mouse_over = false

	--> diminui o tamanho da barra
	self:SetHeight (CONST_BAR_HEIGHT)
	--> volta com o alfa antigo da barra que era de 0.9
	self:SetAlpha(0.9)

	--> volto o background ao normal
	self:SetBackdrop (row_backdrop_onleave)
	self:SetBackdropBorderColor (0, 0, 0, 0)
	self:SetBackdropColor (0, 0, 0, 0)

	GameTooltip:Hide()

	GameCooltip:Hide()

	if (self.isMain) then
		--> retira o zoom no icone
		self.icone:SetWidth (CONST_BAR_HEIGHT)
		self.icone:SetHeight (CONST_BAR_HEIGHT)
		--> volta com a alfa antiga da barra
		self.icone:SetAlpha (1)

		--> remover o conte�do que estava sendo mostrado na direita
		if (info.mostrando_mouse_over) then
			info.mostrando = nil
			info.mostrando_mouse_over = false
			info.showing = nil

			info.jogador.detalhes = nil
			gump:HidaAllDetalheInfo()
		end

	elseif (self.isAlvo) then
		self:SetHeight (CONST_TARGET_HEIGHT)
	end
end

local row_on_mousedown = function (self, button)
	if (self.fading_in) then
		return
	end

	self.mouse_down = _GetTime()
	local x, y = _GetCursorPosition()
	self.x = _math_floor (x)
	self.y = _math_floor (y)

	if (button == "RightButton" and not info.isMoving) then
		_detalhes:FechaJanelaInfo()

	elseif (not info.isMoving and button == "LeftButton" and not self.isDetalhe) then
		info:StartMoving()
		info.isMoving = true
	end
end

local row_on_mouseup = function (self, button)
	if (self.fading_in) then
		return
	end

	if (info.isMoving and button == "LeftButton" and not self.isDetalhe) then
		info:StopMovingOrSizing()
		info.isMoving = false
	end

	local x, y = _GetCursorPosition()
	x = _math_floor (x)
	y = _math_floor (y)
	if ((self.mouse_down+0.4 > _GetTime() and (x == self.x and y == self.y)) or (x == self.x and y == self.y)) then
		--> setar os textos

		if (self.isMain) then --> se n�o for uma barra de alvo

			local barra_antiga = info.mostrando
			if (barra_antiga and not info.mostrando_mouse_over) then

				barra_antiga.textura:SetStatusBarColor (1, 1, 1, 1) --> volta a textura normal
				barra_antiga.on_focus = false --> n�o esta mais no foco

				--> clicou na mesma barra
				if (barra_antiga == self) then -->
					info.mostrando_mouse_over = true
					return

				--> clicou em outra barra
				else --> clicou em outra barra e trocou o foco
					barra_antiga:SetAlpha (.9) --> volta a alfa antiga

					info.mostrando = self
					info.showing = self._index

					info.jogador.detalhes = self.show
					info.jogador:MontaDetalhes (self.show, self)

					self:SetAlpha (1)
					self.textura:SetStatusBarColor (129/255, 125/255, 69/255, 1)
					self.on_focus = true
					return
				end
			end

			--> nao tinha barras pressionadas
			info.mostrando_mouse_over = false
			self:SetAlpha (1)
			self.textura:SetStatusBarColor (129/255, 125/255, 69/255, 1)
			self.on_focus = true
		end

	end
end

local function SetBarraScripts (esta_barra, instancia, i)

	esta_barra._index = i

	esta_barra:SetScript ("OnEnter", row_on_enter)
	esta_barra:SetScript ("OnLeave", row_on_leave)

	esta_barra:SetScript ("OnMouseDown", row_on_mousedown)
	esta_barra:SetScript ("OnMouseUp", row_on_mouseup)

end

local function CriaTexturaBarra (instancia, barra)

	barra.textura = _CreateFrame ("StatusBar", nil, barra)

	-- barra.textura:SetFrameLevel (barra:GetFrameLevel()+1)

	barra.textura:SetAllPoints (barra)
	-- barra.textura:SetAlpha (0.5)

	local texture = SharedMedia:Fetch ("statusbar", _detalhes.player_details_window.bar_texture)
	barra.textura:SetStatusBarTexture (texture)

	barra.textura:GetStatusBarTexture():SetAlpha(0.5)

	barra.textura:SetStatusBarColor (.5, .5, .5, 0)
	barra.textura:SetMinMaxValues (0,100)

	barra.textura.bg = barra.textura:CreateTexture (nil, "BACKGROUND")
	barra.textura.bg:SetAllPoints()
	barra.textura.bg:SetTexture (1, 1, 1, 0.08)

	if (barra.targets) then
		barra.targets:SetParent (barra.textura)
		barra.targets:SetFrameLevel (barra.textura:GetFrameLevel()+2)
	end

	barra.texto_esquerdo = barra.textura:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
	barra.texto_esquerdo:SetPoint ("LEFT", barra.textura, "LEFT", CONST_BAR_HEIGHT + 6, 0)
	barra.texto_esquerdo:SetJustifyH ("LEFT")
	barra.texto_esquerdo:SetTextColor (1,1,1,1)

	barra.texto_esquerdo:SetNonSpaceWrap (true)
	barra.texto_esquerdo:SetWordWrap (false)

	barra.texto_direita = barra.textura:CreateFontString (nil, "OVERLAY", "GameFontHighlightSmall")
	if (barra.targets) then
		barra.texto_direita:SetPoint ("RIGHT", barra.targets, "LEFT", -2, 0)
	else
		barra.texto_direita:SetPoint ("RIGHT", barra, "RIGHT", -2, 0)
	end
	barra.texto_direita:SetJustifyH ("RIGHT")
	barra.texto_direita:SetTextColor (1,1,1,1)

	barra.textura:Show()
end

local miniframe_func_on_enter = function (self)
	local barra = self:GetParent()
	if (barra.show and type (barra.show) == "number") then
		local spellname = _GetSpellInfo (barra.show)
		if (spellname) then
			GameTooltip:SetOwner (self, "ANCHOR_TOPLEFT")
			_detalhes:GameTooltipSetSpellByID (barra.show)
			GameTooltip:Show()
		end
	end
	-- print("DASD")
	barra:GetScript("OnEnter")(barra)
end

local miniframe_func_on_leave = function (self)
	GameTooltip:Hide()
	self:GetParent():GetScript("OnLeave")(self:GetParent())
end

local target_on_enter = function (self)

	local barra = self:GetParent():GetParent()
	
	if (barra.show and type (barra.show) == "number") then
		local actor = barra.other_actor or info.jogador
		local spell = actor.spells and actor.spells:PegaHabilidade (barra.show)
		if (spell) then
		
			local ActorTargetsSortTable = {}
			local ActorTargetsContainer
			local total = 0
			
			local attribute, sub_attribute = info.instancia:GetDisplay()
			if (attribute == 1 or attribute == 3) then
				ActorTargetsContainer = spell.targets
			else
				if (sub_attribute == 3) then --overheal
					ActorTargetsContainer = spell.targets_overheal
				elseif (sub_attribute == 6) then --absorbs
					ActorTargetsContainer = spell.targets_absorbs
				else
					ActorTargetsContainer = spell.targets
				end
			end
			
			--add and sort
			for target_name, amount in _pairs (ActorTargetsContainer) do
				--print (target_name, amount)
				ActorTargetsSortTable [#ActorTargetsSortTable+1] = {target_name, amount or 0}
				total = total + (amount or 0)
			end
			_table_sort (ActorTargetsSortTable, _detalhes.Sort2)
			
			local spellname = _GetSpellInfo (barra.show)
			
			GameTooltip:SetOwner (self, "ANCHOR_TOPRIGHT")
			GameTooltip:AddLine (barra.index .. ". " .. spellname)
			GameTooltip:AddLine (info.target_text)
			GameTooltip:AddLine (" ")
			
			--get time type
			local meu_tempo
			if (_detalhes.time_type == 1 or not actor.grupo) then
				meu_tempo = actor:Tempo()
			elseif (_detalhes.time_type == 2) then
				meu_tempo = info.instancia.showing:GetCombatTime()
			end
			
			local SelectedToKFunction = _detalhes.ToKFunctions [_detalhes.ps_abbreviation]
			
			for index, target in _ipairs (ActorTargetsSortTable) do 
				if (target [2] > 0) then
					local class = _detalhes:GetClass (target [1])
					if (class and _detalhes.class_coords [class]) then
						local cords = _detalhes.class_coords [class]
						if (info.target_persecond) then
							GameTooltip:AddDoubleLine (index .. ". |TInterface\\AddOns\\Details\\images\\classes_small_alpha:14:14:0:0:128:128:"..cords[1]*128 ..":"..cords[2]*128 ..":"..cords[3]*128 ..":"..cords[4]*128 .."|t " .. target [1], _detalhes:comma_value ( _math_floor (target [2] / meu_tempo) ), 1, 1, 1, 1, 1, 1)
						else
							GameTooltip:AddDoubleLine (index .. ". |TInterface\\AddOns\\Details\\images\\classes_small_alpha:14:14:0:0:128:128:"..cords[1]*128 ..":"..cords[2]*128 ..":"..cords[3]*128 ..":"..cords[4]*128 .."|t " .. target [1], SelectedToKFunction (_, target [2]), 1, 1, 1, 1, 1, 1)
						end
					else
						if (info.target_persecond) then
							GameTooltip:AddDoubleLine (index .. ". " .. target [1], _detalhes:comma_value ( _math_floor (target [2] / meu_tempo)), 1, 1, 1, 1, 1, 1)
						else
							GameTooltip:AddDoubleLine (index .. ". " .. target [1], SelectedToKFunction (_, target [2]), 1, 1, 1, 1, 1, 1)
						end
					end
				end
			end
			
			GameTooltip:Show()
		else
			GameTooltip:SetOwner (self, "ANCHOR_TOPRIGHT")
			GameTooltip:AddLine (barra.index .. ". " .. barra.show)
			GameTooltip:AddLine (info.target_text)
			GameTooltip:AddLine (Loc ["STRING_NO_TARGET"], 1, 1, 1)
			GameTooltip:AddLine (Loc ["STRING_MORE_INFO"], 1, 1, 1)
			GameTooltip:Show()
		end
	else
		GameTooltip:SetOwner (self, "ANCHOR_TOPRIGHT")
		GameTooltip:AddLine (barra.index .. ". " .. barra.show)
		GameTooltip:AddLine (info.target_text)
		GameTooltip:AddLine (Loc ["STRING_NO_TARGET"], 1, 1, 1)
		GameTooltip:AddLine (Loc ["STRING_MORE_INFO"], 1, 1, 1)
		GameTooltip:Show()
	end
	
	self.texture:SetAlpha (1)
	self:SetAlpha (1)
	barra:GetScript("OnEnter")(barra)
end

local target_on_leave = function (self)
	GameTooltip:Hide()
	GameCooltip:Hide()
	self:GetParent():GetParent():GetScript("OnLeave")(self:GetParent():GetParent())
	self.texture:SetAlpha (.7)
	self:SetAlpha (.7)
end



function gump:CriaNovaBarraInfo1 (instancia, index)

	if (_detalhes.janela_info.barras1 [index]) then
		print ("erro a barra "..index.." ja existe na janela de detalhes...")
		return
	end

	local janela = info.container_barras.gump

	local esta_barra = _CreateFrame ("Button", "Details_infobox1_bar_"..index, info.container_barras.gump)
	esta_barra:SetHeight (CONST_BAR_HEIGHT)
	esta_barra.index = index

	local y = (index-1) * (CONST_BAR_HEIGHT + 1)
	y = y*-1 --> baixo

	esta_barra:SetPoint ("LEFT", janela, "LEFT", CONST_BAR_HEIGHT, 0)
	esta_barra:SetPoint ("RIGHT", janela, "RIGHT")
	esta_barra:SetPoint ("TOP", janela, "TOP", 0, y)
	esta_barra:SetFrameLevel (janela:GetFrameLevel() + 1)

	esta_barra:EnableMouse (true)
	esta_barra:RegisterForClicks ("LeftButtonDown","RightButtonUp")

	esta_barra.targets = CreateFrame ("Button", "Details_infobox1_bar_"..index.."Targets", esta_barra)
	esta_barra.targets:SetPoint ("RIGHT", esta_barra, "RIGHT")
	esta_barra.targets:SetSize (CONST_BAR_HEIGHT-1, CONST_BAR_HEIGHT-1)
	esta_barra.targets.texture = esta_barra.targets:CreateTexture (nil, overlay)
	esta_barra.targets.texture:SetTexture ([[Interface\AddOns\Details\textures\Minimap\Tracking\Target]])
	esta_barra.targets.texture:SetAllPoints()
	esta_barra.targets.texture:SetDesaturated (true)
	esta_barra.targets:SetAlpha (.7)
	esta_barra.targets.texture:SetAlpha (.7)
	esta_barra.targets:SetScript ("OnEnter", target_on_enter)
	esta_barra.targets:SetScript ("OnLeave", target_on_leave)

	CriaTexturaBarra (instancia, esta_barra)

	--> icone
	esta_barra.miniframe = CreateFrame ("Button", nil, esta_barra)
	esta_barra.miniframe:SetSize (CONST_BAR_HEIGHT-2, CONST_BAR_HEIGHT-2)
	esta_barra.miniframe:SetPoint ("RIGHT", esta_barra.textura, "LEFT", CONST_BAR_HEIGHT + 2, 0)

	esta_barra.miniframe:SetScript ("OnEnter", miniframe_func_on_enter)
	esta_barra.miniframe:SetScript ("OnLeave", miniframe_func_on_leave)

	esta_barra.icone = esta_barra.textura:CreateTexture (nil, "OVERLAY")
	esta_barra.icone:SetWidth (CONST_BAR_HEIGHT)
	esta_barra.icone:SetHeight (CONST_BAR_HEIGHT)
	esta_barra.icone:SetPoint ("RIGHT", esta_barra.textura, "LEFT", CONST_BAR_HEIGHT + 2, 0)

	esta_barra:SetAlpha(0.9)
	esta_barra.icone:SetAlpha (1)

	esta_barra.isMain = true

	SetBarraScripts (esta_barra, instancia, index)

	info.barras1 [index] = esta_barra --> barra adicionada

	esta_barra.textura:SetStatusBarColor (1, 1, 1, 1) --> isso aqui � a parte da sele��o e descele��o
	esta_barra.on_focus = false --> isso aqui � a parte da sele��o e descele��o

	return esta_barra
end

function gump:CriaNovaBarraInfo2 (instancia, index)

	if (_detalhes.janela_info.barras2 [index]) then
		print ("erro a barra "..index.." ja existe na janela de detalhes...")
		return
	end

	local janela = info.container_alvos.gump

	local esta_barra = _CreateFrame ("Button", "Details_infobox2_bar_"..index, info.container_alvos.gump)
	esta_barra:SetHeight (CONST_TARGET_HEIGHT)

	local y = (index-1) * (CONST_TARGET_HEIGHT + 1)
	y = y*-1 --> baixo

	esta_barra:SetPoint ("LEFT", janela, "LEFT")
	esta_barra:SetPoint ("RIGHT", janela, "RIGHT")
	esta_barra:SetPoint ("TOP", janela, "TOP", 0, y)
	esta_barra:SetFrameLevel (janela:GetFrameLevel() + 1)

	esta_barra:EnableMouse (true)
	esta_barra:RegisterForClicks ("LeftButtonDown","RightButtonUp")

	CriaTexturaBarra (instancia, esta_barra)

	--> icone
	esta_barra.icone = esta_barra.textura:CreateTexture (nil, "OVERLAY")
	esta_barra.icone:SetWidth (CONST_TARGET_HEIGHT)
	esta_barra.icone:SetHeight (CONST_TARGET_HEIGHT)
	esta_barra.icone:SetPoint ("RIGHT", esta_barra.textura, "LEFT", CONST_TARGET_HEIGHT + 2, 0)

	esta_barra:SetAlpha (ALPHA_BLEND_AMOUNT)
	esta_barra.icone:SetAlpha (1)

	esta_barra.isAlvo = true

	SetBarraScripts (esta_barra, instancia, index)

	info.barras2 [index] = esta_barra --> barra adicionada

	return esta_barra
end


function gump:CriaNovaBarraInfo3 (instancia, index)

	if (_detalhes.janela_info.barras3 [index]) then
		print ("erro a barra "..index.." ja existe na janela de detalhes...")
		return
	end

	local janela = info.container_detalhes

	local esta_barra = CreateFrame ("Button", "Details_infobox3_bar_"..index, janela)
	esta_barra:SetHeight (16)

	local y = (index-1) * 17
	y = y*-1

	container3_bars_pointFunc (esta_barra, index)

	esta_barra:EnableMouse (true)

	CriaTexturaBarra (instancia, esta_barra)

	--> icone
	esta_barra.icone = esta_barra.textura:CreateTexture (nil, "OVERLAY")
	esta_barra.icone:SetWidth (14)
	esta_barra.icone:SetHeight (14)
	esta_barra.icone:SetPoint ("RIGHT", esta_barra.textura, "LEFT", 18, 0)

	esta_barra:SetAlpha (0.9)
	esta_barra.icone:SetAlpha (1)

	esta_barra.isDetalhe = true

	SetBarraScripts (esta_barra, instancia, index)

	info.barras3 [index] = esta_barra --> barra adicionada

	return esta_barra
end
