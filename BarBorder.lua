-- Utility functions for bar borders

local addonName, NephilistNameplates = ...

local BarBorder = NephilistNameplates.BarBorder


function BarBorder:SetVertexColor(r, g, b, a)
	for i, texture in ipairs(self.Textures) do
		texture:SetVertexColor(r, g, b, a)
	end
end

function BarBorder:SetBorderSizes(borderSize, borderSizeMinPixels, upwardExtendHeightPixels, upwardExtendHeightMinPixels)
	self.borderSize = borderSize
	self.borderSizeMinPixels = borderSizeMinPixels
	self.upwardExtendHeightPixels = upwardExtendHeightPixels
	self.upwardExtendHeightMinPixels = upwardExtendHeightMinPixels
end

function BarBorder:UpdateSizes()
	local borderSize = self.borderSize or 1
	local minPixels = self.borderSizeMinPixels or 2

	local upwardExtendHeightPixels = self.upwardExtendHeightPixels or borderSize
	local upwardExtendHeightMinPixels = self.upwardExtendHeightMinPixels or minPixels

	PixelUtil.SetWidth(self.Left, borderSize, minPixels)
	PixelUtil.SetPoint(self.Left, "TOPRIGHT", self, "TOPLEFT", 0, upwardExtendHeightPixels, 0, upwardExtendHeightMinPixels)
	PixelUtil.SetPoint(self.Left, "BOTTOMRIGHT", self, "BOTTOMLEFT", 0, -borderSize, 0, minPixels)

	PixelUtil.SetWidth(self.Right, borderSize, minPixels)
	PixelUtil.SetPoint(self.Right, "TOPLEFT", self, "TOPRIGHT", 0, upwardExtendHeightPixels, 0, upwardExtendHeightMinPixels)
	PixelUtil.SetPoint(self.Right, "BOTTOMLEFT", self, "BOTTOMRIGHT", 0, -borderSize, 0, minPixels)

	PixelUtil.SetHeight(self.Bottom, borderSize, minPixels)
	PixelUtil.SetPoint(self.Bottom, "TOPLEFT", self, "BOTTOMLEFT", 0, 0)
	PixelUtil.SetPoint(self.Bottom, "TOPRIGHT", self, "BOTTOMRIGHT", 0, 0)

	PixelUtil.SetHeight(self.Top, borderSize, minPixels)
	PixelUtil.SetPoint(self.Top, "BOTTOMLEFT", self, "TOPLEFT", 0, 0)
	PixelUtil.SetPoint(self.Top, "BOTTOMRIGHT", self, "TOPRIGHT", 0, 0)
end



--[[ Blizzard code for reference ]]--

--[[
local NamePlateBorderTemplateMixin = {};

-- Reuse for slightly fancier selection border? SetGradient() might not be in classic
function NamePlateBorderTemplateMixin:SetUnderlineColor(r, g, b, a)
	if self.Top == nil then
		return;
	end
	self.Top:SetVertexColor(0, 0, 0, 0);
	self.Bottom:SetVertexColor(r, g, b, a);
	self.Left:SetGradient("VERTICAL", CreateColor(r, g, b, a), CreateColor(r, g, b, 0));
	self.Right:SetGradient("VERTICAL", CreateColor(r, g, b, a), CreateColor(r, g, b, 0));
end

function NamePlateBorderTemplateMixin:SetBorderSizes(borderSize, borderSizeMinPixels, upwardExtendHeightPixels, upwardExtendHeightMinPixels)
	self.borderSize = borderSize;
	self.borderSizeMinPixels = borderSizeMinPixels;
	self.upwardExtendHeightPixels = upwardExtendHeightPixels;
	self.upwardExtendHeightMinPixels = upwardExtendHeightMinPixels;
end

function NamePlateBorderTemplateMixin:UpdateSizes()
	local borderSize = self.borderSize or 1;
	local minPixels = self.borderSizeMinPixels or 2;

	local upwardExtendHeightPixels = self.upwardExtendHeightPixels or borderSize;
	local upwardExtendHeightMinPixels = self.upwardExtendHeightMinPixels or minPixels;

	PixelUtil.SetWidth(self.Left, borderSize, minPixels);
	PixelUtil.SetPoint(self.Left, "TOPRIGHT", self, "TOPLEFT", 0, upwardExtendHeightPixels, 0, upwardExtendHeightMinPixels);
	PixelUtil.SetPoint(self.Left, "BOTTOMRIGHT", self, "BOTTOMLEFT", 0, -borderSize, 0, minPixels);

	PixelUtil.SetWidth(self.Right, borderSize, minPixels);
	PixelUtil.SetPoint(self.Right, "TOPLEFT", self, "TOPRIGHT", 0, upwardExtendHeightPixels, 0, upwardExtendHeightMinPixels);
	PixelUtil.SetPoint(self.Right, "BOTTOMLEFT", self, "BOTTOMRIGHT", 0, -borderSize, 0, minPixels);

	PixelUtil.SetHeight(self.Bottom, borderSize, minPixels);
	PixelUtil.SetPoint(self.Bottom, "TOPLEFT", self, "BOTTOMLEFT", 0, 0);
	PixelUtil.SetPoint(self.Bottom, "TOPRIGHT", self, "BOTTOMRIGHT", 0, 0);

	if self.Top then
		PixelUtil.SetHeight(self.Top, borderSize, minPixels);
		PixelUtil.SetPoint(self.Top, "BOTTOMLEFT", self, "TOPLEFT", 0, 0);
		PixelUtil.SetPoint(self.Top, "BOTTOMRIGHT", self, "TOPRIGHT", 0, 0);
	end
end
]]--