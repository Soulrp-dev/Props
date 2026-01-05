Objects = {
    Held = nil
}

function Objects.StopHold()
    if not Objects.Held then return end
    
    TriggerServerEvent('dnc:collections:deleteObject')
    Objects.Held = nil
    
    Utils.Debug('Object removed')
end

function Objects.StartHold(itemKey)
    local catalog = ClientState.Cache.Catalog or {}
    local def = catalog[itemKey]
    
    if not def or not def.prop then
        Collections.Notify('error', 'Este item não tem prop configurado.')
        return
    end
    
    local prop = def.prop
    local model = prop.model or prop
    
    if not model or model == '' then
        Collections.Notify('error', 'Modelo do prop inválido.')
        return
    end
    
    -- Remove anterior
    Objects.StopHold()
    
    -- Parâmetros
    local animDict = (prop.anim and prop.anim.dict) or ""
    local animName = (prop.anim and prop.anim.name) or ""
    local animFlag = Utils.ValidateNumber(prop.anim and prop.anim.flag, 0, 127, 49)
    local bone = Utils.ValidateNumber(prop.bone, 0, nil, Config.Objects.DefaultBone)
    
    -- Posição e rotação
    local posX = Utils.ValidateNumber(prop.pos and prop.pos.x, nil, nil, 0)
    local posY = Utils.ValidateNumber(prop.pos and prop.pos.y, nil, nil, 0)
    local posZ = Utils.ValidateNumber(prop.pos and prop.pos.z, nil, nil, 0)
    local rotX = Utils.ValidateNumber(prop.rot and prop.rot.x, nil, nil, 0)
    local rotY = Utils.ValidateNumber(prop.rot and prop.rot.y, nil, nil, 0)
    local rotZ = Utils.ValidateNumber(prop.rot and prop.rot.z, nil, nil, 0)
    
    Utils.Debug('Creating object:', itemKey)
    Utils.Debug('  Model:', model)
    Utils.Debug('  Bone:', bone)
    Utils.Debug('  Pos:', posX, posY, posZ)
    Utils.Debug('  Rot:', rotX, rotY, rotZ)
    
    -- Envia para servidor
    TriggerServerEvent('dnc:collections:createObject', {
        dict = animDict,
        anim = animName,
        prop = model,
        flag = animFlag,
        bone = bone,
        posX = posX,
        posY = posY,
        posZ = posZ,
        rotX = rotX,
        rotY = rotY,
        rotZ = rotZ
    })
    
    Objects.Held = itemKey
end

-- ============================================
-- Callbacks NUI
-- ============================================

RegisterNUICallback('hold:start', function(data, cb)
    local itemKey = data and data.itemKey
    
    if not itemKey or itemKey == '' then
        cb(0)
        return
    end
    
    Objects.StartHold(itemKey)
    cb(1)
end)

RegisterNUICallback('hold:stop', function(_, cb)
    Objects.StopHold()
    cb(1)
end)

-- ============================================
-- Exports
-- ============================================

exports('HoldItem', function(itemKey)
    Objects.StartHold(itemKey)
end)

exports('StopHold', function()
    Objects.StopHold()
end)

exports('GetHeldItem', function()
    return Objects.Held
end)