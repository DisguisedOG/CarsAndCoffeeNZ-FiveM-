RegisterNUICallback('phone:stats:getData', function(_, cb)
    local data = lib.callback.await('streetkings:stats:getData', false)
    cb(data)
end)

-- Favorite Vehicle Tracking
local currentVehicle = nil
local currentPlate = nil
local currentModelName = nil
local currentDisplayName = nil
local accumulatedSeconds = 0

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local speed = GetEntitySpeed(veh) * 3.6 -- Convert to km/h
            if speed > 10.0 then
                if currentVehicle ~= veh then
                    -- If we switched vehicles, sync the old one first
                    if accumulatedSeconds > 0 and currentPlate then
                        TriggerServerEvent('streetkings:stats:syncVehicleDriving', currentPlate, currentModelName, currentDisplayName, accumulatedSeconds)
                    end
                    currentVehicle = veh
                    currentPlate = GetVehicleNumberPlateText(veh)
                    local modelHash = GetEntityModel(veh)
                    currentModelName = GetDisplayNameFromVehicleModel(modelHash):lower()
                    currentDisplayName = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
                    if currentDisplayName == "NULL" then
                        currentDisplayName = GetDisplayNameFromVehicleModel(modelHash)
                    end
                    accumulatedSeconds = 0
                end
                
                accumulatedSeconds = accumulatedSeconds + 1
                
                -- Sync every 60 seconds of driving
                if accumulatedSeconds >= 60 then
                    TriggerServerEvent('streetkings:stats:syncVehicleDriving', currentPlate, currentModelName, currentDisplayName, accumulatedSeconds)
                    accumulatedSeconds = 0
                end
            end
        else
            -- Left vehicle, sync remaining accumulated seconds
            if accumulatedSeconds > 0 and currentPlate then
                TriggerServerEvent('streetkings:stats:syncVehicleDriving', currentPlate, currentModelName, currentDisplayName, accumulatedSeconds)
            end
            currentVehicle = nil
            currentPlate = nil
            currentModelName = nil
            currentDisplayName = nil
            accumulatedSeconds = 0
        end
        
        Wait(1000)
    end
end)