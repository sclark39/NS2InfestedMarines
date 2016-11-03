-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIPlayerTips.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Shows players context-sensitive tips for how to play Infested Marines.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function GetPlayerTipScript()
    return ClientUI.GetScript("IMGUIPlayerTips")
end

class 'IMGUIPlayerTips' (GUIScript)

-- text scale
IMGUIPlayerTips.kTextFont = Fonts.kAgencyFB_Medium
IMGUIPlayerTips.kTextSample = "D"
IMGUIPlayerTips.kTextHeight = 26
IMGUIPlayerTips.kTextScreenCenterOffset = 50
IMGUIPlayerTips.kTextFontScaleCompensationFactor = 26/18 -- for some reason this font doesn't scale properly

IMGUIPlayerTips.kTextBoxHalfWidth = 400
IMGUIPlayerTips.kLineOffset = 41 -- translation from line x to line x+1 (NOT space BETWEEN them)

IMGUIPlayerTips.kMarineTextColor = Color(201/255, 231/255, 1, 1)
IMGUIPlayerTips.kAlienTextColor = Color(0.901, 0.623, 0.215, 1) --kAlienFontColor

IMGUIPlayerTips.kShadowOffset = Vector(2,2,0)

IMGUIPlayerTips.kTextFadeInTime = 0.25
IMGUIPlayerTips.kTextFadeOutTime = 0.5
IMGUIPlayerTips.kTextDisplayTime = 10.0

local function EvaluateColor()
    
    local player = Client.GetLocalPlayer()
    if not player then
        return Color(1,1,1,1)
    end
    
    if player.GetIsInfected then
        if player:GetIsInfected() then
            return IMGUIPlayerTips.kAlienTextColor
        else
            return IMGUIPlayerTips.kMarineTextColor
        end
    end
    
    return Color(1,1,1,1)
    
end

local function GetStringForTipType(type)
    
    if type == kIMTipMessageType.DoNotWeldPurifiers then
        return IMStringGetDoNotWeldPurifiersMessage()
    elseif type == kIMTipMessageType.DoNotKillCysts then
        return IMStringGetDoNotKillCystsMessage()
    elseif type == kIMTipMessageType.KillCysts then
        return IMStringGetKillCystsMessage()
    elseif type == kIMTipMessageType.WeldPurifiers then
        return IMStringGetWeldPurifiersMessage()
    elseif type == kIMTipMessageType.FriendlyFireVictim then
        return IMStringGetFriendlyFireVictimMessage()
    elseif type == kIMTipMessageType.FriendlyFireAttacker then
        return IMStringGetFriendlyFireAttackerMessage()
    elseif type == kIMTipMessageType.InfestedSuicideByFlamethrower then
        return IMStringGetInfestedSuicideByFlamethrowerMessage()
    elseif type == kIMTipMessageType.InfestedFriendlyFire then
        return IMStringGetInfestedFriendlyFireMessage()
    end
    
    return nil
    
end

local function DeleteText(self, index)
    
    if self.texts and self.texts[index] then
        local text = self.texts[index]
        if text.lines then
            for i=#text.lines, 1, -1 do
                if text.lines[i] then
                    GUI.DestroyItem(text.lines[i])
                end
                text.lines[i] = nil
            end
        end
        if text.shadowLines then
            for i=#text.shadowLines, 1, -1 do
                if text.shadowLines[i] then
                    GUI.DestroyItem(text.shadowLines[i])
                end
                text.shadowLines[i] = nil
            end
        end
        table.remove(self.texts, index)
    end
    
end

