local rallyBarrel = nil

RegisterNetEvent('streetkings:events:startRallyBarrel', function(vehicle)
    if DoesEntityExist(rallyBarrel) then
        DeleteEntity(rallyBarrel)
        rallyBarrel = nil
    end

    local model = `prop_barrel_01a`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    local coords = GetEntityCoords(vehicle)
    rallyBarrel = CreateObject(model, coords.x, coords.y, coords.z + 1.0, true, true, false)
    AttachEntityToEntity(rallyBarrel, vehicle, 0, 0.0, 0.0, 0.95, 0.0, 0.0, 0.0, false, false, true, false, 2, true)
    
    CreateThread(function()
        local activeVeh = vehicle
        while DoesEntityExist(rallyBarrel) and SKC.GetGameState() == GameState.EVENT do
            Wait(100)
            local roll = GetEntityRoll(activeVeh)
            local pitch = GetEntityPitch(activeVeh)
            local velocity = GetEntityVelocity(activeVeh)
            local verticalForce = math.abs(velocity.z)
            local onWheels = IsVehicleOnAllWheels(activeVeh)
            
            if math.abs(roll) > 55.0 or math.abs(pitch) > 55.0 or (verticalForce > 16.0 and not onWheels) then
                local barrel = rallyBarrel
                rallyBarrel = nil
                
                DetachEntity(barrel, true, true)
                ApplyForceToEntity(barrel, 1, 0.0, 0.0, 15.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                
                SKNotify({ type = 'error', title = 'Rally barrel detached! It is about to explode!' })
                Wait(800)
                
                local bCoords = GetEntityCoords(barrel)
                AddExplosion(bCoords.x, bCoords.y, bCoords.z, 2, 5.0, true, false, 1.0)
                DeleteEntity(barrel)
                
                SKC.SetGameState(GameState.FREEROAM)
                break
            end
        end
        
        if DoesEntityExist(rallyBarrel) then
            DeleteEntity(rallyBarrel)
            rallyBarrel = nil
        end
    end)
end)
