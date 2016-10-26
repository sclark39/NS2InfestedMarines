-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIInfestedOverlay.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    HUD graphic for infested marines.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetInfestedHUDScript()
    return ClientUI.GetScript("IMGUIInfestedOverlay")
end

class 'IMGUIInfestedOverlay' (GUIScript)

IMGUIInfestedOverlay.kTexture = PrecacheAsset("ui/infested_marines/infested_border.dds")

local function SharedUpdate(self, deltaTime)
    
    self.border:SetPosition(Vector(0,0,0))
    local w = Client.GetScreenWidth()
    local h = Client.GetScreenHeight()
    self.border:SetSize(Vector(w, h, 0))
    
end

function IMGUIInfestedOverlay:Initialize()
    
    self.updateInterval = 1/10 -- 10fps
    
    self.border = GUIManager:CreateGraphicItem()
    self.border:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.border:SetLayer(kGUILayerDeathScreen)
    self.border:SetTexture(IMGUIInfestedOverlay.kTexture)
    self.border:SetIsVisible(false)
    
end

function IMGUIInfestedOverlay:Uninitialize()
    
    if self.border then
        GUI.DestroyItem(self.border)
        self.border = nil
    end
    
end

function IMGUIInfestedOverlay:SetVisibility(state)
    
    if self.border then
        self.border:SetIsVisible(state)
    end
    
end

function IMGUIInfestedOverlay:OnResolutionChanged()

    SharedUpdate(self)

end

function IMGUIInfestedOverlay:Update(deltaTime)
    
    SharedUpdate(self, deltaTime)
    
    -- convenient to do this visibility check here.
    local player = Client.GetLocalPlayer()
    local shouldBeVisible = false
    
    if player and player:isa("Marine") and player.GetIsInfected and player:GetIsInfected() then
        shouldBeVisible = true
    else
        shouldBeVisible = false
    end
    
    self:SetVisibility(shouldBeVisible)
    
end

