do -- Fake infest_* and infect_* maps to ns2_*
    function string.starts(String,Start)
       return string.sub(String,1,string.len(Start))==Start
    end

    oldServerStartWorld = Server.StartWorld
    Server.StartWorld = function( mods, mapName )    
        if string.starts( mapName, "infest_" ) then
            mapName = "ns2_" .. string.sub( mapName, string.len( "infest_") + 1 )
            mods[#mods + 1] = "2e813610" -- infested
        elseif string.starts( mapName, "infect_" ) then
            mapName = "ns2_" .. string.sub( mapName, string.len( "infect_") + 1 )
            mods[#mods + 1] = "2e813610" -- infested
        end
        oldServerStartWorld(mods, mapName)
    end
end

do
    Event.Hook( "ClientConnect", function(client)
            
        local infIndex = Server.GetNumMaps() + 1
        for i = 1, Server.GetNumMaps() do
        
            local mapName = "infest_" .. string.sub( Server.GetMapName(i), string.len( "ns2_" ) + 1 )
            if MapCycle_GetMapIsInCycle(mapName) then
                Server.SendNetworkMessage( client, "AddVoteMap", { name = mapName, index = infIndex }, true )
                infIndex = infIndex + 1
            end
            
        end
        for i = 1, Server.GetNumMaps() do
        
            local mapName = "infect_" .. string.sub( Server.GetMapName(i), string.len( "ns2_" ) + 1 )
            if MapCycle_GetMapIsInCycle(mapName) then
                Server.SendNetworkMessage( client, "AddVoteMap", { name = mapName, index = infIndex }, true )
                infIndex = infIndex + 1
            end
            
        end
        
    end)

    local kExecuteVoteDelay = 10
    local function OnChangeMapVoteSuccessful(data)
        
        if data.map_index > Server.GetNumMaps() then
            local infIndex = Server.GetNumMaps() + 1
            for i = 1, Server.GetNumMaps() do
                local mapName = "infest_" .. string.sub( Server.GetMapName(i), string.len( "ns2_" ) + 1 )
                if MapCycle_GetMapIsInCycle(mapName) then
                    if infIndex == data.map_index then
                        MapCycle_ChangeMap(mapName)
                        return
                    end
                    infIndex = infIndex + 1
                end
            end
            for i = 1, Server.GetNumMaps() do
                local mapName = "infect_" .. string.sub( Server.GetMapName(i), string.len( "ns2_" ) + 1 )
                if MapCycle_GetMapIsInCycle(mapName) then
                    if infIndex == data.map_index then
                        MapCycle_ChangeMap(mapName)
                        return
                    end
                    infIndex = infIndex + 1
                end
            end
        end
                
        MapCycle_ChangeMap(Server.GetMapName(data.map_index))
    end
    SetVoteSuccessfulCallback("VoteChangeMap", kExecuteVoteDelay, OnChangeMapVoteSuccessful)

end