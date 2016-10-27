-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIAirStatus.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Creates an interface for the players that 1) displays the "air quality" (read: marine win-lose bar)
--    and 2) air purifier status (eg destroyed beyond repair, being attacked, etc.)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetAirStatusGUI()
    return ClientUI.GetScript("IMGUIAirStatus")
end

class 'IMGUIAirStatus' (GUIScript)

-- the following measurements are assuming a 1080px vertical size.  They will scale to fill
-- any size screen as a final step.
IMGUIAirStatus.kTopEdgeMargin = 96 -- from top edge of screen to center of text
IMGUIAirStatus.kTextHeight = 40
IMGUIAirStatus.kTopToBarMargin = 128 -- from top edge of screen to top of bar
IMGUIAirStatus.kBarTotalWidth = 640
IMGUIAirStatus.kBarHeight = 32
IMGUIAirStatus.kShadowOffset = Vector(2, 2, 0)

IMGUIAirStatus.kBarColorGood = Color(0,1,0,1)
IMGUIAirStatus.kBarColorOkay = Color(1,1,0,1)
IMGUIAirStatus.kBarColorBad = Color(1,0,0,1)
IMGUIAirStatus.kBarColorDepleted = Color(0.1,0.1,0.1,1)

IMGUIAirStatus.kIconSize = Vector(32, 32, 0)
IMGUIAirStatus.kIconTexture = PrecacheAsset("ui/minimap_largeplayerarrow.dds")
IMGUIAirStatus.kIconGoodColor = Color(0,0.8,0,1)
IMGUIAirStatus.kIconBadColor = Color(0.8,0,0,1)

IMGUIAirStatus.kFont = Fonts.kAgencyFB_Medium

IMGUIAirStatus.kBarSegmentTexture = PrecacheAsset("ui/infested_marines/air_quality_bar_segment.dds")

IMGUIAirStatus.kDataUpdateRate = 0.25

local kBarGoodThreshold = 0.8
local kBarOkayThreshold = 0.4
local kBarMoveSpeedFactor = 0.125 -- the lower this is, the faster it converges

local function GetColorByFraction(fraction)
    
    if fraction >= 0.666667 then
        return IMGUIAirStatus.kBarColorGood
    elseif fraction >= 0.333333 then
        return IMGUIAirStatus.kBarColorOkay
    end
    
    return IMGUIAirStatus.kBarColorBad
end

