-- Nephilist Nameplates: Simple, effective nameplates
-- By NephMakes

local NEPHILIST_NAMEPLATES, NephilistNameplates = ...

-- Define namespaces
NephilistNameplates.DriverFrame = CreateFrame("Frame", "NephilistNameplatesFrame", UIParent)
NephilistNameplates.PlayerPlate = CreateFrame("Button", "NephilistNameplatesPlayerPlate", UIParent)
NephilistNameplates.UnitFrame = {}
NephilistNameplates.Strings = {}
NephilistNameplates.CastBar = {}
NephilistNameplates.LossBar = {}
NephilistNameplates.BarBorder = {}

local DriverFrame = NephilistNameplates.DriverFrame
local UnitFrame = NephilistNameplates.UnitFrame
local PlayerPlate = NephilistNameplates.PlayerPlate

local IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IS_WOWLABS = WOW_PROJECT_ID == WOW_PROJECT_WOWLABS
local IS_CLASSIC_CATA = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
local IS_CLASSIC_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local IS_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IS_CLASSIC = IS_CLASSIC_ERA or IS_CLASSIC_WRATH or IS_CLASSIC_CATA

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates

function NephilistNameplates:Update()
	-- Called by options panel "Okay" button and various checkboxes
	DriverFrame:UpdateAddon()
end


--[[ Driver frame ]]--

function DriverFrame:OnLoad()
	self:SetScript("OnEvent", DriverFrame.OnEvent)
	self:RegisterSharedEvents()
	self:RegisterExpansionEvents()
end

function DriverFrame:RegisterSharedEvents()
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("NAME_PLATE_CREATED")
	self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	-- self:RegisterEvent("FORBIDDEN_NAME_PLATE_CREATED")
	-- self:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_ADDED")
	-- self:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_REMOVED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("CVAR_UPDATE")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")
end

function DriverFrame:RegisterExpansionEvents()
	if IS_RETAIL or IS_WOWLABS then
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
		self:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
		self:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
	elseif IS_CLASSIC_CATA then
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:RegisterEvent("TALENT_GROUP_ROLE_CHANGED")
		self:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
		self:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
		self:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
	elseif IS_CLASSIC_WRATH then
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:RegisterEvent("TALENT_GROUP_ROLE_CHANGED")
	elseif IS_CLASSIC_ERA then
		self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	end
end

function DriverFrame:OnEvent(event, ...) 
	local f = self[event]
	if f then
		f(self, ...)
	end
end

function DriverFrame:ADDON_LOADED(addonName)
	if addonName ~= NEPHILIST_NAMEPLATES then return end

	local nephPlates = NephilistNameplates
	nephPlates:LocalizeStrings()
	nephPlates:UpdateOptions("NephilistNameplatesOptions", nephPlates.Defaults, false)

	-- Disable inapplicable option widgets
	local optionsPanel = nephPlates.OptionsPanel
	if IS_CLASSIC_ERA or IS_CLASSIC_WRATH then
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.showBuffsButton)
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.onlyShowOwnBuffsButton)
	end
	if IS_CLASSIC then
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.hideClassBarButton)
	end

	self:UnregisterEvent("ADDON_LOADED")
end

function DriverFrame:VARIABLES_LOADED()
	-- Blizz variables loaded
	self:HideBlizzard()
	self:UpdateAddon()
end

function DriverFrame:HideBlizzard()
	NamePlateDriverFrame:UnregisterAllEvents()
	if IS_RETAIL or IS_WOWLABS then  
		local manaBar = ClassNameplateManaBarFrame
		manaBar:UnregisterAllEvents()
		manaBar:Hide()
		manaBar:HookScript("OnShow", function(self) self:Hide() end)
	end
end

