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
            if activePed.canHunt == true then
                if activePed.level >= Config.Settings.minHuntingAbilityLevel then
                    HuntandGrab(plyped, activePed)
                else
                    TriggerEvent('QBCore:Notify',
                        "Not enough levels to hunt (min " .. Config.Settings.minHuntingAbilityLevel .. ')')
                end
            else
                TriggerEvent('QBCore:Notify', "Your pet can't hunt!")
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
    },
    [7] = {
        lable = "Tricks",
        action = function(plyped, activePed)
            QBCore.Functions.Notify('test tricks beg', 'error', 1500)
            Animator(activePed.entity, activePed.model, 'tricks', 'beg', {
                sequentialTimings = {
                    -- How close the value is to the Timeout value determines how fast the script moves to the next animation.
                    [1] = 5, -- start animation Timeout ==> 1sec(6s-5s) to loop 
                    [2] = 0, -- loop animation Timeout  ==> 6sec(6s-0s) to exit
                    [3] = 2, -- exit animation Timeout  ==> 4sec(6s-2s) to end
                    step = 1,
                    Timeout = 6
                }
            })
            Wait(10000)
            QBCore.Functions.Notify('test tricks paw', 'error', 1500)
            Animator(activePed.entity, activePed.model, 'tricks', 'paw')
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
    -- local doesPlayerHavePet = ActivePed:read() or {}
    -- if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not PlayerData.metadata["ishandcuffed"] and
    --     not IsPauseMenuActive() and not inRadialMenu and next(doesPlayerHavePet) ~= nil then
    --     SetCursorLocation(0.5, 0.5)
    --     setRadialState(true, true)
    -- elseif next(doesPlayerHavePet) == nil then
    --     TriggerEvent('QBCore:Notify', "you must have atleast one active pet to access to menu")
    -- end

    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not PlayerData.metadata["ishandcuffed"] and
        not IsPauseMenuActive() and not inRadialMenu then
        SetCursorLocation(0.5, 0.5)
        setRadialState(true, true)
    end
end, false)

RegisterKeyMapping('+showMenu', 'show pet menu', 'keyboard', 'o')