local function UpdateArrowVisibilities(self)
    
    for i=1, 6 do
        self.arrowIcons[i]:SetIsVisible(false)
    end
        
    if self.changeRate > 0 then
        
        if self.changeRate >= 1 then
            self.arrowIcons[4]:SetIsVisible(true)
        end
        if self.changeRate >= 2 then
            self.arrowIcons[5]:SetIsVisible(true)
        end
        if self.changeRate >= 3 then
            self.arrowIcons[6]:SetIsVisible(true)
        end
        
    elseif self.changeRate < 0 then
        
        if self.changeRate <= -1 then
            self.arrowIcons[3]:SetIsVisible(true)
        end
        if self.changeRate <= -2 then
            self.arrowIcons[2]:SetIsVisible(true)
        end
        if self.changeRate <= -3 then
            self.arrowIcons[1]:SetIsVisible(true)
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)
    
    UpdateArrowVisibilities(self)
    
    deltaTime = deltaTime or 0
    local interpVal = 1.0 - math.pow( kBarMoveSpeedFactor , deltaTime )
    self.displayedBarFraction = self.displayedBarFraction * (1.0 - interpVal) + self.barFraction * interpVal
    
    local newWidth = IMGUIAirStatus.kBarTotalWidth * self.displayedBarFraction
    self.barLeft:SetSize(GUIScaleHeight(Vector(newWidth, IMGUIAirStatus.kBarHeight, 0)))
    self.barLeft:SetPosition(GUIScaleHeight(Vector(-IMGUIAirStatus.kBarTotalWidth/2, IMGUIAirStatus.kTopToBarMargin, 0)))
    self.barLeft:SetColor(GetColorByFraction(self.displayedBarFraction))
    if self.displayedBarFraction < 1.0 then
        self.barRight:SetIsVisible(true)
        self.barRight:SetSize(GUIScaleHeight(Vector(IMGUIAirStatus.kBarTotalWidth - newWidth, IMGUIAirStatus.kBarHeight, 0)))
        self.barRight:SetPosition(GUIScaleHeight(Vector( -IMGUIAirStatus.kBarTotalWidth/2 + newWidth, IMGUIAirStatus.kTopToBarMargin, 0)))
    else
        self.barRight:SetIsVisible(false)
    end
    self.barShadow:SetSize(GUIScaleHeight(Vector(IMGUIAirStatus.kBarTotalWidth, IMGUIAirStatus.kBarHeight, 0)))
    self.barShadow:SetPosition(GUIScaleHeight(Vector(-IMGUIAirStatus.kBarTotalWidth/2, IMGUIAirStatus.kTopToBarMargin, 0) + IMGUIAirStatus.kShadowOffset))
    
    -- text
    self.text:SetScale(Vector(1,1,1))
    local unscaledHeight = self.text:GetTextHeight("0")
    local scaleFactor = GUIScaleHeight(IMGUIAirStatus.kTextHeight) / unscaledHeight
    self.text:SetScale(Vector(scaleFactor, scaleFactor, 1))
    self.textShadow:SetScale(Vector(scaleFactor, scaleFactor, 1))
    local textPos = GUIScaleHeight(Vector(0, IMGUIAirStatus.kTopEdgeMargin, 0))
    local textShadowPos = textPos + GUIScaleHeight(IMGUIAirStatus.kShadowOffset)
    self.text:SetPosition(textPos)
    self.textShadow:SetPosition(textShadowPos)
    
    -- arrows
    local arrowLeftX = -IMGUIAirStatus.kBarTotalWidth/2 + newWidth - IMGUIAirStatus.kIconSize.x * 3
    local arrowLeftY = IMGUIAirStatus.kTopToBarMargin + ((IMGUIAirStatus.kIconSize.y - IMGUIAirStatus.kBarHeight) / 2)
    local offsetX = 0
    local scaleFact = GUIScaleHeight(1)
    for i=1, 3 do
        self.arrowIcons[i]:SetRotation(Vector(0,0,math.pi))
        local newPosition = Vector(arrowLeftX + offsetX, arrowLeftY, 0)
        self.arrowIcons[i]:SetPosition(scaleFact * newPosition)
        self.arrowIcons[i]:SetSize(scaleFact * IMGUIAirStatus.kIconSize)
        offsetX = offsetX + IMGUIAirStatus.kIconSize.x
    end
    
    for i=4, 6 do
        local newPosition = Vector(arrowLeftX + offsetX, arrowLeftY, 0)
        self.arrowIcons[i]:SetPosition(scaleFact * newPosition)
        self.arrowIcons[i]:SetSize(scaleFact * IMGUIAirStatus.kIconSize)
        offsetX = offsetX + IMGUIAirStatus.kIconSize.x
    end
    
end

