
local math_floor = math.floor
local CreateFrame = CreateFrame
local GetTime = GetTime
local GetCursorPosition = GetCursorPosition

local _detalhes = 		_G._detalhes
local gump = 			_detalhes.gump

function _detalhes:CreateWindowCloseButton (f, anchor, onClick)
	f.Close = CreateFrame ("button", "$parentCloseButton", f)
	f.Close:SetPoint ("RIGHT", anchor, "RIGHT", -2, 0)
	f.Close:SetSize (16, 16)
	f.Close:SetNormalTexture (gump.folder .. "icons")
	f.Close:SetHighlightTexture (gump.folder .. "icons")
	f.Close:SetPushedTexture (gump.folder .. "icons")
	f.Close:GetNormalTexture():SetTexCoord (0, 16/128, 0, 1)
	f.Close:GetHighlightTexture():SetTexCoord (0, 16/128, 0, 1)
	f.Close:GetPushedTexture():SetTexCoord (0, 16/128, 0, 1)
	f.Close:SetAlpha (0.7)
	f.Close:SetScript ("OnClick", onClick)
end

function _detalhes:CreateWindowTitleBar (parent, name)
	local titlebar = CreateFrame ("frame", name, parent)
	titlebar:SetPoint ("topleft", parent, "topleft", 2, -3)
	titlebar:SetPoint ("topright", parent, "topright", -2, -3)
	titlebar:SetHeight (20)
	titlebar:SetBackdrop ({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\AddOns\Details\images\background]], tileSize = 64, tile = true})
	titlebar:SetBackdropColor (.5, .5, .5, 1)
	titlebar:SetBackdropBorderColor (0, 0, 0, 1)
	return titlebar
end


