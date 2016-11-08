-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMClient.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Handles all the client-only functionality of the infested marines mod.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IMGUIAirStatus.lua")
Script.Load("lua/IMGUIAirPurifierStatus.lua")
Script.Load("lua/IMGUIAirPurifierManager.lua")
Script.Load("lua/IMGUIObjectivesMarine.lua")
Script.Load("lua/IMGUIObjectivesAlien.lua")
Script.Load("lua/IMGUIInfestedFeedTimer.lua")
Script.Load("lua/IMGUIInfestedOverlay.lua")
Script.Load("lua/KeybindDisplayManager.lua") -- activate the built-in keybind display functionality.

--map of achievements that are available in this gamemode
local allowedAchievements =
{
    ["Season_0_1"] = true,
    ["Season_0_2"] = true,
    ["Season_0_3"] = true,
    ["Short_2_5"] = true, -- Quality Assurance
    ["Long_0_2"] = true, -- Arcade Champion
}

local oldSetAchievement = Client.SetAchievement
function Client.SetAchievement( name )
    if allowedAchievements[name] then
		local alreadyHas = Client.GetAchievement(name)
        oldSetAchievement( name )

        if not alreadyHas and name == "Season_0_1" then
            Client.GrantPromoItems()
            InventoryNewItemNotifyPush( kHalloween16ShoulderPatchItemId )
        end
    end
end

Event.Hook("LoadComplete", function()
    local deadStatus = Locale.ResolveString("STATUS_DEAD")
    local originalGUIVoiceChatUpdate
    originalGUIVoiceChatUpdate = Class_ReplaceMethod("GUIVoiceChat", "Update", function(guivoicechatself, deltaTime)
        originalGUIVoiceChatUpdate(guivoicechatself, deltaTime)
        local statuses = {}
        local allScores = ScoreboardUI_GetAllScores()
        for i = 1, #allScores do
            local s = allScores[i]
            statuses[s.Name] = s.Status
        end
        for _, bar in pairs(guivoicechatself.chatBars) do
            if bar.Background:GetIsVisible() then
                local chatBarPlayerName = bar.Name:GetText()
                local chatBarPlayerStatus = statuses[chatBarPlayerName]
                local newColor
                if chatBarPlayerStatus == deadStatus then
                    newColor = Color(1, 0, 0, 1)
                end
                if newColor ~= nil then
                    bar.Name:SetColor(newColor)
                    bar.Icon:SetColor(newColor)
                end
            end
        end
    end)
end)
