-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\GUIGameEnd.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

local kEndStates = enum({ 'AlienPlayerWin', 'MarinePlayerWin', 'AlienPlayerLose', 'MarinePlayerLose', 'AlienPlayerDraw', 'MarinePlayerDraw' })

local kEndIconTextures = { [kEndStates.AlienPlayerWin] = "ui/alien_victory.dds",
                           [kEndStates.MarinePlayerWin] = "ui/marine_victory.dds",
                           [kEndStates.AlienPlayerLose] = "ui/alien_defeat.dds",
                           [kEndStates.MarinePlayerLose] = "ui/marine_defeat.dds",
                           [kEndStates.AlienPlayerDraw] = "ui/alien_draw.dds",
                           [kEndStates.MarinePlayerDraw] = "ui/marine_draw.dds", }

local kEndIconWidth = 1024
local kEndIconHeight = 600
local kEndIconPosition = Vector(-kEndIconWidth / 2, -kEndIconHeight / 2, 0)

local kMessageFontName = { marine = Fonts.kAgencyFB_Huge, alien = Fonts.kStamp_Huge }
local kMessageText = { [kEndStates.AlienPlayerWin] = "INFESTED WIN!",
                       [kEndStates.MarinePlayerWin] = "MARINE_VICTORY",
                       [kEndStates.AlienPlayerLose] = "INFESTED LOSE",
                       [kEndStates.MarinePlayerLose] = "MARINE_DEFEAT",
                       [kEndStates.AlienPlayerDraw] = "DRAW_GAME",
                       [kEndStates.MarinePlayerDraw] = "DRAW_GAME", }   
local kMessageWinColor = { marine = kMarineFontColor, alien = kAlienFontColor }
local kMessageLoseColor = { marine = Color(0.2, 0, 0, 1), alien = Color(0.2, 0, 0, 1) }
local kMessageDrawColor = { marine = Color(0.75, 0.75, 0.75, 1), alien = Color(0.75, 0.75, 0.75, 1) }
local kMessageOffset = Vector(0, -255, 0)

function GUIGameEnd:SetGameEnded(playerWon, playerDraw, playerTeamType )

    self.endIcon:DestroyAnimations()

    self.endIcon:SetIsVisible(true)
    self.endIcon:SetColor(Color(1, 1, 1, 0))
    local invisibleFunc = function() self.endIcon:SetIsVisible(false) end
    local fadeOutFunc = function() self.endIcon:FadeOut(0.2, nil, AnimateLinear, invisibleFunc) end
    local pauseFunc = function() self.endIcon:Pause(6, nil, nil, fadeOutFunc) end
    self.endIcon:FadeIn(1.0, nil, AnimateLinear, pauseFunc)

    local player = Client.GetLocalPlayer()
    
    if player.GetIsInfected and player:GetIsInfected() then
        playerTeamType = kAlienTeamType
        playerWon = not playerWon
    end
    
    local playerIsMarine = playerTeamType == kMarineTeamType

    local endState
    if playerWon then
        endState = playerIsMarine and kEndStates.MarinePlayerWin or kEndStates.AlienPlayerWin
    elseif playerDraw then
        endState = playerIsMarine and kEndStates.MarinePlayerDraw or kEndStates.AlienPlayerDraw
    else
        endState = playerIsMarine and kEndStates.MarinePlayerLose or kEndStates.AlienPlayerLose
    end

    self.endIcon:SetTexture(kEndIconTextures[endState])
    self.endIcon:SetPosition(kEndIconPosition * GUIScale(1))
    self.endIcon:SetSize(Vector(GUIScale(kEndIconWidth), GUIScale(kEndIconHeight), 0))

    self.messageText:SetFontName(kMessageFontName[playerIsMarine and "marine" or "alien"])
    self.messageText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.messageText)
    self.messageText:SetPosition(kMessageOffset * GUIScale(1))

    if playerWon then
        self.messageText:SetColor(kMessageWinColor[playerIsMarine and "marine" or "alien"])
    elseif playerDraw then
        self.messageText:SetColor(kMessageDrawColor[playerIsMarine and "marine" or "alien"])        
    else
        self.messageText:SetColor(kMessageLoseColor[playerIsMarine and "marine" or "alien"])
    end

    local messageString = Locale.ResolveString(kMessageText[endState])
    if PlayerUI_IsASpectator() then
        local winningTeamName = nil
        if endState == kEndStates.MarinePlayerWin then
            winningTeamName = InsightUI_GetTeam1Name()
            InsightUI_AddScoreForMarineWin()
        elseif endState == kEndStates.AlienPlayerWin then
            winningTeamName = InsightUI_GetTeam2Name()
            InsightUI_AddScoreForAlienWin()            
        elseif playerDraw then
            InsightUI_AddScoreForDrawGame()
        end
        if winningTeamName then
            messageString = string.format("%s Wins!", winningTeamName)
        end
    end
    
    self.messageText:SetText(messageString)

end