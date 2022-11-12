local addonName, NephilistNameplates = ...

--[[ Player plate ]]--

-- PlayerPlate is static frame that acts like Blizz nameplate with self.unit = "player"

local PlayerPlate = NephilistNameplates.PlayerPlate
local DriverFrame = NephilistNameplates.DriverFrame

do

	PlayerPlate:SetWidth(140)
	PlayerPlate:SetHeight(20)
	PlayerPlate:EnableMouse(false)
	PlayerPlate:SetPoint("TOP", UIParent, "CENTER", 0, -100)  -- temporary

--	PlayerPlate.texture = PlayerPlate:CreateTexture()
--	PlayerPlate.texture:SetAllPoints()
--	PlayerPlate.texture:SetColorTexture(0, 1, 0, 0.5)
end

function PlayerPlate:OnEvent(event, ...)
	if event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == addonName then
			self:ADDON_LOADED()
		end
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
	local unitFrame = self.UnitFrame
	unitFrame:SetOptions()
	unitFrame:UpdateAll()
end


-- function PlayerPlate:SetPosition() end
-- function PlayerPlate:Unlock() end
-- function PlayerPlate:Lock() end
-- function PlayerPlate:OnDragStart() end
-- function PlayerPlate:OnDragStop() end
-- function PlayerPlate:OnClick() end

