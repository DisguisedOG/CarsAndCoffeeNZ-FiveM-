local spawnedProps = {}
local placingActive = false

SKWorkshop = SKWorkshop or {}

function SKWorkshop.applyTuneProfile(vehicle, profile)
    if not DoesEntityExist(vehicle) then return end
    if not profile then return end
    
    -- 1. Suspension / Ride Height (-5 to 5) -> -0.1 to 0.1
    local height = (tonumber(profile.rideHeight) or 0) * -0.02
    SetVehicleSuspensionHeight(vehicle, height)
    
    -- 2. Camber (-5 to 5) -> -0.15 to 0.15
    local camber = (tonumber(profile.camber) or 0) * -0.03
    local numWheels = GetVehicleNumberOfWheels(vehicle)
    for i = 0, numWheels - 1 do
        SetVehicleWheelCamber(vehicle, i, camber)
    end
end

CreateThread(function()
    local lastVehicle = 0
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            if vehicle ~= lastVehicle then
                lastVehicle = vehicle
                local doc = lib.callback.await('phone:mechanic:getState', false)
                if doc and doc.ok then
                    if doc.hasHouse or doc.unlocked then
                        SKWorkshop.applyTuneProfile(vehicle, doc.tuneProfile)
                    end
                end
            end
        else
            lastVehicle = 0
        end
    end
end)

local function interactWithTool(tool, state)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local hasFineTune = state.perks and state.perks.fineTune == true
    
    if tool.type == 'alignment' then
        if veh == 0 then
            SKNotify({ type = 'error', title = 'You must be inside a vehicle!' })
            return
        end
        local limit = hasFineTune and 8.0 or 5.0
        local input = lib.inputDialog('Wheel Stance Calibration', {
            { type = 'slider', label = 'Camber Offset', min = -limit, max = limit, default = activeProfile and activeProfile.camber or 0 },
            { type = 'slider', label = 'Wheel Toe / Offset', min = -limit, max = limit, default = activeProfile and activeProfile.toe or 0 }
        })
        if input then
            TriggerServerEvent('streetkings:workshop:saveStance', input[1], input[2])
            SKNotify({ type = 'success', title = 'Stance saved!' })
            Wait(200)
            syncFuelState()
            Wait(100)
            SKWorkshop.applyTuneProfile(veh, activeProfile)
        end
    elseif tool.type == 'psi' or tool.type == 'turbo' then
        if veh == 0 then
            SKNotify({ type = 'error', title = 'You must be inside a vehicle!' })
            return
        end
        local limit = hasFineTune and 25.0 or 15.0
        local input = lib.inputDialog('Turbo Boost Calibration', {
            { type = 'slider', label = 'Target Boost (PSI)', min = 0, max = limit, default = activeProfile and activeProfile.turboPsi or 0 }
        })
        if input then
            TriggerServerEvent('streetkings:workshop:saveTurboPsi', input[1])
            SKNotify({ type = 'success', title = 'Turbo PSI settings saved!' })
            Wait(200)
            syncFuelState()
        end
    elseif tool.type == 'workbench' or tool.type == 'service' then
        if veh == 0 then
            SKNotify({ type = 'error', title = 'You must be inside a vehicle!' })
            return
        end
        local input = lib.inputDialog('Engine Mixture Calibration', {
            { type = 'slider', label = 'Fuel Mixture Mix (-Lean / +Rich)', min = -5, max = 5, default = activeProfile and activeProfile.fuelMix or 0 }
        })
        if input then
            TriggerServerEvent('streetkings:workshop:saveFuelMix', input[1])
            SKNotify({ type = 'success', title = 'Engine fuel mixture calibrated!' })
            Wait(200)
            syncFuelState()
        end
    elseif tool.type == 'dyno' then
        if veh == 0 then
            SKNotify({ type = 'error', title = 'You must be inside a vehicle!' })
            return
        end
        FreezeEntityPosition(veh, true)
        CreateThread(function()
            if lib.progressBar({
                duration = 6000,
                label = 'Running Dyno Test...',
                useActiveKey = true,
                disable = { move = true, car = true }
            }) then
                FreezeEntityPosition(veh, false)
                local hp = math.floor(250 + (activeProfile and activeProfile.turboPsi or 0) * 18 + (activeProfile and activeProfile.fuelMix or 0) * 12)
                lib.alertDialog({
                    header = 'Dyno Performance Report',
                    content = ('Measured Power: %d HP\nEngine Status: Healthy\nBoost Level: %d PSI'):format(hp, activeProfile and activeProfile.turboPsi or 0),
                    centered = true
                })
                TriggerServerEvent('streetkings:workshop:awardDynoXp')
            else
                FreezeEntityPosition(veh, false)
            end
        end)
    elseif tool.type == 'lift' then
        if veh == 0 then
            SKNotify({ type = 'error', title = 'You must be inside a vehicle!' })
            return
        end
        local input = lib.inputDialog('Suspension Ride Height', {
            { type = 'slider', label = 'Ride Height Offset', min = -5, max = 5, default = activeProfile and activeProfile.rideHeight or 0 }
        })
        if input then
            TriggerServerEvent('streetkings:workshop:saveRideHeight', input[1])
            SKNotify({ type = 'success', title = 'Ride height saved!' })
            Wait(200)
            syncFuelState()
            Wait(100)
            SKWorkshop.applyTuneProfile(veh, activeProfile)
        end
    end
