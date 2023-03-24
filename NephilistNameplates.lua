local addonName, NephilistNameplates = ...

-- Namespaces
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
local IS_CLASSIC_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local IS_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

function NephilistNameplates:Update()
	-- Called by "Okay" button of addon options panel and various checkboxes
	DriverFrame:UpdateNamePlateOptions()
end


--[[ Driver frame ]]--

function DriverFrame:OnLoad()
	DriverFrame:SetScript("OnEvent", DriverFrame.OnEvent)

	DriverFrame:RegisterEvent("ADDON_LOADED")
	DriverFrame:RegisterEvent("VARIABLES_LOADED")
	DriverFrame:RegisterEvent("NAME_PLATE_CREATED")
	DriverFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	DriverFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	-- DriverFrame:RegisterEvent("FORBIDDEN_NAME_PLATE_CREATED")
	-- DriverFrame:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_ADDED")
	-- DriverFrame:RegisterEvent("FORBIDDEN_NAME_PLATE_UNIT_REMOVED")
	DriverFrame:RegisterEvent("CVAR_UPDATE")
	DriverFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
	DriverFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	DriverFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

	if IS_RETAIL then
		DriverFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		DriverFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
		self:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
		self:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
	elseif IS_CLASSIC_WRATH then
		DriverFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		DriverFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
		DriverFrame:RegisterEvent("TALENT_GROUP_ROLE_CHANGED")
	elseif IS_CLASSIC_ERA then
		DriverFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
	end
end

function DriverFrame:OnEvent(event, ...) 
	if event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == addonName then
			self:OnAddonLoaded()
		end
	elseif event == "VARIABLES_LOADED" then
		self:HideBlizzard()
		self:UpdateNamePlateOptions()
	elseif event == "NAME_PLATE_CREATED" or event == "FORBIDDEN_NAME_PLATE_CREATED" then 
		local nameplate = ...
		self:OnNamePlateCreated(nameplate)
	elseif event == "NAME_PLATE_UNIT_ADDED" or event == "FORBIDDEN_NAME_PLATE_UNIT_ADDED" then 
		local unit = ...
		self:OnNamePlateAdded(unit)
	elseif event == "NAME_PLATE_UNIT_REMOVED" or event == "FORBIDDEN_NAME_PLATE_UNIT_REMOVED" then 
		local unit = ...
		self:OnNamePlateRemoved(unit)
	elseif event == "PLAYER_TARGET_CHANGED" then
		self:OnTargetChanged()
	elseif event == "PLAYER_SOFT_INTERACT_CHANGED" or 
		event == "PLAYER_SOFT_FRIEND_CHANGED" or 
		event == "PLAYER_SOFT_ENEMY_CHANGED"
	then
		self:OnSoftTargetUpdate()
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		-- Fires OnEnter and OnLeave
		local nameplate = C_NamePlate.GetNamePlateForUnit("mouseover", issecure())
		if nameplate then 
			nameplate.UnitFrame:ShowMouseoverHighlight()
		end
	elseif event == "DISPLAY_SIZE_CHANGED" then
		self:UpdateNamePlateOptions()
	elseif event == "PLAYER_TALENT_UPDATE" or
		event == "ACTIVE_TALENT_GROUP_CHANGED" or
		event == "TALENT_GROUP_ROLE_CHANGED" or 
		event == "CHARACTER_POINTS_CHANGED"
	then
		self:UpdateNamePlateOptions()
	elseif event == "CVAR_UPDATE" then
		self:UpdateNamePlateOptions()
	end
end

function DriverFrame:OnAddonLoaded()
	NephilistNameplates:LocalizeStrings()
	if not IS_RETAIL then
		-- Disable Retail-only options
		local optionsPanel = NephilistNameplates.OptionsPanel
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.showBuffsButton)
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.onlyShowOwnBuffsButton)
		BlizzardOptionsPanel_CheckButton_Disable(optionsPanel.hideClassBarButton)
	end
	NephilistNameplates:UpdateOptions("NephilistNameplatesOptions", NephilistNameplates.Defaults, false)
