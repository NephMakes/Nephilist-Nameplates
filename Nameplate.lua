local addonName, NephilistNameplates = ...

local DriverFrame = NephilistNameplates.DriverFrame
local UnitFrame = NephilistNameplates.UnitFrame


--[[ Locals ]]-- 

local function IsOnThreatList(unit)
	local _, threatStatus = UnitDetailedThreatSituation("player", unit)
	return threatStatus ~= nil
end

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


--[[ Unit frame ]]-- 

-- "Unit frame" here is non-interactable frame we attach to Blizz "Nameplate#" frames

function UnitFrame:SetUnit(unit)
	self.unit = unit
	self.displayedUnit = unit  -- For vehicles
	self.inVehicle = false
	if unit then
		self:RegisterEvents()
	else
		self:UnregisterEvents()
	end
end

function UnitFrame:UpdateInVehicle() 
	if UnitHasVehicleUI(self.unit) then
		if not self.inVehicle then
			self.inVehicle = true
			local prefix, id, suffix = string.match(self.unit, "([^%d]+)([%d]*)(.*)")
			self.displayedUnit = prefix.."pet"..id..suffix
			self:UpdateEvents()
		end
	else
		if self.inVehicle then
			self.inVehicle = false
			self.displayedUnit = self.unit
			self:UpdateEvents()
		end
	end
end

function UnitFrame:RegisterEvents()
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterEvent("UNIT_EXITED_VEHICLE")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("UNIT_FACTION")
	-- self:RegisterEvent("UNIT_CONNECTION")
	self:UpdateEvents()
	if UnitIsUnit("player", self.unit) then
		self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
		self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
		self:RegisterUnitEvent("UNIT_MAXPOWER", "player")
		-- self:RegisterEvent("UNIT_POWER_FREQUENT")
	end
	self:SetScript("OnEvent", UnitFrame.OnEvent)
end

function UnitFrame:UpdateEvents()
	-- These events affected if unit in vehicle
	-- Sometimes getting Lua error when entering/exiting during combat?
	local displayedUnit
	if self.unit ~= self.displayedUnit then
		displayedUnit = self.displayedUnit
	end
	self:RegisterUnitEvent("UNIT_MAXHEALTH", self.unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_HEALTH", self.unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_AURA", self.unit, displayedUnit)
	self:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", self.unit, displayedUnit)
	-- self:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", self.unit, displayedUnit)
	-- self:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", self.unit, displayedUnit)  -- i.e. AFK, DND
end

function UnitFrame:UnregisterEvents()
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
end

function UnitFrame:OnEvent(event, ...)
	local arg1, arg2, arg3, arg4 = ...;
	if event == "PLAYER_TARGET_CHANGED" then
		self:UpdateSelectionHighlight()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UpdateAll()
	elseif event == "RAID_TARGET_UPDATE" then
		self:UpdateRaidTarget()
	elseif event == "UNIT_POWER_FREQUENT" then 
		self:UpdatePower()
	elseif event == "UNIT_MAXPOWER" then 
		self:UpdateMaxPower()
	elseif event == "UNIT_DISPLAYPOWER" then 
		self:UpdatePowerBar()
	elseif arg1 == self.unit or arg1 == self.displayedUnit then
		if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
			self:UpdateHealth()
		elseif event == "UNIT_MAXHEALTH" then
			self:UpdateMaxHealth()
			self:UpdateHealth()
		elseif event == "UNIT_AURA" then
			self:UpdateBuffs()
		elseif event == "UNIT_THREAT_LIST_UPDATE" then
			if self.optionTable.considerSelectionInCombatAsHostile then
				self:UpdateName()
				self:UpdateHealthColor()
			end
			-- CompactUnitFrame_UpdateAggroFlash(self);
			-- CompactUnitFrame_UpdateHealthBorder(self);
		elseif event == "UNIT_NAME_UPDATE" then
			self:UpdateName()
			self:UpdateHealthColor()  -- Can signify now know unit's class
		elseif event == "UNIT_FACTION" then
			self:UpdateName()  -- Why is this here in Blizzard_Nameplates?
			self:UpdateHealthColor()
		elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" or event == "UNIT_PET" then
			self:UpdateAll()
		end
	end
end

function UnitFrame:SetOptions()
	local options = NephilistNameplatesOptions
	self.showBuffs = options.ShowBuffs
	self.onlyShowOwnBuffs = options.OnlyShowOwnBuffs
	self.showLevel = options.ShowLevel

	if UnitIsUnit("player", self.unit) then
		self.optionTable = PlayerFrameOptions
	elseif UnitIsFriend("player", self.unit) then
		self.optionTable = FriendlyFrameOptions
	else
		self.optionTable = EnemyFrameOptions
	end
end

