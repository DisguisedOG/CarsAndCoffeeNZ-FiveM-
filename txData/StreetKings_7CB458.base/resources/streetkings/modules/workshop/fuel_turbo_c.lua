SKSpeedo = SKSpeedo or {}
SKSpeedo.FuelLevel = 100.0
SKSpeedo.RedFuelBoostActive = false

local activeVehicle = 0
local activeProfile = nil
local turboBlown = false
local smokeParticleEffect = nil
local lastFuelSave = 100.0

local function syncFuelState()
    local doc = lib.callback.await('phone:mechanic:getState', false)
    if doc and doc.ok then
        SKSpeedo.FuelLevel = doc.fuelCurrent or 100.0
        activeProfile = doc.tuneProfile
    end
end

local function TriggerVehicleBackfire(vehicle)
    local exhaustBone = GetEntityBoneIndexByName(vehicle, "exhaust")
    if exhaustBone ~= -1 then
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do Wait(10) end
        UseParticleFxAssetNextCall("core")
        local pos = GetWorldPositionOfEntityBone(vehicle, exhaustBone)
        local rot = GetEntityRotation(vehicle, 2)
        StartNetworkedParticleFxNonLoopedAtCoord("veh_backfire", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, 1.2, false, false, false)
    end
end

local function blowTurbo(vehicle)
    turboBlown = true
    PlaySoundFromEntity(-1, "EXPLOSION", vehicle, "DEFAULT_NO_SPATIAL_LIMIT", 3.0, 0)
    SKNotify({ type = 'error', title = 'Your turbo has blown! Engine in limp mode.' })
end

CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            wait = 100
            
            if vehicle ~= activeVehicle then
                activeVehicle = vehicle
                syncFuelState()
                lastFuelSave = SKSpeedo.FuelLevel
            end
            
            local rpm = GetVehicleCurrentRpm(vehicle)
            local throttle = GetControlNormal(0, 71)
            
            local maxPsi = 10.0
            local fuelMix = 0.0
            if activeProfile then
                maxPsi = 10.0 + (activeProfile.turboPsi or 0) * 3.0
                fuelMix = activeProfile.fuelMix or 0.0
            end
            
            local currentBoost = (rpm * throttle) * maxPsi
            
            local baseRate = 0.003
            local consumption = baseRate * (1.0 + throttle * 1.5) * (rpm * 1.8)
            
            if currentBoost > 12.0 then
                consumption = consumption * (1.0 + (currentBoost / 15.0) * 0.7)
            end
            
            if fuelMix > 0 then
                consumption = consumption * (1.0 + fuelMix * 0.12)
            end
            
            if SKSpeedo.RedFuelBoostActive then
                consumption = consumption * 2.5
            end
            
            SKSpeedo.FuelLevel = math.max(0.0, SKSpeedo.FuelLevel - consumption)
            
            if math.abs(SKSpeedo.FuelLevel - lastFuelSave) > 1.5 then
                lastFuelSave = SKSpeedo.FuelLevel
                TriggerServerEvent('streetkings:workshop:saveFuel', SKSpeedo.FuelLevel)
            end
            
            if SKSpeedo.FuelLevel <= 0.0 then
                SetVehicleEngineOn(vehicle, false, true, true)
                SKSpeedo.RedFuelBoostActive = false
            end
            
            if SKSpeedo.RedFuelBoostActive then
                SetVehicleCheatPowerIncrease(vehicle, 1.8)
                if throttle > 0.8 and rpm > 0.7 and math.random(100) < 15 then
                    TriggerVehicleBackfire(vehicle)
                end
            end
            
            if turboBlown then
                SetVehicleEnginePowerMultiplier(vehicle, 0.15)
                SetVehicleMaxSpeed(vehicle, 15.0)
                
                if not smokeParticleEffect then
                    local boneIndex = GetEntityBoneIndexByName(vehicle, "bonnet")
                    if boneIndex ~= -1 then
                        RequestNamedPtfxAsset("core")
                        while not HasNamedPtfxAssetLoaded("core") do Wait(10) end
                        UseParticleFxAssetNextCall("core")
                        smokeParticleEffect = StartParticleFxLoopedOnEntityBone("ent_ray_meth_key_smoke", vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, boneIndex, 1.2, false, false, false)
                    end
                end
            else
                if currentBoost > 18.0 and rpm > 0.8 then
                    if math.random(1000) < 5 then
                        blowTurbo(vehicle)
                    end
                end
            end
        else
            if activeVehicle ~= 0 then
                TriggerServerEvent('streetkings:workshop:saveFuel', SKSpeedo.FuelLevel)
                activeVehicle = 0
                SKSpeedo.RedFuelBoostActive = false
                if smokeParticleEffect then
                    RemoveParticleFx(smokeParticleEffect, false)
                    smokeParticleEffect = nil
                end
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    while true do
        Wait(100)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            if IsControlJustReleased(0, 10) then -- PAGE UP key
                if SKSpeedo.RedFuelBoostActive then
                    SKSpeedo.RedFuelBoostActive = false
                    SKNotify({ type = 'info', title = 'Gumball Red Fuel Boost DEACTIVATED' })
                else
                    lib.callback('streetkings:workshop:useRedFuel', false, function(allowed)
                        if allowed then
                            SKSpeedo.RedFuelBoostActive = true
                            SKNotify({ type = 'success', title = 'Gumball Red Fuel Boost ACTIVATED!' })
                        else
                            SKNotify({ type = 'error', title = 'No Gumball Red Fuel Cans available!' })
                        end
                    end)
                end
            end
        end
    end
end)

CreateThread(function()
    local promptShown = false
    while true do
        local wait = 1000
        if turboBlown and activeVehicle ~= 0 then
            local ped = PlayerPedId()
            local veh = activeVehicle
            local vehCoords = GetEntityCoords(veh)
            local coords = GetEntityCoords(ped)
            local dist = #(coords - vehCoords)
            
            if dist < 4.0 and GetVehiclePedIsIn(ped, false) == 0 then
                wait = 0
                local forward = GetEntityForwardVector(veh)
                local frontCoords = vehCoords + forward * 2.0
                local distToFront = #(coords - frontCoords)
                
                if distToFront < 1.8 then
                    if not promptShown then
                        promptShown = true
                        lib.showTextUI('[E] Repair Blown Turbo')
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        lib.hideTextUI()
                        promptShown = false
                        
                        local state = lib.callback.await('phone:supercheap:getState', false)
                        local hasKit = state and state.consumables and (state.consumables['spark_plugs_iridium'] or 0) > 0
                        
                        if not hasKit then
                            SKNotify({ type = 'error', title = 'You need Spark Plugs from Supercheap Auto to repair!' })
                        else
                            TaskStartScenarioInPlace(ped, "PROP_HUMAN_BUM_BIN", 0, true)
                            if lib.progressBar({
                                duration = 8000,
                                label = 'Repairing blown turbo core...',
                                useActiveKey = true,
                                disable = { move = true, car = true }
                            }) then
                                ClearPedTasksImmediately(ped)
                                TriggerServerEvent('streetkings:workshop:repairBlownTurbo')
                                turboBlown = false
                                if smokeParticleEffect then
                                    RemoveParticleFx(smokeParticleEffect, false)
                                    smokeParticleEffect = nil
                                end
                                SKNotify({ type = 'success', title = 'Turbo repaired!' })
                            else
                                ClearPedTasksImmediately(ped)
                            end
                        end
                    end
                else
                    if promptShown then
                        promptShown = false
                        lib.hideTextUI()
                    end
                end
            end
        end
        Wait(wait)
    end
end)
