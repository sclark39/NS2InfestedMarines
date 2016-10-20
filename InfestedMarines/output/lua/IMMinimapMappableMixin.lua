-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMMinimapMappableMixin.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Bit of a hack to hide icons of players you can't see.  Unfortunately, the way it's done in the
--    vanilla game is with server relevancy checks, which uses a bitfield... which can't be extended to
--    apply to >8 players.  So we'll just hide the icons here if they shouldn't be seen.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

if Client then
    
    local kHideableTypes = 
    {
        [kMinimapBlipType.Marine] = true,
        [kMinimapBlipType.JetpackMarine] = true,
    }
    
    local kInfestedPlayerColor = Color(0,1,0,1)
    
    function MinimapMappableMixin:UpdateMinimapItem(minimap, item)
        -- if a big change happen (like change of team or type), set the
        -- self.resetMinimapItem to cause a reset
        if item.resetMinimapItem then
            self:InitMinimapItem(minimap, item)
        end
        
        -- only show other players on minimap if A) they are within LOS of the viewer, B) the
        -- viewer is infected, or C) the viewer is in an overhead view (ie not participating
        -- in the game)
        local parentId = self:GetOwnerEntityId()
        local parent = Shared.GetEntity(parentId)
        local player = Client.GetLocalPlayer()
        
        local canBeObscured = kHideableTypes[self:GetType()] == true
        
        local seeAll = false
        if player and canBeObscured then
            seeAll = seeAll or HasMixin(player, "OverheadMove")
            seeAll = seeAll or (player.GetIsInfected and player:GetIsInfected())
            
            if not seeAll then
                if not parent then
                    -- out of relevancy, no chance of being shown
                    item:SetIsVisible(false)
                    return
                end
                
                if not GetCanSeeEntity(player, parent, true) then
                    item:SetIsVisible(false)
                    return
                end
            end
        end
        
        item:SetIsVisible(true)
        minimap:UpdateBlipPosition(item, self:GetMapBlipOrigin())
        
        if self.UpdateMinimapItemHook then
            self:UpdateMinimapItemHook(minimap, item)
        end
        
        local blipColor = self:GetMapBlipColor(minimap,item)
        
        if seeAll and self.GetIsInfested and self:GetIsInfested() then
            blipColor = kInfestedPlayerColor
        end
        
        if blipColor ~= item.prevBlipColor then
            item.prevBlipColor = blipColor
            item:SetColor(blipColor)
        end
        
    end
    
end
