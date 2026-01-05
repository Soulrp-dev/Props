Collections = {
    Featured = nil
}

function Collections.Notify(color, message)
    color = color or 'info'
    message = tostring(message or '')
    
    if Config.Notify.Provider == 'ox_lib' and lib and lib.notify then
        local type = ({
            info = 'info',
            success = 'success',
            warning = 'warning',
            error = 'error',
            importante = 'info',
            sucesso = 'success',
            amarelo = 'warning',
            negado = 'error'
        })[color] or 'info'
        
        lib.notify({
            title = 'Coleções',
            description = message,
            type = type
        })
        
    elseif Config.Notify.Provider == 'custom' or Config.Notify.Provider == 'auto' then
        local mappedColor = Config.Notify.ColorMap[color] or color
        TriggerEvent(Config.Notify.CustomEvent, mappedColor, message)
    end
end

RegisterNUICallback('openFromInventory', function(data, cb)
    SetTimeout(120, function()
        NUI.Open(data and data.tab or 'collections')
    end)
    cb(1)
end)

RegisterNUICallback('collections:setFeatured', function(data, cb)
    local itemKey = data and data.itemKey or nil
    TriggerServerEvent('dnc:collections:setFeatured', itemKey)
    cb(1)
end)

RegisterNetEvent('dnc:collections:featuredChanged', function(itemKey, icon)
    Collections.Featured = itemKey
    
    NUI.Send({
        action = 'featured_changed',
        itemKey = itemKey,
        icon = icon
    })
end)

-- RegisterNetEvent('dnc:collections:itemAdded', function(itemKey, qty)
--     Collections.Notify('success', ('Você recebeu %s x%d'):format(itemKey, qty))
    
--     NUI.Send({
--         action = 'item_added',
--         itemKey = itemKey,
--         qty = qty
--     })
-- end)

exports('GetFeatured', function()
    return Collections.Featured
end)