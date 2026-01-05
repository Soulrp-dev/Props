local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")

ServerState = {
    Ready = false,
    StartTime = os.time(),
    ResourceName = GetCurrentResourceName()
}

function GetUserId(source)
    if not source or source == 0 then 
        return nil 
    end
    
    if not vRP or not vRP.Passport then
        Utils.Error('vRP.Passport não está disponível')
        return nil
    end
    
    local user_id = vRP.Passport(source)
    
    if not user_id or user_id == 0 then
        return nil
    end
    
    return user_id
end

function GetSource(user_id)
    if not user_id or user_id == 0 then
        return nil
    end
    
    if not vRP or not vRP.Source then
        Utils.Error('vRP.Source não está disponível')
        return nil
    end
    
    return vRP.Source(user_id)
end

function IsOnline(source)
    if not source or source == 0 then
        return false
    end
    
    return GetPlayerPed(source) ~= 0
end

function HasPermission(user_id, perm)
    if not user_id then return false end
    
    if not vRP or not vRP.HasPermission then
        Utils.Debug('vRP.HasPermission não disponível, permitindo acesso')
        return true
    end
    
    return vRP.HasPermission(user_id, perm)
end

local _OriginalTCE = TriggerClientEvent
TriggerClientEvent = function(eventName, target, ...)
    if eventName == nil then
        Utils.Error('TriggerClientEvent com eventName nil')
        Utils.Debug(debug.traceback('', 2))
        return
    end
    
    if target == nil then
        Utils.Debug('TriggerClientEvent sem target, usando broadcast')
        target = -1
    end
    
    if target ~= -1 and not IsOnline(target) then
        Utils.Debug(('TriggerClientEvent: player %s offline, event %s ignorado'):format(target, eventName))
        return
    end
    
    return _OriginalTCE(eventName, target, ...)
end

AddEventHandler('playerDropped', function(reason)
    local source = source
    local user_id = GetUserId(source)
    
    Utils.Debug(('Player dropped: source=%d user_id=%s reason=%s'):format(
        source,
        tostring(user_id or 'unknown'),
        reason or 'unknown'
    ))

    if TradeManager then
        TradeManager.CleanupPlayer(source)
    end
end)

CreateThread(function()
    Wait(2000)
    
    Utils.Debug('========== SERVER INITIALIZATION ==========')
    Utils.Debug('Resource:', ServerState.ResourceName)
    Utils.Debug('vRP available:', vRP ~= nil)
    
    if vRP then
        Utils.Debug('vRP.Passport:', type(vRP.Passport))
        Utils.Debug('vRP.Source:', type(vRP.Source))
        Utils.Debug('vRP.HasPermission:', type(vRP.HasPermission))
    end
    
    if CollectionsCatalog then
        Utils.Debug('Catalog items:', Utils.TableCount(CollectionsCatalog))
    else
        Utils.Error('CollectionsCatalog não carregado!')
    end
    
    if MySQL then
        local result = MySQL.scalar.await('SELECT 1', {})
        if result then
            Utils.Debug('Database connection: OK')
        else
            Utils.Error('Database connection: FAILED')
        end
    else
        Utils.Error('MySQL não está disponível!')
    end
    
    Utils.Debug('==========================================')
    
    ServerState.Ready = true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= ServerState.ResourceName then return end
    Utils.Debug('Cleaning up server state...')
    TriggerClientEvent('dnc:collections:force_close', -1)
    if TradeManager then
        TradeManager.CancelAll()
    end
end)