end

function DriverFrame:HideBlizzard()
	NamePlateDriverFrame:UnregisterAllEvents()
	if IS_RETAIL then  
		ClassNameplateManaBarFrame:Hide()
		ClassNameplateManaBarFrame:UnregisterAllEvents()
		ClassNameplateManaBarFrame:HookScript("OnShow", function(self) self:Hide() end)  -- Appears on level up
	end
end

function DriverFrame:UpdateNamePlateOptions()
	-- Get cvars
	local enemyOptions = NephilistNameplates.EnemyFrameOptions
	local friendlyOptions = NephilistNameplates.FriendlyFrameOptions
	enemyOptions.showClassColor = GetCVarBool("ShowClassColorInNameplate")
	friendlyOptions.showClassColor = GetCVarBool("ShowClassColorInFriendlyNameplate")

	if IS_RETAIL then
		local baseNamePlateWidth = 110
		local baseNamePlateHeight = 45
		-- local namePlateVerticalScale = tonumber(GetCVar("NamePlateVerticalScale"))
		-- local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"))
		-- C_NamePlate.SetNamePlateOtherSize(baseNamePlateWidth * horizontalScale, baseNamePlateHeight)
		-- /script SetCVar("nameplateHorizontalScale", 0.5)
		-- /script print(GetCVar("nameplateVerticalScale"))
		C_NamePlate.SetNamePlateSelfSize(baseNamePlateWidth, baseNamePlateHeight)
			-- Creates taint in combat
	end

	DriverFrame:UpdateThreatRole()

	-- Update frames
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame
		unitFrame:SetOptions()
		unitFrame:UpdateLayout()
		unitFrame:UpdateAll()
	end
	PlayerPlate:Update()
	DriverFrame:UpdateClassResourceBar()  -- In Power.lua
end

function DriverFrame:UpdateThreatRole()
	if IS_RETAIL then
		local spec = GetSpecialization()
		if spec then
			self.threatRole = GetSpecializationRole(spec)
		end
	elseif IS_CLASSIC_WRATH then
		self.threatRole = GetTalentGroupRole(GetActiveTalentGroup())
	end
end

function DriverFrame:OnNamePlateCreated(nameplate)
	local unitFrame = CreateFrame("Button", "$parentUnitFrame", nameplate, "NephilistNameplatesTemplate")
	unitFrame:SetAllPoints()
	unitFrame:EnableMouse(false)
	Mixin(unitFrame, UnitFrame)  -- Inherit UnitFrame:Methods()
	unitFrame:Initialize()
end

function DriverFrame:OnNamePlateAdded(unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
	if namePlate then
		local unitFrame = namePlate.UnitFrame
		unitFrame:UpdateLayout()
		unitFrame:SetUnit(unit)
		unitFrame:SetOptions()
		unitFrame:UpdateAll()
		if IS_RETAIL then
			self:OnSoftTargetUpdate()
		end
		self:UpdateClassResourceBar()
	end
end

function DriverFrame:OnNamePlateRemoved(unit)
	-- local namePlate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
	if namePlate then
		namePlate.UnitFrame:SetUnit(nil)
		namePlate.UnitFrame.castBar:SetUnit(nil)
	end
end

function DriverFrame:OnTargetChanged()
	DriverFrame:UpdateClassResourceBar()  -- in Power.lua
end

function DriverFrame:OnSoftTargetUpdate()
	local iconSize = tonumber(GetCVar("SoftTargetNameplateSize"))
	local doEnemyIcon = GetCVarBool("SoftTargetIconEnemy")
	local doFriendIcon = GetCVarBool("SoftTargetIconFriend")
	local doInteractIcon = GetCVarBool("SoftTargetIconInteract")
	for _, frame in pairs(C_NamePlate.GetNamePlates(issecure())) do
		local icon = frame.UnitFrame.SoftTargetFrame.Icon
		local hasCursorTexture = false
		if iconSize > 0 then
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

do
	DriverFrame:OnLoad()
end
