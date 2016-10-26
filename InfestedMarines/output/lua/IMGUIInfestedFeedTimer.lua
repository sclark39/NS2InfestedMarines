-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIInfestedFeedTimer.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Shows infested player how long they have to live before they starve to death.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetFeedTimerGUI()
    return ClientUI.GetScript("IMGUIInfestedFeedTimer")
end

class 'IMGUIInfestedFeedTimer' (GUIScript)

-- the following measurements are in pixels, based on a 1920x1080 display.  They will scale to fill any
-- screen size based on the vertical resolution.
IMGUIInfestedFeedTimer.kRightEdgeMargin = 24 -- right edge of monster is 128 pixels from right edge of screen
IMGUIInfestedFeedTimer.kTextureSourceSize = Vector(556, 679, 0) -- literal pixels, source image, not scaled.
IMGUIInfestedFeedTimer.kMonsterTargetSize = Vector(205, 253, 0) -- scaled monster size, on screen.

IMGUIInfestedFeedTimer.kMonsterTexture = PrecacheAsset("ui/infested_marines/infested_silhouette.dds")
-- cannot precache gui shaders, causes compile errors :/
IMGUIInfestedFeedTimer.kMonsterShader = "shaders/infested_marines/GUIMonsterMeter.surface_shader"

local kBarMoveSpeedFactor = 0.125 -- the lower this is, the faster it converges
local kMonsterColor = kAlienFontColor

local function SharedUpdate(self, deltaTime)
    
    deltaTime = deltaTime or 0.0
    
    local interpVal = 1.0 - math.pow(kBarMoveSpeedFactor, deltaTime)
    self.displayedFraction = self.displayedFraction * (1.0 - interpVal) + self.fraction * interpVal
    
    local scaleFact = GUIScaleHeight(1)
    self.monsterIcon:SetSize(scaleFact * IMGUIInfestedFeedTimer.kMonsterTargetSize)
    local xPos = -IMGUIInfestedFeedTimer.kRightEdgeMargin - IMGUIInfestedFeedTimer.kMonsterTargetSize.x
    local yPos = -IMGUIInfestedFeedTimer.kMonsterTargetSize.y * 0.5
    self.monsterIcon:SetPosition(scaleFact * Vector(xPos, yPos, 0))
    
    self.monsterIcon:SetFloatParameter("fillFraction", self.displayedFraction)
    
end

function IMGUIInfestedFeedTimer:Initialize()
    
    self.updateInterval = 1/60 -- 60fps
    
    self.monsterIcon = GUIManager:CreateGraphicItem()
    self.monsterIcon:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.monsterIcon:SetColor(kMonsterColor)
    self.monsterIcon:SetLayer(kGUILayerPlayerHUDForeground1)
    self.monsterIcon:SetShader(IMGUIInfestedFeedTimer.kMonsterShader)
    self.monsterIcon:SetTexture(IMGUIInfestedFeedTimer.kMonsterTexture)
    self.monsterIcon:SetIsVisible(false)
    
    self.fraction = 1.0 -- actual value
    self.displayedFraction = 1.0 -- animated value
    
end

function IMGUIInfestedFeedTimer:Uninitialize()
    
    if self.monsterIcon then
        GUI.DestroyItem(self.monsterIcon)
        self.monsterIcon = nil
    end
    
end

function IMGUIInfestedFeedTimer:SetVisibility(state)
    
    if self.monsterIcon then
        self.monsterIcon:SetIsVisible(state)
    end
    
end

function IMGUIInfestedFeedTimer:OnResolutionChanged()

    SharedUpdate(self)

end

function IMGUIInfestedFeedTimer:Update(deltaTime)
    
    SharedUpdate(self, deltaTime)
    
    -- convenient to do this visibility check here.
    local player = Client.GetLocalPlayer()
    local shouldBeVisible = false
    
    if player then
        if player:isa("Marine") and player.GetIsInfected and player:GetIsInfected() then
            shouldBeVisible = true
            local immediate = player:GetId() ~= self.lastSpectateId
            self:SetFeedFraction(player.infestedEnergy / Marine.kInfestedEnergyMax, immediate)
            self.lastSpectateId = player:GetId()
        else
            shouldBeVisible = false
        end
        
    end
    
    self:SetVisibility(shouldBeVisible)
    
end

function IMGUIInfestedFeedTimer:SetFeedFraction(fraction, optional_immediate)
    
    if optional_immediate == true then
        self.displayedFraction = fraction
    end
    self.fraction = fraction
    
end

