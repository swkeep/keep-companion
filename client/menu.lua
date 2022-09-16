QBCore = exports['qb-core']:GetCoreObject()

local isMenuOpen = false
PlayerData = nil
PlayerJob = nil

local alreadyHunting = {
    state = false
}

local function updatePlayerJob()
    repeat
        Wait(10)
    until QBCore.Functions.GetPlayerData().job ~= nil
    PlayerJob = QBCore.Functions.GetPlayerData().job
end

local function isModelK9(model)
    for key, k9 in pairs(Config.k9.models) do
        if model == k9 then
            return true
        end
    end
    return false
end

-- action menu
local menu = {
    [1] = {
        lable = Lang:t('menu.action_menu.follow'),
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
        lable = Lang:t('menu.action_menu.hunt'),
        TYPE = 'Hunt',
        triggerNotification = { 'PETNAME is now hunting!', 'PETNAME can not do that!' },
        action = function(plyped, activePed)
            local min_lvl_to_hunt = Config.Settings.minHuntingAbilityLevel
            if activePed.canHunt ~= true then
                QBCore.Functions.Notify(Lang:t('menu.action_menu.error.pet_unable_to_hunt'), 'error', 5000)
                return false
            end

            if alreadyHunting.state ~= false then
                QBCore.Functions.Notify(Lang:t('menu.action_menu.error.already_hunting_something'), 'error', 5000)
                return
            end

            if activePed.itemData.info.level <= min_lvl_to_hunt then
                local msg = Lang:t('menu.action_menu.error.not_meet_min_requirement_to_hunt')
                msg = string.format(msg, min_lvl_to_hunt)
                QBCore.Functions.Notify(msg, 'error', 5000)
                return false
            end

            doSomethingIfPedIsInsideVehicle(activePed.entity)
            return attackLogic(alreadyHunting)
        end
    },
    [3] = {
        lable = Lang:t('menu.action_menu.hunt_and_grab'),
        TYPE = 'HuntandGrab',
        action = function(plyped, activePed)
            local min_lvl_to_hunt = Config.Settings.minHuntingAbilityLevel
            if activePed.canHunt ~= true then
                QBCore.Functions.Notify(Lang:t('menu.action_menu.error.pet_unable_to_hunt'), 'error', 5000)
                return false
            end

            if activePed.itemData.info.level <= min_lvl_to_hunt then
                local msg = Lang:t('menu.action_menu.error.not_meet_min_requirement_to_hunt')
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
        lable = Lang:t('menu.action_menu.go_there'),
        TYPE = 'There',
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            goThere(activePed.entity)
        end
    },
    [5] = {
        lable = Lang:t('menu.action_menu.wait'),
        TYPE = 'Wait',
        action = function(plyped, activePed)
            doSomethingIfPedIsInsideVehicle(activePed.entity)
            ClearPedTasks(activePed.entity)
        end
    },
    [6] = {
        lable = Lang:t('menu.action_menu.get_in_car'),
        TYPE = 'GetinCar',
        action = function(plyped, activePed)
            getIntoCar()
        end
    },
    [7] = {
        lable = 'Search Person',
        TYPE = 'SearchPerson',
        action = function(plyped, activePed)
            SearchLogic(plyped, activePed)
        end
    },
    [8] = {
        lable = 'Search Car',
        TYPE = 'SearchCar',
        show = function(activePed)
            if not PlayerJob then return false end
            if not (PlayerJob.name == 'police') then return false end
            return isModelK9(activePed.model)
        end,
        action = function(plyped, activePed)
            local vehicle = QBCore.Functions.GetClosestVehicle()
            k9SearchVehicle(vehicle, activePed)
        end
    }
}

local coo = {
    [1] = {
        offset = vector4(-1.5, 0.0, 0.0, -90.0),
    },
    [2] = {
        offset = vector4(0.0, -2.8, 0.0, 0.0),
    },
    -- [3] = {
    --     offset = vector4(1.5, 0.0, 0.0, -270.0),
    -- },
}

