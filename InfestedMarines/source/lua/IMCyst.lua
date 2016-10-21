-- ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\IMCyst.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

if Client then
    
    function Cyst:OnTimedUpdate()
    end
    
end

local old_Cyst_OnCreate = Cyst.OnCreate
function Cyst:OnCreate()
    
    old_Cyst_OnCreate(self)
    
    self.nearCysts = {}
    self.nearCysts.num = 0
    
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
        
        ScriptActor.OnUpdate(self, deltaTime)
        
    end
    
end

function Cyst:OnUpdateRender()

    PROFILE("Cyst:OnUpdateRender")
    
    local model = self:GetRenderModel()
    if model then

        model:SetMaterialParameter("connected", 1)
        
    end
    
end




