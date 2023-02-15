-- Nameplate cast bar

local _, NephilistNameplates = ...
local CastBar = NephilistNameplates.CastBar

-- Local versions of global functions
local GetTime = GetTime
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo


--[[ CastBar functions ]]-- 

function CastBar:Initialize()
	-- Called by NephilistNameplates.UnitFrame:Initialize()
	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)
	self:OnLoad(nil, false, true)
end

function CastBar:OnLoad(unit, showTradeSkills, showShield)
	self.startCastColor = CreateColor(0.6, 0.6, 0.6)
	self.startChannelColor = CreateColor(0.6, 0.6, 0.6)
	self.finishedCastColor = CreateColor(0.6, 0.6, 0.6)
	self.failedCastColor = CreateColor(0.5, 0.2, 0.2)
	self.nonInterruptibleColor = CreateColor(0.3, 0.3, 0.3)
	self:AddWidgetForFade(self.BorderShield)

	--classic cast bars should flash green when finished casting
	--CastingBarFrame_SetUseStartColorForFinished(self, true)
	-- CastingBarFrame_SetUseStartColorForFlash(self, true)
	self.finishedColorSameAsStart = true
	self.flashColorSameAsStart = true

	self:SetUnit(unit, showTradeSkills, showShield)

	self.showCastbar = true
	self.notInterruptible = false
end

function CastBar:Update()
end

function CastBar:AddWidgetForFade(widget)
	-- Fade additional widgets with cast bar in case they're not parented or use ignoreParentAlpha
	if not self.additionalFadeWidgets then
		self.additionalFadeWidgets = {}
	end
	self.additionalFadeWidgets[widget] = true
end

function CastBar:SetUnit(unit, showTradeSkills, showShield)
	if self.unit ~= unit then
		self.unit = unit
		self.showTradeSkills = showTradeSkills
		self.showShield = showShield

		self.casting = nil
		self.channeling = nil
		self.holdTime = 0
		self.fadeOut = nil

		if unit then
			self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
			self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
			self:RegisterEvent("PLAYER_ENTERING_WORLD")
			self:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
			self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
			self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)

			self:OnEvent("PLAYER_ENTERING_WORLD")
		else
			self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
			self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
			self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
			self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
			self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
			self:UnregisterEvent("PLAYER_ENTERING_WORLD")
			self:UnregisterEvent("UNIT_SPELLCAST_START")
			self:UnregisterEvent("UNIT_SPELLCAST_STOP")
			self:UnregisterEvent("UNIT_SPELLCAST_FAILED")

			self:Hide()
		end
	end
end

function CastBar:OnShow()
	if self.unit then
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
end

function CastBar:GetEffectiveStartColor(isChannel)
	return isChannel and self.startChannelColor or self.startCastColor
end

