local addonName, NephilistNameplates = ...

--[[ Player plate ]]--

-- PlayerPlate is static frame that acts like Blizz nameplate frame with self.unit = "player"

local PlayerPlate = NephilistNameplates.PlayerPlate
local DriverFrame = NephilistNameplates.DriverFrame

do
--	PlayerPlate.texture = PlayerPlate:CreateTexture()
--	PlayerPlate.texture:SetAllPoints()
--	PlayerPlate.texture:SetColorTexture(0, 1, 0, 0.5)
	PlayerPlate:SetWidth(140)
	PlayerPlate:SetHeight(20)
end

function PlayerPlate:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == addonName then
			self:ADDON_LOADED()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		-- Called before InCombatLockdown() true
		self:SetShown()
	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Called before InCombatLockdown() false
		self:SetOutOfCombat()
	end
end
PlayerPlate:SetScript("OnEvent", PlayerPlate.OnEvent)
PlayerPlate:RegisterEvent("ADDON_LOADED")

function PlayerPlate:ADDON_LOADED()
	DriverFrame:OnNamePlateCreated(self)
	self.UnitFrame:SetUnit("player")
	self:Update()
end

function PlayerPlate:Update()
	-- Called by PlayerPlate:ADDON_LOADED(), DriverFrame:UpdateNamePlateOptions()
	-- and options panel controls
	local options = NephilistNameplatesOptions
	-- if options.ShowPlayerPlate then 
	if true then
		self.inUse = true
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")

		self:SetPosition(options.PlayerPlatePosition)
		self:SetLocked(options.PlayerPlateLocked)
		self.outOfCombatAlpha = options.PlayerPlateOutOfCombatAlpha

		self.UnitFrame:SetOptions()
		self.UnitFrame:UpdateAll()
	else
		self.inUse = false
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:UpdateShown()
end

function PlayerPlate:SetPosition(point) 
	PlayerPlate:ClearAllPoints();
	PlayerPlate:SetPoint(unpack(point))
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
	if self.isLocked then 
		self:SetAlpha(self.outOfCombatAlpha)
	else
		self:SetShown()
	end
end

function PlayerPlate:SetShown()
	self:SetAlpha(1)
end

function PlayerPlate:SetLocked(isLocked)
	-- Called by PlayerPlate:Update() and [options panel control]
	self.isLocked = isLocked
	if isLocked then
		self:EnableMouse(false)
	else
		self:EnableMouse(true)
	end
end

-- function PlayerPlate:OnDragStart() end
-- function PlayerPlate:OnDragStop() end
-- function PlayerPlate:OnClick() end

