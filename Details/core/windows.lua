
	local _detalhes =	_G._detalhes
	local Loc =			LibStub ("AceLocale-3.0"):GetLocale ( "Details" )

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> local pointers

	local _math_floor = math.floor --lua local
	local _type = type --lua local
	local _math_abs = math.abs --lua local
	local _math_min = math.min
	local _math_max = math.max
	local _ipairs = ipairs --lua local
	local _pairs = pairs --lua local

local _string_format = string.format
local _table_sort = table.sort
local _utf8len = string.utf8len
local _utf8sub = string.utf8sub

	local _UIParent = UIParent --wow api local

	local gump = _detalhes.gump --details local
	local _

	local reskin_code_editor = function (editor)
		editor.scroll:SetBackdrop (nil)
		editor.editbox:SetBackdrop (nil)
		gump:ReskinSlider (editor.scroll)

		if (not editor.__background) then
			editor.__background = editor:CreateTexture (nil, "background")
		end

		editor:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
		editor:SetBackdropBorderColor (0, 0, 0, 1)

		editor.__background:SetTexture (0.2317647, 0.2317647, 0.2317647)
		editor.__background:SetVertexColor (0.27, 0.27, 0.27)
		editor.__background:SetAlpha (0.8)
		editor.__background:SetVertTile (true)
		editor.__background:SetHorizTile (true)
		editor.__background:SetAllPoints()
	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> constants

	local end_window_spacement = 0

	--prefix used on sync statistics
	local CONST_GUILD_SYNC = "GS"

--> settings

	local animation_speed = 33
	local animation_speed_hightravel_trigger = 5
	local animation_speed_hightravel_maxspeed = 3
	local animation_speed_lowtravel_minspeed = 0.33
	local animation_func_left
	local animation_func_right

	gump:NewColor ("DETAILS_API_ICON", .5, .4, .3, 1)
	gump:NewColor ("DETAILS_STATISTICS_ICON", .8, .8, .8, 1)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> core



	function _detalhes:fazer_animacoes (amt_barras)

		if (self.bars_sort_direction == 2) then

			for i = _math_min (self.rows_fit_in_window, amt_barras) - 1, 1, -1 do
				local row = self.barras [i]
				local row_proxima = self.barras [i-1]

				if (row_proxima and not row.animacao_ignorar) then
					local v = row.statusbar.value
					local v_proxima = row_proxima.statusbar.value

					if (v_proxima > v) then
						if (row.animacao_fim >= v_proxima) then
							row:SetValue (v_proxima)
						else
							row:SetValue (row.animacao_fim)
							row_proxima.statusbar:SetValue (row.animacao_fim)
						end
					end
				end
			end

			for i = 1, self.rows_fit_in_window -1 do
				local row = self.barras [i]
				if (row.animacao_ignorar) then
					row.animacao_ignorar = nil
					if (row.tem_animacao) then
						row.tem_animacao = false
						row:SetScript ("OnUpdate", nil)
					end
				else
					if (row.animacao_fim ~= row.animacao_fim2) then
						_detalhes:AnimarBarra (row, row.animacao_fim)
						row.animacao_fim2 = row.animacao_fim
					end
				end
			end
		else
			for i = 2, self.rows_fit_in_window do
				local row = self.barras [i]
				local row_proxima = self.barras [i+1]

				if (row_proxima and not row.animacao_ignorar) then
					local v = row.statusbar.value
					local v_proxima = row_proxima.statusbar.value

					if (v_proxima > v) then
						if (row.animacao_fim >= v_proxima) then
							row:SetValue (v_proxima)
						else
							row:SetValue (row.animacao_fim)
							row_proxima.statusbar:SetValue (row.animacao_fim)
						end
					end
				end
			end

			for i = 2, self.rows_fit_in_window do
				local row = self.barras [i]
				if (row.animacao_ignorar) then
					row.animacao_ignorar = nil
					if (row.tem_animacao) then
						row.tem_animacao = false
						row:SetScript ("OnUpdate", nil)
					end
				else
					if (row.animacao_fim ~= row.animacao_fim2) then
						_detalhes:AnimarBarra (row, row.animacao_fim)
						row.animacao_fim2 = row.animacao_fim
					end
				end
			end
		end

	end

	--> animation with acceleration
	local animation_left_with_accel = function (self, deltaTime)
		local distance = self.inicio - self.fim

		-- DefaultSpeed * max of ( min of (Distance / TriggerSpeed , MaxSpeed) , LowSpeed )
		local calcAnimationSpeed = animation_speed * _math_max (_math_min (distance/animation_speed_hightravel_trigger, animation_speed_hightravel_maxspeed), animation_speed_lowtravel_minspeed)

		self.inicio = self.inicio - (calcAnimationSpeed * deltaTime)
		self:SetValue (self.inicio)
		if (self.inicio-0.1 <= self.fim) then
			self.tem_animacao = false
			self:SetScript ("OnUpdate", nil)
		end
	end

	local animation_right_with_accel = function (self, deltaTime)
		local distance = self.fim - self.inicio
		local calcAnimationSpeed = animation_speed * _math_max (_math_min (distance/animation_speed_hightravel_trigger, animation_speed_hightravel_maxspeed), animation_speed_lowtravel_minspeed)

		self.inicio = self.inicio + (calcAnimationSpeed * deltaTime)
		self:SetValue (self.inicio)
		if (self.inicio+0.1 >= self.fim) then
			self.tem_animacao = false
			self:SetScript ("OnUpdate", nil)
		end
	end

	--> initiate with defaults
	animation_func_left  = animation_left_with_accel
	animation_func_right = animation_right_with_accel

	function _detalhes:AnimarBarra (esta_barra, fim)
		esta_barra.inicio = esta_barra.statusbar.value
		esta_barra.fim = fim
		esta_barra.tem_animacao = true

		if (esta_barra.fim > esta_barra.inicio) then
			esta_barra:SetScript ("OnUpdate", animation_func_right)
		else
			esta_barra:SetScript ("OnUpdate", animation_func_left)
		end
	end

	function _detalhes:RefreshAnimationFunctions()
		animation_speed = _detalhes.animation_speed
		animation_speed_hightravel_trigger = _detalhes.animation_speed_triggertravel
		animation_speed_hightravel_maxspeed = _detalhes.animation_speed_maxtravel
		animation_speed_lowtravel_minspeed = _detalhes.animation_speed_mintravel
	end

	local update_group_points = function (self, _x, _y, _w, _h)
		local metade_largura = _w/2
		local metade_altura = _h/2

		local statusbar_y_mod = 0
		if (not self.show_statusbar) then
			statusbar_y_mod = 14 * self.baseframe:GetScale()
		end

		if (not self.ponto1) then
			self.ponto1 = {x = _x - metade_largura, y = _y + metade_altura + (statusbar_y_mod*-1)} --topleft
			self.ponto2 = {x = _x - metade_largura, y = _y - metade_altura + statusbar_y_mod} --bottomleft
			self.ponto3 = {x = _x + metade_largura, y = _y - metade_altura + statusbar_y_mod} --bottomright
			self.ponto4 = {x = _x + metade_largura, y = _y + metade_altura + (statusbar_y_mod*-1)} --topright
		else
			self.ponto1.x = _x - metade_largura
			self.ponto1.y = _y + metade_altura + (statusbar_y_mod*-1)
			self.ponto2.x = _x - metade_largura
			self.ponto2.y = _y - metade_altura + statusbar_y_mod
			self.ponto3.x = _x + metade_largura
			self.ponto3.y = _y - metade_altura + statusbar_y_mod
			self.ponto4.x = _x + metade_largura
			self.ponto4.y = _y + metade_altura + (statusbar_y_mod*-1)
		end
	end

	function _detalhes:AtualizaPontos()
		local _x, _y = self:GetPositionOnScreen()
		if (not _x) then
 			return
 		end

		local _w, _h = self:GetRealSize()

		update_group_points (self, _x, _y, _w, _h)

	end

--------------------------------------------------------------------------------------------------------

	--> LibWindow-1.1 by Mikk http://www.wowace.com/profiles/mikk/
	--> this is the restore function from Libs\LibWindow-1.1\LibWindow-1.1.lua.
	--> we can't schedule a new save after restoring, we save it inside the instance without frame references and always attach to UIparent.
	function _detalhes:RestoreLibWindow()
		local frame = self.baseframe
		if (frame) then
			if (self.libwindow.x) then

				local x = self.libwindow.x
				local y = self.libwindow.y
				local point = self.libwindow.point
				local s = self.libwindow.scale

				if s then
					(frame.lw11origSetScale or frame.SetScale)(frame,s)
				else
					s = frame:GetScale()
				end

				if not x or not y then		-- nothing stored in config yet, smack it in the center
					x=0; y=0; point="CENTER"
				end

				x = x/s
				y = y/s

				frame:ClearAllPoints()
				if not point and y==0 then	-- errr why did i do this check again? must have been a reason, but i can't remember it =/
					point="CENTER"
				end

				--> Details: using UIParent always in order to not break the positioning when using AddonSkin with ElvUI.
				if not point then	-- we have position, but no point, which probably means we're going from data stored by the addon itself before LibWindow was added to it. It was PROBABLY topleft->bottomleft anchored. Most do it that way.
					frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y) --frame:SetPoint("TOPLEFT", frame:GetParent(), "BOTTOMLEFT", x, y)
					-- make it compute a better attachpoint (on next update)
					--_detalhes:ScheduleTimer ("SaveLibWindow", 0.05, self)
					return
				end

				frame:SetPoint(point, UIParent, point, x, y)

			end
		end
	end

	--> LibWindow-1.1 by Mikk http://www.wowace.com/profiles/mikk/
	--> this is the save function from Libs\LibWindow-1.1\LibWindow-1.1.lua.
	--> we need to make it save inside the instance object without frame references and also we must always use UIParent due to embed settings for ElvUI and LUI.

		function _detalhes:SaveLibWindow()
			local frame = self.baseframe
			if (frame) then
				local left = frame:GetLeft()
				if (not left) then
					return _detalhes:ScheduleTimer ("SaveLibWindow", 0.05, self)
				end
					--> Details: we are always using UIParent here or the addon break when using Embeds.
					local parent = UIParent --local parent = frame:GetParent() or nilParent
					-- No, this won't work very well with frames that aren't parented to nil or UIParent
					local s = frame:GetScale()
					local left,top = frame:GetLeft()*s, frame:GetTop()*s
					local right,bottom = frame:GetRight()*s, frame:GetBottom()*s
					local pwidth, pheight = parent:GetWidth(), parent:GetHeight()

					local x,y,point;
					if left < (pwidth-right) and left < abs((left+right)/2 - pwidth/2) then
						x = left;
						point="LEFT";
					elseif (pwidth-right) < abs((left+right)/2 - pwidth/2) then
						x = right-pwidth;
						point="RIGHT";
					else
						x = (left+right)/2 - pwidth/2;
						point="";
					end

					if bottom < (pheight-top) and bottom < abs((bottom+top)/2 - pheight/2) then
						y = bottom;
						point="BOTTOM"..point;
					elseif (pheight-top) < abs((bottom+top)/2 - pheight/2) then
						y = top-pheight;
						point="TOP"..point;
					else
						y = (bottom+top)/2 - pheight/2;
						-- point=""..point;
					end

					if point=="" then
						point = "CENTER"
					end

				----------------------------------------
				--> save inside the instance object
				self.libwindow.x = x
				self.libwindow.y = y
				self.libwindow.point = point
				self.libwindow.scale = s
			end
		end

	--> end for libwindow-1.1
