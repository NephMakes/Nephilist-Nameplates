local addonName, NephilistNameplates = ...

NephilistNameplates.Localization = {};
local Localization = NephilistNameplates.Localization;

Localization["enUS"] = {
	HideClassBar = "Hide secondary resource bar",
	HideClassBarTooltip = "Hide secondary combat resources like combo points",
	OnlyShowOwnBuffs = "Only show your own buffs and debuffs",
	OnlyShowOwnBuffsTooltip = "Only show your own buffs and debuffs",
	ReloadAlert = "Some of your settings will not take effect until you reload the user interface",
	ShowBuffs = "Show buffs and debuffs",
	ShowBuffsTooltip = "Show important buffs and debuffs on nameplates",
	ShowClassResource = "Show class-specific combat resources",
	ShowClassResourceTooltip = "Show combo points, runes, holy power, etc.", 
	Subtext = "These options let you change the appearance of unit nameplates"
}

--[[
Localization["deDE"] = {}; 
Localization["esES"] = {}; 
Localization["esMX"] = {}; 
Localization["frFR"] = {}; 
Localization["itIT"] = {}; 
Localization["koKR"] = {}; 
Localization["ptBR"] = {}; 
Localization["ruRU"] = {}; 
Localization["zhCN"] = {}; 
Localization["zhTW"] = {}; 
--]]

function NephilistNameplates:LocalizeStrings()
	NephilistNameplates.Strings = Localization[GetLocale()] or Localization["enUS"];
	NephilistNameplates:SetAllTheText();
end

function NephilistNameplates:SetAllTheText()
	local strings = NephilistNameplates.Strings;
	local optionsPanel = _G["InterfaceOptionsNephilistNameplatesPanel"];
	optionsPanel.subtext:SetText(strings.Subtext);
	optionsPanel.showBuffsButton.Text:SetText(strings.ShowBuffs);
	optionsPanel.onlyShowOwnBuffsButton.Text:SetText(strings.OnlyShowOwnBuffs);
	optionsPanel.hideClassBarButton.Text:SetText(strings.HideClassBar);
end


