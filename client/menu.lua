QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

local isMenuOpen = false

local menu = {
    ['Follow'] = {
        lable = 'Follow',
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            TaskFollowTargetedPlayer(activePed.entity, plyped, 3.0)
        end
    },
    ['Hunt'] = {
        lable = 'Hunt',
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
    ['HuntandGrab'] = {
        lable = 'Hunt and Grab',
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
    ['There'] = {
        lable = 'Go there',
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            goThere(activePed.entity)
        end
    },
    ['Wait'] = {
        lable = 'Wait',
        action = function(plyped, activePed)
            ClearPedTasks(activePed.entity)
        end
    },
    ['GetinCar'] = {
        lable = 'Get in Car',
        action = function(plyped, activePed)
            getIntoCar()
        end
    },
    ['Tricks'] = {
        lable = 'Tricks',
        action = function(plyped, activePed)

            if Animator(activePed.entity, activePed.model, 'tricks', {
                animation = 'beg',
                sequentialTimings = {
                    -- How close the value is to the Timeout value determines how fast the script moves to the next animation.
                    [1] = 5, -- start animation Timeout ==> 1sec(6s-5s) to loop 
                    [2] = 0, -- loop animation Timeout  ==> 6sec(6s-0s) to exit
                    [3] = 2, -- exit animation Timeout  ==> 4sec(6s-2s) to end
                    step = 1,
                    Timeout = 6
                }
            }) == false then
                QBCore.Functions.Notify('this pet can not do that', 'error', 1500)
            else
                QBCore.Functions.Notify('test tricks beg', 'error', 1500)
            end
            Wait(10000)
            if Animator(activePed.entity, activePed.model, 'tricks', {
                animation = 'paw'
            }) == false then
                QBCore.Functions.Notify('this pet can not do that', 'error', 1500)
            else
                QBCore.Functions.Notify('test tricks paw', 'error', 1500)
            end
        end
    }
}

-- Command
AddEventHandler('keep-companion:client:menuActionDispatcher', function(option)
    local plyped = PlayerPedId()
    local activePed = ActivePed.read()
    for key, func in pairs(menu) do
        if option.type == key then
            func.action(plyped, activePed)
        end
    end
end)

AddEventHandler('keep-companion:client:MainMenu', function()
    local header = "name: " .. ActivePed.read().itemData.info.name
    local leave = "leave"

    -- header
    local openMenu = {{
        header = header,
        isMenuHeader = true
    }}

    -- actions
    for key, value in pairs(menu) do
        openMenu[#openMenu + 1] = {
            header = value.lable,
            txt = value.desc or nil,
            params = {
                event = "keep-companion:client:EventDispatcher",
                args = {
                    type = key
                }
            }
        }
    end

    -- leave menu
    openMenu[#openMenu + 1] = {
        header = leave,
        txt = "",
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end)

local function IsPoliceOrEMS()
    return (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance")
end

local function IsDowned()
    return (PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"])
end

RegisterKeyMapping('+showMenu', 'show pet menu', 'keyboard', Config.Settings.petMenuKeybind)
RegisterCommand('+showMenu', function()
    local doesPlayerHavePet = ActivePed:read() or {}
    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not PlayerData.metadata["ishandcuffed"] and
        not IsPauseMenuActive() and not isMenuOpen and next(doesPlayerHavePet) ~= nil then
        TriggerEvent('keep-companion:client:MainMenu')
    elseif next(doesPlayerHavePet) == nil then
        TriggerEvent('QBCore:Notify', "you must have atleast one active pet to access to menu")
    end

    -- if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not PlayerData.metadata["ishandcuffed"] and
    --     not IsPauseMenuActive() and not isMenuOpen then
    --     SetCursorLocation(0.5, 0.5)
    --     setRadialState(true, true)
    -- end
end, false)

-- This will update all the PlayerData that doesn't get updated with a specific event other than this like the metadata
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

