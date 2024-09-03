-- Nameplate buffs and debuffs

local addonName, NephilistNameplates = ...
local UnitFrame = NephilistNameplates.UnitFrame

local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex

local BUFF_MAX_DISPLAY = BUFF_MAX_DISPLAY
local IS_CLASSIC = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC) or
	(WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC) or 
	(WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

local function MakeAuraButton(auraFrame, i)
	-- Not actually a pressable button
	local button = CreateFrame("Frame", auraFrame:GetParent():GetName() .. "Buff" .. i, auraFrame, "NephilistNameplates_BuffButtonTemplate")
	button:SetMouseClickEnabled(false)
	button:SetID(i)
	button.layoutIndex = i
	auraFrame.auras[i] = button
	return button
end

local function SetButtonAura(button, auraData)
	button.name = auraData.name
	button.Icon:SetTexture(auraData.icon)
	local count = button.CountFrame.Count
	if auraData.applications > 1 then
		count:SetText(auraData.applications)
		count:Show()
	else
		count:Hide()
	end
	local duration = auraData.duration
	CooldownFrame_Set(button.Cooldown, auraData.expirationTime - duration, duration, duration > 0, true)
	button:Show()
end

local function ShouldShowAura(aura, onlyShowOwn, isPlayer)
	if not aura then return false end
	if aura.nameplateShowAll then return true end
	if aura.isNameplateOnly then
		return (aura.nameplateShowPersonal == onlyShowOwn)
	end
	if IS_CLASSIC then
		-- isNameplateOnly and nameplateShowPersonal always false
		if not onlyShowOwn then return true end
		if isPlayer then
			return aura.canApplyAura
		else
			local caster = aura.sourceUnit
			return (caster == "player" or caster == "pet" or caster == "vehicle")
		end
	end
end

function UnitFrame:UpdateBuffs()
	local auraFrame = self.BuffFrame
	if self.showBuffs then
		auraFrame:Show()
	else
		auraFrame:Hide()
		return
	end

	local unit = self.displayedUnit
	local isPlayer = UnitIsUnit("player", unit)
	local filter

	auraFrame:ClearAllPoints()
	if isPlayer then
		auraFrame:SetPoint("BOTTOMLEFT", self.healthBar, "TOPLEFT", 0, 5)
		filter = "HELPFUL"
	else
		auraFrame:SetPoint("TOPLEFT", self.healthBar, "BOTTOMLEFT", 0, -5)
		local reaction = UnitReaction("player", unit)
		if reaction and reaction <= 4 then
			-- 4 is neutral, < 4 increasingly more hostile
			filter = "HARMFUL"
		else
			filter = "NONE"
		end
	end

	if filter == "NONE" then
		for _, button in ipairs(auraFrame.auras) do
			button:Hide()
		end
	else
		local auraData, button
		local j = 1
		for i = 1, BUFF_MAX_DISPLAY do
			auraData = GetAuraDataByIndex(unit, i, filter)
			if ShouldShowAura(auraData, self.onlyShowOwnBuffs, isPlayer) then
				button = auraFrame.auras[i] or MakeAuraButton(auraFrame, i)
				SetButtonAura(button, auraData)
				j = j + 1
			end
		end
		for i = j, BUFF_MAX_DISPLAY do
			if auraFrame.auras[i] then
				auraFrame.auras[i]:Hide()
			end
		end
	end

	auraFrame.unit = unit  -- For tooltips
	auraFrame.filter = filter  -- For tooltips
	auraFrame:Layout()  -- via Blizz HorizontalLayoutFrame
end






