Objects = {}

RegisterNetEvent('dnc:collections:createObject', function(data)
    local source = source
    
    if type(data) ~= 'table' then
        return
    end
    
    local user_id = GetUserId(source)
    if not user_id then
        return
    end

    local model = Utils.ValidateString(data.prop, 1, 100, '')
    if model == '' then
        Utils.Error('Invalid model for object creation')
        return
    end
    
    local dict = Utils.ValidateString(data.dict, 0, 100, '')
    local anim = Utils.ValidateString(data.anim, 0, 100, '')
    local flag = Utils.ValidateNumber(data.flag, 0, 127, Config.Objects.DefaultFlag)
    local bone = Utils.ValidateNumber(data.bone, 0, nil, Config.Objects.DefaultBone)
    
    local posX = Utils.ValidateNumber(data.posX, nil, nil, 0)
    local posY = Utils.ValidateNumber(data.posY, nil, nil, 0)
    local posZ = Utils.ValidateNumber(data.posZ, nil, nil, 0)
    local rotX = Utils.ValidateNumber(data.rotX, nil, nil, 0)
    local rotY = Utils.ValidateNumber(data.rotY, nil, nil, 0)
    local rotZ = Utils.ValidateNumber(data.rotZ, nil, nil, 0)
    
    Utils.Debug(('Creating object for source %d'):format(source))
    Utils.Debug(('  Model: %s'):format(model))
    Utils.Debug(('  Bone: %d'):format(bone))
    Utils.Debug(('  Pos: %.2f, %.2f, %.2f'):format(posX, posY, posZ))
    Utils.Debug(('  Rot: %.2f, %.2f, %.2f'):format(rotX, rotY, rotZ))
    
    -- Chama vRPC
    local success, err = pcall(function()
        vRPC._CreateObjects(
            source,
            dict,
            anim,
            model,
            flag,
            bone,
            posX,
            posY,
            posZ,
            rotX,
            rotY,
            rotZ
        )
    end)
    
    if not success then
        Utils.Error(('Failed to create object: %s'):format(tostring(err)))
    else
        Utils.Debug('Object created successfully')
    end
end)

RegisterNetEvent('dnc:collections:deleteObject', function()
    local source = source
    local user_id = GetUserId(source)
    
    if not user_id then
        return
    end
    
    Utils.Debug(('Deleting object for source %d'):format(source))
    
    local success, err = pcall(function()
        vRPC._Destroy(source, "one")
    end)
    
    if not success then
        Utils.Error(('Failed to delete object: %s'):format(tostring(err)))
    else
        Utils.Debug('Object deleted successfully')
    end
end)