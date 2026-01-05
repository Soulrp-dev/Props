-- ============================================
-- Client Bootstrap - Inicialização e guardas
-- ============================================

ClientState = {
    Ready = false,
    NuiReady = false,
    PlayerData = {},
    Cache = {}
}

-- Guards para prevenir nil arguments
local function GuardNative(name, original)
    if type(original) ~= 'function' then return end
    
    _G[name] = function(arg1, ...)
        if arg1 == nil then
            Utils.Error(('%s called with nil arg1'):format(name))
            Utils.Debug(debug.traceback('', 2))
            return
        end
        return original(arg1, ...)
    end
end

-- Protege nativas críticas de NUI
GuardNative('SendNUIMessage', SendNUIMessage)
GuardNative('SetNuiFocus', SetNuiFocus)

if RegisterNuiCallbackType then
    GuardNative('RegisterNuiCallbackType', RegisterNuiCallbackType)
end

-- Cleanup ao desligar
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    Utils.Debug('Cleaning up client state...')
    
    -- Fecha NUI
    if NUI then
        NUI.Close()
    end
    
    -- Remove objetos
    if Objects then
        Objects.StopHold()
    end
    
    ClientState.Ready = false
end)

-- Inicialização
CreateThread(function()
    Wait(1000)
    
    -- Verifica dependências
    if not lib then
        Utils.Error('ox_lib not found! Resource cannot function.')
        return
    end
    
    Utils.Debug('Client initialized successfully')
    ClientState.Ready = true
end)