end

CreateThread(function()
    local insidePrompt = false
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        if SKC.GetGameState() == GameState.PROPERTY then
            local state = lib.callback.await('phone:supercheap:getState', false)
            if state and state.ok and state.placedTools then
                local nearAny = false
                for _, tool in ipairs(state.placedTools) do
                    local dist = #(coords - tool.coords)
                    if dist < 2.0 then
                        nearAny = true
                        wait = 0
                        local label = 'Workbench'
                        if tool.type == 'lift' then label = 'Car Lift'
                        elseif tool.type == 'dyno' then label = 'Dyno Roller'
                        elseif tool.type == 'psi' then label = 'PSI Calibration'
                        elseif tool.type == 'alignment' then label = 'Wheel Alignment'
                        elseif tool.type == 'turbo' then label = 'Turbo Desk'
                        elseif tool.type == 'service' then label = 'Service Bay'
                        end
                        
                        if not insidePrompt then
                            insidePrompt = true
                            lib.showTextUI('[E] Use ' .. label)
                        end
                        
                        if IsControlJustReleased(0, 38) then
                            interactWithTool(tool, state)
                        end
                        break
                    end
                end
                if not nearAny and insidePrompt then
                    insidePrompt = false
                    lib.hideTextUI()
                end
            end
        end
        Wait(wait)
    end
end)

