-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMPlayingTeam.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Prevent team alerts from sounding.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function PlayingTeam:TriggerAlert()
    return true
end