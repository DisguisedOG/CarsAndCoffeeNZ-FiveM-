RegisterNetEvent('streetkings:admin:teleport', function(x, y, z)
    SKC.Warp(vector3(x, y, z), GetEntityHeading(PlayerPedId()))
end)

RegisterNetEvent('streetkings:admin:teleportMarker', function()
    local ok, message = SKC.WarpToWaypoint()
    if not ok and message then
        SKNotify({ type = 'error', title = message })
    end
end)

RegisterNetEvent('streetkings:admin:logout', function()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    SKC.SetGameState(GameState.MAIN_MENU)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('streetkings:admin:copyCoords', function(coords)
    lib.setClipboard(('vector3(%.4f, %.4f, %.4f)'):format(coords.x, coords.y, coords.z))
end)

RegisterNetEvent('streetkings:admin:copyCoords4', function(coords, heading)
    lib.setClipboard(('vector4(%.4f, %.4f, %.4f, %.4f)'):format(coords.x, coords.y, coords.z, heading))
end)

-- Admin Spectating Logic
local spectating = false
local originalCoords = nil
local spectateTarget = nil

RegisterNUICallback('phone:worldhub:spectate', function(data, cb)
    local targetId = tonumber(data.targetId)
    if not targetId then return cb({ ok = false }) end
    
    TriggerServerEvent('streetkings:worldhub:requestSpectate', targetId)
    cb({ ok = true })
end)

RegisterNetEvent('streetkings:worldhub:startSpectate', function(targetId, targetCoords)
    local ped = PlayerPedId()
    if spectating then
        TriggerEvent('streetkings:worldhub:stopSpectate')
        return
    end

    if targetCoords.x == 0 and targetCoords.y == 0 and targetCoords.z == 0 then
        SKNotify({ type = 'error', title = 'Player not found or offline' })
        return
    end

    spectating = true
    spectateTarget = targetId
    originalCoords = GetEntityCoords(ped)

    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)

    SetEntityCoords(ped, targetCoords.x, targetCoords.y, targetCoords.z - 10.0, false, false, false, false)

    CreateThread(function()
        local timeout = GetGameTimer() + 5000
        local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
        
        while spectating and (targetPed == 0 or not HasCollisionLoadedAroundEntity(targetPed)) and GetGameTimer() < timeout do
            Wait(100)
            targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
        end

        if not spectating then return end

        if targetPed ~= 0 then
            NetworkSetInSpectatorMode(true, targetPed)
            SendNUIMessage({ type = 'worldhub:spectateUpdate', active = true })
            SKNotify({ type = 'success', title = 'Spectating player ' .. targetId })
        else
            spectating = false
            SetEntityVisible(ped, true, false)
            SetEntityCollision(ped, true, true)
            FreezeEntityPosition(ped, false)
            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
            originalCoords = nil
            spectateTarget = nil
            SKNotify({ type = 'error', title = 'Failed to stream target player entity' })
        end
    end)
end)

RegisterNetEvent('streetkings:worldhub:stopSpectate', function()
    if spectating then
        local ped = PlayerPedId()
        spectating = false
        NetworkSetInSpectatorMode(false, GetPlayerPed(spectateTarget))
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        if originalCoords then
            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
        end
        originalCoords = nil
        spectateTarget = nil
        SendNUIMessage({ type = 'worldhub:spectateUpdate', active = false })
        SKNotify({ type = 'info', title = 'Stopped spectating' })
    end
end)

CreateThread(function()
    while true do
        Wait(250)
        if spectating then
            if IsControlJustReleased(0, 177) or IsControlJustReleased(0, 194) or IsControlJustReleased(0, 200) then -- BACKSPACE / ESC
                TriggerEvent('streetkings:worldhub:stopSpectate')
            end
        end
    end
end)