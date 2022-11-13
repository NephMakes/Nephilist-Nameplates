local addonName, NephilistNameplates = ...

local PlayerPlate = NephilistNameplates.PlayerPlate


--[[ Default settings ]]-- 

NephilistNameplates.Defaults = {
	ColorRareNames = true, 
	HideClassBar = false, 
	ShowBuffs = true, 
	ShowEliteIcon = true, 
	ShowLevel = true, 
	ShowPlayerPlate = false, 
	PlayerPlateLocked = true, 
	PlayerPlateOutOfCombatAlpha = 0.2, 
	PlayerPlatePosition = {"TOP", UIParent, "CENTER", 0, -150}, 
	OnlyShowOwnBuffs = true, 
	Version = GetAddOnMetadata(addonName, "Version")
}


--[[ Interface options panel ]]-- 

NephilistNameplates.OptionsPanel = NephilistNameplates:CreateOptionsPanel()

local optionsPanel = NephilistNameplates.OptionsPanel
optionsPanel.savedVariablesName = "NephilistNameplatesOptions"
optionsPanel.defaults = NephilistNameplates.Defaults
optionsPanel.defaultsFunc = NephilistNameplates.DriverFrame.UpdateNamePlateOptions
optionsPanel.okayFunc = NephilistNameplates.DriverFrame.UpdateNamePlateOptions

optionsPanel.showLevelButton = optionsPanel:CreateCheckButton("ShowLevel")
local showLevelButton = optionsPanel.showLevelButton
showLevelButton:SetPoint("TOPLEFT", optionsPanel.subtext, "BOTTOMLEFT", 2, -34)
showLevelButton.onValueChanged = NephilistNameplates.DriverFrame.UpdateNamePlateOptions

optionsPanel.showBuffsButton = optionsPanel:CreateCheckButton("ShowBuffs")
local showBuffsButton = optionsPanel.showBuffsButton
showBuffsButton:SetPoint("TOPLEFT", showLevelButton, "BOTTOMLEFT", 0, -12)
-- showBuffsButton.onValueChanged = function() end

optionsPanel.onlyShowOwnBuffsButton = optionsPanel:CreateCheckButton("OnlyShowOwnBuffs")
local onlyShowOwnBuffsButton = optionsPanel.onlyShowOwnBuffsButton
onlyShowOwnBuffsButton:SetPoint("TOPLEFT", optionsPanel.showBuffsButton, "BOTTOMLEFT", 0, -12)
-- onlyShowOwnBuffsButton.onValueChanged = function() end

optionsPanel.hideClassBarButton = optionsPanel:CreateCheckButton("HideClassBar")
local hideClassBarButton = optionsPanel.hideClassBarButton
hideClassBarButton:SetPoint("TOPLEFT", optionsPanel.onlyShowOwnBuffsButton, "BOTTOMLEFT", 0, -12)
-- hideClassBarButton.onValueChanged = function() end

optionsPanel.showPlayerPlateButton = optionsPanel:CreateCheckButton("ShowPlayerPlate")
local showPlayerPlateButton = optionsPanel.showPlayerPlateButton
showPlayerPlateButton:SetPoint("TOPLEFT", optionsPanel.hideClassBarButton, "BOTTOMLEFT", 0, -12)
showPlayerPlateButton.onValueChanged = PlayerPlate.Update

local lockPlayerPlateButton = optionsPanel:CreateCheckButton("PlayerPlateLocked")
optionsPanel.lockPlayerPlateButton = lockPlayerPlateButton
lockPlayerPlateButton:SetPoint("TOPLEFT", optionsPanel.showPlayerPlateButton, "BOTTOMLEFT", 0, -12)
lockPlayerPlateButton.onValueChanged = PlayerPlate.Update

local outOfCombatAlpha = optionsPanel:CreateSlider("PlayerPlateOutOfCombatAlpha")
optionsPanel.outOfCombatAlpha = outOfCombatAlpha
outOfCombatAlpha:SetPoint("TOPLEFT", optionsPanel.lockPlayerPlateButton, "BOTTOMLEFT", 12, -24)
outOfCombatAlpha:SetMinMaxValues(0, 1)
outOfCombatAlpha:SetValueStep(0.05)
outOfCombatAlpha:SetObeyStepOnDrag(true)
outOfCombatAlpha.onValueChanged = PlayerPlate.Update



