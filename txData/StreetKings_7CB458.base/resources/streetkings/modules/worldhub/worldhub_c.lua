RegisterNUICallback('phone:worldhub:getState', function(_, cb)
    local data = lib.callback.await('phone:worldhub:getState', false)
    cb(data)
end)

RegisterNUICallback('phone:worldhub:setFuelSettings', function(data, cb)
    local result = lib.callback.await('phone:worldhub:setFuelSettings', false, data)
    cb(result)
end)

RegisterNUICallback('phone:worldhub:setLoadscreenTune', function(tuneName, cb)
    local result = lib.callback.await('phone:worldhub:setLoadscreenTune', false, tuneName)
    cb(result)
end)

RegisterNUICallback('phone:worldhub:getPlayerGarage', function(targetId, cb)
    local result = lib.callback.await('phone:worldhub:getPlayerGarage', false, targetId)
    cb(result)
end)

RegisterNUICallback('phone:worldhub:setPlayerCash', function(data, cb)
    local result = lib.callback.await('phone:worldhub:setPlayerCash', false, data.targetId, data.amount)
    cb(result)
end)

RegisterNUICallback('phone:worldhub:setPlayerXp', function(data, cb)
    local result = lib.callback.await('phone:worldhub:setPlayerXp', false, data.targetId, data.xp)
    cb(result)
end)

RegisterNUICallback('phone:worldhub:setPlayerLevel', function(data, cb)
    local result = lib.callback.await('phone:worldhub:setPlayerLevel', false, data.targetId, data.level)
    cb(result)
end)

RegisterNUICallback('phone:worldhub:banPlayer', function(targetId, cb)
    local result = lib.callback.await('phone:worldhub:banPlayer', false, targetId)
    cb(result)
end)

RegisterNUICallback('phone:worldhub:givePlayerCash', function(data, cb)
    local result = lib.callback.await('phone:worldhub:givePlayerCash', false, data.targetId, data.amount)
    cb(result)
end)

RegisterNetEvent('streetkings:worldhub:client:syncState', function(cash, level, xp)
    if cash then
        SendNUIMessage({
            type = 'phone:updateCash',
            cash = cash
        })
    end
    if level then
        SKNotify({
            type = 'success',
            title = 'Driver Level Set: Lv. ' .. tostring(level),
            duration = 3500
        })
    end
end)
