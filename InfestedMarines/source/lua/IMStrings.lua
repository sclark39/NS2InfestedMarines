-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMStrings.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Stores all the strings for the Infested Marines mod, and accessors for them.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

---------------------
-- STRING LITERALS --
---------------------
-- Here for now.  Will later be moved to enUS, and be loaded via Locale.

local kInfestedMessage = "You are infested!\nRight-click (default for alt-fire) marines when close enough (outline turns red) to infest them.  Pretend you're uninfested to avoid suspicion, but you will starve to death soon if you do not infest more humans!"

local kNotInfestedMessage = "The infested has been chosen!\nYou are not infested!  One or more of your \"friends\" however, are.  Watch each other closely.  Infestation is spreading throughout the facility and poisoning the air!  Clear the infestation and repair the Air Purifiers before the air becomes lethal!"

local kNobodyInfestedMessage = "Infestation is taking over the facility; the air is becoming toxic!  Repair the Air Purifiers before the air becomes lethal.  We cannot lose this facility!\n\n(Infested has not yet been chosen.)"

local kRightClickTipMessage = "Infest (get close)"

local kDoNotWeldPurifiersMessage = "You are helping the enemy!  Do not repair Air Purifiers except to avoid suspicion."

local kDoNotKillCystsMessage = "You are helping the enemy!  Do not kill cysts except to avoid suspicion."

local kKillCystsMessage = "Those cysts are emitting toxic gas.  Burn them!"

local kWeldPurifiersMessage = "There is a damaged air purifier nearby.  Damaged purifiers filter the toxins out of the air less effectively.  Weld them!"

local kFriendlyFireVictimMessage = "You were burned by a teammate!  They must have thought you were infested.  Keep your distance from other players, and try not to act suspicious."

local kFriendlyFireAttackerMessage = "You burned an innocent, uninfested teammate!  If they were acting crazy, then bad luck, they probably deserved it.  But if they were being reasonable, maybe give them the benefit of the doubt next time."

local kInfestedSuicideByFlamethrowerMessage = "You attempted to burn a perfectly good host!  You violated the primary directive of the infested: to spread."

local kInfestedFriendlyFireMessage = "You cannot kill other infested."

local kFeedSoonMessage = "You are close to starvation!  Infest another player soon!"

local kFeedDeathMessage = "You starved to death!  Infest marines to keep yourself from starving."

local kSuffocatedDeathMessage = "You suffocated on the toxic air!  Weld Air Purifiers and kill Cysts to keep the air clean!"

------------------------
-- ACCESSOR FUNCTIONS --
------------------------
-- These will not be replaced later, but will be modified to return the Locale string, rather
-- than the above English literals.

function IMStringGetBlankMessage()
    return ""
end

function IMStringGetInfestedMessage()
    return kInfestedMessage
end

function IMStringGetNotInfestedMessage()
    return kNotInfestedMessage
end

function IMStringGetNobodyInfestedMessage()
    return kNobodyInfestedMessage
end

function IMStringGetRightClickTipMessage()
    return kRightClickTipMessage
end

function IMStringGetDoNotWeldPurifiersMessage()
    return kDoNotWeldPurifiersMessage
end

function IMStringGetDoNotKillCystsMessage()
    return kDoNotKillCystsMessage
end

function IMStringGetKillCystsMessage()
    return kKillCystsMessage
end

function IMStringGetWeldPurifiersMessage()
    return kWeldPurifiersMessage
end

function IMStringGetFriendlyFireVictimMessage()
    return kFriendlyFireVictimMessage
end

function IMStringGetFriendlyFireAttackerMessage()
    return kFriendlyFireAttackerMessage
end

function IMStringGetInfestedSuicideByFlamethrowerMessage()
    return kInfestedSuicideByFlamethrowerMessage
end

function IMStringGetInfestedFriendlyFireMessage()
    return kInfestedFriendlyFireMessage
end

function IMStringGetFeedSoonMessage()
    return kFeedSoonMessage
end

function IMStringGetFeedDeathMessage()
    return kFeedDeathMessage
end

function IMStringGetSuffocatedMessage()
    return kSuffocatedDeathMessage
end






