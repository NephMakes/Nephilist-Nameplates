local addonName, NephilistNameplates = ...

NephilistNameplates.Localization = {}
local Localization = NephilistNameplates.Localization

Localization["enUS"] = {
	DragToMove = "Drag to move. Right click for options.", 
	HideClassBar = "Hide secondary resource bar",
	HideClassBarTooltip = "Hide secondary combat resources like combo points",
	HideClassBarTooltip = "Lock position",
	High = "High", 
	Hidden = "Hidden", 
	LockPlayerPlate = "Lock player nameplate",
	NephilistNameplates = "Nephilist Nameplates",
	OnlyShowOwnBuffs = "Only show your own buffs and debuffs",
	OnlyShowOwnBuffsTooltip = "Only show your own buffs and debuffs",
	OutOfCombatOpacity = "Visibility out of combat",
	ReloadAlert = "Some settings will not take effect until you reload the user interface",
	ShowBuffs = "Show buffs and debuffs",
	ShowBuffsTooltip = "Show important buffs and debuffs on nameplates",
	ShowClassResource = "Show class-specific combat resources",
	ShowClassResourceTooltip = "Show combo points, runes, holy power, etc.", 
	ShowLevel = "Show unit level and difficulty",
	ShowLevelTooltip = "Show unit level and difficulty",
	ShowPlayerPlate = "Show non-moving nameplate for your character",
	-- ShowPlayerPlateTooltip = "Show non-moving nameplate for your character",
	Subtext = "These options let you change the appearance of unit nameplates"
}

--[[
Localization["deDE"] = {}
Localization["esES"] = {}
Localization["esMX"] = {}
Localization["frFR"] = {}
Localization["itIT"] = {}
Localization["koKR"] = {}
Localization["ptBR"] = {}
Localization["ruRU"] = {}
Localization["zhCN"] = {}
Localization["zhTW"] = {}
--]]

function NephilistNameplates:LocalizeStrings()
	NephilistNameplates.Strings = Localization[GetLocale()] or Localization["enUS"]
	NephilistNameplates:SetAllTheText()
end

function NephilistNameplates:SetAllTheText()
	local strings = NephilistNameplates.Strings
	local optionsPanel = _G["InterfaceOptionsNephilistNameplatesPanel"]
	optionsPanel.subtext:SetText(strings.Subtext)
	optionsPanel.hideClassBarButton.Text:SetText(strings.HideClassBar)
	optionsPanel.onlyShowOwnBuffsButton.Text:SetText(strings.OnlyShowOwnBuffs)
	optionsPanel.showBuffsButton.Text:SetText(strings.ShowBuffs)
	optionsPanel.showLevelButton.Text:SetText(strings.ShowLevel)

	-- Player nameplate
	optionsPanel.showPlayerPlateButton.Text:SetText(strings.ShowPlayerPlate)
	optionsPanel.lockPlayerPlateButton.Text:SetText(strings.LockPlayerPlate)
	optionsPanel.outOfCombatAlpha.Text:SetText(strings.OutOfCombatOpacity)
	optionsPanel.outOfCombatAlpha.High:SetText(strings.High)
	optionsPanel.outOfCombatAlpha.Low:SetText(strings.Hidden)
end


