local addonName, NephilistNameplates = ...
local UnitFrame = NephilistNameplates.UnitFrame

local BUFF_MAX_DISPLAY = BUFF_MAX_DISPLAY

local function ShouldShowAura(aura, onlyShowOwn, isPlayer)
	if not aura then return false end
	if aura.nameplateShowAll then return true end
	if aura.isNameplateOnly then
		return (aura.nameplateShowPersonal == onlyShowOwn)
	end

	-- In Classic isNameplateOnly and nameplateShowPersonal always false
	if not onlyShowOwn then return true end
	if isPlayer then
		return aura.canApplyAura
	else
		local caster = aura.sourceUnit
		return (caster == "player" or caster == "pet" or caster == "vehicle")
	end
end


function UnitFrame:UpdateBuffs()
	local buffFrame = self.BuffFrame
	if self.showBuffs then
		buffFrame:Show()
	else
		buffFrame:Hide()
		return
	end

	local unit = self.displayedUnit
	local filter

	local isPlayer = UnitIsUnit("player", unit)

	buffFrame:ClearAllPoints()
	if isPlayer then
		buffFrame:SetPoint("BOTTOMLEFT", self.healthBar, "TOPLEFT", 0, 5)
		filter = "HELPFUL"
	else
		buffFrame:SetPoint("TOPLEFT", self.healthBar, "BOTTOMLEFT", 0, -5)
		local reaction = UnitReaction("player", unit)
		if reaction and reaction <= 4 then
			-- Reaction 4 is neutral and less than 4 becomes increasingly more hostile
			filter = "HARMFUL"
		else
			filter = "NONE"
		end
	end

	-- For buff tooltips:
	buffFrame.unit = unit
	buffFrame.filter = filter

	if filter == "NONE" then
		for i, buff in ipairs(buffFrame.buffList) do
			buff:Hide()
		end
	else
		local _, name, texture, count, duration, expirationTime, caster, nameplateShowPersonal, nameplateShowAll, buff
		local isNameplateOnly
		local buffIndex = 1
		local aura

		for i = 1, BUFF_MAX_DISPLAY do
			aura = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
			if ShouldShowAura(aura, self.onlyShowOwnBuffs, isPlayer) then
				if not buffFrame.buffList[buffIndex] then
					buffFrame.buffList[buffIndex] = CreateFrame("Frame", buffFrame:GetParent():GetName() .. "Buff" .. buffIndex, buffFrame, "NephilistNameplates_BuffButtonTemplate")
					buffFrame.buffList[buffIndex]:SetMouseClickEnabled(false)
				end
				buff = buffFrame.buffList[buffIndex]
				buff:SetID(i)
				buff.name = aura.name
				buff.layoutIndex = i

				buff.Icon:SetTexture(aura.icon)
				if aura.applications > 1 then
					buff.CountFrame.Count:SetText(aura.applications)
					buff.CountFrame.Count:Show()
				else
					buff.CountFrame.Count:Hide()
				end

				local duration = aura.duration
				CooldownFrame_Set(buff.Cooldown, aura.expirationTime - duration, duration, duration > 0, true)

				buff:Show()
				buffIndex = buffIndex + 1
			end
		end
		for i = buffIndex, BUFF_MAX_DISPLAY do
			if buffFrame.buffList[i] then
				buffFrame.buffList[i]:Hide()
			end
		end
	end
	buffFrame:Layout()  -- via Blizz HorizontalLayoutFrame
end






