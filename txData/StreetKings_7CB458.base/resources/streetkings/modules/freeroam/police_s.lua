local BUST_AMOUNT        = 1000
local BUST_COOLDOWN_MS   = 8000
local TRAP_SPAWN_PERCENT = 0.20

---@type table<integer, integer>
local lastBustAt = {}

---@param src integer
---@return boolean
local function canApplyBustFine(src)
    if not SKSaves.hasActiveSave(src) then
        return false
    end

    local now = GetGameTimer()
    if lastBustAt[src] and (now - lastBustAt[src]) < BUST_COOLDOWN_MS then
        return false
    end

    return true
end

AddEventHandler('playerDropped', function()
    lastBustAt[source --[[@as integer]]] = nil
end)

-- Select active traps on resource start ---------------------------------

local activeTraps = {}

local function selectActiveTraps()
    local locations = SKPoliceTrapLocations
    local count     = math.max(1, math.ceil(#locations * TRAP_SPAWN_PERCENT))
    local pool      = {}
    for i = 1, #locations do pool[i] = i end

    activeTraps = {}
    for i = 1, count do
        local pick = math.random(i, #pool)
        pool[i], pool[pick] = pool[pick], pool[i]
        activeTraps[#activeTraps + 1] = locations[pool[i]]
    end

end

selectActiveTraps()

-- Callbacks -------------------------------------------------------------

lib.callback.register('streetkings:police:getActiveTraps', function(_)
    return activeTraps
end)

lib.callback.register('streetkings:police:confirmBust', function(src)
    if not canApplyBustFine(src) then
        return { ok = false }
    end

    lastBustAt[src] = GetGameTimer()
    local document = SKSaves.getDocument(src)
    if not document then
        return { ok = false }
    end

    local current = document.economy.cash or 0
    local deducted = math.min(current, BUST_AMOUNT)
    document.economy.cash = math.max(0, current - BUST_AMOUNT)
    
    -- Increment Busted Strikes & Lock active vehicle in impound for 1 hour
    document.garage = document.garage or {}
    document.garage.bustedStrikes = (document.garage.bustedStrikes or 0) + 1
    
    local activeVehId = document.garage.activeVehicleId
    if activeVehId and activeVehId ~= '' and document.garage.vehicles[activeVehId] then
        local entry = document.garage.vehicles[activeVehId]
        entry.impoundTime = os.time() + 3600 -- 1 hour impound lockout
    end

    SKSaves.persist(src)
    SKStats.increment(src, 'totalCashSpent', deducted)
    SKStats.increment(src, 'policeBusts', 1)

    return { ok = true }
end)

-- Impound App callbacks
lib.callback.register('phone:impound:getState', function(source)
    local document = SKSaves.getDocument(source)
    if not document or not document.garage or not document.garage.vehicles then
        return { ok = false }
    end

    local list = {}
    local now = os.time()
    for id, entry in pairs(document.garage.vehicles) do
        if entry.impoundTime and entry.impoundTime > 0 then
            table.insert(list, {
                id = id,
                displayName = entry.displayName or entry.modelName,
                remainingSeconds = math.max(0, entry.impoundTime - now),
                fee = 1000
            })
        end
    end

    return { ok = true, vehicles = list }
end)

lib.callback.register('phone:impound:release', function(source, data)
    local vehicleId = data.vehicleId
    local pay = data.pay
    
    local document = SKSaves.getDocument(source)
    if not document or not document.garage or not document.garage.vehicles or not document.garage.vehicles[vehicleId] then
        return { ok = false, reason = 'not_found' }
    end

    local entry = document.garage.vehicles[vehicleId]
    local now = os.time()

    if pay then
        local current = document.economy.cash or 0
        if current < 1000 then
            return { ok = false, reason = 'insufficient_funds' }
        end
        document.economy.cash = current - 1000
        entry.impoundTime = nil
        SKSaves.persist(source)
        return { ok = true }
    else
        if entry.impoundTime and now < entry.impoundTime then
            return { ok = false, reason = 'still_locked' }
        end
        entry.impoundTime = nil
        SKSaves.persist(source)
        return { ok = true }
    end
end)