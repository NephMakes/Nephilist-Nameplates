local addonName, NephilistNameplates = ...
local DriverFrame = NephilistNameplates.DriverFrame;
local UnitFrame = NephilistNameplates.UnitFrame


--[[ Power bar ]]--

function UnitFrame:UpdatePowerBar()
	local powerBar = self.powerBar
	if self.optionTable.showPowerBar == true then
		powerBar:Show()
		local powerType, powerToken = UnitPowerType(self.displayedUnit)
		if self.powerToken ~= powerToken or self.powerType ~= powerType then
			self.powerToken = powerToken
			self.powerType = powerType
		end
		self:UpdatePowerBarColor()
		self:UpdateMaxPower()
		self:UpdatePower()
	else
		powerBar:Hide()
	end
end

function UnitFrame:UpdatePowerBarColor()
	local powerBar = self.powerBar
	local powerToken = self.powerToken
	local info = PowerBarColor[powerToken] or {r = 0.3, g = 0.3, b = 1}
	powerBar:SetStatusBarColor(info.r, info.g, info.b)
	powerBar.background:SetColorTexture(0.15+info.r/6, 0.15+info.g/6, 0.15+info.b/6, 1)
end

function UnitFrame:UpdateMaxPower()
	self.powerBar:SetMinMaxValues(0, UnitPowerMax(self.displayedUnit, self.powerType))
end

function UnitFrame:UpdatePower()
	self.powerBar:SetValue(UnitPower(self.displayedUnit, self.powerType))
end


--[[ Class resource bar ]]--

function DriverFrame:UpdateClassResourceBar()

	local classBar = NamePlateDriverFrame.classNamePlateMechanicFrame -- reuse Blizzard frame
	if not classBar then 
		return
	end
	classBar:Hide()

	local showSelf = GetCVar("nameplateShowSelf")
	if (showSelf == "0") or NephilistNameplatesOptions.HideClassBar then
		return
	end

	if NephilistNameplatesOptions.HideClassBar then return end

	local targetMode = GetCVarBool("nameplateResourceOnTarget")
	if classBar and (classBar.overrideTargetMode ~= nil) then
		targetMode = classBar.overrideTargetMode
	end
	if targetMode and classBar then
		local namePlateTarget = C_NamePlate.GetNamePlateForUnit("target")
		if namePlateTarget then
			classBar:SetParent(namePlateTarget)
			classBar:ClearAllPoints()
			classBar:SetPoint("BOTTOM", namePlateTarget.UnitFrame.name, "TOP", 0, 4)
			classBar:Show()
		else
			classBar:Hide()
		end
	elseif not targetMode and classBar then
		local namePlatePlayer = C_NamePlate.GetNamePlateForUnit("player")
		if namePlatePlayer then
			classBar:SetParent(namePlatePlayer)
			classBar:ClearAllPoints()
			classBar:SetPoint("TOP", namePlatePlayer.UnitFrame.powerBar, "BOTTOM", 0, -4)
			classBar:Show()
		end
	end
end




