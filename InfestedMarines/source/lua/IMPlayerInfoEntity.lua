-- ======= Copyright (c) 2003-2016, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMPlayerInfoEntity.lua
--
--    Created by:   Sebastian Schuck (sebastian@naturalselection2.com)
--
--    Update the netvars with the updated status enum.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- overriding the enum declared in Globals.lua.  This is the only place it is used in netvars.
Script.Load("lua/IMUpdatedPlayerStatusEnum.lua")

local newNetworkVars = 
{
    status = "enum kPlayerStatus"
}

Class_Reload("PlayerInfoEntity", newNetworkVars)