function gump:NewDetailsButton (parent, container, instancia, func, param1, param2, w, h, pic_up, pic_down, pic_disabled, pic_highlight, options, FrameName)

	if (not parent) then
		return nil
	end

	w = w or 16
	h = h or 16
	options = options or {}

	local new_button = CreateFrame ("Button", FrameName, parent)

	new_button:SetWidth (w)
	new_button:SetHeight (h)

	if (not pic_down and pic_up) then
		pic_down = pic_up
	end
	if (not pic_disabled and pic_up) then
		pic_disabled = pic_up
	end
	if (not pic_highlight and pic_up) then
		pic_highlight = pic_up
	end

	new_button:SetNormalTexture (pic_up)
	new_button:SetPushedTexture (pic_down)
	new_button:SetDisabledTexture (pic_disabled)
	new_button:SetHighlightTexture (pic_highlight, "ADD")

	local new_text = new_button:CreateFontString (nil, "OVERLAY", "GameFontNormal")
	new_text:SetPoint ("CENTER", new_button, "CENTER")
	new_button.text = new_text

	new_button.supportFrame = CreateFrame ("Frame", nil, new_button)
	new_button.supportFrame:SetPoint ("TOPLEFT", new_button, "TOPLEFT")
	new_button.supportFrame:SetPoint ("BOTTOMRIGHT", new_button, "BOTTOMRIGHT")
	new_button.supportFrame:SetFrameLevel (new_button:GetFrameLevel()+1)

	new_button.supportFrame.disable_overlay = new_button.supportFrame:CreateTexture (nil, "overlay")
	new_button.supportFrame.disable_overlay:SetTexture ("Interface\\AddOns\\Details\\images\\button_disable_overlay")
	new_button.supportFrame.disable_overlay:SetPoint ("TOPLEFT", new_button.supportFrame, "TOPLEFT")
	new_button.supportFrame.disable_overlay:SetPoint ("BOTTOMRIGHT", new_button.supportFrame, "BOTTOMRIGHT")
	new_button.supportFrame.disable_overlay:Hide()

	local rightFunction = options.rightFunc

	new_button:SetScript ("OnDisable", function()
		new_button.supportFrame.disable_overlay:Show()
	end)
	new_button:SetScript ("OnEnable", function()
		new_button.supportFrame.disable_overlay:Hide()
	end)

	new_button.funcParam1 = param1
	new_button.funcParam2 = param2
	new_button.options = options

	new_button.enter = false

	new_button:SetScript ("OnMouseDown", function(self, button)
		if (not self:IsEnabled()) then
			return
		end

		self.mouse_down = GetTime()
		local x, y = GetCursorPosition()
		self.x = math_floor (x)
		self.y = math_floor (y)

		if (container) then
			if (container:IsMovable() and not container.isLocked) then
				container:StartMoving()
				container.isMoving = true
			end
		end

		if (new_button.texture) then
			new_button.texture:SetTexCoord (0, 1, 0.5, 0.74609375)
		end

		if (options.OnGrab and options.OnGrab == "PassClick") then
			if (rightFunction) then
				if (button == "LeftButton") then
					func (new_button.funcParam1, new_button.funcParam2)
				else
					rightFunction.func (rightFunction.param1, rightFunction.param2)
				end
			else
				func (new_button.funcParam1, new_button.funcParam2)
			end
		end
	end)

	new_button:SetScript ("OnMouseUp", function (self, button)
		if (not self:IsEnabled()) then
			return
		end

		if (container) then
			if (container.isMoving) then
				container:StopMovingOrSizing()
				container.isMoving = false
			end
		end

		if (new_button.texture) then
			if (new_button.enter) then
				new_button.texture:SetTexCoord (0, 1, 0.25, 0.49609375)
			else
				new_button.texture:SetTexCoord (0, 1, 0, 0.24609375)
			end
		end

		local x, y = GetCursorPosition()
		x = math_floor (x)
		y = math_floor (y)
		if ((self.mouse_down+0.4 > GetTime() and (x == self.x and y == self.y)) or (x == self.x and y == self.y)) then
			if (rightFunction) then
				if (button == "LeftButton") then
					func (new_button.funcParam1, new_button.funcParam2)
				else
					rightFunction.func (rightFunction.param1, rightFunction.param2)
				end
			else
				func (new_button.funcParam1, new_button.funcParam2)
			end
		end
	end)

	new_button.tooltip = nil

	new_button:SetScript ("OnEnter", function()

		new_button.enter = true

		if (new_button.tooltip) then
			GameCooltip:Reset()
			GameCooltip:SetType ("tooltip")
			GameCooltip:SetColor ("main", "transparent")
			GameCooltip:AddLine (new_button.tooltip)
			GameCooltip:SetOwner (new_button)
			GameCooltip:ShowCooltip()
		end

		if (new_button.texture) then
			new_button.texture:SetTexCoord (0, 1, 0.25+(0.0078125/2), 0.5+(0.0078125/2))
		end

		if (new_button.MouseOnEnterHook) then
			new_button.MouseOnEnterHook (new_button)
		end
	end)

	new_button:SetScript ("OnLeave", function()

		new_button.enter = false

		if (new_button.tooltip) then
			_detalhes.popup:ShowMe (false)
		end

		if (new_button.texture) then
			new_button.texture:SetTexCoord (0, 1, 0, 0.24609375)
		end

		if (new_button.MouseOnLeaveHook) then
			new_button.MouseOnLeaveHook (new_button)
		end
	end)

	function new_button:ChangeIcon (icon1, icon2, icon3, icon4)
		new_button:SetNormalTexture (icon1)
		new_button:SetPushedTexture (icon2)
		new_button:SetDisabledTexture (icon3)
		new_button:SetHighlightTexture (icon4, "ADD")
	end

	function new_button:InstallCustomTexture (texture, rect)
		new_button:SetNormalTexture(nil)
		new_button:SetPushedTexture(nil)
		new_button:SetDisabledTexture(nil)
		new_button:SetHighlightTexture(nil)
		texture = texture or "Interface\\AddOns\\Details\\images\\default_button"
		new_button.texture = new_button:CreateTexture (nil, "background")

		if (not rect) then
			new_button.texture:SetAllPoints (new_button)
		else
			new_button.texture:SetPoint ("TOPLEFT", new_button, "TOPLEFT", rect.x1, rect.y1)
			new_button.texture:SetPoint ("BOTTOMRIGHT", new_button, "BOTTOMRIGHT", rect.x2, rect.y2)
		end

		new_button.texture:SetTexCoord (0, 1, 0, 0.24609375)
		new_button.texture:SetTexture (texture)
	end

	new_button.textColor = {}
	new_button.textColor.r, new_button.textColor.g, new_button.textColor.b = new_button.text:GetTextColor()

	return new_button
end
