RegisterNUICallback('phone:mechanic:getEscrowJobs', function(_, cb)
    local state = lib.callback.await('streetkings:escrow:getState', false)
    cb(state)
end)

RegisterNUICallback('phone:mechanic:createEscrowJob', function(data, cb)
    local result = lib.callback.await('streetkings:escrow:createJob', false, data.mechanicId, data.amount, data.description)
    cb(result)
end)

RegisterNUICallback('phone:mechanic:acceptEscrowJob', function(data, cb)
    local result = lib.callback.await('streetkings:escrow:acceptJob', false, data.jobId)
    cb(result)
end)

RegisterNUICallback('phone:mechanic:completeEscrowJob', function(data, cb)
    local result = lib.callback.await('streetkings:escrow:completeJob', false, data.jobId)
    cb(result)
end)

RegisterNUICallback('phone:mechanic:confirmEscrowJob', function(data, cb)
    local result = lib.callback.await('streetkings:escrow:confirmJob', false, data.jobId)
    cb(result)
end)
