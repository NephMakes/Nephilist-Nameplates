local addonName, NephilistNameplates = ...

-- local Strings = NephilistNameplates.Strings;

--[[ Defaults ]]-- 

NephilistNameplates.Defaults = {
	HideClassBar = false,
	OnlyShowOwnBuffs = true,
	ShowBuffs = true,
	ShowEliteIcon = true, 
	ColorRareNames = true, 
	Version = GetAddOnMetadata(addonName, "Version")
}


--[[ Interface options panel ]]-- 

NephilistNameplates.OptionsPanel = NephilistNameplates:CreateOptionsPanel();
local optionsPanel = NephilistNameplates.OptionsPanel;
optionsPanel.savedVariablesName = "NephilistNameplatesOptions";
optionsPanel.defaults = NephilistNameplates.Defaults;
optionsPanel.defaultsFunc = NephilistNameplates.DriverFrame.UpdateNamePlateOptions;
optionsPanel.okayFunc = NephilistNameplates.DriverFrame.UpdateNamePlateOptions;

optionsPanel.showBuffsButton = optionsPanel:CreateCheckButton("ShowBuffs");
local showBuffsButton = optionsPanel.showBuffsButton;
showBuffsButton:SetPoint("TOPLEFT", optionsPanel.subtext, "BOTTOMLEFT", 2, -34);
-- showBuffsButton.onValueChanged = function() end

optionsPanel.onlyShowOwnBuffsButton = optionsPanel:CreateCheckButton("OnlyShowOwnBuffs");
local onlyShowOwnBuffsButton = optionsPanel.onlyShowOwnBuffsButton;
onlyShowOwnBuffsButton:SetPoint("TOPLEFT", optionsPanel.showBuffsButton, "BOTTOMLEFT", 0, -12);
-- onlyShowOwnBuffsButton.onValueChanged = function() end

optionsPanel.hideClassBarButton = optionsPanel:CreateCheckButton("HideClassBar");
local hideClassBarButton = optionsPanel.hideClassBarButton;
hideClassBarButton:SetPoint("TOPLEFT", optionsPanel.onlyShowOwnBuffsButton, "BOTTOMLEFT", 0, -12);
-- hideClassBarButton.onValueChanged = function() end



