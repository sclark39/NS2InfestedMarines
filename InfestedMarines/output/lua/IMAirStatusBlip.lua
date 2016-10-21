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

local kAirStatusBlipUpdateRate = 0.25

local networkVars = 
{
    fraction = "float",
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

function IMAirStatusBlip:OnInitialized()
    
    if Client then
        self:AddTimedCallback(function() self:ClientUpdate() return true end, kAirStatusBlipUpdateRate)
    end
    
end

function IMAirStatusBlip:OnDestroy()
    if Server then
        DestroyAirStatusBlip()
    end
end

function IMAirStatusBlip:ClientUpdate()
    
    local script = GetAirStatusGUI()
    if script then
        script:SetAirQuality(self.fraction)
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
    
end

Shared.LinkClassToMap("IMAirStatusBlip", IMAirStatusBlip.kMapName, networkVars)