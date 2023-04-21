Framework = nil
TOMM = {}
TOMM.Framework = Config.Framework
TOMM.CoreObject = nil
TOMM.Functions = {}
TOMM.Functions.UI = {}
TOMM.Callback = {}
TOMM.Callback.Functions = {}
TOMM.Callback.ServerCallbacks = {}
TOMM.Callback.ClientCallbacks = {}
TOMM.Math = {}

Citizen.CreateThread(function()
    if Config.Framework == "ESX" then
        if Config.NewESX == true then
            while Framework == nil do
                Framework = exports['es_extended']:getSharedObject()
                Citizen.Wait(1)
            end
        else
            while Framework == nil do
                TriggerEvent('esx:getSharedObject', function(obj) Framework = obj end)
                Citizen.Wait(1)
            end
        end
    elseif Config.Framework == "QBCore" then
        while Framework == nil do
            Framework = exports['qb-core']:GetCoreObject()
            Citizen.Wait(1)
        end
    end
    while TOMM.CoreObject == nil do
        TOMM.CoreObject = Framework
        Citizen.Wait(1)
    end


    RegisterNetEvent("tomm_lib:playerLoaded")
    AddEventHandler("tomm_lib:playerLoaded",function()
    end)

    RegisterNetEvent('esx:playerLoaded', function()
        TriggerEvent("tomm_lib:playerLoaded")
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        TriggerEvent("tomm_lib:playerLoaded")
    end)


    TOMM.Callback.Functions.TriggerServerCallback = function(name, cb, ...)
        TOMM.Callback.ServerCallbacks[name] = cb
        TriggerServerEvent('tomm_lib:Server:TriggerServerCallback', name, ...)
    end

    RegisterNetEvent('tomm_lib:Client:TriggerServerCallback', function(name, ...)
        if TOMM.Callback.ServerCallbacks[name] then
            TOMM.Callback.ServerCallbacks[name](...)
            TOMM.Callback.ServerCallbacks[name] = nil
        end
    end)

    TOMM.Functions.GetPlayerData = function()
        if Config.Framework == "ESX" then
            return Framework.GetPlayerData()
        else
            local temp = Framework.Functions.GetPlayerData()
            temp.identifier = temp.citizenid
            return temp
        end
    end

    TOMM.Functions.SpawnVehicle = function(model, coords, heading, cb, networked)
        if Config.Framework == "ESX" then

            local model = model
            local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
            networked = networked == nil and true or networked
            CreateThread(function()

                if not IsModelInCdimage(model) then
                    return
                end
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(10)
                end

                local vehicle = CreateVehicle(model, vector.xyz, heading, networked, true)

                if networked then
                    local id = NetworkGetNetworkIdFromEntity(vehicle)
                    SetNetworkIdCanMigrate(id, true)
                    SetEntityAsMissionEntity(vehicle, true, true)
                end
                SetVehicleHasBeenOwnedByPlayer(vehicle, true)
                SetVehicleNeedsToBeHotwired(vehicle, false)
                SetModelAsNoLongerNeeded(model)
                SetVehRadioStation(vehicle, 'OFF')

                RequestCollisionAtCoord(vector.xyz)
                while not HasCollisionLoadedAroundEntity(vehicle) do
                    Wait(0)
                end

                if cb then
                    cb(vehicle)
                end
            end)
        else
            local model = GetHashKey(model)
            local ped = PlayerPedId()
            if coords then
                coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
            else
                coords = GetEntityCoords(ped)
            end
            local isnetworked = networked or true
            if not IsModelInCdimage(model) then
                return
            end
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(10)
            end
            local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
            local netid = NetworkGetNetworkIdFromEntity(veh)
            SetVehicleHasBeenOwnedByPlayer(veh, true)
            SetNetworkIdCanMigrate(netid, true)
            SetVehicleNeedsToBeHotwired(veh, false)
            SetVehRadioStation(veh, 'OFF')
            SetModelAsNoLongerNeeded(model)
            if cb then
                cb(veh)
            end
        end
    end

    TOMM.Functions.DeleteVehicle = function(vehicle)
        if Config.Framework == "ESX" then
            Framework.Game.DeleteVehicle(vehicle)
        else
            Framework.Functions.DeleteVehicle(vehicle)
        end
    end

    TOMM.Functions.GetVehicleProperties = function(vehicle)
        if Config.Framework == "ESX" then
            return Framework.Game.GetVehicleProperties(vehicle)
        else
            return Framework.Functions.GetVehicleProperties(vehicle)
        end
    end

    TOMM.Functions.SetVehicleProperties = function(vehicle, props)
        if Config.Framework == "ESX" then
            Framework.Game.SetVehicleProperties(vehicle, props)
        else
            Framework.Functions.SetVehicleProperties(vehicle, props)
        end
    end

    TOMM.Functions.Teleport = function(entity, coords)
        SetEntityCoords(entity, coords)
    end

    TOMM.Functions.IsSpawnPointClear = function(coords, maxDistance)
        local maxDistance = maxDistance or 5
        if Config.Framework == "ESX" then
            return Framework.Game.IsSpawnPointClear(coords, maxDistance)
        else
            local closestVehicle, distance = Framework.Functions.GetClosestVehicle(coords)
            if distance > maxDistance then
                return true
            else
                return false
            end
        end
    end

    TOMM.Functions.Draw3DText = function(coords, text, size, font)
        local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
        local camCoords = GetFinalRenderedCamCoord()
        local distance = #(vector - camCoords)
        if not size then
            size = 1
        end
        if not font then
            font = 0
        end
        local scale = (size / distance) * 2
        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        BeginTextCommandDisplayText('STRING')
        SetTextCentre(true)
        AddTextComponentSubstringPlayerName(text)
        SetDrawOrigin(vector.xyz, 0)
        EndTextCommandDisplayText(0.0, 0.0)
        ClearDrawOrigin()
    end

    TOMM.Math.GroupDigits = function(value)
        local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')

        return left..(num:reverse():gsub('(%d%d%d)','%1' .. ","):reverse())..right
    end

end)

exports('getObject', function()
    while TOMM == nil do
        Wait(1)
    end
    return TOMM
end)