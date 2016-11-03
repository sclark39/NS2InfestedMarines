-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMTipHandler.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Contains all the functionality needed to display a tip message on a client's screen.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kIMTipMessageType = enum({"Blank", "DoNotWeldPurifiers", "DoNotKillCysts"})

if Server then
    Script.Load("lua/IMTipHandlerActions.lua") -- script that looks for opportunities to present tips.
end

Shared.RegisterNetworkMessage("DoTipTypeForPlayer",
{
    tipType = "enum kIMTipMessageType",
})

if Server then
    function DisplayTipForPlayer(player, tipType)
        Server.SendNetworkMessage(player, "DoTipTypeForPlayer", {tipType = tipType}, true)
    end
end

if Client then
    local function OnClientDoTipType(msg)
        GetPlayerTipScript():DoPlayerTip(msg.tipType)
    end
    Client.HookNetworkMessage("DoTipTypeForPlayer", OnClientDoTipType)
end