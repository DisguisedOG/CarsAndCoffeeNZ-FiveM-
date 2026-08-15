local EscrowJobs = {}
local nextJobId = 1

local function getOnlinePlayers(source)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local idVal = tonumber(playerId)
        if idVal ~= source then
            table.insert(players, {
                id = idVal,
                name = GetPlayerName(idVal)
            })
        end
    end
    return players
end

lib.callback.register('streetkings:escrow:getState', function(source)
    local myJobs = {}
    for _, job in pairs(EscrowJobs) do
        if job.customerId == source or job.mechanicId == source then
            table.insert(myJobs, job)
        end
    end
    
    return {
        ok = true,
        players = getOnlinePlayers(source),
        jobs = myJobs,
        myId = source
    }
end)

lib.callback.register('streetkings:escrow:createJob', function(source, mechanicId, amount, description)
    local amountVal = tonumber(amount) or 0
    local targetMech = tonumber(mechanicId)
    
    if amountVal <= 0 or not targetMech or targetMech == source then
        return { ok = false, reason = 'invalid_parameters' }
    end
    
    local doc = SKSaves.getDocument(source)
    if not doc then
        return { ok = false, reason = 'no_save_loaded' }
    end
    
    local cash = doc.economy.cash or 0
    if cash < amountVal then
        return { ok = false, reason = 'insufficient_funds' }
    end
    
    -- Deduct customer cash and hold in escrow
    doc.economy.cash = cash - amountVal
    SKSaves.persist(source)
    
    local jobId = tostring(nextJobId)
    nextJobId = nextJobId + 1
    
    EscrowJobs[jobId] = {
        id = jobId,
        customerId = source,
        mechanicId = targetMech,
        amount = amountVal,
        description = description,
        status = 'pending',
        timeout = os.time() + 300 -- 5 minutes timeout
    }
    
    TriggerClientEvent('chat:addMessage', targetMech, {
        args = { ('^2[Escrow] Player %s [%d] offered you a service contract: "%s" for $%d. Open tablet to accept.'):format(GetPlayerName(source), source, description, amountVal) }
    })
    
    return { ok = true }
end)

lib.callback.register('streetkings:escrow:acceptJob', function(source, jobId)
    local job = EscrowJobs[jobId]
    if not job or job.mechanicId ~= source or job.status ~= 'pending' then
        return { ok = false, reason = 'invalid_job' }
    end
    
    job.status = 'active'
    job.timeout = os.time() + 300 -- Reset timeout to 5 mins from acceptance
    
    TriggerClientEvent('chat:addMessage', job.customerId, {
        args = { ('^2[Escrow] Mechanic %s accepted your service contract!'):format(GetPlayerName(source)) }
    })
    
    return { ok = true }
end)

lib.callback.register('streetkings:escrow:completeJob', function(source, jobId)
    local job = EscrowJobs[jobId]
    if not job or job.mechanicId ~= source or job.status ~= 'active' then
        return { ok = false, reason = 'invalid_job' }
    end
    
    job.status = 'completed'
    job.timeout = os.time() + 300 -- Reset timeout for confirmation
    
    TriggerClientEvent('chat:addMessage', job.customerId, {
        args = { ('^2[Escrow] Mechanic %s marked the contract as complete! Confirm via tablet to release funds.'):format(GetPlayerName(source)) }
    })
    
    return { ok = true }
end)

lib.callback.register('streetkings:escrow:confirmJob', function(source, jobId)
    local job = EscrowJobs[jobId]
    if not job or job.customerId ~= source or job.status ~= 'completed' then
        return { ok = false, reason = 'invalid_job' }
    end
    
    local mechDoc = SKSaves.getDocument(job.mechanicId)
    if mechDoc then
        local currentCash = mechDoc.economy.cash or 0
        mechDoc.economy.cash = currentCash + job.amount
        SKSaves.persist(job.mechanicId)
        
        -- Award Mechanic XP
        if SKMechanic and SKMechanic.awardXp then
            SKMechanic.awardXp(job.mechanicId, 150)
        end
        
        TriggerClientEvent('chat:addMessage', job.mechanicId, {
            args = { ('^2[Escrow] Contract confirmed! $%d released to your cash balance, +150 Mechanic XP.'):format(job.amount) }
        })
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        args = { ('^2[Escrow] Funds of $%d released to mechanic.'):format(job.amount) }
    })
    
    EscrowJobs[jobId] = nil
    return { ok = true }
end)

-- Escrow timeout check thread
CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()
        for jobId, job in pairs(EscrowJobs) do
            if now > job.timeout then
                -- Timeout! Auto refund customer
                local custDoc = SKSaves.getDocument(job.customerId)
                if custDoc then
                    local currentCash = custDoc.economy.cash or 0
                    custDoc.economy.cash = currentCash + job.amount
                    SKSaves.persist(job.customerId)
                    
                    TriggerClientEvent('chat:addMessage', job.customerId, {
                        args = { ('^1[Escrow] Contract timeout! $%d has been automatically refunded to your cash balance.'):format(job.amount) }
                    })
                end
                
                TriggerClientEvent('chat:addMessage', job.mechanicId, {
                    args = { ('^1[Escrow] Contract timeout! Job was cancelled or unconfirmed.'):format() }
                })
                
                EscrowJobs[jobId] = nil
            end
        end
    end
end)
