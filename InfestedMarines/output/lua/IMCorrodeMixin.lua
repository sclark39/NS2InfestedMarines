-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMCorrodeMixin.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Modified to make it damage health as well as armor.  Also added a thing to make the damage
--    scale, as a way of setting the amount of "time" players had to get to a location.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local function CorrodeOnInfestation(self)

    if self:GetMaxArmor() == 0 then
        return false
    end

    if self.updateInitialInfestationCorrodeState and GetIsPointOnInfestation(self:GetOrigin()) then
    
        self:SetGameEffectMask(kGameEffect.OnInfestation, true)
        self.updateInitialInfestationCorrodeState = false
        
    end

    if self:GetGameEffectMask(kGameEffect.OnInfestation) and self:GetCanTakeDamage() and (not HasMixin(self, "GhostStructure") or not self:GetIsGhostStructure()) then
        
        self:SetCorroded()
        
        if self:isa("PowerPoint") and self:GetArmor() == 0 then
            self:DoDamageLighting()
        end
        
        if not self:isa("PowerPoint") or self:GetArmor() > 0 then
            -- stop damaging power nodes when armor reaches 0... gets annoying otherwise.
            local corrosionDamageFact = 1
            if self.GetCorrosionDamageFactor then
                corrosionDamageFact = self:GetCorrosionDamageFactor()
            end
            self:DeductHealth(kInfestationCorrodeDamagePerSecond * corrosionDamageFact, nil, nil, false, false, true)
        end
        
    end

    return true

end

function CorrodeMixin:__initmixin()

    if Server then
        
        self.isCorroded = false
        self.timeCorrodeStarted = 0
        
        if not self:isa("Player") and not self:isa("MAC") and not self:isa("Exosuit") and kCorrodeMarineStructureArmorOnInfestation then
        
            self:AddTimedCallback(CorrodeOnInfestation, 1)
            self.updateInitialInfestationCorrodeState = true
            
        end
        
    end
    
end