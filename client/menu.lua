QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

local isMenuOpen = false

local menu = {
    [1] = {
        lable = 'Follow',
        TYPE = 'Follow',
        -- triggerNotification = {'onSuccess', 'onFailed'},
        -- and action should retrun a bool value true == onSuccess ,false == onFailed
        triggerNotification = { 'PETNAME is now following you!', 'PETNAME failed to follow you!' },
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            TaskFollowTargetedPlayer(activePed.entity, plyped, 3.0)
            return true
        end
    },
    [2] = {
        lable = 'Hunt',
        TYPE = 'Hunt',
        triggerNotification = { 'PETNAME is now hunting!', 'PETNAME can not do that!' },
        action = function(plyped, activePed)
            if activePed.canHunt == true then
                if activePed.level >= Config.Settings.minHuntingAbilityLevel then
                    doSomethingIfPedIsInsideVehicle(activePed.entity)
                    if attackLogic() == true then
                        return true
                    else
                        return false
                    end
                else
                    TriggerEvent('QBCore:Notify',
                        "Not enough levels to hunt (min " .. Config.Settings.minHuntingAbilityLevel .. ')')
                    return false
                end
            else
                TriggerEvent('QBCore:Notify', "Your pet can't hunt!")
                return false
            end
        end
    },
    [3] = {
        lable = 'Hunt and Grab',
        TYPE = 'HuntandGrab',
        action = function(plyped, activePed)
            if activePed.canHunt == true then
                if activePed.level >= Config.Settings.minHuntingAbilityLevel then
                    doSomethingIfPedIsInsideVehicle(activePed.entity)
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
        lable = 'Go there',
        TYPE = 'There',
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            goThere(activePed.entity)
        end
    },
    [5] = {
        lable = 'Wait',
        TYPE = 'Wait',
        action = function(plyped, activePed)
            ClearPedTasks(activePed.entity)
        end
    },
    [6] = {
        lable = 'Get in Car',
        TYPE = 'GetinCar',
        action = function(plyped, activePed)
            getIntoCar()
        end
    }
}

local menu2 = {
    [1] = {
        lable = 'Beg',
        TYPE = 'Beg',
        action = function(plyped, activePed)
            if Animator(activePed.entity, activePed.model, 'tricks', {
                animation = 'beg',
                sequentialTimings = {
                    -- How close the value is to the Timeout value determines how fast the script moves to the next animation.
                    [1] = 6, -- start animation Timeout ==> 1sec(6s-5s) to loop
                    [2] = 0, -- loop animation Timeout  ==> 6sec(6s-0s) to exit
                    [3] = 2, -- exit animation Timeout  ==> 4sec(6s-2s) to end
                    step = 1,
                    Timeout = 6
                }
            }) == false then
                QBCore.Functions.Notify('this pet can not do that', 'error', 1500)
            else
                QBCore.Functions.Notify('Start', 'success', 1500)
            end
        end
    },
    [2] = {
        lable = 'TEST',
        TYPE = 'TEST',
        action = function(plyped, activePed)
            local isInVehicle = IsPedInAnyVehicle(activePed.entity, true)
            print(isInVehicle)
            variationTester(activePed.entity, 0)
        end
    },
    [3] = {
        lable = 'Paw',
        TYPE = 'Paw',
        action = function(plyped, activePed)
            if Animator(activePed.entity, activePed.model, 'tricks', {
                animation = 'paw'
            }) == false then
                QBCore.Functions.Notify('this pet can not do that', 'error', 1500)
            else
                QBCore.Functions.Notify('Start', 'success', 1500)
            end
        end
    }
}

local function replaceString(s)
    local x
    x = s:gsub("PETNAME", ActivePed.read().itemData.info.name)
    return x
end

-- Command
AddEventHandler('keep-companion:client:actionMenuDispatcher', function(option)
    local plyped = PlayerPedId()
    local activePed = ActivePed.read()
    for key, values in pairs(option.menu) do
        if option.type == values.TYPE then
            if values.action(plyped, activePed) == true then
                if values.triggerNotification ~= nil then
                    QBCore.Functions.Notify(replaceString(values.triggerNotification[1]), 'success', 1500)
                end
            else
                if values.triggerNotification ~= nil then
                    QBCore.Functions.Notify(replaceString(values.triggerNotification[2]))
                end
            end
        end
    end
end)

AddEventHandler('keep-companion:client:PetMenu', function()
    local header = "Name: " .. ActivePed.read().itemData.info.name
    local leave = "leave"

    -- header
    local openMenu = { {
        header = header,
        txt = "pet under control",
        isMenuHeader = true
    }, {
        header = 'Actions',
        params = {
            event = "keep-companion:client:petMenuActions"
        }
    }, {
        header = 'switchControl',
        txt = "",
        params = {
            event = "keep-companion:client:switchControl"
        }
    }, {
        header = leave,
        txt = "",
        params = {
            event = "qb-menu:closeMenu"
        }
    } }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:petMenuActions', function(option)
    local header = "name: " .. ActivePed.read().itemData.info.name
    local leave = "leave"

    -- header
    local openMenu = { {
        header = header,
        isMenuHeader = true
    } }

    for key, value in pairs(menu) do
        openMenu[#openMenu + 1] = {
            header = value.lable,
            txt = value.desc or "",
            params = {
                event = "keep-companion:client:actionMenuDispatcher",
                args = {
                    type = value.TYPE,
                    menu = menu
                }
            }
        }
    end

    openMenu[#openMenu + 1] = {
        header = 'Tricks',
        txt = "",
        params = {
            event = "keep-companion:client:Tricks"
        }
    }

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

AddEventHandler('keep-companion:client:Tricks', function(option)
    local header = "name: " .. ActivePed.read().itemData.info.name
    local leave = "leave"

    -- header
    local openMenu = { {
        header = header,
        isMenuHeader = true
    } }

    for key, value in pairs(menu2) do
        openMenu[#openMenu + 1] = {
            header = value.lable,
            txt = value.desc or "",
            params = {
                event = "keep-companion:client:actionMenuDispatcher",
                args = {
                    type = value.TYPE,
                    menu = menu2
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

AddEventHandler('keep-companion:client:switchControl', function(option)
    local header = "Switch pet on Control"
    local leave = "leave"

    -- header
    local openMenu = { {
        header = header,
        isMenuHeader = true
    } }

    for key, value in pairs(ActivePed:petsList()) do
        openMenu[#openMenu + 1] = {
            header = value.name,
            params = {
                event = "keep-companion:client:switchControlOfPet",
                args = {
                    index = value.key
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

AddEventHandler('keep-companion:client:switchControlOfPet', function(option)
    if option.index > 0 then
        ActivePed:switchControl(option.index)
        TriggerEvent('keep-companion:client:petMenuActions')
    end
end)

local function IsPoliceOrEMS()
    return (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance")
end

local function IsDowned()
    return (PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"])
end

RegisterKeyMapping('+showMenu', 'show pet menu', 'keyboard', Config.Settings.petMenuKeybind)
RegisterCommand('+showMenu', function()
    local doesPlayerHavePet = ActivePed:read()
    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not PlayerData.metadata["ishandcuffed"] and
        not IsPauseMenuActive() and not isMenuOpen and doesPlayerHavePet ~= nil then
        TriggerEvent('keep-companion:client:PetMenu')
    elseif doesPlayerHavePet == nil then
        TriggerEvent('QBCore:Notify', "you must have atleast one active pet to access to menu")
    end
end, false)

-- This will update all the PlayerData that doesn't get updated with a specific event other than this like the metadata
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)
