QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

local menu = Config.RadialMeneu
local names = {}
local inRadialMenu = false

RegisterNetEvent("onResourceStart", function()
    Wait(100)
    for key, name in pairs(Config.RadialMeneu) do
        names[key] = name.lable
    end
    SendNUIMessage({
        type = "ui",
        display = false,
        initData = names,
        customKey = Config.WheelHotKey
    })
    PlayerData = QBCore.Functions.GetPlayerData()
end)

-- Sets the metadata when the player spawns
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(100)
    PlayerData = QBCore.Functions.GetPlayerData()
    for key, name in pairs(Config.RadialMeneu) do
        names[key] = name.lable
    end
    SendNUIMessage({
        type = "ui",
        display = false,
        initData = names,
        customKey = Config.WheelHotKey
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
