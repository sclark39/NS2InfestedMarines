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
    maxLives = "integer",
    currLives = "integer",
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
    
    self.maxLives = 5
    self.currLives = self.maxLives
    
    self:UpdateRelevancy()
    
end

function IMAirStatusBlip:OnInitialized()
    
    if Client then
        self.lastLives = self.currLives
        self.lastMaxLives = self.maxLives
        self:AddTimedCallback(function() self:ClientUpdate() return true end, kAirStatusBlipUpdateRate)
    end
    
end

function IMAirStatusBlip:OnDestroy()
    if Server then
        DestroyAirStatusBlip()
    end
end

function IMAirStatusBlip:ClientUpdate()
    
    local foundChange = false
    if self.lastLives ~= self.currLives then
        self.lastLives = self.currLives
        foundChange = true
    end
    
    if self.lastMaxLives ~= self.maxLives then
        self.lastMaxLives = self.maxLives
        foundChange = true
    end
    
    if foundChange then
        local script = GetAirStatusGUI()
        if script then
            script:SetAirQuality(self.currLives / self.maxLives)
        end
    end
    
end

function IMAirStatusBlip:UpdateRelevancy()
    
    self:SetRelevancyDistance(Math.infinity)
    
end

if Server then

    function IMAirStatusBlip:SetMaxLives(maxLives)
        
        self.maxLives = maxLives
        
    end
    
    function IMAirStatusBlip:SetCurrentLives(currLives)
        
        self.currLives = currLives
        
    end

end

Shared.LinkClassToMap("IMAirStatusBlip", IMAirStatusBlip.kMapName, networkVars)