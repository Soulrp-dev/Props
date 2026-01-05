Database = {
    Cache = {},
    CacheTimeout = Config.Collections.CacheTimeout or 60000
}

function Database.GetCharacterName(user_id)
    if not user_id then return nil end

    local cached = Database.Cache['name_' .. user_id]
    if cached and (os.time() - cached.time) < (Database.CacheTimeout / 1000) then
        return cached.value
    end

    local row = MySQL.single.await([[
        SELECT name, name2
        FROM characters
        WHERE id = ? AND (deleted = 0 OR deleted IS NULL)
        LIMIT 1
    ]], { user_id })
    
    if not row then return nil end
    
    local first = Utils.Trim(row.name or "")
    local last = Utils.Trim(row.name2 or "")
    
    local fullName = nil
    if first ~= "" and last ~= "" then
        fullName = first .. " " .. last
    elseif first ~= "" then
        fullName = first
    elseif last ~= "" then
        fullName = last
    end

    if fullName then
        Database.Cache['name_' .. user_id] = {
            value = fullName,
            time = os.time()
        }
    end
    
    return fullName
end

function Database.GetCharacterNameFromSource(source)
    local user_id = GetUserId(source)
    if not user_id then 
        return 'ID ' .. tostring(source) 
    end
    
    return Database.GetCharacterName(user_id) or ('ID ' .. tostring(source))
end

function Database.GetCharacterNames(user_ids)
    if type(user_ids) ~= 'table' or #user_ids == 0 then
        return {}
    end
    
    local names = {}
    local toFetch = {}

    for _, user_id in ipairs(user_ids) do
        local cached = Database.Cache['name_' .. user_id]
        if cached and (os.time() - cached.time) < (Database.CacheTimeout / 1000) then
            names[tostring(user_id)] = cached.value
        else
            table.insert(toFetch, user_id)
        end
    end

    if #toFetch > 0 then
        local placeholders = table.concat(
            table.pack(string.rep('?', #toFetch):gsub('.', '%1,')):sub(1, -2), ','
        )
        
        local rows = MySQL.query.await(
            ('SELECT id, name, name2 FROM characters WHERE id IN (%s) AND (deleted = 0 OR deleted IS NULL)'):format(placeholders),
            toFetch
        ) or {}
        
        for _, row in ipairs(rows) do
            local first = Utils.Trim(row.name or "")
            local last = Utils.Trim(row.name2 or "")
            local fullName = nil
            
            if first ~= "" and last ~= "" then
                fullName = first .. " " .. last
            elseif first ~= "" then
                fullName = first
            elseif last ~= "" then
                fullName = last
            end
            
            if fullName then
                names[tostring(row.id)] = fullName
                Database.Cache['name_' .. row.id] = {
                    value = fullName,
                    time = os.time()
                }
            end
        end
    end
    
    return names
end

function Database.GetUserCollections(user_id)
    if not user_id then return {} end
    
    local rows = MySQL.query.await([[
        SELECT item_key, qty
        FROM dnc_collections_ownership
        WHERE user_id = ?
    ]], { user_id }) or {}
    
    return rows
end

function Database.GetUserFeatured(user_id)
    if not user_id then return nil end
    
    return MySQL.scalar.await([[
        SELECT item_key
        FROM dnc_collections_badge
        WHERE user_id = ?
        LIMIT 1
    ]], { user_id })
end

function Database.SetUserFeatured(user_id, item_key)
    if not user_id then return false end
    
    if not item_key or item_key == '' then
        MySQL.prepare.await([[
            DELETE FROM dnc_collections_badge
            WHERE user_id = ?
        ]], { user_id })
        return true
    end
    
    MySQL.prepare.await([[
        INSERT INTO dnc_collections_badge (user_id, item_key)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE item_key = VALUES(item_key)
    ]], { user_id, item_key })
    
    return true
end

function Database.GetItemQuantity(user_id, item_key)
    if not user_id or not item_key then return 0 end
    
    local qty = MySQL.scalar.await([[
        SELECT qty
        FROM dnc_collections_ownership
        WHERE user_id = ? AND item_key = ?
        LIMIT 1
    ]], { user_id, item_key })
    
    return tonumber(qty or 0) or 0
end

function Database.AdjustItem(user_id, item_key, delta)
    if not user_id or not item_key then return false end
    
    delta = tonumber(delta or 0) or 0
    if delta == 0 then return true end
    
    if delta > 0 then
        MySQL.prepare.await([[
            INSERT INTO dnc_collections_ownership (user_id, item_key, qty)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE qty = qty + VALUES(qty)
        ]], { user_id, item_key, delta })
        
    else
        local current = Database.GetItemQuantity(user_id, item_key)
        if current < math.abs(delta) then
            return false
        end
        
        MySQL.prepare.await([[
            UPDATE dnc_collections_ownership
            SET qty = qty + ?
            WHERE user_id = ? AND item_key = ?
        ]], { delta, user_id, item_key })
    end
    
    return true
end

function Database.HasEnough(user_id, item_key, qty)
    local current = Database.GetItemQuantity(user_id, item_key)
    return current >= qty
end

function Database.BatchAdjustItems(user_id, items)
    if not user_id or type(items) ~= 'table' then return false end

    for _, item in ipairs(items) do
        if item.qty < 0 then
            if not Database.HasEnough(user_id, item.item_key, math.abs(item.qty)) then
                return false, 'insufficient_qty'
            end
        end
    end

    for _, item in ipairs(items) do
        Database.AdjustItem(user_id, item.item_key, item.qty)
    end
    
    return true
end

function Database.ClearCache()
    Database.Cache = {}
end

function Database.ClearUserCache(user_id)
    if not user_id then return end
    Database.Cache['name_' .. user_id] = nil
end

CreateThread(function()
    while true do
        Wait(Database.CacheTimeout)
        
        local now = os.time()
        local timeout = Database.CacheTimeout / 1000
        
        for key, cached in pairs(Database.Cache) do
            if (now - cached.time) > timeout then
                Database.Cache[key] = nil
            end
        end
    end
end)