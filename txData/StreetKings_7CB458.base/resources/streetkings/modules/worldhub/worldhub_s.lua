local function isAdmin(source)
    if IsPlayerAceAllowed(source, 'command') == 1 then
        return true
    end
    local numPlayers = #GetPlayers()
    if numPlayers <= 1 then
        return true
    end
    local ep = GetPlayerEndpoint(source)
    if ep and (ep == '127.0.0.1' or ep == 'localhost' or ep:match('^127%.') or ep:match('^192%.168%.')) then
        return true
    end
    return false
end

local SKActiveTune = "Cars And Coffee Soundtrack.mp3"

local function scanTunesFolder()
    local tunes = {}
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local folderPath = resourcePath .. "/Tunes"
    
    os.execute('mkdir "' .. folderPath:gsub("/", "\\") .. '" 2>nul')

    local p = io.popen('dir "' .. folderPath:gsub("/", "\\") .. '" /b /a-d')
    if p then
        for file in p:lines() do
            if file:match("%.mp3$") then
                table.insert(tunes, file)
            end
        end
        p:close()
    end
    
    if #tunes == 0 then
        table.insert(tunes, "Cars And Coffee Soundtrack.mp3")
    end
    
    return tunes
end

local function getPlayerSummary(src)
    local document = assert(SKSaves.getDocument(src), 'streetkings: missing active worldhub document')
    local mechanic = type(document.mechanic) == 'table' and document.mechanic or {}
    local workshop = type(document.workshop) == 'table' and document.workshop or {}
    local fuel = type(document.fuel) == 'table' and document.fuel or {}
    local stats = type(document.stats) == 'table' and document.stats or {}
    local vehicleStats = type(document.vehicleStats) == 'table' and document.vehicleStats or {}

    return {
        id = src,
        name = GetPlayerName(src),
        cash = document.economy.cash,
        level = document.progression.level,
        xp = document.progression.playerXp,
        mechanicLevel = mechanic.level or 1,
        mechanicXp = mechanic.xp or 0,
        hasHouse = SKWorkshop.hasHouse(src),
        workshopUnlocked = workshop.unlocked == true,
        fuelLevel = fuel.currentFuel or 0,
        fuelMax = fuel.maxFuel or SKFuel.getDefaultCapacity(),
        totalDrivingMinutes = vehicleStats.totalDrivingMinutes or 0,
        favoriteCars = vehicleStats.favoriteCars or {},
    }
end

lib.callback.register('phone:mechanic:getState', function(source)
    local document = assert(SKSaves.getDocument(source), 'streetkings: missing active mechanic document')
    local mechanic = type(document.mechanic) == 'table' and document.mechanic or {}
    local workshop = type(document.workshop) == 'table' and document.workshop or {}

    return {
        ok = true,
        hasHouse = SKWorkshop.hasHouse(source),
        unlocked = workshop.unlocked == true,
        level = mechanic.level or 1,
        xp = mechanic.xp or 0,
        perkPoints = mechanic.perkPoints or 0,
        fuelCurrent = (document.fuel and document.fuel.currentFuel) or 0,
        fuelMax = (document.fuel and document.fuel.maxFuel) or SKFuel.getDefaultCapacity(),
        fuelType = (document.fuel and document.fuel.fuelType) or SKFuel.DEFAULT_FUEL_TYPE,
    }
end)

lib.callback.register('phone:mechanic:toggleWorkshop', function(source)
    local document = assert(SKSaves.getDocument(source), 'streetkings: missing active mechanic document')
    if not SKWorkshop.hasHouse(source) then
        return { ok = false, reason = 'house_required' }
    end

    document.workshop = document.workshop or {}
    document.workshop.hasHouse = true
    document.workshop.unlocked = not (document.workshop.unlocked == true)

    if not SKSaves.persist(source) then
        return { ok = false, reason = 'save_failed' }
    end

    return {
        ok = true,
        unlocked = document.workshop.unlocked == true,
    }
end)