-- Seat Time driving XP check
CreateThread(function()
    local driveTimer = 0
    while true do
        Wait(5000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped and GetEntitySpeed(vehicle) > 2.7 then
            local state = lib.callback.await('phone:mechanic:getState', false)
            if state and state.ok and state.perks and state.perks.seatTime == true then
                driveTimer = driveTimer + 5
                if driveTimer >= 60 then
                    driveTimer = 0
                    TriggerServerEvent('streetkings:workshop:earnSeatTime')
                end
            end
        else
            driveTimer = 0
        end
    end
end)

local function clearSpawnedTools()
    for _, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    spawnedProps = {}
end

local function spawnPlacedTools(placedTools)
    clearSpawnedTools()
    if not placedTools then return end
    
    local toolCatalog = {
        workbench = 'prop_tool_bench_02',
        lift = 'prop_car_lift_01',
        dyno = 'prop_roadcone02a',
        psi = 'prop_cabinet_02b',
        alignment = 'prop_wheel_01',
        turbo = 'prop_laptop_01a',
        service = 'prop_crate_pile_01'
    }

    for _, tool in ipairs(placedTools) do
        local model = toolCatalog[tool.type]
        if model then
            local modelHash = GetHashKey(model)
            RequestModel(modelHash)
            while not HasModelLoaded(modelHash) do Wait(10) end
            local prop = CreateObject(modelHash, tool.coords.x, tool.coords.y, tool.coords.z, false, false, false)
            SetEntityHeading(prop, tool.heading)
            FreezeEntityPosition(prop, true)
            table.insert(spawnedProps, prop)
        end
    end
end

CreateThread(function()
    local wasInProperty = false
    while true do
        Wait(500)
        local inProperty = SKC.GetGameState() == GameState.PROPERTY
        if inProperty ~= wasInProperty then
            wasInProperty = inProperty
            if inProperty then
                local state = lib.callback.await('phone:supercheap:getState', false)
                if state and state.ok then
                    spawnPlacedTools(state.placedTools)
                end
            else
                clearSpawnedTools()
            end
        end
    end
end)

RegisterNUICallback('phone:workshop:startPlacing', function(data, cb)
    local toolType = data.tool
    local isMove = data.move == true
    cb({ ok = true })
    
    SKPhone.close()
    placingActive = true
    
    local toolCatalog = {
        workbench = 'prop_tool_bench_02',
        lift = 'prop_car_lift_01',
        dyno = 'prop_roadcone02a',
        psi = 'prop_cabinet_02b',
        alignment = 'prop_wheel_01',
        turbo = 'prop_laptop_01a',
        service = 'prop_crate_pile_01'
    }
    
    local model = toolCatalog[toolType]
    if not model then
        placingActive = false
        return
    end
    
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end
    
    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    local heading = GetEntityHeading(ped)
    
    local tempProp = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(tempProp, 150, false)
    SetEntityCollision(tempProp, false, false)
    
    lib.showTextUI('[WASD/Arrows] Move • [PgUp/PgDn] Rotate • [Shift/Ctrl] Z-Height • [Enter] Confirm • [Esc/Backspace] Cancel')
    
    CreateThread(function()
        while placingActive do
            Wait(0)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            DisableControlAction(0, 174, true)
            DisableControlAction(0, 175, true)
            
            local propCoords = GetEntityCoords(tempProp)
            local propHeading = GetEntityHeading(tempProp)
            local moveSpeed = 0.03
            local rotateSpeed = 1.5
            
            if IsDisabledControlPressed(0, 172) or IsControlPressed(0, 32) then
                local forward = GetEntityForwardVector(ped)
                SetEntityCoords(tempProp, propCoords.x + forward.x * moveSpeed, propCoords.y + forward.y * moveSpeed, propCoords.z, false, false, false, false)
            elseif IsDisabledControlPressed(0, 173) or IsControlPressed(0, 31) then
                local forward = GetEntityForwardVector(ped)
                SetEntityCoords(tempProp, propCoords.x - forward.x * moveSpeed, propCoords.y - forward.y * moveSpeed, propCoords.z, false, false, false, false)
            end
            
            if IsDisabledControlPressed(0, 174) or IsControlPressed(0, 34) then
                local right = GetEntityMatrix(ped)
                SetEntityCoords(tempProp, propCoords.x - right.x * moveSpeed, propCoords.y - right.y * moveSpeed, propCoords.z, false, false, false, false)
            elseif IsDisabledControlPressed(0, 175) or IsControlPressed(0, 35) then
                local right = GetEntityMatrix(ped)
                SetEntityCoords(tempProp, propCoords.x + right.x * moveSpeed, propCoords.y + right.y * moveSpeed, propCoords.z, false, false, false, false)
            end
            
            if IsControlPressed(0, 10) then
                SetEntityHeading(tempProp, (propHeading - rotateSpeed) % 360)
            elseif IsControlPressed(0, 11) then
                SetEntityHeading(tempProp, (propHeading + rotateSpeed) % 360)
            end
            
            if IsControlPressed(0, 21) then
                SetEntityCoords(tempProp, propCoords.x, propCoords.y, propCoords.z + 0.015, false, false, false, false)
            elseif IsControlPressed(0, 36) then
                SetEntityCoords(tempProp, propCoords.x, propCoords.y, propCoords.z - 0.015, false, false, false, false)
            end
            
            if IsControlJustReleased(0, 18) then
                placingActive = false
                local finalCoords = GetEntityCoords(tempProp)
                local finalHeading = GetEntityHeading(tempProp)
                DeleteEntity(tempProp)
                lib.hideTextUI()
                
                lib.callback('streetkings:workshop:placeTool', false, function(result)
                    if result and result.ok then
                        SKNotify({ type = 'success', title = 'Tool placed!' })
                        local state = lib.callback.await('phone:supercheap:getState', false)
                        if state and state.ok then
                            spawnPlacedTools(state.placedTools)
                        end
                    else
                        SKNotify({ type = 'error', title = result.reason or 'Failed to place tool' })
                    end
                end, toolType, finalCoords, finalHeading, isMove)
            end
            
            if IsControlJustReleased(0, 177) or IsControlJustReleased(0, 194) or IsControlJustReleased(0, 200) then
                placingActive = false
                DeleteEntity(tempProp)
                lib.hideTextUI()
                SKNotify({ type = 'info', title = 'Placing cancelled' })
            end
        end
    end)
end)

RegisterNUICallback('phone:workshop:removeTool', function(data, cb)
    local tool = data.tool
    lib.callback('streetkings:workshop:removeTool', false, function(result)
        if result and result.ok then
            local state = lib.callback.await('phone:supercheap:getState', false)
            if state and state.ok then
                spawnPlacedTools(state.placedTools)
            end
            cb({ ok = true })
        else
            cb({ ok = false })
        end
    end, tool)
end)

RegisterNUICallback('phone:mechanic:unlockPerk', function(data, cb)
    local result = lib.callback.await('phone:mechanic:unlockPerk', false, data.perk)
    cb(result)
end)
