TradeManager = {
    ActiveTrades = {},
    NextId = 1
}

local function ValidateOffer(offer)
    if type(offer) ~= 'table' then return {} end
    
    local aggregated = {}
    
    for _, item in ipairs(offer) do
        local key = Utils.ValidateString(item.item_key, 1, 100, '')
        local qty = Utils.ValidateNumber(item.qty, 1, nil, 0)
        
        if key ~= '' and qty > 0 then
            aggregated[key] = (aggregated[key] or 0) + qty
        end
    end
    
    local clean = {}
    for key, qty in pairs(aggregated) do
        if CollectionsCatalog and CollectionsCatalog[key] then
            local def = CollectionsCatalog[key]
            if def.type == 'collection' then
                local isTradeable = def.tradeable ~= false
                
                if isTradeable then
                    table.insert(clean, {
                        item_key = key,
                        qty = qty
                    })
                else
                    Utils.Debug(('Item %s não é trocável, removendo da oferta'):format(key))
                end
            end
        end
    end
    
    return clean
end

local function CheckProximity(sourceA, sourceB)
    if not Config.Trade.RequireProximity then
        return true
    end
    
    local pedA = GetPlayerPed(sourceA)
    local pedB = GetPlayerPed(sourceB)
    
    if pedA == 0 or pedB == 0 then
        return false
    end
    
    local posA = GetEntityCoords(pedA)
    local posB = GetEntityCoords(pedB)
    local dist = #(posA - posB)
    
    return dist <= (Config.Trade.MaxDistance or 25.0)
end

function TradeManager.Create(initiatorSrc, targetSrc)
    local idA = GetUserId(initiatorSrc)
    local idB = GetUserId(targetSrc)
    
    if not idA or not idB or idA == idB then
        return nil
    end

    for _, trade in pairs(TradeManager.ActiveTrades) do
        if trade.state ~= 'accepted' and trade.state ~= 'cancelled' then
            if (trade.userA == idA and trade.userB == idB) or
               (trade.userA == idB and trade.userB == idA) then
                trade.sourceA = initiatorSrc
                trade.sourceB = targetSrc
                trade.state = 'request'
                trade.timestamp = os.time()
                return trade
            end
        end
    end

    local tradeId = TradeManager.NextId
    TradeManager.NextId = TradeManager.NextId + 1
    
    local trade = {
        id = tradeId,
        userA = idA,
        userB = idB,
        sourceA = initiatorSrc,
        sourceB = targetSrc,
        state = 'request',
        offerA = {},
        offerB = {},
        readyA = false,
        readyB = false,
        timestamp = os.time()
    }
    
    TradeManager.ActiveTrades[tradeId] = trade

    MySQL.insert.await([[
        INSERT INTO dnc_collections_trades (initiator_id, target_id, state)
        VALUES (?, ?, ?)
    ]], { idA, idB, 'pending' })
    
    Utils.Debug(('Trade created: id=%d A=%d B=%d'):format(tradeId, idA, idB))
    
    return trade
end

function TradeManager.GetTrade(tradeId)
    return TradeManager.ActiveTrades[tradeId]
end

function TradeManager.AcceptRequest(tradeId)
    local trade = TradeManager.GetTrade(tradeId)
    if not trade or trade.state ~= 'request' then
        return false
    end

    if not CheckProximity(trade.sourceA, trade.sourceB) then
        return false, 'too_far'
    end
    
    trade.state = 'pending'

    TriggerClientEvent('dnc:trade:opened', trade.sourceA, tradeId, 'a')
    TriggerClientEvent('dnc:trade:opened', trade.sourceB, tradeId, 'b')
    
    TradeManager.Sync(tradeId)
    
    Utils.Debug(('Trade accepted: id=%d'):format(tradeId))
    
    return true
end

function TradeManager.UpdateOffer(tradeId, side, offer, userId)
    local trade = TradeManager.GetTrade(tradeId)
    if not trade or trade.state ~= 'pending' then
        return false
    end

    if (side == 'a' and userId ~= trade.userA) or
       (side == 'b' and userId ~= trade.userB) then
        return false
    end

    local cleanOffer = ValidateOffer(offer)

    local validOffer = {}
    for _, item in ipairs(cleanOffer) do
        if Database.HasEnough(userId, item.item_key, item.qty) then
            table.insert(validOffer, item)
        else
            Utils.Debug(('Jogador %d não tem quantidade suficiente de %s'):format(userId, item.item_key))
        end
    end

    if side == 'a' then
        trade.offerA = validOffer
        trade.readyA = false
    else
        trade.offerB = validOffer
        trade.readyB = false
    end
    
    TradeManager.Sync(tradeId)
    
    return true
end

function TradeManager.SetReady(tradeId, side, ready, userId)
    local trade = TradeManager.GetTrade(tradeId)
    if not trade or trade.state ~= 'pending' then
        return false
    end

    if (side == 'a' and userId ~= trade.userA) or
       (side == 'b' and userId ~= trade.userB) then
        return false
    end

    if side == 'a' then
        trade.readyA = ready and true or false
    else
        trade.readyB = ready and true or false
    end
    
    TradeManager.Sync(tradeId)

    if trade.readyA and trade.readyB then
        return TradeManager.Execute(tradeId)
    end
    
    return true
