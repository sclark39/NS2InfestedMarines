-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMapBlip.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Add a field to the blip to tell if a player is infested or not.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/MapBlip.lua")

local networkVars = 
{
    isInfested = "boolean",
}

function MapBlip:UpdateRelevancy()
    
    self:SetRelevancyDistance(Math.infinity)
    
end

function MapBlip:GetIsSighted()
    
    return true
    
end

function PlayerMapBlip:GetIsInfested()
    return self.isInfested
end

function PlayerMapBlip:SetIsInfested(state)
    if Server then
        self.isInfested = state
    end
end

function PlayerMapBlip:OnCreate()
    
    MapBlip.OnCreate(self)
    self.isInfested = false
    
end

function PlayerMapBlip:Update()
    
    MapBlip.Update(self)
    
    local owner = Shared.GetEntity(self.ownerEntityId)
    if owner then
        self:SetIsInfested(owner.GetIsInfected ~= nil and owner:GetIsInfected())
    end
    
end

Class_Reload("PlayerMapBlip", networkVars)

