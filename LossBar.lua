-- Animated health loss bar

local addonName, NephilistNameplates = ...

local LossBar = NephilistNameplates.LossBar
local UnitFrame = NephilistNameplates.UnitFrame


function LossBar:Initialize()
	self:SetAllPoints(self:GetParent().healthBar)
	self:SetDuration(0.25)
	self:SetStartDelay(0.1)
	self:SetPauseDelay(0.05)
	self:SetPostponeDelay(0.05)
end

function LossBar:SetDuration(duration)
	self.animationDuration = duration or 0
end

function LossBar:SetStartDelay(delay)
	self.animationStartDelay = delay or 0
end

function LossBar:SetPauseDelay(delay)
	self.animationPauseDelay = delay or 0
end

function LossBar:SetPostponeDelay(delay)
	self.animationPostponeDelay = delay or 0
end

function LossBar:UpdateHealth(currentHealth, previousHealth)
	local delta = currentHealth - previousHealth
	local hasLoss = delta < 0
	local hasBegun = self.animationStartTime ~= nil
	local isAnimating = hasBegun and self.animationCompletePercent > 0

	if hasLoss and not hasBegun then
		-- self:BeginAnimation(previousHealth)
	elseif hasLoss and hasBegun and not isAnimating then
		-- self:PostponeStartTime()
	elseif hasLoss and isAnimating then
		-- Reset the starting value of the health to what the animated loss bar was when the new incoming damage happened
		-- and pause briefly when new damage occurs.
		-- self.animationStartValue = self:GetHealthLossAnimationData(previousHealth, self.animationStartValue)
		self.animationStartTime = GetTime() + self.animationPauseDelay
	elseif not hasLoss and hasBegun and currentHealth >= self.animationStartValue then
		-- self:CancelAnimation()
	end
end

function LossBar:BeginAnimation(value)
	self.animationStartValue = value
	self.animationStartTime = GetTime() + self.animationStartDelay
	self.animationCompletePercent = 0
	self:Show()
	self:SetValue(self.animationStartValue)
end

function LossBar:PostponeStartTime()
	self.animationStartTime = self.animationStartTime + self.animationPostponeDelay
end

function LossBar:GetHealthLossAnimationData(currentHealth, previousHealth)
	if self.animationStartTime then
		local totalElapsedTime = GetTime() - self.animationStartTime
		if totalElapsedTime > 0 then
			local animCompletePercent = totalElapsedTime / self.animationDuration
			if animCompletePercent < 1 and previousHealth > currentHealth then
				local healthDelta = previousHealth - currentHealth
				local animatedLossAmount = previousHealth - (animCompletePercent * healthDelta);
				return animatedLossAmount, animCompletePercent
			end
		else
			return previousHealth, 0
		end
	end
	return 0, 1 -- Animated loss amount is 0, and the animation is fully complete.
end

function LossBar:UpdateLossAnimation(currentHealth)
	-- Called by ...

	local totalAbsorb = UnitGetTotalAbsorbs(self.unit) or 0
	if totalAbsorb > 0 then
		self:CancelAnimation()
	end

	if self.animationStartTime then
		local animationValue, animationCompletePercent = self:GetHealthLossAnimationData(currentHealth, self.animationStartValue)
		self.animationCompletePercent = animationCompletePercent
		if animationCompletePercent >= 1 then
			self:CancelAnimation()
		else
			self:SetValue(animationValue)
		end
	end
end

function LossBar:CancelAnimation()
	self:Hide()
	self.animationStartTime = nil
	self.animationCompletePercent = nil
end



--[[ Blizzard code for reference ]]-- 

--[[
local AnimatedHealthLossMixin = {};

function AnimatedHealthLossMixin:SetUnitHealthBar(unit, healthBar)
	if self.unit ~= unit then
		healthBar.AnimatedLossBar = self;

		self.unit = unit;
		self:SetAllPoints(healthBar);
		self:UpdateHealthMinMax();
	end
end

function UnitFrameHealthBar_OnUpdate(self)
	if ( not self.disconnected and not self.lockValues) then
		local currValue = UnitHealth(self.unit);
		local animatedLossBar = self.AnimatedLossBar;

		if ( currValue ~= self.currValue ) then
			if ( not self.ignoreNoUnit or UnitGUID(self.unit) ) then

				if animatedLossBar then
					animatedLossBar:UpdateHealth(currValue, self.currValue);
				end

				self:SetValue(currValue);
				self.currValue = currValue;
				TextStatusBar_UpdateTextString(self);
				UnitFrameHealPredictionBars_Update(self.unitFrame);
			end
		end

		if animatedLossBar then
			animatedLossBar:UpdateLossAnimation(currValue);
		end
	end
end
]]--





