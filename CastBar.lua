-- Nameplate cast bar

local _, NephilistNameplates = ...
local CastBar = NephilistNameplates.CastBar

-- Constants
local ALPHA_STEP = 0.05  -- Fade out over 20 frames
local FLASH_STEP = 0.2  -- Flash over 5 frames
local HOLD_TIME = 1  -- Seconds to show failed/interrupted cast
local FAILED = FAILED  -- Blizz localized string
local INTERRUPTED = INTERRUPTED  -- Blizz localized string

-- Local versions of global functions
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo


--[[ CastBar setup ]]-- 

function CastBar:OnLoad()
	-- Called by NephilistNameplates.UnitFrame:Initialize()
	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)

	self.startCastColor = CreateColor(0.6, 0.6, 0.6)
	self.finishedCastColor = CreateColor(0.7, 0.7, 0.7)
	self.failedCastColor = CreateColor(0.5, 0.1, 0.1)
	self.notInterruptibleColor = CreateColor(0.4, 0.4, 0.4)
	self.Flash:SetVertexColor(1, 1, 1)

	self:SetUnit(nil)
end

function CastBar:SetUnit(unit)
	-- Primary update call
	-- Called by CastBar:OnLoad, NephilistNameplates.UnitFrame:UpdateCastBar
	if self.unit == unit then return end  -- Job's done

	self.unit = unit
	self.casting = nil
	self.channeling = nil
	self.holdTime = 0
	self.fadeOut = nil

	if unit then
		self:RegisterEvents(unit)
		self:PLAYER_ENTERING_WORLD(unit)
	else
		self:UnregisterEvents()
		self:Hide()
	end
end

function CastBar:RegisterEvents(unit)
	-- self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", unit)
end

function CastBar:UnregisterEvents()
	-- self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	self:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
end


--[[ CastBar action ]]-- 

function CastBar:OnShow()
	-- Update bar value
	if not self.unit then return end
	if self.casting then
		local _, _, _, startTime = UnitCastingInfo(self.unit)
		if startTime then
			self.value = GetTime() - (startTime/1000)
		end
	else
		local _, _, _, _, endTime = UnitChannelInfo(self.unit)
		if endTime then
			self.value = (endTime/1000) - GetTime()
		end
	end
end

function CastBar:OnEvent(event, unit, ...)
	local eventFunction = self[event]
	if eventFunction then
		eventFunction(self, unit, ...)
	end
end

function CastBar:PLAYER_ENTERING_WORLD(unit)
	-- Check if cast in progress
	-- Will only have valid unit when called by castbar:SetUnit 
	-- (not castbar:OnEvent)
	local channelName = UnitChannelInfo(unit)
	local castName = UnitCastingInfo(unit)
	if channelName then
		self:UNIT_SPELLCAST_CHANNEL_START(unit)
	elseif castName then
		self:UNIT_SPELLCAST_START(unit)
	else
		self:FinishSpell()
	end
end

function CastBar:UNIT_SPELLCAST_START(unit)
	local name, text, _, startTime, endTime, _, castID, notInterruptible = UnitCastingInfo(unit)
	if not name then
		self:Hide()
		return
	end

	self.value = GetTime() - (startTime / 1000)
	self.maxValue = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.maxValue)
	self:SetValue(self.value)

	local startColor = self:GetStartColor(notInterruptible)
	self:SetStatusBarColor(startColor:GetRGB())
	self.Text:SetText(text)
	self.Spark:Show()
	self:ShowNotInterruptible(notInterruptible)

	self.casting = true
	self.channeling = nil
	self.castID = castID
	self.holdTime = 0
	self.fadeOut = nil

	self:SetAlpha(1)
	self:Show()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(unit)
	local name, text, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo(unit)
	if not name then
		self:Hide()
		return
	end

	self.value = (endTime / 1000) - GetTime()
	self.maxValue = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.maxValue)
	self:SetValue(self.value)

	local startColor = self:GetStartColor(notInterruptible)
	self:SetStatusBarColor(startColor:GetRGB())
	self.Text:SetText(text)
	self.Spark:Hide()
	self:ShowNotInterruptible(notInterruptible)

	self.casting = nil
	self.channeling = true
	self.holdTime = 0
	self.fadeOut = nil

	self:SetAlpha(1)
	self:Show()
end

