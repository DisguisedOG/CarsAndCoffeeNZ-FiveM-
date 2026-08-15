RegisterNUICallback('phone:supercheap:getState', function(_, cb)
    local state = lib.callback.await('phone:supercheap:getState', false)
    cb(state)
end)

RegisterNUICallback('phone:supercheap:buyItem', function(data, cb)
    local result = lib.callback.await('phone:supercheap:buyItem', false, data.category, data.itemId)
    cb(result)
end)

CreateThread(function()
    for _, loc in ipairs(SKSupercheap.LOCATIONS) do
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, loc.blipSprite or 524)
        SetBlipColour(blip, loc.blipColor or 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(loc.name)
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    local inside = false
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local nearAny = false
        
        for _, loc in ipairs(SKSupercheap.LOCATIONS) do
            local dist = #(coords - loc.coords)
            if dist < 10.0 then
                wait = 0
                DrawMarker(1, loc.coords.x, loc.coords.y, loc.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 255, 59, 48, 120, false, true, 2, false, nil, nil, false)
                if dist < 1.5 then
                    nearAny = true
                    if not inside then
                        inside = true
                        lib.showTextUI('[E] Browse Supercheap Auto')
                    end
                    if IsControlJustReleased(0, 38) then -- E key
                        -- Open phone to Supercheap app
                        SendNUIMessage({
                            type = 'phone:open',
                            app = 'Supercheap'
                        })
                        SetNuiFocus(true, true)
                    end
                end
            end
        end
        
        if not nearAny and inside then
            inside = false
            lib.hideTextUI()
        end
        
        Wait(wait)
    end
end)
