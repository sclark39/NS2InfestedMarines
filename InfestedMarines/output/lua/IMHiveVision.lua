-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMHiveVision.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Overrides the enable/disable logic of HiveVision... otherwise we'd be force to override a
--    metric crap-ton of local functions.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kHiveVisionOutlineColor = enum { [0]='Yellow', 'Green', 'KharaaOrange', 'Red' }
kHiveVisionOutlineColorCount = #kHiveVisionOutlineColor+1

local old_HiveVision_SetEnabled = HiveVision_SetEnabled
function HiveVision_SetEnabled(enabled)

    local player = Client.GetLocalPlayer()
    if not player then
        -- sometimes there isn't a player for a very brief period
        return
    end
    
    -- spectators can see all
    if not Client.GetIsControllingPlayer() then
        old_HiveVision_SetEnabled(true)
        return
    end
    
    if (player.GetIsInfected and player:GetIsInfected()) or player:isa("Commander") then
        old_HiveVision_SetEnabled(true)
    else
        old_HiveVision_SetEnabled(false)
    end
   
end