-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMCyst.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Cyst.kBoxTraceExtents = Cyst.kExtents
Cyst.kBoxTraceExtents.y = 0.01

Cyst.kToxinEffectInterval = 5.0

local function CystToxins(self, timePassed)
    
    if not self:GetIsAlive() then
        return false
    end
    
    self:TriggerEffects("cyst_toxins")
    
    return Cyst.kToxinEffectInterval
    
end

local old_Cyst_OnCreate = Cyst.OnCreate
function Cyst:OnCreate()
    
    old_Cyst_OnCreate(self)
    
    -- emit cyst toxins every Cyst.kToxinEffectInterval seconds.  (first call is random so cysts created at the same time
    -- aren't synchronized).
    if Server then
        self:AddTimedCallback(CystToxins, math.random(Cyst.kToxinEffectInterval))
    end
    
end

function Cyst:GetCanAutoBuild()
    return true
end

function Cyst:OnInitialized()
    
    InitMixin(self, InfestationMixin)
    
    ScriptActor.OnInitialized(self)

    if Server then
    
        -- start out as disconnected; wait for impulse to arrive
        self.connected = false
        
        self.nextUpdate = Shared.GetTime()
        self.impulseActive = false
        self.bursted = false
        self.timeBursted = 0
        self.children = { }
        
        InitMixin(self, SleeperMixin)
        InitMixin(self, StaticTargetMixin)
        
        self:SetModel(Cyst.kModelName, Cyst.kAnimationGraph)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then    
    
        InitMixin(self, UnitStatusMixin)
        
    end
    
    InitMixin(self, IdleMixin)
    
end

if Server then
  
    function Cyst:OnUpdate(deltaTime)

        PROFILE("Cyst:OnUpdate")
        
        ScriptActor.OnUpdate(self, deltaTime)
        
        if not self:GetIsAlive() then
            local destructionAllowedTable = { allowed = true }
            if self.GetDestructionAllowed then
                self:GetDestructionAllowed(destructionAllowedTable)
            end
            
            if destructionAllowedTable.allowed then
                DestroyEntity(self)
            end
        end
        
    end
end

function Cyst:OnUpdateRender()

    PROFILE("Cyst:OnUpdateRender")
    
    local model = self:GetRenderModel()
    if model then

        model:SetMaterialParameter("connected", 1)
        
    end
    
end