lib.callback.register('phone:worldhub:getState', function(source)
    if not isAdmin(source) then
        return { ok = false, reason = 'not_authorized' }
    end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        players[#players + 1] = getPlayerSummary(tonumber(playerId))
    end

    local adminTop = {
        fuelPrice = SKFuel.getPrice(),
        worldTime = (SKEnvironment and SKEnvironment.getTime) and SKEnvironment.getTime() or 12,
        weather = (SKEnvironment and SKEnvironment.getWeather) and SKEnvironment.getWeather() or 'CLEAR',
        globalPrice = SKFuelSettings.globalPrice,
        nearestStationOverrideEnabled = SKFuelSettings.nearestStationOverrideEnabled,
        nearestStationOverridePrice = SKFuelSettings.nearestStationOverridePrice,
        activeTune = SKActiveTune,
        tunes = scanTunesFolder(),
    }

    return {
        ok = true,
        admin = true,
        players = players,
        top = adminTop,
    }
end)

lib.callback.register('phone:worldhub:setFuelSettings', function(source, data)
    if not isAdmin(source) then return { ok = false, reason = 'not_authorized' } end
    
    SKFuelSettings.globalPrice = tonumber(data.globalPrice) or SKFuelSettings.globalPrice
    SKFuelSettings.nearestStationOverrideEnabled = data.nearestStationOverrideEnabled == true
    SKFuelSettings.nearestStationOverridePrice = tonumber(data.nearestStationOverridePrice) or SKFuelSettings.nearestStationOverridePrice

    TriggerClientEvent('streetkings:fuel:syncPrice', -1, SKFuel.getPrice())
    return { ok = true, settings = SKFuelSettings }
end)

lib.callback.register('phone:worldhub:setLoadscreenTune', function(source, tuneName)
    if not isAdmin(source) then return { ok = false, reason = 'not_authorized' } end
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local srcPath
    if tuneName == "Cars And Coffee Soundtrack.mp3" then
        srcPath = (resourcePath .. "/html/assets/loading/Cars And Coffee Soundtrack.mp3"):gsub("/", "\\")
    else
        srcPath = (resourcePath .. "/Tunes/" .. tuneName):gsub("/", "\\")
    end
    local destPath = (resourcePath .. "/html/assets/loading/active_music.mp3"):gsub("/", "\\")
    
    local ok = os.execute('copy /Y "' .. srcPath .. '" "' .. destPath .. '"')
    if ok then
        SKActiveTune = tuneName
        return { ok = true, activeTune = tuneName }
    else
        return { ok = false, reason = 'copy_failed' }
    end
end)

lib.callback.register('phone:worldhub:getPlayerGarage', function(source, targetId)
    if not isAdmin(source) then return { ok = false, reason = 'not_authorized' } end
    local target = tonumber(targetId)
    if not target or not SKSaves.hasActiveSave(target) then
        return { ok = false, reason = 'invalid_target' }
    end
    local doc = SKSaves.getDocument(target)
    if not doc or not doc.garage then
        return { ok = true, vehicles = {} }
    end
    return { ok = true, vehicles = doc.garage.vehicles or {} }
end)

lib.callback.register('phone:worldhub:setPlayerCash', function(source, targetId, amount)
    if not isAdmin(source) then
        return { ok = false, reason = 'not_authorized' }
    end

    local target = tonumber(targetId)
    if not target or not SKSaves.hasActiveSave(target) then
        return { ok = false, reason = 'invalid_target' }
    end

    local value = tonumber(amount) or 0
    SKSaves.write(target, 'economy.cash', value)
    TriggerClientEvent('streetkings:worldhub:client:syncState', target, value, nil, nil)
    return { ok = true, cash = value, targetId = target }
end)

lib.callback.register('phone:worldhub:setPlayerXp', function(source, targetId, xp)
    if not isAdmin(source) then return { ok = false, reason = 'not_authorized' } end
    local target = tonumber(targetId)
    if not target or not SKSaves.hasActiveSave(target) then
        return { ok = false, reason = 'invalid_target' }
    end

    local value = tonumber(xp) or 0
    SKSaves.write(target, 'progression.playerXp', value)
    local calculatedLevel = SKProgression.getPlayerLevelFromXp(value)
    SKSaves.write(target, 'progression.level', calculatedLevel)
    TriggerClientEvent('streetkings:worldhub:client:syncState', target, nil, calculatedLevel, value)
    return { ok = true, xp = value, targetId = target }
end)

lib.callback.register('phone:worldhub:givePlayerCash', function(source, targetId, amount)
    if not isAdmin(source) then
        return { ok = false, reason = 'not_authorized' }
    end

    local target = tonumber(targetId)
    if not target or not SKSaves.hasActiveSave(target) then
        return { ok = false, reason = 'invalid_target' }
    end

    local value = tonumber(amount) or 0
    local document = SKSaves.getDocument(target)
    local currentCash = document.economy.cash or 0
    local newCash = currentCash + value

    SKSaves.write(target, 'economy.cash', newCash)
    SKStats.increment(target, 'totalCashEarned', value)
    TriggerClientEvent('streetkings:worldhub:client:syncState', target, newCash, nil, nil)
    return { ok = true, cash = newCash, targetId = target }
end)

lib.callback.register('phone:worldhub:setPlayerLevel', function(source, targetId, level)
    if not isAdmin(source) then
        return { ok = false, reason = 'not_authorized' }
    end

    local target = tonumber(targetId)
    local value = tonumber(level) or 1
    if not target or not SKSaves.hasActiveSave(target) then
        return { ok = false, reason = 'invalid_target' }
    end

    local document = SKSaves.getDocument(target)
    if document then
        local progression = document.progression or {}
        progression.level = value
        progression.playerXp = SKProgression.PLAYER_LEVEL_THRESHOLDS[value] or 0
        SKSaves.write(target, 'progression', progression)
    else
        SKSaves.write(target, 'progression.level', value)
    end
    TriggerClientEvent('streetkings:worldhub:client:syncState', target, nil, value, nil)
    return { ok = true, level = value, targetId = target }
end)

lib.callback.register('phone:worldhub:banPlayer', function(source, targetId)
    if not isAdmin(source) then
        return { ok = false, reason = 'not_authorized' }
    end

    local target = tonumber(targetId)
    if not target then
        return { ok = false, reason = 'invalid_target' }
    end

    DropPlayer(target, 'You were banned by an administrator.')
    return { ok = true, targetId = target }
end)

RegisterNetEvent('streetkings:worldhub:requestSpectate', function(targetId)
    local src = source
    if not isAdmin(src) then return end
    
    local targetPed = GetPlayerPed(targetId)
    if DoesEntityExist(targetPed) then
        local coords = GetEntityCoords(targetPed)
        TriggerClientEvent('streetkings:worldhub:startSpectate', src, targetId, coords)
    else
        TriggerClientEvent('streetkings:worldhub:startSpectate', src, targetId, vector3(0,0,0))
    end
end)

CreateThread(function()
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local tunesFolder = resourcePath .. "/Tunes"
    os.execute('mkdir "' .. tunesFolder:gsub("/", "\\") .. '" 2>nul')

    local activeMusicPath = resourcePath .. "/html/assets/loading/active_music.mp3"
    local f = io.open(activeMusicPath, "rb")
    if f then
        f:close()
    else
        local defaultMusic = resourcePath .. "/html/assets/loading/Cars And Coffee Soundtrack.mp3"
        os.execute('copy /Y "' .. defaultMusic:gsub("/", "\\") .. '" "' .. activeMusicPath:gsub("/", "\\") .. '"')
    end
end)
