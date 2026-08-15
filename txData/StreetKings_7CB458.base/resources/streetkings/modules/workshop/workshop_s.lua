lib.callback.register('streetkings:workshop:placeTool', function(source, toolType, coords, heading, isMove)
    local document = assert(SKSaves.getDocument(source))
    document.workshop = document.workshop or {}
    document.workshop.placedTools = document.workshop.placedTools or {}
    document.workshop.tools = document.workshop.tools or {}

    local ownedKey = 'mech_tool_' .. toolType
    if toolType == 'psi' then ownedKey = 'mech_tool_psi_station' end
    if toolType == 'turbo' then ownedKey = 'mech_tool_turbo_bay' end
    if toolType == 'service' then ownedKey = 'mech_tool_service_bay' end

    if not document.workshop.tools[ownedKey] then
        return { ok = false, reason = 'You do not own this tool!' }
    end

    local existingIndex = nil
    for idx, t in ipairs(document.workshop.placedTools) do
        if t.type == toolType then
            existingIndex = idx
            break
        end
    end

    if existingIndex then
        local entry = document.workshop.placedTools[existingIndex]
        local moves = (entry.moveCount or 0) + 1
        if moves >= 3 then
            table.remove(document.workshop.placedTools, existingIndex)
            document.workshop.tools[ownedKey] = nil
            SKSaves.persist(source)
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1[Supercheap Auto] Your tool broke! Go buy another one.' }
            })
            return { ok = false, reason = 'Your tool broke!' }
        else
            entry.coords = coords
            entry.heading = heading
            entry.moveCount = moves
        end
    else
        table.insert(document.workshop.placedTools, {
            type = toolType,
            coords = coords,
            heading = heading,
            moveCount = 0
        })
    end

    SKSaves.persist(source)
    return { ok = true }
end)

lib.callback.register('streetkings:workshop:removeTool', function(source, toolType)
    local document = assert(SKSaves.getDocument(source))
    document.workshop = document.workshop or {}
    document.workshop.placedTools = document.workshop.placedTools or {}

    for idx, t in ipairs(document.workshop.placedTools) do
        if t.type == toolType then
            table.remove(document.workshop.placedTools, idx)
            SKSaves.persist(source)
            return { ok = true }
        end
    end

    return { ok = false, reason = 'not_placed' }
end)

lib.callback.register('phone:mechanic:unlockPerk', function(source, perkName)
    local document = assert(SKSaves.getDocument(source))
    local mechanic = document.mechanic
    if not mechanic then return { ok = false, reason = 'no_mechanic_profile' } end
    
    local points = mechanic.perkPoints or 0
    if points < 1 then
        return { ok = false, reason = 'insufficient_perk_points' }
    end
    
    mechanic.perks = mechanic.perks or {}
    if mechanic.perks[perkName] == true then
        return { ok = false, reason = 'already_unlocked' }
    end
    
    mechanic.perks[perkName] = true
    mechanic.perkPoints = points - 1
    SKSaves.persist(source)
    return { ok = true }
end)

-- Mechanic progression limits & levels
SKMechanic = {}
SKMechanic.MAX_LEVEL = 10
SKMechanic.LEVEL_THRESHOLDS = {
    [1] = 0,
    [2] = 500,
    [3] = 1200,
    [4] = 2200,
    [5] = 3500,
    [6] = 5000,
    [7] = 7000,
    [8] = 9500,
    [9] = 12500,
    [10] = 16000,
}

function SKMechanic.awardXp(source, amount)
    local document = SKSaves.getDocument(source)
    if not document or not document.mechanic then return end
    
    local mechanic = document.mechanic
    local oldXp = mechanic.xp or 0
    local oldLevel = mechanic.level or 1
    
    if oldLevel >= SKMechanic.MAX_LEVEL then
        return
    end
    
    local newXp = oldXp + amount
    local newLevel = oldLevel
    
    for level = oldLevel + 1, SKMechanic.MAX_LEVEL do
        if newXp >= SKMechanic.LEVEL_THRESHOLDS[level] then
            newLevel = level
        else
            break
        end
    end
    
    mechanic.xp = newXp
    
    if newLevel > oldLevel then
        local earnedPoints = newLevel - oldLevel
        mechanic.level = newLevel
        mechanic.perkPoints = (mechanic.perkPoints or 0) + earnedPoints
        
        TriggerClientEvent('chat:addMessage', source, {
            args = { ('^2[Mechanic Skill] Level Up! You are now Level %d. Earned %d perk points.'):format(newLevel, earnedPoints) }
        })
    end
    
    SKSaves.persist(source)
end

-- Tuning parameter saves
RegisterNetEvent('streetkings:workshop:saveStance', function(camber, toe)
    local src = source
    local doc = SKSaves.getDocument(src)
    if not doc or not doc.workshop then return end
    
    doc.workshop.tuneProfile = doc.workshop.tuneProfile or {}
    doc.workshop.tuneProfile.camber = tonumber(camber) or 0
    doc.workshop.tuneProfile.toe = tonumber(toe) or 0
    SKSaves.persist(src)
    SKMechanic.awardXp(src, 50) -- 50 XP for tuning
end)

RegisterNetEvent('streetkings:workshop:saveTurboPsi', function(psi)
    local src = source
    local doc = SKSaves.getDocument(src)
    if not doc or not doc.workshop then return end
    
    doc.workshop.tuneProfile = doc.workshop.tuneProfile or {}
    doc.workshop.tuneProfile.turboPsi = tonumber(psi) or 0
    SKSaves.persist(src)
    SKMechanic.awardXp(src, 50)
end)

RegisterNetEvent('streetkings:workshop:saveFuelMix', function(mix)
    local src = source
    local doc = SKSaves.getDocument(src)
    if not doc or not doc.workshop then return end
    
    doc.workshop.tuneProfile = doc.workshop.tuneProfile or {}
    doc.workshop.tuneProfile.fuelMix = tonumber(mix) or 0
    SKSaves.persist(src)
    SKMechanic.awardXp(src, 50)
end)

RegisterNetEvent('streetkings:workshop:saveRideHeight', function(height)
    local src = source
    local doc = SKSaves.getDocument(src)
    if not doc or not doc.workshop then return end
    
    doc.workshop.tuneProfile = doc.workshop.tuneProfile or {}
    doc.workshop.tuneProfile.rideHeight = tonumber(height) or 0
    SKSaves.persist(src)
    SKMechanic.awardXp(src, 50)
end)

RegisterNetEvent('streetkings:workshop:awardDynoXp', function()
    local src = source
    SKMechanic.awardXp(src, 100) -- 100 XP for dyno run
end)

-- Seat Time driving perk award
RegisterNetEvent('streetkings:workshop:earnSeatTime', function()
    local src = source
    local doc = SKSaves.getDocument(src)
    if not doc then return end
    
    local cash = doc.economy.cash or 0
    doc.economy.cash = cash + 50
    SKSaves.persist(src)
    
    SKMechanic.awardXp(src, 25) -- 25 XP
    TriggerClientEvent('chat:addMessage', src, {
        args = { '^2[Seat Time] Passive Driving Reward: Earned $50 and 25 Mechanic XP!' }
    })
end)