function CastBar:OnEvent(event, ...)
	local arg1 = ...

	local unit = self.unit
	if event == "PLAYER_ENTERING_WORLD" then
		local nameChannel = UnitChannelInfo(unit)
		local nameSpell = UnitCastingInfo(unit)
		if nameChannel then
			event = "UNIT_SPELLCAST_CHANNEL_START"
			arg1 = unit
		elseif nameSpell then
			event = "UNIT_SPELLCAST_START"
			arg1 = unit
		else
			self:FinishSpell()
		end
	end

	if arg1 ~= unit then
		return
	end

	if event == "UNIT_SPELLCAST_START" then
		local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
		self.notInterruptible = notInterruptible

		--[[
		if notInterruptible then
			CastingBarFrame_SetUseStartColorForFinished(self, false)
		end
		]]--

		if not name or (not self.showTradeSkills and isTradeSkill) then
			self:Hide()
			return
		end

		local startColor = self:GetEffectiveStartColor(false)
		self:SetStatusBarColor(startColor:GetRGB())
		if self.flashColorSameAsStart then
			self.Flash:SetVertexColor(startColor:GetRGB())
		else
			self.Flash:SetVertexColor(1, 1, 1)
		end
		
		if self.Spark then
			self.Spark:Show()
		end
		self.value = GetTime() - (startTime / 1000)
		self.maxValue = (endTime - startTime) / 1000
		self:SetMinMaxValues(0, self.maxValue)
		self:SetValue(self.value)
		if self.Text then
			self.Text:SetText(text)
		end
		--[[
		if self.Icon then
			CastingBarFrame_SetIcon(self, texture)
			if self.iconWhenNoninterruptible then
				self.Icon:SetShown(not notInterruptible)
			end
		end
		]]--
		self:ApplyAlpha(1)
		self.holdTime = 0
		self.casting = true
		self.castID = castID
		self.channeling = nil
		self.fadeOut = nil

		if self.BorderShield then
			if self.showShield and notInterruptible then
				self.BorderShield:Show()
				if self.BarBorder then
					self.BarBorder:Hide()
				end
			else
				self.BorderShield:Hide()
				if self.BarBorder then
					self.BarBorder:Show()
				end
			end
		end
		if self.showCastbar then
			self:Show()
		end

	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if not self:IsVisible() then
			self:Hide()
		end
		if ( (self.casting and event == "UNIT_SPELLCAST_STOP" and select(2, ...) == self.castID) or
		     (self.channeling and event == "UNIT_SPELLCAST_CHANNEL_STOP") ) then
			if self.Spark then
				self.Spark:Hide()
			end
			if self.Flash then
				self.Flash:SetAlpha(0.0)
				self.Flash:Show()
			end
			self:SetValue(self.maxValue)
			if event == "UNIT_SPELLCAST_STOP" then
				self.casting = nil
				if not self.finishedColorSameAsStart then
					self:SetStatusBarColor(self.finishedCastColor:GetRGB())
				end
			else
				self.channeling = nil
			end
			self.flash = true
			self.fadeOut = true
			self.holdTime = 0
		end
	elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		if ( self:IsShown() and (self.casting and select(2, ...) == self.castID) and not self.fadeOut ) then
			self:SetValue(self.maxValue)
			self:SetStatusBarColor(self.failedCastColor:GetRGB())
			if self.Spark then
				self.Spark:Hide()
			end
			if self.Text then
				if event == "UNIT_SPELLCAST_FAILED" then
					self.Text:SetText(FAILED)
				else
					self.Text:SetText(INTERRUPTED)
				end
			end
			self.casting = nil
			self.channeling = nil
			self.fadeOut = true
			self.holdTime = GetTime() + CASTING_BAR_HOLD_TIME
		end
	elseif event == "UNIT_SPELLCAST_DELAYED" then
		if self:IsShown() then
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
			self.notInterruptible = notInterruptible

			if ( not name or (not self.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				self:Hide()
				return
			end
			self.value = GetTime() - (startTime / 1000)
			self.maxValue = (endTime - startTime) / 1000
			self:SetMinMaxValues(0, self.maxValue)
			if not self.casting then
				self:SetStatusBarColor(self:GetEffectiveStartColor(false):GetRGB())
				if self.Spark then
					self.Spark:Show()
				end
				if self.Flash then
					self.Flash:SetAlpha(0.0)
					self.Flash:Hide()
				end
				self.casting = true
				self.channeling = nil
				self.flash = nil
				self.fadeOut = nil
			end
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
		self.notInterruptible = notInterruptible

		if ( not name or (not self.showTradeSkills and isTradeSkill)) then
			-- if there is no name, there is no bar
			self:Hide()
			return
		end

		local startColor = self:GetEffectiveStartColor(true)
		if self.flashColorSameAsStart then
			self.Flash:SetVertexColor(startColor:GetRGB())
		else
			self.Flash:SetVertexColor(1, 1, 1)
		end
		self:SetStatusBarColor(startColor:GetRGB())
		self.value = (endTime / 1000) - GetTime()
		self.maxValue = (endTime - startTime) / 1000
		self:SetMinMaxValues(0, self.maxValue)
		self:SetValue(self.value)
		if self.Text then
			self.Text:SetText(text)
		end
		--[[
		if self.Icon then
			CastingBarFrame_SetIcon(self, texture)
		end
		]]--
		if self.Spark then
			self.Spark:Hide()
		end
		self:ApplyAlpha(1)
		self.holdTime = 0
		self.casting = nil
		self.channeling = true
		self.fadeOut = nil
		if self.BorderShield then
			if self.showShield and notInterruptible then
				self.BorderShield:Show()
				if self.BarBorder then
					self.BarBorder:Hide()
				end
			else
				self.BorderShield:Hide()
				if self.BarBorder then
					self.BarBorder:Show()
				end
			end
		end
		if self.showCastbar then
			self:Show()
		end
	elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
		if self:IsShown() then
			local name, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)
			if ( not name or (not self.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				self:Hide()
				return
			end
			self.value = (endTime / 1000) - GetTime()
			self.maxValue = (endTime - startTime) / 1000
			self:SetMinMaxValues(0, self.maxValue)
			self:SetValue(self.value)
		end
	elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
		-- CastingBarFrame_UpdateInterruptibleState(self, event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
		self:UpdateInterruptibleState(event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
	end
end

function CastBar:UpdateInterruptibleState(notInterruptible)
	if self.casting or self.channeling then
		local startColor = self:GetEffectiveStartColor(self.channeling)
		self:SetStatusBarColor(startColor:GetRGB())

		if self.flashColorSameAsStart then
			self.Flash:SetVertexColor(startColor:GetRGB())
		end

		if self.BorderShield then
			if elf.showShield and notInterruptible then
				self.BorderShield:Show()
				if self.BarBorder then
					self.BarBorder:Hide()
				end
			else
				self.BorderShield:Hide()
				if self.BarBorder then
					self.BarBorder:Show()
				end
			end
		end

		--[[
		if self.Icon and self.iconWhenNoninterruptible then
			self.Icon:SetShown(not notInterruptible)
		end
		]]--
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
		if self.Flash then
			self.Flash:Hide()
		end
		if self.Spark then
			local sparkPosition = (self.value / self.maxValue) * self:GetWidth()
			self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, self.Spark.offsetY or 2)
		end
	elseif self.channeling then
		self.value = self.value - elapsed
		if self.value <= 0 then
			self:FinishSpell()
			return
		end
		self:SetValue(self.value)
		if self.Flash then
			self.Flash:Hide()
		end
	elseif GetTime() < self.holdTime then
		return
	elseif self.flash then
		local alpha = 0
		if self.Flash then
			alpha = self.Flash:GetAlpha() + CASTING_BAR_FLASH_STEP
		end
		if alpha < 1 then
			if self.Flash then
				self.Flash:SetAlpha(alpha)
			end
		else
			if self.Flash then
				self.Flash:SetAlpha(1.0)
			end
			self.flash = nil
		end
	elseif self.fadeOut then
		local alpha = self:GetAlpha() - CASTING_BAR_ALPHA_STEP
		if alpha > 0 then
			self:ApplyAlpha(alpha)
		else
			self.fadeOut = nil
			self:Hide()
		end
	end
end

function CastBar:FinishSpell()
	if not self.finishedColorSameAsStart then
		self:SetStatusBarColor(self.finishedCastColor:GetRGB())
	end
	if self.Spark then
		self.Spark:Hide()
	end
	if self.Flash then
		self.Flash:SetAlpha(0)
		self.Flash:Show()
	end
	self.flash = true
	self.fadeOut = true
	self.casting = nil
	self.channeling = nil
end

function CastBar:ApplyAlpha(alpha)
	self:SetAlpha(alpha)
	if self.additionalFadeWidgets then
		for widget in pairs(self.additionalFadeWidgets) do
			widget:SetAlpha(alpha)
		end
	end
end
