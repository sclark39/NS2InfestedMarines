-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMObjectiveStrings.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Stores the message strings, and accessors.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kInfestedMessage = "You are infested!\nRight-click (default for alt-fire) marines when close enough (outline turns red) to infest them.  Pretend you're uninfested to avoid suspicion, but you will starve to death soon if you do not infest more humans!"

local kNotInfestedMessage = "You are not infested!  One or more of your \"friends\" however, are.  Watch each other closely.  Infestation is spreading throughout the facility and poisoning the air!  Clear the infestation and repair the Air Purifiers before the air becomes lethal!"

local kNobodyInfestedMessage = "Infestation is taking over the facility; the air is becoming toxic!  Repair the Air Purifiers before the air becomes lethal.  We cannot lose this facility!\n\n(Infested has not yet been chosen.)"

function IMStringGetBlankMessage()
    return ""
end

-- will overwrite later with locale
function IMStringGetInfestedMessage()
    return kInfestedMessage
end

-- will overwrite later with locale
function IMStringGetNotInfestedMessage()
    return kNotInfestedMessage
end

-- will overwrite later with locale
function IMStringGetNobodyInfestedMessage()
    return kNobodyInfestedMessage
end