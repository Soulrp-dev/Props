Config = {}

Config.Trade = {
    RequireProximity = true,
    MaxDistance = 25.0,
    RequestTimeout = 5000,
    AcceptKey = 'Y',
    DeclineKey = 'N',
    CleanupInterval = 300000,
    MaxActiveTrades = 100
}

Config.Notify = {
    Provider = 'auto',
    CustomEvent = 'Notify',
    ColorMap = {
        info = 'importante',
        success = 'sucesso',
        warning = 'importante',
        error = 'negado'
    }
}

Config.Collections = {
    EnableInventoryBadge = true,
    CacheTimeout = 60000,
    MaxItemsPerTrade = 50
}

Config.Objects = {
    DefaultBone = 28422,
    DefaultFlag = 49
}

Config.Performance = {
    EnableDebug = false,
    CachePlayerData = true,
    BatchDatabaseWrites = true
}

Config.Rarities = {
    'Comum',
    'Rara', 
    'Épica',
    'Lendária',
    'NFT'
}