QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

local names = {}
local inRadialMenu = false

local menu = {
    [1] = {
        lable = 'Follow',
        action = function()
            local plyped = PlayerPedId()
            local ped = ActivePed:read().entity
            doSomethingIfPedIsInsideVehicle(ped)
            TaskFollowTargetedPlayer(ped, plyped, 3.0)
        end
    },
    [2] = {
        lable = "Hunt",
        action = function()
            if ActivePed:read().level >= 0 then
                attackLogic()
            else
                TriggerEvent('QBCore:Notify', "Not enoght levels")
            end
        end
    },
    [3] = {
        lable = "Change Color",
        action = function()
            local ped = ActivePed:read().entity
            local model = ActivePed:read().model
            waitForAnimation('creatures@retriever@amb@world_dog_barking@idle_a')
            TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_barking@idle_a', 'idle_c', 8.0, -8, -1, 1, 0, false,
                false, false)
        end
    },
    [4] = {
        lable = "There",
        action = function()
            local ped = ActivePed:read().entity
            doSomethingIfPedIsInsideVehicle(ped)
            goThere(ped)
        end
    },
    [5] = {
        lable = "Wait",
        action = function()
            local ped = ActivePed:read().entity
            ClearPedTasks(ped)
        end
    },
    [6] = {
        lable = "Get in Car",
        action = function()
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

-- Sets the playerdata to an empty table when the player has quit or did /logout
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
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
            value.action()
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
