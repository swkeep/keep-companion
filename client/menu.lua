QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData()

local isMenuOpen = false
local alreadyHunting = {
    state = false
}

local menu = {
    [1] = {
        lable = Lang:t('menu.follow'),
        TYPE = 'Follow',
        -- triggerNotification = {'onSuccess', 'onFailed'},
        -- and action should retrun a bool value true == onSuccess ,false == onFailed
        triggerNotification = { 'PETNAME is now following you!', 'PETNAME failed to follow you!' },
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            return TaskFollowTargetedPlayer(activePed.entity, plyped, 3.0, false)
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

            if alreadyHunting.state ~= false then
                local msg = 'Aleardy hunting something'
                QBCore.Functions.Notify(msg, 'error', 5000)
                return
            end

            if activePed.level <= min_lvl_to_hunt then
                local msg = Lang:t('error.not_meet_min_requirement_to_hunt')
                msg = string.format(msg, min_lvl_to_hunt)
                QBCore.Functions.Notify(msg, 'error', 5000)
                return false
            end

            doSomethingIfPedIsInsideVehicle(activePed.entity)
            return attackLogic(alreadyHunting)
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
            doSomethingIfPedIsInsideVehicle(activePed.entity)
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
    activePed.entity = NetworkGetEntityFromNetworkId(activePed.netId)
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

-- =======================================
--           Customization menu
-- =======================================

RegisterNetEvent('keep-companion:client:initialization_process', function(item, pet_information)
    if type(item) ~= "table" then
        QBCore.Functions.Notify(Lang:t('error.failed_to_start_procces'), 'error', 5000)
        return
    end
    TriggerEvent('keep-companion:client:openMenu_customization', {
        item = item, pet_information = pet_information
    })
end)

AddEventHandler('keep-companion:client:openMenu_customization', function(data)
    openMenu_customization(data)
end)

AddEventHandler('keep-companion:client:openMenu_customization_rename', function(data)
    openMenu_customization_rename(data)
end)

local function rename(data)
    local inputData = exports['qb-input']:ShowInput(
        {
            header = "Type new name",
            submitText = "Confirm",
            inputs = {
                {
                    type = 'text',
                    isRequired = true,
                    name = 'name',
                    text = "name"
                },
            }
        }
    )
    if inputData then
        if not inputData.name then
            return
        end
        local validation = ValidatePetName(inputData.name, 12)

        if type(validation) == "table" and next(validation) ~= nil then
            QBCore.Functions.Notify(Lang:t('error.failed_to_validate_name'), 'error', 5000)
            if validation.reason == 'badword' then
                QBCore.Functions.Notify(Lang:t('error.badword_inside_pet_name'), 'error', 5000)
                print_table(validation.words)
                TriggerEvent('keep-companion:client:openMenu_customization_rename', data)
                return
            elseif validation.reason == 'maxCharacter' then
                QBCore.Functions.Notify(Lang:t('error.more_than_one_word_as_name'), 'error', 5000)
                TriggerEvent('keep-companion:client:openMenu_customization_rename', data)
                return
            end
            return
        end

        data.item.info.name = inputData.name
        TriggerEvent('keep-companion:client:openMenu_customization_rename', data)
    end
end

AddEventHandler('keep-companion:client:openMenu_customization_rename:rename', function(data)
    rename(data)
end)

AddEventHandler('keep-companion:client:openMenu_customization_select_variation', function(data)
    if data.selected ~= nil then
        data.item.info.variation = data.selected
    end
    openMenu_customization_select_variation(data)
end)

local function change_variation(data)
    local item = data.item
    local pet_information = data.pet_information

    local openMenu = {
        {
            header = Lang:t('menu.menu_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:openMenu_customization_select_variation",
                args = {
                    item = item,
                    pet_information = pet_information
                }
            }
        },
        {
            header = 'Variation list',
            icon = 'fa-solid fa-rectangle-list',
            isMenuHeader = true
        },
    }

    for key, value in pairs(pet_information.pet_variation_list) do
        openMenu[#openMenu + 1] = {
            header = 'Variation: ' .. value,
            txt = 'select to take effect',
            icon = 'fa-solid fa-brush',
            params = {
                event = "keep-companion:client:openMenu_customization_select_variation",
                args = {
                    selected = value,
                    item = item,
                    pet_information = pet_information
                }
            }
        }
    end

    exports['qb-menu']:openMenu(openMenu)
end

AddEventHandler('keep-companion:client:openMenu_customization_variation:variation_menu', function(data)
    change_variation(data)
end)

-- customization menu
function openMenu_customization(data)
    -- header
    local c_name = data.item.info.name
    local c_variation = data.item.info.variation

    local openMenu = {
        {
            header = 'Customization menu',
            icon = 'fa-solid fa-pen-to-square',
            isMenuHeader = true
        },
        {
            header = 'Rename',
            txt = 'current name: ' .. c_name,
            icon = 'fa-regular fa-keyboard',
            params = {
                event = "keep-companion:client:openMenu_customization_rename",
                args = {
                    item = data.item,
                    pet_information = data.pet_information
                },
            }
        },
        {
            header = 'Select variation',
            txt = 'current color: ' .. c_variation,
            icon = 'fa-solid fa-brush',
            params = {
                event = "keep-companion:client:openMenu_customization_select_variation",
                args = {
                    item = data.item,
                    pet_information = data.pet_information
                },
            }
        },
        {
            header = 'Confirm',
            icon = 'fa-solid fa-circle-check',
            params = {
                event = "keep-companion:client:openMenu_customization:confirm",
                args = {
                    item = data.item,
                    pet_information = data.pet_information
                }
            }
        },
        {
            header = Lang:t('menu.menu_leave'),
            txt = "",
            icon = 'fa-solid fa-circle-xmark',
            params = {
                event = "qb-menu:closeMenu"
            }
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end

function openMenu_customization_rename(data)
    local item = data.item
    local pet_information = data.pet_information

    local c_name = item.info.name
    -- header
    local openMenu = {
        {
            header = Lang:t('menu.menu_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:openMenu_customization",
                args = {
                    item = item,
                    pet_information = pet_information
                },
            }
        },
        {
            header = 'Current name',
            icon = 'fa-solid fa-pen-to-square',
            txt = c_name,
            isMenuHeader = true,
            disabled = true
        },
        {
            header = 'Rename',
            icon = 'fa-regular fa-keyboard',
            params = {
                event = "keep-companion:client:openMenu_customization_rename:rename",
                args = {
                    item = item,
                    pet_information = pet_information
                },
            }
        },
    }

    exports['qb-menu']:openMenu(openMenu)
end

function openMenu_customization_select_variation(data)
    -- header
    local item = data.item
    local pet_information = data.pet_information

    local openMenu = {
        {
            header = Lang:t('menu.menu_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:openMenu_customization",
                args = {
                    item = item,
                    pet_information = pet_information
                }
            }
        },
        {
            header = 'Current color',
            txt = item.info.variation,
            icon = 'fa-solid fa-palette',
            isMenuHeader = true,
            disabled = true
        },
        {
            header = 'Select variation',
            txt = 'choice color of you pet',
            icon = 'fa-solid fa-brush',
            params = {
                event = "keep-companion:client:openMenu_customization_variation:variation_menu",
                args = {
                    item = item,
                    pet_information = pet_information
                }
            }
        },
    }

    exports['qb-menu']:openMenu(openMenu)
end

AddEventHandler('keep-companion:client:openMenu_customization:confirm', function(data)
    TriggerServerEvent('keep-companion:server:compelete_initialization_process', data.item)
end)