function CastBar:UNIT_SPELLCAST_DELAYED(unit)
	if not self:IsShown() then return end
	local name, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
	if not name then
		self:Hide()
		return
	end

	self.value = GetTime() - (startTime / 1000)
	self.maxValue = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.maxValue)
	self:SetValue(self.value)

	if not self.casting then
		local startColor = self:GetStartColor(notInterruptible)
		self:SetStatusBarColor(startColor:GetRGB())
		self.Spark:Show()
		self.Flash:SetAlpha(0)
		self.Flash:Hide()

		self.casting = true
		self.channeling = nil
		self.flash = nil
		self.fadeOut = nil
	end
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(unit)
	if not self:IsShown() then return end
	local name, _, _, startTime, endTime, _ = UnitChannelInfo(unit)
	if not name then
		self:Hide()
		return
	end
	self.value = (endTime / 1000) - GetTime()
	self.maxValue = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.maxValue)
	self:SetValue(self.value)
end

function CastBar:UNIT_SPELLCAST_STOP(unit, castID)
	if not self:IsVisible() then
		self:Hide()
		return
	end
	if self.casting and (castID == self.castID) then
		self:SetValue(self.maxValue)
		self:SetStatusBarColor(self.finishedCastColor:GetRGB())
		self.Spark:Hide()
		self.Flash:Show()
		self.Flash:SetAlpha(0)

		self.casting = nil
		self.holdTime = 0
		self.flash = true
		self.fadeOut = true
	end
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(unit)
	if not self:IsVisible() then
		self:Hide()
		return
	end
	if self.channeling then
		self:SetValue(self.maxValue)
		self.Spark:Hide()
		self.Flash:Show()
		self.Flash:SetAlpha(0)

		self.channeling = nil
		self.holdTime = 0
		self.flash = true
		self.fadeOut = true
	end
end

function CastBar:UNIT_SPELLCAST_FAILED(unit, castID)
	if self:IsShown() and 
		(self.casting and castID == self.castID) and 
		not self.fadeOut
	then
		self:SetValue(self.maxValue)
		self:SetStatusBarColor(self.failedCastColor:GetRGB())
		self.Spark:Hide()
		self.Text:SetText(FAILED)
		self.casting = nil
		self.channeling = nil
		self.fadeOut = true
		self.holdTime = GetTime() + HOLD_TIME
	end
end

function CastBar:UNIT_SPELLCAST_INTERRUPTED(unit, castID)
	if self:IsShown() and 
		(self.casting and castID == self.castID) and 
		not self.fadeOut
	then
		self:SetValue(self.maxValue)
		self:SetStatusBarColor(self.failedCastColor:GetRGB())
		self.Spark:Hide()
		self.Text:SetText(INTERRUPTED)
		self.casting = nil
		self.channeling = nil
		self.fadeOut = true
		self.holdTime = GetTime() + HOLD_TIME
	end
end

function CastBar:UNIT_SPELLCAST_INTERRUPTIBLE()
	self:ShowNotInterruptible(false)
	self:SetStatusBarColor(self.startCastColor:GetRGB())
end

function CastBar:UNIT_SPELLCAST_NOT_INTERRUPTIBLE()
	self:ShowNotInterruptible(true)
	self:SetStatusBarColor(self.notInterruptibleColor:GetRGB())
end

function CastBar:GetStartColor(notInterruptible)
	if notInterruptible then
		return self.notInterruptibleColor
	else
		return self.startCastColor
	end
end

function CastBar:ShowNotInterruptible(notInterruptible)
	-- Show/hide icon indicating not interruptible
	if notInterruptible then
		self.BorderShield:Show()
	else
		self.BorderShield:Hide()
	end
end

function CastBar:OnUpdate(elapsed)
	if self.casting then
		self.value = self.value + elapsed
		if self.value >= self.maxValue then
			self:SetValue(self.maxValue)
			self:FinishSpell()
			return
		end
		self:SetValue(self.value)
		local sparkPosition = (self.value / self.maxValue) * self:GetWidth()
		self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, -1)
		self.Flash:Hide()
	elseif self.channeling then
		self.value = self.value - elapsed
		if self.value <= 0 then
			self:FinishSpell()
			return
		end
		self:SetValue(self.value)
		self.Flash:Hide()
	elseif GetTime() < self.holdTime then
		return
	elseif self.flash then
		local alpha = 0
		alpha = self.Flash:GetAlpha() + FLASH_STEP
		if alpha < 1 then
			self.Flash:SetAlpha(alpha)
		else
			self.Flash:SetAlpha(1)
			self.flash = nil
		end
	elseif self.fadeOut then
		local alpha = self:GetAlpha() - ALPHA_STEP
		if alpha > 0 then
			self:SetAlpha(alpha)
		else
			self.fadeOut = nil
			self:Hide()
		end
	end
end

function CastBar:FinishSpell()
	self:SetStatusBarColor(self.finishedCastColor:GetRGB())
	self.Spark:Hide()
	self.Flash:Show()
	self.Flash:SetAlpha(0)
	self.casting = nil
	self.channeling = nil
	self.flash = true
	self.fadeOut = true
end
