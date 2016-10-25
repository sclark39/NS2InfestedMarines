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

local kBilebombMaterial = PrecacheAsset("cinematics/vfx_materials/bilebomb.material")
local kBilebombExoMaterial = PrecacheAsset("cinematics/vfx_materials/bilebomb_exoview.material")

local kCorrodeShaderDuration = 4

local function UpdateCorrodeMaterial(self)

    if self._renderModel then
    
        if self.isCorroded and not self.corrodeMaterial then

            local material = Client.CreateRenderMaterial()
            material:SetMaterial(kBilebombMaterial)

            local viewMaterial = Client.CreateRenderMaterial()
            if self:isa("Exo") then
                viewMaterial:SetMaterial(kBilebombExoMaterial)
            else
                viewMaterial:SetMaterial(kBilebombMaterial)
            end
            
            self.corrodeEntities = {}
            self.corrodeMaterial = material
            self.corrodeMaterialViewMaterial = viewMaterial
            AddMaterialEffect(self, material, viewMaterial, self.corrodeEntities)
        
        elseif not self.isCorroded and self.corrodeMaterial then

            RemoveMaterialEffect(self.corrodeEntities, self.corrodeMaterial, self.corrodeMaterialViewMaterial)
            Client.DestroyRenderMaterial(self.corrodeMaterial)
            Client.DestroyRenderMaterial(self.corrodeMaterialViewMaterial)
            self.corrodeMaterial = nil
            self.corrodeMaterialViewMaterial = nil
            self.corrodeEntities = nil
            
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)
    PROFILE("CorrodeMixin:OnUpdate")
    
    if Server then
    
        if self.isCorroded and self.timeCorrodeStarted + kCorrodeShaderDuration < Shared.GetTime() then
            self.isCorroded = false
            if self:isa("Extractor") then
                Log("Updating extractor because it is no longer corroding")
                GetGameMaster():UpdateExtractor(self)
            end
        end
        
    elseif Client then
        UpdateCorrodeMaterial(self)
    end
    
end

local function CorrodeOnInfestation(self)
    
    if self:GetMaxArmor() == 0 then
        return false
    end

    if self.updateInitialInfestationCorrodeState and GetIsPointOnInfestation(self:GetOrigin()) then
    
        self:SetGameEffectMask(kGameEffect.OnInfestation, true)
        self.updateInitialInfestationCorrodeState = false
        
    end

    if self:GetGameEffectMask(kGameEffect.OnInfestation) and self:GetCanTakeDamage() and (not HasMixin(self, "GhostStructure") or not self:GetIsGhostStructure()) then
        
        local updateGM = false
        
        -- notify GameMaster when a node first becomes corroded
        if not self.isCorroded then
            updateGM = true
        end
        
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
        
        if updateGM and self:isa("Extractor") then
            GetGameMaster():UpdateExtractor(self)
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

function CorrodeMixin:OnUpdate(deltaTime)   
    SharedUpdate(self, deltaTime)
end

function CorrodeMixin:OnProcessMove(input)   
    SharedUpdate(self, input.time)
end

