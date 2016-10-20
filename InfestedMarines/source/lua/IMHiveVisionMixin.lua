-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMHiveVisionMixin.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Makes infected marines see other marines as green (infected) or orange (not infected) through
--    walls.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kHiveVisionUpdateRate = 0.125

function HiveVisionMixin:OnUpdate(deltaTime)
    
    if Client then
        
        PROFILE("HiveVisionMixin:OnUpdate")
        
        local now = Shared.GetTime()
        self.timeHiveVisionChanged = self.timeHiveVisionChanged or now
        
        local player = Client.GetLocalPlayer()
        local playerCanSeeHiveVision = player.GetIsInfected and player:GetIsInfected()
        
        -- debug for game molding
        playerCanSeeHiveVision = playerCanSeeHiveVision or player:isa("Commander")
        
        local visible = self:isa("Marine")
        local infected = self.GetIsInfected and self:GetIsInfected()
        
        visible = visible and (player ~= self)
        visible = visible and playerCanSeeHiveVision
        
        local needsUpdate = (visible ~= self.hiveSightVisible) or (infected ~= self.hiveSightInfected) or (self.hiveSightTargeting ~= self.targetedForInfection)
        if needsUpdate and self.timeHiveVisionChanged + kHiveVisionUpdateRate < now then
            local model = self:GetRenderModel()
            if model ~= nil then
                if visible then
                    if infected then
                        HiveVision_AddModel( model, kHiveVisionOutlineColor.Green)
                    else
                        if self.targetedForInfection then
                            HiveVision_AddModel( model, kHiveVisionOutlineColor.Red)
                        else
                            HiveVision_AddModel( model, kHiveVisionOutlineColor.KharaaOrange)
                        end
                    end
                else
                    HiveVision_RemoveModel( model )
                end
                
                self.hiveSightVisible = visible
                self.hiveSightInfected = infected
                self.hiveSightTargeting = self.targetedForInfection
                self.timeHiveVisionChanged = now
            end
        end
    end
end