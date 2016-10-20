-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMAirPurifierBlip.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    An always-relevant "tag" for extractors, so the GUI can update properly.  Keeps track of what
--    "state" the air purifier is in.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'IMAirPurifierBlip' (Entity)

IMAirPurifierBlip.kMapName = "airpurifierblip"

IMAirPurifierBlip.kPurifierState = enum({"Normal", "Destroyed", "Damaged", "Fixed"})

local networkVars = 
{
    entId = "entityid",
    state = "enum IMAirPurifierBlip.kPurifierState",
    rampTime = "float",
    locationId = "integer",
}

function IMAirPurifierBlip:OnCreate()
    
    self.entId = Entity.invalidId
    self.state = IMAirPurifierBlip.kPurifierState.Normal
    self.rampTime = 20.0
    self:UpdateRelevancy()
    
end

function IMAirPurifierBlip:UpdateRelevancy()
    
    self:SetRelevancyDistance(Math.infinity)
    
end

if Server then

    function IMAirPurifierBlip:SetEntityId(entityId)
        
        self.entId = entityId
        local entity = Shared.GetEntity(entityId)
        assert(entity)
        self.locationId = entity:GetLocationId()
        entity.purifierBlipId = self:GetId()
        
    end
    
    function IMAirPurifierBlip:SetState(state)
        Log("IMAirPurifierBlip:SetState(%s)", EnumToString( IMAirPurifierBlip.kPurifierState, state ))
        self.state = state
        
    end
    
    function IMAirPurifierBlip:SetRampTime(rampTime)
        
        self.rampTime = rampTime
        
    end

end

Shared.LinkClassToMap("IMAirPurifierBlip", IMAirPurifierBlip.kMapName, networkVars)