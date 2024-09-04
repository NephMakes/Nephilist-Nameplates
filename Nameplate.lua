-- "UnitFrame" here is the non-interactable frame we attach to Blizz "Nameplate#"

local addonName, NephilistNameplates = ...

local DriverFrame = NephilistNameplates.DriverFrame
local UnitFrame = NephilistNameplates.UnitFrame
local LossBar = NephilistNameplates.LossBar
local BarBorder = NephilistNameplates.BarBorder
local CastBar = NephilistNameplates.CastBar

NephilistNameplates.EnemyFrameOptions = {
	colorHealthByReaction = true,
	considerSelectionInCombatAsHostile = true,
	greyWhenTapDenied = true,
	-- showClassColor set by DriverFrame:UpdateNamePlateOptions()
	showEliteIcon = true, 
	showName = true, 
	showSelectionHighlight = true, 
}
NephilistNameplates.FriendlyFrameOptions = {
	colorHealthByReaction = true,
	colorHealthWithExtendedColors = true,
	considerSelectionInCombatAsHostile = true,
	-- showClassColor set by DriverFrame:UpdateNamePlateOptions()
	showEliteIcon = true, 
	showName = true,
	showSelectionHighlight = true,
}
NephilistNameplates.PlayerFrameOptions = {
	healthBarColorOverride = CreateColor(0, 0.7, 0), 
	hideCastBar = true, 
	showPowerBar = true,
}
local EnemyFrameOptions = NephilistNameplates.EnemyFrameOptions
local FriendlyFrameOptions = NephilistNameplates.FriendlyFrameOptions
local PlayerFrameOptions = NephilistNameplates.PlayerFrameOptions

local BAR_HEIGHT = 5
local BAR_HEIGHT_MIN_PIXELS = 5
local BORDER_SIZE = 1
local BORDER_MIN_PIXELS = 2

-- No UnitHasVehicleUI() in Classic Era
local UnitHasVehicleUI = UnitHasVehicleUI or function(unit) return false end


--[[ Setup ]]-- 

function UnitFrame:OnLoad()
	-- Called by DriverFrame:NAME_PLATE_CREATED

	self.healthBackground:SetAllPoints(self.healthBar)
	self.selectionBorder = self.healthBar.selectionBorder

	local healthBorder = self.healthBar.border
	local powerBorder = self.powerBar.border
	local selectionBorder = self.selectionBorder
	Mixin(healthBorder, BarBorder)
	Mixin(powerBorder, BarBorder)
	Mixin(selectionBorder, BarBorder)
	healthBorder:SetBorderSizes(BORDER_SIZE, BORDER_MIN_PIXELS)
	powerBorder:SetBorderSizes(BORDER_SIZE, BORDER_MIN_PIXELS)
	selectionBorder:SetBorderSizes(BORDER_SIZE, BORDER_MIN_PIXELS)
	healthBorder:SetVertexColor(0, 0, 0, 1)
	powerBorder:SetVertexColor(0, 0, 0, 1)
	selectionBorder:SetVertexColor(1, 1, 1, 1)

	self.optionTable = {}
	self.BuffFrame.auras = {}

	Mixin(self.lossBar, LossBar)
	self.lossBar:Initialize()

	Mixin(self.castBar, CastBar)
	self.castBar:OnLoad()
end

function UnitFrame:OnNamePlateAdded(unit)
	-- Activate for unit
	-- Called by DriverFrame:NAME_PLATE_UNIT_ADDED, PlayerPlate:ADDON_LOADED
	self:SetUnit(unit)
	self:Activate()
	self:Update()
end

function UnitFrame:OnNamePlateRemoved()
	-- called by DriverFrame:NAME_PLATE_UNIT_REMOVED
	self:SetUnit(nil)
	self:SetScript("OnEvent", nil)
	self:UnregisterAllEvents()
	self.castBar:SetUnit(nil)
	self.currentHealth = nil  -- Reset for LossBar
end

