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
IMGUIAirStatus.kBarBlueTexture = PrecacheAsset("ui/infested_marines/air_quality_bar_blue.dds")
IMGUIAirStatus.kBarBackTexture = PrecacheAsset("ui/infested_marines/air_quality_bar_background.dds")
IMGUIAirStatus.kBarInfestedTexture = PrecacheAsset("ui/infested_marines/air_quality_bar_infestation.dds")
IMGUIAirStatus.kRedArrowTexture = PrecacheAsset("ui/infested_marines/air_quality_red_arrow.dds")
IMGUIAirStatus.kGreenArrowTexture = PrecacheAsset("ui/infested_marines/air_quality_green_arrow.dds")

IMGUIAirStatus.kTopEdgeMargin = 96 -- from top edge of screen to center of text
IMGUIAirStatus.kTextHeight = 40
IMGUIAirStatus.kShadowOffset = Vector(2, 2, 0)

IMGUIAirStatus.kBarScale = 0.6

IMGUIAirStatus.kBarBlueSourceSize = Vector( 1081, 61, 0 )
IMGUIAirStatus.kBarBackSourceSize = Vector( 1136, 120, 0)
IMGUIAirStatus.kBarInfestedSourceSize = Vector( 1136, 120, 0)
IMGUIAirStatus.kBarArrowRedSourceSize = Vector( 45, 59, 0 )
IMGUIAirStatus.kBarArrowGreenSourceSize = Vector( 44, 59, 0 )
IMGUIAirStatus.kBarBackToBlueOffset = Vector(-21, -32, 0)  * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kBarInfestedToBackOffset = Vector(0, 0, 0) * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kGreenArrowInitialOffset = Vector(-9, 2, 0) * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kRedArrowInitialOffset = Vector(3, 2, 0) * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kArrowSpacing = 40 * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kTopBlueOpacity = 0.9

IMGUIAirStatus.kBarBlueTargetSize = IMGUIAirStatus.kBarBlueSourceSize * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kBarBackTargetSize = IMGUIAirStatus.kBarBackSourceSize * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kBarInfestedTargetSize = IMGUIAirStatus.kBarInfestedSourceSize * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kBarArrowRedTargetSize = IMGUIAirStatus.kBarArrowRedSourceSize * IMGUIAirStatus.kBarScale
IMGUIAirStatus.kBarArrowGreenTargetSize = IMGUIAirStatus.kBarArrowGreenSourceSize * IMGUIAirStatus.kBarScale


IMGUIAirStatus.kGlobalOffset = Vector(0,0,0) -- I'm anticipating having to move this.
IMGUIAirStatus.kTopToBarMargin = 144 -- from top edge of screen to top of bar, not bar back

IMGUIAirStatus.kDataUpdateRate = 0.25

