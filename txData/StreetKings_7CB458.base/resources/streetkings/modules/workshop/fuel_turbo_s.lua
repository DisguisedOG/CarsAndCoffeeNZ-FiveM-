RegisterNetEvent('streetkings:workshop:saveFuel', function(fuelLevel)
    local src = source
    local document = SKSaves.getDocument(src)
    if not document then return end
    
    document.fuel = document.fuel or {}
    document.fuel.currentFuel = math.max(0.0, math.min(100.0, tonumber(fuelLevel) or 100.0))
    SKSaves.persist(src)
end)

lib.callback.register('streetkings:workshop:useRedFuel', function(source)
    local document = SKSaves.getDocument(source)
    if not document or not document.workshop or not document.workshop.consumables then
        return false
    end
    
    local count = document.workshop.consumables['red_fuel_can'] or 0
    if count <= 0 then
        return false
    end
    
    document.workshop.consumables['red_fuel_can'] = count - 1
    SKSaves.persist(source)
    return true
end)

RegisterNetEvent('streetkings:workshop:repairBlownTurbo', function()
    local src = source
    local document = SKSaves.getDocument(src)
    if not document or not document.workshop or not document.workshop.consumables then
        return
    end
    
    local count = document.workshop.consumables['spark_plugs_iridium'] or 0
    if count <= 0 then return end
    
    document.workshop.consumables['spark_plugs_iridium'] = count - 1
    SKSaves.persist(src)
end)
