Collections = {}

lib.callback.register('dnc:collections:getData', function(source)
    local user_id = GetUserId(source)
    
    if not user_id then
        return {
            items = {},
            featured = nil,
            catalog = CollectionsCatalog or {}
        }
    end
    
    local items = Database.GetUserCollections(user_id)
    local featured = Database.GetUserFeatured(user_id)
    
    return {
        items = items,
        featured = featured,
        catalog = CollectionsCatalog or {}
    }
end)

lib.callback.register('dnc:collections:getFeaturedForPlayer', function(source)
    local user_id = GetUserId(source)
    
    if not user_id then
        return {}
    end
    
    local key = Database.GetUserFeatured(user_id)
    local icon = nil
    
    if key and CollectionsCatalog and CollectionsCatalog[key] then
        icon = CollectionsCatalog[key].icon
    end
    
    return {
        key = key,
        icon = icon
    }
end)

lib.callback.register('dnc:players:getNames', function(source, ids)
    if type(ids) ~= 'table' then
        return {}
    end
    
    local user_ids = {}
    
    for _, sid in ipairs(ids) do
        sid = tonumber(sid)
        if sid and IsOnline(sid) then
            local user_id = GetUserId(sid)
            if user_id then
                user_ids[sid] = user_id
            end
        end
    end
    
    local names = {}
    
    for sid, user_id in pairs(user_ids) do
        local name = Database.GetCharacterName(user_id)
        if name and name ~= "" then
            names[tostring(sid)] = name
        end
    end
    
    return names
end)

RegisterNetEvent('dnc:collections:setFeatured', function(itemKey)
    local source = source
    local user_id = GetUserId(source)
    
    if not user_id then return end

    if itemKey and itemKey ~= '' then
        if not CollectionsCatalog or not CollectionsCatalog[itemKey] then
            return
        end
        
        local def = CollectionsCatalog[itemKey]
        if def.type ~= 'badge' then
            return
        end

        if Database.GetItemQuantity(user_id, itemKey) <= 0 then
            return
        end
    end

    Database.SetUserFeatured(user_id, itemKey)

    local icon = nil
    if itemKey and CollectionsCatalog and CollectionsCatalog[itemKey] then
        icon = CollectionsCatalog[itemKey].icon
    end
    
    TriggerClientEvent('dnc:collections:featuredChanged', source, itemKey, icon)
end)

function Collections.GiveItem(user_id, item_key, qty)
    user_id = tonumber(user_id)
    qty = Utils.ValidateNumber(qty, 1, nil, 1)
    
    if not user_id or not item_key or item_key == '' then
        return false, 'invalid_args'
    end
    
    if not CollectionsCatalog or not CollectionsCatalog[item_key] then
        return false, 'unknown_item'
    end
    
    local success = Database.AdjustItem(user_id, item_key, qty)
    
    if success then
        local source = GetSource(user_id)
        if source and IsOnline(source) then
            TriggerClientEvent('dnc:collections:itemAdded', source, item_key, qty)
            TriggerClientEvent('dnc:collections:refresh', source)
        end
        
        Utils.Debug(('Item given: user=%d item=%s qty=%d'):format(user_id, item_key, qty))
    end
    
    return success
end

function Collections.RemoveItem(user_id, item_key, qty)
    user_id = tonumber(user_id)
    qty = Utils.ValidateNumber(qty, 1, nil, 1)
    
    if not user_id or not item_key or item_key == '' then
        return false, 'invalid_args'
    end
    
    local success = Database.AdjustItem(user_id, item_key, -qty)
    
    if success then
        local source = GetSource(user_id)
        if source and IsOnline(source) then
            TriggerClientEvent('dnc:collections:refresh', source)
        end
        
        Utils.Debug(('Item removed: user=%d item=%s qty=%d'):format(user_id, item_key, qty))
    end
    
    return success
end

function Collections.GetItemQuantity(user_id, item_key)
    return Database.GetItemQuantity(user_id, item_key)
end

function Collections.HasItem(user_id, item_key, qty)
    qty = qty or 1
    return Database.HasEnough(user_id, item_key, qty)
end

exports('GiveByUserId', function(user_id, item_key, qty)
    return Collections.GiveItem(user_id, item_key, qty)
end)

exports('GiveToSource', function(source, item_key, qty)
    local user_id = GetUserId(source)
    if not user_id then
        return false, 'no_user_id'
    end
    return Collections.GiveItem(user_id, item_key, qty)
end)

exports('GiveCollectionItem', function(user_id, item_key, qty)
    return Collections.GiveItem(user_id, item_key, qty)
end)

exports('RemoveCollectionItem', function(user_id, item_key, qty)
    return Collections.RemoveItem(user_id, item_key, qty)
end)

exports('GetItemQuantity', function(user_id, item_key)
    return Collections.GetItemQuantity(user_id, item_key)
end)

exports('HasItem', function(user_id, item_key, qty)
    return Collections.HasItem(user_id, item_key, qty)
end)

RegisterCommand('convertcatalog', function()
    local new = {}
    for key, item in pairs(CollectionsCatalog) do
        new[key] = {
            name = item.name,
            desc = item.desc or '',
            icon = item.icon,
            type = item.type or 'collection',
            rarity = item.rarity or 'Comum',
            category = item.category or 'Outros',
            prop = type(item.prop) == 'string' and {
                model = item.prop,
                bone = 28422,
                pos = vector3(0,0,0),
                rot = vector3(0,0,0)
            } or item.prop
        }
    end
    print(json.encode(new, {indent = true}))
end)

function Collections.IsItemTradeable(item_key)
    if not CollectionsCatalog or not CollectionsCatalog[item_key] then
        return false
    end
    
    local def = CollectionsCatalog[item_key]
    return def.tradeable ~= false
end

exports('IsItemTradeable', function(item_key)
    return Collections.IsItemTradeable(item_key)
end)

exports('GetCatalog', function()
    return CollectionsCatalog or {}
end)

exports('GetCollectionsModule', function()
    return Collections
end)

exports('GiveItem', function(passport, item_key, qty)
    return Collections.GiveItem(passport, item_key, qty)
end)

exports('ItemExists', function(item_key)
    if not CollectionsCatalog then return false end
    return CollectionsCatalog[item_key] ~= nil
end)

exports('GetItemData', function(item_key)
    if not CollectionsCatalog then return nil end
    return CollectionsCatalog[item_key]
end)

CreateThread(function()
    Wait(1000)
    print("^2[DN_COLLECTIONS] Exports registrados com sucesso!^0")
    if CollectionsCatalog then
        local count = 0
        for _ in pairs(CollectionsCatalog) do count = count + 1 end
        print("^2[DN_COLLECTIONS] Catálogo disponível com "..count.." itens^0")
    end
end)