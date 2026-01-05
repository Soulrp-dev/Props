NUI = {
    Ready = false,
    Queue = {},
    Focus = false,
    CurrentTab = nil
}

function NUI.Send(payload)
    if not payload or type(payload) ~= 'table' then
        Utils.Error('NUI.Send: Invalid payload')
        return
    end
    
    if not NUI.Ready then
        table.insert(NUI.Queue, payload)
        return
    end
    
    SendNUIMessage(payload)
end

function NUI.Open(tab)
    tab = tab or 'collections'
    
    NUI.Send({ action = 'set_tab', tab = tab })
    NUI.Send({ action = 'toggle', state = true })
    
    SetNuiFocus(true, true)
    NUI.Focus = true
    NUI.CurrentTab = tab
    
    Utils.Debug('NUI opened on tab:', tab)
end

function NUI.Close()
    SetNuiFocus(false, false)
    NUI.Send({ action = 'toggle', state = false })
    
    NUI.Focus = false
    NUI.CurrentTab = nil
    
    Utils.Debug('NUI closed')
end

function NUI.Toggle(state, tab)
    if state then
        NUI.Open(tab)
    else
        NUI.Close()
    end
end

function NUI.FlushQueue()
    Utils.Debug('Flushing NUI queue:', #NUI.Queue, 'messages')
    
    for _, payload in ipairs(NUI.Queue) do
        SendNUIMessage(payload)
    end
    
    NUI.Queue = {}
end

RegisterNUICallback('nui_ready', function(_, cb)
    Utils.Debug('NUI is ready')
    
    NUI.Ready = true
    NUI.FlushQueue()
    
    cb(1)
end)

RegisterNUICallback('close', function(_, cb)
    NUI.Close()
    cb(1)
end)

RegisterNUICallback('notify', function(data, cb)
    if Collections then
        Collections.Notify(data.color or 'info', data.message or '')
    end
    cb(1)
end)

RegisterNUICallback('dnc:collections:getData', function(_, cb)
    if not lib then
        cb({ catalog = {}, items = {}, featured = nil })
        return
    end
    
    lib.callback('dnc:collections:getData', false, function(data)
        if not data then
            cb({ catalog = {}, items = {}, featured = nil })
            return
        end

        ClientState.Cache.Catalog = data.catalog or {}
        ClientState.Cache.Items = data.items or {}
        ClientState.Cache.Featured = data.featured
        
        cb(data)
    end)
end)

RegisterNetEvent('dnc:collections:toggleNUI', function(state, tab)
    NUI.Toggle(state, tab)
end)

RegisterNetEvent('dnc:collections:open', function(tab)
    NUI.Open(tab)
end)

RegisterNetEvent('dnc:collections:force_close', function()
    NUI.Close()
end)

RegisterNetEvent('dnc:collections:refresh', function()
    NUI.Send({ action = 'refresh_data' })
end)

exports('OpenMenu', function(tab)
    NUI.Open(tab)
end)

exports('CloseMenu', function()
    NUI.Close()
end)

exports('IsOpen', function()
    return NUI.Focus
end)