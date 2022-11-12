local addonName, NephilistNameplates = ...

NephilistNameplates.DriverFrame = CreateFrame("Frame", "NephilistNameplatesFrame", UIParent)
NephilistNameplates.UnitFrame = {}
NephilistNameplates.PlayerPlate = CreateFrame("Frame", "NephilistNameplatesPlayerPlate", UIParent)

local DriverFrame = NephilistNameplates.DriverFrame
local UnitFrame = NephilistNameplates.UnitFrame
local PlayerPlate = NephilistNameplates.PlayerPlate

local EnemyFrameOptions = {
	showName = true, 
	colorHealthBySelection = true,
	displaySelectionHighlight = true,
	considerSelectionInCombatAsHostile = true,
	greyOutWhenTapDenied = true,
	hideCastBar = false, 
	showEliteIcon = true 
}
local FriendlyFrameOptions = {
	showName = true,
	colorHealthBySelection = true,
	displaySelectionHighlight = true,
	considerSelectionInCombatAsHostile = true,
	colorHealthWithExtendedColors = true,
	hideCastBar = false, 
	showEliteIcon = true 
}
local PlayerFrameOptions = {
	showName = false,
	displaySelectionHighlight = false,
	healthBarColorOverride = CreateColor(0, 0.7, 0), 
	hideCastBar = true, 
	showPowerBar = true,
	showEliteIcon = false 
}

function NephilistNameplates:Update()
	-- Called by "Okay" button of addon options panel
	DriverFrame:UpdateNamePlateOptions()
end


--[[ Driver frame ]]--

function DriverFrame:OnEvent(event, ...) 
	if ( event == "ADDON_LOADED" ) then
		local arg1 = ...;
		if ( arg1 == addonName ) then
			self:OnAddonLoaded();
		end
	elseif ( event == "VARIABLES_LOADED" ) then
		self:HideBlizzard();
		self:UpdateNamePlateOptions(); 
	elseif ( event == "NAME_PLATE_CREATED" ) then 
		local nameplate = ...;
		self:OnNamePlateCreated(nameplate);
	elseif ( event == "NAME_PLATE_UNIT_ADDED" ) then 
		local unit = ...;
		self:OnNamePlateAdded(unit);
	elseif ( event == "NAME_PLATE_UNIT_REMOVED" ) then 
		local unit = ...;
		self:OnNamePlateRemoved(unit);
	elseif event == "PLAYER_TARGET_CHANGED" then
		self:OnTargetChanged();
	elseif event == "DISPLAY_SIZE_CHANGED" then
		self:UpdateNamePlateOptions();
	elseif event == "CVAR_UPDATE" then
		local name = ...;
		if name == "SHOW_CLASS_COLOR_IN_V_KEY" or name == "SHOW_NAMEPLATE_LOSE_AGGRO_FLASH" then
			self:UpdateNamePlateOptions();
		end
	end
end
DriverFrame:SetScript("OnEvent", DriverFrame.OnEvent);
DriverFrame:RegisterEvent("ADDON_LOADED");
DriverFrame:RegisterEvent("VARIABLES_LOADED");
DriverFrame:RegisterEvent("NAME_PLATE_CREATED");
DriverFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
DriverFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
DriverFrame:RegisterEvent("CVAR_UPDATE");
DriverFrame:RegisterEvent("DISPLAY_SIZE_CHANGED");
DriverFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
-- DriverFrame:RegisterEvent("PLAYER_LOGIN");
-- DriverFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
-- DriverFrame:RegisterEvent("PLAYER_LOGOUT");

function DriverFrame:OnAddonLoaded()
	NephilistNameplates:LocalizeStrings()

	-- Disable Retail-only options
	if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then  -- Blizz globals in FrameXML/Constants.lua
		local optionsPanel = NephilistNameplates.OptionsPanel
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.showBuffsButton)
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.onlyShowOwnBuffsButton)
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.hideClassBarButton)
	end

--	local reset = false
--	if NephilistNameplatesOptions and NephilistNameplates.Version and NephilistNameplates.Version < "2.0.3" then
--		reset = true
--	end
	NephilistNameplates:UpdateOptions("NephilistNameplatesOptions", NephilistNameplates.Defaults, false)