function UnitFrame:SetUnit(unit)
	-- Called by UnitFrame:OnNamePlateAdded, UnitFrame:OnNamePlateRemoved
	self.unit = unit
	self.displayedUnit = unit
	self.inVehicle = false
	-- See also UnitFrame:UpdateDisplayedUnit()
end

function UnitFrame:Activate()
	local unit = self.unit
	self:SetScript("OnEvent", self.OnEvent)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterUnitEvent("UNIT_PET", unit)
	self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", unit)
	self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", unit)
	self:RegisterUnitEvent("UNIT_FACTION", unit)
	self:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
	-- self:RegisterEvent("UNIT_CONNECTION", unit)
	-- See also UnitFrame:UpdateUnitEvents()
end

function UnitFrame:Update()
	-- Called by UnitFrame:OnNamePlateAdded, 
	--   DriverFrame:UpdateAddon, 
	--   PlayerPlate:Update
	self:SetOptions()
	self:UpdateLayout()
	self:UpdateElements()
end

function UnitFrame:SetOptions()
	if UnitIsUnit("player", self.unit) then
		self.optionTable = PlayerFrameOptions
	elseif UnitIsFriend("player", self.unit) then
		self.optionTable = FriendlyFrameOptions
	else
		self.optionTable = EnemyFrameOptions
	end

	local options = NephilistNameplatesOptions  -- Saved variable
	self.showBuffs = options.ShowBuffs
	self.onlyShowOwnBuffs = options.OnlyShowOwnBuffs
	self.showLevel = options.ShowLevel
	self.showThreat = options.ShowThreat
	self.threatRole = DriverFrame.threatRole
	self.showThreatOnlyInGroup = options.ShowThreatOnlyInGroup
	self.showLossBar = options.ShowLossBar
end

