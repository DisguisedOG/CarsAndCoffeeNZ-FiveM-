lib.callback.register('phone:supercheap:getState', function(source)
    local document = assert(SKSaves.getDocument(source), 'streetkings: missing active save document for supercheap')
    
    local hasHouse = SKWorkshop.hasHouse(source)
    local balance = document.economy.cash or 0
    
    local ownedTools = {}
    if document.workshop and document.workshop.tools then
        for toolId, val in pairs(document.workshop.tools) do
            if val == true then
                ownedTools[toolId] = true
            end
        end
    end
    
    local consumables = {}
    if document.workshop and document.workshop.consumables then
        consumables = document.workshop.consumables
    end

    local placedTools = {}
    if document.workshop and document.workshop.placedTools then
        placedTools = document.workshop.placedTools
    end
    
    return {
        ok = true,
        catalog = SKSupercheap.CATALOG,
        ownedTools = ownedTools,
        consumables = consumables,
        placedTools = placedTools,
        balance = balance,
        hasHouse = hasHouse
    }
end)

lib.callback.register('phone:supercheap:buyItem', function(source, category, itemId)
    local document = assert(SKSaves.getDocument(source), 'streetkings: missing active save document for supercheap')
    
    local catItems = SKSupercheap.CATALOG[category]
    if not catItems then
        return { ok = false, reason = 'invalid_category' }
    end
    
    local matchedItem = nil
    for _, item in ipairs(catItems) do
        if item.id == itemId then
            matchedItem = item
            break
        end
    end
    
    if not matchedItem then
        return { ok = false, reason = 'item_not_found' }
    end
    
    local price = matchedItem.price
    local mechanic = document.mechanic or {}
    local perks = mechanic.perks or {}
    if perks.cashedUp == true then
        price = math.floor(price * 0.85)
    end

    local currentCash = document.economy.cash or 0
    if currentCash < price then
        return { ok = false, reason = 'insufficient_funds' }
    end
    
    document.workshop = document.workshop or {}
    
    if matchedItem.type == 'tool' then
        if not SKWorkshop.hasHouse(source) then
            return { ok = false, reason = 'house_required' }
        end
        document.workshop.tools = document.workshop.tools or {}
        if document.workshop.tools[itemId] == true then
            return { ok = false, reason = 'already_owned' }
        end
        document.workshop.tools[itemId] = true
    else
        document.workshop.consumables = document.workshop.consumables or {}
        document.workshop.consumables[itemId] = (document.workshop.consumables[itemId] or 0) + 1
    end
    
    document.economy.cash = currentCash - price
    
    if not SKSaves.persist(source) then
        return { ok = false, reason = 'save_failed' }
    end
    
    return { ok = true }
end)