function IMGUIAirStatus:Initialize()
    
    self.updateInterval = 1/60 -- 60 fps
    
    self.text = GUIManager:CreateGraphicItem()
    self.text:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.text:SetIsVisible(true)
    self.text:SetColor(kBrightColor)
    self.text:SetLayer(kGUILayerPlayerHUDForeground1)
    self.text:SetOptionFlag(GUIItem.ManageRender)
    self.text:SetFontName(IMGUIAirStatus.kFont)
    self.text:SetTextAlignmentX(GUIItem.Align_Center)
    self.text:SetTextAlignmentY(GUIItem.Align_Center)
    self.text:SetText("AIR QUALITY")
    
    self.textShadow = GUIManager:CreateGraphicItem()
    self.textShadow:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.textShadow:SetIsVisible(true)
    self.textShadow:SetColor(Color(0,0,0,1))
    self.textShadow:SetLayer(kGUILayerPlayerHUDBackground)
    self.textShadow:SetOptionFlag(GUIItem.ManageRender)
    self.textShadow:SetFontName(IMGUIAirStatus.kFont)
    self.textShadow:SetTextAlignmentX(GUIItem.Align_Center)
    self.textShadow:SetTextAlignmentY(GUIItem.Align_Center)
    self.textShadow:SetText("AIR QUALITY")
    
    self.barLeft = GUIManager:CreateGraphicItem()
    self.barLeft:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.barLeft:SetIsVisible(true)
    self.barLeft:SetColor(IMGUIAirStatus.kBarColorGood)
    self.barLeft:SetLayer(kGUILayerPlayerHUDForeground1)
    self.barLeft:SetTexture(IMGUIAirStatus.kBarSegmentTexture)
    
    -- the "empty" side of the bar, if not completely full
    self.barRight = GUIManager:CreateGraphicItem()
    self.barRight:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.barRight:SetIsVisible(false)
    self.barRight:SetColor(IMGUIAirStatus.kBarColorDepleted)
    self.barRight:SetLayer(kGUILayerPlayerHUDForeground1)
    self.barRight:SetTexture(IMGUIAirStatus.kBarSegmentTexture)
    
    self.barShadow = GUIManager:CreateGraphicItem()
    self.barShadow:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.barShadow:SetIsVisible(true)
    self.barShadow:SetColor(Color(0,0,0,1))
    self.barShadow:SetLayer(kGUILayerPlayerHUDBackground)
    self.barShadow:SetTexture(IMGUIAirStatus.kBarSegmentTexture)
    
    self.arrowIcons = {}
    for i=1, 6 do
        local newArrowIcon = GUIManager:CreateGraphicItem()
        newArrowIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
        newArrowIcon:SetIsVisible(false)
        newArrowIcon:SetColor((i >= 4) and IMGUIAirStatus.kIconGoodColor or IMGUIAirStatus.kIconBadColor)
        newArrowIcon:SetLayer(kGUILayerPlayerHUDForeground2)
        newArrowIcon:SetTexture(IMGUIAirStatus.kIconTexture)
        table.insert(self.arrowIcons, newArrowIcon)
    end
    
    self.changeRate = 0
    self.barFraction = 1.0 -- full, 0=empty, the fraction we are animating towards
    self.displayedBarFraction = 1.0 -- animated fraction value
    
end

function IMGUIAirStatus:Uninitialize()
    
    GUI.DestroyItem(self.text)
    GUI.DestroyItem(self.textShadow)
    GUI.DestroyItem(self.barLeft)
    GUI.DestroyItem(self.barRight)
    GUI.DestroyItem(self.barShadow)
    if self.arrowIcons then
        for i=1, 6 do
            if self.arrowIcons[i] then
                GUI.DestroyItem(self.arrowIcons[i])
            end
        end
    end
    
    self.text = nil
    self.textShadow = nil
    self.barLeft = nil
    self.barRight = nil
    self.barShadow = nil
    self.arrowIcons = nil
    
end

function IMGUIAirStatus:OnResolutionChanged()
    
    SharedUpdate(self)
    
end

local function UpdateData(self, deltaTime)
    
    self.dataUpdateCooldown = self.dataUpdateCooldown and self.dataUpdateCooldown - deltaTime or 0
    if self.dataUpdateCooldown <= 0 then
        self.dataUpdateCooldown = IMGUIAirStatus.kDataUpdateRate
        local blip = GetAirStatusBlip()
        if blip then
            self:SetAirQuality(blip:GetAirQuality())
            self:SetChangeRate(blip:GetChangeRate())
        end
    end
    
end

function IMGUIAirStatus:Update(deltaTime)
    
    UpdateData(self, deltaTime)
    SharedUpdate(self, deltaTime)
    
end

function IMGUIAirStatus:SetAirQuality(fraction, optional_immediate)
    
    if optional_immediate == true then
        self.displayedBarFraction = fraction
    end
    self.barFraction = fraction
    
end

function IMGUIAirStatus:SetChangeRate(rate)
    
    self.changeRate = rate
    
end


