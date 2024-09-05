-- PlayerPlate acts like Blizz self nameplate but doesn't move on screen

local addonName, NephilistNameplates = ...

local PlayerPlate = NephilistNameplates.PlayerPlate
local DriverFrame = NephilistNameplates.DriverFrame

local function round(x) 
	return floor(x + 0.5)
end

--[[ PlayerPlate ]]--

function PlayerPlate:OnLoad()
	self:SetSize(140, 20)
	self:SetScript("OnEvent", self.OnEvent)
	self:RegisterEvent("ADDON_LOADED")
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnDragStart", self.OnDragStart)
	self:SetScript("OnDragStop", self.OnDragStop)
	self:SetScript("OnClick", self.OnClick)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("RightButtonUp")
end

function PlayerPlate:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == addonName then
			self:ADDON_LOADED()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		self:SetShown()
	elseif event == "PLAYER_REGEN_ENABLED" then
		self:SetOutOfCombat()
	end
end

function PlayerPlate:ADDON_LOADED()
	DriverFrame:NAME_PLATE_CREATED(self)
	self.UnitFrame:OnNamePlateAdded("player")
	self:Update()
end

function PlayerPlate:Update()
	-- Called by PlayerPlate:ADDON_LOADED, DriverFrame:Update, 
	-- and options panel controls
	local self = PlayerPlate
	local options = NephilistNameplatesOptions
	if options.ShowPlayerPlate then 
		self.inUse = true
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")

		self:SetPosition(options.PlayerPlatePosition)
		self:SetLocked(options.PlayerPlateLocked)
		self.outOfCombatAlpha = options.PlayerPlateOutOfCombatAlpha

		self.UnitFrame:Update()
	else
		self.inUse = false
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:UpdateShown()
end

function PlayerPlate:SetPosition(point) 
	self:ClearAllPoints()
	self:SetPoint(unpack(point))
end

function PlayerPlate:SetLocked(shouldLock)
	-- Called by PlayerPlate:Update() and [options panel checkbutton]
	if shouldLock then
		self:EnableMouse(false)
	else
		self:EnableMouse(true)
	end
	self.isLocked = shouldLock
end

function PlayerPlate:UpdateShown()
	-- Called by PlayerPlate:Update()
	if self.inUse then
		self:Show()
		if not InCombatLockdown() then
			self:SetOutOfCombat()
		else
			self:SetShown()
		end
	else
		self:Hide()
	end
end

function PlayerPlate:SetOutOfCombat()
	self:SetAlpha(self.outOfCombatAlpha)
end

function PlayerPlate:SetShown()
	self:SetAlpha(1)
end

function PlayerPlate:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	local strings = NephilistNameplates.Strings
	GameTooltip:AddLine(strings.NephilistNameplates, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.g)
	GameTooltip:AddLine(strings.DragToMove)
	GameTooltip:Show()
end

function PlayerPlate:OnLeave()
	GameTooltip:Hide()
end

function PlayerPlate:OnDragStart()
	self:StartMoving()
end

function PlayerPlate:OnDragStop()
	self:StopMovingOrSizing()
	self:SetUserPlaced(false)
	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
	xOfs, yOfs = round(xOfs), round(yOfs)
	NephilistNameplatesOptions.PlayerPlatePosition = {point, relativeTo, relativePoint, xOfs, yOfs}
end

function PlayerPlate:OnClick(button)
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	if button == "RightButton" then
		Settings.OpenToCategory(addonName)
	end
end

do
	PlayerPlate:OnLoad()
end
