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

local kKeepBlipAfterRepairTime = 5

Extractor.kPurificationEffectsInterval = 2.0

local function CalculateTimeRemaining(self)
    
    local ehp = self:GetArmor() * 2 + self:GetHealth()
    local dps = kInfestationCorrodeDamagePerSecond * self:GetCorrosionDamageFactor()
    
    return ehp / dps
    
end

local function GetFrequencyByHealthAndArmorStatus(self)
    
    local timeLeft = CalculateTimeRemaining(self)
    
    if timeLeft < 5 then
        return 8.0 -- flashes/sec
    elseif timeLeft < 10 then
        return 4.0
    elseif timeLeft < 20 then
        return 2.0
    elseif timeLeft < 40 then
        return 1.0
    end
    
    return 0.25
    
end

local function GetIsDamaged(self)
    return (self:GetHealth() < self:GetMaxHealth() - 0.01) and (self:GetArmor() < self:GetMaxArmor() - 0.01)
end


function Extractor:ExtractorBlipUpdate(deltaTime)
    local damaged = GetIsDamaged(self)
    if GetIsDamaged(self) and not self.purifierBlipId then
        GetGameMaster():UpdateExtractor(self)
    end
    
    if self.purifierBlipId then
        local blip = Shared.GetEntity(self.purifierBlipId)
        if blip then
            if damaged then
                self.elapsedTimeRepaired = 0.0
                if self:GetIsAlive() then
                    blip:SetFrequency(GetFrequencyByHealthAndArmorStatus(self))
                end
            else
                self.elapsedTimeRepaired = self.elapsedTimeRepaired + deltaTime
                if blip:GetState() ~= IMAirPurifierBlip.kPurifierState.Fixed then
                    GetGameMaster():UpdateExtractor(self)
                end
                if self.elapsedTimeRepaired >= kKeepBlipAfterRepairTime then
                    GetGameMaster():UpdateExtractor(self)
                end
            end
        end
    end
    
    if not self:GetIsAlive() then
        GetGameMaster():UpdateExtractor(self)
        return false
    end
    
    return true
    
end

function Extractor:GetPurifierBlip()
    
    if self.purifierBlipId then
        local blip = Shared.GetEntity(self.purifierBlipId)
        return blip
    end
    
    return nil
    
end

function Extractor:OnKill(attacker, doer, point, direction)
    
    ScriptActor.OnKill(self, attacker, doer, point, direction)
    
    GetGameMaster():UpdateExtractor(self)
    
end

local function AirPurificationEffects(self, timePassed)
    
    if not self:GetIsAlive() then
        return false
    end
    
    local ehp = self:GetHealth() + self:GetArmor() * 2
    local maxehp = self:GetMaxHealth() + self:GetMaxArmor() * 2
    local frac = ehp / maxehp
    
    if frac <= 0 then
        return false
    end
    
    local nextInterval = Extractor.kPurificationEffectsInterval / frac
    
    self:TriggerEffects("air_purifier_working")
    
    return nextInterval
    
end

local old_Extractor_OnInitialized = Extractor.OnInitialized
function Extractor:OnInitialized()
    
    old_Extractor_OnInitialized(self)
    
    if Server then
        self:AddTimedCallback(Extractor.ExtractorBlipUpdate, kUpdateRate)
        self:AddTimedCallback(AirPurificationEffects, math.random(Extractor.kPurificationEffectsInterval))
        self.elapsedTimeRepaired = 0
    end
    
end


if Server then
    function Extractor:GetCorrosionDamageFactor()
        return self.corrosionDamageFactor or 1
    end
    
    function Extractor:SetCorrosionDamageFactorByTTK(desiredTime)
        self.corrosionDamageFactor = kTTKAtOne / desiredTime
    end
end





