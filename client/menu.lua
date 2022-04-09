QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

local names = {}
local inRadialMenu = false

local menu = {
    [1] = {
        lable = 'Follow',
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            TaskFollowTargetedPlayer(activePed.entity, plyped, 3.0)
        end
    },
    [2] = {
        lable = "Hunt",
        action = function(plyped, activePed)
            if activePed.canHunt == true then
                if activePed.level >= Config.Settings.minHuntingAbilityLevel then
                    attackLogic()
                else
                    TriggerEvent('QBCore:Notify',
                        "Not enough levels to hunt (min " .. Config.Settings.minHuntingAbilityLevel .. ')')
                end
            else
                TriggerEvent('QBCore:Notify', "Your pet can't hunt!")
            end
        end
    },
    [3] = {
        lable = "Hunt and Grab",
        action = function(plyped, activePed)
            local activeLaser = true
            while activeLaser do
                Wait(0)
                local color = {
                    r = 2,
                    g = 241,
                    b = 181,
                    a = 200
                }
                local plyped = PlayerPedId()
                local position = GetEntityCoords(plyped)
                local coords, entity = RayCastGamePlayCamera(1000.0)
                Draw2DText('Press ~g~E~w~ To go there', 4, {255, 255, 255}, 0.4, 0.43, 0.888 + 0.025)
                if IsControlJustReleased(0, 38) then
                    local dragger = activePed.entity
                    CreateThread(function()
                        local finished = false
                        TaskFollowToOffsetOfEntity(dragger, entity, 0.0, 0.0, 0.0, 5.0, 10.0, 1.0, 1)
                        waitForAnimation('creatures@retriever@melee@streamed_core@')
                        while finished == false do
                            local pedCoord = GetEntityCoords(entity)
                            local petCoord = GetEntityCoords(dragger)
                            local distance = GetDistanceBetweenCoords(pedCoord, petCoord)
                            if distance < 5.0 then
                                AttackTargetedPed(dragger, entity)
                                while IsPedDeadOrDying(entity) == false do

                                    Wait(250)
                                end
                                SetEntityCoords(entity, GetOffsetFromEntityInWorldCoords(dragger, 0.0, 0.25, 0.0))
                                AttachEntityToEntity(entity, dragger, 11816, 0.05, 0.05, 0.5, 0.0, 0.0, 0.0, false,
                                    false, false, false, 2, true)
                                -- TaskPlayAnim(dragger, 'creatures@retriever@melee@streamed_core@', 'ground_attack_0',
                                --     8.0, 1.0, -1, 49, 0, 0, 0, 0)
                                -- pedCoord = GetEntityCoords(entity)
                                -- TaskPlayAnimAdvanced(dragger --[[ Ped ]] , 'creatures@retriever@melee@streamed_core@' --[[ string ]] ,
                                --     'ground_attack_0' --[[ string ]] , pedCoord.x --[[ number ]] , pedCoord.y --[[ number ]] ,
                                --     pedCoord.z --[[ number ]] , 0 --[[ number ]] , 0 --[[ number ]] , 0 --[[ number ]] ,
                                --     0.5 --[[ number ]] , 0.5 --[[ number ]] , 10.0 --[[ integer ]] , 49 --[[ Any ]] ,
                                --     0.5 --[[ number ]] , 0 --[[ Any ]] , 0 --[[ Any ]] )
                                finished = true
                            end
                            Wait(1000)
                        end
                        CreateThread(function()
                            local finished2 = false
                            local playerPed = PlayerPedId()
                            TaskFollowToOffsetOfEntity(dragger, playerPed, 2.0, 2.0, 2.0, 1.0, 10.0, 3.0, 1)
                            while finished2 == false do
                                local pedCoord = GetEntityCoords(playerPed)
                                local petCoord = GetEntityCoords(dragger)
                                local distance = GetDistanceBetweenCoords(pedCoord, petCoord)
                                if distance < 3.0 then
                                    DetachEntity(entity, true, false)
                                    ClearPedSecondaryTask(dragger)
                                    finished2 = true
                                end
                                Wait(1000)

                            end
                        end)
                    end)
                    activeLaser = false
                end
                DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b,
                    color.a)
                DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r,
                    color.g, color.b, color.a, false, true, 2, nil, nil, false)
            end
        end
    },
    [4] = {
        lable = "There",
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            goThere(activePed.entity)
        end
    },
    [5] = {
        lable = "Wait",
        action = function(plyped, activePed)
            ClearPedTasks(activePed.entity)
        end
    },
    [6] = {
        lable = "Get in Car",
        action = function(plyped, activePed)
            getIntoCar()
        end
    }
}

RegisterNetEvent("onResourceStart", function()
    Wait(100)
    for key, name in pairs(menu) do
        names[key] = name.lable
    end
    SendNUIMessage({
        type = "ui",
        display = false,
        initData = names,
        customKey = 'o'
    })
    PlayerData = QBCore.Functions.GetPlayerData()
end)

-- Sets the metadata when the player spawns
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(100)
    PlayerData = QBCore.Functions.GetPlayerData()
    for key, name in pairs(menu) do
        names[key] = name.lable
    end
    SendNUIMessage({
        type = "ui",
        display = false,
        initData = names,
        customKey = 'o'
    })
end)

-- This will update all the PlayerData that doesn't get updated with a specific event other than this like the metadata
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

local function IsPoliceOrEMS()
    return (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance")
end

local function IsDowned()
    return (PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"])
end

local function setRadialState(bool, sendMessage, delay)
    -- Menuitems have to be added only once
    SetNuiFocus(bool, bool)
    if sendMessage then
        SendNUIMessage({
            type = "msg"
        })
    end
    if delay then
        Wait(500)
    end
    inRadialMenu = bool
end

RegisterNUICallback('exit', function(req)
    if req.exit == true then
        Wait(50)
        inRadialMenu = false
        SetNuiFocus(false, false)
    end
end)

RegisterNUICallback('request', function(req)
    -- what player asked to do
    for key, value in pairs(menu) do
        if req.content == value.lable then
            value.action(PlayerPedId(), ActivePed:read())
        end
    end
end)

-- Command
RegisterCommand('+showMenu', function()
    local doesPlayerHavePet = ActivePed:read() or {}
    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not PlayerData.metadata["ishandcuffed"] and
        not IsPauseMenuActive() and not inRadialMenu and next(doesPlayerHavePet) ~= nil then
        SetCursorLocation(0.5, 0.5)
        setRadialState(true, true)
    elseif next(doesPlayerHavePet) == nil then
        TriggerEvent('QBCore:Notify', "you must have atleast one active pet to access to menu")
    end
end, false)

RegisterKeyMapping('+showMenu', 'show pet menu', 'keyboard', 'o')
