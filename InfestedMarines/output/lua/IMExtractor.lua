-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMExtractor.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Modified to update its blip when it takes damage or is repaired, so it will flash at the
--    appropriate frequency.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kUpdateRate = 0.5
local kTTKAtOne = 150 -- takes 150 seconds for corrosion to kill an extractor at mult=1

local function GetFrequencyByHealthAndArmorStatus(self)
    
    if self:GetArmorFraction()
    
end

function Extractor:ExtractorBlipUpdate(deltaTime)
    
    if self.purifierBlipId then
        local blip = Shared.GetEntity(purifierBlipId)
        if blip then
            blip:SetFrequency()
        end
    end
    
end

local old_Extractor_OnInitialized = Extractor.OnInitialized
function Extractor:OnInitialized()
    
    old_Extractor_OnInitialized(self)
    
    if Server then
        self:AddTimedCallback(Extractor.ExtractorBlipUpdate, kUpdateRate)
    end
    
end

if Server then
    function Extractor:GetCorrosionDamageFactor()
        return self.corrosionDamageFactor
    end
    
    function Extractor:SetCorrosionDamageFactorByTTK(desiredTime)
        self.corrosionDamageFactor = kTTKAtOne / desiredTime
    end
end





