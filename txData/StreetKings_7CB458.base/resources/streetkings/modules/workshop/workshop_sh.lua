SKWorkshop = SKWorkshop or {}
SKFuel = SKFuel or {}

SKWorkshop.DEFAULT_TUNE_PROFILE = {
    rideHeight = 0,
    camber = 0,
    toe = 0,
    turboPsi = 0,
    fuelMix = 0,
}

SKFuel.DEFAULT_PRICE = 2.40
SKFuel.DEFAULT_CAPACITY = 100
SKFuel.DEFAULT_FUEL_TYPE = 'regular'

---@param source integer
---@return SKSaveDocument|nil
local function getDocument(source)
    if not SKSaves or not SKSaves.getDocument then
        return nil
    end
    return SKSaves.getDocument(source)
end

---@param source integer
---@return boolean
function SKWorkshop.hasHouse(source)
    local document = getDocument(source)
    if not document then
        return false
    end

    if document.workshop and document.workshop.hasHouse == true then
        return true
    end

    if type(document.properties) == 'table' and type(document.properties.owned) == 'table' then
        for _, owned in pairs(document.properties.owned) do
            if owned == true then
                return true
            end
        end
    end

    return false
end

---@param source integer
---@return boolean
function SKWorkshop.isUnlocked(source)
    local document = getDocument(source)
    if not document or type(document.workshop) ~= 'table' then
        return false
    end

    return document.workshop.unlocked == true or SKWorkshop.hasHouse(source)
end

---@param source integer
---@return table
function SKWorkshop.getState(source)
    local document = getDocument(source) or {}
    local workshop = type(document.workshop) == 'table' and document.workshop or {}
    local mechanic = type(document.mechanic) == 'table' and document.mechanic or {}
    local fuel = type(document.fuel) == 'table' and document.fuel or {}

    return {
        hasHouse = SKWorkshop.hasHouse(source),
        unlocked = workshop.unlocked == true,
        level = tonumber(mechanic.level) or 1,
        xp = tonumber(mechanic.xp) or 0,
        perkPoints = tonumber(mechanic.perkPoints) or 0,
        fuelLevel = tonumber(fuel.currentFuel) or 0,
        fuelMax = tonumber(fuel.maxFuel) or SKFuel.DEFAULT_CAPACITY,
        fuelName = fuel.fuelType or SKFuel.DEFAULT_FUEL_TYPE,
        tuneProfile = workshop.tuneProfile or SKWorkshop.DEFAULT_TUNE_PROFILE,
    }
end

SKFuel = SKFuel or {}
SKFuel.currentPrice = SKFuel.DEFAULT_PRICE

if IsDuplicityVersion() then
    SKFuelSettings = {
        globalPrice = 2.40,
        nearestStationOverrideEnabled = false,
        nearestStationOverridePrice = 2.40,
    }

    function SKFuel.getPrice()
        if SKFuelSettings.nearestStationOverrideEnabled and SKFuelSettings.nearestStationOverridePrice then
            return SKFuelSettings.nearestStationOverridePrice
        end
        return SKFuelSettings.globalPrice
    end

    RegisterNetEvent('streetkings:fuel:requestPrice', function()
        local src = source
        TriggerClientEvent('streetkings:fuel:syncPrice', src, SKFuel.getPrice())
    end)
else
    function SKFuel.getPrice()
        return SKFuel.currentPrice
    end

    RegisterNetEvent('streetkings:fuel:syncPrice', function(price)
        SKFuel.currentPrice = price
    end)

    CreateThread(function()
        while not NetworkIsSessionStarted() do Wait(100) end
        TriggerServerEvent('streetkings:fuel:requestPrice')
    end)
end

---@return number
function SKFuel.getDefaultCapacity()
    return SKFuel.DEFAULT_CAPACITY
end

---@param source integer
---@return table
function SKFuel.getPlayerState(source)
    local document = getDocument(source) or {}
    local fuel = type(document.fuel) == 'table' and document.fuel or {}

    return {
        currentFuel = tonumber(fuel.currentFuel) or 0,
        maxFuel = tonumber(fuel.maxFuel) or SKFuel.DEFAULT_CAPACITY,
        fuelType = fuel.fuelType or SKFuel.DEFAULT_FUEL_TYPE,
        redFuelBoost = fuel.redFuelBoost == true,
        price = SKFuel.getPrice(),
    }
end
