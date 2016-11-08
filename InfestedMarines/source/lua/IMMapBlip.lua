-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMapBlip.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Add a field to the blip to tell if a player is infested or not.
--    Make cysts change color depending on if the player is infested or not.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/MapBlip.lua")

local networkVars = 
{
    isInfested = "boolean",
}

if Client then
    local blipRotation = Vector(0,0,0)
    function MapBlip:UpdateMinimapItemHook(minimap, item)

        PROFILE("MapBlip:UpdateMinimapItemHook")

        local rotation = self:GetRotation()
        if rotation ~= item.prevRotation then
            item.prevRotation = rotation
            blipRotation.z = rotation
            item:SetRotation(blipRotation)
        end
        local blipTeam = self:GetMapBlipTeam(minimap)
        local blipColor = item.blipColor
        
        if self.OnSameMinimapBlipTeam(minimap.playerTeam, blipTeam) or minimap.spectating then
            
            if self.isInCombat and self:GetMapBlipType() ~= kMinimapBlipType.Marine then
                blipColor = self.PulseRed(1.0)
            end
            self:UpdateHook(minimap, item)
            
        end
        self.currentMapBlipColor = blipColor

    end
    
    function MapBlip:GetMapBlipColor(minimap, item)
        
        if self.mapBlipType == kMinimapBlipType.InfestationDying or self.mapBlipType == kMinimapBlipType.Infestation then
            local player = Client.GetLocalPlayer()
            if player and player.GetIsInfected then
                if player:GetIsInfected() then
                    return Color(0.2, 0.7, 0.2, .25) -- from GUIMinimap.lua, kInfestationColor
                else
                    return Color(1, 0.2, 0, .25) -- also from GUIMinimap.lua, kInfestationDyingColor
                end
            end
        end
        
        return self.currentMapBlipColor or Color()
        
    end
    
end

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