local logThrottle1 = 0.0
local function SharedUpdate(self, deltaTime)
    logThrottle1 = deltaTime + logThrottle1
    if logThrottle1 > 0.5 then
        logThrottle1 = 0.0
    end
    
    local beginFadeOut = false
    
    -- Fade in text #1...
    if self.texts and self.texts[1] and not self.texts[1].empty then
        self.texts[1].opacity = self.texts[1].opacity or 0.0
        self.texts[1].timeDisplayed = self.texts[1].timeDisplayed or 0.0
        self.texts[1].opacity = math.min(self.texts[1].opacity + deltaTime / IMGUIPlayerTips.kTextFadeInTime, 1.0)
        self.texts[1].timeDisplayed = self.texts[1].timeDisplayed + deltaTime
        
        if self.texts[1].timeDisplayed >= IMGUIPlayerTips.kTextDisplayTime then
            beginFadeOut = true
        end
        
    end
    
    -- ...fade out all others, deleting those that hit 0.0 opacity.
    if self.texts and #self.texts > 1 then
        for i=#self.texts, 2, -1 do
            self.texts[i].opacity = self.texts[i].opacity or 0.0
            self.texts[i].opacity = math.max(self.texts[i].opacity - deltaTime / IMGUIPlayerTips.kTextFadeOutTime, 0.0)
            if self.texts[i].opacity <= 0.0001 then
                DeleteText(self, i)
            end
        end
    end
    
    -- update colors/opacity, and text positions
    local displayScale = GUIScaleHeight(1)
    if self.texts then
        for i=1, #self.texts do
            if not self.texts[i].empty then
                local color = self.texts[i].color or EvaluateColor()
                self.texts[i].color = self.texts[i].color or color
                color.a = self.texts[i].opacity
                local shadowColor = Color(0,0,0,self.texts[i].opacity)
                if self.texts[i].lines then
                    for j=1, #self.texts[i].lines do
                        self.texts[i].lines[j]:SetColor(color)
                        local newPos = Vector(0, IMGUIPlayerTips.kTextScreenCenterOffset + IMGUIPlayerTips.kLineOffset * (j - 0.5), 0)
                        --Log("position = %s", newPos * displayScale)
                        self.texts[i].lines[j]:SetPosition(displayScale * newPos)
                    end
                end
                if self.texts[i].shadowLines then
                    for j=1, #self.texts[i].shadowLines do
                        self.texts[i].shadowLines[j]:SetColor(shadowColor)
                        local newPos = Vector(0, IMGUIPlayerTips.kTextScreenCenterOffset + IMGUIPlayerTips.kLineOffset * (j - 0.5), 0)
                        self.texts[i].shadowLines[j]:SetPosition(displayScale * (newPos + IMGUIPlayerTips.kShadowOffset))
                    end
                end
            end
        end
    end
    
    if beginFadeOut then
        self:DoPlayerTip(kIMTipMessageType.Blank)
    end
    
    -- cleanup when all are gone.
    if #self.texts == 1 and self.texts[1].empty then
        self.texts = {}
    end
    
end

