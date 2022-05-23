QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

local isMenuOpen = false

local menu = {
    [1] = {
        lable = Lang:t('menu.follow'),
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
        lable = Lang:t('menu.hunt'),
        TYPE = 'Hunt',
        triggerNotification = { 'PETNAME is now hunting!', 'PETNAME can not do that!' },
        action = function(plyped, activePed)
            local min_lvl_to_hunt = Config.Settings.minHuntingAbilityLevel
            if activePed.canHunt ~= true then
                QBCore.Functions.Notify(Lang:t('info.pet_unable_to_hunt'), 'primary', 5000)
                return false
            end

            if activePed.level <= min_lvl_to_hunt then
                local msg = Lang:t('error.not_meet_min_requirement_to_hunt')
                msg = string.format(msg, min_lvl_to_hunt)
                QBCore.Functions.Notify(msg, 'error', 5000)
                return false
            end

            doSomethingIfPedIsInsideVehicle(activePed.entity)
            if attackLogic() ~= true then
                return false
            end
            return true
        end
    },
    [3] = {
        lable = Lang:t('menu.hunt_and_grab'),
        TYPE = 'HuntandGrab',
        action = function(plyped, activePed)
            local min_lvl_to_hunt = Config.Settings.minHuntingAbilityLevel
            if activePed.canHunt ~= true then
                QBCore.Functions.Notify(Lang:t('info.pet_unable_to_hunt'), 'primary', 5000)
                return false
            end

            if activePed.level <= min_lvl_to_hunt then
                local msg = Lang:t('error.not_meet_min_requirement_to_hunt')
                msg = string.format(msg, min_lvl_to_hunt)
                QBCore.Functions.Notify(msg, 'error', 5000)
                return false
            end

            doSomethingIfPedIsInsideVehicle(activePed.entity)
            HuntandGrab(plyped, activePed)
            return true
        end
    },
    [4] = {
        lable = Lang:t('menu.go_there'),
        TYPE = 'There',
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            goThere(activePed.entity)
        end
    },
    [5] = {
        lable = Lang:t('menu.wait'),
        TYPE = 'Wait',
        action = function(plyped, activePed)
            ClearPedTasks(activePed.entity)
        end
    },
    [6] = {
        lable = Lang:t('menu.get_in_car'),
        TYPE = 'GetinCar',
        action = function(plyped, activePed)
            getIntoCar()
        end
    }
}

local menu2 = {
    [1] = {
        lable = Lang:t('menu.beg'),
        TYPE = 'Beg',
        icon = 'fa-solid fa-arrows-rotate',
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
        lable = Lang:t('menu.paw'),
        TYPE = 'Paw',
        icon = 'fa-solid fa-paw',
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

function get_correct_icon(model)
    for key, value in pairs(Config.pets) do
        if model == value.model then
            for w in value.distinct:gmatch("%S+") do
                if w == 'dog' then
                    return 'fa-solid fa-dog'
                end
            end
        end
    end
    return 'fa-solid fa-cat'
end

AddEventHandler('keep-companion:client:PetMenu', function()
    local name = ActivePed.read().itemData.info.name
    local model = ActivePed.read().model
    local icon = get_correct_icon(model)

    local header = string.format(Lang:t('menu.pet_name'), name)
    local sub_header = Lang:t('menu.menu_pet_main_sub_header')

    -- header
    local openMenu = { {
        header = header,
        txt = sub_header,
        icon = icon,
        isMenuHeader = true
    }, {
        header = Lang:t('menu.menu_btn_actions'),
        icon = 'fa-solid fa-circle-play',
        params = {
            event = "keep-companion:client:petMenuActions"
        }
    }, {
        header = Lang:t('menu.menu_btn_switchcontroll'),
        txt = "",
        icon = 'fa-solid fa-repeat',
        params = {
            event = "keep-companion:client:switchControl"
        }
    }, {
        header = Lang:t('menu.menu_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    } }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:petMenuActions', function()
    local name = ActivePed.read().itemData.info.name
    local header = string.format(Lang:t('menu.pet_name'), name)
    local header_tricks = Lang:t('menu.menu_header_tricks')
    local sub_header = Lang:t('menu.menu_pet_main_sub_header')
    local model = ActivePed.read().model
    local icon = get_correct_icon(model)

    -- header
    local openMenu = {
        {
            header = Lang:t('menu.menu_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:PetMenu",
            }
        },
        {
            header = header,
            txt = sub_header,
            icon = icon,
            isMenuHeader = true
        }
    }

    for key, value in pairs(menu) do
        openMenu[#openMenu + 1] = {
            header = value.lable,
            icon = 'fa-solid fa-' .. key,
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
        header = header_tricks,
        icon = 'fa-solid fa-' .. #openMenu - 1,
        txt = "",
        params = {
            event = "keep-companion:client:Tricks"
        }
    }

    -- leave menu
    openMenu[#openMenu + 1] = {
        header = Lang:t('menu.menu_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:Tricks', function()
    local name = ActivePed.read().itemData.info.name
    local header = string.format(Lang:t('menu.pet_name'), name)
    local sub_header = Lang:t('menu.menu_pet_main_sub_header')
    local model = ActivePed.read().model
    local icon = get_correct_icon(model)

    -- header
    local openMenu = {
        {
            header = Lang:t('menu.menu_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:petMenuActions",
            }
        },
        {
            header = header,
            txt = sub_header,
            icon = icon,
            isMenuHeader = true
        }
    }

    for key, value in pairs(menu2) do
        openMenu[#openMenu + 1] = {
            header = value.lable,
            txt = value.desc or "",
            icon = value.icon,
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
        header = Lang:t('menu.menu_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:switchControl', function()
    local header = Lang:t('menu.manu_switch_header')
    local sub_header = Lang:t('menu.manu_switch_sub_header')

    -- header
    local openMenu = {
        {
            header = Lang:t('menu.menu_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:PetMenu",
            }
        },
        {
            header = header,
            txt = sub_header,
            icon = 'fa-solid fa-list-check',
            isMenuHeader = true
        }
    }

    for key, value in pairs(ActivePed:petsList()) do
        openMenu[#openMenu + 1] = {
            header = value.name,
            icon = 'fa-solid fa-' .. key,
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
        header = Lang:t('menu.menu_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:switchControlOfPet', function(option)
    if option.index < 0 then
        return
    end
    ActivePed:switchControl(option.index)
    TriggerEvent('keep-companion:client:petMenuActions')
end)

local function IsPoliceOrEMS()
    return (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance")
end

local function IsDowned()
    return (PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"])
end

local function Ishandcuffed()
    return PlayerData.metadata["ishandcuffed"]
end

RegisterKeyMapping('+showMenu', 'show pet menu', 'keyboard', Config.Settings.petMenuKeybind)
RegisterCommand('+showMenu', function()
    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not Ishandcuffed() and not IsPauseMenuActive() and not isMenuOpen then
        local doesPlayerHavePet = ActivePed:read()

        if doesPlayerHavePet == nil then
            QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
            return
        end
        TriggerEvent('keep-companion:client:PetMenu')
    end
end, false)

-- This will update all the PlayerData that doesn't get updated with a specific event other than this like the metadata
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)
