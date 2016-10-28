-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMAirStatusBlip.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    A lightweight, always relevant entity to pass along the air quality (lives) information to
--    the client GUI.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'IMAirStatusBlip' (Entity)

IMAirStatusBlip.kMapName = "airstatusblip"

IMAirStatusBlip.kRepairRemoveDelay = 3.0

local networkVars = 
{
    fraction = "float",
    changeRate = "integer (-3 to 3)"
}

if Server then
    local airStatusBlip = nil
    function CreateAirStatusBlip()
        return CreateEntity(IMAirStatusBlip.kMapName, Vector(0,0,0), kMarineTeamType)
    end
    
    function GetAirStatusBlip()
        if not airStatusBlip then
            airStatusBlip = CreateAirStatusBlip()
        end
        return airStatusBlip
    end
    
    function DestroyAirStatusBlip()
        airStatusBlip = nil
    end
end

function IMAirStatusBlip:OnCreate()
    
    self.fraction = 1
    
    self:UpdateRelevancy()
    
end

function IMAirStatusBlip:OnDestroy()
    if Server then
        DestroyAirStatusBlip()
    end
end

function IMAirStatusBlip:GetAirQuality()
    return self.fraction
end

function IMAirStatusBlip:GetChangeRate()
    return self.changeRate
end

if Client then
    function GetAirStatusBlip()
        local blips = EntityListToTable(Shared.GetEntitiesWithClassname("IMAirStatusBlip"))
        for i=1, #blips do
            if blips[i] then
                return blips[i]
            end
        end
        
        return nil
    end
end

function IMAirStatusBlip:UpdateRelevancy()
    
    self:SetRelevancyDistance(Math.infinity)
    
end

if Server then

    function IMAirStatusBlip:SetFraction(fraction)
        
        fraction = math.min(math.max(fraction, 0), 1)
        self.fraction = fraction
        
    end
    
    function IMAirStatusBlip:SetChangeRate(rate)
        self.changeRate = rate
    end
    
end

Shared.LinkClassToMap("IMAirStatusBlip", IMAirStatusBlip.kMapName, networkVars)