IMGUIAirStatus.kFont = Fonts.kAgencyFB_Medium

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
    
    for i=1, 3 do
        self.greenArrows[i]:SetIsVisible(false)
        self.redArrows[i]:SetIsVisible(false)
    end
        
    if self.changeRate > 0 then
        
        if self.changeRate >= 1 then
            self.greenArrows[1]:SetIsVisible(true)
        end
        if self.changeRate >= 2 then
            self.greenArrows[2]:SetIsVisible(true)
        end
        if self.changeRate >= 3 then
            self.greenArrows[3]:SetIsVisible(true)
        end
        
    elseif self.changeRate < 0 then
        
        if self.changeRate <= -1 then
            self.redArrows[1]:SetIsVisible(true)
        end
        if self.changeRate <= -2 then
            self.redArrows[2]:SetIsVisible(true)
        end
        if self.changeRate <= -3 then
            self.redArrows[3]:SetIsVisible(true)
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)
    
    UpdateArrowVisibilities(self)
    
    deltaTime = deltaTime or 0
    local interpVal = 1.0 - math.pow( kBarMoveSpeedFactor , deltaTime )
    self.displayedBarFraction = self.displayedBarFraction * (1.0 - interpVal) + self.barFraction * interpVal
    
    local displayScaleFactor = GUIScaleHeight(1)
   -- local toxicFrac = 1.0 - self.displayedBarFraction -- used to be the opposite -- "air quality"
    local toxicFrac = self.displayedBarFraction 
    
    -- bar blue
    local newBlueWidth = math.floor( toxicFrac * IMGUIAirStatus.kBarBlueTargetSize.x )
    local blueSize = Vector(newBlueWidth, IMGUIAirStatus.kBarBlueTargetSize.y, 0)
    local bluePosition = Vector(-IMGUIAirStatus.kBarBlueTargetSize.x/2, IMGUIAirStatus.kTopToBarMargin, 0) + IMGUIAirStatus.kGlobalOffset
    self.barBlue:SetTextureCoordinates(0,0,toxicFrac,1)
    self.barBlue2:SetTextureCoordinates(0,0,toxicFrac,1)
    self.barBlue:SetSize(blueSize * displayScaleFactor)
    self.barBlue2:SetSize(blueSize * displayScaleFactor)
    self.barBlue:SetPosition(bluePosition * displayScaleFactor)
    self.barBlue2:SetPosition(bluePosition * displayScaleFactor)
	
	local toxicColor = Clamp( ( toxicFrac - 0.2 ) / 0.8, 0, 1 ) -- make it yellow at 20%, starting the transition at 80%
    local toxicOpacity = 0.3 + 0.5 * Clamp( ( toxicFrac - 0.1 ) / 0.5, 0, 1 )
	self.barBlue:SetColor( Color( 1, 1, toxicColor, 1 ) )
	self.barBlue2:SetColor( Color( 1, 1, toxicColor, toxicOpacity ) )
	
    -- bar back
    local backSize = IMGUIAirStatus.kBarBackTargetSize
    local backPosition = bluePosition + IMGUIAirStatus.kBarBackToBlueOffset
    self.barBack:SetSize(backSize * displayScaleFactor)
    self.barBack:SetPosition(backPosition * displayScaleFactor)
	
    -- infested bar
    local barInfestedSize = IMGUIAirStatus.kBarInfestedTargetSize
    local barInfestedPosition = backPosition + IMGUIAirStatus.kBarInfestedToBackOffset
    self.barInfested:SetSize(barInfestedSize * displayScaleFactor)
    self.barInfested:SetPosition(barInfestedPosition * displayScaleFactor)
    
    -- text
    self.text:SetScale(Vector(1,1,1))
    local unscaledHeight = self.text:GetTextHeight("0")
    local scaleFactor = GUIScaleHeight(IMGUIAirStatus.kTextHeight) / unscaledHeight
    self.text:SetScale(Vector(scaleFactor, scaleFactor, 1))
    self.textShadow:SetScale(Vector(scaleFactor, scaleFactor, 1))
    local textPos = GUIScaleHeight(Vector(0, IMGUIAirStatus.kTopEdgeMargin, 0) + IMGUIAirStatus.kGlobalOffset)
    local textShadowPos = textPos + GUIScaleHeight(IMGUIAirStatus.kShadowOffset)
    self.text:SetPosition(textPos)
    self.textShadow:SetPosition(textShadowPos)
    
    -- green arrows
    do
        local startX = bluePosition.x + newBlueWidth -- right edge of the bar
        startX = startX + IMGUIAirStatus.kGreenArrowInitialOffset.x
        local startY = bluePosition.y + IMGUIAirStatus.kGreenArrowInitialOffset.y
        local offsetX = -IMGUIAirStatus.kArrowSpacing
        for i=1, 3 do
            self.redArrows[i]:SetSize(IMGUIAirStatus.kBarArrowGreenTargetSize * displayScaleFactor)
            self.redArrows[i]:SetPosition(Vector(startX + (offsetX * i), startY, 0) * displayScaleFactor)
        end
    end
    
    -- red arrows
    do
        local startX = bluePosition.x + newBlueWidth -- right edge of the bar
        startX = startX + IMGUIAirStatus.kRedArrowInitialOffset.x
        local startY = bluePosition.y + IMGUIAirStatus.kRedArrowInitialOffset.y
        local offsetX = IMGUIAirStatus.kArrowSpacing
        for i=1, 3 do
            self.greenArrows[i]:SetSize(IMGUIAirStatus.kBarArrowRedTargetSize * displayScaleFactor)
            self.greenArrows[i]:SetPosition(Vector(startX + (offsetX * (i-1)), startY, 0) * displayScaleFactor)
        end
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
    self.textShadow:SetText(self.text:GetText())
    
    self.barBack = GUIManager:CreateGraphicItem()
    self.barBack:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.barBack:SetIsVisible(true)
    self.barBack:SetLayer(kGUILayerPlayerHUDBackground)
    self.barBack:SetTexture(IMGUIAirStatus.kBarBackTexture)
    
    self.barBlue = GUIManager:CreateGraphicItem()
    self.barBlue:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.barBlue:SetIsVisible(true)
    self.barBlue:SetLayer(kGUILayerPlayerHUDForeground1)
    self.barBlue:SetTexture(IMGUIAirStatus.kBarBlueTexture)
    
    self.barInfested = GUIManager:CreateGraphicItem()
    self.barInfested:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.barInfested:SetIsVisible(true)
    self.barInfested:SetLayer(kGUILayerPlayerHUDForeground2)
    self.barInfested:SetTexture(IMGUIAirStatus.kBarInfestedTexture)
    
    self.barBlue2 = GUIManager:CreateGraphicItem()
    self.barBlue2:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.barBlue2:SetIsVisible(true)
    self.barBlue2:SetLayer(kGUILayerPlayerHUDForeground3)
    self.barBlue2:SetColor(Color(1,1,1,IMGUIAirStatus.kTopBlueOpacity))
    self.barBlue2:SetTexture(IMGUIAirStatus.kBarBlueTexture)
    
    self.greenArrows = {}
    for i=1, 3 do
        local newArrowIcon = GUIManager:CreateGraphicItem()
        newArrowIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
        newArrowIcon:SetIsVisible(false)
        newArrowIcon:SetLayer(kGUILayerPlayerHUDForeground4)
        newArrowIcon:SetTexture(IMGUIAirStatus.kGreenArrowTexture)
        table.insert(self.greenArrows, newArrowIcon)
    end
    
    self.redArrows = {}
    for i=1, 3 do
        local newArrowIcon = GUIManager:CreateGraphicItem()
        newArrowIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
        newArrowIcon:SetIsVisible(false)
        newArrowIcon:SetLayer(kGUILayerPlayerHUDForeground4)
        newArrowIcon:SetTexture(IMGUIAirStatus.kRedArrowTexture)
        table.insert(self.redArrows, newArrowIcon)
    end
    
    self.changeRate = 0
    self.barFraction = 1.0 -- full, 0=empty, the fraction we are animating towards
    self.displayedBarFraction = 1.0 -- animated fraction value
    
end

function IMGUIAirStatus:Uninitialize()
    
    GUI.DestroyItem(self.text)
    GUI.DestroyItem(self.textShadow)
    GUI.DestroyItem(self.barBack)
    GUI.DestroyItem(self.barBlue)
    GUI.DestroyItem(self.barInfested)
    GUI.DestroyItem(self.barBlue2)
    if self.greenArrows then
        for i=1, 3 do
            if self.greenArrows[i] then
                GUI.DestroyItem(self.greenArrows[i])
            end
        end
    end
    if self.redArrows then
        for i=1, 3 do
            if self.redArrows[i] then
                GUI.DestroyItem(self.redArrows[i])
            end
        end
    end
    
    self.text = nil
    self.textShadow = nil
    self.barBack = nil
    self.barBlue = nil
    self.barInfested = nil
    self.barBlue2 = nil
    self.greenArrows = nil
    self.redArrows = nil
    
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