--------------------------------------------------------------------------------------------------------

	function _detalhes:SaveMainWindowSize()

		local baseframe_width = self.baseframe:GetWidth()
		if (not baseframe_width) then
			return _detalhes:ScheduleTimer ("SaveMainWindowSize", 1, self)
		end
		local baseframe_height = self.baseframe:GetHeight()

		--> calc position
		local _x, _y = self:GetPositionOnScreen()
		if (not _x) then
 			return _detalhes:ScheduleTimer ("SaveMainWindowSize", 1, self)
 		end

		--> save the position
		local _w = baseframe_width
		local _h = baseframe_height

		local mostrando = self.mostrando

		self.posicao[mostrando].x = _x
		self.posicao[mostrando].y = _y
		self.posicao[mostrando].w = _w
		self.posicao[mostrando].h = _h

		update_group_points (self, _x, _y, _w, _h)

		self.baseframe.BoxBarrasAltura = self.baseframe:GetHeight() - end_window_spacement --> espa�o para o final da janela

		return {altura = self.baseframe:GetHeight(), largura = self.baseframe:GetWidth(), x = _x, y = _y}
	end

	function _detalhes:SaveMainWindowPosition (instance)

		if (instance) then
			self = instance
		end
		local mostrando = self.mostrando

		--> get sizes
		local baseframe_width = self.baseframe:GetWidth()
		if (not baseframe_width) then
			return _detalhes:ScheduleTimer ("SaveMainWindowPosition", 1, self)
		end
		local baseframe_height = self.baseframe:GetHeight()

		--> calc position
		local _x, _y = self:GetPositionOnScreen()
		if (not _x) then
 			return _detalhes:ScheduleTimer ("SaveMainWindowPosition", 1, self)
 		end

		self:SaveLibWindow()

		--> save the position
		local _w = baseframe_width
		local _h = baseframe_height

		self.posicao[mostrando].x = _x
		self.posicao[mostrando].y = _y
		self.posicao[mostrando].w = _w
		self.posicao[mostrando].h = _h

		update_group_points (self, _x, _y, _w, _h)

		self.baseframe.BoxBarrasAltura = self.baseframe:GetHeight() - end_window_spacement --> espa�o para o final da janela

		return {altura = self.baseframe:GetHeight(), largura = self.baseframe:GetWidth(), x = _x, y = _y}
	end

	function _detalhes:RestoreMainWindowPosition (pre_defined)

		if (not pre_defined and self.libwindow.x and self.mostrando == "normal" and not _detalhes.instances_no_libwindow) then
			local s = self.window_scale
			self.baseframe:SetScale (s)
			self.rowframe:SetScale (s)

			self.baseframe:SetWidth (self.posicao[self.mostrando].w)
			self.baseframe:SetHeight (self.posicao[self.mostrando].h)

			self:RestoreLibWindow()
			self.baseframe.BoxBarrasAltura = self.baseframe:GetHeight() - end_window_spacement --> espa�o para o final da janela
			return
		end

		local s = self.window_scale
		self.baseframe:SetScale (s)
		self.rowframe:SetScale (s)

		local _scale = self.baseframe:GetEffectiveScale()
		local _UIscale = _UIParent:GetScale()

		local novo_x = self.posicao[self.mostrando].x*_UIscale/_scale
		local novo_y = self.posicao[self.mostrando].y*_UIscale/_scale

		if (pre_defined and pre_defined.x) then --> overwrite
			novo_x = pre_defined.x*_UIscale/_scale
			novo_y = pre_defined.y*_UIscale/_scale
			self.posicao[self.mostrando].w = pre_defined.largura
			self.posicao[self.mostrando].h = pre_defined.altura

		elseif (pre_defined and not pre_defined.x) then
			_detalhes:Msg ("invalid pre_defined table for resize, please rezise the window manually.")
		end

		self.baseframe:SetWidth (self.posicao[self.mostrando].w)
		self.baseframe:SetHeight (self.posicao[self.mostrando].h)

		self.baseframe:ClearAndSetPoint ("CENTER", _UIParent, "CENTER", novo_x, novo_y)

	end

	function _detalhes:RestoreMainWindowPositionNoResize (pre_defined, x, y)

		x = x or 0
		y = y or 0

		local _scale = self.baseframe:GetEffectiveScale()
		local _UIscale = _UIParent:GetScale()

		local novo_x = self.posicao[self.mostrando].x*_UIscale/_scale
		local novo_y = self.posicao[self.mostrando].y*_UIscale/_scale

		if (pre_defined) then --> overwrite
			novo_x = pre_defined.x*_UIscale/_scale
			novo_y = pre_defined.y*_UIscale/_scale
			self.posicao[self.mostrando].w = pre_defined.largura
			self.posicao[self.mostrando].h = pre_defined.altura
		end

		self.baseframe:ClearAndSetPoint ("CENTER", _UIParent, "CENTER", novo_x + x, novo_y + y)
		self.baseframe.BoxBarrasAltura = self.baseframe:GetHeight() - end_window_spacement --> espa�o para o final da janela
	end

	function _detalhes:CreatePositionTable()
		local t = {pos_table = true}

		if (self.libwindow) then
			t.x = self.libwindow.x
			t.y = self.libwindow.y
			t.scale = self.libwindow.scale
			t.point = self.libwindow.point
		end

		--> old way to save positions
		t.x_legacy = self.posicao.normal.x
		t.y_legacy = self.posicao.normal.y

		--> size
		t.w = self.posicao.normal.w
		t.h = self.posicao.normal.h

		return t
	end

	function _detalhes:RestorePositionFromPositionTable (t)
		if (not t.pos_table) then
			return
		end

		if (t.x) then
			self.libwindow.x = t.x
			self.libwindow.y = t.y
			self.libwindow.scale = t.scale
			self.libwindow.point = t.point
		end

		self.posicao.normal.x = t.x_legacy
		self.posicao.normal.y = t.y_legacy

		self.posicao.normal.w = t.w
		self.posicao.normal.h = t.h

		return self:RestoreMainWindowPosition()
	end

	function _detalhes:ResetaGump (instancia, tipo, segmento)
		if (not instancia or _type (instancia) == "boolean") then
			segmento = tipo
			tipo = instancia
			instancia = self
		end

		if (tipo and tipo == 0x1) then --> entrando em combate
			if (instancia.segmento == -1) then --> esta mostrando a tabela overall
				return
			end
		end

		if (segmento and instancia.segmento ~= segmento) then
			return
		end

		instancia.barraS = {nil, nil} --> zera o iterator
		instancia.rows_showing = 0 --> resetou, ent�o n�o esta mostranho nenhuma barra

		for i = 1, instancia.rows_created, 1 do --> limpa a refer�ncia do que estava sendo mostrado na barra
			local esta_barra= instancia.barras[i]
			esta_barra.minha_tabela = nil
			esta_barra.animacao_fim = 0
			esta_barra.animacao_fim2 = 0
		end

		if (instancia.rolagem) then
			instancia:EsconderScrollBar() --> hida a scrollbar
		end
		instancia.need_rolagem = false
		instancia.bar_mod = nil

	end

	function _detalhes:ReajustaGump()
		if (self.mostrando == "normal") then --> somente alterar o tamanho das barras se tiver mostrando o gump normal

			if (not self.baseframe.isStretching and self.stretchToo and #self.stretchToo > 0) then
				if (self.eh_horizontal or self.eh_tudo or (self.verticalSnap and not self.eh_vertical)) then
					for _, instancia in _ipairs (self.stretchToo) do
						instancia.baseframe:SetWidth (self.baseframe:GetWidth())
						local mod = (self.baseframe:GetWidth() - instancia.baseframe._place.largura) / 2
						instancia:RestoreMainWindowPositionNoResize (instancia.baseframe._place, mod, nil)
--						instancia:BaseFrameSnap() -- TODO: stretch resize bug
					end
				end
				if ( (self.eh_vertical or self.eh_tudo or not self.eh_horizontal) and (not self.verticalSnap or self.eh_vertical)) then
					for _, instancia in _ipairs (self.stretchToo) do
						if (instancia.baseframe) then --> esta criada
							instancia.baseframe:SetHeight (self.baseframe:GetHeight())
							local mod
							if (self.eh_vertical) then
								mod = (self.baseframe:GetHeight() - instancia.baseframe._place.altura) / 2
							else
								mod = - (self.baseframe:GetHeight() - instancia.baseframe._place.altura) / 2
							end
							instancia:RestoreMainWindowPositionNoResize (instancia.baseframe._place, nil, mod)
--							instancia:BaseFrameSnap() -- TODO: stretch resize bug
						end
					end
				end
			elseif (self.baseframe.isStretching and self.stretchToo and #self.stretchToo > 0) then
				if (self.baseframe.stretch_direction == "top") then
					for _, instancia in _ipairs (self.stretchToo) do
						instancia.baseframe:SetHeight (self.baseframe:GetHeight())
						local mod = (self.baseframe:GetHeight() - (instancia.baseframe._place.altura or instancia.baseframe:GetHeight())) / 2
						instancia:RestoreMainWindowPositionNoResize (instancia.baseframe._place, nil, mod)
					end
				elseif (self.baseframe.stretch_direction == "bottom") then
					for _, instancia in _ipairs (self.stretchToo) do
						instancia.baseframe:SetHeight (self.baseframe:GetHeight())
						local mod = (self.baseframe:GetHeight() - instancia.baseframe._place.altura) / 2
						mod = mod * -1
						instancia:RestoreMainWindowPositionNoResize (instancia.baseframe._place, nil, mod)
					end
				end
			end

			if (self.stretch_button_side == 2) then
				self:StretchButtonAnchor (2)
			end

			--> reajusta o freeze
			if (self.freezed) then
				_detalhes:Freeze (self)
			end

			-- -4 difere a precis�o de quando a barra ser� adicionada ou apagada da barra
			self.baseframe.BoxBarrasAltura = (self.baseframe:GetHeight()) - end_window_spacement

			local T = self.rows_fit_in_window
			if (not T) then --> primeira vez que o gump esta sendo reajustado
				T = _math_floor (self.baseframe.BoxBarrasAltura / self.row_height)
			end

			self.rows_fit_in_window = _math_floor ( self.baseframe.BoxBarrasAltura / self.row_height)

			--> verifica se precisa criar mais barras
			if (self.rows_fit_in_window > #self.barras) then--> verifica se precisa criar mais barras
				for i  = #self.barras+1, self.rows_fit_in_window, 1 do
					gump:CriaNovaBarra (self, i) --> cria nova barra
				end
				self.rows_created = #self.barras
			end

			--> faz um cache do tamanho das barras
			self.cached_bar_width = self.barras[1] and self.barras[1]:GetWidth() or 0

			--> seta a largura das barras
			if (self.bar_mod and self.bar_mod ~= 0) then
				for index = 1, self.rows_fit_in_window do
					self.barras [index]:SetWidth (self.baseframe:GetWidth()+self.bar_mod)
				end
			else
				for index = 1, self.rows_fit_in_window do
					self.barras [index]:SetWidth (self.baseframe:GetWidth()+self.row_info.space.right)
				end
			end

			--> verifica se precisa esconder ou mostrar alguma barra
			local A = self.barraS[1]
			if (not A) then --> primeira vez que o resize esta sendo usado, no caso no startup do addon ou ao criar uma nova inst�ncia
				--> hida as barras n�o usadas
				for i = 1, self.rows_created, 1 do
					gump:Fade (self.barras [i], 1)
					self.barras [i].on = false
				end
				return
			end

			local X = self.rows_showing
			local C = self.rows_fit_in_window

			--> novo iterator
			local barras_diff = C - T --> aqui pega a quantidade de barras, se aumentou ou diminuiu
			if (barras_diff > 0) then --> ganhou barras_diff novas barras
				local fim_iterator = self.barraS[2] --> posi��o atual
				fim_iterator = fim_iterator+barras_diff --> nova posi��o
				local excedeu_iterator = fim_iterator - X --> total que ta sendo mostrado - fim do iterator
				if (excedeu_iterator > 0) then --> extrapolou
					fim_iterator = X --> seta o fim do iterator pra ser na ultima barra
					self.barraS[2] = fim_iterator --> fim do iterator setado

					local inicio_iterator = self.barraS[1]
					if (inicio_iterator-excedeu_iterator > 0) then --> se as barras que sobraram preenchem o inicio do iterator
						inicio_iterator = inicio_iterator-excedeu_iterator --> pega o novo valor do iterator
						self.barraS[1] = inicio_iterator
					else
						self.barraS[1] = 1 --> se ganhou mais barras pra cima, ignorar elas e mover o iterator para a poci��o inicial
					end
				else
					--> se n�o extrapolou esta okey e esta mostrando a quantidade de barras correta
					self.barraS[2] = fim_iterator
				end

				for index = T+1, C do
					local barra = self.barras[index]
					if (barra) then
						if (index <= X) then
							--gump:Fade (barra, 0)
							gump:Fade (barra, "out")
						else
							--if (self.baseframe.isStretching or self.auto_resize) then
								gump:Fade (barra, 1)
							--else
							--	gump:Fade (barra, 1)
							--end
						end
					end
				end

			elseif (barras_diff < 0) then --> perdeu barras_diff barras
				local fim_iterator = self.barraS[2] --> posi��o atual
				if (not (fim_iterator == X and fim_iterator < C)) then --> calcula primeiro as barras que foram perdidas s�o barras que n�o estavam sendo usadas
					--> perdi X barras, diminui X posi��es no iterator
					local perdeu = _math_abs (barras_diff)

					if (fim_iterator == X) then --> se o iterator tiver na ultima posi��o
						perdeu = perdeu - (C - X)
					end

					fim_iterator = fim_iterator - perdeu

					if (fim_iterator < C) then
						fim_iterator = C
					end

					self.barraS[2] = fim_iterator

					for index = T, C+1, -1 do
						local barra = self.barras[index]
						if (barra) then
							if (self.baseframe.isStretching or self.auto_resize) then
								gump:Fade (barra, 1)
							else
								--gump:Fade (barra, "in", 0.1)
								gump:Fade (barra, 1)
							end
						end
					end
				end
			end

			if (X <= C) then --> desligar a rolagem
				if (self.rolagem and not self.baseframe.isStretching) then
					self:EsconderScrollBar()
				end
				self.need_rolagem = false
			else --> ligar ou atualizar a rolagem
				if (not self.rolagem and not self.baseframe.isStretching) then
					self:MostrarScrollBar()
				end
				self.need_rolagem = true
			end

			--> verificar o tamanho dos nomes
			local qual_barra = 1
			for i = self.barraS[1], self.barraS[2], 1 do
				local esta_barra = self.barras [qual_barra]
				local tabela = esta_barra.minha_tabela

				if (tabela) then --> a barra esta mostrando alguma coisa

					if (tabela._custom) then
						tabela (esta_barra, self)
					elseif (tabela._refresh_window) then
						tabela:_refresh_window (esta_barra, self)
					else
						tabela:RefreshBarra (esta_barra, self, true)
					end

				end

				qual_barra = qual_barra+1
			end

			--> for�a o pr�ximo refresh
			self.showing[self.atributo].need_refresh = true

		end
	end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> panels

--> cooltip presets
	local preset3_backdrop = {bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]], edgeFile = [[Interface\AddOns\Details\images\border_3]], tile=true,
	edgeSize = 16, tileSize = 64, insets = {left = 3, right = 3, top = 4, bottom = 4}}

	local white_table = {1, 1, 1, 1}
	local black_table = {0, 0, 0, 1}
	local gray_table = {0.37, 0.37, 0.37, 0.95}

	local preset2_backdrop = {bgFile = [[Interface\AddOns\Details\images\background]], edgeFile = [[Interface\Buttons\WHITE8X8]], tile=true,
	edgeSize = 1, tileSize = 64, insets = {left = 0, right = 0, top = 0, bottom = 0}}
	_detalhes.cooltip_preset2_backdrop = preset2_backdrop

	--"Details BarBorder 3"
	function _detalhes:CooltipPreset (preset)
		local GameCooltip = GameCooltip

		GameCooltip:Reset()

		if (preset == 1) then
			GameCooltip:SetOption ("TextFont", "Friz Quadrata TT")
			GameCooltip:SetOption ("TextColor", "orange")
			GameCooltip:SetOption ("TextSize", 12)
			GameCooltip:SetOption ("ButtonsYMod", -4)
			GameCooltip:SetOption ("YSpacingMod", -4)
			GameCooltip:SetOption ("IgnoreButtonAutoHeight", true)
			GameCooltip:SetColor (1, 0.5, 0.5, 0.5, 0.5)

		elseif (preset == 2) then
			GameCooltip:SetOption ("TextFont", "Friz Quadrata TT")
			GameCooltip:SetOption ("TextColor", "orange")
			GameCooltip:SetOption ("TextSize", 12)
			GameCooltip:SetOption ("FixedWidth", 220)
			GameCooltip:SetOption ("ButtonsYMod", -4)
			GameCooltip:SetOption ("YSpacingMod", -4)
			GameCooltip:SetOption ("IgnoreButtonAutoHeight", true)
			GameCooltip:SetColor (1, 0, 0, 0, 0)

			GameCooltip:SetOption ("LeftBorderSize", -5)
			GameCooltip:SetOption ("RightBorderSize", 5)

			GameCooltip:SetBackdrop (1, preset2_backdrop, gray_table, black_table)

		elseif (preset == 2.1) then
			GameCooltip:SetOption ("TextFont", "Friz Quadrata TT")
			GameCooltip:SetOption ("TextColor", "orange")
			GameCooltip:SetOption ("TextSize", 10)
			GameCooltip:SetOption ("FixedWidth", 220)
			GameCooltip:SetOption ("ButtonsYMod", 0)
			GameCooltip:SetOption ("YSpacingMod", -4)
			GameCooltip:SetOption ("IgnoreButtonAutoHeight", true)
			GameCooltip:SetColor (1, 0, 0, 0, 0)

			GameCooltip:SetBackdrop (1, preset2_backdrop, gray_table, black_table)

		elseif (preset == 3) then
			GameCooltip:SetOption ("TextFont", "Friz Quadrata TT")
			GameCooltip:SetOption ("TextColor", "orange")
			GameCooltip:SetOption ("TextSize", 12)
			GameCooltip:SetOption ("FixedWidth", 220)
			GameCooltip:SetOption ("ButtonsYMod", -4)
			GameCooltip:SetOption ("YSpacingMod", -4)
			GameCooltip:SetOption ("IgnoreButtonAutoHeight", true)
			GameCooltip:SetColor (1, 0.5, 0.5, 0.5, 0.5)

			GameCooltip:SetBackdrop (1, preset3_backdrop, nil, white_table)

		end
	end

--> cria o frame de wait for plugin
	function _detalhes:CreateWaitForPlugin()

		local WaitForPluginFrame = CreateFrame ("Frame", "DetailsWaitForPluginFrame" .. self.meu_id, UIParent)
		local WaitTexture = WaitForPluginFrame:CreateTexture (nil, "overlay")
		WaitTexture:SetTexture ("Interface\\UNITPOWERBARALT\\Mechanical_Circular_Frame")
		WaitTexture:SetPoint ("CENTER", WaitForPluginFrame)
		WaitTexture:SetWidth (180)
		WaitTexture:SetHeight (180)
		WaitForPluginFrame.wheel = WaitTexture
		local RotateAnimGroup = WaitForPluginFrame:CreateAnimationGroup()
		local rotate = RotateAnimGroup:CreateAnimation ("Rotation")
		rotate:SetDegrees (360)
		rotate:SetDuration (60)
		RotateAnimGroup:SetLooping ("repeat")

		local bgpanel = gump:NewPanel (UIParent, UIParent, "DetailsWaitFrameBG"..self.meu_id, nil, 120, 30, false, false, false)
		bgpanel:SetPoint ("CENTER", WaitForPluginFrame, "CENTER")
		bgpanel:SetBackdrop ({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"})
		bgpanel:SetBackdropColor (.2, .2, .2, 1)

		local label = gump:NewLabel (UIParent, UIParent, nil, nil, Loc ["STRING_WAITPLUGIN"]) --> localize-me
		label.color = "silver"
		label:SetPoint ("CENTER", WaitForPluginFrame, "CENTER")
		label:SetJustifyH ("CENTER")
		label:Hide()

		WaitForPluginFrame:Hide()
		self.wait_for_plugin_created = true

		function self:WaitForPlugin()

			self:ChangeIcon ([[Interface\GossipFrame\ActiveQuestIcon]])

			if (WaitForPluginFrame:IsShown() and WaitForPluginFrame:GetParent() == self.baseframe) then
				self.waiting_pid = self:ScheduleTimer ("ExecDelayedPlugin1", 5, self)
			end

			WaitForPluginFrame:SetParent (self.baseframe)
			WaitForPluginFrame:SetAllPoints (self.baseframe)
			local size = math.max (self.baseframe:GetHeight()* 0.35, 100)
			WaitForPluginFrame.wheel:SetWidth (size)
			WaitForPluginFrame.wheel:SetHeight (size)
			WaitForPluginFrame:Show()
			label:Show()
			bgpanel:Show()
			RotateAnimGroup:Play()

			self.waiting_raid_plugin = true

			self.waiting_pid = self:ScheduleTimer ("ExecDelayedPlugin1", 5, self)
		end

		function self:CancelWaitForPlugin()
			RotateAnimGroup:Stop()
			WaitForPluginFrame:Hide()
			label:Hide()
			bgpanel:Hide()
		end

		function self:ExecDelayedPlugin1()

			self.waiting_raid_plugin = nil
			self.waiting_pid = nil

			RotateAnimGroup:Stop()
			WaitForPluginFrame:Hide()
			label:Hide()
			bgpanel:Hide()

			if (self.modo == _detalhes._detalhes_props["MODO_RAID"]) then
				_detalhes.RaidTables:EnableRaidMode (self)

			end
		end
	end

--> tutorial bookmark (removed)
	function _detalhes:TutorialBookmark (instance)
		_detalhes:SetTutorialCVar ("ATTRIBUTE_SELECT_TUTORIAL1", true)
	end


--> raid history window ~history ~statistics

	function _detalhes:InitializeRaidHistoryWindow()
		local DetailsRaidHistoryWindow = CreateFrame ("Frame", "DetailsRaidHistoryWindow", UIParent)
		DetailsRaidHistoryWindow.Frame = DetailsRaidHistoryWindow
		DetailsRaidHistoryWindow.__name = Loc ["STRING_STATISTICS"]
		DetailsRaidHistoryWindow.real_name = "DETAILS_STATISTICS"
		DetailsRaidHistoryWindow.__icon = [[Interface\AddOns\Details\images\icons]]
		DetailsRaidHistoryWindow.__iconcoords = {278/512, 314/512, 43/512, 76/512}
		DetailsRaidHistoryWindow.__iconcolor = "DETAILS_STATISTICS_ICON"
		DetailsPluginContainerWindow.EmbedPlugin (DetailsRaidHistoryWindow, DetailsRaidHistoryWindow, true)

		function DetailsRaidHistoryWindow.RefreshWindow()
			_detalhes:OpenRaidHistoryWindow()
		end
	end

	function _detalhes:OpenRaidHistoryWindow (_raid, _boss, _difficulty, _role, _guild, _player_base, _player_name, _history_type)

		if (not DetailsRaidHistoryWindow or not DetailsRaidHistoryWindow.Initialized) then

			local db = _detalhes.storage:OpenRaidStorage()
			if (not db) then
				return _detalhes:Msg (Loc ["STRING_GUILDDAMAGERANK_DATABASEERROR"])
			end

			DetailsRaidHistoryWindow.Initialized = true

			local f = DetailsRaidHistoryWindow or CreateFrame ("Frame", "DetailsRaidHistoryWindow", UIParent) --, "ButtonFrameTemplate"
			f:SetPoint ("CENTER", UIParent, "CENTER")
			f:SetFrameStrata ("HIGH")
			f:SetToplevel (true)

			f:SetMovable (true)
			f:SetWidth (850)
			f:SetHeight (500)
			tinsert (UISpecialFrames, "DetailsRaidHistoryWindow")

			f.Mode = 2

			_detalhes:FormatBackground (f)

			--> menu title bar
				local titlebar = _detalhes:CreateWindowTitleBar (f)

			--> menu title
				local titleLabel = _detalhes.gump:NewLabel (titlebar, titlebar, nil, "titulo", "Details! " .. Loc ["STRING_STATISTICS"], "GameFontNormal", 12) --{227/255, 186/255, 4/255}
				titleLabel:SetPoint ("CENTER", titlebar , "CENTER")
				titleLabel:SetPoint ("TOP", titlebar , "TOP", 0, -4)

			--> close button
				_detalhes:CreateWindowCloseButton (f, titlebar, function() f:Hide() end)

			if (not _detalhes:GetTutorialCVar ("HISTORYPANEL_TUTORIAL")) then
				local tutorialFrame = CreateFrame ("Frame", "$parentTutorialFrame", f)
				tutorialFrame:SetPoint ("CENTER", f, "CENTER")
				tutorialFrame:SetFrameStrata ("DIALOG")
				tutorialFrame:SetSize (400, 300)
				tutorialFrame:SetBackdrop ({bgFile = [[Interface\AddOns\Details\images\background]], tile = true, tileSize = 16,
				insets = {left = 0, right = 0, top = 0, bottom = 0}, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize=1})
				tutorialFrame:SetBackdropColor (0, 0, 0, 1)

				tutorialFrame.Title = _detalhes.gump:CreateLabel (tutorialFrame, "Statistics" , 12, "orange") --curse localization isn't adding new strings (and I deleted the old one)
				tutorialFrame.Title:SetPoint ("TOP", tutorialFrame, "TOP", 0, -5)

				tutorialFrame.Desc = _detalhes.gump:CreateLabel (tutorialFrame, Loc ["STRING_GUILDDAMAGERANK_TUTORIAL_DESC"], 12)
				tutorialFrame.Desc.width = 370
				tutorialFrame.Desc:SetPoint ("TOPLEFT", tutorialFrame, "TOPLEFT", 10, -45)


				local closeButton = _detalhes.gump:CreateButton (tutorialFrame, function() _detalhes:SetTutorialCVar ("HISTORYPANEL_TUTORIAL", true); tutorialFrame:Hide() end, 80, 20, Loc ["STRING_OPTIONS_CHART_CLOSE"])
				closeButton:SetPoint ("BOTTOM", tutorialFrame, "BOTTOM", 0, 10)
				closeButton:SetTemplate (_detalhes.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))
			end

			--wallpaper
			local background = f:CreateTexture ("$parentBackgroundImage", "border")
			background:SetAlpha (0.3)
			background:SetPoint ("TOPLEFT", f, "TOPLEFT", 6, -65)
			background:SetPoint ("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 28)

			--separate menu and main list
			local div = f:CreateTexture (nil, "artwork")
			div:SetTexture ([[Interface\ACHIEVEMENTFRAME\UI-Achievement-MetalBorder-Left]])
			div:SetAlpha (0.1)
			div:SetPoint ("TOPLEFT", f, "TOPLEFT", 180, -64)
			div:SetHeight (574)


			--select history or guild rank
			local options_switch_template = _detalhes.gump:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
			local options_text_template = _detalhes.gump:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
			local options_button_template = _detalhes.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")

			local select_history = function()
				f.GuildRankCheckBox:SetValue (false)
				f.HistoryCheckBox:SetValue (true)
				f.Mode = 1
				_G.DetailsRaidHistoryWindow:Refresh()
				f.ReportButton:Hide()
			end
			local select_guildrank = function()
				f.HistoryCheckBox:SetValue (false)
				f.GuildRankCheckBox:SetValue (true)
				DetailsRaidHistoryWindow.select_player:Select (1, true)
				f.select_player2:Hide()
				f.select_player2_label:Hide()
				f.Mode = 2
				_G.DetailsRaidHistoryWindow:Refresh()
				f.ReportButton:Show()
			end

			local HistoryCheckBox, HistoryLabel = _detalhes.gump:CreateSwitch (f, select_history, false, 18, 18, "", "", "HistoryCheckBox", nil, nil, nil, nil, Loc ["STRING_GUILDDAMAGERANK_SHOWHISTORY"], options_switch_template) --, options_text_template
			HistoryCheckBox:ClearAllPoints()
			HistoryCheckBox:SetPoint ("TOPLEFT", f, "TOPLEFT", 100, -34)
			HistoryLabel:ClearAllPoints()
			HistoryLabel:SetPoint ("LEFT", HistoryCheckBox, "RIGHT", 2, 0)
			HistoryCheckBox:SetAsCheckBox()

			local GuildRankCheckBox, GuildRankLabel = _detalhes.gump:CreateSwitch (f, select_guildrank, true, 18, 18, "", "", "GuildRankCheckBox", nil, nil, nil, nil, Loc ["STRING_GUILDDAMAGERANK_SHOWRANK"], options_switch_template) --, options_text_template
			GuildRankCheckBox:ClearAllPoints()
			GuildRankCheckBox:SetPoint ("TOPLEFT", f, "TOPLEFT", 240, -34)
			GuildRankLabel:ClearAllPoints()
			GuildRankLabel:SetPoint ("LEFT", GuildRankCheckBox, "RIGHT", 2, 0)
			GuildRankCheckBox:SetAsCheckBox()

			local guild_sync = function()

				f.RequestedAmount = 0
				f.DownloadedAmount = 0
				f.EstimateSize = 0
				f.DownloadedSize = 0
				f.SyncStartTime = time()

				_detalhes.storage:DBGuildSync()
				f.GuildSyncButton:Disable()

				if (not f.SyncTexture) then
					local workingFrame = CreateFrame ("Frame", nil, f)
					f.WorkingFrame = workingFrame
					workingFrame:SetSize (1, 1)
					f.SyncTextureBackground = workingFrame:CreateTexture (nil, "border")
					f.SyncTextureBackground:SetPoint ("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, -1)
					f.SyncTextureBackground:SetTexture ([[Interface\COMMON\StreamBackground]])
					f.SyncTextureBackground:SetSize (32, 32)
					f.SyncTextureCircle = workingFrame:CreateTexture (nil, "artwork")
					f.SyncTextureCircle:SetPoint ("CENTER", f.SyncTextureBackground, "CENTER", 0, 0)
					f.SyncTextureCircle:SetTexture ([[Interface\COMMON\StreamCircle]])
					f.SyncTextureCircle:SetSize (32, 32)
					f.SyncTextureGrade = workingFrame:CreateTexture (nil, "overlay")
					f.SyncTextureGrade:SetPoint ("CENTER", f.SyncTextureBackground, "CENTER", 0, 0)
					f.SyncTextureGrade:SetTexture ([[Interface\COMMON\StreamFrame]])
					f.SyncTextureGrade:SetSize (32, 32)

					local animationHub = _detalhes.gump:CreateAnimationHub (workingFrame)
					animationHub:SetLooping ("Repeat")
					f.WorkingAnimation = animationHub

					local rotation = _detalhes.gump:CreateAnimation (animationHub, "ROTATION", 1, 3, -360)
				--	rotation:SetTarget (f.SyncTextureCircle) -- TEMP
					--_detalhes.gump:CreateAnimation (animationHub, "ALPHA", 1, 0.5, 0, 1)

					f.SyncText = workingFrame:CreateFontString (nil, "border", "GameFontNormal")
					f.SyncText:SetPoint ("RIGHT", f.SyncTextureBackground, "LEFT", 0, 0)
					f.SyncText:SetText ("working")

					local endAnimationHub = _detalhes.gump:CreateAnimationHub (workingFrame, nil, function() workingFrame:Hide() end)
					_detalhes.gump:CreateAnimation (endAnimationHub, "ALPHA", 1, 0.5, 1, 0)
					f.EndAnimationHub = endAnimationHub
				end

				f.WorkingFrame:Show()
				f.WorkingAnimation:Play()

				C_Timer:NewTicker (10, function (self)
					if (not _detalhes.LastGuildSyncReceived) then
						self:Cancel()
						f.GuildSyncButton:Enable()
						f.EndAnimationHub:Play()
					elseif (_detalhes.LastGuildSyncReceived+10 < GetTime()) then
						f.GuildSyncButton:Enable()
						f.EndAnimationHub:Play()
						self:Cancel()
					end
				end)

			end

			local GuildSyncButton = _detalhes.gump:CreateButton (f, guild_sync, 130, 20, Loc ["STRING_GUILDDAMAGERANK_SYNCBUTTONTEXT"], nil, nil, nil, "GuildSyncButton", nil, nil, options_button_template, options_text_template)
			GuildSyncButton:SetPoint ("TOPRIGHT", f, "TOPRIGHT", -20, -34)
			GuildSyncButton:SetIcon ([[Interface\Buttons\UI-RefreshButton]], 12, 12, "overlay", {0, 1, 0, 1}, nil, 4)

			--> listen to comm events
				local eventListener = _detalhes:CreateEventListener()

				function eventListener:OnCommReceived (event, length, prefix, playerName, realmName, detailsVersion, guildSyncID, data)
					if (prefix == CONST_GUILD_SYNC) then
						--received a list of encounter IDs
						if (guildSyncID == "L") then
							if ( f.RequestedAmount == 0 or not f.RequestedAmount) then
								--if the receiving player reloads, f.RequestedAmount is nil
								return
							end
						--received one encounter table
						elseif (guildSyncID == "A") then
							f.DownloadedAmount = (f.DownloadedAmount or 0) + 1

							--size = 1 byte per characters in the string
							f.EstimateSize = length * f.RequestedAmount > f.EstimateSize and length * f.RequestedAmount or f.RequestedAmount
							f.DownloadedSize = f.DownloadedSize + length
							local downloadSpeed = f.DownloadedSize / (time() - f.SyncStartTime)

							f.SyncText:SetText ("working [downloading " .. f.DownloadedAmount .. "/" .. f.RequestedAmount .. ", " .. format ("%.2f", downloadSpeed/1024) .. "Kbps]" .. " from ".. playerName)
						end
					end
				end

				function eventListener:OnCommSent (event, length, prefix, playerName, realmName, detailsVersion, guildSyncID, missingIDs, arg8, arg9)
					if (prefix == CONST_GUILD_SYNC) then
						--requested a list of encounters
						if (guildSyncID == "R") then


						--requested to download a selected list of encounter tables
						elseif (guildSyncID == "G") then
							f.RequestedAmount = f.RequestedAmount + #missingIDs
							f.SyncText:SetText ("working [downloading " .. f.DownloadedAmount .. "/" .. f.RequestedAmount .. "]")
						end
					end
				end

				eventListener:RegisterEvent ("COMM_EVENT_RECEIVED", "OnCommReceived")
				eventListener:RegisterEvent ("COMM_EVENT_SENT", "OnCommSent")

			function f.BuildReport()
				if (f.LatestResourceTable) then
					local reportFunc = function (IsCurrent, IsReverse, AmtLines)
						local bossName = f.select_boss.label:GetText()
						local bossDiff = f.select_diff.label:GetText()
						local guildName = f.select_guild.label:GetText()

						local reportTable = {"Details!: DPS Rank for: " .. (bossDiff or "") .. " " .. (bossName or "--x--x--") .. " <" .. (guildName or "") .. ">"}
						local result = {}

						for i = 1, AmtLines do
							if (f.LatestResourceTable[i]) then
								local playerName = f.LatestResourceTable[i][1]
								playerName = playerName:gsub ("%|c%x%x%x%x%x%x%x%x", "")
								playerName = playerName:gsub ("%|r", "")
								playerName = playerName:gsub (".*%s", "")
								result[#result+1] = {playerName, f.LatestResourceTable[i][2]}
							else
								break
							end
						end

						_detalhes:FormatReportLines (reportTable, result)
						Details:SendReportLines (reportTable)
					end

					Details:SendReportWindow (reportFunc, nil, nil, true)
				end
			end

			local ReportButton = _detalhes.gump:CreateButton (f, f.BuildReport, 130, 20, Loc ["STRING_OPTIONS_REPORT_ANCHOR"]:gsub (":", ""), nil, nil, nil, "ReportButton", nil, nil, options_button_template, options_text_template)
			ReportButton:SetPoint ("RIGHT", GuildSyncButton, "LEFT", -2, 0)
			ReportButton:SetIcon ([[Interface\Buttons\UI-RefreshButton]], 12, 12, "overlay", {0, 1, 0, 1}, nil, 4)

			--
			function f:SetBackgroundImage (encounterId)
				local instanceId = _detalhes:GetInstanceIdFromEncounterId (encounterId)
				if (instanceId) then
					local file, L, R, T, B = _detalhes:GetRaidBackground (instanceId)
					background:SetTexture (file)
					background:SetTexCoord (L, R, T, B)
				end
			end

			f:SetScript ("OnMouseDown", function(self, button)
				if (self.isMoving) then
					return
				end
				if (button == "RightButton") then
					self:Hide()
				else
					self:StartMoving()
					self.isMoving = true
				end
			end)
			f:SetScript ("OnMouseUp", function(self, button)
				if (self.isMoving and button == "LeftButton") then
					self:StopMovingOrSizing()
					self.isMoving = nil
				end
			end)

			f:SetScript ("OnHide", function()
				--> save latest shown state
				f.LatestSelection = f.LatestSelection or {}
				f.LatestSelection.Raid = DetailsRaidHistoryWindow.select_raid.value
				f.LatestSelection.Boss = DetailsRaidHistoryWindow.select_boss.value
				f.LatestSelection.Diff = DetailsRaidHistoryWindow.select_diff.value
				f.LatestSelection.Role = DetailsRaidHistoryWindow.select_role.value
				f.LatestSelection.Guild = DetailsRaidHistoryWindow.select_guild.value
				f.LatestSelection.PlayerBase = DetailsRaidHistoryWindow.select_player.value
				f.LatestSelection.PlayerName = DetailsRaidHistoryWindow.select_player2.value
			end)


			local dropdown_size = 160
			local icon = [[Interface\AddOns\Details\textures\FriendsFrame\BattleBet-Status-Offline]]

			local diff_list = {}
			local raid_list = {}
			local boss_list = {}
			local guild_list = {}

			local sort_alphabetical2 = function(a,b) return a.value < b.value end

			local on_select = function()
				if (f.Refresh) then
					f:Refresh()
				end
			end

			--> select raid:
			local on_raid_select = function (_, _, raid)
				_detalhes.rank_window.last_raid = raid
				f:UpdateDropdowns (true)
				on_select()
			end
			local build_raid_list = function()
				return raid_list
			end
			local raid_dropdown = gump:CreateDropDown (f, build_raid_list, 1, dropdown_size, 20, "select_raid")
			local raid_string = gump:CreateLabel (f, Loc ["STRING_GUILDDAMAGERANK_RAID"] .. ":", _, _, "GameFontNormal", "select_raid_label")
			raid_dropdown:SetTemplate (gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

			--> select boss:
			local on_boss_select = function (_, _, boss)
				on_select()
			end
			local build_boss_list = function()
				return boss_list
			end
			local boss_dropdown = gump:CreateDropDown (f, build_boss_list, 1, dropdown_size, 20, "select_boss")
			local boss_string = gump:CreateLabel (f, Loc ["STRING_GUILDDAMAGERANK_BOSS"] .. ":", _, _, "GameFontNormal", "select_boss_label")
			boss_dropdown:SetTemplate (gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

			--> select difficulty:
			local on_diff_select = function (_, _, diff)
				_detalhes.rank_window.last_difficulty = diff
				on_select()
			end

			local build_diff_list = function()
				return diff_list
			end
			local diff_dropdown = gump:CreateDropDown (f, build_diff_list, 1, dropdown_size, 20, "select_diff")
			local diff_string = gump:CreateLabel (f, Loc ["STRING_GUILDDAMAGERANK_DIFF"] .. ":", _, _, "GameFontNormal", "select_diff_label")
			diff_dropdown:SetTemplate (gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

			--> select role:
			local on_role_select = function (_, _, role)
				on_select()
			end
			local build_role_list = function()
				return {
					{value = "damage", label = "Damager", icon = icon, onclick = on_role_select},
					{value = "healing", label = "Healer", icon = icon, onclick = on_role_select}
				}
			end
			local role_dropdown = gump:CreateDropDown (f, build_role_list, 1, dropdown_size, 20, "select_role")
			local role_string = gump:CreateLabel (f, Loc ["STRING_GUILDDAMAGERANK_ROLE"] .. ":", _, _, "GameFontNormal", "select_role_label")
			role_dropdown:SetTemplate (gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

			--> select guild:
			local on_guild_select = function (_, _, guild)
				on_select()
			end
			local build_guild_list = function()
				return guild_list
			end
			local guild_dropdown = gump:CreateDropDown (f, build_guild_list, 1, dropdown_size, 20, "select_guild")
			local guild_string = gump:CreateLabel (f, Loc ["STRING_GUILDDAMAGERANK_GUILD"] .. ":", _, _, "GameFontNormal", "select_guild_label")
			guild_dropdown:SetTemplate (gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

			--> select playerbase:
			local on_player_select = function (_, _, player)
				on_select()
			end
			local build_player_list = function()
				return {
					{value = 1, label = Loc ["STRING_GUILDDAMAGERANK_PLAYERBASE_RAID"], icon = icon, onclick = on_player_select},
					{value = 2, label = Loc ["STRING_GUILDDAMAGERANK_PLAYERBASE_INDIVIDUAL"], icon = icon, onclick = on_player_select},
				}
			end
			local player_dropdown = gump:CreateDropDown (f, build_player_list, 1, dropdown_size, 20, "select_player")
			local player_string = gump:CreateLabel (f, Loc ["STRING_GUILDDAMAGERANK_PLAYERBASE"] .. ":", _, _, "GameFontNormal", "select_player_label")
			player_dropdown:SetTemplate (gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

			--> select player:
			local on_player2_select = function (_, _, player)
				f.latest_player_selected = player
				f:BuildPlayerTable (player)
			end
			local build_player2_list = function()
				local encounterTable, guild, role = unpack (f.build_player2_data or {})
				local t = {}
				local already_listed = {}
				if (encounterTable) then
					for encounterIndex, encounter in _ipairs (encounterTable) do
						if (encounter.guild == guild) then
							local roleTable = encounter [role]
							for playerName, _ in _pairs (roleTable) do
								if (not already_listed [playerName]) then
									t[#t+1] = {value = playerName, label = playerName, icon = icon, onclick = on_player2_select}
									already_listed [playerName] = true
								end
							end
						end
					end
				end

				_table_sort (t, sort_alphabetical2)

				return t
			end
			local player2_dropdown = gump:CreateDropDown (f, build_player2_list, 1, dropdown_size, 20, "select_player2")
			local player2_string = gump:CreateLabel (f, Loc ["STRING_GUILDDAMAGERANK_PLAYERBASE_PLAYER"] .. ":", _, _, "GameFontNormal", "select_player2_label")
			player2_dropdown:SetTemplate (gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))

			local diff_labels = {"10 Normal", "25 Normal", "10 Heroic", "25 Heroic"}

			function f:UpdateDropdowns (DoNotSelectRaid)

				local currentGuild = guild_dropdown.value

				--difficulty
				wipe (diff_list)
				wipe (boss_list)
				wipe (raid_list)
				wipe (guild_list)

				local boss_repeated = {}
				local raid_repeated = {}
				local guild_repeated = {}

				local raidSelected = DetailsRaidHistoryWindow.select_raid:GetValue()

				for difficulty, encounterIdTable in _pairs (db) do
					if (type (difficulty) == "number") then
						if (diff_labels [difficulty]) then
							diff_list [#diff_list+1] = {value = difficulty, label = diff_labels [difficulty], icon = icon, onclick = on_diff_select}
						end

						for encounterId, encounterTable in _pairs (encounterIdTable) do
							if (not boss_repeated [encounterId]) then
								local encounter, instance = _detalhes:GetBossEncounterDetailsFromEncounterId (_, encounterId)
								if (encounter) then
									local InstanceID = _detalhes:GetInstanceIdFromEncounterId (encounterId)
									if (raidSelected == InstanceID) then

										boss_list[#boss_list+1] = {value = encounterId, label = encounter.boss, icon = icon, onclick = on_boss_select}
										boss_repeated [encounterId] = true
									end

									if (not raid_repeated [instance.name]) then
										raid_list[#raid_list+1] = {value = instance.id, label = instance.name, icon = icon, onclick = on_raid_select}
										raid_repeated [instance.name] = true
									end

								end
							end

							for index, encounter in _ipairs (encounterTable) do
								local guild = encounter.guild
								if (not guild_repeated [guild]) then
									guild_list[#guild_list+1] = {value = guild, label = guild, icon = icon, onclick = on_guild_select}
									guild_repeated [guild] = true
								end
							end
						end
					end
				end

				_table_sort (diff_list, function (t1, t2) return t1.value < t2.value end)
				_table_sort (boss_list, function (t1, t2) return t1.label < t2.label end)


				diff_dropdown:Refresh()
				diff_dropdown:Select (1, true)
				boss_dropdown:Refresh()
				boss_dropdown:Select (1, true)
				if (not DoNotSelectRaid) then
					raid_dropdown:Refresh()
					raid_dropdown:Select (1, true)
				end

				guild_dropdown:Refresh()
				if (currentGuild) then
					guild_dropdown:Select (currentGuild)
				else
					guild_dropdown:Select (1, true)
				end
			end

			function f.UpdateBossDropdown()

				local raidSelected = DetailsRaidHistoryWindow.select_raid:GetValue()
				local boss_repeated = {}
				wipe (boss_list)

				for difficulty, encounterIdTable in _pairs (db) do
					if (type (difficulty) == "number") then
						for encounterId, encounterTable in _pairs (encounterIdTable) do
							if (not boss_repeated [encounterId]) then
								local encounter, instance = _detalhes:GetBossEncounterDetailsFromEncounterId (_, encounterId)
								if (encounter) then
									local InstanceID = _detalhes:GetInstanceIdFromEncounterId (encounterId)
									if (raidSelected == InstanceID) then
										boss_list[#boss_list+1] = {value = encounterId, label = encounter.boss, icon = icon, onclick = on_boss_select}
										boss_repeated [encounterId] = true
									end
								end
							end
						end
					end
				end

				_table_sort (boss_list, function (t1, t2) return t1.label < t2.label end)
				boss_dropdown:Refresh()
			end

			--> anchors:
			raid_string:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -70)
			raid_dropdown:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -85)

			boss_string:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -110)
			boss_dropdown:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -125)

			diff_string:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -150)
			diff_dropdown:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -165)

			role_string:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -190)
			role_dropdown:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -205)

			guild_string:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -230)
			guild_dropdown:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -245)

			player_string:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -270)
			player_dropdown:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -285)

			player2_string:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -310)
			player2_dropdown:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -325)
			player2_string:Hide()
			player2_dropdown:Hide()

			--> refresh the window:

			function f:BuildPlayerTable (playerName)

				local encounterTable, guild, role = unpack (f.build_player2_data or {})
				local data = {}

				if (type (playerName) == "string" and string.len (playerName) > 1) then
					for encounterIndex, encounter in _ipairs (encounterTable) do

						if (encounter.guild == guild) then
							local roleTable = encounter [role]

							local date = encounter.date
							date = date:gsub (".*%s", "")
							date = date:sub (1, -4)

							local player = roleTable [playerName]

							if (player) then

								--tinsert (data, {text = date, value = player[1], data = player, fulldate = encounter.date, elapsed = encounter.elapsed})
								data[#data+1] = {text = date, value = player[1]/encounter.elapsed, utext = _detalhes:ToK2 (player[1]/encounter.elapsed), data = player, fulldate = encounter.date, elapsed = encounter.elapsed}
							end
						end
					end

					--> update graphic
					if (not f.gframe) then

						local onenter = function (self)
							GameCooltip:Reset()
							GameCooltip:SetType ("tooltip")
							GameCooltip:Preset (2)

							GameCooltip:AddLine ("Total Done:", _detalhes:ToK2 (self.data.value), 1, "white")
							GameCooltip:AddLine ("Dps:", _detalhes:ToK2 (self.data.value / self.data.elapsed), 1, "white")
							GameCooltip:AddLine ("Item Level:", floor (self.data.data [2]), 1, "white")
							GameCooltip:AddLine ("Date:", self.data.fulldate:gsub (".*%s", ""), 1, "white")

							GameCooltip:SetOwner (self.ball.tooltip_anchor)
							GameCooltip:Show()
						end
						local onleave = function (self)
							GameCooltip:Hide()
						end
						f.gframe = gump:CreateGFrame (f, 650, 400, 35, onenter, onleave, "gframe", "$parentGF")
						f.gframe:SetPoint ("TOPLEFT", f, "TOPLEFT", 190, -65)
					end

					f.gframe:Reset()
					f.gframe:UpdateLines (data)

				end
			end

			local fillpanel = gump:NewFillPanel (f, {}, "$parentFP", "fillpanel", 710, 501, false, false, true, nil)
			fillpanel:SetPoint ("TOPLEFT", f, "TOPLEFT", 195, -65)


			function f:BuildGuildRankTable (encounterTable, guild, role)

				local header = {{name = "Player Name", type = "text"}, {name = "Per Second", type = "text"}, {name = "Total", type = "text"}, {name = "Length", type = "text"}, {name = "Item Level", type = "text"}, {name = "Date", type = "text"}}

				local playerScore = {}

				--get the best of each player
				for encounterIndex, encounter in _ipairs (encounterTable) do
					if (encounter.guild == guild) then
						local roleTable = encounter [role]

						local date = encounter.date
						date = date:gsub (".*%s", "")
						date = date:sub (1, -4)

						for playerName, playerTable in _pairs (roleTable) do

							if (not playerScore [playerName]) then
								playerScore [playerName] = {
									total = 0,
									ps = 0,
									ilvl = 0,
									date = 0,
									class = 0,
									length = 0,
								}
							end

							local total = playerTable [1]
							local dps = total / encounter.elapsed

							--if (total > playerScore [playerName].total) then
							if (dps > playerScore [playerName].ps) then
								playerScore [playerName].total = total
								playerScore [playerName].ps = total / encounter.elapsed
								playerScore [playerName].ilvl = playerTable [2]
								playerScore [playerName].length = encounter.elapsed
								playerScore [playerName].date = date
								playerScore [playerName].class = playerTable [3]
							end
						end
					end
				end

				local sortTable = {}
				for playerName, t in _pairs (playerScore) do
					local className = _detalhes.classid_to_classstring[t.class or 0]
					local classColor = "FFFFFFFF"
					if (className) then
						classColor = RAID_CLASS_COLORS [className] and RAID_CLASS_COLORS [className].colorStr or "FFFFFFFF"
					end

					local playerNameFormated = _detalhes:GetOnlyName (playerName)

					sortTable[#sortTable+1] = {
						"|c" .. classColor .. playerNameFormated .. "|r",
						_detalhes:comma_value (t.ps),
						_detalhes:ToK2 (t.total),
						_detalhes.gump:IntegerToTimer (t.length),
						floor (t.ilvl),
						t.date,
						t.total,
						t.ps,
					}
				end

				_table_sort (sortTable, function(a, b) return a[8] > b[8] end)

				--> add the number before the player name
				for i = 1, #sortTable do
					local t = sortTable [i]
					t [1] = i .. ". " .. t [1]
				end

				fillpanel:SetFillFunction (function (index) return sortTable [index] end)
				fillpanel:SetTotalFunction (function() return #sortTable end)
				fillpanel:UpdateRows (header)
				fillpanel:Refresh()

				f.LatestResourceTable = sortTable
			end

			function f:BuildRaidTable (encounterTable, guild, role)

				if (f.Mode == 2) then
					f:BuildGuildRankTable (encounterTable, guild, role)
					return
				end

				local header = {{name = "Player Name", type = "text"}} -- , width = 90
				local players = {}
				local players_index = {}
				local player_class = {}
				local amt_encounters = 0

				for encounterIndex, encounter in _ipairs (encounterTable) do
					if (encounter.guild == guild) then
						local roleTable = encounter [role]

						local date = encounter.date
						date = date:gsub (".*%s", "")
						date = date:sub (1, -4)
						amt_encounters = amt_encounters + 1

						header[#header+1] = {name = date, type = "text"}

						for playerName, playerTable in _pairs (roleTable) do
							local index = players_index [playerName]
							local player

							if (not index) then
								player = {playerName}
								player_class [playerName] = playerTable [3]
								for i = 1, amt_encounters-1 do
									player[#player+1] = ""
								end
								player[#player+1] = _detalhes:ToK2 (playerTable [1] / encounter.elapsed)
								players[#players+1] = player
								players_index [playerName] = #players

								--print ("not index", playerName, amt_encounters, date, 2, amt_encounters-1)
							else
								player = players [index]
								for i = #player+1, amt_encounters-1 do
									player[#player+1] = ""
								end
								player[#player+1] = _detalhes:ToK2 (playerTable [1] / encounter.elapsed)
							end

						end
					end
				end

				--> sort alphabetical
				_table_sort (players, function(a, b) return a[1] < b[1] end)

				for index, playerTable in _ipairs (players) do
					for i = #playerTable, amt_encounters do
						playerTable[#playerTable+1] = ""
					end

					local className = _detalhes.classid_to_classstring[player_class[playerTable[1]] or 0]
					if (className) then
						local playerNameFormated = _detalhes:GetOnlyName (playerTable[1])
						local classColor = RAID_CLASS_COLORS [className] and RAID_CLASS_COLORS [className].colorStr
						playerTable [1] = "|c" .. classColor .. playerNameFormated .. "|r"
					end
				end

				fillpanel:SetFillFunction (function (index) return players [index] end)
				fillpanel:SetTotalFunction (function() return #players end)

				fillpanel:UpdateRows (header)

				fillpanel:Refresh()
				fillpanel:SetPoint ("TOPLEFT", f, "TOPLEFT", 200, -65)
			end

			function f:Refresh (player_name)
				--> build the main table
				local diff = diff_dropdown.value
				local boss = boss_dropdown.value
				local role = role_dropdown.value
				local guild = guild_dropdown.value
				local player = player_dropdown.value

				local diffTable = db [diff]

				f:SetBackgroundImage (boss)
				--_detalhes:OpenRaidHistoryWindow (_raid, _boss, _difficulty, _role, _guild, _player_base, _player_name)

				if (diffTable) then
					local encounters = diffTable [boss]
					if (encounters) then
						if (player == 1) then --> raid
							fillpanel:Show()
							if (f.gframe) then
								f.gframe:Hide()
							end
							player2_string:Hide()
							player2_dropdown:Hide()
							f:BuildRaidTable (encounters, guild, role)
						elseif (player == 2) then --> only one player
							fillpanel:Hide()
							if (f.gframe) then
								f.gframe:Show()
							end
							player2_string:Show()
							player2_dropdown:Show()
							f.build_player2_data = {encounters, guild, role}
							player2_dropdown:Refresh()

							player_name = f.latest_player_selected or player_name

							if (player_name) then
								player2_dropdown:Select (player_name)
							else
								player2_dropdown:Select (1, true)
							end

							f:BuildPlayerTable (player2_dropdown.value)
						end
					else
						if (player == 1) then --> raid
							fillpanel:Show()
							if (f.gframe) then
								f.gframe:Hide()
							end
							player2_string:Hide()
							player2_dropdown:Hide()
							f:BuildRaidTable ({}, guild, role)
						elseif (player == 2) then --> only one player
							fillpanel:Hide()
							if (f.gframe) then
								f.gframe:Show()
							end
							player2_string:Show()
							player2_dropdown:Show()
							f.build_player2_data = {{}, guild, role}
							player2_dropdown:Refresh()
							player2_dropdown:Select (1, true)
							f:BuildPlayerTable (player2_dropdown.value)
						end
					end
				end
			end

			f.FirstRun = true

		end
		local statsWindow = _G.DetailsRaidHistoryWindow
		--> table means some button send the request - nil for other ways

		if (type (_raid) == "table" or (not _raid and not _boss and not _difficulty and not _role and not _guild and not _player_base and not _player_name)) then
			local f = statsWindow
			if (f.LatestSelection) then
				_raid = f.LatestSelection.Raid
				_boss = f.LatestSelection.Boss
				_difficulty = f.LatestSelection.Diff
				_role = f.LatestSelection.Role
				_guild = f.LatestSelection.Guild
				_player_base = f.LatestSelection.PlayerBase
				_player_name = f.LatestSelection.PlayerBase
			end
		end

		if (statsWindow.FirstRun) then
			_difficulty = _detalhes.rank_window.last_difficulty or _difficulty
			if (IsInGuild()) then
				local guildName = GetGuildInfo ("player")
				if (guildName) then
					_guild = guildName
				end
			end
			if (_detalhes.rank_window.last_raid ~= "") then
				_raid = _detalhes.rank_window.last_raid or _raid
			end

			-- _G.DetailsRaidHistoryWindow.FirstRun = nil
		end

		if (not statsWindow.UpdateDropdowns) then
			_detalhes:Msg("Failed to load statistics, Details! Storage is disabled?")
			return
		end
		statsWindow:UpdateDropdowns()

		statsWindow:Refresh()
		statsWindow:Show()

		if (_history_type == 1 or _history_type == 2) then
			statsWindow.Mode = _history_type
			if (statsWindow.Mode == 1) then
				--overall
				statsWindow.HistoryCheckBox:SetValue (true)
				statsWindow.GuildRankCheckBox:SetValue (false)
			elseif (statsWindow.Mode == 2) then
				--guild rank
				statsWindow.GuildRankCheckBox:SetValue (true)
				statsWindow.HistoryCheckBox:SetValue (false)
			end
		end

		if (_raid) then
			statsWindow.select_raid:Select (_raid)
			statsWindow:Refresh()
			statsWindow.UpdateBossDropdown()
		end
		if (_boss) then
			statsWindow.select_boss:Select (_boss)
			statsWindow:Refresh()
		end
		if (_difficulty) then
			statsWindow.select_diff:Select (_difficulty)
			statsWindow:Refresh()
		end
		if (_role) then
			statsWindow.select_role:Select (_role)
			statsWindow:Refresh()
		end
		if (_guild) then
			if (type (_guild) == "boolean") then
				_guild = GetGuildInfo ("player")
			end
			statsWindow.select_guild:Select (_guild)
			statsWindow:Refresh()
		end
		if (_player_base) then
			statsWindow.select_player:Select (_player_base)
			statsWindow:Refresh()
		end
		if (_player_name) then
			statsWindow.select_player2:Refresh()
			statsWindow.select_player2:Select (_player_name)
			statsWindow:Refresh (_player_name)
		end

		DetailsPluginContainerWindow.OpenPlugin (statsWindow)
	end

--> config class colors
	function _detalhes:OpenClassColorsConfig()
		if (not _G.DetailsClassColorManager) then
			gump:CreateSimplePanel (UIParent, 300, 280, Loc ["STRING_OPTIONS_CLASSCOLOR_MODIFY"], "DetailsClassColorManager")
			local panel = _G.DetailsClassColorManager

			_detalhes.gump:ApplyStandardBackdrop (panel)

			local upper_panel = CreateFrame ("Frame", nil, panel)
			upper_panel:SetAllPoints (panel)
			upper_panel:SetFrameLevel (panel:GetFrameLevel()+3)

			local y = -50

			local callback = function (button, r, g, b, a, self)
				self.MyObject.my_texture:SetVertexColor (r, g, b)
				_detalhes.class_colors [self.MyObject.my_class][1] = r
				_detalhes.class_colors [self.MyObject.my_class][2] = g
				_detalhes.class_colors [self.MyObject.my_class][3] = b
				_detalhes:AtualizaGumpPrincipal (-1, true)
			end
			local set_color = function (self, button, class, index)
				local current_class_color = _detalhes.class_colors [class]
				local r, g, b = unpack (current_class_color)
				_detalhes.gump:ColorPick (self, r, g, b, 1, callback)
			end
		local reset_color = function (self, button, class, index)
				local color_table = RAID_CLASS_COLORS [class]
				local r, g, b = color_table.r, color_table.g, color_table.b
				self.MyObject.my_texture:SetVertexColor (r, g, b)
				_detalhes.class_colors [self.MyObject.my_class][1] = r
				_detalhes.class_colors [self.MyObject.my_class][2] = g
				_detalhes.class_colors [self.MyObject.my_class][3] = b
				_detalhes:AtualizaGumpPrincipal (-1, true)
			end
			local on_enter = function (self, capsule)
				--_detalhes:CooltipPreset (1)
				--GameCooltip:AddLine ("right click to reset")
				--GameCooltip:Show (self)
			end
			local on_leave = function (self, capsule)
			--GameCooltip:Hide()
			end

			local reset = gump:NewLabel (panel, panel, nil, nil, "|TInterface\\TUTORIALFRAME\\UI-TUTORIAL-FRAME:" .. 20 .. ":" .. 20 .. ":0:1:512:512:8:70:328:409|t " .. Loc ["STRING_OPTIONS_CLASSCOLOR_RESET"])
			reset:SetPoint ("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -23, 08)
			local reset_texture = gump:CreateImage (panel, [[Interface\MONEYFRAME\UI-MONEYFRAME-BORDER]], 138, 45, "border")
			reset_texture:SetPoint ("CENTER", reset, "CENTER", 0, -7)
			reset_texture:SetDesaturated (true)

			panel.buttons = {}

			for index, class_name in _ipairs (CLASS_SORT_ORDER) do

				local icon = gump:CreateImage (upper_panel, [[Interface\Glues\CHARACTERCREATE\UI-CHARACTERCREATE-CLASSES]], 32, 32, nil, CLASS_ICON_TCOORDS [class_name], "icon_" .. class_name)

				if (index%2 ~= 0) then
					icon:SetPoint (10, y)
				else
					icon:SetPoint (150, y)
					y = y - 33
				end

				local bg_texture = gump:CreateImage (panel, [[Interface\AddOns\Details\images\bar_skyline]], 135, 30, "artwork")
				bg_texture:SetPoint ("LEFT", icon, "RIGHT", -32, 0)

				local button = gump:CreateButton (panel, set_color, 135, 30, "set color", class_name, index)
				button:SetPoint ("LEFT", icon, "RIGHT", -32, 0)
				button:InstallCustomTexture (nil, nil, nil, nil, true)
				button:SetFrameLevel (panel:GetFrameLevel()+1)
				button.my_texture = bg_texture
				button.my_class = class_name
				button:SetHook ("OnEnter", on_enter)
				button:SetHook ("OnLeave", on_leave)
				button:SetClickFunction (reset_color, nil, nil, "RightClick")
				panel.buttons [class_name] = button

			end

		end

		for class, button in _pairs (_G.DetailsClassColorManager.buttons) do
			button.my_texture:SetVertexColor (unpack (_detalhes.class_colors [class]))
		end

		_G.DetailsClassColorManager:Show()
	end

--> config bookmarks
	function _detalhes:OpenBookmarkConfig()

		if (not _G.DetailsBookmarkManager) then
			gump:CreateSimplePanel (UIParent, 465, 460, Loc ["STRING_OPTIONS_MANAGE_BOOKMARKS"], "DetailsBookmarkManager")
			local panel = _G.DetailsBookmarkManager
			_detalhes.gump:ApplyStandardBackdrop (panel)
			panel.blocks = {}

			local clear_func = function (self, button, id)
				if (_detalhes.switch.table [id]) then
					_detalhes.switch.table [id].atributo = nil
					_detalhes.switch.table [id].sub_atributo = nil
					panel:Refresh()
					_detalhes.switch:Update()
				end
			end

			local select_attribute = function (_, _, _, attribute, sub_atribute)
				if (not sub_atribute) then
					return
				end
				_detalhes.switch.table [panel.selecting_slot].atributo = attribute
				_detalhes.switch.table [panel.selecting_slot].sub_atributo = sub_atribute
				panel:Refresh()
				_detalhes.switch:Update()
			end

			local cooltip_color = {.1, .1, .1, .3}
			local set_att = function (self, button, id)
				panel.selecting_slot = id
				GameCooltip:Reset()
				GameCooltip:SetType (3)
				GameCooltip:SetOwner (self)
				_detalhes:MontaAtributosOption (_detalhes:GetInstance(1), select_attribute)
				GameCooltip:SetColor (1, cooltip_color)
				GameCooltip:SetColor (2, cooltip_color)
				GameCooltip:SetOption ("HeightAnchorMod", -7)
				GameCooltip:SetOption ("TextSize", _detalhes.font_sizes.menus)
				GameCooltip:SetBackdrop (1, _detalhes.tooltip_backdrop, nil, _detalhes.tooltip_border_color)
				GameCooltip:SetBackdrop (2, _detalhes.tooltip_backdrop, nil, _detalhes.tooltip_border_color)

				GameCooltip:ShowCooltip()
			end

			local button_backdrop = {bgFile = [[Interface\AddOns\Details\images\background]], tile = true, tileSize = 64, insets = {left=0, right=0, top=0, bottom=0}}

			local set_onenter = function (self, capsule)
				self:SetBackdropColor (1, 1, 1, 0.9)
				capsule.icon:SetBlendMode ("ADD")
			end
			local set_onleave = function (self, capsule)
				self:SetBackdropColor (0, 0, 0, 0.5)
				capsule.icon:SetBlendMode ("BLEND")
			end

			for i = 1, 40 do
				local clear = gump:CreateButton (panel, clear_func, 16, 16, nil, i, nil, [[Interface\Glues\LOGIN\Glues-CheckBox-Check]])
				if (i%2 ~= 0) then
					--impar
					clear:SetPoint (15, (( i*10 ) * -1) - 35) --left
				else
					--par
					local o = i-1
					clear:SetPoint (250, (( o*10 ) * -1) - 35) --right
				end

				local set = gump:CreateButton (panel, set_att, 16, 16, nil, i)
				set:SetPoint ("LEFT", clear, "RIGHT")
				set:SetPoint ("RIGHT", clear, "RIGHT", 180, 0)
				set:SetBackdrop (button_backdrop)
				set:SetBackdropColor (0, 0, 0, 0.5)
				set:SetHook ("OnEnter", set_onenter)
				set:SetHook ("OnLeave", set_onleave)

				--set:InstallCustomTexture (nil, nil, nil, nil, true)
				set:SetTemplate (gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"))

				local bg_texture = gump:CreateImage (set, [[Interface\AddOns\Details\images\bar_skyline]], 135, 30, "background")
				bg_texture:SetAllPoints()
				set.bg = bg_texture

				local icon = gump:CreateImage (set, nil, 16, 16, nil, nil, "icon")
				icon:SetPoint ("LEFT", clear, "RIGHT", 4, 0)

				local label = gump:CreateLabel (set, "")
				label:SetPoint ("LEFT", icon, "RIGHT", 2, 0)

				panel.blocks[#panel.blocks+1] = {icon = icon, label = label, bg = set.bg, button = set}
			end

			local normal_coords = {0, 1, 0, 1}
			local unknown_coords = {157/512, 206/512, 39/512,  89/512}

			function panel:Refresh()
				local bookmarks = _detalhes.switch.table

				for i = 1, 40 do
					local bookmark = bookmarks [i]
					local this_block = panel.blocks [i]
					if (bookmark and bookmark.atributo and bookmark.sub_atributo) then
						if (bookmark.atributo == 5) then --> custom
							local CustomObject = _detalhes.custom [bookmark.sub_atributo]
							if (not CustomObject) then --> ele j� foi deletado
								this_block.label.text = "-- x -- x --"
								this_block.icon.texture = "Interface\\ICONS\\Ability_DualWield"
								this_block.icon.texcoord = normal_coords
								this_block.bg:SetVertexColor (.4, .1, .1, .12)
							else
								this_block.label.text = CustomObject.name
								this_block.icon.texture = CustomObject.icon
								this_block.icon.texcoord = normal_coords
								this_block.bg:SetVertexColor (.4, .4, .4, .6)
							end
						else
							bookmark.atributo = bookmark.atributo or 1
							bookmark.sub_atributo = bookmark.sub_atributo or 1
							this_block.label.text = _detalhes.sub_atributos [bookmark.atributo] and _detalhes.sub_atributos [bookmark.atributo].lista [bookmark.sub_atributo]
							this_block.icon.texture = _detalhes.sub_atributos [bookmark.atributo] and _detalhes.sub_atributos [bookmark.atributo].icones [bookmark.sub_atributo] [1]
							this_block.icon.texcoord = _detalhes.sub_atributos [bookmark.atributo] and _detalhes.sub_atributos [bookmark.atributo].icones [bookmark.sub_atributo] [2]
							this_block.bg:SetVertexColor (.4, .4, .4, .6)
						end

						this_block.button:SetAlpha (1)
					else
						this_block.label.text = "-- x -- x --"
						this_block.icon.texture = [[Interface\AddOns\Details\images\icons]]
						this_block.icon.texcoord = unknown_coords
						this_block.bg:SetVertexColor (.1, .1, .1, .12)
						this_block.button:SetAlpha (0.3)
					end
				end
			end
		end

		_G.DetailsBookmarkManager:Show()
		_G.DetailsBookmarkManager:Refresh()
	end

--> interface menu
	local f = CreateFrame ("Frame", "DetailsInterfaceOptionsPanel", UIParent)
	f.name = "Details"
	f.logo = f:CreateTexture (nil, "overlay")
	f.logo:SetPoint ("CENTER", f, "CENTER", 0, 0)
	f.logo:SetPoint ("TOP", f, "TOP", 25, 56)
	f.logo:SetTexture ([[Interface\AddOns\Details\images\logotipo]])
	f.logo:SetSize (256, 128)
	InterfaceOptions_AddCategory (f)

		--> open options panel
		f.options_button = CreateFrame ("button", nil, f, "OptionsButtonTemplate")
		f.options_button:SetText (Loc ["STRING_INTERFACE_OPENOPTIONS"])
		f.options_button:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -100)
		f.options_button:SetWidth (170)
		f.options_button:SetScript ("OnClick", function (self)
			local lower_instance = _detalhes:GetLowerInstanceNumber()
			if (not lower_instance) then
				--> no window opened?
				local instance1 = _detalhes.tabela_instancias [1]
				if (instance1) then
					instance1:Enable()
					return _detalhes:OpenOptionsWindow (instance1)
				else
					instance1 = _detalhes:CriarInstancia (_, true)
					if (instance1) then
						return _detalhes:OpenOptionsWindow (instance1)
					else
						_detalhes:Msg ("couldn't open options panel: no window available.")
					end
				end
			end
			_detalhes:OpenOptionsWindow (_detalhes:GetInstance (lower_instance))
		end)

		--> create new window
		f.new_window_button = CreateFrame ("button", nil, f, "OptionsButtonTemplate")
		f.new_window_button:SetText (Loc ["STRING_MINIMAPMENU_NEWWINDOW"])
		f.new_window_button:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -125)
		f.new_window_button:SetWidth (170)
		f.new_window_button:SetScript ("OnClick", function (self)
			_detalhes:CriarInstancia (_, true)
		end)

	function _detalhes:CreateWelcomePanel (name, parent, width, height, make_movable)

		local f = CreateFrame ("Frame", name, parent or UIParent)

		--f:SetBackdrop ({bgFile = [[Interface\AddOns\Details\images\background]], tile = true, tileSize = 128, insets = {left=3, right=3, top=3, bottom=3}, edgeFile = [[Interface\AddOns\Details\images\border_welcome]], edgeSize = 16})
		f:SetBackdrop ({bgFile = [[Interface\AddOns\Details\images\background]], tile = true, tileSize = 128, insets = {left=0, right=0, top=0, bottom=0}, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
		f:SetBackdropColor (1, 1, 1, 0.75)
		f:SetBackdropBorderColor (0, 0, 0, 1)
		f:SetSize (width or 1, height or 1)

		if (make_movable) then
			f:SetScript ("OnMouseDown", function(self, button)
				if (self.isMoving) then
					return
				end
				if (button == "RightButton") then
					self:Hide()
				else
					self:StartMoving()
					self.isMoving = true
				end
			end)
			f:SetScript ("OnMouseUp", function(self, button)
				if (self.isMoving and button == "LeftButton") then
					self:StopMovingOrSizing()
					self.isMoving = nil
				end
			end)
			f:SetToplevel (true)
			f:SetMovable (true)
		end

		return f
	end

	function _detalhes:OpenBrokerTextEditor()

		if (not DetailsWindowOptionsBrokerTextEditor) then

			local panel = _detalhes:CreateWelcomePanel ("DetailsWindowOptionsBrokerTextEditor", nil, 650, 210, true)
			panel:SetPoint ("CENTER", UIParent, "CENTER")
			panel:Hide()
			panel:SetFrameStrata ("FULLSCREEN")

			local textentry = _detalhes.gump:NewSpecialLuaEditorEntry (panel, 450, 185, "editbox", "$parentEntry", true)
			textentry:SetPoint ("TOPLEFT", panel, "TOPLEFT", 10, -12)

			textentry.editbox:SetScript ("OnTextChanged", function()
				local text = panel.editbox:GetText()
				_detalhes.data_broker_text = text
				_detalhes:BrokerTick()
				if (_G.DetailsOptionsWindow)  then
					_G.DetailsOptionsWindow19BrokerEntry.MyObject:SetText (_detalhes.data_broker_text)
				end
			end)

			local option_selected = 1
			local onclick= function (_, _, value)
				option_selected = value
			end
			local AddOptions = {
				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD1"], value = 1, onclick = onclick},
				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD2"], value = 2, onclick = onclick},
				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD3"], value = 3, onclick = onclick},
				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD4"], value = 4, onclick = onclick},

				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD5"], value = 5, onclick = onclick},
				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD6"], value = 6, onclick = onclick},
				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD7"], value = 7, onclick = onclick},
				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD8"], value = 8, onclick = onclick},

				{label = Loc ["STRING_OPTIONS_DATABROKER_TEXT_ADD9"], value = 9, onclick = onclick},
			}
			local buildAddMenu = function()
				return AddOptions
			end

			local d = _detalhes.gump:NewDropDown (panel, _, "$parentTextOptionsDropdown", "TextOptionsDropdown", 150, 20, buildAddMenu, 1)
			d:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, -14)
			--d:SetFrameStrata ("TOOLTIP")

			local optiontable = {"{dmg}", "{dps}", "{dpos}", "{ddiff}", "{heal}", "{hps}", "{hpos}", "{hdiff}", "{time}"}

			local add_button = _detalhes.gump:NewButton (panel, nil, "$parentAddButton", nil, 20, 20, function()
				textentry.editbox:Insert (optiontable [option_selected])
			end,
			nil, nil, nil, "<-")
			add_button:SetPoint ("RIGHT", d, "LEFT", -2, 0)
			add_button:InstallCustomTexture()


			-- code author Saiket from  http://www.wowinterface.com/forums/showpost.php?p=245759&postcount=6
			--- @return StartPos, EndPos of highlight in this editbox.
			local function GetTextHighlight ( self )
				local Text, Cursor = self:GetText(), self:GetCursorPosition();
				self:Insert( "" ); -- Delete selected text
				local TextNew, CursorNew = self:GetText(), self:GetCursorPosition();
				-- Restore previous text
				self:SetText( Text );
				self:SetCursorPosition( Cursor );
				local Start, End = CursorNew, #Text - ( #TextNew - CursorNew );
				self:HighlightText( Start, End );
				return Start, End;
			end

			local StripColors;
			do
				local CursorPosition, CursorDelta;
				--- Callback for gsub to remove unescaped codes.
				local function StripCodeGsub ( Escapes, Code, End )
					if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
						if ( CursorPosition and CursorPosition >= End - 1 ) then
							CursorDelta = CursorDelta - #Code;
						end
						return Escapes;
					end
				end
				--- Removes a single escape sequence.
				local function StripCode ( Pattern, Text, OldCursor )
					CursorPosition, CursorDelta = OldCursor, 0;
					return Text:gsub( Pattern, StripCodeGsub ), OldCursor and CursorPosition + CursorDelta;
				end
				--- Strips Text of all color escape sequences.
				-- @param Cursor  Optional cursor position to keep track of.
				-- @return Stripped text, and the updated cursor position if Cursor was given.
				function StripColors ( Text, Cursor )
					Text, Cursor = StripCode( "(|*)(|c%x%x%x%x%x%x%x%x)()", Text, Cursor );
					return StripCode( "(|*)(|r)()", Text, Cursor );
				end
			end

			local COLOR_END = "|r";
			--- Wraps this editbox's selected text with the given color.
			local function ColorSelection ( self, ColorCode )
				local Start, End = GetTextHighlight( self );
				local Text, Cursor = self:GetText(), self:GetCursorPosition();
				if ( Start == End ) then -- Nothing selected
					--Start, End = Cursor, Cursor; -- Wrap around cursor
					return; -- Wrapping the cursor in a color code and hitting backspace crashes the client!
				end
				-- Find active color code at the end of the selection
				local ActiveColor;
				if ( End < #Text ) then -- There is text to color after the selection
					local ActiveEnd;
					local CodeEnd, _, Escapes, Color = 0;
					while ( true ) do
						_, CodeEnd, Escapes, Color = Text:find( "(|*)(|c%x%x%x%x%x%x%x%x)", CodeEnd + 1 );
						if ( not CodeEnd or CodeEnd > End ) then
							break;
						end
						if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
							ActiveColor, ActiveEnd = Color, CodeEnd;
						end
					end

					if ( ActiveColor ) then
						-- Check if color gets terminated before selection ends
						CodeEnd = 0;
						while ( true ) do
							_, CodeEnd, Escapes = Text:find( "(|*)|r", CodeEnd + 1 );
							if ( not CodeEnd or CodeEnd > End ) then
								break;
							end
							if ( CodeEnd > ActiveEnd and #Escapes % 2 == 0 ) then -- Terminates ActiveColor
								ActiveColor = nil;
								break;
							end
						end
					end
				end

				local Selection = Text:sub( Start + 1, End );
				-- Remove color codes from the selection
				local Replacement, CursorReplacement = StripColors( Selection, Cursor - Start );

				self:SetText( ( "" ):join(
					Text:sub( 1, Start ),
					ColorCode, Replacement, COLOR_END,
					ActiveColor or "", Text:sub( End + 1 )
				) );

				-- Restore cursor and highlight, adjusting for wrapper text
				Cursor = Start + CursorReplacement;
				if ( CursorReplacement > 0 ) then -- Cursor beyond start of color code
					Cursor = Cursor + #ColorCode;
				end
				if ( CursorReplacement >= #Replacement ) then -- Cursor beyond end of color
					Cursor = Cursor + #COLOR_END;
				end

				self:SetCursorPosition( Cursor );
				-- Highlight selection and wrapper
				self:HighlightText( Start, #ColorCode + ( #Replacement - #Selection ) + #COLOR_END + End );
			end

			local color_func = function (_, r, g, b, a)
				local hex = _detalhes:hex (a*255).._detalhes:hex (r*255).._detalhes:hex (g*255).._detalhes:hex (b*255)
				ColorSelection ( textentry.editbox, "|c" .. hex)
			end

			local color_button = _detalhes.gump:NewColorPickButton (panel, "$parentButton5", nil, color_func)
			color_button:SetSize (80, 20)
			color_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, -102)
			color_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_COLOR_TOOLTIP"]

			local done = function()
				local text = panel.editbox:GetText()
				_detalhes.data_broker_text = text
				if (_G.DetailsOptionsWindow)  then
					_G.DetailsOptionsWindow19BrokerEntry.MyObject:SetText (_detalhes.data_broker_text)
				end
				_detalhes:BrokerTick()
				panel:Hide()
			end

			local ok_button = _detalhes.gump:NewButton (panel, nil, "$parentButtonOk", nil, 80, 20, done, nil, nil, nil, Loc ["STRING_OPTIONS_TEXTEDITOR_DONE"], 1)
			ok_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_DONE_TOOLTIP"]
			ok_button:InstallCustomTexture()
			ok_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, -174)

			local reset_button = _detalhes.gump:NewButton (panel, nil, "$parentDefaultOk", nil, 80, 20, function() textentry.editbox:SetText ("") end, nil, nil, nil, "Reset", 1)
			reset_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_RESET_TOOLTIP"]
			reset_button:InstallCustomTexture()
			reset_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -100, -152)

			local cancel_button = _detalhes.gump:NewButton (panel, nil, "$parentDefaultCancel", nil, 80, 20, function() textentry.editbox:SetText (panel.default_text); done(); end, nil, nil, nil, Loc ["STRING_OPTIONS_TEXTEDITOR_CANCEL"], 1)
			cancel_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_CANCEL_TOOLTIP"]
			cancel_button:InstallCustomTexture()
			cancel_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -100, -174)

		end

		local panel = DetailsWindowOptionsBrokerTextEditor

		local text = _detalhes.data_broker_text:gsub ("||", "|")
		panel.default_text = text
		panel.editbox:SetText (text)

		panel:Show()
	end

--> row text editor

	local panel = _detalhes:CreateWelcomePanel ("DetailsWindowOptionsBarTextEditor", nil, 1150, 600, true)
	panel:SetPoint ("CENTER", UIParent, "CENTER")
	panel:Hide()
	panel:SetFrameStrata ("FULLSCREEN")
	Details.gump:ApplyStandardBackdrop (panel)
	Details.gump:CreateTitleBar (panel, "Details! Custom Line Text Editor")

	function panel:Open (text, callback, host, default)
		if (host) then
			panel:ClearAndSetPoint ("CENTER", host, "CENTER")
		end

		text = text:gsub ("||", "|")
		panel.default_text = text
		panel.editbox:SetText (text)
		panel.callback = callback
		panel.default = default or ""
		panel:Show()
	end

	local y = -32
	local buttonTemplate = Details.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")

	local textentry = _detalhes.gump:NewSpecialLuaEditorEntry (panel, 950, 555, "editbox", "$parentEntry")
	textentry:SetPoint ("TOPLEFT", panel, "TOPLEFT", 10, y)
	Details.gump:ApplyStandardBackdrop (textentry)
	Details.gump:SetFontSize (textentry.editbox, 14)
	Details.gump:ReskinSlider (textentry.scroll)

	local arg1_button = _detalhes.gump:NewButton (panel, nil, "$parentButton1", nil, 80, 20, function() textentry.editbox:Insert ("{data1}") end, nil, nil, nil, _string_format (Loc ["STRING_OPTIONS_TEXTEDITOR_DATA"], "1"), 1)
	local arg2_button = _detalhes.gump:NewButton (panel, nil, "$parentButton2", nil, 80, 20, function() textentry.editbox:Insert ("{data2}") end, nil, nil, nil, _string_format (Loc ["STRING_OPTIONS_TEXTEDITOR_DATA"], "2"), 1)
	local arg3_button = _detalhes.gump:NewButton (panel, nil, "$parentButton3", nil, 80, 20, function() textentry.editbox:Insert ("{data3}") end, nil, nil, nil, _string_format (Loc ["STRING_OPTIONS_TEXTEDITOR_DATA"], "3"), 1)
	arg1_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, y)
	arg2_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, y - (20*1))
	arg3_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, y - (20*2))
	arg1_button:SetTemplate (buttonTemplate)
	arg2_button:SetTemplate (buttonTemplate)
	arg3_button:SetTemplate (buttonTemplate)

	arg1_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_DATA_TOOLTIP"]
	arg2_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_DATA_TOOLTIP"]
	arg3_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_DATA_TOOLTIP"]

	local func_button = _detalhes.gump:NewButton (panel, nil, "$parentButton4", nil, 80, 20, function() textentry.editbox:Insert ("{func local player, combat = ...; return 0;}") end, nil, nil, nil, Loc ["STRING_OPTIONS_TEXTEDITOR_FUNC"], 1)

	func_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, y - (20*3))
	func_button:SetTemplate (buttonTemplate)

	func_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_FUNC_TOOLTIP"]
	local done = function()
		local text = panel.editbox:GetText()
		panel.callback (text)
		panel:Hide()
	end

	local ok_button = _detalhes.gump:NewButton (panel, nil, "$parentButtonOk", nil, 80, 20, done, nil, nil, nil, Loc ["STRING_OPTIONS_TEXTEDITOR_DONE"], 1)
	ok_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_DONE_TOOLTIP"]
	ok_button:SetTemplate (buttonTemplate)
	ok_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -12, -194)

	local reset_button = _detalhes.gump:NewButton (panel, nil, "$parentDefaultOk", nil, 80, 20, function() textentry.editbox:SetText (panel.default) end, nil, nil, nil, Loc ["STRING_OPTIONS_TEXTEDITOR_RESET"], 1)
	reset_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_RESET_TOOLTIP"]
	reset_button:SetTemplate (buttonTemplate)
	reset_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -100, -172)

	local cancel_button = _detalhes.gump:NewButton (panel, nil, "$parentDefaultCancel", nil, 80, 20, function() textentry.editbox:SetText (panel.default_text); done(); end, nil, nil, nil, Loc ["STRING_OPTIONS_TEXTEDITOR_CANCEL"], 1)
	cancel_button.tooltip = Loc ["STRING_OPTIONS_TEXTEDITOR_CANCEL_TOOLTIP"]
	cancel_button:SetTemplate (buttonTemplate)
	cancel_button:SetPoint ("TOPRIGHT", panel, "TOPRIGHT", -100, -194)

	function _detalhes:OpenProfiler()

		--> isn't first run, so just quit
		if (not _detalhes.character_first_run) then
			return
		elseif (_detalhes.is_first_run) then
			return
		elseif (_detalhes.always_use_profile) then -- and type (_detalhes.always_use_profile) == "string"
			return
		else
			--> check is this is the first run of the addon (after being installed)
			local amount = 0
			for name, profile in _pairs (_detalhes_global.__profiles) do
				amount = amount + 1
			end
			if (amount == 1) then
				return
			end
		end

		local f = _detalhes:CreateWelcomePanel (nil, nil, 250, 300, true)
		f:SetPoint ("RIGHT", UIParent, "RIGHT", -5, 0)

		local logo = f:CreateTexture (nil, "artwork")
		logo:SetTexture ([[Interface\AddOns\Details\images\logotipo]])
		logo:SetSize (256*0.8, 128*0.8)
		logo:SetPoint ("CENTER", f, "CENTER", 0, 0)
		logo:SetPoint ("TOP", f, "TOP", 20, 20)

		local string_profiler = f:CreateFontString (nil, "artwork", "GameFontNormal")
		string_profiler:SetPoint ("TOP", logo, "BOTTOM", -20, 10)
		string_profiler:SetText ("Profiler!")

		local string_profiler = f:CreateFontString (nil, "artwork", "GameFontNormal")
		string_profiler:SetPoint ("TOPLEFT", f, "TOPLEFT", 10, -130)
		string_profiler:SetText (Loc ["STRING_OPTIONS_PROFILE_SELECTEXISTING"])
		string_profiler:SetWidth (230)
		_detalhes:SetFontSize (string_profiler, 11)
		_detalhes:SetFontColor (string_profiler, "white")

		--> get the new profile name
		local current_profile = _detalhes:GetCurrentProfileName()

		local on_select_profile = function (_, _, profilename)
			if (profilename ~= _detalhes:GetCurrentProfileName()) then
				_detalhes:ApplyProfile (profilename)
				if (_G.DetailsOptionsWindow and _G.DetailsOptionsWindow:IsShown()) then
					_detalhes:OpenOptionsWindow (_G.DetailsOptionsWindow.instance)
				end
			end
		end

		local texcoord = {5/32, 30/32, 4/32, 28/32}

		local fill_dropdown = function()
			local t = {
				{value = current_profile, label = Loc ["STRING_OPTIONS_PROFILE_USENEW"], onclick = on_select_profile, icon = [[Interface\AddOns\Details\textures\FriendsFrame\UI-Toast-FriendRequestIcon]], texcoord = {4/32, 30/32, 4/32, 28/32}, iconcolor = "orange"}
			}
			for _, profilename in _ipairs (_detalhes:GetProfileList()) do
				if (profilename ~= current_profile) then
					t[#t+1] = {value = profilename, label = profilename, onclick = on_select_profile, icon = [[Interface\AddOns\Details\textures\FriendsFrame\UI-Toast-FriendOnlineIcon]], texcoord = texcoord, iconcolor = "yellow"}
				end
			end
			return t
		end

		local dropdown = _detalhes.gump:NewDropDown (f, f, "DetailsProfilerProfileSelectorDropdown", "dropdown", 220, 20, fill_dropdown, 1)
		dropdown:SetPoint (15, -190)

		local confirm_func = function()
			if (current_profile ~= _detalhes:GetCurrentProfileName()) then
				_detalhes:EraseProfile (current_profile)
			end
			f:Hide()
		end
		local confirm = _detalhes.gump:NewButton (f, f, "DetailsProfilerProfileConfirmButton", "button", 150, 20, confirm_func, nil, nil, nil, "okey!")
		confirm:SetPoint (50, -250)
		confirm:InstallCustomTexture()

	end

	--> minimap icon
	function _detalhes:RegisterMinimap()

		local LDB = LibStub ("LibDataBroker-1.1", true)
		local LDBIcon = LDB and LibStub ("LibDBIcon-1.0", true)

		if LDB then

			local databroker = LDB:NewDataObject ("Details", {
				type = "data source",
				icon = [[Interface\AddOns\Details\images\minimap]],
				text = "0",

				OnClick = function (self, button)

					if (button == "LeftButton") then
						if (IsControlKeyDown()) then
							_detalhes:ToggleWindows()
							return
						end
						--> 1 = open options panel
						if (_detalhes.minimap.onclick_what_todo == 1) then
							local lower_instance = _detalhes:GetLowerInstanceNumber()
							if (not lower_instance) then
								local instance = _detalhes:GetInstance (1)
								_detalhes.CriarInstancia (_, _, 1)
								_detalhes:OpenOptionsWindow (instance)
							else
								_detalhes:OpenOptionsWindow (_detalhes:GetInstance (lower_instance))
							end

						--> 2 = reset data
						elseif (_detalhes.minimap.onclick_what_todo == 2) then
							_detalhes.tabela_historico:resetar()

						--> 3 = show hide windows
						elseif (_detalhes.minimap.onclick_what_todo == 3) then
							local opened = _detalhes:GetOpenedWindowsAmount()

							if (opened == 0) then
								_detalhes:ReabrirTodasInstancias()
							else
								_detalhes:ShutDownAllInstances()
							end
						end

					elseif (button == "RightButton") then

						GameTooltip:Hide()
						local GameCooltip = GameCooltip

						GameCooltip:Reset()
						GameCooltip:SetType ("menu")
						GameCooltip:SetOption ("ButtonsYMod", -5)
						GameCooltip:SetOption ("HeighMod", 5)
						GameCooltip:SetOption ("TextSize", 10)

						--344 427 200 268 0.0009765625
						--0.672851, 0.833007, 0.391601, 0.522460

						--GameCooltip:SetBannerImage (1, [[Interface\AddOns\Details\images\icons]], 83*.5, 68*.5, {"bottomleft", "topleft", 1, -4}, {0.672851, 0.833007, 0.391601, 0.522460}, nil)
						--GameCooltip:SetBannerImage (2, "Interface\\PetBattles\\Weather-Windy", 512*.35, 128*.3, {"bottomleft", "topleft", -25, -4}, {0, 1, 1, 0})
						--GameCooltip:SetBannerText (1, "Mini Map Menu", {"left", "right", 2, -5}, "white", 10)

						--> reset
						GameCooltip:AddMenu (1, _detalhes.tabela_historico.resetar, true, nil, nil, Loc ["STRING_ERASE_DATA"], nil, true)
						GameCooltip:AddIcon ([[Interface\COMMON\VOICECHAT-MUTED]], 1, 1, 14, 14)

						GameCooltip:AddLine ("$div")

						--> nova instancia
						GameCooltip:AddMenu (1, function() _detalhes:CriarInstancia (nil, true) end, true, nil, nil, Loc ["STRING_MINIMAPMENU_NEWWINDOW"], nil, true)
						--GameCooltip:AddIcon ([[Interface\Buttons\UI-AttributeButton-Encourage-Up]], 1, 1, 10, 10, 4/16, 12/16, 4/16, 12/16)
						GameCooltip:AddIcon ([[Interface\AddOns\Details\images\icons]], 1, 1, 12, 11, 462/512, 473/512, 1/512, 11/512)

						--> reopen all windows
						GameCooltip:AddMenu (1, _detalhes.ReabrirTodasInstancias, true, nil, nil, Loc ["STRING_MINIMAPMENU_REOPENALL"], nil, true)
						GameCooltip:AddIcon ([[Interface\Buttons\UI-MicroStream-Green]], 1, 1, 14, 14, 0.1875, 0.8125, 0.84375, 0.15625)
						--> close all windows
						GameCooltip:AddMenu (1, _detalhes.ShutDownAllInstances, true, nil, nil, Loc ["STRING_MINIMAPMENU_CLOSEALL"], nil, true)
						GameCooltip:AddIcon ([[Interface\Buttons\UI-MicroStream-Red]], 1, 1, 14, 14, 0.1875, 0.8125, 0.15625, 0.84375)

						GameCooltip:AddLine ("$div")

						--> lock
						GameCooltip:AddMenu (1, _detalhes.TravasInstancias, true, nil, nil, Loc ["STRING_MINIMAPMENU_LOCK"], nil, true)
						GameCooltip:AddIcon ([[Interface\PetBattles\PetBattle-LockIcon]], 1, 1, 14, 14, 0.0703125, 0.9453125, 0.0546875, 0.9453125)

						GameCooltip:AddMenu (1, _detalhes.DestravarInstancias, true, nil, nil, Loc ["STRING_MINIMAPMENU_UNLOCK"], nil, true)
						GameCooltip:AddIcon ([[Interface\PetBattles\PetBattle-LockIcon]], 1, 1, 14, 14, 0.0703125, 0.9453125, 0.0546875, 0.9453125, "gray")

						GameCooltip:AddLine ("$div")

						--> disable minimap icon
						local disable_minimap = function()
							_detalhes.minimap.hide = true

							LDBIcon:Refresh ("Details", _detalhes.minimap)
							if (_detalhes.minimap.hide) then
								LDBIcon:Hide ("Details")
							else
								LDBIcon:Show ("Details")
							end
						end
						GameCooltip:AddMenu (1, disable_minimap, true, nil, nil, Loc ["STRING_MINIMAPMENU_HIDEICON"], nil, true)
						GameCooltip:AddIcon ([[Interface\Buttons\UI-Panel-HideButton-Disabled]], 1, 1, 14, 14, 7/32, 24/32, 8/32, 24/32, "gray")

						--

						GameCooltip:SetBackdrop (1, _detalhes.tooltip_backdrop, nil, _detalhes.tooltip_border_color)
						GameCooltip:SetWallpaper (1, [[Interface\SPELLBOOK\Spellbook-Page-1]], {.6, 0.1, 0.64453125, 0}, {.8, .8, .8, 0.2}, true)

						GameCooltip:SetOwner (self, "topright", "bottomleft")
						GameCooltip:ShowCooltip()


					end
				end,
				OnTooltipShow = function (tooltip)
					tooltip:AddLine ("Details!", 1, 1, 1)
					if (_detalhes.minimap.onclick_what_todo == 1) then
						tooltip:AddLine (Loc ["STRING_MINIMAP_TOOLTIP1"])
					elseif (_detalhes.minimap.onclick_what_todo == 2) then
						tooltip:AddLine (Loc ["STRING_MINIMAP_TOOLTIP11"])
					elseif (_detalhes.minimap.onclick_what_todo == 3) then
						tooltip:AddLine (Loc ["STRING_MINIMAP_TOOLTIP12"])
					end
					tooltip:AddLine (Loc ["STRING_MINIMAP_TOOLTIP2"])
					tooltip:AddLine ("|cFFCFCFCFctrl + left click|r: show/hide windows")
				end,
			})

			if (databroker and not LDBIcon:IsRegistered ("Details")) then
				LDBIcon:Register ("Details", databroker, self.minimap)
			end

			_detalhes.databroker = databroker

		end
	end

	function _detalhes:TestBarsUpdate()
		local current_combat = _detalhes:GetCombat ("current")
		for index, actor in current_combat[1]:ListActors() do
			actor.total = actor.total + (actor.total / 100 * math.random (1, 10))
			actor.total = actor.total - (actor.total / 100 * math.random (1, 10))
		end
		for index, actor in current_combat[2]:ListActors() do
			actor.total = actor.total + (actor.total / 100 * math.random (1, 10))
			actor.total = actor.total - (actor.total / 100 * math.random (1, 10))
		end
		current_combat[1].need_refresh = true
		current_combat[2].need_refresh = true
	end

	function _detalhes:StartTestBarUpdate()
		if (_detalhes.test_bar_update) then
			_detalhes:CancelTimer (_detalhes.test_bar_update)
		end
		_detalhes.test_bar_update = _detalhes:ScheduleRepeatingTimer ("TestBarsUpdate", 0.1)
	end
	function _detalhes:StopTestBarUpdate()
		if (_detalhes.test_bar_update) then
			_detalhes:CancelTimer (_detalhes.test_bar_update)
		end
		_detalhes.test_bar_update = nil
	end

	function _detalhes:CreateTestBars (alphabet)
		local current_combat = _detalhes:GetCombat ("current")
		local _, pclass = UnitClass ("player")

		local actors_name = {
				{"Ragnaros", "MAGE", 63},
				{"The Lich King", "DEATHKNIGHT", },
				{"Your Neighbor", "SHAMAN", },
				-- {"Your Raid Leader", "MONK", },
				{"Huffer", "HUNTER", },
				{"Your Internet Girlfriend", "SHAMAN", },
				{"Mr. President", "WARRIOR", },
				{"Antonidas", "MAGE"},
				{"Your Math Teacher", "SHAMAN", },
				{"King Djoffrey", "PALADIN", },
				{UnitName ("player") .. " Snow", pclass, },
				-- {"A Drunk Dawrf", "MONK", },
				-- {"Low Dps Guy", "MONK", },
				{"Helvis Phresley", "DEATHKNIGHT", },
				{"Stormwind Guard", "WARRIOR", },
				{"A PvP Player", "ROGUE", 260},
				{"Bolvar Fordragon", "PALADIN", },
				{"Malygos", "MAGE", },
				{"Akama", "ROGUE", },
				{"Nozdormu", "MAGE", },
				{"Lady Blaumeux", "DEATHKNIGHT", },
				{"Cairne Bloodhoof", "WARRIOR", },
				{"Borivar", "ROGUE", 260},
				{"C'Thun", "WARLOCK", },
				{"Drek'Thar", "DEATHKNIGHT", },
				{"Durotan", "WARRIOR", },
				{"Eonar", "DRUID", },
				{"Malfurion Stormrage", "DRUID", },
				{"Footman Malakai", "WARRIOR", },
				{"Bolvar Fordragon", "PALADIN", },
				{"Fritz Fizzlesprocket", "HUNTER", },
				{"Lisa Gallywix", "ROGUE", },
				{"M'uru", "WARLOCK", },
				{"Priestess MacDonnell", "PRIEST", },
				{"Elune", "PRIEST", },
				{"Nazgrel", "WARRIOR", },
				{"Ner'zhul", "WARLOCK", },
				{"Saria Nightwatcher", "PALADIN", },
				{"Kael'thas Sunstrider", "MAGE", 63},
				{"Velen", "PRIEST"},
				{"Tyrande Whisperwind", "PRIEST", 257},
				{"Sargeras", "WARLOCK", 267},
				{"Arthas", "PALADIN", },
				{"Orman of Stromgarde", "WARRIOR", },
				{"General Rajaxx", "WARRIOR", },
				{"Baron Rivendare", "DEATHKNIGHT", },
				{"Roland", "MAGE", },
				{"Archmage Trelane", "MAGE", },
				{"Lilian Voss", "ROGUE", },
			}

		local russian_actors_name = { --arial narrow
			{"Экспортировать", "MAGE", 63},
			{"Готово", "DEATHKNIGHT", },
			{"Создать", "SHAMAN", },
			-- {"Текущий", "MONK", },
			{"список команд", "HUNTER", },
			{"центр", "SHAMAN", },
			{"Разное", "WARRIOR", },
		}

		local tw_actor_name = { --GBK
			{"造成傷害目標", "ROGUE", },
			{"怒氣生�", "DEATHKNIGHT", },
			{"承受治療", "WARLOCK", },
			{"格檔", "PRIEST", },
			{"中央", "MAGE", },
			{"傷害", "SHAMAN", },
			-- {"建立", "MONK", },
			{"編輯", "WARRIOR", },
			{"儲存變更", "ROGUE", },
			{"刪除", "DEATHKNIGHT", },
			{"從", "WARLOCK", },
			{"吸收", "PRIEST", },
			{"加到書籤", "MAGE", },
			{"最大化", "SHAMAN", },
			-- {"未命中", "MONK", },
			{"�進階", "WARRIOR", },
		}

		local cn_actor_name = { --GBK
			{"打断", "PRIEST"},
			{"恢复", "PRIEST", 257},
			{"自动射击", "WARLOCK", 267},
			{"平均", "PALADIN", },
			{"团队", "WARRIOR", },
			{"当前", "WARRIOR", },
			{"完毕", "DEATHKNIGHT", },
			{"存储变更", "MAGE", },
			{"闪避", "MAGE", },
			{"空的片段", "ROGUE", },
			{"删除", "ROGUE", },
			{"治疗暴击", "ROGUE", },
		}

		local korean_actor_name = { --2002
			{"적이 받은 피해", "ROGUE", },
			{"초과 치유", "DEATHKNIGHT", },
			{"자동 사격", "WARLOCK", },
			{"시전", "PRIEST", },
			{"현재", "MAGE", },
			{"취소", "SHAMAN", },
			{"내보내기", "MONK", },
			{"(사용자 설정)", "WARRIOR", },
			{"방어", "ROGUE", },
			{"예제", "DEATHKNIGHT", },
			{"특화", "WARLOCK", },
			{"최소", "PRIEST", },
			{"미러 이미지", "MAGE", },
			{"가장자리", "SHAMAN", },
			-- {"외형", "MONK", },
			{"아바타 선택", "WARRIOR", },
		}

		if (not alphabet or alphabet == "en") then
			actors_name = actors_name

		elseif (alphabet == "ru") then
			actors_name = russian_actors_name

		elseif (alphabet == "cn") then
			actors_name = cn_actor_name

		elseif (alphabet == "ko") then
			actors_name = korean_actor_name

		elseif (alphabet == "tw") then
			actors_name = tw_actor_name

		end


		local total_damage = 0
		local total_heal = 0

		local class_specs = {
			DEATHKNIGHT = {250, 251, 252}, DRUID = {102, 103, 104, 105}, HUNTER = {253, 254, 255}, MAGE = {62, 63, 64}, PALADIN = {65, 66, 70},
			PRIEST = {256, 257, 258}, ROGUE = {259, 260, 261}, SHAMAN = {262, 263, 264}, WARLOCK = {265, 266, 267}, WARRIOR = {71, 72, 73},
		}
		local random_spec = function (who)
			local specs = class_specs [who[2]]
			return who[3] or (specs and specs [math.random (1, #specs)])
		end

		for i = 1, 10 do

			local who = actors_name [math.random (1, #actors_name)]

			local robot = current_combat[1]:PegarCombatente ("0x0000-0000-0000", who[1], 0x114, true)
			robot.grupo = true

			robot.classe = who [2]

			robot.spec = random_spec (who)

			robot.total = math.random (10000000, 60000000)
			robot.damage_taken = math.random (10000000, 60000000)
			robot.friendlyfire_total = math.random (10000000, 60000000)

			total_damage = total_damage + robot.total

			if (robot.nome == "King Djoffrey") then
				local robot_death = current_combat[4]:PegarCombatente ("0x0000-0000-0000", robot.nome, 0x114, true)
				robot_death.grupo = true
				robot_death.classe = robot.classe
				local esta_morte = {{true, 96648, 100000, time(), 0, "Lady Holenna"}, {true, 96648, 100000, time()-52, 100000, "Lady Holenna"}, {true, 96648, 100000, time()-86, 200000, "Lady Holenna"}, {true, 96648, 100000, time()-101, 300000, "Lady Holenna"}, {false, 55296, 400000, time()-54, 400000, "King Djoffrey"}, {true, 14185, 0, time()-59, 400000, "Lady Holenna"}, {false, 87351, 400000, time()-154, 400000, "King Djoffrey"}, {false, 56236, 400000, time()-158, 400000, "King Djoffrey"} }
				local t = {esta_morte, time(), robot.nome, robot.classe, 400000, "52m 12s",  ["dead"] = true}
				current_combat.last_events_tables[#current_combat.last_events_tables+1] = t

			elseif (robot.nome == "Mr. President") then
				rawset (_detalhes.spellcache, 56488, {"Nuke", 56488, [[Interface\ICONS\inv_gizmo_supersappercharge]]})
				robot.spells:PegaHabilidade (56488, true, "SPELL_DAMAGE")
				robot.spells._ActorTable [56488].total = robot.total
			end

			local who = actors_name [math.random (1, #actors_name)]
			local robot = current_combat[2]:PegarCombatente ("0x0000-0000-0000", who[1], 0x114, true)
			robot.grupo = true
			robot.classe = who[2]

			robot.spec = random_spec (who)

			robot.total = math.random (10000000, 60000000)
			robot.totalover = math.random (10000000, 60000000)
			robot.totalabsorb = math.random (10000000, 60000000)
			robot.healing_taken = math.random (10000000, 60000000)

			total_heal = total_heal + robot.total

		end

		--current_combat.start_time = time()-360
		current_combat.start_time = GetTime() - 360
		--current_combat.end_time = time()
		current_combat.end_time = GetTime()

		current_combat.totals_grupo [1] = total_damage
		current_combat.totals_grupo [2] = total_heal
		current_combat.totals [1] = total_damage
		current_combat.totals [2] = total_heal

		for _, instance in _ipairs (_detalhes.tabela_instancias) do
			if (instance:IsEnabled()) then
				instance:InstanceReset()
			end
		end

		current_combat.enemy = "Illidan Stormrage"

	end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~macros

	function _detalhes:InitializeMacrosWindow()
		local DetailsMacrosPanel = gump:CreateSimplePanel (UIParent, 700, 480, "Details! Useful Macros", "DetailsMacrosPanel")
		DetailsMacrosPanel.Frame = DetailsMacrosPanel
		DetailsMacrosPanel.__name = Loc["Macros"]
		DetailsMacrosPanel.real_name = "DETAILS_MACROSWINDOW"
		DetailsMacrosPanel.__icon = [[Interface\MacroFrame\MacroFrame-Icon]]
		DetailsMacrosPanel.__iconcoords = {0, 1, 0, 1}
		DetailsMacrosPanel.__iconcolor = "white"
		DetailsPluginContainerWindow.EmbedPlugin (DetailsMacrosPanel, DetailsMacrosPanel, true)

		function DetailsMacrosPanel.RefreshWindow()
			_detalhes.OpenMacrosWindow()
		end

		DetailsMacrosPanel:Hide()
	end

	function _detalhes.OpenMacrosWindow()

		if (not DetailsMacrosPanel or not DetailsMacrosPanel.Initialized) then
			local DF = DetailsFramework

			DetailsMacrosPanel.Initialized = true
			local f = DetailsMacrosPanel or gump:CreateSimplePanel (UIParent, 700, 480, "Details! Useful Macros", "DetailsMacrosPanel")

			local scrollbox_line_backdrop_color = {0, 0, 0, 0.2}
			local scrollbox_line_backdrop_color_onenter = {.3, .3, .3, 0.5}
			local scrollbox_lines = 7
			local scrollbox_line_height = 79.5
			local scrollbox_size = {890, 563}

			f:SetFrameStrata ("HIGH")
			_detalhes:FormatBackground (f, 0.8, .7)

			local macrosAvailable = _detalhes.MacroList

			local OnEnterMacroButton = function (self)
				self:SetBackdropColor (unpack (scrollbox_line_backdrop_color_onenter))
			end

			local onLeaveMacroButton = function (self)
				self:SetBackdropColor (unpack (scrollbox_line_backdrop_color))
			end

			local updateMacroLine = function (self, index, title, desc, macroText)
				self.Title:SetText (title)
				self.Desc:SetText (desc)
				self.MacroTextEntry:SetText (macroText)
			end

			local textEntryOnFocusGained = function (self)
				self:HighlightText()
			end

			local textEntryOnFocusLost = function (self)
				self:HighlightText (0, 0)
			end

			local refreshMacroScrollbox = function (self, data, offset, totalLines)
				for i = 1, totalLines do
					local index = i + offset
					local macro = macrosAvailable [index]
					if (macro) then
						local line = self:GetLine (i)
						line:UpdateLine (index, macro.Name, macro.Desc, macro.MacroText)
					end
				end
			end

			local macroListCreateLine = function (self, index)
				--create a new line
				local line = CreateFrame ("button", "$parentLine" .. index, self)

				--set its parameters
				line:SetPoint ("TOPLEFT", self, "TOPLEFT", 0, -((index-1) * (scrollbox_line_height+1)))
				line:SetSize (scrollbox_size[1], scrollbox_line_height)
				line:SetScript ("OnEnter", OnEnterMacroButton)
				line:SetScript ("OnLeave", onLeaveMacroButton)
				line:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
				line:SetBackdropColor (unpack (scrollbox_line_backdrop_color))
				line:SetBackdropBorderColor (0, 0, 0, 0.3)

				local titleLabel = DF:CreateLabel (line, "", DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
				titleLabel.textsize = 14
				titleLabel.textcolor = "yellow"
				local descLabel = DF:CreateLabel (line, "", DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
				descLabel.textsize = 12

				local options_dropdown_template = DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
				options_dropdown_template = DF.table.copy ({}, options_dropdown_template)
				options_dropdown_template.backdropcolor = {.51, .51, .51, .3}
				options_dropdown_template.onenterbordercolor = {.51, .51, .51, .2}

				local textEntry = DF:CreateTextEntry (line, function()end, scrollbox_size[1] - 10, 40, "MacroTextEntry", _, _, options_dropdown_template)
				textEntry:SetHook ("OnEditFocusGained", textEntryOnFocusGained)
				textEntry:SetHook ("OnEditFocusLost", textEntryOnFocusLost)
				textEntry:SetJustifyH ("LEFT")
				textEntry:SetTextInsets (8, 8, 0, 0)

				titleLabel:SetPoint ("TOPLEFT", line, "TOPLEFT", 5, -5)
				descLabel:SetPoint ("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, -2)
				textEntry:SetPoint ("TOPLEFT", descLabel, "BOTTOMLEFT", 0, -4)

				line.Title = titleLabel
				line.Desc = descLabel
				line.MacroTextEntry = textEntry

				line.UpdateLine = updateMacroLine
				line:Hide()

				return line
			end

			local macroScrollbox = DF:CreateScrollBox (f, "$parentMacroScrollbox", refreshMacroScrollbox, macrosAvailable, scrollbox_size[1], scrollbox_size[2], scrollbox_lines, scrollbox_line_height)
			macroScrollbox:SetPoint ("TOPLEFT", f, "TOPLEFT", 5, -30)
			macroScrollbox:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
			macroScrollbox:SetBackdropColor (0, 0, 0, 0)
			macroScrollbox:SetBackdropBorderColor (0, 0, 0, 1)
			f.MacroScrollbox = macroScrollbox
			DF:ReskinSlider (macroScrollbox)

			macroScrollbox.__background:Hide()

			--create the scrollbox lines
			for i = 1, scrollbox_lines do
				macroScrollbox:CreateLine (macroListCreateLine)
			end
		end

		DetailsPluginContainerWindow.OpenPlugin (DetailsMacrosPanel)
		DetailsMacrosPanel.MacroScrollbox:Refresh()
		DetailsMacrosPanel:Show()
	end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~run ~runcode

	function _detalhes:InitializeRunCodeWindow()
		local DetailsRunCodePanel = gump:CreateSimplePanel (UIParent, 700, 480, "Details! Run Code", "DetailsRunCodePanel")
		DetailsRunCodePanel.Frame = DetailsRunCodePanel
		DetailsRunCodePanel.__name = "Auto Run Code"
		DetailsRunCodePanel.real_name = "DETAILS_RUNCODEWINDOW"
		--DetailsRunCodePanel.__icon = [[Interface\AddOns\Details\images\lua_logo]]
		DetailsRunCodePanel.__icon = [[Interface\AddOns\Details\images\run_code]]
		--DetailsRunCodePanel.__iconcoords = {0, 1, 0, 1}
		DetailsRunCodePanel.__iconcoords = {0, 30/32, 0, 25/32}
		DetailsRunCodePanel.__iconcoords = {0, 1, 0, 1}
		DetailsRunCodePanel.__iconcolor = "white"
		DetailsPluginContainerWindow.EmbedPlugin (DetailsRunCodePanel, DetailsRunCodePanel, true)

		function DetailsRunCodePanel.RefreshWindow()
			_detalhes.OpenRunCodeWindow()
		end

		DetailsRunCodePanel:Hide()
	end

	function _detalhes.OpenRunCodeWindow()
		if (not DetailsRunCodePanel or not DetailsRunCodePanel.Initialized) then

			DetailsRunCodePanel.Initialized = true

			local f = DetailsRunCodePanel or gump:CreateSimplePanel (UIParent, 700, 480, "Details! Run Code", "DetailsRunCodePanel")
			f:SetFrameStrata ("HIGH")

			--> lua editor
			local code_editor = gump:NewSpecialLuaEditorEntry (f, 885, 510, "text", "$parentCodeEditorWindow")
			f.CodeEditor = code_editor
			code_editor:SetPoint ("TOPLEFT", f, "TOPLEFT", 20, -56)

				reskin_code_editor (code_editor)

				--> code compile error warning
				local errortext_frame = CreateFrame ("Frame", nil, code_editor)
				errortext_frame:SetPoint ("BOTTOMLEFT", code_editor, "BOTTOMLEFT", 1, 1)
				errortext_frame:SetPoint ("BOTTOMRIGHT", code_editor, "BOTTOMRIGHT", -1, 1)
				errortext_frame:SetHeight (20)
				errortext_frame:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
				errortext_frame:SetBackdropBorderColor (0, 0, 0, 1)
				errortext_frame:SetBackdropColor (0, 0, 0)

				gump:CreateFlashAnimation (errortext_frame)

				local errortext_label = gump:CreateLabel (errortext_frame, "", gump:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
				errortext_label.textcolor = "red"
				errortext_label:SetPoint ("LEFT", errortext_frame, "LEFT", 3, 0)
				code_editor.NextCodeCheck = 0.33

				code_editor:HookScript ("OnUpdate", function (self, deltaTime)
					code_editor.NextCodeCheck = code_editor.NextCodeCheck - deltaTime

					if (code_editor.NextCodeCheck < 0) then
						local script = code_editor:GetText()
						local func, errortext = loadstring (script, "Q")
						if (not func) then
							local firstLine = strsplit ("\n", script, 2)
							errortext = errortext:gsub ((firstLine:gsub ("%p", "%%%0")), "")
							errortext = errortext:gsub ("%[string \"", "")
							errortext = errortext:gsub ("...\"]:", "")
							errortext = errortext:gsub ("Q\"]:", "")
							errortext = "Line " .. errortext
							errortext_label.text = errortext
						else
							errortext_label.text = ""
						end

						code_editor.NextCodeCheck = 0.33
					end
				end)

			--> script selector
			local on_select_CodeType_option = function (self, fixedParameter, value)
				--> set the current editing code type
				f.EditingCodeKey = _detalhes.RunCodeTypes [value].ProfileKey

				--> load the code for the event
				local code = _detalhes.run_code [f.EditingCodeKey]
				code_editor:SetText (code)
			end

			local build_CodeType_dropdown_options = function()
				local t = {}

				for i = 1, #_detalhes.RunCodeTypes do
					local option = _detalhes.RunCodeTypes [i]
					t [#t + 1] = {label = option.Name, value = option.Value, onclick = on_select_CodeType_option, desc = option.Desc}
				end

				return t
			end

			local code_type_label = gump:CreateLabel (f, "Event:", gump:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
			local code_type_dropdown = gump:CreateDropDown (f, build_CodeType_dropdown_options, 1, 160, 20, "CodeTypeDropdown", _, gump:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
			code_type_dropdown:SetPoint ("LEFT", code_type_label, "RIGHT", 2, 0)
			code_type_dropdown:SetFrameLevel (code_editor:GetFrameLevel() + 10)
			code_type_label:SetPoint ("BOTTOMLEFT", code_editor, "TOPLEFT", 0, 8)

			--> create save button
			local save_script = function()
				local code = code_editor:GetText()
				local func, errortext = loadstring (code, "Q")

				if (func) then
					_detalhes.run_code [f.EditingCodeKey] = code
					_detalhes:RecompileAutoRunCode()
					_detalhes:Msg ("Code saved!")
					code_editor:ClearFocus()
				else
					errortext_frame:Flash (0.2, 0.2, 0.4, true, nil, nil, "NONE")
					_detalhes:Msg ("Can't save the code: it has errors.")
				end
			end

			local button_y = -6

			local save_script_button = gump:CreateButton (f, save_script, 120, 20, "Save", -1, nil, nil, nil, nil, nil, gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"), gump:GetTemplate ("font", "PLATER_BUTTON"))
			save_script_button:SetIcon ([[Interface\BUTTONS\UI-Panel-ExpandButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
			save_script_button:SetPoint ("TOPRIGHT", code_editor, "BOTTOMRIGHT", 0, button_y)

			--> create cancel button
			local cancel_script = function()
				code_editor:SetText (_detalhes.run_code [f.EditingCodeKey])
				_detalhes:Msg ("Code cancelled!")
				code_editor:ClearFocus()
			end

			local cancel_script_button = gump:CreateButton (f, cancel_script, 120, 20, "Cancel", -1, nil, nil, nil, nil, nil, gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"), gump:GetTemplate ("font", "PLATER_BUTTON"))
			cancel_script_button:SetIcon ([[Interface\BUTTONS\UI-Panel-MinimizeButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
			cancel_script_button:SetPoint ("TOPLEFT", code_editor, "BOTTOMLEFT", 0, button_y)

			--> create run now button

			local functionFilter = _detalhes:CreateScriptEnvironment()

			local execute_script = function()
				local script = code_editor:GetText()
				local func, errortext = loadstring (script, "Q")

				if (func) then
					setfenv (func, functionFilter)
					gump:QuickDispatch (func)
				else
					errortext_frame:Flash (0.2, 0.2, 0.4, true, nil, nil, "NONE")
				end
			end

			local run_script_button = gump:CreateButton (f, execute_script, 120, 20, "Test Code", -1, nil, nil, nil, nil, nil, gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"), gump:GetTemplate ("font", "PLATER_BUTTON"))
			run_script_button:SetIcon ([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Up]], 20, 20, "overlay", {0.05, 0.95, 0.05, 0.95})
			run_script_button:SetPoint ("BOTTOMRIGHT", code_editor, "TOPRIGHT", 0, 3)

		end

		DetailsPluginContainerWindow.OpenPlugin (DetailsRunCodePanel)
		DetailsRunCodePanel.CodeTypeDropdown:Select (1, true)

		--> show the initialization code when showing up this window
		DetailsRunCodePanel.EditingCodeKey = _detalhes.RunCodeTypes [1].ProfileKey

		local code = _detalhes.run_code [DetailsRunCodePanel.EditingCodeKey]
		DetailsRunCodePanel.CodeEditor:SetText (code)
	end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ~API

	function _detalhes:InitializeAPIWindow()
		local DetailsAPI2Frame = gump:CreateSimplePanel (UIParent, 700, 480, "Details! API", "DetailsAPI2Frame")
		DetailsAPI2Frame.Frame = DetailsAPI2Frame
		DetailsAPI2Frame.__name = "API"
		DetailsAPI2Frame.real_name = "DETAILS_APIWINDOW"
		DetailsAPI2Frame.__icon = [[Interface\AddOns\Details\images\icons]]
		DetailsAPI2Frame.__iconcoords = {449/512, 480/512, 62/512, 83/512}
		DetailsAPI2Frame.__iconcolor = "DETAILS_API_ICON"
		DetailsPluginContainerWindow.EmbedPlugin (DetailsAPI2Frame, DetailsAPI2Frame, true)

		function DetailsAPI2Frame.RefreshWindow()
			_detalhes.OpenAPI()
		end
	end

	function _detalhes.OpenAPI()

		if (not DetailsAPI2Frame or not DetailsAPI2Frame.Initialized) then

			--menu settings

			DetailsAPI2Frame.Initialized = true

			local panelWidth = 800
			local scrollWidth = 200
			local scrollHeight = 570
			local lineHeight = 20
			local lineAmount = 27
			local backdropColor = {.2, .2, .2, 0.2}
			local backdropColorOnEnter = {.8, .8, .8, 0.4}
			local backdropColorSelected = {1, 1, .8, 0.4}
			local yStart = -30
			local xAnchorPoint = 250
			local parametersAmount = 10
			local returnAmount = 10

			--local Api2Frame = DetailsFramework:CreateSimplePanel (UIParent, panelWidth, panelHeight, "Details! API 2.0", "DetailsAPI2Frame")
			local Api2Frame = DetailsAPI2Frame

			Api2Frame:SetFrameStrata ("HIGH")
			Api2Frame:SetPoint ("CENTER")
			DetailsFramework:ApplyStandardBackdrop (Api2Frame, false, 1.2)

			--store
			local apiFunctionNames = {}
			local parametersLines = {}
			local returnLines = {}
			local currentSelected = 1

			local api = Details.API_Description.namespaces[1].api

			--on select api on the menu
			local onSelectAPI = function (self)
				local apiName = apiFunctionNames [self.index]
				if (not apiName) then
					Details:Msg ("API name not found:", apiName)
					return
				end

				--fill the box in the right with information about the API
				local apiInfo = api [self.index]
				if (not apiInfo) then
					Details:Msg ("API information for api not found", apiName)
					return
				end

				currentSelected = self.index

				--update name and desc
				Api2Frame.ApiFunctionName.text = apiName
				Api2Frame.ApiFunctionDesc.text = apiInfo.desc

				--update the copy line text box
				local parameters = ""
				for parameterIndex, parameterInfo in _ipairs (apiInfo.parameters) do
					if (parameterInfo.required) then
						parameters = parameters .. parameterInfo.name .. ", "
					end
				end
				parameters = parameters:gsub (", $", "")

				local returnValues = "local "
				for returnIndex, returnInfo in _ipairs (apiInfo.returnValues) do
					returnValues = returnValues .. returnInfo.name .. ", "
				end
				returnValues = returnValues:gsub (", $", "")
				returnValues = returnValues .. " = "

				if (parameters ~= "") then
					Api2Frame.ApiCopy.text = returnValues .. "Details." .. apiName .. "( " .. parameters .. " )"
				else
					Api2Frame.ApiCopy.text = returnValues .. "Details." .. apiName .. "()"
				end

				Api2Frame.ApiCopy:SetFocus (true)
				Api2Frame.ApiCopy:HighlightText()

				--parameters
				for i = 1, #parametersLines do
					local parameterLine = parametersLines [i]
					local parameterInfo = apiInfo.parameters [i]

					if (parameterInfo) then
						parameterLine:Show()
						parameterLine.index = i
						parameterLine.name.text = parameterInfo.name
						parameterLine.typeData.text = parameterInfo.type
						parameterLine.required.text = parameterInfo.required and "yes" or "no"
						parameterLine.default.text = parameterInfo.default or ""
					else
						parameterLine:Hide()
					end
				end

				--return values
				for i = 1, #returnLines do
					local returnLine = returnLines [i]
					local returnInfo = apiInfo.returnValues [i]

					if (returnInfo) then
						returnLine:Show()
						returnLine.index = i
						returnLine.name.text = returnInfo.name
						returnLine.typeData.text = returnInfo.type
						returnLine.desc.text = returnInfo.desc

					else
						returnLine:Hide()
					end
				end

				--refresh the scroll box
				Api2Frame.scrollMenu:Refresh()
			end

			--menu scroll
			local apiMenuScrollRefresh = function (self, data, offset, total_lines)
				for i = 1, total_lines do
					local index = i + offset
					local apiName = data [index]
					if (apiName) then
						local line = self:GetLine (i)
						line.text:SetText (apiName)
						line.index = index

						if (currentSelected == index) then
							line:SetBackdropColor (unpack (backdropColorSelected))
						else
							line:SetBackdropColor (unpack (backdropColor))
						end
					end
				end
			end

			for apiIndex, apiDesc in _ipairs (api) do
				apiFunctionNames[#apiFunctionNames+1] = apiDesc.name
			end

			local api2ScrollMenu = DetailsFramework:CreateScrollBox (Api2Frame, "$parentApi2MenuScroll", apiMenuScrollRefresh, apiFunctionNames, scrollWidth, scrollHeight, lineAmount, lineHeight)
			DetailsFramework:ReskinSlider (api2ScrollMenu)
			api2ScrollMenu:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", 10, yStart)
			Api2Frame.scrollMenu = api2ScrollMenu

			local lineOnEnter = function (self)
				self:SetBackdropColor (unpack (backdropColorOnEnter))

				local apiName = apiFunctionNames [self.index]
				if (not apiName) then
					return
				end

				--fill the box in the right with information about the API
				local apiInfo = api [self.index]
				if (not apiInfo) then
					return
				end

				GameCooltip2:Preset(2)
				GameCooltip2:SetOwner (self, "LEFT", "RIGHT", 2, 0)
				GameCooltip2:AddLine (apiInfo.desc)
				GameCooltip2:ShowCooltip()
			end

			local lineOnLeave = function (self)
				if (currentSelected == self.index) then
					self:SetBackdropColor (unpack (backdropColorSelected))
				else
					self:SetBackdropColor (unpack (backdropColor))
				end

				GameCooltip2:Hide()
			end

			--create lines
			for i = 1, lineAmount do
				api2ScrollMenu:CreateLine (function (self, index)
					local line = CreateFrame ("button", "$parentLine" .. index, self)
					line:SetPoint ("TOPLEFT", self, "TOPLEFT", 1, -((index-1)*(lineHeight+1)) - 1)
					line:SetSize (scrollWidth - 2, lineHeight)
					line.index = index

					line:SetScript ("OnEnter", lineOnEnter)
					line:SetScript ("OnLeave", lineOnLeave)

					line:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
					line:SetBackdropColor (unpack (backdropColor))

					line.text = DetailsFramework:CreateLabel (line)
					line.text:SetPoint ("LEFT", line, "LEFT", 2, 0)

					line:SetScript ("OnMouseDown", onSelectAPI)

					return line
				end)
			end

			--info box
				local infoWidth = panelWidth - xAnchorPoint - 10
				--api name
				Api2Frame.ApiFunctionName = DetailsFramework:CreateLabel (Api2Frame, "", 14, "orange")
				Api2Frame.ApiFunctionName:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", xAnchorPoint, yStart)
				--api desc
				Api2Frame.ApiFunctionDesc = DetailsFramework:CreateLabel (Api2Frame)
				Api2Frame.ApiFunctionDesc:SetPoint ("TOPLEFT", Api2Frame.ApiFunctionName, "BOTTOMLEFT", 0, -2)
				Api2Frame.ApiFunctionDesc.width = infoWidth
				Api2Frame.ApiFunctionDesc.height = 22
				Api2Frame.ApiFunctionDesc.valign = "top"

				--api func to copy
				local apiCopyString = DetailsFramework:CreateLabel (Api2Frame, "Copy String", 12, "orange")
				apiCopyString:SetPoint ("TOPLEFT", Api2Frame.ApiFunctionDesc, "BOTTOMLEFT", 0, -20)
				Api2Frame.ApiCopy = DetailsFramework:CreateTextEntry (Api2Frame, function() end, infoWidth, 20)
				Api2Frame.ApiCopy:SetPoint ("TOPLEFT", apiCopyString, "BOTTOMLEFT", 0, -2)
				Api2Frame.ApiCopy:SetTemplate (DetailsFramework:GetTemplate ("button", "DETAILS_CUSTOMDISPLAY_CODE_BOX"))

				--parameters
				local parametersYStart = yStart - 110
				local parametersString = DetailsFramework:CreateLabel (Api2Frame, "Parameters", 12, "orange")
				parametersString:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", xAnchorPoint, parametersYStart)

				parametersYStart = parametersYStart - 20

				local space1, space2, space3 = 150, 300, 450
				local parametersHeader = CreateFrame ("Frame", nil, Api2Frame)
				parametersHeader:SetSize (infoWidth, 20)
				parametersHeader:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", xAnchorPoint, parametersYStart)
				parametersHeader:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
				parametersHeader:SetBackdropColor (unpack (backdropColor))
				parametersHeader.name = DetailsFramework:CreateLabel (parametersHeader, "Name", 12, "yellow")
				parametersHeader.typeData = DetailsFramework:CreateLabel (parametersHeader, "Type", 12, "yellow")
				parametersHeader.required = DetailsFramework:CreateLabel (parametersHeader, "Is Required", 12, "yellow")
				parametersHeader.default = DetailsFramework:CreateLabel (parametersHeader, "Default Value", 12, "yellow")
				parametersHeader.name:SetPoint ("LEFT", parametersHeader, "LEFT", 2, 0)
				parametersHeader.typeData:SetPoint ("LEFT", parametersHeader, "LEFT", space1, 0)
				parametersHeader.required:SetPoint ("LEFT", parametersHeader, "LEFT", space2, 0)
				parametersHeader.default:SetPoint ("LEFT", parametersHeader, "LEFT", space3, 0)

				local parameterOnEnter = function (self)
					GameCooltip2:Preset(2)
					GameCooltip2:SetOwner (self)

					--fill the box in the right with information about the API
					local apiInfo = api [currentSelected]
					if (not apiInfo) then
						return
					end
					GameCooltip2:AddLine (apiInfo.parameters [self.index].desc)
					GameCooltip2:ShowCooltip()

					self:SetBackdropColor (unpack (backdropColorOnEnter))
				end
				local parameterOnLeave = function (self)
					GameCooltip2:Hide()
					self:SetBackdropColor (unpack (backdropColor))
				end

				for i = 1, parametersAmount do
					local f = CreateFrame ("Button", nil, Api2Frame)
					f:SetSize (infoWidth, 20)
					f:SetScript ("OnEnter", parameterOnEnter)
					f:SetScript ("OnLeave", parameterOnLeave)
					f:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
					f:SetBackdropColor (unpack (backdropColor))
					f:Hide()

					f.name = DetailsFramework:CreateLabel (f)
					f.typeData = DetailsFramework:CreateLabel (f)
					f.required = DetailsFramework:CreateLabel (f)
					f.default = DetailsFramework:CreateLabel (f)

					f:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", xAnchorPoint, parametersYStart + (-i * 20))

					f.name:SetPoint ("LEFT", f, "LEFT", 2, 0)
					f.typeData:SetPoint ("LEFT", f, "LEFT", space1, 0)
					f.required:SetPoint ("LEFT", f, "LEFT", space2, 0)
					f.default:SetPoint ("LEFT", f, "LEFT", space3, 0)

					parametersLines[#parametersLines+1] = f
				end

			--return value box
				local returnYStart = yStart - 260
				local returnString = DetailsFramework:CreateLabel (Api2Frame, "Return Values", 12, "orange")
				returnString:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", xAnchorPoint, returnYStart)

				returnYStart = returnYStart - 20

				local space1 = 200
				local returnHeader = CreateFrame ("Frame", nil, Api2Frame)
				returnHeader:SetSize (infoWidth, 20)
				returnHeader:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", xAnchorPoint, returnYStart)
				returnHeader:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
				returnHeader:SetBackdropColor (unpack (backdropColor))
				returnHeader.name = DetailsFramework:CreateLabel (returnHeader, "Name", 12, "yellow")
				returnHeader.typeData = DetailsFramework:CreateLabel (returnHeader, "Type", 12, "yellow")
				returnHeader.name:SetPoint ("LEFT", returnHeader, "LEFT", 2, 0)
				returnHeader.typeData:SetPoint ("LEFT", returnHeader, "LEFT", space1, 0)

				local returnOnEnter = function (self)
					self:SetBackdropColor (unpack (backdropColorOnEnter))
				end
				local returnOnLeave = function (self)
					self:SetBackdropColor (unpack (backdropColor))
				end

				for i = 1, returnAmount do
					local f = CreateFrame ("Button", nil, Api2Frame)
					f:SetSize (infoWidth, 20)
					f:SetScript ("OnEnter", returnOnEnter)
					f:SetScript ("OnLeave", returnOnLeave)
					f:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
					f:SetBackdropColor (unpack (backdropColor))
					f:Hide()

					f.name = DetailsFramework:CreateLabel (f)
					f.typeData = DetailsFramework:CreateLabel (f)

					f.desc = DetailsFramework:CreateLabel (f, "", 10, "gray")
					f.desc.width = infoWidth
					f.desc.height = 60
					f.desc.valign = "top"

					f:SetPoint ("TOPLEFT", Api2Frame, "TOPLEFT", xAnchorPoint, returnYStart + (-i * 20))

					f.name:SetPoint ("LEFT", f, "LEFT", 2, 0)
					f.typeData:SetPoint ("LEFT", f, "LEFT", space1, 0)

					f.desc:SetPoint ("TOPLEFT", f.name, "BOTTOMLEFT", 0, -5)

					returnLines[#returnLines+1] = f
				end

			function Api2Frame.Refresh()
				onSelectAPI (api2ScrollMenu.Frames [1])
			end
		end

		DetailsAPI2Frame:Show()
		DetailsAPI2Frame.Refresh()

		DetailsPluginContainerWindow.OpenPlugin (DetailsAPI2Frame)

	end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



local CreateCurrentDpsFrame = function (parent, name)

	local DF = _detalhes.gump

	--> some constants
		local header_size = 12 --title bar size
		local green_team_color = {.5, 1, .5, 1}
		local yellow_team_color = {1, 1, .5, 1}

	--> main farame
		local f = CreateFrame ("Frame", name, parent or UIParent)
		f:SetPoint ("CENTER", UIParent, "CENTER")
		f:SetSize (_detalhes.current_dps_meter.frame.width, _detalhes.current_dps_meter.frame.height)

		f:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}})
		f:SetBackdropColor (unpack (_detalhes.current_dps_meter.frame.backdrop_color))
		f:EnableMouse (true)
		f:SetMovable (true)
		f:SetClampedToScreen (true)

		f.PlayerTeam = 0

		local LibWindow = LibStub ("LibWindow-1.1")
		LibWindow.RegisterConfig (f, _detalhes.current_dps_meter.frame)
		LibWindow.MakeDraggable (f)
		LibWindow.RestorePosition (f)

	--> title bar
		local TitleString = f:CreateFontString (nil, "overlay", "GameFontNormal")
		TitleString:SetPoint ("TOP", f, "TOP", 0, -1)
		TitleString:SetText ("Dps on Last 5 Seconds")
		DF:SetFontSize (TitleString, 9)
		local TitleBackground = f:CreateTexture (nil, "artwork")
		TitleBackground:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
		TitleBackground:SetVertexColor (.1, .1, .1, .9)
		TitleBackground:SetPoint ("TOPLEFT", f, "TOPLEFT")
		TitleBackground:SetPoint ("TOPRIGHT", f, "TOPRIGHT")
		TitleBackground:SetHeight (header_size)

	--> labels for arena
		local labelPlayerTeam = f:CreateFontString (nil, "overlay", "GameFontNormal")
		local labelYellowTeam = f:CreateFontString (nil, "overlay", "GameFontNormal")
		labelPlayerTeam:SetText ("Player Team")
		labelYellowTeam:SetText ("Enemy Team")
		DF:SetFontSize (labelPlayerTeam, 14)
		DF:SetFontSize (labelYellowTeam, 14)
		DF:SetFontOutline (labelPlayerTeam, "NONE")
		DF:SetFontOutline (labelYellowTeam, "NONE")

		local labelPlayerTeam_DPS = f:CreateFontString (nil, "overlay", "GameFontNormal")
		local labelYellowTeam_DPS = f:CreateFontString (nil, "overlay", "GameFontNormal")
		labelPlayerTeam_DPS:SetText ("0")
		labelYellowTeam_DPS:SetText ("0")

		local labelPlayerTeam_DPS_Icon = f:CreateTexture (nil, "overlay")
		local labelYellowTeam_DPS_Icon = f:CreateTexture (nil, "overlay")
		labelPlayerTeam_DPS_Icon:SetTexture ([[Interface\LFGFRAME\UI-LFG-ICON-ROLES]])
		labelYellowTeam_DPS_Icon:SetTexture ([[Interface\LFGFRAME\UI-LFG-ICON-ROLES]])
		labelPlayerTeam_DPS_Icon:SetTexCoord (72/256, 130/256, 69/256, 127/256)
		labelYellowTeam_DPS_Icon:SetTexCoord (72/256, 130/256, 69/256, 127/256)
		local icon_size = 16
		labelPlayerTeam_DPS_Icon:SetSize (icon_size, icon_size)
		labelYellowTeam_DPS_Icon:SetSize (icon_size, icon_size)

		labelPlayerTeam:SetPoint ("LEFT", f, "LEFT", 5, 10)
		labelYellowTeam:SetPoint ("RIGHT", f, "RIGHT", -5, 10)

		labelPlayerTeam_DPS_Icon:SetPoint ("TOPLEFT", labelPlayerTeam, "BOTTOMLEFT", 0, -4)
		labelYellowTeam_DPS_Icon:SetPoint ("TOPLEFT", labelYellowTeam, "BOTTOMLEFT", 0, -4)

		labelPlayerTeam_DPS:SetPoint ("LEFT", labelPlayerTeam_DPS_Icon, "RIGHT", 4, 0)
		labelYellowTeam_DPS:SetPoint ("LEFT", labelYellowTeam_DPS_Icon, "RIGHT", 4, 0)

		labelPlayerTeam:SetTextColor (unpack (green_team_color))
		labelYellowTeam:SetTextColor (unpack (yellow_team_color))

		function f.SwapArenaTeamColors()
			if (f.PlayerTeam == 0) then
				labelPlayerTeam:SetTextColor (unpack (yellow_team_color))
				labelYellowTeam:SetTextColor (unpack (green_team_color))
			else
				labelPlayerTeam:SetTextColor (unpack (green_team_color))
				labelYellowTeam:SetTextColor (unpack (yellow_team_color))
			end
		end

	--> frame update function

		--> update
		local time_fraction = 100/1000 --one tick per 100ms
		f.NextUpdate =  time_fraction --when the next tick occur
		f.NextScreenUpdate = _detalhes.current_dps_meter.update_interval --when the labels on the frame receive update

		--> arena
		f.PlayerTeamBuffer = {}
		f.YellowTeamBuffer = {}
		f.PlayerTeamDamage = 0
		f.YellowDamage = 0
		f.LastPlayerTeamDamage = 0
		f.LastYellowDamage = 0

		--> general
		f.SampleSize = _detalhes.current_dps_meter.sample_size
		f.MaxBufferIndex = 1
		f.ShowingArena = false

		function _detalhes:UpdateTheRealCurrentDPSFrame (scenario)
			--> don't run if the featured hasn't loaded
			if (not f) then
				return
			end

			if (not _detalhes.current_dps_meter.enabled) then
				f:Hide()
				return
			end

			if (not _detalhes.current_dps_meter.arena_enabled) then
				f:Hide()
				return
			end

			--> where the player are
			if (scenario == "arena") then
				labelPlayerTeam_DPS:Show()
				labelYellowTeam_DPS:Show()
				labelPlayerTeam:Show()
				labelYellowTeam:Show()
				labelPlayerTeam_DPS_Icon:Show()
				labelYellowTeam_DPS_Icon:Show()

				--> update arena labels
				DF:SetFontColor (labelPlayerTeam_DPS, _detalhes.current_dps_meter.font_color)
				DF:SetFontFace (labelPlayerTeam_DPS, _detalhes.current_dps_meter.font_face)
				DF:SetFontSize (labelPlayerTeam_DPS, _detalhes.current_dps_meter.font_size)
				DF:SetFontOutline (labelPlayerTeam_DPS, _detalhes.current_dps_meter.font_shadow)

				DF:SetFontColor (labelYellowTeam_DPS, _detalhes.current_dps_meter.font_color)
				DF:SetFontFace (labelYellowTeam_DPS, _detalhes.current_dps_meter.font_face)
				DF:SetFontSize (labelYellowTeam_DPS, _detalhes.current_dps_meter.font_size)
				DF:SetFontOutline (labelYellowTeam_DPS, _detalhes.current_dps_meter.font_shadow)

				--> wipe current data for arena
				wipe (f.PlayerTeamBuffer)
				wipe (f.YellowTeamBuffer)

				--> reset damage
				f.PlayerTeamDamage = 0
				f.YellowDamage = 0

				--> reset last tick damage
				f.LastPlayerTeamDamage = 0
				f.LastYellowDamage = 0

				f:Show()
			else
				--> isn't arena, hide arena labels
				labelPlayerTeam_DPS:Hide()
				labelYellowTeam_DPS:Hide()
				labelPlayerTeam:Hide()
				labelYellowTeam:Hide()
				labelPlayerTeam_DPS_Icon:Hide()
				labelYellowTeam_DPS_Icon:Hide()
			end

			--> frame position
			f:SetSize (_detalhes.current_dps_meter.frame.width, _detalhes.current_dps_meter.frame.height)
			LibWindow.RegisterConfig (f, _detalhes.current_dps_meter.frame)
			LibWindow.RestorePosition (f)

			--> backdrop color
			f:SetBackdropColor (unpack (_detalhes.current_dps_meter.frame.backdrop_color))

			--> set frame size
			f:SetSize (_detalhes.current_dps_meter.frame.width, _detalhes.current_dps_meter.frame.height)

			--> frame is locked
			if (_detalhes.current_dps_meter.frame.locked) then
				f:EnableMouse (false)
			else
				f:EnableMouse (true)
			end

			--> frame can show title
			TitleString:SetShown(_detalhes.current_dps_meter.frame.show_title)
			TitleBackground:SetShown(_detalhes.current_dps_meter.frame.show_title)

			--> frame strata
			f:SetFrameStrata (_detalhes.current_dps_meter.frame.strata)

			--> calcule buffer size
			f.MaxBufferIndex = f.SampleSize * time_fraction * 100 --sample size in seconds * fraction * tick milliseconds

			--> interval to update the frame
			f.NextScreenUpdate = _detalhes.current_dps_meter.update_interval
		end

		_detalhes:UpdateTheRealCurrentDPSFrame()

		local on_tick = function (self, deltaTime)

			self.NextUpdate = self.NextUpdate - deltaTime

			if (self.NextUpdate <= 0) then
				--> update string
				local currentCombat = _detalhes:GetCombat()
				local damageContainer = currentCombat:GetContainer (DETAILS_ATTRIBUTE_DAMAGE)

				--> show the current dps during an arena match
				if (self.ShowingArena) then
					--> the team damage done at this tick
					local thisTickPlayerTeamDamage = 0
					local thisTickYellowDamage = 0

					for i, actor in damageContainer:ListActors() do
						--actor.arena_team = actor.arena_team or 0 --debug
						if (actor:IsPlayer() and actor.arena_team) then
							if (actor.arena_team == 0) then
								--green team / player team
								thisTickPlayerTeamDamage = thisTickPlayerTeamDamage + actor.total
							else
								--yellow
								thisTickYellowDamage = thisTickYellowDamage + actor.total
							end

							if (actor.nome == _detalhes.playername) then
								--> if player isn't in green team > swap colors
								if (f.PlayerTeam ~= actor.arena_team) then
									f.SwapArenaTeamColors()
									f.PlayerTeam  = actor.arena_team
								end
							end
						end
					end

					--> calculate how much damage the team made on this tick
					local playerTeamDamageDone = thisTickPlayerTeamDamage - f.LastPlayerTeamDamage
					local yellowDamageDone = thisTickYellowDamage - f.LastYellowDamage

					--> add the damage to buffer
					tinsert (f.PlayerTeamBuffer, 1, playerTeamDamageDone)
					tinsert (f.YellowTeamBuffer, 1, yellowDamageDone)

					--> save the current damage amount
					f.LastPlayerTeamDamage = thisTickPlayerTeamDamage
					f.LastYellowDamage = thisTickYellowDamage

					--> add the damage to current total damage
					f.PlayerTeamDamage = f.PlayerTeamDamage + playerTeamDamageDone
					f.YellowDamage = f.YellowDamage + yellowDamageDone

					--> remove player team damage
					local removedDamage = tremove (f.PlayerTeamBuffer, f.MaxBufferIndex+1)
					if (removedDamage) then
						f.PlayerTeamDamage = f.PlayerTeamDamage - removedDamage
						--> be save
						f.PlayerTeamDamage = max (0, f.PlayerTeamDamage)
					end

					--> remove yellow damage
					local removedDamage = tremove (f.YellowTeamBuffer, f.MaxBufferIndex+1)
					if (removedDamage) then
						f.YellowDamage = f.YellowDamage - removedDamage
						--> be save
						f.YellowDamage = max (0, f.YellowDamage)
					end

					self.NextScreenUpdate = self.NextScreenUpdate - time_fraction
					if (self.NextScreenUpdate <= 0) then
						if (f.PlayerTeam == 0) then
							labelPlayerTeam_DPS:SetText (_detalhes:ToK2 (self.PlayerTeamDamage / self.SampleSize))
							labelYellowTeam_DPS:SetText (_detalhes:ToK2 (self.YellowDamage / self.SampleSize))
						else
							labelPlayerTeam_DPS:SetText (_detalhes:ToK2 (self.YellowDamage / self.SampleSize))
							labelYellowTeam_DPS:SetText (_detalhes:ToK2 (self.PlayerTeamDamage / self.SampleSize))
						end
						f.NextScreenUpdate = _detalhes.current_dps_meter.update_interval
					end

				end

				--> set next update time
				self.NextUpdate = time_fraction
			end
		end

		f:SetScript ("OnHide", function()
			f.ShowingArena = false
			f:SetScript ("OnUpdate", nil)
		end)

		function f:StartForArenaMatch()
			if (not f.ShowingArena) then
				_detalhes:UpdateTheRealCurrentDPSFrame ("arena")
				f.ShowingArena = true
				f:SetScript ("OnUpdate", on_tick)
			end
		end

		local eventListener = _detalhes:CreateEventListener()

		function eventListener:ArenaStarted()
			if (_detalhes.current_dps_meter.arena_enabled) then
				f:StartForArenaMatch()
			end
		end

		function eventListener:ArenaEnded()
			f:Hide()
		end

		function eventListener:ResetBuffer()
			if (f:IsShown()) then
				wipe (f.PlayerTeamBuffer)
				wipe (f.YellowTeamBuffer)
				f.PlayerTeamDamage = 0
				f.YellowDamage = 0
				f.LastPlayerTeamDamage = 0
				f.LastYellowDamage = 0
			end
		end

		eventListener:RegisterEvent ("COMBAT_ARENA_START", "ArenaStarted")
		eventListener:RegisterEvent ("COMBAT_ARENA_END", "ArenaEnded")
		eventListener:RegisterEvent ("COMBAT_PLAYER_ENTER", "ResetBuffer")

	_detalhes.Broadcaster_CurrentDpsLoaded = true
	f:Hide()
end

local CreateEventTrackerFrame = function (parent, name)

	local DF = _detalhes.gump
	local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")

	--> main farame
		local f = CreateFrame ("Frame", name, parent or UIParent)
		f:SetPoint ("CENTER", UIParent, "CENTER")
		f:SetMinResize (150, 40)
		f:SetMaxResize (800, 1024)
		f:SetSize (_detalhes.event_tracker.frame.width, _detalhes.event_tracker.frame.height)

		f:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}})
		f:SetBackdropColor (unpack (_detalhes.event_tracker.frame.backdrop_color))
		f:EnableMouse (true)
		f:SetMovable (true)
		f:SetResizable (true)
		f:SetClampedToScreen (true)

		local LibWindow = LibStub ("LibWindow-1.1")
		LibWindow.RegisterConfig (f, _detalhes.event_tracker.frame)
		LibWindow.MakeDraggable (f)
		LibWindow.RestorePosition (f)

	--> two resizers

		local left_resize, right_resize = DF:CreateResizeGrips (f)

		left_resize:SetScript ("OnMouseDown", function (self)
			if (not f.resizing and not _detalhes.event_tracker.frame.locked) then
				f.resizing = true
				f:StartSizing ("BOTTOMLEFT")
			end
		end)
		left_resize:SetScript ("OnMouseUp", function (self)
			if (f.resizing) then
				f.resizing = false
				f:StopMovingOrSizing()
				_detalhes.event_tracker.frame.width = f:GetWidth()
				_detalhes.event_tracker.frame.height = f:GetHeight()
			end
		end)
		right_resize:SetScript ("OnMouseDown", function (self)
			if (not f.resizing and not _detalhes.event_tracker.frame.locked) then
				f.resizing = true
				f:StartSizing ("BOTTOMRIGHT")
			end
		end)
		right_resize:SetScript ("OnMouseUp", function (self)
			if (f.resizing) then
				f.resizing = false
				f:StopMovingOrSizing()
				_detalhes.event_tracker.frame.width = f:GetWidth()
				_detalhes.event_tracker.frame.height = f:GetHeight()
			end
		end)

		f:SetScript ("OnSizeChanged", function (self)

		end)

	--> scroll frame

		--> frame config

		local scroll_line_amount = 1
		local scroll_width = 195
		local header_size = 20

		--> on tick script
		local lineOnTick = function (self, deltaTime)
			--> when this event occured on combat log
			local gameTime = self.GameTime

			--> calculate how much time elapsed since the event got triggered
			local elapsedTime = GetTime() - gameTime

			--> set the bar animation:
			local animationPercent = min (elapsedTime, 1)
			self.Statusbar:SetValue (animationPercent)

			--> set the spark location
			if (animationPercent < 1) then
				self.Spark:SetPoint ("LEFT", self, "LEFT", (self:GetWidth() * animationPercent) - 10, 0)
				if (not self.Spark:IsShown()) then
					self.Spark:Show()
				end
			else
				if (self.Spark:IsShown()) then
					self.Spark:Hide()
				end
			end
		end

		--> create a line on the scroll frame
		local scroll_createline = function (self, index)

			local line = CreateFrame ("Frame", "$parentLine" .. index, self)
			line:EnableMouse (false)
			line.Index = index --> hack to not trigger error on UpdateWorldTrackerLines since Index is set after this function is ran

			--> set its backdrop
			line:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 16, insets = {left = 0, right = 0, top = 0, bottom = 0}})
			--line:SetBackdropColor (1, 1, 1, 0.75)

			--> statusbar
			local statusbar = CreateFrame ("statusbar", "$parentStatusBar", line)
			statusbar:SetAllPoints()
			local statusbartexture = statusbar:CreateTexture (nil, "border")
			statusbar:SetStatusBarTexture (statusbartexture)
			statusbar:SetMinMaxValues (0, 1)
			statusbar:SetValue (0)

			local statusbarspark = statusbar:CreateTexture (nil, "artwork")
			statusbarspark:SetTexture ([[Interface\CastingBar\UI-CastingBar-Spark]])
			statusbarspark:SetSize (16, 30)
			statusbarspark:SetBlendMode ("ADD")
			statusbarspark:Hide()

			--> create the icon textures and texts - they are all statusbar childs
			local lefticon = statusbar:CreateTexture ("$parentLeftIcon", "overlay")
			lefticon:SetPoint ("LEFT", line, "LEFT", 0, 0)

			local righticon = statusbar:CreateTexture ("$parentRightIcon", "overlay")
			righticon:SetPoint ("RIGHT", line, "RIGHT", 0, 0)

			local lefttext = statusbar:CreateFontString ("$parentLeftText", "overlay", "GameFontNormal")
			DF:SetFontSize (lefttext, 9)
			lefttext:SetPoint ("LEFT", lefticon, "RIGHT", 2, 0)

			local righttext = statusbar:CreateFontString ("$parentRightText", "overlay", "GameFontNormal")
			DF:SetFontSize (righttext, 9)
			righttext:SetPoint ("RIGHT", righticon, "LEFT", -2, 0)

			lefttext:SetJustifyH ("LEFT")
			righttext:SetJustifyH ("RIGHT")

			local actionicon = statusbar:CreateTexture ("$parentRightIcon", "overlay")
			actionicon:SetPoint ("CENTER", line, "CENTER")

			--> set members
			line.LeftIcon = lefticon
			line.RightIcon = righticon
			line.LeftText = lefttext
			line.RightText = righttext
			line.Statusbar = statusbar
			line.StatusbarTexture = statusbartexture
			line.Spark = statusbarspark
			line.ActionIcon = actionicon

			--> set some parameters
			_detalhes:UpdateWorldTrackerLines (line)

			--> set scripts
			line:SetScript ("OnUpdate", lineOnTick)

			return line
		end

		--> some consts to help work with indexes
		local SPELLTYPE_COOLDOWN = "cooldown"
		local SPELLTYPE_INTERRUPT = "interrupt"
		local SPELLTYPE_OFFENSIVE = "offensive"
		local SPELLTYPE_CROWDCONTROL = "crowdcontrol"

		local ABILITYTABLE_SPELLTYPE = 1
		local ABILITYTABLE_SPELLID = 2
		local ABILITYTABLE_CASTERNAME = 3
		local ABILITYTABLE_TARGETNAME = 4
		local ABILITYTABLE_EXTRASPELLID = 6
		local ABILITYTABLE_GAMETIME = 7
		local ABILITYTABLE_CASTERSERIAL = 8
		local ABILITYTABLE_ISENEMY = 9
		local ABILITYTABLE_TARGETSERIAL = 10

		local get_spec_or_class = function (serial, name)
			local class
			local spec = _detalhes.cached_specs [serial]
			if (not spec) then
				local _, engClass = UnitClass (name)
				if (engClass) then
					class = engClass
				else
					local locClass, engClass, locRace, engRace, gender = GetPlayerInfoByGUID (serial)
					if (engClass) then
						class = engClass
					end
				end
			end

			return spec, class
		end

		local get_player_icon = function (spec, class)
			if (spec) then
				return [[Interface\AddOns\Details\images\spec_icons_normal]], unpack (_detalhes.class_specs_coords [spec])
			elseif (class) then
				return [[Interface\AddOns\Details\images\classes_small]], unpack (_detalhes.class_coords [class])
			else
				return [[Interface\AddOns\Details\images\classes_plus]], 0.50390625, 0.62890625, 0, 0.125
			end
		end

		local add_role_and_class_color = function (player_name, player_serial)

			--> get the actor object
			local actor = _detalhes.tabela_vigente[1]:GetActor (player_name)

			if (actor) then
				--> remove realm name
				player_name = _detalhes:GetOnlyName (player_name)

				local class, spec, role = actor.classe, actor.spec, actor.role
				if (not class) then
					spec, class = get_spec_or_class (player_serial, player_name)
				end

				--> add the class color
				if (_detalhes.player_class [class]) then
					--> is a player, add the class color
					player_name = _detalhes:AddColorString (player_name, class)
				end

				--add the role icon
				if (role ~= "NONE") then
					--> have a role
					player_name = _detalhes:AddRoleIcon (player_name, role, _detalhes.event_tracker.line_height)
				end

			else
				local spec, class = get_spec_or_class (player_serial, player_name)
				player_name = _detalhes:GetOnlyName (player_name)

				if (class) then
					--> add the class color
					if (_detalhes.player_class [class]) then
						--> is a player, add the class color
						player_name = _detalhes:AddColorString (player_name, class)
					end
				end
			end

			return player_name
		end

		local get_text_size = function()
			local iconsSpace = _detalhes.event_tracker.line_height * 3
			local textSpace = 4
			local saveSpace = 14

			local availableSpace = (f:GetWidth() - iconsSpace - textSpace - saveSpace) / 2

			return availableSpace
		end

		local shrink_string = function (fontstring, size)
			local text = fontstring:GetText()
			local loops = 20
			while (fontstring:GetStringWidth() > size and loops > 0) do
				text = _utf8sub(text, 1, _utf8len(text) - 1)
				fontstring:SetText (text)
				loops = loops - 1
			end

			return fontstring
		end

		--refresh the scroll frame
		local scroll_refresh = function (self, data, offset, total_lines)

			local textSize = get_text_size()

			for i = 1, total_lines do
				local index = i + offset
				local ability = data [index]

				if (ability) then
					local line = self:GetLine (i)

					local spec, class = get_spec_or_class (ability [ABILITYTABLE_CASTERSERIAL], ability [ABILITYTABLE_CASTERNAME])
					local texture, L, R, T, B = get_player_icon (spec, class)
					line.LeftIcon:SetTexture (texture)
					line.LeftIcon:SetTexCoord (L, R, T, B)
					line.LeftText:SetText (_detalhes:GetOnlyName (ability [ABILITYTABLE_CASTERNAME]))

					if (ability [ABILITYTABLE_ISENEMY]) then
						line:SetBackdropColor (1, .3, .3, 0.5)
					else
						line:SetBackdropColor (1, 1, 1, 0.5)
					end

					if (ability [ABILITYTABLE_SPELLTYPE] == SPELLTYPE_COOLDOWN) then
						local spellName, _, spellIcon = GetSpellInfo (ability [ABILITYTABLE_SPELLID])
						line.RightIcon:SetTexture (spellIcon)
						line.RightIcon:SetTexCoord (.06, .94, .06, .94)

						local targetName = ability [ABILITYTABLE_TARGETNAME]
						if (targetName) then
							local targetSerial = ability [ABILITYTABLE_TARGETSERIAL]
							targetName = add_role_and_class_color (targetName, targetSerial)
						end

						line.RightText:SetText (targetName or spellName)

						line.ActionIcon:SetTexture ([[Interface\AddOns\Details\images\event_tracker_icons]])
						line.ActionIcon:SetTexCoord (0, 0.125, 0, 1)

					elseif (ability [ABILITYTABLE_SPELLTYPE] == SPELLTYPE_OFFENSIVE) then
						local spellName, _, spellIcon = GetSpellInfo (ability [ABILITYTABLE_SPELLID])
						line.RightIcon:SetTexture (spellIcon)
						line.RightIcon:SetTexCoord (.06, .94, .06, .94)
						line.RightText:SetText (spellName)

						line.ActionIcon:SetTexture ([[Interface\AddOns\Details\images\event_tracker_icons]])
						line.ActionIcon:SetTexCoord (0.127, 0.25, 0, 1)

					elseif (ability [ABILITYTABLE_SPELLTYPE] == SPELLTYPE_INTERRUPT) then
						local spellNameInterrupted, _, spellIconInterrupted = GetSpellInfo (ability [ABILITYTABLE_EXTRASPELLID])
						line.RightIcon:SetTexture (spellIconInterrupted)
						line.RightIcon:SetTexCoord (.06, .94, .06, .94)
						line.RightText:SetText (spellNameInterrupted)

						line.ActionIcon:SetTexture ([[Interface\AddOns\Details\images\event_tracker_icons]])
						line.ActionIcon:SetTexCoord (0.251, 0.375, 0, 1)

					elseif (ability [ABILITYTABLE_SPELLTYPE] == SPELLTYPE_CROWDCONTROL) then
						local spellName, _, spellIcon = GetSpellInfo (ability [ABILITYTABLE_SPELLID])
						line.RightIcon:SetTexture (spellIcon)
						line.RightIcon:SetTexCoord (.06, .94, .06, .94)

						local targetName = ability [ABILITYTABLE_TARGETNAME]
						if (targetName) then
							local targetSerial = ability [ABILITYTABLE_TARGETSERIAL]
							targetName = add_role_and_class_color (targetName, targetSerial)
						end

						line.RightText:SetText (targetName or "unknown target")

						line.ActionIcon:SetTexture ([[Interface\AddOns\Details\images\event_tracker_icons]])
						line.ActionIcon:SetTexCoord (0.376, 0.5, 0, 1)

					end

					shrink_string (line.LeftText, textSize)
					shrink_string (line.RightText, textSize)

					--> set when the ability was registered on combat log
					line.GameTime = ability [ABILITYTABLE_GAMETIME]
					line:Show()
				end
			end
		end

		--title text
		local TitleString = f:CreateFontString (nil, "overlay", "GameFontNormal")
		TitleString:SetPoint ("TOP", f, "TOP", 0, -3)
		TitleString:SetText ("Details!: Event Tracker")
		local TitleBackground = f:CreateTexture (nil, "artwork")
		TitleBackground:SetTexture ([[Interface\Tooltips\UI-Tooltip-Background]])
		TitleBackground:SetVertexColor (.1, .1, .1, .9)
		TitleBackground:SetPoint ("TOPLEFT", f, "TOPLEFT")
		TitleBackground:SetPoint ("TOPRIGHT", f, "TOPRIGHT")
		TitleBackground:SetHeight (header_size)

		--> table with spells showing on the scroll frame
		local CurrentShowing = {}

		--> scrollframe
		local scrollframe = DF:CreateScrollBox (f, "$parentScrollFrame", scroll_refresh, CurrentShowing, scroll_width, 400, scroll_line_amount, _detalhes.event_tracker.line_height, scroll_createline, true, true)
		scrollframe:SetPoint ("TOPLEFT", f, "TOPLEFT", 0, -header_size)
		scrollframe:SetPoint ("TOPRIGHT", f, "TOPRIGHT", 0, -header_size)
		scrollframe:SetPoint ("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		scrollframe:SetPoint ("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

		--> update line - used by 'UpdateWorldTrackerLines' function
		local update_line = function (line)

			--> get the line index
			local index = line.Index

			--> update left text
			DF:SetFontColor (line.LeftText, _detalhes.event_tracker.font_color)
			DF:SetFontFace (line.LeftText, _detalhes.event_tracker.font_face)
			DF:SetFontSize (line.LeftText, _detalhes.event_tracker.font_size)
			DF:SetFontOutline (line.LeftText, _detalhes.event_tracker.font_shadow)

			--> update right text
			DF:SetFontColor (line.RightText, _detalhes.event_tracker.font_color)
			DF:SetFontFace (line.RightText, _detalhes.event_tracker.font_face)
			DF:SetFontSize (line.RightText, _detalhes.event_tracker.font_size)
			DF:SetFontOutline (line.RightText, _detalhes.event_tracker.font_shadow)

			--> adjust where the line is anchored
			line:SetPoint ("TOPLEFT", line:GetParent(), "TOPLEFT", 0, -((index-1)*(_detalhes.event_tracker.line_height+1)))
			line:SetPoint ("TOPRIGHT", line:GetParent(), "TOPRIGHT", 0, -((index-1)*(_detalhes.event_tracker.line_height+1)))

			--> set its height
			line:SetHeight (_detalhes.event_tracker.line_height)

			--> set texture
			local texture = SharedMedia:Fetch ("statusbar", _detalhes.event_tracker.line_texture)
			line.StatusbarTexture:SetTexture (texture)
			line.StatusbarTexture:SetVertexColor (unpack (_detalhes.event_tracker.line_color))

			--> set icon size
			line.LeftIcon:SetSize (_detalhes.event_tracker.line_height, _detalhes.event_tracker.line_height)
			line.RightIcon:SetSize (_detalhes.event_tracker.line_height, _detalhes.event_tracker.line_height)
			line.ActionIcon:SetSize (_detalhes.event_tracker.line_height-4, _detalhes.event_tracker.line_height-4)
			line.ActionIcon:SetAlpha (0.65)
		end

		-- /run _detalhes.event_tracker.font_shadow = 24
		-- /run _detalhes:UpdateWorldTrackerLines()

		function _detalhes:UpdateWorldTrackerLines (line)
			--> don't run if the featured hasn't loaded
			if (not f) then
				return
			end

			if (line) then
				update_line (line)
			else
				--> update all lines
				for index, line in _ipairs (scrollframe:GetFrames()) do
					update_line (line)
				end
				scrollframe:SetFramesHeight (_detalhes.event_tracker.line_height)
				scrollframe:Refresh()
			end
		end

		function _detalhes:UpdateEventTrackerFrame()
			--> don't run if the featured hasn't loaded
			if (not f) then
				return
			end

			f:SetSize (_detalhes.event_tracker.frame.width, _detalhes.event_tracker.frame.height)
			LibWindow.RegisterConfig (f, _detalhes.event_tracker.frame)
			LibWindow.RestorePosition (f)
			scrollframe:OnSizeChanged()

			local locked = _detalhes.event_tracker.frame.locked
			f:EnableMouse (not locked)
			left_resize:SetShown(not locked)
			right_resize:SetShown(not locked)

			if (_detalhes.event_tracker.frame.show_title) then
				TitleString:Show()
				TitleBackground:Show()
				scrollframe:SetPoint ("TOPLEFT", f, "TOPLEFT", 0, -header_size)
				scrollframe:SetPoint ("TOPRIGHT", f, "TOPRIGHT", 0, -header_size)
			else
				TitleString:Hide()
				TitleBackground:Hide()
				scrollframe:SetPoint ("TOPLEFT", f, "TOPLEFT", 0, 0)
				scrollframe:SetPoint ("TOPRIGHT", f, "TOPRIGHT", 0, 0)
			end

			f:SetBackdropColor (unpack (_detalhes.event_tracker.frame.backdrop_color))
			scrollframe.__background:SetVertexColor (unpack (_detalhes.event_tracker.frame.backdrop_color))

			f:SetFrameStrata (_detalhes.event_tracker.frame.strata)

			_detalhes:UpdateWorldTrackerLines()
			scrollframe:Refresh()
		end

		--create the first line
		for i = 1, 1 do
			scrollframe:CreateLine (scroll_createline)
		end
		f.scrollframe = scrollframe
		scrollframe:SetBackdrop ({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
		scrollframe:SetBackdropColor (0, 0, 0, 0)

		--> get tables used inside the combat parser
		local cooldownListFromFramework = DetailsFramework.CooldownsAllDeffensive
		local attackCooldownsFromFramework = DetailsFramework.CooldownsAttack
		local crowdControlFromFramework = DetailsFramework.CrowdControlSpells

		local combatLog = CreateFrame ("Frame")
		combatLog:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")
		local OBJECT_TYPE_PLAYER = 0x00000400
		local OBJECT_TYPE_ENEMY = 0x00000040

		--> combat parser
		local is_player = function (flag)
			if (not flag) then
				return false
			end
			return bit.band (flag, OBJECT_TYPE_PLAYER) ~= 0
		end
		local is_enemy = function (flag)
			if (not flag) then
				return false
			end
			return bit.band (flag, OBJECT_TYPE_ENEMY) ~= 0
		end

		combatLog:SetScript ("OnEvent", function (self, event, time, token, caster_serial, caster_name, caster_flags, target_serial, target_name, target_flags, spellid, spellname, spelltype, extraSpellID, extraSpellName, extraSchool)
			local added = false

			--> defensive cooldown
			if (token == "SPELL_CAST_SUCCESS" and (cooldownListFromFramework [spellid]) and is_player (caster_flags)) then
				tinsert (CurrentShowing, 1, {SPELLTYPE_COOLDOWN, spellid, caster_name, target_name, time, false, GetTime(), caster_serial, is_enemy (caster_flags), target_serial})
				added = true

			--> offensive cooldown
			elseif (token == "SPELL_CAST_SUCCESS" and (attackCooldownsFromFramework [spellid]) and is_player (caster_flags)) then
				tinsert (CurrentShowing, 1, {SPELLTYPE_OFFENSIVE, spellid, caster_name, target_name, time, false, GetTime(), caster_serial, is_enemy (caster_flags), target_serial})
				added = true

			--> crowd control
			elseif (token == "SPELL_AURA_APPLIED" and (crowdControlFromFramework [spellid])) then
				--check if isnt a pet
				if (target_flags and is_player (target_flags)) then
					tinsert (CurrentShowing, 1, {SPELLTYPE_CROWDCONTROL, spellid, caster_name, target_name, time, false, GetTime(), caster_serial, is_enemy (caster_flags), target_serial})
					added = true
				end

			--> spell interrupt
			elseif (token == "SPELL_INTERRUPT") then
				tinsert (CurrentShowing, 1, {SPELLTYPE_INTERRUPT, spellid, caster_name, target_name, time, extraSpellID, GetTime(), caster_serial, is_enemy (caster_flags), target_serial})
				added = true

			end

			if (added) then
				local amountOfLines = scrollframe:GetNumFramesShown()
				local amountToShow = #CurrentShowing

				if (amountToShow > amountOfLines) then
					tremove (CurrentShowing, amountToShow)
				end
				scrollframe:Refresh()
			end

		end)

	_detalhes.Broadcaster_EventTrackerLoaded = true
	f:Hide()

end

function Details:LoadFramesForBroadcastTools()
	--> event tracker
		--> if enabled and not loaded, load it
		if (_detalhes.event_tracker.enabled and not _detalhes.Broadcaster_EventTrackerLoaded) then
			CreateEventTrackerFrame (UIParent, "DetailsEventTracker")
		end

		--> if enabled and loaded, refresh and show
		if (_detalhes.event_tracker.enabled and _detalhes.Broadcaster_EventTrackerLoaded) then
			_detalhes:UpdateEventTrackerFrame()
			DetailsEventTracker:Show()
		end

		--> if not enabled but loaded, hide it
		if (not _detalhes.event_tracker.enabled and _detalhes.Broadcaster_EventTrackerLoaded) then
			DetailsEventTracker:Hide()
		end

	--> current dps
		local bIsEnabled = _detalhes.current_dps_meter.enabled and _detalhes.current_dps_meter.arena_enabled

		--> if enabled and not loaded, load it
		if (bIsEnabled and not _detalhes.Broadcaster_CurrentDpsLoaded) then
			CreateCurrentDpsFrame (UIParent, "DetailsCurrentDpsMeter")
		end

		--> if enabled, check if can show
		if (bIsEnabled and _detalhes.Broadcaster_CurrentDpsLoaded) then
			local _, instanceType = GetInstanceInfo()
			if (instanceType == "arena") then
				--> player is inside an arena
				DetailsCurrentDpsMeter:StartForArenaMatch()
			end
		end

		--> if not enabled but loaded, hide it
		if (not bIsEnabled and _detalhes.Broadcaster_CurrentDpsLoaded) then
			DetailsCurrentDpsMeter:Hide()
		end

end

function Details:OpenCurrentRealDPSOptions (from_options_panel)

	if (not DetailsCurrentRealDPSOptions) then

		local DF = _detalhes.gump

		local f = DF:CreateSimplePanel (UIParent, 700, 400, "Details! The Current Real DPS Options", "DetailsCurrentRealDPSOptions")
		f:SetPoint ("CENTER", UIParent, "CENTER")
		f:SetScript ("OnMouseDown", nil)
		f:SetScript ("OnMouseUp", nil)
		local LibWindow = LibStub ("LibWindow-1.1")
		LibWindow.RegisterConfig (f, _detalhes.current_dps_meter.options_frame)
		LibWindow.MakeDraggable (f)
		LibWindow.RestorePosition (f)

		local options_text_template = DF:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
		local options_switch_template = DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
		local options_slider_template = DF:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
		local options_button_template = DF:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")

		local testUsing = "arena" --mythicdungeon

		--> frame strata options
			local set_frame_strata = function (_, _, strata)
				Details.current_dps_meter.frame.strata = strata
				Details:UpdateTheRealCurrentDPSFrame (testUsing)
			end
			local strataTable = {}
			strataTable [1] = {value = "BACKGROUND", label = "BACKGROUND", onclick = set_frame_strata}
			strataTable [2] = {value = "LOW", label = "LOW", onclick = set_frame_strata}
			strataTable [3] = {value = "MEDIUM", label = "MEDIUM", onclick = set_frame_strata}
			strataTable [4] = {value = "HIGH", label = "HIGH", onclick = set_frame_strata}
			strataTable [5] = {value = "DIALOG", label = "DIALOG", onclick = set_frame_strata}

		--> font options
			local set_font_shadow= function (_, _, shadow)
				Details.current_dps_meter.font_shadow = shadow
				Details:UpdateTheRealCurrentDPSFrame (testUsing)
			end
			local fontShadowTable = {}
			fontShadowTable [1] = {value = "NONE", label = "None", onclick = set_font_shadow}
			fontShadowTable [2] = {value = "OUTLINE", label = "Outline", onclick = set_font_shadow}
			fontShadowTable [3] = {value = "THICKOUTLINE", label = "Thick Outline", onclick = set_font_shadow}

			local on_select_text_font = function (self, fixed_value, value)
				Details.current_dps_meter.font_face = value
				Details:UpdateTheRealCurrentDPSFrame (testUsing)
			end

		--> options table
		local options = {

			{type = "label", get = function() return "Frame Settings:" end, text_template = DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
			--enabled
			{
				type = "toggle",
				get = function() return Details.current_dps_meter.enabled end,
				set = function (self, fixedparam, value)
					Details.current_dps_meter.enabled = not Details.current_dps_meter.enabled
					Details:LoadFramesForBroadcastTools()
				end,
				desc = "Enabled",
				name = "Enabled",
				text_template = options_text_template,
			},
			--locked
			{
				type = "toggle",
				get = function() return Details.current_dps_meter.frame.locked end,
				set = function (self, fixedparam, value)
					Details.current_dps_meter.frame.locked = not Details.current_dps_meter.frame.locked
					Details:UpdateTheRealCurrentDPSFrame (testUsing)
				end,
				desc = "Locked",
				name = "Locked",
				text_template = options_text_template,
			},
			--showtitle
			{
				type = "toggle",
				get = function() return Details.current_dps_meter.frame.show_title end,
				set = function (self, fixedparam, value)
					Details.current_dps_meter.frame.show_title = not Details.current_dps_meter.frame.show_title
					Details:UpdateTheRealCurrentDPSFrame (testUsing)
				end,
				desc = "Show Title",
				name = "Show Title",
				text_template = options_text_template,
			},
			--backdrop color
			{
				type = "color",
				get = function()
					return {Details.current_dps_meter.frame.backdrop_color[1], Details.current_dps_meter.frame.backdrop_color[2], Details.current_dps_meter.frame.backdrop_color[3], Details.current_dps_meter.frame.backdrop_color[4]}
				end,
				set = function (self, r, g, b, a)
					local color = Details.current_dps_meter.frame.backdrop_color
					color[1], color[2], color[3], color[4] = r, g, b, a
					Details:UpdateTheRealCurrentDPSFrame (testUsing)
				end,
				desc = "Backdrop Color",
				name = "Backdrop Color",
				text_template = options_text_template,
			},
			--statra
			{
				type = "select",
				get = function() return Details.current_dps_meter.frame.strata end,
				values = function() return strataTable end,
				name = "Frame Strata"
			},
			--width
			{
				type = "range",
				get = function() return Details.current_dps_meter.frame.width end,
				set = function (self, fixedparam, value)
					Details.current_dps_meter.frame.width = value
					Details:UpdateTheRealCurrentDPSFrame (testUsing)
				end,
				min = 1,
				max = 300,
				step = 1,
				name = "Width",
				text_template = options_text_template,
			},
			--height
			{
				type = "range",
				get = function() return Details.current_dps_meter.frame.height end,
				set = function (self, fixedparam, value)
					Details.current_dps_meter.frame.height = value
					Details:UpdateTheRealCurrentDPSFrame (testUsing)
				end,
				min = 1,
				max = 300,
				step = 1,
				name = "Height",
				text_template = options_text_template,
			},

			{type = "breakline"},
			{type = "label", get = function() return "Enabled On:" end, text_template = DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
			--arenas
			{
				type = "toggle",
				get = function() return Details.current_dps_meter.arena_enabled end,
				set = function (self, fixedparam, value)
					Details.current_dps_meter.arena_enabled = not Details.current_dps_meter.arena_enabled
					Details:LoadFramesForBroadcastTools()
				end,
				name = "Arena Matches",
				text_template = options_text_template,
			},

			{type = "breakline"},
			{type = "label", get = function() return "Text Settings:" end, text_template = DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
			--font size
			{
				type = "range",
				get = function() return Details.current_dps_meter.font_size end,
				set = function (self, fixedparam, value)
					Details.current_dps_meter.font_size = value
					Details:UpdateTheRealCurrentDPSFrame (testUsing)
				end,
				min = 4,
				max = 32,
				step = 1,
				name = "Font Size",
				text_template = options_text_template,
			},
			--font color
			{
				type = "color",
				get = function()
					return {Details.current_dps_meter.font_color[1], Details.current_dps_meter.font_color[2], Details.current_dps_meter.font_color[3], Details.current_dps_meter.font_color[4]}
				end,
				set = function (self, r, g, b, a)
					local color = Details.current_dps_meter.font_color
					color[1], color[2], color[3], color[4] = r, g, b, a
					Details:UpdateTheRealCurrentDPSFrame (testUsing)
				end,
				desc = "Font Color",
				name = "Font Color",
				text_template = options_text_template,
			},
			--font shadow
			{
				type = "select",
				get = function() return Details.current_dps_meter.font_shadow end,
				values = function() return fontShadowTable end,
				name = "Font Shadow"
			},
			--font face
			{
				type = "select",
				get = function() return Details.current_dps_meter.font_face end,
				values = function() return DF:BuildDropDownFontList (on_select_text_font) end,
				name = "Font Face",
				text_template = options_text_template,
			},


		}

		DF:BuildMenu (f, options, 7, -30, 500, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

		f:SetScript ("OnHide" , function()
			if (DetailsCurrentDpsMeter) then
				--> check if can hide the main frame as well
				--> we force show the main frame for the user see the frame while editing the options
				local _, instanceType = GetInstanceInfo()
				if (instanceType ~= "arena") then
					DetailsCurrentDpsMeter:Hide()
				end
			end

			--> reopen the options panel
			if (f.FromOptionsPanel) then
				C_Timer:After (0.2, function()
					Details:OpenOptionsWindow(Details:GetInstance(1))
				end)
			end
		end)

	end

	--> check if the frame was been created
	if (not DetailsCurrentDpsMeter) then
		CreateCurrentDpsFrame (UIParent, "DetailsCurrentDpsMeter")
	end

	--> show the options
	DetailsCurrentRealDPSOptions:Show()
	DetailsCurrentRealDPSOptions:RefreshOptions()
	DetailsCurrentRealDPSOptions.FromOptionsPanel = from_options_panel

	--> start the frame for viewing while editing the options
	DetailsCurrentDpsMeter:StartForArenaMatch()

end

function Details:OpenEventTrackerOptions (from_options_panel)

	if (not DetailsEventTrackerOptions) then

		local DF = _detalhes.gump

		local f = DF:CreateSimplePanel (UIParent, 700, 400, "Details! Event Tracker Options", "DetailsEventTrackerOptions")
		f:SetPoint ("CENTER", UIParent, "CENTER")
		f:SetScript ("OnMouseDown", nil)
		f:SetScript ("OnMouseUp", nil)
		local LibWindow = LibStub ("LibWindow-1.1")
		LibWindow.RegisterConfig (f, _detalhes.event_tracker.options_frame)
		LibWindow.MakeDraggable (f)
		LibWindow.RestorePosition (f)

		local options_text_template = DF:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
		local options_dropdown_template = DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
		local options_switch_template = DF:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
		local options_slider_template = DF:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
		local options_button_template = DF:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")

		--> frame strata options
			local set_frame_strata = function (_, _, strata)
				Details.event_tracker.frame.strata = strata
				Details:UpdateEventTrackerFrame()
			end
			local strataTable = {}
			strataTable [1] = {value = "BACKGROUND", label = "BACKGROUND", onclick = set_frame_strata}
			strataTable [2] = {value = "LOW", label = "LOW", onclick = set_frame_strata}
			strataTable [3] = {value = "MEDIUM", label = "MEDIUM", onclick = set_frame_strata}
			strataTable [4] = {value = "HIGH", label = "HIGH", onclick = set_frame_strata}
			strataTable [5] = {value = "DIALOG", label = "DIALOG", onclick = set_frame_strata}

		--> font options
			local set_font_shadow= function (_, _, shadow)
				Details.event_tracker.font_shadow = shadow
				Details:UpdateEventTrackerFrame()
			end
			local fontShadowTable = {}
			fontShadowTable [1] = {value = "NONE", label = "None", onclick = set_font_shadow}
			fontShadowTable [2] = {value = "OUTLINE", label = "Outline", onclick = set_font_shadow}
			fontShadowTable [3] = {value = "THICKOUTLINE", label = "Thick Outline", onclick = set_font_shadow}

			local on_select_text_font = function (self, fixed_value, value)
				Details.event_tracker.font_face = value
				Details:UpdateEventTrackerFrame()
			end

		--> texture options
			local set_bar_texture = function (_, _, value)
				Details.event_tracker.line_texture = value
				Details:UpdateEventTrackerFrame()
			end

			local SharedMedia = LibStub:GetLibrary ("LibSharedMedia-3.0")
			local textures = SharedMedia:HashTable ("statusbar")
			local texTable = {}
			for name, texturePath in _pairs (textures) do
				texTable [#texTable + 1] = {value = name, label = name, statusbar = texturePath, onclick = set_bar_texture}
			end
			_table_sort (texTable, function (t1, t2) return t1.label < t2.label end)

		--> options table
		local options = {

			{type = "label", get = function() return "Frame Settings:" end, text_template = DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
			--enabled
			{
				type = "toggle",
				get = function() return Details.event_tracker.enabled end,
				set = function (self, fixedparam, value)
					Details.event_tracker.enabled = not Details.event_tracker.enabled
					Details:LoadFramesForBroadcastTools()
				end,
				desc = "Enabled",
				name = "Enabled",
				text_template = options_text_template,
			},
			--locked
			{
				type = "toggle",
				get = function() return Details.event_tracker.frame.locked end,
				set = function (self, fixedparam, value)
					Details.event_tracker.frame.locked = not Details.event_tracker.frame.locked
					Details:UpdateEventTrackerFrame()
				end,
				desc = "Locked",
				name = "Locked",
				text_template = options_text_template,
			},
			--showtitle
			{
				type = "toggle",
				get = function() return Details.event_tracker.frame.show_title end,
				set = function (self, fixedparam, value)
					Details.event_tracker.frame.show_title = not Details.event_tracker.frame.show_title
					Details:UpdateEventTrackerFrame()
				end,
				desc = "Show Title",
				name = "Show Title",
				text_template = options_text_template,
			},
			--backdrop color
			{
				type = "color",
				get = function()
					return {Details.event_tracker.frame.backdrop_color[1], Details.event_tracker.frame.backdrop_color[2], Details.event_tracker.frame.backdrop_color[3], Details.event_tracker.frame.backdrop_color[4]}
				end,
				set = function (self, r, g, b, a)
					local color = Details.event_tracker.frame.backdrop_color
					color[1], color[2], color[3], color[4] = r, g, b, a
					Details:UpdateEventTrackerFrame()
				end,
				desc = "Backdrop Color",
				name = "Backdrop Color",
				text_template = options_text_template,
			},
			--statra
			{
				type = "select",
				get = function() return Details.event_tracker.frame.strata end,
				values = function() return strataTable end,
				name = "Frame Strata"
			},
			{type = "breakline"},
			{type = "label", get = function() return "Line Settings:" end, text_template = DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
			--line height
			{
				type = "range",
				get = function() return Details.event_tracker.line_height end,
				set = function (self, fixedparam, value)
					Details.event_tracker.line_height = value
					Details:UpdateEventTrackerFrame()
				end,
				min = 4,
				max = 32,
				step = 1,
				name = "Line Height",
				text_template = options_text_template,
			},
			--line texture
			{
				type = "select",
				get = function() return Details.event_tracker.line_texture end,
				values = function() return texTable end,
				name = "Line Texture",
			},
			--line color
			{
				type = "color",
				get = function()
					return {Details.event_tracker.line_color[1], Details.event_tracker.line_color[2], Details.event_tracker.line_color[3], Details.event_tracker.line_color[4]}
				end,
				set = function (self, r, g, b, a)
					local color = Details.event_tracker.line_color
					color[1], color[2], color[3], color[4] = r, g, b, a
					Details:UpdateEventTrackerFrame()
				end,
				desc = "Line Color",
				name = "Line Color",
				text_template = options_text_template,
			},
			--font size
			{
				type = "range",
				get = function() return Details.event_tracker.font_size end,
				set = function (self, fixedparam, value)
					Details.event_tracker.font_size = value
					Details:UpdateEventTrackerFrame()
				end,
				min = 4,
				max = 32,
				step = 1,
				name = "Font Size",
				text_template = options_text_template,
			},
			--font color
			{
				type = "color",
				get = function()
					return {Details.event_tracker.font_color[1], Details.event_tracker.font_color[2], Details.event_tracker.font_color[3], Details.event_tracker.font_color[4]}
				end,
				set = function (self, r, g, b, a)
					local color = Details.event_tracker.font_color
					color[1], color[2], color[3], color[4] = r, g, b, a
					Details:UpdateEventTrackerFrame()
				end,
				desc = "Font Color",
				name = "Font Color",
				text_template = options_text_template,
			},
			--font shadow
			{
				type = "select",
				get = function() return Details.event_tracker.font_shadow end,
				values = function() return fontShadowTable end,
				name = "Font Shadow"
			},
			--font face
			{
				type = "select",
				get = function() return Details.event_tracker.font_face end,
				values = function() return DF:BuildDropDownFontList (on_select_text_font) end,
				name = "Font Face",
				text_template = options_text_template,
			},
		}

		DF:BuildMenu (f, options, 7, -30, 500, true, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

		f:SetScript ("OnHide", function()
			--> reopen the options panel
			if (f.FromOptionsPanel) then
				C_Timer:After (0.2, function()
					Details:OpenOptionsWindow(Details:GetInstance(1))
				end)
			end
		end)
	end

	DetailsEventTrackerOptions:RefreshOptions()
	DetailsEventTrackerOptions:Show()

	DetailsEventTrackerOptions.FromOptionsPanel = from_options_panel

end


function _detalhes:FormatBackground (f, bgAlpha, backdropAlpha)
	f:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]], tileSize = 64, tile = true})
	f:SetBackdropColor (.5, .5, .5, backdropAlpha or .5)
	f:SetBackdropBorderColor (0, 0, 0, 1)

	if (not f.__background) then
		f.__background = f:CreateTexture (nil, "background")
	end

	f.__background:SetTexture ([[Interface\AddOns\Details\images\background]], true)
	f.__background:SetAlpha (bgAlpha or 0.7)
	f.__background:SetVertexColor (0.27, 0.27, 0.27)
	f.__background:SetVertTile (true)
	f.__background:SetHorizTile (true)
	f.__background:SetAllPoints()
end




--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> dump table frame

function Details:DumpTable (t)
	return Details:Dump (t)
end

function Details:Dump (t)
	if (not DetailsDumpFrame) then
		DetailsDumpFrame = DetailsFramework:CreateSimplePanel (UIParent)
		DetailsDumpFrame:SetSize (700, 600)
		DetailsDumpFrame:SetTitle ("Details! Dump Table [|cFFFF3333Ready Only|r]")

		local text_editor = DetailsFramework:NewSpecialLuaEditorEntry (DetailsDumpFrame, 680, 560, "Editbox", "$parentEntry", true)
		text_editor:SetPoint ("TOPLEFT", DetailsDumpFrame, "TOPLEFT", 10, -30)

		reskin_code_editor (text_editor)
	end

	t = t or {}
	local s = Details.table.dump (t)
	DetailsDumpFrame.Editbox:SetText (s)
	DetailsDumpFrame:Show()
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> damage scroll

function Details:ScrollDamage()
	if (not DetailsScrollDamage) then
		local DF = DetailsFramework
		DetailsScrollDamage = DetailsFramework:CreateSimplePanel (UIParent)
		DetailsScrollDamage:SetSize (707, 505)
		DetailsScrollDamage:SetTitle ("Details! Scroll Damage")
		DetailsScrollDamage.Data = {}
		DetailsScrollDamage:ClearAndSetPoint ("LEFT", UIParent, "LEFT", 10, 0)
		DetailsScrollDamage:Hide()

		local scroll_width = 675
		local scroll_height = 450
		local scroll_lines = 21
		local scroll_line_height = 20

		local backdrop_color = {.2, .2, .2, 0.2}
		local backdrop_color_on_enter = {.8, .8, .8, 0.4}
		local backdrop_color_is_critical = {.4, .4, .2, 0.2}
		local backdrop_color_is_critical_on_enter = {1, 1, .8, 0.4}

		local y = -15
		local headerY = y - 15
		local scrollY = headerY - 20

		--header
		local headerTable = {
			{text = "Icon", width = 32},
			{text = "Spell Name", width = 180},
			{text = "Amount", width = 80},

			{text = "Time", width = 80},
			{text = "Token", width = 130},
			{text = "Spell ID", width = 80},
			{text = "School", width = 80},
		}
		local headerOptions = {
			padding = 2,
		}

		DetailsScrollDamage.Header = DetailsFramework:CreateHeader (DetailsScrollDamage, headerTable, headerOptions)
		DetailsScrollDamage.Header:SetPoint ("TOPLEFT", DetailsScrollDamage, "TOPLEFT", 5, headerY)

		local scroll_refresh = function (self, data, offset, total_lines)

			local ToK = _detalhes:GetCurrentToKFunction()

			for i = 1, total_lines do
				local index = i + offset
				local spellTable = data [index]

				if (spellTable) then

					local line = self:GetLine (i)
					local time, token, sourceSerial, sourceName, sourceFlag, targetSerial, targetName, targetFlag, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical = unpack (spellTable)

					local spellName, _, spellIcon

					if (token ~= "SWING_DAMAGE") then
						spellName, _, spellIcon = GetSpellInfo (spellID)
					else
						spellName, _, spellIcon = GetSpellInfo (1)
					end

					line.SpellID = spellID
					line.IsCritical = isCritical

					if (isCritical) then
						line:SetBackdropColor (unpack (backdrop_color_is_critical))
					else
						line:SetBackdropColor (unpack (backdrop_color))
					end

					if (spellName) then
						line.Icon:SetTexture (spellIcon)
						line.Icon:SetTexCoord (.1, .9, .1, .9)

						line.DamageText.text = isCritical and "|cFFFFFF00" .. ToK (_, amount) or ToK (_, amount)
						line.TimeText.text = format ("%.4f", time - DetailsScrollDamage.Data.Started)
						line.TokenText.text = token:gsub ("SPELL_", "")
						line.SchoolText.text = _detalhes:GetSpellSchoolFormatedName (school)
						line.SpellIDText.text = spellID
						line.SpellNameText.text = spellName
					else
						line:Hide()
					end
				end
			end
		end

		local lineOnEnter = function (self)
			if (self.IsCritical) then
				self:SetBackdropColor (unpack (backdrop_color_is_critical_on_enter))
			else
				self:SetBackdropColor (unpack (backdrop_color_on_enter))
			end

			if (self.SpellID) then
				GameTooltip:SetOwner (self, "ANCHOR_TOPLEFT")
				GameTooltip:SetSpellByID (self.SpellID)
				GameTooltip:AddLine (" ")
				GameTooltip:Show()
			end
		end

		local lineOnLeave = function (self)
			if (self.IsCritical) then
				self:SetBackdropColor (unpack (backdrop_color_is_critical))
			else
				self:SetBackdropColor (unpack (backdrop_color))
			end

			GameTooltip:Hide()
		end

		local scroll_createline = function (self, index)

			local line = CreateFrame ("button", "$parentLine" .. index, self)
			line:SetPoint ("TOPLEFT", self, "TOPLEFT", 1, -((index-1)*(scroll_line_height+1)) - 1)
			line:SetSize (scroll_width - 2, scroll_line_height)

			line:SetBackdrop ({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
			line:SetBackdropColor (unpack (backdrop_color))

			DF:Mixin (line, DF.HeaderFunctions)

			line:SetScript ("OnEnter", lineOnEnter)
			line:SetScript ("OnLeave", lineOnLeave)

			--icon
			local icon = line:CreateTexture ("$parentSpellIcon", "overlay")
			icon:SetSize (scroll_line_height - 2, scroll_line_height - 2)

			--spellname
			local spellNameText = DF:CreateLabel (line)

			--damage
			local damageText = DF:CreateLabel (line)

			--time
			local timeText = DF:CreateLabel (line)

			--token
			local tokenText = DF:CreateLabel (line)

			--spell ID
			local spellIDText = DF:CreateLabel (line)

			--school
			local schoolText = DF:CreateLabel (line)

			line:AddFrameToHeaderAlignment (icon)
			line:AddFrameToHeaderAlignment (spellNameText)
			line:AddFrameToHeaderAlignment (damageText)
			line:AddFrameToHeaderAlignment (timeText)
			line:AddFrameToHeaderAlignment (tokenText)
			line:AddFrameToHeaderAlignment (spellIDText)
			line:AddFrameToHeaderAlignment (schoolText)

			line:AlignWithHeader (DetailsScrollDamage.Header, "left")

			line.Icon = icon
			line.DamageText = damageText
			line.TimeText = timeText
			line.TokenText = tokenText
			line.SchoolText = schoolText
			line.SpellIDText = spellIDText
			line.SpellNameText = spellNameText

			return line
		end

		local damageScroll = DF:CreateScrollBox (DetailsScrollDamage, "$parentSpellScroll", scroll_refresh, DetailsScrollDamage.Data, scroll_width, scroll_height, scroll_lines, scroll_line_height)
		DF:ReskinSlider (damageScroll)
		damageScroll:SetPoint ("TOPLEFT", DetailsScrollDamage, "TOPLEFT", 5, scrollY)

		--create lines
		for i = 1, scroll_lines do
			damageScroll:CreateLine (scroll_createline)
		end

		local combatLogReader = CreateFrame ("Frame")
		local playerSerial = UnitGUID ("player")

		combatLogReader:SetScript ("OnEvent", function (self, _, timew, token, sourceSerial, sourceName, sourceFlag, targetSerial, targetName, targetFlag, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical)
			if (sourceSerial == playerSerial) then
				if (token == "SPELL_DAMAGE" or token == "SPELL_PERIODIC_DAMAGE" or token == "RANGE_DAMAGE" or token == "DAMAGE_SHIELD") then
					if (not DetailsScrollDamage.Data.Started) then
						DetailsScrollDamage.Data.Started = time()
					end
					tinsert (DetailsScrollDamage.Data, 1, {timew, token, sourceSerial, sourceName, sourceFlag, targetSerial, targetName, targetFlag, spellID, spellName, spellType, amount, overKill or 0, school or 1, resisted or 0, blocked or 0, absorbed or 0, isCritical})
					damageScroll:Refresh()

				elseif (token == "SWING_DAMAGE") then
				--	amount, overkill, school, resisted, blocked, absorbed, critical, glacing, crushing, isoffhand = spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical
				--	tinsert (DetailsScrollDamage.Data, 1, {timew, token, sourceSerial, sourceName, sourceFlag, targetSerial, targetName, targetFlag, spellID, spellName, spellType, amount, overKill, school, resisted, blocked, absorbed, isCritical})
				--	damageScroll:Refresh()
				end
			end
		end)

		DetailsScrollDamage:SetScript ("OnShow", function()
			wipe (DetailsScrollDamage.Data)
			damageScroll:Refresh()
			combatLogReader:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")
		end)

		DetailsScrollDamage:SetScript ("OnHide", function()
			combatLogReader:UnregisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")
		end)
	end

	DetailsScrollDamage:Show()
end

---------------------------------------------------------------------------------------------------------------------------------------
--> import export window

--show a window with a big text editor and 2 buttons: okay and cancel.
--cancel button always closes the window and okay calls the comfirm function passed in the argument
--default text is the text shown show the window is show()

function _detalhes:DumpString (text)
	_detalhes:ShowImportWindow (text)
end

function _detalhes:ShowImportWindow (defaultText, confirmFunc, titleText)
	if (not DetailsExportWindow) then
		local importWindow = DetailsFramework:CreateSimplePanel (UIParent, 800, 610, "Details! Dump String", "DetailsExportWindow")
		importWindow:SetFrameStrata ("FULLSCREEN")
		importWindow:SetPoint ("CENTER")
		DetailsFramework:ApplyStandardBackdrop (importWindow, false, 1.2)

		local importTextEditor = DetailsFramework:NewSpecialLuaEditorEntry (importWindow, 780, 540, "ImportEditor", "$parentEditor", true)
		importTextEditor:SetPoint ("TOPLEFT", importWindow, "TOPLEFT", 10, -30)
		reskin_code_editor (importTextEditor)

		--import button
		local onClickImportButton = function()
			if (DetailsExportWindow.ConfirmFunction) then
				DetailsFramework:Dispatch (DetailsExportWindow.ConfirmFunction, importTextEditor:GetText())
			end
			importWindow:Hide()
		end
		local okayButton = DetailsFramework:CreateButton (importTextEditor, onClickImportButton, 120, 20, "Okay", -1, nil, nil, nil, nil, nil, _detalhes.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"), _detalhes.gump:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")) --> localize-me
		okayButton:SetIcon ([[Interface\BUTTONS\UI-Panel-BiggerButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})

		--cancel button
		local cancelButton = DetailsFramework:CreateButton (importTextEditor, function() importWindow:Hide() end, 120, 20, "Cancel", -1, nil, nil, nil, nil, nil, _detalhes.gump:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE"), _detalhes.gump:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")) --> localize-me
		cancelButton:SetIcon ([[Interface\BUTTONS\UI-Panel-MinimizeButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})

		okayButton:SetPoint ("TOPRIGHT", importTextEditor, "BOTTOMRIGHT", 0, -10)
		cancelButton:SetPoint ("RIGHT", okayButton, "LEFT", -20, 0)

	end

	DetailsExportWindow.ConfirmFunction = confirmFunc
	DetailsExportWindow.ImportEditor:SetText (defaultText or "")
	DetailsExportWindow:Show()

	titleText = titleText or "Details! Dump String"
	DetailsExportWindow.Title:SetText (titleText)

	C_Timer:After (.2, function()
		DetailsExportWindow.ImportEditor:SetFocus (true)
		DetailsExportWindow.ImportEditor.editbox:HighlightText (0)
	end)
end