function DriverFrame:UpdateAddon()
	self:SetOptions()
	for _, namePlate in pairs(GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame
		unitFrame:SetOptions()
		unitFrame:UpdateLayout()
		unitFrame:UpdateAll()
	end
	PlayerPlate:Update()
	self:UpdateClassResourceBar()  -- In Power.lua
end
DriverFrame.UpdateNamePlateOptions = DriverFrame.UpdateAddon  -- Deprecated

function DriverFrame:SetOptions()
	-- Get cvars
	local enemyOptions = NephilistNameplates.EnemyFrameOptions
	local friendlyOptions = NephilistNameplates.FriendlyFrameOptions
	enemyOptions.showClassColor = GetCVarBool("ShowClassColorInNameplate")
	friendlyOptions.showClassColor = GetCVarBool("ShowClassColorInFriendlyNameplate")

	-- Set nameplate sizes
	PlayerPlate:SetSize(140, 20)
	if IS_RETAIL or IS_WOWLABS then
		local baseNamePlateWidth = 110
		local baseNamePlateHeight = 45
		C_NamePlate.SetNamePlateSelfSize(baseNamePlateWidth, baseNamePlateHeight)
			-- Creates taint if called in combat

		-- local namePlateVerticalScale = tonumber(GetCVar("NamePlateVerticalScale"))
		-- local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"))
		-- C_NamePlate.SetNamePlateOtherSize(baseNamePlateWidth * horizontalScale, baseNamePlateHeight)
		-- /script SetCVar("nameplateHorizontalScale", 0.5)
		-- /script print(GetCVar("nameplateVerticalScale"))
	end

	self:UpdateThreatRole()
end

function DriverFrame:UpdateThreatRole()
	if IS_RETAIL or IS_WOWLABS then
		local spec = GetSpecialization()
		if spec then
			self.threatRole = GetSpecializationRole(spec)
		end
	elseif IS_CLASSIC_WRATH or IS_CLASSIC_CATA then
		self.threatRole = GetTalentGroupRole(GetActiveTalentGroup())
	end
end

function DriverFrame:NAME_PLATE_CREATED(nameplate)
	self:OnNamePlateCreated(nameplate)
end

function DriverFrame:OnNamePlateCreated(nameplate)
	-- Called by DriverFrame:NAME_PLATE_CREATED, PlayerPlate:ADDON_LOADED
	local unitFrame = CreateFrame("Button", "$parentUnitFrame", nameplate, "NephilistNameplatesTemplate")
	unitFrame:SetAllPoints()
	unitFrame:EnableMouse(false)
	Mixin(unitFrame, UnitFrame)
	unitFrame:OnLoad()
end

function DriverFrame:NAME_PLATE_UNIT_ADDED(unit)
	local namePlate = GetNamePlateForUnit(unit)
	if namePlate then
		namePlate.UnitFrame:OnNamePlateAdded(unit)
		if IS_RETAIL or IS_WOWLABS then
			self:OnSoftTargetUpdate()
		end
		self:UpdateClassResourceBar()
	end
end

function DriverFrame:NAME_PLATE_UNIT_REMOVED(unit)
	local namePlate = GetNamePlateForUnit(unit)
	if namePlate then
		namePlate.UnitFrame:OnNamePlateRemoved()
	end
end

function DriverFrame:UPDATE_MOUSEOVER_UNIT(unit)
	-- Fires OnEnter and OnLeave
	local nameplate = GetNamePlateForUnit("mouseover")
	if nameplate then 
		nameplate.UnitFrame:ShowMouseoverHighlight()
	end
end

function DriverFrame:PLAYER_TARGET_CHANGED()
	self:UpdateClassResourceBar()  -- in Power.lua
end

function DriverFrame:PLAYER_SOFT_INTERACT_CHANGED()
	self:OnSoftTargetUpdate()
end

function DriverFrame:PLAYER_SOFT_FRIEND_CHANGED()
	self:OnSoftTargetUpdate()
end

function DriverFrame:PLAYER_SOFT_ENEMY_CHANGED()
	self:OnSoftTargetUpdate()
end

function DriverFrame:OnSoftTargetUpdate()
	local iconSize = tonumber(GetCVar("SoftTargetNameplateSize"))
	local doEnemyIcon = GetCVarBool("SoftTargetIconEnemy")
	local doFriendIcon = GetCVarBool("SoftTargetIconFriend")
	local doInteractIcon = GetCVarBool("SoftTargetIconInteract")
	for _, frame in pairs(GetNamePlates()) do
		local icon = frame.UnitFrame.SoftTargetFrame.Icon
		local hasCursorTexture = false
		if frame.namePlateUnitToken and iconSize > 0 then
			if (doEnemyIcon and UnitIsUnit(frame.namePlateUnitToken, "softenemy")) or
				(doFriendIcon and UnitIsUnit(frame.namePlateUnitToken, "softfriend")) or
				(doInteractIcon and UnitIsUnit(frame.namePlateUnitToken, "softinteract"))
			then
				hasCursorTexture = SetUnitCursorTexture(icon, frame.namePlateUnitToken)
			end
		end
		if hasCursorTexture then
			icon:Show()
		else
			icon:Hide()
		end
	end
end

function DriverFrame:PLAYER_TALENT_UPDATE()
	self:UpdateAddon()
end

function DriverFrame:ACTIVE_TALENT_GROUP_CHANGED()
	self:UpdateAddon()
end

function DriverFrame:TALENT_GROUP_ROLE_CHANGED()
	self:UpdateAddon()
end

function DriverFrame:CHARACTER_POINTS_CHANGED()
	self:UpdateAddon()
end

function DriverFrame:CVAR_UPDATE()
	self:UpdateAddon()
end

do
	DriverFrame:OnLoad()
end