end

function TradeManager.Execute(tradeId)
    local trade = TradeManager.GetTrade(tradeId)
    if not trade then return false end

    if not IsOnline(trade.sourceA) or not IsOnline(trade.sourceB) then
        TradeManager.Cancel(tradeId, 'player_offline')
        return false
    end

    if not CheckProximity(trade.sourceA, trade.sourceB) then
        trade.readyA = false
        trade.readyB = false
        TriggerClientEvent('dnc:trade:error', trade.sourceA, 'too_far')
        TriggerClientEvent('dnc:trade:error', trade.sourceB, 'too_far')
        TradeManager.Sync(tradeId)
        return false
    end

    for _, item in ipairs(trade.offerA) do
        if not Database.HasEnough(trade.userA, item.item_key, item.qty) then
            trade.readyA = false
            trade.readyB = false
            TriggerClientEvent('dnc:trade:error', trade.sourceA, 'insufficient_qty')
            TriggerClientEvent('dnc:trade:error', trade.sourceB, 'peer_error')
            TradeManager.Sync(tradeId)
            return false
        end
        
        local def = CollectionsCatalog[item.item_key]
        if def and def.tradeable == false then
            trade.readyA = false
            trade.readyB = false
            TriggerClientEvent('dnc:trade:error', trade.sourceA, 'item_not_tradeable')
            TriggerClientEvent('dnc:trade:error', trade.sourceB, 'peer_error')
            TradeManager.Sync(tradeId)
            return false
        end
    end
    
    for _, item in ipairs(trade.offerB) do
        if not Database.HasEnough(trade.userB, item.item_key, item.qty) then
            trade.readyA = false
            trade.readyB = false
            TriggerClientEvent('dnc:trade:error', trade.sourceB, 'insufficient_qty')
            TriggerClientEvent('dnc:trade:error', trade.sourceA, 'peer_error')
            TradeManager.Sync(tradeId)
            return false
        end
        
        local def = CollectionsCatalog[item.item_key]
        if def and def.tradeable == false then
            trade.readyA = false
            trade.readyB = false
            TriggerClientEvent('dnc:trade:error', trade.sourceB, 'item_not_tradeable')
            TriggerClientEvent('dnc:trade:error', trade.sourceA, 'peer_error')
            TradeManager.Sync(tradeId)
            return false
        end
    end

    for _, item in ipairs(trade.offerA) do
        Database.AdjustItem(trade.userA, item.item_key, -item.qty)
        Database.AdjustItem(trade.userB, item.item_key, item.qty)
    end
    
    for _, item in ipairs(trade.offerB) do
        Database.AdjustItem(trade.userB, item.item_key, -item.qty)
        Database.AdjustItem(trade.userA, item.item_key, item.qty)
    end

    trade.state = 'accepted'
    
    MySQL.update.await([[
        UPDATE dnc_collections_trades
        SET state = ?, initiator_offer = ?, target_offer = ?
        WHERE trade_id = ?
    ]], { 
        'accepted',
        json.encode(trade.offerA),
        json.encode(trade.offerB),
        tradeId
    })

    TriggerClientEvent('dnc:trade:finished', trade.sourceA, true)
    TriggerClientEvent('dnc:trade:finished', trade.sourceB, true)
    
    Utils.Debug(('Trade completed: id=%d'):format(tradeId))

    SetTimeout(5000, function()
        TradeManager.ActiveTrades[tradeId] = nil
    end)
    
    return true
end

function TradeManager.Cancel(tradeId, reason)
    local trade = TradeManager.GetTrade(tradeId)
    if not trade then return end
    
    trade.state = 'cancelled'
    
    MySQL.update.await([[
        UPDATE dnc_collections_trades
        SET state = ?
        WHERE trade_id = ?
    ]], { 'cancelled', tradeId })
    
    if IsOnline(trade.sourceA) then
        TriggerClientEvent('dnc:trade:finished', trade.sourceA, false)
    end
    
    if IsOnline(trade.sourceB) then
        TriggerClientEvent('dnc:trade:finished', trade.sourceB, false)
    end
    
    Utils.Debug(('Trade cancelled: id=%d reason=%s'):format(tradeId, reason or 'unknown'))
    
    TradeManager.ActiveTrades[tradeId] = nil
end

function TradeManager.Sync(tradeId)
    local trade = TradeManager.GetTrade(tradeId)
    if not trade then return end
    
    local payload = {
        tradeId = tradeId,
        aOffer = trade.offerA,
        bOffer = trade.offerB,
        aReady = trade.readyA,
        bReady = trade.readyB
    }
    
    if IsOnline(trade.sourceA) then
        local payloadA = Utils.TableCopy(payload)
        payloadA.selfSide = 'a'
        TriggerClientEvent('dnc:trade:sync', trade.sourceA, payloadA)
    end
    
    if IsOnline(trade.sourceB) then
        local payloadB = Utils.TableCopy(payload)
        payloadB.selfSide = 'b'
        TriggerClientEvent('dnc:trade:sync', trade.sourceB, payloadB)
    end