local function AddTipText(self, newString, newType)
    
    -- perform word wrapping on text.  Unfortunately, the text centering doesn't respect multi-
    -- line content, so in order to get centered multi-line text, we have to break it up into
    -- individual lines.
    local tempTextObject = GUIManager:CreateGraphicItem()
    tempTextObject:SetFontName(IMGUIPlayerTips.kTextFont)
    tempTextObject:SetOptionFlag(GUIItem.ManageRender)
    tempTextObject:SetIsVisible(false)
    local scaleFactor = (IMGUIPlayerTips.kTextHeight / tempTextObject:GetTextHeight(IMGUIPlayerTips.kTextSample)) * IMGUIPlayerTips.kTextFontScaleCompensationFactor
    local displayScaleFactor = GUIScaleHeight(1)
    tempTextObject:SetScale(Vector(scaleFactor,scaleFactor,1))
    
    local boxWidth = IMGUIPlayerTips.kTextBoxHalfWidth * 2 * displayScaleFactor
    
    local wrappedText = WordWrap( tempTextObject, newString, 0, boxWidth)
    local lines = string.Explode(wrappedText, "\n")
    
    GUI.DestroyItem(tempTextObject)
    
    -- now create a new gui item for each line, and add it to the first slot of the "texts" table.
    local newText = {}
    newText.lines = {}
    newText.shadowLines = {}
    newText.opacity = 0.0
    newText.timeDisplayed = 0.0
    newText.color = EvaluateColor()
    for i=1, #lines do
        local newLine = GUIManager:CreateGraphicItem()
        newLine:SetFontName(IMGUIPlayerTips.kTextFont)
        newLine:SetOptionFlag(GUIItem.ManageRender)
        newLine:SetIsVisible(true)
        newLine:SetScale(Vector(scaleFactor, scaleFactor, 1))
        newLine:SetLayer(kGUILayerPlayerHUDForeground2)
        newLine:SetColor(Color(1,1,1,0))
        newLine:SetTextAlignmentX(GUIItem.Align_Center)
        newLine:SetTextAlignmentY(GUIItem.Align_Center)
        newLine:SetAnchor(GUIItem.Middle, GUIItem.Center)
        newLine:SetText(lines[i])
        
        local newShadowLine = GUIManager:CreateGraphicItem()
        newShadowLine:SetFontName(IMGUIPlayerTips.kTextFont)
        newShadowLine:SetOptionFlag(GUIItem.ManageRender)
        newShadowLine:SetIsVisible(true)
        newShadowLine:SetScale(Vector(scaleFactor, scaleFactor, 1))
        newShadowLine:SetLayer(kGUILayerPlayerHUDForeground1)
        newShadowLine:SetColor(Color(0,0,0,0))
        newShadowLine:SetTextAlignmentX(GUIItem.Align_Center)
        newShadowLine:SetTextAlignmentY(GUIItem.Align_Center)
        newShadowLine:SetAnchor(GUIItem.Middle, GUIItem.Center)
        newShadowLine:SetText(lines[i])
        
        table.insert(newText.lines, newLine)
        table.insert(newText.shadowLines, newShadowLine)
    end
    
    table.insert(self.texts, 1, newText)
    
end

-- when message expires, add a blank text
local function HideTipText(self)
    
    local newTable = {}
    newTable.empty = true
    table.insert(self.texts, 1, newTable)
    
end

local function UpdateText(self)
    
    if self.currentTipType ~= self.prevTipType then
        self.prevTipType = self.currentTipType
        local newString = GetStringForTipType(self.currentTipType)
        if newString then
            AddTipText(self, newString, self.currentTipType)
        else
            HideTipText(self)
        end
        
    end
    
end

function IMGUIPlayerTips:Initialize()
    
    self.updateInterval = 1/60 -- 60fps
    
    -- texts is a collection of all the texts being displayed at once.  Normally, we'll only see
    -- one at a time, but in order to have them fade in and out nicely, we have to keep multiple
    -- messages in memory at the same time.
    self.texts =
    {
        -- empty at start, but here's a template
        --{
            --opacity = 0.0 -- will animate in and out.
            --timeDisplayed = 0.0 -- elapsed time of message being on screen
            --lines =
            --{
                -- GUI objects for each line.
            --}
            --shadowLines = 
            --{
                -- GUI objects for each line shadow.
            --}
        --},
    }
    
end

function IMGUIPlayerTips:Uninitialize()
    
    -- delete all texts
    if self.texts then
        for i=#self.texts, 1, -1 do
            DeleteText(self, i) -- deletes the GUI item associated with this text.
        end
    end
    
end

function IMGUIPlayerTips:SetVisibility(state)
    
    if self.texts then
        for i=1, #self.texts do
            if self.texts[i].lines then
                for j=1, #self.texts[i].lines do
                    self.texts[i].lines[j]:SetIsVisible(state)
                end
            end
            if self.texts[i].shadowLines then
                for j=1, #self.texts[i].shadowLines do
                    self.texts[i].shadowLines[j]:SetIsVisible(state)
                end
            end
        end
    end
    
end

function IMGUIPlayerTips:OnResolutionChanged()
    
    SharedUpdate(self, 0)
    
end

function IMGUIPlayerTips:Update(deltaTime)
    
    SharedUpdate(self, deltaTime)
    
end

function IMGUIPlayerTips:DoPlayerTip(tipType)
    
    self.currentTipType = tipType
    UpdateText(self)
    
end

