-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIAirPurifierStatus.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Displays the status of non-normal air purifiers (eg destroyed, under attack, damaged).
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IMAirPurifierBlip.lua") -- ensure IMAirPurifierBlip.kPurifierState is accessible
Script.Load("lua/Hud/Marine/GUIMarineHUDStyle.lua") -- we use color constants from this.

class 'IMGUIAirPurifierStatus' (GUIScript)

-- pixels @ 1080p
IMGUIAirPurifierStatus.kIconSpaceSize = Vector(128, 108, 0)
IMGUIAirPurifierStatus.kTextHeight = 20
IMGUIAirPurifierStatus.kShadowOffset = Vector(2,2,0)

IMGUIAirPurifierStatus.kIconSize = Vector(256, 256, 0)

IMGUIAirPurifierStatus.kFont = Fonts.kAgencyFB_Medium

IMGUIAirPurifierStatus.iconNormal = PrecacheAsset("ui/infested_marines/air_purifier_icon_normal.dds")
IMGUIAirPurifierStatus.iconDestroyed = PrecacheAsset("ui/infested_marines/air_purifier_icon_destroyed.dds")
IMGUIAirPurifierStatus.iconShader = "shaders/infested_marines/GUIAirPurifierIcon.surface_shader"

IMGUIAirPurifierStatus.flashColor = Color(1,0,0,0.9)
IMGUIAirPurifierStatus.kDefaultPulseRampupTime = 20.0

IMGUIAirPurifierStatus.textColor = kBrightColor
IMGUIAirPurifierStatus.destroyedTextColor = Color(121/255, 41/255, 41/255, 1)

IMGUIAirPurifierStatus.iconScaleFactor = 0.8287
IMGUIAirPurifierStatus.textScaleFactor = 1.5

local kMoveSpeedFactor = 0.25 -- the lower this is, the faster it converges

local function SharedUpdate(self, deltaTime)
    
    deltaTime = deltaTime or 0
    local interpVal = 1.0 - math.pow( kMoveSpeedFactor , deltaTime )
    
    self.desiredPosition = self.desiredPosition or Vector(0,0,0)
    self.displayedPosition = self.displayedPosition or self.desiredPosition
    
    self.displayedPosition = self.displayedPosition * (1.0 - interpVal) + self.desiredPosition * interpVal
    local iconScaleFact = (IMGUIAirPurifierStatus.kIconSpaceSize.x / IMGUIAirPurifierStatus.kIconSize.x) * IMGUIAirPurifierStatus.iconScaleFactor
    local iconOffset = (IMGUIAirPurifierStatus.kIconSpaceSize - (IMGUIAirPurifierStatus.kIconSize * iconScaleFact)) * 0.5
    self.icon:SetPosition(GUIScaleHeight(self.displayedPosition) + iconOffset)
    self.icon:SetSize(GUIScaleHeight(IMGUIAirPurifierStatus.kIconSize * iconScaleFact))
    
    self.text:SetScale(Vector(1,1,1))
    local unscaledTextHeight = self.text:GetTextHeight("0")
    local scaleFactor = (GUIScaleHeight(IMGUIAirPurifierStatus.kTextHeight) / unscaledTextHeight) * IMGUIAirPurifierStatus.textScaleFactor
    self.text:SetScale(Vector(scaleFactor, scaleFactor, 1))
    self.textShadow:SetScale(Vector(scaleFactor, scaleFactor, 1))
    local textOffset = Vector(IMGUIAirPurifierStatus.kIconSpaceSize.x/2, IMGUIAirPurifierStatus.kIconSpaceSize.y + IMGUIAirPurifierStatus.kTextHeight/2, 0)
    self.text:SetPosition(GUIScaleHeight(textOffset + self.displayedPosition))
    self.textShadow:SetPosition(GUIScaleHeight(textOffset + self.displayedPosition + IMGUIAirPurifierStatus.kShadowOffset))
    
    self.text:SetText(self.roomName or "")
    self.textShadow:SetText(self.roomName or "")
    
end

function IMGUIAirPurifierStatus.GetStartingPosition()
    
    local screenSize = Vector(0, Client.GetScreenHeight(), 0)
    local tileSize = IMGUIAirPurifierStatus.kIconSpaceSize + Vector(0, IMGUIAirPurifierStatus.kTextHeight, 0)
    
    return (screenSize - tileSize) * 0.5
    
end

