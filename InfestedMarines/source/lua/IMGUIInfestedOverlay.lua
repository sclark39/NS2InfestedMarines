-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIInfestedOverlay.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    HUD graphic for infested marines.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

function GetInfestedHUDScript()
    return ClientUI.GetScript("IMGUIInfestedOverlay")
end

class 'IMGUIInfestedOverlay' (GUIAnimatedScript)

IMGUIInfestedOverlay.kTexture = PrecacheAsset("ui/infested_marines/infested_border.dds")

function IMGUIInfestedOverlay:Initialize()
    
    GUIAnimatedScript.Initialize(self)
    
    self.updateInterval = 1/10 -- 10fps
    
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetTexture(IMGUIInfestedOverlay.kTexture)
    self.background:SetIsScaling(false)
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(),0))
    self.background:SetLayer(kGUILayerDeathScreen)
    
    local player = Client.GetLocalPlayer()
    local shouldBeVisible = player and player:isa("Marine") and player.GetIsInfected and player:GetIsInfected() 
    if shouldBeVisible then
        self.background:SetColor(Color(1,1,1,1))
    else
        self.background:SetColor(Color(1,1,1,0))
    end
    self.lastState = shouldBeVisible
    
end

function IMGUIInfestedOverlay:Reset()

    GUIAnimatedScript.Reset(self)
    
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(),0))
    
end

function IMGUIInfestedOverlay:SetVisibility(state)
    
    if self.background then
        if self.lastState ~= state then
            self.lastState = state
            if state then
                self.background:FadeIn(1.5, "INFEST_OVERLAY")
            else
                self.background:FadeOut(0, "INFEST_OVERLAY")
                
            end
        end
        --self.border:SetIsVisible(state)
    end
    
end

function IMGUIInfestedOverlay:OnResolutionChanged()
    self:Uninitialize()
    self:Initialize()
end

function IMGUIInfestedOverlay:Update(deltaTime)
    
    GUIAnimatedScript.Update(self, deltaTime)
    
    -- convenient to do this visibility check here.
    local player = Client.GetLocalPlayer()
    local shouldBeVisible = player and player:isa("Marine") and player.GetIsInfected and player:GetIsInfected()     
    self:SetVisibility(shouldBeVisible)
    
end

