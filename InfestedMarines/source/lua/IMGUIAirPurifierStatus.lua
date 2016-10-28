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
IMGUIAirPurifierStatus.iconShader = "shaders/infested_marines/GUIAirPurifierIcon.surface_shader"
IMGUIAirPurifierStatus.kPurNormalTexture = PrecacheAsset("ui/infested_marines/air_purifier_icon_normal.dds")
IMGUIAirPurifierStatus.kPurDamagedTexture = PrecacheAsset("ui/infested_marines/air_purifier_icon_damaged.dds")
IMGUIAirPurifierStatus.kPurDestroyedTexture = PrecacheAsset("ui/infested_marines/air_purifier_icon_destroyed.dds")

IMGUIAirPurifierStatus.kPurNormalSourceSize = Vector(679, 704, 0)
IMGUIAirPurifierStatus.kPurDamagedSourceSize = Vector(647, 735, 0)
IMGUIAirPurifierStatus.kPurDestroyedSourceSize = Vector(834, 705, 0)

IMGUIAirPurifierStatus.kSourceToTargetScaleFactor = 0.254

IMGUIAirPurifierStatus.kPurNormalTargetSize = IMGUIAirPurifierStatus.kSourceToTargetScaleFactor * IMGUIAirPurifierStatus.kPurNormalSourceSize
IMGUIAirPurifierStatus.kPurDamagedTargetSize = IMGUIAirPurifierStatus.kSourceToTargetScaleFactor * IMGUIAirPurifierStatus.kPurDamagedSourceSize
IMGUIAirPurifierStatus.kPurDestroyedTargetSize = IMGUIAirPurifierStatus.kSourceToTargetScaleFactor * IMGUIAirPurifierStatus.kPurDestroyedSourceSize
IMGUIAirPurifierStatus.kPurDamagedToNormalOffset = Vector(-53, 105, 0) * IMGUIAirPurifierStatus.kSourceToTargetScaleFactor
IMGUIAirPurifierStatus.kPurDestroyedToNormalOffset = Vector(-110, 87, 0) * IMGUIAirPurifierStatus.kSourceToTargetScaleFactor

IMGUIAirPurifierStatus.kFont = Fonts.kAgencyFB_Medium

IMGUIAirPurifierStatus.kIconSpaceSize = Vector(150, 108, 0)
IMGUIAirPurifierStatus.kTextHeight = 20
IMGUIAirPurifierStatus.kTextBuffer = 3
IMGUIAirPurifierStatus.textColor = kBrightColor
IMGUIAirPurifierStatus.destroyedTextColor = Color(121/255, 41/255, 41/255, 1)
IMGUIAirPurifierStatus.flashColor = Color(1,0,0,0.9)
IMGUIAirPurifierStatus.kShadowOffset = Vector(2,2,0)

local kMoveSpeedFactor = 0.25 -- the lower this is, the faster it converges

local function SharedUpdate(self, deltaTime)
    
    deltaTime = deltaTime or 0
    local interpVal = 1.0 - math.pow( kMoveSpeedFactor , deltaTime )
    self.desiredPosition = self.desiredPosition or Vector(0,0,0)
    self.displayedPosition = self.displayedPosition or self.desiredPosition
    self.displayedPosition = self.displayedPosition * (1.0 - interpVal) + self.desiredPosition * interpVal
    
    local displayScaleFactor = GUIScaleHeight(1)
    
    -- icon
    do
        local newSize = self.targetSize
        local newPosition = self.displayedPosition + (IMGUIAirPurifierStatus.kIconSpaceSize / 2) - (newSize / 2)
        self.icon:SetSize(newSize * displayScaleFactor)
        self.icon:SetPosition(newPosition * displayScaleFactor)
    end
    
    -- text
    do
        self.text:SetScale(Vector(1,1,1))
        local unscaledTextHeight = self.text:GetTextHeight("0")
        local desiredHeight = (IMGUIAirPurifierStatus.kTextHeight * displayScaleFactor)
        local scaleFactor = desiredHeight / unscaledTextHeight
        
        self.text:SetScale(Vector(scaleFactor, scaleFactor, 0))
        self.textShadow:SetScale(Vector(scaleFactor, scaleFactor, 0))
        
        local newPosition = self.displayedPosition
        newPosition.x = newPosition.x  + (IMGUIAirPurifierStatus.kIconSpaceSize.x / 2)
        newPosition.y = newPosition.y + IMGUIAirPurifierStatus.kIconSpaceSize.y + IMGUIAirPurifierStatus.kTextBuffer + (IMGUIAirPurifierStatus.kTextHeight/2)
        
        self.text:SetPosition(newPosition * displayScaleFactor)
        self.textShadow:SetPosition((newPosition + IMGUIAirPurifierStatus.kShadowOffset) * displayScaleFactor)
        self.text:SetText(self.roomName or "")
        self.textShadow:SetText(self.roomName or "")
    end
    
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
    self.icon:SetTexture(IMGUIAirPurifierStatus.kPurNormalTexture)
    
    self:SetFrequency(0.25)
    self.iconOffset = Vector(0,0,0)
    self.targetSize = IMGUIAirPurifierStatus.kPurNormalTargetSize
    
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
    if state == IMAirPurifierBlip.kPurifierState.BeingDamaged then
        self.icon:SetTexture(IMGUIAirPurifierStatus.kPurDamagedTexture)
        self.icon:SetFloatParameter("pulseInfluence", 1)
        self.icon:SetColor(IMGUIAirPurifierStatus.flashColor)
        self.text:SetColor(IMGUIAirPurifierStatus.textColor)
        self.iconOffset = IMGUIAirPurifierStatus.kPurDamagedToNormalOffset
        self.targetSize = IMGUIAirPurifierStatus.kPurDamagedTargetSize
    elseif state == IMAirPurifierBlip.kPurifierState.Destroyed then
        self.icon:SetTexture(IMGUIAirPurifierStatus.kPurDestroyedTexture)
        self.text:SetColor(IMGUIAirPurifierStatus.destroyedTextColor)
        self.icon:SetFloatParameter("pulseInfluence", 0)
        self.iconOffset = IMGUIAirPurifierStatus.kPurDestroyedToNormalOffset
        self.targetSize = IMGUIAirPurifierStatus.kPurDestroyedTargetSize
    elseif state == IMAirPurifierBlip.kPurifierState.Damaged then
        self.icon:SetTexture(IMGUIAirPurifierStatus.kPurDamagedTexture)
        self.icon:SetFloatParameter("pulseInfluence", 0)
        self.text:SetColor(IMGUIAirPurifierStatus.textColor)
        self.iconOffset = IMGUIAirPurifierStatus.kPurDamagedToNormalOffset
        self.targetSize = IMGUIAirPurifierStatus.kPurDamagedTargetSize
    else --state == IMAirPurifierBlip.kPurifierState.Fixed then
        self.icon:SetTexture(IMGUIAirPurifierStatus.kPurNormalTexture)
        self.icon:SetFloatParameter("pulseInfluence", 0)
        self.text:SetColor(IMGUIAirPurifierStatus.textColor)
        self.iconOffset = Vector(0,0,0)
        self.targetSize = IMGUIAirPurifierStatus.kPurNormalTargetSize
    end
    
end

