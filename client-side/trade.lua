Trade = {
    PendingRequest = nil,
    ActiveTrade = nil
}

local function ClearPendingRequest()
    if not Trade.PendingRequest then return end
    
    NUI.Send({ action = 'trade_request', show = false })
    Trade.PendingRequest = nil
end

RegisterNUICallback('trade:getNearby', function(data, cb)
    local maxDist = Utils.ValidateNumber(data and data.max, 1, 100, 50)
    
    local myPed = PlayerPedId()
    local myPos = GetEntityCoords(myPed)
    local mySid = GetPlayerServerId(PlayerId())
    
    local players = {}
    local ids = {}
    
    for _, player in ipairs(GetActivePlayers()) do
        local sid = GetPlayerServerId(player)
        
        if sid ~= mySid then
            local ped = GetPlayerPed(player)
            
            if DoesEntityExist(ped) then
                local dist = #(GetEntityCoords(ped) - myPos)
                
                if dist <= maxDist then
                    local fallback = GetPlayerName(player) or ('ID ' .. sid)
                    
                    table.insert(players, {
                        id = sid,
                        name = fallback,
                        dist = math.floor(dist * 10) / 10
                    })
                    
                    table.insert(ids, sid)
                end
            end
        end
    end

    if #ids > 0 and lib then
        lib.callback('dnc:players:getNames', false, function(names)
            if names then
                for _, p in ipairs(players) do
                    local name = names[tostring(p.id)]
                    if name and name ~= "" then
                        p.name = name
                    end
                end
            end
            
            table.sort(players, function(a, b) return a.dist < b.dist end)
            cb(players)
        end, ids)
    else
        table.sort(players, function(a, b) return a.dist < b.dist end)
        cb(players)
    end
end)

RegisterNUICallback('trade:start', function(data, cb)
    local targetId = Utils.ValidateNumber(data and data.targetId, 1, nil, 0)
    
    if targetId <= 0 then
        cb({ ok = false, err = 'jogador_invalido' })
        return
    end
    
    if not lib then
        cb({ ok = false, err = 'no_lib' })
        return
    end
    
    lib.callback('dnc:trade:start', false, function(result)
        cb(result or { ok = false, err = 'falha' })
    end, { targetId = targetId })
end)

RegisterNUICallback('trade:inviteReply', function(data, cb)
    local tradeId = Utils.ValidateNumber(data.from)
    local accept = data.accept and true or false
    
    if tradeId then
        TriggerServerEvent('dnc:trade:reply', tradeId, accept)
    end
    
    ClearPendingRequest()
    cb(1)
end)

RegisterNUICallback('trade:updateOffer', function(data, cb)
    if type(data) ~= 'table' then 
        cb(0) 
        return 
    end
    
    local tradeId = Utils.ValidateNumber(data.tradeId)
    local side = Utils.ValidateString(data.side, 1, 1, 'a')
    
    TriggerServerEvent('dnc:trade:updateOffer', tradeId, side, data.offer or {})
    cb(1)
end)

RegisterNUICallback('trade:setReady', function(data, cb)
    if type(data) ~= 'table' then 
        cb(0) 
        return 
    end
    
    local tradeId = Utils.ValidateNumber(data.tradeId)
    local side = Utils.ValidateString(data.side, 1, 1, 'a')
    local ready = data.ready and true or false
    
    TriggerServerEvent('dnc:trade:setReady', tradeId, side, ready)
    cb(1)
end)

RegisterNUICallback('trade:cancel', function(data, cb)
    if type(data) ~= 'table' then 
        cb(0) 
        return 
    end
    
    local tradeId = Utils.ValidateNumber(data.tradeId)
    TriggerServerEvent('dnc:trade:cancel', tradeId)
    cb(1)
end)

RegisterNetEvent('dnc:trade:request', function(payload)
    if not payload then return end
    
    local tradeId = Utils.ValidateNumber(payload.tradeId)
    local fromName = Utils.ValidateString(payload.fromName, 1, 100, 'Jogador')
    local timeout = Utils.ValidateNumber(payload.timeout, 1000, 30000, 5000)
    
    Trade.PendingRequest = {
        id = tradeId,
        from = fromName,
        timestamp = Utils.GetTimestamp()
    }
    
    NUI.Send({
        action = 'trade_request',
        show = true,
        tradeId = tradeId,
        fromName = fromName,
        acceptKey = Config.Trade.AcceptKey,
        declineKey = Config.Trade.DeclineKey,
        timeoutMs = timeout
    })

    SetTimeout(timeout, function()
        if Trade.PendingRequest and Trade.PendingRequest.id == tradeId then
            ClearPendingRequest()
        end
    end)
end)

RegisterNetEvent('dnc:trade:opened', function(tradeId, selfSide)
    Trade.ActiveTrade = {
        id = tradeId,
        side = selfSide
    }
    
    NUI.Send({
        action = 'trade_opened',
        tradeId = tradeId,
        selfSide = selfSide
    })
    
    NUI.Open('trade')
end)

RegisterNetEvent('dnc:trade:sync', function(payload)
    if type(payload) ~= 'table' then return end
    
    NUI.Send({
        action = 'trade_sync',
        tradeId = payload.tradeId,
        aOffer = payload.aOffer or {},
        bOffer = payload.bOffer or {},
        aReady = payload.aReady and true or false,
        bReady = payload.bReady and true or false,
        selfSide = payload.selfSide or 'a'
    })
end)

RegisterNetEvent('dnc:trade:error', function(err)
    NUI.Send({ 
        action = 'trade_error', 
        err = Utils.ValidateString(err, 1, 100, 'erro') 
    })
end)

RegisterNetEvent('dnc:trade:finished', function(success)
    NUI.Send({ 
        action = 'trade_finished', 
        success = success and true or false 
    })
    
    Trade.ActiveTrade = nil
    SetTimeout(2000, NUI.Close)
end)

RegisterNetEvent('dnc:trade:hideRequest', function()
    ClearPendingRequest()
end)

RegisterCommand('dnc_trade_accept', function()
    if Trade.PendingRequest then
        TriggerServerEvent('dnc:trade:reply', Trade.PendingRequest.id, true)
        ClearPendingRequest()
    end
end, false)

RegisterCommand('dnc_trade_decline', function()
    if Trade.PendingRequest then
        TriggerServerEvent('dnc:trade:reply', Trade.PendingRequest.id, false)
        ClearPendingRequest()
    end
end, false)

RegisterKeyMapping('dnc_trade_accept', 'Aceitar troca', 'keyboard', Config.Trade.AcceptKey)
RegisterKeyMapping('dnc_trade_decline', 'Recusar troca', 'keyboard', Config.Trade.DeclineKey)