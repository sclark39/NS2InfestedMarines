
originalGUIDeathMessagesUpdate = Class_ReplaceMethod( "GUIDeathMessages", "Update", function( self, deltaTime)
    originalGUIDeathMessagesUpdate(self, deltaTime)
    self.anchor:SetPosition(Vector(0, GUIScale(400), 0))
end)