end

function DriverFrame:HideBlizzard()
	NamePlateDriverFrame:UnregisterAllEvents()

	-- Retail-only features
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then  

		ClassNameplateManaBarFrame:Hide()
		ClassNameplateManaBarFrame:UnregisterAllEvents()
		-- Blizz mana bar appearing on level-up
		ClassNameplateManaBarFrame:HookScript("OnShow", function(self) self:Hide() end)

		local checkBox = InterfaceOptionsNamesPanelUnitNameplatesMakeLarger
		if checkBox then
			function checkBox.setFunc(value)
				if value == "1" then
					SetCVar("NamePlateHorizontalScale", checkBox.largeHorizontalScale)
					SetCVar("NamePlateVerticalScale", checkBox.largeVerticalScale)
				else
					SetCVar("NamePlateHorizontalScale", checkBox.normalHorizontalScale)
					SetCVar("NamePlateVerticalScale", checkBox.normalVerticalScale)
				end
				DriverFrame:UpdateNamePlateOptions()
			end
			-- Is this written properly? Are we defining or executing setFunc? 
			-- Where does value come from? 
		end
	end
end

function DriverFrame:UpdateNamePlateOptions()

	EnemyFrameOptions.useClassColors = GetCVarBool("ShowClassColorInNameplate");
	EnemyFrameOptions.playLoseAggroHighlight = GetCVarBool("ShowNamePlateLoseAggroFlash");

	local baseNamePlateWidth = 110;
	local baseNamePlateHeight = 45;
	local namePlateVerticalScale = tonumber(GetCVar("NamePlateVerticalScale"));
	local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"));
	-- C_NamePlate.SetNamePlateOtherSize(baseNamePlateWidth * horizontalScale, baseNamePlateHeight);
	C_NamePlate.SetNamePlateSelfSize(baseNamePlateWidth, baseNamePlateHeight);

	-- /script SetCVar("nameplateHorizontalScale", 0.5)
	-- /script print(GetCVar("nameplateVerticalScale"))

	--[[
	-- Somehow creating taint to have these here -- why would these get called in combat?
	-- Make these options
	SetCVar("nameplateOtherTopInset", -1);  -- Default 0.08
	SetCVar("nameplateOtherBottomInset", -1);  -- Default 0.1
	-- also bottom inset self?  
	SetCVar("nameplateMinScale", 0.6);  -- Default 0.8
	SetCVar("nameplateMinScaleDistance", 10);  -- Default 10
	SetCVar("nameplateMaxDistance", 40);  -- Default 60
	]]--

	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame
		unitFrame:SetOptions()
		unitFrame:UpdateAll()
	end
	PlayerPlate:Update()
	DriverFrame:UpdateClassResourceBar()  -- In Power.lua
end

function DriverFrame:OnNamePlateCreated(nameplate)
	local unitFrame = CreateFrame("Button", "$parentUnitFrame", nameplate, "NephilistNameplatesTemplate")
	unitFrame:SetAllPoints()
	unitFrame:EnableMouse(false)
	Mixin(unitFrame, UnitFrame)  -- Inherit UnitFrame:Methods()
	unitFrame.highlight = unitFrame.healthBar.highlight
	unitFrame.selectionBorder = unitFrame.healthBar.selectionBorder
	unitFrame.optionTable = {}
	unitFrame.BuffFrame.buffList = {}
	-- nameplate:HookScript("OnEnter", UnitFrame.ShowHighlight)   
	-- nameplate:HookScript("OnLeave", UnitFrame.HideHighlight)
	-- Causes nameplate to be unclickable
end

function DriverFrame:OnNamePlateAdded(unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit);
	local unitFrame = namePlate.UnitFrame;
	unitFrame:SetUnit(unit);
	unitFrame:SetOptions();
	unitFrame:UpdateAll();
	self:UpdateClassResourceBar();
end

function DriverFrame:OnNamePlateRemoved(unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit);
	namePlate.UnitFrame:SetUnit(nil);
end

function DriverFrame:OnTargetChanged()
	DriverFrame:UpdateClassResourceBar();  -- in Power.lua
end