end

function TradeManager.CleanupPlayer(source)
    for tradeId, trade in pairs(TradeManager.ActiveTrades) do
        if trade.sourceA == source or trade.sourceB == source then
            if trade.state == 'pending' or trade.state == 'request' then
                TradeManager.Cancel(tradeId, 'player_dropped')
            end
        end
    end
end

function TradeManager.CancelAll()
    for tradeId, trade in pairs(TradeManager.ActiveTrades) do
        if trade.state == 'pending' or trade.state == 'request' then
            TradeManager.Cancel(tradeId, 'server_stop')
        end
    end
end

function TradeManager.CleanupExpired()
    local now = os.time()
    local timeout = (Config.Trade.RequestTimeout or 5000) / 1000
    
    for tradeId, trade in pairs(TradeManager.ActiveTrades) do
        if trade.state == 'request' and Utils.IsExpired(trade.timestamp, Config.Trade.RequestTimeout) then
            TradeManager.Cancel(tradeId, 'timeout')
        end
    end
end

CreateThread(function()
    while true do
        Wait(60000)
        
        TradeManager.CleanupExpired()
        local count = Utils.TableCount(TradeManager.ActiveTrades)
        if count > (Config.Trade.MaxActiveTrades or 100) then
            Utils.Debug(('Warning: %d active trades'):format(count))
        end
    end
end)

lib.callback.register('dnc:trade:start', function(source, payload)
    local targetSrc = Utils.ValidateNumber(payload and payload.targetId, 1, nil, 0)
    
    if targetSrc <= 0 or not IsOnline(targetSrc) then
        return { ok = false, err = 'jogador_invalido' }
    end
    
    local initiatorId = GetUserId(source)
    local targetId = GetUserId(targetSrc)
    
    if not initiatorId or not targetId or initiatorId == targetId then
        return { ok = false, err = 'jogador_invalido' }
    end
    
    if not CheckProximity(source, targetSrc) then
        return { ok = false, err = 'alvo_longe' }
    end
    
    local trade = TradeManager.Create(source, targetSrc)
    if not trade then
        return { ok = false, err = 'erro_criar_trade' }
    end

    TriggerClientEvent('dnc:trade:request', targetSrc, {
        tradeId = trade.id,
        fromId = source,
        fromName = Database.GetCharacterNameFromSource(source),
        timeout = Config.Trade.RequestTimeout
    })

    SetTimeout(Config.Trade.RequestTimeout, function()
        local t = TradeManager.GetTrade(trade.id)
        if t and t.state == 'request' then
            TradeManager.Cancel(trade.id, 'timeout')
            TriggerClientEvent('dnc:trade:error', source, 'request_timeout')
        end
    end)
    
    return { ok = true, trade_id = trade.id, requested = true }
end)

RegisterNetEvent('dnc:trade:reply', function(tradeId, accepted)
    local source = source
    tradeId = Utils.ValidateNumber(tradeId)
    
    local trade = TradeManager.GetTrade(tradeId)
    if not trade or trade.state ~= 'request' then return end
    if source ~= trade.sourceB then return end
    
    if not accepted then
        TradeManager.Cancel(tradeId, 'declined')
        TriggerClientEvent('dnc:trade:error', trade.sourceA, 'request_declined')
        return
    end
    
    local success, err = TradeManager.AcceptRequest(tradeId)
    if not success then
        TradeManager.Cancel(tradeId, err or 'accept_failed')
        TriggerClientEvent('dnc:trade:error', trade.sourceA, err or 'erro')
        TriggerClientEvent('dnc:trade:error', trade.sourceB, err or 'erro')
    end
end)

RegisterNetEvent('dnc:trade:updateOffer', function(tradeId, side, offer)
    local source = source
    tradeId = Utils.ValidateNumber(tradeId)
    side = Utils.ValidateString(side, 1, 1, 'a')
    
    local userId = GetUserId(source)
    if not userId then return end
    
    TradeManager.UpdateOffer(tradeId, side, offer, userId)
end)

RegisterNetEvent('dnc:trade:setReady', function(tradeId, side, ready)
    local source = source
    tradeId = Utils.ValidateNumber(tradeId)
    side = Utils.ValidateString(side, 1, 1, 'a')
    
    local userId = GetUserId(source)
    if not userId then return end
    
    TradeManager.SetReady(tradeId, side, ready, userId)
end)

RegisterNetEvent('dnc:trade:cancel', function(tradeId)
    local source = source
    tradeId = Utils.ValidateNumber(tradeId)
    
    local trade = TradeManager.GetTrade(tradeId)
    if not trade then return end
    
    local userId = GetUserId(source)
    if userId ~= trade.userA and userId ~= trade.userB then return end
    
    TradeManager.Cancel(tradeId, 'user_cancelled')
end)