local addonName, NephilistNameplates = ...

local DriverFrame = NephilistNameplates.DriverFrame
local PlayerPlate = NephilistNameplates.PlayerPlate


--[[ Default settings ]]-- 

NephilistNameplates.Defaults = {
	ColorRareNames = true, 
	HideClassBar = false, 
	ShowBuffsOnPlayer = true, 
	ShowDebuffsOnEnemy = true, 
	ShowEliteIcon = true, 
	ShowLevel = true, 
	ShowLossBar = true, 
	ShowPlayerPlate = false, 
	ShowThreat = false, 
	ShowThreatOnlyInGroup = false, 
	PlayerPlateLocked = true, 
	PlayerPlateOutOfCombatAlpha = 0.2, 
	PlayerPlatePosition = {"TOP", UIParent, "CENTER", 0, -150}, 
	OnlyShowOwnBuffs = true, 
	Version = C_AddOns.GetAddOnMetadata(addonName, "Version")
}


--[[ Interface options panel ]]-- 

NephilistNameplates.OptionsPanel = NephilistNameplates:CreateOptionsPanel()

local optionsPanel = NephilistNameplates.OptionsPanel
optionsPanel.savedVariablesName = "NephilistNameplatesOptions"
optionsPanel.defaults = NephilistNameplates.Defaults
optionsPanel.defaultsFunc = NephilistNameplates.Update
optionsPanel.okayFunc = NephilistNameplates.Update

-- Show/Hide

optionsPanel.showHideText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
optionsPanel.showHideText:SetPoint("TOPLEFT", optionsPanel.subtext, "BOTTOMLEFT", 2, -34)

optionsPanel.showLevelButton = optionsPanel:CreateCheckButton("ShowLevel")
local showLevelButton = optionsPanel.showLevelButton
showLevelButton:SetPoint("TOPLEFT", optionsPanel.showHideText, "BOTTOMLEFT", 0, -8)
showLevelButton.onValueChanged = NephilistNameplates.Update

optionsPanel.showBuffsOnPlayerButton = optionsPanel:CreateCheckButton("ShowBuffsOnPlayer")
local showBuffsOnPlayerButton = optionsPanel.showBuffsOnPlayerButton
showBuffsOnPlayerButton:SetPoint("TOPLEFT", showLevelButton, "BOTTOMLEFT", 0, -8)
showBuffsOnPlayerButton.onValueChanged = NephilistNameplates.Update

optionsPanel.showDebuffsOnEnemyButton = optionsPanel:CreateCheckButton("ShowDebuffsOnEnemy")
local showDebuffsOnEnemyButton = optionsPanel.showDebuffsOnEnemyButton
showDebuffsOnEnemyButton:SetPoint("TOPLEFT", showBuffsOnPlayerButton, "BOTTOMLEFT", 0, -8)
showDebuffsOnEnemyButton.onValueChanged = NephilistNameplates.Update

optionsPanel.onlyShowOwnBuffsButton = optionsPanel:CreateCheckButton("OnlyShowOwnBuffs")
local onlyShowOwnBuffsButton = optionsPanel.onlyShowOwnBuffsButton
onlyShowOwnBuffsButton:SetPoint("TOPLEFT", optionsPanel.showDebuffsOnEnemyButton, "BOTTOMLEFT", 0, -8)
onlyShowOwnBuffsButton.onValueChanged = NephilistNameplates.Update

optionsPanel.hideClassBarButton = optionsPanel:CreateCheckButton("HideClassBar")
local hideClassBarButton = optionsPanel.hideClassBarButton
hideClassBarButton:SetPoint("TOPLEFT", optionsPanel.onlyShowOwnBuffsButton, "BOTTOMLEFT", 0, -8)
hideClassBarButton.onValueChanged = NephilistNameplates.Update

local showThreatButton = optionsPanel:CreateCheckButton("ShowThreat")
optionsPanel.showThreatButton = showThreatButton
showThreatButton:SetPoint("LEFT", optionsPanel.showLevelButton, 280, 0)
showThreatButton.onValueChanged = NephilistNameplates.Update

local showThreatOnlyInGroupButton = optionsPanel:CreateCheckButton("ShowThreatOnlyInGroup")
optionsPanel.showThreatOnlyInGroupButton = showThreatOnlyInGroupButton
showThreatOnlyInGroupButton:SetPoint("TOPLEFT", optionsPanel.showThreatButton, "BOTTOMLEFT", 0, -8)
showThreatOnlyInGroupButton.onValueChanged = NephilistNameplates.Update

local showLossBarButton = optionsPanel:CreateCheckButton("ShowLossBar")
optionsPanel.showLossBarButton = showLossBarButton
showLossBarButton:SetPoint("TOPLEFT", optionsPanel.showThreatOnlyInGroupButton, "BOTTOMLEFT", 0, -8)
showLossBarButton.onValueChanged = NephilistNameplates.Update


-- PlayerPlate

optionsPanel.playerPlateText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
optionsPanel.playerPlateText:SetPoint("TOPLEFT", optionsPanel.hideClassBarButton, "BOTTOMLEFT", 0, -30)

optionsPanel.showPlayerPlateButton = optionsPanel:CreateCheckButton("ShowPlayerPlate")
local showPlayerPlateButton = optionsPanel.showPlayerPlateButton
showPlayerPlateButton:SetPoint("TOPLEFT", optionsPanel.playerPlateText, "BOTTOMLEFT", 0, -8)
showPlayerPlateButton.onValueChanged = PlayerPlate.Update

local lockPlayerPlateButton = optionsPanel:CreateCheckButton("PlayerPlateLocked")
optionsPanel.lockPlayerPlateButton = lockPlayerPlateButton
lockPlayerPlateButton:SetPoint("TOPLEFT", optionsPanel.showPlayerPlateButton, "BOTTOMLEFT", 0, -8)
lockPlayerPlateButton.onValueChanged = PlayerPlate.Update

local outOfCombatAlpha = optionsPanel:CreateSlider("PlayerPlateOutOfCombatAlpha")
optionsPanel.outOfCombatAlpha = outOfCombatAlpha
outOfCombatAlpha:SetPoint("TOPLEFT", optionsPanel.lockPlayerPlateButton, "BOTTOMLEFT", 24, -26)
outOfCombatAlpha:SetMinMaxValues(0, 1)
outOfCombatAlpha:SetValueStep(0.05)
outOfCombatAlpha:SetObeyStepOnDrag(true)
outOfCombatAlpha.onValueChanged = PlayerPlate.Update



