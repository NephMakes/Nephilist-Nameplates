-- Nameplate cast bar

local _, NephilistNameplates = ...
local CastBar = NephilistNameplates.CastBar

-- Constants
local ALPHA_STEP = 0.05
local FLASH_STEP = 0.2
local HOLD_TIME = 1
local FAILED = FAILED  -- Blizz localized string
local INTERRUPTED = INTERRUPTED  -- Blizz localized string

-- Local versions of global functions
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo


--[[ CastBar functions ]]-- 

function CastBar:OnLoad()
	-- Called by NephilistNameplates.UnitFrame:Initialize()
	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)

	self.startCastColor = CreateColor(0.6, 0.6, 0.6)
	self.startChannelColor = CreateColor(0.6, 0.6, 0.6)
	self.finishedCastColor = CreateColor(0.7, 0.7, 0.7)
	self.failedCastColor = CreateColor(0.5, 0.2, 0.2)
	self.nonInterruptibleColor = CreateColor(0.3, 0.3, 0.3)
	self.Flash:SetVertexColor(1, 1, 1)

	self:SetUnit(nil)
	self.notInterruptible = false
end

function CastBar:SetUnit(unit)
	-- Called by CastBar:OnLoad, NephilistNameplates.UnitFrame:UpdateCastBar
	if self.unit == unit then return end  -- Job's done
	self.unit = unit
	self.casting = nil
	self.channeling = nil
	self.holdTime = 0
	self.fadeOut = nil
	if unit then
		self:RegisterEvents(unit)
		self:OnEvent("PLAYER_ENTERING_WORLD")
	else
		self:UnregisterEvents()
		self:Hide()
	end
end

function CastBar:RegisterEvents(unit)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
	self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
end

function CastBar:UnregisterEvents()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
	self:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_START")
	self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
end

function CastBar:OnShow()
	if not self.unit then return end
	if self.casting then
		local _, _, _, startTime = UnitCastingInfo(self.unit)
		if startTime then
			self.value = GetTime() - (startTime / 1000)
		end
	else
		local _, _, _, _, endTime = UnitChannelInfo(self.unit)
		if endTime then
			self.value = (endTime / 1000) - GetTime()
		end
	end
end

function CastBar:GetEffectiveStartColor(isChannel)
	return (isChannel and self.startChannelColor) or self.startCastColor
end

function CastBar:OnEvent(event, ...)
	local arg1 = ...
	local unit = self.unit
	if arg1 ~= unit then return end

	local eventFunction = self[event]
	if eventFunction then
		eventFunction(self, unit, ...)
	end

	if event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if not self:IsVisible() then
			self:Hide()
			return
		end
		if (self.casting and event == "UNIT_SPELLCAST_STOP" and select(2, ...) == self.castID) or
			(self.channeling and event == "UNIT_SPELLCAST_CHANNEL_STOP") 
		then
			self.Spark:Hide()
			self.Flash:SetAlpha(0)
			self.Flash:Show()
			self:SetValue(self.maxValue)
			if event == "UNIT_SPELLCAST_STOP" then
				self.casting = nil
				self:SetStatusBarColor(self.finishedCastColor:GetRGB())
			else
				self.channeling = nil
			end
			self.flash = true
			self.fadeOut = true
			self.holdTime = 0
		end
	elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if self:IsShown() and 
			(self.casting and select(2, ...) == self.castID) and 
			not self.fadeOut
		then
			self:SetValue(self.maxValue)
			self:SetStatusBarColor(self.failedCastColor:GetRGB())
			self.Spark:Hide()
			if event == "UNIT_SPELLCAST_FAILED" then
				self.Text:SetText(FAILED)
			else
				self.Text:SetText(INTERRUPTED)
			end
			self.casting = nil
			self.channeling = nil
			self.fadeOut = true
			self.holdTime = GetTime() + HOLD_TIME
		end
	end
end

function CastBar:PLAYER_ENTERING_WORLD(unit)
	-- Check if cast in progress
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
	self.notInterruptible = notInterruptible

	if not name then
		self:Hide()
		return
	end

	local startColor = self:GetEffectiveStartColor(false)
	self:SetStatusBarColor(startColor:GetRGB())
	
	self.Spark:Show()
	self.value = GetTime() - (startTime / 1000)
	self.maxValue = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.maxValue)
	self:SetValue(self.value)
	self.Text:SetText(text)
	self:SetAlpha(1)

	self.holdTime = 0
	self.casting = true
	self.castID = castID
	self.channeling = nil
	self.fadeOut = nil

	if notInterruptible then
		self.BorderShield:Show()
	else
		self.BorderShield:Hide()
	end
	self:Show()
end

function CastBar:UNIT_SPELLCAST_DELAYED(unit)
	if not self:IsShown() then return end

	local name, _, _, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
	self.notInterruptible = notInterruptible

	if not name then
		self:Hide()
		return
	end

	self.value = GetTime() - (startTime / 1000)
	self.maxValue = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.maxValue)
	if not self.casting then
		self:SetStatusBarColor(self:GetEffectiveStartColor(false):GetRGB())
		self.Spark:Show()
		self.Flash:SetAlpha(0)
		self.Flash:Hide()
		self.casting = true
		self.channeling = nil
		self.flash = nil
		self.fadeOut = nil
	end
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(unit)
	local name, text, _, startTime, endTime, _, notInterruptible, _ = UnitChannelInfo(unit)
	self.notInterruptible = notInterruptible

	if not name then
		self:Hide()
		return
	end

	local startColor = self:GetEffectiveStartColor(true)
	self:SetStatusBarColor(startColor:GetRGB())
	self.value = (endTime / 1000) - GetTime()
	self.maxValue = (endTime - startTime) / 1000
	self:SetMinMaxValues(0, self.maxValue)
	self:SetValue(self.value)
	self.Text:SetText(text)
	self.Spark:Hide()
	self:SetAlpha(1)

	self.holdTime = 0
	self.casting = nil
	self.channeling = true
	self.fadeOut = nil

	if notInterruptible then
		self.BorderShield:Show()
	else
		self.BorderShield:Hide()
	end
	self:Show()
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

function CastBar:UNIT_SPELLCAST_INTERRUPTIBLE()
	self:UpdateInterruptible(true)
end

function CastBar:UNIT_SPELLCAST_NOT_INTERRUPTIBLE()
	self:UpdateInterruptible(false)
end

function CastBar:UpdateInterruptible(isInterruptible)
	if self.casting or self.channeling then
		local startColor = self:GetEffectiveStartColor(self.channeling)
		self:SetStatusBarColor(startColor:GetRGB())
		if isInterruptible then
			self.BorderShield:Hide()
		else
			self.BorderShield:Show()
		end
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
		self.Flash:Hide()
		local sparkPosition = (self.value / self.maxValue) * self:GetWidth()
		self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, -1)
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
	self.Flash:SetAlpha(0)
	self.Flash:Show()
	self.flash = true
	self.fadeOut = true
	self.casting = nil
	self.channeling = nil
end
