Framework = {}
TOMM.CoreObject = nil
TOMM.Math = {}
TOMM.Functions = {}
TOMM.Callback = {}
TOMM.Callback.Functions = {}
TOMM.Callback.ServerCallbacks = {}

exports('getObject', function()
    return TOMM
end)

if TOMM.Framework == "ESX" then
    if TOMM.NewESX == true then
        Framework = exports['es_extended']:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj) Framework = obj end)
    end
elseif TOMM.Framework == "QBCore" then
    Framework = exports['qb-core']:GetCoreObject()
end

TOMM.CoreObject = Framework

TOMM.Callback.Functions.RegisterServerCallback = function(name, cb)
    TOMM.Callback.ServerCallbacks[name] = cb
end

TOMM.Callback.Functions.TriggerServerCallback = function(name, source, cb, ...)
    local src = source
    if TOMM.Callback.ServerCallbacks[name] then
        TOMM.Callback.ServerCallbacks[name](src, cb, ...)
    end
end

RegisterNetEvent('tomm_lib:Server:TriggerServerCallback', function(name, ...)
    local src = source
    TOMM.Callback.Functions.TriggerServerCallback(name, src, function(...)
        TriggerClientEvent('tomm_lib:Client:TriggerServerCallback', src, name, ...)
    end, ...)
end)

TOMM.Functions.SpawnVehicle = function(model, coords, heading, Properties, cb)
    if TOMM.Framework == "ESX" then
        local veh_model = model
        Properties = Properties or {}
        local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
        TriggerClientEvent("esx:requestModel", -1, model)
        CreateThread(function()
            local xPlayer = Framework.OneSync.GetClosestPlayer(vector, 300)
            Framework.GetVehicleType(veh_model, xPlayer.id, function(Type)
                if Type then
                    local SpawnedEntity = CreateVehicleServerSetter(veh_model, Type, vector, heading)
                    local NetworkId = NetworkGetNetworkIdFromEntity(SpawnedEntity)
                    while not DoesEntityExist(SpawnedEntity) do
                        Wait(100)
                    end
                    Properties.NetId = NetworkId
                    Entity(SpawnedEntity).state:set('VehicleProperties', Properties, true)
                    cb(NetworkId)
                else
                    print(('[^1ERROR^7] Tried to spawn invalid vehicle - ^5%s^7!'):format(model))
                end
            end)
        end)
    else
        local veh_model = model
        Properties = Properties or {}
        local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
        CreateThread(function()
            local SpawnedEntity = CreateVehicle(veh_model, vector, heading, true, true)
            Wait(100)
            while not DoesEntityExist(SpawnedEntity) do
                Wait(100)
            end
            local NetworkId = NetworkGetNetworkIdFromEntity(SpawnedEntity)
            Properties.NetId = NetworkId
            Entity(SpawnedEntity).state:set('VehicleProperties', Properties, true)
            cb(NetworkId)
        end)
    end
end

TOMM.Functions.SpawnObject = function(model, coords, heading, cb)
    local coords = type(coords) == "vector3" and coords or vector3(coords.x, coords.y, coords.z)
    CreateThread(function()
        local entity = CreateObject(model, coords, true, true)
        while not DoesEntityExist(entity) do Wait(50) end
        SetEntityHeading(entity, heading)
        cb(NetworkGetNetworkIdFromEntity(entity))
    end)
end

TOMM.Functions.GetPlayers = function()
    if TOMM.Framework == "ESX" then
        if TOMM.NewESX == true then
            return Framework.GetExtendedPlayers()
        else
            local temp = Framework.GetPlayers()
            local xPlayers = {}
            for i=1, #temp, 1 do
                xPlayers[i] = TOMM.Functions.GetPlayerFromIdentifier(1)
            end
            return xPlayers
        end
    else
        local players = Framework.Functions.GetQBPlayers()
        local tempPlayers = {}
        for k, v in pairs(players) do
            tempPlayers[k] = TOMM.Functions.GetPlayerFromId(v.PlayerData.source)
        end
        return tempPlayers
    end
end

TOMM.Functions.GetPlayerFromIdentifier = function(identifier)
    if TOMM.Framework == "ESX" then
        return Framework.GetPlayerFromIdentifier(identifier)
    else
        return Framework.Functions.GetPlayerByCitizenId(identifier)
    end
end

TOMM.Functions.GetPlayerFromId = function(source)
    if TOMM.Framework == "ESX" then
        return Framework.GetPlayerFromId(source)
    else

        local player = Framework.Functions.GetPlayer(source)

        if player == nil then
            return nil
        end

        local self = player

        self.identifier = self.PlayerData.citizenid

        self.removeAccountMoney = function(account, amount)
            return self.Functions.RemoveMoney(account,amount)
        end

        self.addAccountMoney = function(account, amount)
            return self.Functions.AddMoney(account,amount)
        end

        self.getAccount = function(moneytype)
            if moneytype then
                local moneytype = moneytype:lower()
                local temp = {}
                temp.name = moneytype
                temp.money = self.PlayerData.money[moneytype]
                temp.label = moneytype
                return temp
            else
                return false
            end
        end

        self.source = self.PlayerData.source

        self.getName = function()
            return self.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
        end

        return self
    end
end

TOMM.Math.GroupDigits = function(value)
    local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1' .. ","):reverse())..right
end


