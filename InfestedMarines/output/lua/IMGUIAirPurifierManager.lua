-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMGUIAirPurifierManager.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Manages the HUD air purifier graphics -- keeps them arranged properly, also in charge of
--    creation/destruction of icons.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/IMGUIAirPurifierStatus.lua")

function GetAirPurifierGUIManager()
    return ClientUI.GetScript("IMGUIAirPurifierManager")
end

class 'IMGUIAirPurifierManager' (GUIScript)

IMGUIAirPurifierManager.kTopMargin = 160 -- from top edge of screen to top of icon boxes

local function GetAssociatedBlip(node)
    
    local blip = Shared.GetEntity(node.entityId)
    return blip
    
end

local function FindNodeIndexWithEntityId(self, entityId)
    
    for i=1, #self.nodes do
        if self.nodes[i].entityId == entityId then
            return i
        end
    end
    
    return 0 -- not found
    
end

local function VerifyNodes(self)
    
    -- remove nodes that no longer have associated blips
    for i=#self.nodes, 1, -1 do
        local blip = GetAssociatedBlip(self.nodes[i])
        if not blip then
            -- blip has been removed, signifying the node was saved, and no longer needs to be displayed
            self.nodes[i]:Uninitialize()
            table.remove(self.nodes, i)
        else
            -- blip is still around.  Update node.
            if not blip.state then
                assert(false)
            end
            self.nodes[i]:SetIconState(blip.state)
            self.nodes[i]:SetRoomName(Shared.GetString(blip.locationId))
        end
    end
    
    local blips = EntityListToTable(Shared.GetEntitiesWithClassname("IMAirPurifierBlip"))
    local newBlips = {}
    for i=1, #blips do
        if blips[i] and (FindNodeIndexWithEntityId(self, blips[i]:GetId()) == 0) then
            table.insert(newBlips, blips[i]:GetId())
        end
    end
    
    -- add nodes for new blips
    for i=1, #newBlips do
        self:AddNode(newBlips[i])
    end
    
end

local function SharedUpdate(self, deltaTime)
    
    deltaTime = deltaTime or 0
    
    VerifyNodes(self)   -- checks node list to ensure it's up to date with the server-provided blips.
                        -- removes those that no longer exist, adds new ones, and updates the status
                        -- of existing nodes.
                        
    local x = -IMGUIAirPurifierStatus.kIconSpaceSize.x * ((#self.nodes) * 0.5)
    local offset = IMGUIAirPurifierStatus.kIconSpaceSize.x
    
    for i=1, #self.nodes do
        self.nodes[i]:SetPosition(Vector(x, IMGUIAirPurifierManager.kTopMargin, 0))
        self.nodes[i]:SetFrequency(GetAssociatedBlip(self.nodes[i]).frequency)
        x = x + offset
    end
    
end

function IMGUIAirPurifierManager:Initialize()
    
    self.updateInterval = 1/4 -- 4 fps, don't need rapid updates here.
    self.nodes = {}
    
end

function IMGUIAirPurifierManager:Uninitialize()
    
    for i=1, #self.nodes do
        if self.nodes[i] then
            self.nodes[i]:Uninitialize()
        end
    end
    
end

function IMGUIAirPurifierManager:OnResolutionChanged()
    
    SharedUpdate(self, 0)
    
end

function IMGUIAirPurifierManager:Update(deltaTime)
    
    SharedUpdate(self, deltaTime)
    
end

function IMGUIAirPurifierManager:AddNode(entityId)
    
    local index = FindNodeIndexWithEntityId(self, entityId)
    if index > 0 then
        -- already exists!
        return nil
    end
    
    local newNode = GetGUIManager():CreateGUIScript("IMGUIAirPurifierStatus")
    newNode.entityId = entityId
    newNode:SetPosition(IMGUIAirPurifierStatus.GetStartingPosition(), true)
    newNode:SetIconState(IMAirPurifierBlip.kPurifierState.Damaged)
    table.insert(self.nodes, newNode)
    
    return newNode
    
end

function IMGUIAirPurifierManager:RemoveNode(entityId)
    
    local index = FindNodeIndexWithEntityId(self, entityId)
    if index <= 0 then
        Log("Attempted to remove node that isn't in the node list!")
        return
    end
    
    table.remove(self.nodes, index)
    
end