function IMGUIAirPurifierStatus:Initialize()
    
    self.updateInterval = 1/60 -- 60fps
    
    self.text = GUIManager:CreateGraphicItem()
    self.text:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.text:SetIsVisible(true)
    self.text:SetColor(IMGUIAirPurifierStatus.textColor)
    self.text:SetLayer(kGUILayerPlayerHUDForeground1)
    self.text:SetOptionFlag(GUIItem.ManageRender)
    self.text:SetFontName(IMGUIAirPurifierStatus.kFont)
    self.text:SetTextAlignmentX(GUIItem.Align_Center)
    self.text:SetTextAlignmentY(GUIItem.Align_Center)
    self.text:SetText("")
    
    self.textShadow = GUIManager:CreateGraphicItem()
    self.textShadow:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.textShadow:SetIsVisible(true)
    self.textShadow:SetColor(Color(0,0,0,1))
    self.textShadow:SetLayer(kGUILayerPlayerHUDBackground)
    self.textShadow:SetOptionFlag(GUIItem.ManageRender)
    self.textShadow:SetFontName(IMGUIAirPurifierStatus.kFont)
    self.textShadow:SetTextAlignmentX(GUIItem.Align_Center)
    self.textShadow:SetTextAlignmentY(GUIItem.Align_Center)
    self.textShadow:SetText("")
    
    self.icon = GUIManager:CreateGraphicItem()
    self.icon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.icon:SetIsVisible(true)
    self.icon:SetLayer(kGUILayerPlayerHUDForeground1)
    self.icon:SetColor(IMGUIAirPurifierStatus.flashColor)
    self.icon:SetShader(IMGUIAirPurifierStatus.iconShader)
    
    self:SetFrequency(0.25)
    
    self.roomName = self.roomName or ""
    
end

function IMGUIAirPurifierStatus:Uninitialize()
    
    GUI.DestroyItem(self.text)
    GUI.DestroyItem(self.textShadow)
    GUI.DestroyItem(self.icon)
    
    self.text = nil
    self.textShadow = nil
    self.icon = nil
    
    GetGUIManager():DestroyGUIScript(self)
    
end

function IMGUIAirPurifierStatus:OnResolutionChanged()
    
    SharedUpdate(self, 0)
    
end

function IMGUIAirPurifierStatus:SetManager(manager)
    
    self.manager = manager
    
end

function IMGUIAirPurifierStatus:SetPosition(vect, optional_immediate)
    
    if optional_immediate == true then
        self.displayedPosition = vect
    end
    self.desiredPosition = vect
    
end

function IMGUIAirPurifierStatus:GetPosition(optional_displayed)
    
    if optional_displayed then
        return self.displayedPosition
    end
    
    return self.desiredPosition
    
end

function IMGUIAirPurifierStatus:Update(deltaTime)
    
    SharedUpdate(self, deltaTime)
    
end

function IMGUIAirPurifierStatus:SetFrequency(freq)
    
    if self.freq ~= freq then
        self.freq = freq
        self.icon:SetFloatParameter("pulseFreq", freq)
    end
    
end

function IMGUIAirPurifierStatus:SetRoomName(name)
    
    self.roomName = name
    
end

function IMGUIAirPurifierStatus:SetIconState(state)
    
    if self.iconState == state then
        return
    end
    
    if not self.icon then
        return
    end
    
    local now = Shared.GetTime()
    
    self.iconState = state
    if state == IMAirPurifierBlip.kPurifierState.Damaged then
        self.icon:SetTexture(IMGUIAirPurifierStatus.iconNormal)
        self.icon:SetFloatParameter("pulseInfluence", 1)
        self.icon:SetColor(IMGUIAirPurifierStatus.flashColor)
        self.text:SetColor(IMGUIAirPurifierStatus.textColor)
    elseif state == IMAirPurifierBlip.kPurifierState.Destroyed then
        self.icon:SetTexture(IMGUIAirPurifierStatus.iconDestroyed)
        self.text:SetColor(IMGUIAirPurifierStatus.destroyedTextColor)
        self.icon:SetFloatParameter("pulseInfluence", 0)
    else --state == IMAirPurifierBlip.kPurifierState.Fixed then
        self.icon:SetTexture(IMGUIAirPurifierStatus.iconNormal)
        self.icon:SetFloatParameter("pulseInfluence", 0)
        self.text:SetColor(IMGUIAirPurifierStatus.textColor)
    end
    
end

