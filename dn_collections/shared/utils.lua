Utils = {}

function Utils.Trim(s)
    if not s then return "" end
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

function Utils.IsEmpty(s)
    return not s or Utils.Trim(s) == ""
end

function Utils.TableCount(t)
    if type(t) ~= 'table' then return 0 end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function Utils.TableCopy(t)
    if type(t) ~= 'table' then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == 'table' and Utils.TableCopy(v) or v
    end
    return copy
end

function Utils.TableMerge(t1, t2)
    local result = Utils.TableCopy(t1)
    for k, v in pairs(t2 or {}) do
        result[k] = v
    end
    return result
end

function Utils.ValidateNumber(val, min, max, default)
    local num = tonumber(val)
    if not num then return default or 0 end
    if min and num < min then return min end
    if max and num > max then return max end
    return num
end

function Utils.ValidateString(val, minLen, maxLen, default)
    if type(val) ~= 'string' then return default or "" end
    local trimmed = Utils.Trim(val)
    if minLen and #trimmed < minLen then return default or "" end
    if maxLen and #trimmed > maxLen then return trimmed:sub(1, maxLen) end
    return trimmed
end

function Utils.Debug(...)
    if not Config.Performance.EnableDebug then return end
    print(('[DN_COLLECTIONS] %s'):format(table.concat({...}, ' ')))
end

function Utils.Error(...)
    print(('[DN_COLLECTIONS ERROR] %s'):format(table.concat({...}, ' ')))
end

function Utils.GetTimestamp()
    if os and os.time then
        return os.time()
    end
    
    if GetCloudTimeAsInt then
        local cloudTime = GetCloudTimeAsInt()
        if cloudTime and cloudTime > 0 then
            return cloudTime
        end
    end


    if GetGameTimer then
        return math.floor(GetGameTimer() / 1000)
    end
    
    return 0
end

function Utils.IsExpired(timestamp, timeout)
    return (Utils.GetTimestamp() - timestamp) > (timeout / 1000)
end