function k9SearchVehicle(veh, activePed)
    if not isModelK9(activePed.model) then
        QBCore.Functions.Notify('This pet can not do that!', "error", 1500)
        return
    end
    if not PlayerJob then return end
    if not (PlayerJob.name == 'police') then
        QBCore.Functions.Notify('You are not allowed to do this action', "error", 1500)
        return
    end

    if not PlayerJob.onduty == true then
        QBCore.Functions.Notify('You Must be on duty to do this action', "error", 1500)
        return
    end

    for key, value in pairs(coo) do
        local vehHead = GetEntityHeading(veh)
        local plate = GetVehicleNumberPlateText(veh)
        local pos = GetOffsetFromEntityInWorldCoords(veh, value.offset.x, value.offset.y, value.offset.z)
        TaskFollowNavMeshToCoord(activePed.entity, pos, 3.0, -1, 0.0, true, 0)
        Wait(4000)
        TaskAchieveHeading(activePed.entity, vehHead + value.offset.w, -1)
        Wait(2000)
        QBCore.Functions.TriggerCallback('keep-companion:server:search_vehicle', function(result)
            if result then
                SetAnimalMood(activePed.entity, 1)
                PlayAnimalVocalization(activePed.entity, 3, 'bark')
                Animator(activePed.entity, activePed.model, 'misc', {
                    animation = 'indicate_high',
                    sequentialTimings = {
                        -- How close the value is to the Timeout value determines how fast the script moves to the next animation.
                        [1] = 6, -- start animation Timeout ==> 1sec(6s-5s) to loop
                        [2] = 0, -- loop animation Timeout  ==> 6sec(6s-0s) to exit
                        [3] = 2, -- exit animation Timeout  ==> 4sec(6s-2s) to end
                        step = 1,
                        Timeout = 6
                    }
                })
                return
            end
            Animator(activePed.entity, activePed.model, 'siting', {
                animation = 'sit',
                sequentialTimings = {
                    -- How close the value is to the Timeout value determines how fast the script moves to the next animation.
                    [1] = 6, -- start animation Timeout ==> 1sec(6s-5s) to loop
                    [2] = 0, -- loop animation Timeout  ==> 6sec(6s-0s) to exit
                    [3] = 2, -- exit animation Timeout  ==> 4sec(6s-2s) to end
                    step = 1,
                    Timeout = 6
                }
            })
        end, {
            key = key,
            plate = plate
        })
        Wait(3000)
    end
end

function k9EnterVehicle(k9, veh)
    local vehCoords = GetEntityCoords(veh)
    local forwardX = GetEntityForwardX(veh) * 2.0
    local forwardY = GetEntityForwardY(veh) * 2.0

    SetVehicleDoorOpen(veh, 5, false)
    TaskFollowNavMeshToCoord(k9, vehCoords.x - forwardX, vehCoords.y - forwardY, vehCoords.z, 4.0, -1, 1.0, 1, 1)
    Wait(5000)
    TaskAchieveHeading(k, GetEntityHeading(veh), -1)
    RequestAnimDict("creatures@rottweiler@in_vehicle@van", true)
    RequestAnimDict("creatures@rottweiler@amb@world_dog_sitting@base", true)
    while not HasAnimDictLoaded("creatures@rottweiler@in_vehicle@van") or
        not HasAnimDictLoaded("creatures@rottweiler@amb@world_dog_sitting@base") do
        Citizen.Wait(0)
    end
    TaskPlayAnim(k9, "creatures@rottweiler@in_vehicle@van", "get_in", 8.0, -4.0, -1, 2, 0.0, false, false, false)
    Wait(1100)
    ClearPedTasks(k9)
    AttachEntityToEntity(k9, veh, GetEntityBoneIndexByName(veh, "chassis"), 0.0, -0.8, 0.6, 0.0, 0.0, 0.0, false, false,
        false, false, 0, true)
    TaskPlayAnim(k9, "creatures@rottweiler@amb@world_dog_sitting@base", "base", 8.0, -4.0, -1, 1, 0.0, false, false,
        false)
    Wait(500)
    SetVehicleDoorShut(veh, 5, false)
end

