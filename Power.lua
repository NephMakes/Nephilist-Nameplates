local addonName, NephilistNameplates = ...
local DriverFrame = NephilistNameplates.DriverFrame;
local UnitFrame = NephilistNameplates.UnitFrame;


--[[ Power bar ]]--

function UnitFrame:UpdatePowerBar()
	local powerBar = self.powerBar;
	if ( self.optionTable.showPowerBar == true ) then
		powerBar:Show();
		local powerType, powerToken = UnitPowerType("player");
		if ( self.powerToken ~= powerToken or self.powerType ~= powerType ) then
			self.powerToken = powerToken;
			self.powerType = powerType;
		end
		self:UpdatePowerBarColor();
		self:UpdateMaxPower();
		self:UpdatePower();
	else
		powerBar:Hide();
	end
end

function UnitFrame:UpdatePowerBarColor()
	local powerToken = self.powerToken;
	local powerBar = self.powerBar;
	if (powerToken) then
		info = PowerBarColor[powerToken];
		powerBar:SetStatusBarColor(info.r, info.g, info.b);
		powerBar.background:SetColorTexture(0.15+info.r/5, 0.15+info.g/5, 0.15+info.b/5, 1);
	end
end

function UnitFrame:UpdateMaxPower()
	self.powerBar:SetMinMaxValues(0, UnitPowerMax("player", self.powerType));
end

function UnitFrame:UpdatePower()
	self.powerBar:SetValue(UnitPower("player", self.powerType));	
end


--[[ Class resource bar ]]--

function DriverFrame:UpdateClassResourceBar()

	local nameplateBar = NamePlateDriverFrame.nameplateBar;
	if ( not nameplateBar ) then 
		return;
	end
	nameplateBar:Hide();

	local showSelf = GetCVar("nameplateShowSelf");
	if ( showSelf == "0" or NephilistNameplatesOptions.HideClassBar ) then
		return;
	end
	--[[
	if ( NephilistNameplatesOptions.HideClassBar ) then
		return;
	end
	]]--

	local targetMode = GetCVarBool("nameplateResourceOnTarget");
	if ( nameplateBar and nameplateBar.overrideTargetMode ~= nil ) then
		targetMode = nameplateBar.overrideTargetMode;
	end
	if ( targetMode and NamePlateTargetResourceFrame ) then
		local namePlateTarget = C_NamePlate.GetNamePlateForUnit("target");
		if ( namePlateTarget ) then
			nameplateBar:SetParent(NamePlateTargetResourceFrame);
			NamePlateTargetResourceFrame:SetParent(namePlateTarget.UnitFrame);
			NamePlateTargetResourceFrame:ClearAllPoints();
			NamePlateTargetResourceFrame:SetPoint("BOTTOM", namePlateTarget.UnitFrame.name, "TOP", 0, 3);
			nameplateBar:Show();
		end
		NamePlateTargetResourceFrame:SetShown(namePlateTarget ~= nil);
	elseif ( not targetMode and NamePlatePlayerResourceFrame ) then
		local namePlatePlayer = C_NamePlate.GetNamePlateForUnit("player");
		if ( namePlatePlayer ) then
			nameplateBar:SetParent(NamePlatePlayerResourceFrame);
			NamePlatePlayerResourceFrame:SetParent(namePlatePlayer.UnitFrame);
			NamePlatePlayerResourceFrame:ClearAllPoints();
			NamePlatePlayerResourceFrame:SetPoint("TOP", namePlatePlayer.UnitFrame.powerBar, "BOTTOM", 0, -3);
			nameplateBar:Show();
		end
		NamePlatePlayerResourceFrame:SetShown(namePlatePlayer ~= nil);
	end
end




