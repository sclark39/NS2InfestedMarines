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
IMGUIInfestedFeedTimer.kRightEdgeMargin = 64-- right edge of monster is 64 pixels from right edge of screen
IMGUIInfestedFeedTimer.kMonsterTextureEmpty = PrecacheAsset("ui/infested_marines/feed_meter_empty.dds")
IMGUIInfestedFeedTimer.kMonsterTextureFull = PrecacheAsset("ui/infested_marines/feed_meter_full.dds")
-- cannot precache gui shaders, causes compile errors :/
IMGUIInfestedFeedTimer.kMonsterShader = "shaders/infested_marines/GUIMonsterMeter.surface_shader"
IMGUIInfestedFeedTimer.kSourceSize = Vector( 1068, 964, 0)
IMGUIInfestedFeedTimer.kSourceToTargetScaleFactor = 0.367
IMGUIInfestedFeedTimer.kTargetSize = IMGUIInfestedFeedTimer.kSourceSize * IMGUIInfestedFeedTimer.kSourceToTargetScaleFactor

local kBarMoveSpeedFactor = 0.125 -- the lower this is, the faster it converges

local function SharedUpdate(self, deltaTime)
    
    deltaTime = deltaTime or 0.0
    
    local interpVal = 1.0 - math.pow(kBarMoveSpeedFactor, deltaTime)
    self.displayedFraction = self.displayedFraction * (1.0 - interpVal) + self.fraction * interpVal
    
    local displayScaleFactor = GUIScaleHeight(1)
    
    local newSize = IMGUIInfestedFeedTimer.kTargetSize
    self.monsterIcon:SetSize(newSize * displayScaleFactor)
    local xPos = -IMGUIInfestedFeedTimer.kRightEdgeMargin - IMGUIInfestedFeedTimer.kTargetSize.x
    local yPos = -IMGUIInfestedFeedTimer.kTargetSize.y
    self.monsterIcon:SetPosition(displayScaleFactor * Vector(xPos, yPos, 0))
    self.monsterIcon:SetLayer(kGUILayerDeathScreen + 1)
    
    self.monsterIcon:SetFloatParameter("fillFraction", self.displayedFraction)
    
end

function IMGUIInfestedFeedTimer:Initialize()
    
    
    self.updateInterval = 1/60 -- 60fps
    
    self.monsterIcon = GUIManager:CreateGraphicItem()
    self.monsterIcon:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.monsterIcon:SetShader(IMGUIInfestedFeedTimer.kMonsterShader)
    self.monsterIcon:SetTexture(IMGUIInfestedFeedTimer.kMonsterTextureEmpty)
    self.monsterIcon:SetAdditionalTexture("full", IMGUIInfestedFeedTimer.kMonsterTextureFull)
    self.monsterIcon:SetIsVisible(false)
    
    self.fraction = 1.0 -- actual value
    self.displayedFraction = 1.0 -- animated value
    
end

function IMGUIInfestedFeedTimer:Uninitialize()
    
    if self.monsterIcon then
        GUI.DestroyItem(self.monsterIcon)
        self.monsterIcon = nil
    end
    
    -- keybind stuff
    GetKeybindDisplayManager():DestroyBinding("SecondaryAttack")
end

function IMGUIInfestedFeedTimer:SetVisibility(state)
    
    if self.monsterIcon then
        
        self.monsterIcon:SetIsVisible(state)
    end
    
end

function IMGUIInfestedFeedTimer:OnResolutionChanged()

    SharedUpdate(self)

end

local function UpdateKeybindDisplay()
    
    local player = Client.GetLocalPlayer()
    local shouldBeDisplayed = player.secondaryKeybindShown and not player.secondaryKeybindHidden
    shouldBeDisplayed = shouldBeDisplayed and player.GetIsAlive and player:GetIsAlive()
    
    if player.secondaryKeybindShown and not player.secondaryKeybindHidden then
        if not GetKeybindDisplayManager():GetIsBindingDisplayed("SecondaryAttack") then
            GetKeybindDisplayManager():DisplayBinding("SecondaryAttack", IMStringGetRightClickTipMessage())
        end
    else
        GetKeybindDisplayManager():DestroyBinding("SecondaryAttack")
    end
end

function IMGUIInfestedFeedTimer:Update(deltaTime)
    
    SharedUpdate(self, deltaTime)
    UpdateKeybindDisplay()
    
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