function UnitFrame:UpdateLayout()
	-- Tweak size and position of frame elements for pixel-scale clarity
	local healthBar = self.healthBar
	local powerBar = self.powerBar
	local selectionBorder = self.selectionBorder

	PixelUtil.SetHeight(healthBar, BAR_HEIGHT, BAR_HEIGHT_MIN_PIXELS)
	PixelUtil.SetHeight(powerBar, BAR_HEIGHT, BAR_HEIGHT_MIN_PIXELS)
	PixelUtil.SetPoint(powerBar, "TOPLEFT", healthBar, "BOTTOMLEFT", 0, -BORDER_SIZE, 0, BORDER_MIN_PIXELS)
	PixelUtil.SetPoint(powerBar, "TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, -BORDER_SIZE, 0, BORDER_MIN_PIXELS)

	healthBar.border:UpdateSizes()
	powerBar.border:UpdateSizes()
	selectionBorder:UpdateSizes()

	PixelUtil.SetPoint(selectionBorder, "TOPLEFT", healthBar, "TOPLEFT", -BORDER_SIZE, BORDER_SIZE, -BORDER_MIN_PIXELS, BORDER_MIN_PIXELS)
	PixelUtil.SetPoint(selectionBorder, "BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", BORDER_SIZE, -BORDER_SIZE, BORDER_MIN_PIXELS, -BORDER_MIN_PIXELS)
end


--[[ Action ]]-- 

function UnitFrame:UpdateElements()
	self:UpdateDisplayedUnit()
	if not UnitExists(self.displayedUnit) then return end
	self:UpdateUnitEvents()

	self:UpdateName()
	self:UpdateLevel()
	self:UpdateHealthColor()
	self:UpdateMaxHealth()
	self:UpdateHealth()
	self:UpdateSelectionHighlight()
	self:UpdateMouseoverHighlight()
	self:UpdateRaidTarget()
	self:UpdateCastBar()
	self:UpdatePowerBar()
	self:UpdateBuffs()
	self:UpdateEliteIcon()
	self:UpdateThreat()
end

function UnitFrame:UpdateDisplayedUnit()
	-- Show nameplate for vehicle if present
	if UnitHasVehicleUI(self.unit) then
		self.inVehicle = true
		if self.unit == "player" then
			self.displayedUnit = "vehicle"
		else
			local prefix, id, suffix = string.match(self.unit, "([^%d]+)([%d]*)(.*)")
			self.displayedUnit = prefix.."pet"..id..suffix
		end
	else
		self.inVehicle = false
		self.displayedUnit = self.unit
	end
end

function UnitFrame:UpdateUnitEvents()
	-- Events affected if unit in vehicle
	local unit = self.unit
	local displayedUnit
	if unit ~= self.displayedUnit then
		displayedUnit = self.displayedUnit
	end
	self:RegisterUnitEvent("UNIT_HEALTH", unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_MAXHEALTH", unit, displayedUnit)
	if UnitIsUnit("player", unit) then
		self:RegisterUnitEvent("UNIT_POWER_FREQUENT", unit, displayedUnit)
		self:RegisterUnitEvent("UNIT_MAXPOWER", unit, displayedUnit)
		self:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit, displayedUnit)
	end
	if self.showBuffs then
		self:RegisterUnitEvent("UNIT_AURA", unit, displayedUnit)
	end
	if self.showThreat then
		self:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", unit, displayedUnit)
		self:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", unit, displayedUnit)
	end
end

function UnitFrame:UpdateName() 
	local name = GetUnitName(self.unit, false)
	self.name:SetText(name)
	self.nameHighlight:SetText(name)
	if not self.optionTable.showName then
		self.name:Hide()
		self.nameHighlight:Hide()
	else
		self.name:Show()
		local unitLevel = UnitLevel(self.unit)
		local classification = UnitClassification(self.unit)
		if unitLevel == -1 or classification == "worldboss" then
			self.name:SetTextColor(1.0, 0.6, 0.0)  -- Orange
		elseif classification == "rare" or classification == "rareelite" then
			self.name:SetTextColor(0.4, 0.4, 1.0)  -- Blue
		else
			self.name:SetTextColor(0.7, 0.7, 0.7)  -- Light grey
		end
	end
end

function UnitFrame:UpdateLevel()
	if self.showLevel and not UnitIsUnit("player", self.unit) then
		local unitLevel = UnitLevel(self.unit)
		local levelColor = {r = 0.7, g = 0.7, b = 0.7}
		if UnitCanAttack("player", self.unit) then
			levelColor = GetCreatureDifficultyColor(unitLevel)
		end
		if unitLevel == -1 then
			unitLevel = "??"
			levelColor = {r = 1.0, g = 0.0, b = 0.0}  -- Red
		end
		self.levelText:SetText(unitLevel)
		self.levelText:SetTextColor(levelColor.r, levelColor.g, levelColor.b)
		self.levelText:Show()
	else
		self.levelText:Hide()
	end
end

function UnitFrame:UpdateHealthColor() 
	local r, g, b = self:GetHealthColor()
	local healthBar = self.healthBar
	healthBar:SetStatusBarColor(r, g, b)
	healthBar.highlight:SetVertexColor(r, g, b)
	self.healthBackground:SetStatusBarColor(r/5, g/5, b/5, 1)
end

function UnitFrame:GetHealthColor()
	local unit = self.unit
	local optionTable = self.optionTable

	if not UnitIsConnected(unit) then
		return 0.7, 0.7, 0.7
	end

	if optionTable.healthBarColorOverride then
		local override = optionTable.healthBarColorOverride
		return override.r, override.g, override.b
	end

	if UnitIsPlayer(unit) and optionTable.showClassColor then
		-- Set from cvars by DriverFrame:UpdateNamePlateOptions()
		local _, englishClass = UnitClass(unit)
		local classColor = RAID_CLASS_COLORS[englishClass]
		if classColor then 
			return classColor.r, classColor.g, classColor.b
		end
	end

	if self:IsTapDenied() then
		return 0.4, 0.4, 0.4
	end

	if self.threatColor then
		return self.threatColor.r, self.threatColor.g, self.threatColor.b
	end

	if optionTable.colorHealthByReaction then
		-- Color by unit reaction (neutral, hostile, etc)
		return UnitSelectionColor(unit, optionTable.colorHealthWithExtendedColors)
	end

	if UnitIsFriend("player", unit) then
		return 0.0, 0.8, 0.0
	else
		return 1.0, 0.0, 0.0
	end
end

function UnitFrame:IsTapDenied()
	return self.optionTable.greyWhenTapDenied 
		and UnitIsTapDenied(self.unit)
		and not UnitPlayerControlled(self.unit)
end

function UnitFrame:UpdateMaxHealth() 
	local maxHealth = UnitHealthMax(self.displayedUnit)
	self.healthBar:SetMinMaxValues(0, maxHealth)
	self.lossBar:SetMinMaxValues(0, maxHealth)
	self.lossBar.maxHealth = maxHealth
end

function UnitFrame:UpdateHealth() 
	local currentHealth = UnitHealth(self.displayedUnit)
	if self.currentHealth then
		-- We've seen this before
		if currentHealth ~= self.currentHealth then 
			-- Health has changed
			self.healthBar:SetValue(currentHealth)
			if self.showLossBar then
				self.lossBar:UpdateHealth(currentHealth, self.currentHealth)
			end
			self.currentHealth = currentHealth
		end
		if self.showLossBar then
			self.lossBar:UpdateAnimation(currentHealth)
		end
	else 
		-- We haven't seen this before
		self.healthBar:SetValue(currentHealth)
		self.currentHealth = currentHealth
	end
end

function UnitFrame:UpdateSelectionHighlight() 
	if not self.optionTable.showSelectionHighlight then
		self.selectionBorder:Hide()
	elseif UnitIsUnit(self.displayedUnit, "target") then
		self.selectionBorder:Show()
	else
		self.selectionBorder:Hide()
	end
end

function UnitFrame:ShowMouseoverHighlight()
	self.healthBar.highlight:Show()
	if self.optionTable.showName then
		self.nameHighlight:Show()
	end
	self:SetIgnoreParentAlpha(true)
		-- Default UI behavior:
		--   Classic: nontarget nameplates lower alpha when target exists
		--   Retail: alpha changes with distance (bleh)
	self:SetScript("OnUpdate", self.UpdateMouseoverHighlight)
end

function UnitFrame:UpdateMouseoverHighlight()
	-- OnUpdate because UnitIsUnit("mouseover", self.unit) true 
	-- when UPDATE_MOUSEOVER_UNIT fired OnLeave
	if not UnitIsUnit("mouseover", self.unit) then
		self:HideMouseoverHighlight()
		self:SetScript("OnUpdate", nil)
		if not self.threatAlpha then
			self:SetIgnoreParentAlpha(false)
		end
	end
end

function UnitFrame:HideMouseoverHighlight()
	self.healthBar.highlight:Hide()
	self.nameHighlight:Hide()
end

function UnitFrame:UpdateRaidTarget() 
	local icon = self.RaidTargetFrame.RaidTargetIcon
	local index = GetRaidTargetIndex(self.unit)
	if index then
		SetRaidTargetIconTexture(icon, index)
		icon:Show()
	else
		icon:Hide()
	end
end

function UnitFrame:UpdateEliteIcon() 
	local icon = self.EliteFrame.EliteIcon
	if not self.optionTable.showEliteIcon then
		icon:Hide()
	else
		local classification = UnitClassification(self.unit)
		if classification == "worldboss" or 
			classification == "elite" or 
			classification == "rareelite" 
		then
			icon:Show()
		else
			icon:Hide()
		end
	end
end

function UnitFrame:UpdateThreat()
	if not self.showThreat or 
		(not IsInGroup() and self.showThreatOnlyInGroup) or 
		UnitIsFriend("player", self.unit) or 
		UnitIsPlayer(self.unit)
	then
		self:HideThreat()
		return
	end

	local isTanking, status = UnitDetailedThreatSituation("player", self.unit)
	if status then
		if self.threatRole == "TANK" then
			if not isTanking then
				self:ShowThreatBad()
			elseif status < 3 then
				self:ShowThreatDanger()
			else
				self:ShowThreatGood()
			end
		else
			if isTanking then
				self:ShowThreatBad()
			elseif status > 0 then
				self:ShowThreatDanger()
			else
				self:ShowThreatGood()
			end
		end
	else
		self:HideThreat()
	end
end

function UnitFrame:ShowThreatBad()
	self.threatColor = {r = 1, g = 0, b = 0}
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:SetVertexColor(1, 0, 0)
	-- self.healthBar.glowBottom:SetVertexColor(1, 0, 0)
	-- self.healthBar.glowTop:Show()
	-- self.healthBar.glowBottom:Show()

	-- Full opacity for nameplates with threat warning
	self:SetIgnoreParentAlpha(true)
	self.threatAlpha = true
end

function UnitFrame:ShowThreatDanger()
	self.threatColor = {r = 1.0, g = 0, b = 0.5}
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:SetVertexColor(1, 0, 0.5)
	-- self.healthBar.glowBottom:SetVertexColor(1, 0, 0.5)
	-- self.healthBar.glowTop:Show()
	-- self.healthBar.glowBottom:Show()

	-- Full opacity for nameplates with threat warning
	self:SetIgnoreParentAlpha(true)
	self.threatAlpha = true
end

function UnitFrame:ShowThreatGood()
	self.threatColor = {r = 0.6, g = 0.0, b = 0.7}
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:Hide()
	-- self.healthBar.glowBottom:Hide()
	self.threatAlpha = nil
	self:UpdateMouseoverHighlight()
end

function UnitFrame:HideThreat()
	self.threatColor = nil
	self:UpdateHealthColor()
	-- self.healthBar.glowTop:Hide()
	-- self.healthBar.glowBottom:Hide()
	self.threatAlpha = nil
	self:UpdateMouseoverHighlight()
end

function UnitFrame:UpdateCastBar()
	if not self.optionTable.hideCastBar then
		self.castBar:SetUnit(self.unit)
	else
		self.castBar:SetUnit(nil)
	end
end


--[[ Events ]]--

function UnitFrame:OnEvent(event, unit, ...)
	local eventFunction = self[event]
	if eventFunction then
		eventFunction(self, unit, ...)
	end
end

function UnitFrame:PLAYER_ENTERING_WORLD()
	self:UpdateElements()
end

function UnitFrame:PLAYER_TARGET_CHANGED()
	self:UpdateSelectionHighlight()
end

function UnitFrame:UNIT_HEALTH()
	self:UpdateHealth()
end

function UnitFrame:UNIT_MAXHEALTH()
	self:UpdateMaxHealth()
	self:UpdateHealth()
end

function UnitFrame:UNIT_POWER_FREQUENT()
	self:UpdatePower()
end

function UnitFrame:UNIT_DISPLAYPOWER()
	self:UpdatePowerBar()
end

function UnitFrame:UNIT_MAXPOWER()
	self:UpdateMaxPower()
end

function UnitFrame:UNIT_AURA(unit)
	self:UpdateBuffs()
end

function UnitFrame:UNIT_THREAT_LIST_UPDATE(unit)
	if self.optionTable.considerSelectionInCombatAsHostile then
		self:UpdateName()  -- We've been bamboozled! 
		self:UpdateThreat()
	end
end

function UnitFrame:UNIT_THREAT_SITUATION_UPDATE(unit)
	if self.optionTable.considerSelectionInCombatAsHostile then
		self:UpdateName()  -- It's a trap! 
		self:UpdateThreat()
	end
end

function UnitFrame:RAID_TARGET_UPDATE()
	self:UpdateRaidTarget()
end

function UnitFrame:UNIT_ENTERED_VEHICLE(unit)
	self:UpdateElements()
end

function UnitFrame:UNIT_EXITED_VEHICLE(unit)
	self:UpdateElements()
end

function UnitFrame:UNIT_PET(unit)
	self:UpdateElements()
end

function UnitFrame:UNIT_FACTION(unit)
	-- Curse your sudden but inevitable betrayal! 
	self:Update()
end

function UnitFrame:UNIT_NAME_UPDATE(unit)
	self:UpdateName()
	self:UpdateHealthColor()  -- Event can signal we now know unit class
end

