local function Notify(source, type, message)
    if source == 0 then
        print(('[DN_COLLECTIONS] %s: %s'):format(type, message))
    else
        TriggerClientEvent('Notify', source, type, message)
    end
end

RegisterCommand('givecol', function(source, args)
    if source ~= 0 then
        local user_id = GetUserId(source)
        
        if not user_id then
            Notify(source, 'negado', 'Erro ao verificar credenciais')
            return
        end
        
        if not HasPermission(user_id, 'Admin') then
            Notify(source, 'negado', 'Sem permissão')
            return
        end
    end

    if #args < 2 then
        Notify(source, 'importante', 'Uso: /givecol <user_id> <item_key> [qty]')
        return
    end
    
    local target_id = Utils.ValidateNumber(args[1], 1, nil, 0)
    local item_key = Utils.ValidateString(args[2], 1, 100, '')
    local qty = Utils.ValidateNumber(args[3], 1, nil, 1)
    
    if target_id <= 0 then
        Notify(source, 'negado', 'ID inválido')
        return
    end
    
    if item_key == '' then
        Notify(source, 'negado', 'Item inválido')
        return
    end

    if not CollectionsCatalog or not CollectionsCatalog[item_key] then
        Notify(source, 'negado', ('Item "%s" não existe no catálogo'):format(item_key))

        if CollectionsCatalog then
            local items = {}
            local count = 0
            for k in pairs(CollectionsCatalog) do
                count = count + 1
                if count <= 10 then
                    table.insert(items, k)
                else
                    break
                end
            end
            if #items > 0 then
                Notify(source, 'importante', 'Exemplos: ' .. table.concat(items, ', '))
            end
        end
        return
    end

    local success, err = Collections.GiveItem(target_id, item_key, qty)
    
    if success then
        local itemName = CollectionsCatalog[item_key].name or item_key
        Notify(source, 'sucesso', ('%s x%d entregue para ID %d'):format(itemName, qty, target_id))

        local target_src = GetSource(target_id)
        if target_src and IsOnline(target_src) then
            Notify(target_src, 'sucesso', ('Você recebeu %s x%d'):format(itemName, qty))
        end
    else
        Notify(source, 'negado', 'Erro: ' .. (err or 'desconhecido'))
    end
end, false)

RegisterCommand('removecol', function(source, args)
    if source ~= 0 then
        local user_id = GetUserId(source)
        if not user_id or not HasPermission(user_id, 'Admin') then
            Notify(source, 'negado', 'Sem permissão')
            return
        end
    end
    
    if #args < 2 then
        Notify(source, 'importante', 'Uso: /removecol <user_id> <item_key> [qty]')
        return
    end
    
    local target_id = Utils.ValidateNumber(args[1], 1, nil, 0)
    local item_key = Utils.ValidateString(args[2], 1, 100, '')
    local qty = Utils.ValidateNumber(args[3], 1, nil, 1)
    
    if target_id <= 0 or item_key == '' then
        Notify(source, 'negado', 'Argumentos inválidos')
        return
    end
    
    local success, err = Collections.RemoveItem(target_id, item_key, qty)
    
    if success then
        Notify(source, 'sucesso', ('%s x%d removido de ID %d'):format(item_key, qty, target_id))
    else
        Notify(source, 'negado', 'Erro: ' .. (err or 'quantidade insuficiente'))
    end
end, false)

RegisterCommand('listcol', function(source, args)
    if source ~= 0 then
        local user_id = GetUserId(source)
        if not user_id or not HasPermission(user_id, 'Admin') then
            Notify(source, 'negado', 'Sem permissão')
            return
        end
    end
    
    local target_id = Utils.ValidateNumber(args[1], 1, nil, source == 0 and 0 or GetUserId(source))
    
    if target_id <= 0 then
        Notify(source, 'importante', 'Uso: /listcol [user_id]')
        return
    end
    
    local items = Database.GetUserCollections(target_id)
    
    if #items == 0 then
        Notify(source, 'importante', ('ID %d não possui itens'):format(target_id))
        return
    end
    
    Notify(source, 'importante', ('ID %d possui %d itens:'):format(target_id, #items))
    
    for i, item in ipairs(items) do
        if i <= 20 then
            local name = CollectionsCatalog and CollectionsCatalog[item.item_key] and 
                        CollectionsCatalog[item.item_key].name or item.item_key
            Notify(source, 'importante', ('  %s x%d'):format(name, item.qty))
        end
    end
    
    if #items > 20 then
        Notify(source, 'importante', ('  ... e mais %d itens'):format(#items - 20))
    end
end, false)

RegisterCommand('checkcol', function(source, args)
    if source ~= 0 then
        local user_id = GetUserId(source)
        if not user_id or not HasPermission(user_id, 'Admin') then
            Notify(source, 'negado', 'Sem permissão')
            return
        end
    end
    
    if #args < 2 then
        Notify(source, 'importante', 'Uso: /checkcol <user_id> <item_key>')
        return
    end
    
    local target_id = Utils.ValidateNumber(args[1], 1, nil, 0)
    local item_key = Utils.ValidateString(args[2], 1, 100, '')
    
    if target_id <= 0 or item_key == '' then
        Notify(source, 'negado', 'Argumentos inválidos')
        return
    end
    
    local qty = Database.GetItemQuantity(target_id, item_key)
    local name = CollectionsCatalog and CollectionsCatalog[item_key] and 
                CollectionsCatalog[item_key].name or item_key
    
    Notify(source, 'importante', ('ID %d possui %d de "%s"'):format(target_id, qty, name))
end, false)

RegisterCommand('colstats', function(source)
    if source ~= 0 then
        local user_id = GetUserId(source)
        if not user_id or not HasPermission(user_id, 'Admin') then
            Notify(source, 'negado', 'Sem permissão')
            return
        end
    end
    
    local catalog_count = Utils.TableCount(CollectionsCatalog or {})
    local trades_count = Utils.TableCount(TradeManager.ActiveTrades)
    
    -- Estatísticas do banco
    local total_items = MySQL.scalar.await('SELECT COUNT(*) FROM dnc_collections_ownership', {}) or 0
    local total_users = MySQL.scalar.await('SELECT COUNT(DISTINCT user_id) FROM dnc_collections_ownership', {}) or 0
    local total_trades = MySQL.scalar.await('SELECT COUNT(*) FROM dnc_collections_trades', {}) or 0
    
    Notify(source, 'importante', '========== DN COLLECTIONS STATS ==========')
    Notify(source, 'importante', ('Catálogo: %d itens'):format(catalog_count))
    Notify(source, 'importante', ('Trades ativos: %d'):format(trades_count))
    Notify(source, 'importante', ('Total de coleções: %d'):format(total_items))
    Notify(source, 'importante', ('Jogadores com itens: %d'):format(total_users))
    Notify(source, 'importante', ('Trades completos: %d'):format(total_trades))
    Notify(source, 'importante', ('Uptime: %d minutos'):format((os.time() - ServerState.StartTime) / 60))
    Notify(source, 'importante', '=========================================')
end, false)

RegisterCommand('clearcache_col', function(source)
    if source ~= 0 then
        local user_id = GetUserId(source)
        if not user_id or not HasPermission(user_id, 'Admin') then
            Notify(source, 'negado', 'Sem permissão')
            return
        end
    end
    
    Database.ClearCache()
    Notify(source, 'sucesso', 'Cache limpo')
end, false)