function UnitFrame:UpdateAll()
	self:UpdateInVehicle()
	if UnitExists(self.displayedUnit) then
		self:UpdateName()
		self:UpdateLevel()
		self:UpdateHealthColor()
		self:UpdateMaxHealth()
		self:UpdateHealth()
		self:UpdateSelectionHighlight()
		self:UpdateRaidTarget()
		self:UpdateCastBar()
		self:UpdatePowerBar()
		self:UpdateBuffs()
		self:UpdateEliteIcon()
	end
end

function UnitFrame:UpdateName() 
	local name = GetUnitName(self.unit, false)
	self.name:SetText(name)
	if not self.optionTable.showName then
		self.name:Hide()
	else
		self.name:Show()
		local unitLevel = UnitLevel(self.unit)
		local classification = UnitClassification(self.unit)
		if unitLevel == -1 or classification == "worldboss" then
			self.name:SetTextColor(1.0, 0.6, 0.0)  -- Orange
		elseif classification == "rare" or classification == "rareelite" then
			self.name:SetTextColor(0.5, 0.5, 1.0)
		else
			self.name:SetTextColor(0.7, 0.7, 0.7)
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
	local healthBar = self.healthBar;
	local options = self.optionTable;
	local unit = self.unit;
	local r, g, b;
	if ( not UnitIsConnected(unit) ) then
		r, g, b = 0.7, 0.7, 0.7;
	else
		if ( options.healthBarColorOverride ) then
			local override = options.healthBarColorOverride;
			r, g, b = override.r, override.g, override.b;
		else
			local _, englishClass = UnitClass(unit);
			local classColor = RAID_CLASS_COLORS[englishClass];
			if ( UnitIsPlayer(unit) and classColor and options.useClassColors ) then
				r, g, b = classColor.r, classColor.g, classColor.b;
			elseif ( self:IsTapDenied() ) then
				r, g, b = 0.3, 0.3, 0.3;
			elseif ( options.colorHealthBySelection ) then
				-- Use color based on the type of unit (neutral, etc.)
				if ( options.considerSelectionInCombatAsHostile and IsOnThreatList(self.displayedUnit) ) then
					r, g, b = 1.0, 0.0, 0.0;
				else
					r, g, b = UnitSelectionColor(unit, options.colorHealthWithExtendedColors);
				end
			elseif ( UnitIsFriend("player", unit) ) then
				r, g, b = 0.0, 1.0, 0.0;
			else
				r, g, b = 1.0, 0.0, 0.0;
			end
		end
	end
	if ( r ~= healthBar.r or g ~= healthBar.g or b ~= healthBar.b ) then
		healthBar:SetStatusBarColor(r, g, b);
		healthBar.background:SetColorTexture(0.15+r/5, 0.15+g/5, 0.15+b/5, 1);
		healthBar.r, healthBar.g, healthBar.b = r, g, b;
	end
end

function UnitFrame:IsTapDenied()
	return self.optionTable.greyOutWhenTapDenied 
		and UnitIsTapDenied(self.unit)
		and not UnitPlayerControlled(self.unit)
end

function UnitFrame:UpdateMaxHealth() 
	self.healthBar:SetMinMaxValues(0, UnitHealthMax(self.displayedUnit))
end

function UnitFrame:UpdateHealth() 
	self.healthBar:SetValue(UnitHealth(self.displayedUnit))
end

function UnitFrame:UpdateSelectionHighlight() 
	if not self.optionTable.displaySelectionHighlight then
		self.selectionBorder:Hide()
		return
	end
	if UnitIsUnit(self.displayedUnit, "target") then
		self.selectionBorder:Show()
	else
		self.selectionBorder:Hide()
	end
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
		if classification == "worldboss" or classification == "elite" or classification == "rareelite" then
			icon:Show()
		else
			icon:Hide()
		end
	end
end

function UnitFrame:UpdateCastBar()
	local castBar = self.castBar
	castBar.startCastColor = CreateColor(0.6, 0.6, 0.6)
	castBar.startChannelColor = CreateColor(0.6, 0.6, 0.6)
	castBar.finishedCastColor = CreateColor(0.6, 0.6, 0.6)
	castBar.failedCastColor = CreateColor(0.5, 0.2, 0.2)
	castBar.nonInterruptibleColor = CreateColor(0.3, 0.3, 0.3)
	CastingBarFrame_AddWidgetForFade(castBar, castBar.BorderShield)
	if not self.optionTable.hideCastBar then
		CastingBarFrame_SetUnit(castBar, self.unit, false, true)
	else
		CastingBarFrame_SetUnit(castBar, nil, nil, nil)
	end
end

--function UnitFrame:ShowHighlight()
--	self.UnitFrame.highlight:Show()
--end
--
--function UnitFrame:HideHighlight()
--	self.UnitFrame.highlight:Hide()
--end


