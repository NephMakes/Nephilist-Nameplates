local addonName, NephilistNameplates = ...

-- local Strings = NephilistNameplates.Strings;

--[[ Defaults ]]-- 

NephilistNameplates.Defaults = {
	ColorRareNames = true, 
	HideClassBar = false,
	OnlyShowOwnBuffs = true,
	ShowBuffs = true,
	ShowEliteIcon = true, 
	ShowLevel = true,
	Version = GetAddOnMetadata(addonName, "Version")
}


--[[ Interface options panel ]]-- 

NephilistNameplates.OptionsPanel = NephilistNameplates:CreateOptionsPanel();
local optionsPanel = NephilistNameplates.OptionsPanel;
optionsPanel.savedVariablesName = "NephilistNameplatesOptions";
optionsPanel.defaults = NephilistNameplates.Defaults;
optionsPanel.defaultsFunc = NephilistNameplates.DriverFrame.UpdateNamePlateOptions;
optionsPanel.okayFunc = NephilistNameplates.DriverFrame.UpdateNamePlateOptions;

optionsPanel.showLevelButton = optionsPanel:CreateCheckButton("ShowLevel");
local showLevelButton = optionsPanel.showLevelButton;
showLevelButton:SetPoint("TOPLEFT", optionsPanel.subtext, "BOTTOMLEFT", 2, -34);
showLevelButton.onValueChanged = NephilistNameplates.DriverFrame.UpdateNamePlateOptions

optionsPanel.showBuffsButton = optionsPanel:CreateCheckButton("ShowBuffs");
local showBuffsButton = optionsPanel.showBuffsButton;
showBuffsButton:SetPoint("TOPLEFT", showLevelButton, "BOTTOMLEFT", 0, -12);
-- showBuffsButton.onValueChanged = function() end

optionsPanel.onlyShowOwnBuffsButton = optionsPanel:CreateCheckButton("OnlyShowOwnBuffs");
local onlyShowOwnBuffsButton = optionsPanel.onlyShowOwnBuffsButton;
onlyShowOwnBuffsButton:SetPoint("TOPLEFT", optionsPanel.showBuffsButton, "BOTTOMLEFT", 0, -12);
-- onlyShowOwnBuffsButton.onValueChanged = function() end

optionsPanel.hideClassBarButton = optionsPanel:CreateCheckButton("HideClassBar");
local hideClassBarButton = optionsPanel.hideClassBarButton;
hideClassBarButton:SetPoint("TOPLEFT", optionsPanel.onlyShowOwnBuffsButton, "BOTTOMLEFT", 0, -12);
-- hideClassBarButton.onValueChanged = function() end