-- tricks menu
local menu2 = {
    [1] = {
        lable = Lang:t('menu.action_menu.beg'),
        TYPE = 'Beg',
        icon = 'fa-solid fa-arrows-rotate',
        action = function(plyped, activePed)
            Animator(activePed.entity, activePed.model, 'tricks', {
                animation = 'beg',
                sequentialTimings = {
                    -- How close the value is to the Timeout value determines how fast the script moves to the next animation.
                    [1] = 6, -- start animation Timeout ==> 1sec(6s-5s) to loop
                    [2] = 0, -- loop animation Timeout  ==> 6sec(6s-0s) to exit
                    [3] = 2, -- exit animation Timeout  ==> 4sec(6s-2s) to end
                    step = 1,
                    Timeout = 6
                }
            })
        end
    },
    [2] = {
        lable = Lang:t('menu.action_menu.paw'),
        TYPE = 'Paw',
        icon = 'fa-solid fa-paw',
        action = function(plyped, activePed)
            Animator(activePed.entity, activePed.model, 'tricks', {
                animation = 'paw'
            })
        end
    },
    [3] = {
        lable = Lang:t('menu.action_menu.play_dead'),
        TYPE = 'Playdead',
        icon = 'fa-solid fa-face-dizzy',
        action = function(plyped, activePed)
            -- PlayFacialAnim(activePed.entity, "dying_facial", "creatures@rottweiler@move")
            Animator(activePed.entity, activePed.model, 'misc', {
                animation = 'play_dead',
                c_timings = 'STOP_LAST_FRAME'
            })
        end
    },
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
                elseif w == 'rabbit' then
                    return 'fa-solid fa-paw'
                elseif w == 'hen' then
                    return 'fa-solid fa-kiwi-bird'
                end
            end
        end
    end
    return 'fa-solid fa-cat'
end

AddEventHandler('keep-companion:client:main_menu', function()
    local name = ActivePed.read().itemData.info.name
    local model = ActivePed.read().model
    local icon = get_correct_icon(model)
    local header = string.format(Lang:t('menu.main_menu.header'), name)
    local sub_header = Lang:t('menu.main_menu.sub_header')

    -- header
    local openMenu = { {
        header = header,
        txt = sub_header,
        icon = icon,
        isMenuHeader = true
    }, {
        header = Lang:t('menu.main_menu.btn_actions'),
        icon = 'fa-solid fa-circle-play',
        params = {
            event = "keep-companion:client:action_menu"
        }
    }, {
        header = Lang:t('menu.main_menu.btn_switchcontrol'),
        txt = "",
        icon = 'fa-solid fa-repeat',
        params = {
            event = "keep-companion:client:switchControl_menu"
        }
    }, {
        header = Lang:t('menu.general_menu_items.btn_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    } }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:action_menu', function()
    local name = ActivePed.read().itemData.info.name
    local header = string.format(Lang:t('menu.action_menu.header'), name)
    local sub_header = Lang:t('menu.action_menu.sub_header')
    local model = ActivePed.read().model
    local icon = get_correct_icon(model)

    -- header
    local openMenu = {
        {
            header = Lang:t('menu.general_menu_items.btn_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:main_menu",
            }
        },
        {
            header = header,
            txt = sub_header,
            icon = icon,
            isMenuHeader = true
        }
    }

    for key, value in ipairs(menu) do
        if value.show then
            if not value.show(ActivePed.read()) then
                goto here
            end
        end
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
        ::here::
    end

    openMenu[#openMenu + 1] = {
        header = Lang:t('menu.action_menu.tricks'),
        icon = 'fa-solid fa-' .. #openMenu - 1,
        txt = "",
        params = {
            event = "keep-companion:client:tricks_menu"
        }
    }

    -- leave menu
    openMenu[#openMenu + 1] = {
        header = Lang:t('menu.general_menu_items.btn_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:tricks_menu', function()
    local name = ActivePed.read().itemData.info.name
    local header = string.format(Lang:t('menu.tricks.header'), name)
    local sub_header = Lang:t('menu.tricks.sub_header')
    local model = ActivePed.read().model
    local icon = get_correct_icon(model)

    -- header
    local openMenu = {
        {
            header = Lang:t('menu.general_menu_items.btn_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:action_menu",
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
        header = Lang:t('menu.general_menu_items.btn_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:switchControl_menu', function()
    local name = ActivePed.read().itemData.info.name
    local header = string.format(Lang:t('menu.switchControl_menu.header'), name)
    local sub_header = name

    -- header
    local openMenu = {
        {
            header = Lang:t('menu.general_menu_items.btn_back'),
            icon = 'fa-solid fa-angle-left',
            params = {
                event = "keep-companion:client:main_menu",
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
                event = "keep-companion:client:switchControl_event",
                args = {
                    index = value.key
                }
            }
        }
    end

    -- leave menu
    openMenu[#openMenu + 1] = {
        header = Lang:t('menu.general_menu_items.btn_leave'),
        txt = "",
        icon = 'fa-solid fa-circle-xmark',
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(openMenu)
end)

AddEventHandler('keep-companion:client:switchControl_event', function(option)
    if option.index < 0 then
        return
    end
    ActivePed:switchControl(option.index)
    TriggerEvent('keep-companion:client:action_menu')
end)

local function IsPoliceOrEMS()
    return (PlayerJob.name == "police" or PlayerJob.name == "ambulance")
end

local function IsDowned()
    return (PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"])
end

local function Ishandcuffed()
    return PlayerData.metadata["ishandcuffed"]
end

RegisterKeyMapping('+showMenu', 'show pet menu', 'keyboard', Config.Settings.petMenuKeybind)
RegisterCommand('+showMenu', function()
    updatePlayerJob()
    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not Ishandcuffed() and not IsPauseMenuActive() and
        not isMenuOpen then
        local doesPlayerHavePet = ActivePed:read()

        if doesPlayerHavePet == nil then
            QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
            return
        end

        TriggerEvent('keep-companion:client:main_menu')
    end
end, false)

-- This will update all the PlayerData that doesn't get updated with a specific event other than this like the metadata
RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- =======================================
--           Customization menu
-- =======================================
RegisterNetEvent('keep-companion:client:start_grooming_process', function()
    local activePed = ActivePed:read()
    if type(activePed) ~= "table" then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end
    TriggerServerEvent('keep-companion:server:grooming_process', activePed.itemData)
end)

RegisterNetEvent('keep-companion:client:initialization_process', function(item, pet_information)
    if type(item) ~= "table" then
        QBCore.Functions.Notify(Lang:t('error.failed_to_start_procces'), 'error', 5000)
        return
    end
    if pet_information.type == 'init' then
        TriggerEvent('keep-companion:client:openMenu_customization', {
            item = item, pet_information = pet_information
        })
        return
    end
    local hasitem = QBCore.Functions.HasItem(Config.core_items.groomingkit.item_name)

    if not hasitem then QBCore.Functions.Notify('you need grooming kit', 'error', 5000) return end
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
            header = Lang:t('menu.customization_menu.rename.inputs.header'),
            submitText = Lang:t('menu.general_menu_items.confirm'),
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
            header = Lang:t('menu.general_menu_items.btn_back'),
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
            header = Lang:t('menu.variation_menu.selection_menu.header'),
            icon = 'fa-solid fa-rectangle-list',
            isMenuHeader = true,
            disabled = true
        },
    }

    for key, value in pairs(pet_information.pet_variation_list) do
        openMenu[#openMenu + 1] = {
            header = Lang:t('menu.variation_menu.selection_menu.btn_variation_items') .. value,
            txt = Lang:t('menu.variation_menu.selection_menu.btn_desc'),
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
            header = Lang:t('menu.customization_menu.header'),
            txt = Lang:t('menu.customization_menu.sub_header'),
            icon = 'fa-solid fa-pen-to-square',
            isMenuHeader = true
        },
        {
            header = Lang:t('menu.customization_menu.btn_rename'),
            txt = Lang:t('menu.customization_menu.btn_txt_btn_rename') .. c_name,
            icon = 'fa-regular fa-keyboard',
            disabled = data.pet_information.disable.rename,
            params = {
                event = "keep-companion:client:openMenu_customization_rename",
                args = {
                    item = data.item,
                    pet_information = data.pet_information
                },
            }
        },
        {
            header = Lang:t('menu.customization_menu.btn_select_variation'),
            txt = Lang:t('menu.customization_menu.btn_txt_select_variation') .. c_variation,
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
            header = Lang:t('menu.general_menu_items.confirm'),
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
            header = Lang:t('menu.general_menu_items.btn_leave'),
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
            header = Lang:t('menu.general_menu_items.btn_back'),
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
            header = Lang:t('menu.rename_menu.header'),
            icon = 'fa-solid fa-pen-to-square',
            txt = c_name,
            isMenuHeader = true,
            disabled = true
        },
        {
            header = Lang:t('menu.rename_menu.btn_rename'),
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
            header = Lang:t('menu.general_menu_items.btn_back'),
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
            header = Lang:t('menu.variation_menu.header'),
            txt = item.info.variation,
            icon = 'fa-solid fa-palette',
            isMenuHeader = true,
            disabled = true
        },
        {
            header = Lang:t('menu.variation_menu.btn_select_variation'),
            txt = Lang:t('menu.variation_menu.btn_txt_select_variation'),
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
    TriggerServerEvent('keep-companion:server:compelete_initialization_process', data.item, data.pet_information.type)
end)
