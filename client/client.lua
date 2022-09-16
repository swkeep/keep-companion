local CoreName = exports['qb-core']:GetCoreObject()

-- ============================
--         Pet Class
-- ============================
ActivePed = {
    data = {
        -- model = '',
        -- entity = '',
        -- hostile = '',
        -- lastCoord = '',
        -- variation = '',
        -- health = '',
    },
    onControl = -1
}
-- itemData.name is item's name
-- itemData.info.name is pet's name

--- inital pet data
function ActivePed:new(model, hostile, item, ped, netId)
    -- set modelString and canHunt
    local index = (#self.data + 1)
    if self.data[index] == nil then
        self.data[index] = {}
        self.onControl = 1
    else
        self.onControl = self.onControl + 1
    end
    -- move onControll to last spawned pet

    self.data[index]['model'] = model
    self.data[index]['entity'] = ped
    self.data[index]['netId'] = netId
    self.data[index]['hostile'] = hostile
    self.data[index]['itemData'] = item
    self.data[index]['lastCoord'] = GetEntityCoords(ped) -- if we don't have coord we know entity is missing
    self.data[index]['variation'] = item.info.variation
    self.data[index]['health'] = item.info.health

    for key, information in pairs(Config.pets) do
        if information.name == item.name then
            self.data[index]['modelString'] = information.model
            self.data[index]['maxHealth'] = information.maxHealth
            for w in information.distinct:gmatch("%S+") do
                if w == 'yes' then
                    self.data[index]['canHunt'] = true
                elseif w == 'no' then
                    self.data[index]['canHunt'] = false
                end
            end
            return
        end
    end
end

--- return current active pet
function ActivePed:read()
    local index = ActivePed.onControl
    return ActivePed.data[index]
end

--- clean current ped data
function ActivePed:remove(index)
    local netId = NetworkGetNetworkIdFromEntity(self.data[index].entity)
    if not netId then return end
    TriggerServerEvent('keep-companion:server:ForceRemoveNetEntity', netId)
    self.data[index] = nil
    -- assign onControl to valid value
    if #self.data == 0 then
        self.onControl = -1
        return
    end
    for key, value in pairs(self.data) do
        self.onControl = key
        return
    end
end

function ActivePed:removeAll()
    local tmpHash = {}
    for key, value in pairs(ActivePed:petsList()) do
        DeletePed(value.pedHandle)
        table.insert(tmpHash, value.itemData)
        local currentItem = {
            hash = value.itemData.info.hash or nil,
            slot = value.itemData.slot or nil
        }

        TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            key = 'XP',
        })
    end
    TriggerServerEvent('keep-companion:server:onPlayerUnload', tmpHash)
    self.data = {}
    self.onControl = -1
end

function ActivePed:switchControl(to)
    if to > #self.data or to < 1 then
        return
    end
    self.onControl = to
end

function ActivePed:findByHash(hash)
    for key, data in pairs(self.data) do
        if data.itemData.info.hash == hash then
            return key, data
        end
    end
end

function ActivePed:petsList()
    local tmp = {}
    for key, data in pairs(self.data) do
        table.insert(tmp, {
            key = key,
            name = data.itemData.info.name,
            pedHandle = data.entity,
            itemData = {
                info = {
                    hash = data.itemData.info.hash -- used on ActivePed:removeAll()
                }
            }
        })
    end
    return tmp
end

RegisterNetEvent('keep-companion:client:callCompanion')
AddEventHandler('keep-companion:client:callCompanion', function(modelName, hostileTowardPlayer, item)
    -- add another layer when player spawn it inside Vehicle
    local model = (tonumber(modelName) ~= nil and tonumber(modelName) or GetHashKey(modelName))
    local plyPed = PlayerPedId()
    local ped = nil
    SetCurrentPedWeapon(plyPed, 0xA2719263, true)
    ClearPedTasks(plyPed)

    whistleAnimation(plyPed, 1500)

    CoreName.Functions.Progressbar("callCompanion", "Calling companion", Config.Settings.callCompanionDuration * 1000,
        false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        ClearPedTasks(plyPed)

        local spawnCoord = getSpawnLocation(plyPed)
        ped = CreateAPed(model, spawnCoord)
        local netId = NetworkGetNetworkIdFromEntity(ped)
        QBCore.Functions.TriggerCallback('keep-companion:server:updatePedData', function(result)
            if hostileTowardPlayer == true then
                -- if player is not owner of pet it will attack player
                QBCore.Functions.Notify(Lang:t('error.not_owner_of_pet'), 'error', 5000)
            end
            ClearPedTasks(ped)
            TaskFollowTargetedPlayer(ped, plyPed, 3.0, true)
            -- -- add blip to entity

            if Config.Settings.PetMiniMap.showblip ~= nil and Config.Settings.PetMiniMap.showblip == true then
                createBlip({
                    entity = ped,
                    sprite = Config.Settings.PetMiniMap.sprite,
                    colour = Config.Settings.PetMiniMap.colour,
                    text = item.info.name,
                    shortRange = false
                })
            end

            -- init ped data inside client
            ActivePed:new(modelName, hostileTowardPlayer, item, ped, netId)
            local index, petData = ActivePed:findByHash(item.info.hash)

            -- check for variation data
            if petData.itemData.info.variation ~= nil then
                PetVariation:setPedVariation(ped, modelName, petData.itemData.info.variation)
            end
            SetEntityMaxHealth(ped, petData.maxHealth)
            SetEntityHealth(ped, math.floor(petData.itemData.info.health))
            local currentHealth = GetEntityHealth(ped)

            exports['qb-target']:AddTargetEntity(ped, {
                options = { {
                    icon = "fas fa-sack-dollar",
                    label = "pet",
                    canInteract = function(entity)
                        return (IsEntityDead(entity) == false and ActivePed.read() ~= nil)
                    end,
                    action = function(entity)
                        makeEntityFaceEntity(PlayerPedId(), entity)
                        makeEntityFaceEntity(entity, PlayerPedId())

                        local playerPed = PlayerPedId()
                        local coords = GetEntityCoords(playerPed)
                        local forward = GetEntityForwardVector(playerPed)
                        local x, y, z = table.unpack(coords + forward * 1.0)

                        SetEntityCoords(entity, x, y, z, 0, 0, 0, 0)
                        TaskPause(entity, 5000)

                        Animator(entity, modelName, 'tricks', {
                            animation = 'petting_chop'
                        })
                        Animator(plyPed, 'A_C_Rottweiler', 'tricks', {
                            animation = 'petting_franklin'
                        })

                        TriggerServerEvent('hud:server:RelieveStress', Config.Balance.petting_stress_relief)
                        return true
                    end
                }, {
                    icon = "fas fa-first-aid",
                    label = "Heal",
                    canInteract = function(entity)
                        return (IsEntityDead(entity) == false and ActivePed.read() ~= nil)
                    end,
                    action = function(entity)
                        request_healing_process(ped, item, 'Heal')
                        return true
                    end
                }, {
                    icon = "fas fa-first-aid",
                    label = "revive pet",
                    canInteract = function(entity)
                        return (IsEntityDead(entity) == 1 and ActivePed.read() ~= nil)
                    end,
                    action = function(entity)
                        if not DoesEntityExist(entity) then
                            return false
                        end

                        request_healing_process(ped, item, 'revive')
                        return true
                    end
                }, {
                    icon = "fa-solid fa-flask",
                    label = "Drink from water bottle",
                    canInteract = function(entity)
                        return (IsEntityDead(entity) ~= 1 and ActivePed.read() ~= nil)
                    end,
                    action = function(entity)
                        if not DoesEntityExist(entity) then
                            return false
                        end

                        start_drinking_animation()
                        return true
                    end
                }
                },
                distance = 1.5
            })

            if petData.hostile == true then
                TriggerServerEvent('keep-companion:server:despwan_not_owned_pet', petData.itemData.info.hash)
                return
            end

            if currentHealth > 100 then
                creatActivePetThread(ped, item)
            end
        end, {
            item = item, model = model, entity = ped
        })
    end)
end)

function request_healing_process(ped, item, process_type)
    local hasitem = QBCore.Functions.HasItem(Config.core_items.firstaid.item_name)
    if not hasitem then QBCore.Functions.Notify(Lang:t('error.not_enough_first_aid'), 'error', 5000) return end

    local plyID = PlayerPedId()
    local timeout = Config.core_items.firstaid.settings.duration
    local current_pet = ActivePed.data[ActivePed:findByHash(item.info.hash)]

    if process_type == 'Heal' then
        timeout = timeout * math.floor(Config.core_items.firstaid.settings.healing_duration_multiplier)
        makeEntityFaceEntity(ped, plyID) -- pet face owner
        TaskPause(ped, 5000)
    else
        timeout = timeout * math.floor(Config.core_items.firstaid.settings.revive_duration_multiplier)
    end
    makeEntityFaceEntity(plyID, ped) -- owner face pet

    Animator(plyID, "PLAYER", 'revive', {
        animation = 'tendtodead',
        sequentialTimings = {
            [1] = timeout,
            [2] = 0,
            [3] = 0,
            step = 1,
            Timeout = timeout
        }
    })
    -- firstaidforpet
    CoreName.Functions.Progressbar("reviveing", "Reviveing",
        timeout * 1000, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {}, {}, {}, function()
        TriggerServerEvent('keep-companion:server:revivePet', current_pet, process_type)
        TaskFollowTargetedPlayer(ped, plyID, false)
    end)
end

RegisterNetEvent('keep-companion:client:update_health_value', function(item, amount)
    SetEntityHealth(item.entity, math.floor(amount))
end)


--- when the player is AFK for a certain time pet will wander around
---@param timeOut table
---@param afk number
local function afkWandering(timeOut, afk, plyPed, ped)
    local coord = GetEntityCoords(plyPed)
    if IsPedStopped(plyPed) and IsPedInAnyVehicle(plyPed) == false then
        if timeOut[1] < afk.afkTimerRestAfter then
            timeOut[1] = timeOut[1] + 1
            -- code here
            if timeOut[1] == afk.wanderingInterval then
                if timeOut.lastAction == nil or (timeOut.lastAction ~= nil and timeOut.lastAction == 'animation') then
                    ClearPedTasks(ped) -- clear last animation
                    TaskWanderInArea(ped, coord, 4.0, 2, 8.0)
                    timeOut.lastAction = 'wandering'
                end
            end
            if timeOut[1] == afk.animationInterval then
                ClearPedTasks(ped) -- clear TaskWanderInArea
                Animator(ped, ActivePed:read().model, 'siting')
                timeOut.lastAction = 'animation'
            end
        else
            timeOut[1] = 0 --
        end
    else
        timeOut[1] = 0
    end
end

--- this set of Functions will executed evetry sec to tracker pet's behaviour.
---@param ped any
function creatActivePetThread(ped, item)
    local afk = Config.Balance.afk
    local count = Config.DataUpdateInterval -- this value is
    local plyPed = PlayerPedId()
    CreateThread(function()
        local tmpcount = 0
        local savedData = ActivePed.data[ActivePed:findByHash(item.info.hash)]
        local fninished = false
        -- it's table just to have passed by reference.
        local timeOut = {
            0,
            lastAction = nil
        }
        while DoesEntityExist(ped) and fninished == false do
            afkWandering(timeOut, afk, plyPed, ped)

            -- update every 10 sec
            if tmpcount >= count then
                local activeped = savedData
                local currentItem = {
                    hash = activeped.itemData.info.hash,
                    slot = activeped.itemData.slot
                }

                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'XP',
                })

                tmpcount = 0
            end
            tmpcount = tmpcount + 1

            -- update health
            local currentHealth = GetEntityHealth(savedData.entity)
            if IsPedDeadOrDying(savedData.entity) == false and savedData.maxHealth ~= currentHealth and
                savedData.health ~=
                currentHealth then
                -- ped is still alive
                TriggerServerEvent('keep-companion:server:updateAllowedInfo', {
                    hash = savedData.itemData.info.hash,
                    slot = savedData.itemData.slot
                }, {
                    key = 'health',
                    netId = NetworkGetNetworkIdFromEntity(ped),
                })
                savedData.health = currentHealth
            end
            -- pet is died
            if IsPedDeadOrDying(savedData.entity) == 1 then
                local c_health = GetEntityHealth(savedData.entity)

                if c_health <= 100 then
                    TriggerServerEvent('keep-companion:server:updateAllowedInfo', {
                        hash = savedData.itemData.info.hash,
                        slot = savedData.itemData.slot
                    }, {
                        key = 'health',
                        netId = NetworkGetNetworkIdFromEntity(ped),
                    })
                    fninished = true
                end
            end
            Wait(1000)
        end
    end)
end

RegisterNetEvent('keep-companion:client:forceKill', function(hash, reason)
    local index, petData = ActivePed:findByHash(hash)
    local c_health = GetEntityHealth(petData.entity)
    if c_health < 100 then
        return
    end
    petData.health = 0
    SetEntityHealth(petData.entity, 0)
    local msg = Lang:t('error.your_pet_died_by')
    msg = string.format(msg, reason)
    QBCore.Functions.Notify(msg, 'error', 5000)
end)

RegisterNetEvent('keep-companion:client:despawn')
AddEventHandler('keep-companion:client:despawn', function(item, revive)
    if revive ~= nil and revive == true then
        -- revive skip animation
        local index, pedData = ActivePed:findByHash(item.info.hash)
        ActivePed:remove(index)
        TriggerServerEvent('keep-companion:server:setAsDespawned', item)
        return
    end
    local plyPed = PlayerPedId()

    SetCurrentPedWeapon(plyPed, 0xA2719263, true)
    ClearPedTasks(plyPed)
    whistleAnimation(plyPed, 1500)

    CoreName.Functions.Progressbar("despawn", "despawning", Config.Settings.despawnDuration * 1000, false, false, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false
    }, {}, {}, {}, function()
        ClearPedTasks(plyPed)
        Citizen.CreateThread(function()
            local index, pedData = ActivePed:findByHash(item.info.hash)
            ActivePed:remove(index)
            TriggerServerEvent('keep-companion:server:setAsDespawned', item)
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ActivePed:removeAll()
    PlayerData = {} -- empty playerData
end)

-- =========================================
--          Commands Client Events
-- =========================================

RegisterNetEvent('keep-companion:client:start_feeding_animation', function()
    local current_pet = ActivePed:read()

    if current_pet == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    local c_health = GetEntityHealth(current_pet.entity)
    if c_health <= 100.0 or current_pet.itemData.info.health <= 100.0 then
        QBCore.Functions.Notify(Lang:t('error.your_pet_is_dead'), 'error', 5000)
        return
    end

    CoreName.Functions.Progressbar("feeding", "Feeding", Config.core_items.food.settings.duration * 1000, false, false,
        {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        TriggerServerEvent('keep-companion:server:increaseFood', current_pet.itemData)
    end)
end)

RegisterNetEvent('keep-companion:client:', function()

end)

function start_drinking_animation()
    local current_pet = ActivePed:read()

    if current_pet == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    local c_health = GetEntityHealth(current_pet.entity)
    if c_health <= 100.0 or current_pet.itemData.info.health <= 100.0 then
        QBCore.Functions.Notify(Lang:t('error.your_pet_is_dead'), 'error', 5000)
        return
    end

    CoreName.Functions.Progressbar("pet_drinking", "drinking", Config.core_items.waterbottle.settings.duration * 1000,
        false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        QBCore.Functions.TriggerCallback('keep-companion:server:decrease_thirst', function(result)

        end, current_pet.itemData)
    end)
end

RegisterNetEvent('keep-companion:client:filling_animation', function(item)
    CoreName.Functions.Progressbar("filling_animation", "filling bottle",
        Config.core_items.waterbottle.settings.duration * 1000, false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        }, {}, {}, {}, function()
        TriggerServerEvent('keep-companion:server:filling_event', item)
    end)
end)

RegisterNetEvent('keep-companion:client:rename_name_tag', function(item)
    if ActivePed:read() == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    local name = exports['qb-input']:ShowInput({
        header = "rename: " .. ActivePed:read().itemData.info.name,
        submitText = "rename",
        inputs = { {
            type = 'text',
            isRequired = true,
            name = 'pet_name',
            text = "enter pet name"
        } }
    })
    if name then
        if not name.pet_name then
            return
        end
        TriggerServerEvent('keep-companion:server:rename_name_tag', name.pet_name)
    end
end)



RegisterNetEvent('keep-companion:client:rename_name_tagAction', function(name)
    -- process of updating pet's name
    local activePed = ActivePed:read() or nil
    local validation = ValidatePetName(name, 12)

    if activePed == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    if activePed.itemData.info.hash == nil or type(name) ~= "string" then
        QBCore.Functions.Notify(Lang:t('error.failed_to_start_procces'), 'error', 5000)
        return
    end

    if type(validation) == "table" and next(validation) ~= nil then
        QBCore.Functions.Notify(Lang:t('error.failed_to_validate_name'), 'error', 5000)
        if validation.reason == 'badword' then
            QBCore.Functions.Notify(Lang:t('error.badword_inside_pet_name'), 'error', 5000)
            print_table(validation.words)
            return
        elseif validation.reason == 'maxCharacter' then
            QBCore.Functions.Notify(Lang:t('error.more_than_one_word_as_name'), 'error', 5000)
            return
        end
        return
    end

    CoreName.Functions.Progressbar("waitingForName", "waiting for Name",
        Config.core_items.nametag.settings.duration * 1000, false, false, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true
        }, {}, {}, {}, function()
        QBCore.Functions.TriggerCallback('keep-companion:server:renamePet', function(result)
            if type(result) == "string" then
                QBCore.Functions.Notify(Lang:t('success.pet_rename_was_successful') .. result, 'success', 5000)
            end
        end, {
            hash = activePed.itemData.info.hash or nil,
            slot = activePed.itemData.slot or nil,
            name = name
        })
    end)
end)

RegisterNetEvent('keep-companion:client:collar_process', function()
    -- process of updating pet's owernship
    local activePed = ActivePed:read() or nil

    if activePed == nil then
        QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
        return
    end

    if activePed.itemData.info.hash == nil then
        QBCore.Functions.Notify(Lang:t('error.failed_to_find_pet'), 'error', 5000)
        return
    end

    local inputData = exports['qb-input']:ShowInput({
        header = "New owner id: ",
        submitText = "Confirm",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'cid',
                text = "new owner id"
            },
        }
    })
    if inputData then
        if not inputData.cid then
            return
        end
        CoreName.Functions.Progressbar("waitingForOwenership", "waiting for new owner",
            Config.core_items.collar.settings.duration * 1000, false, false, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true
            }, {}, {}, {},
            function()
                local c_pet = ActivePed:read()
                if c_pet == nil then
                    QBCore.Functions.Notify(Lang:t('error.no_pet_under_control'), 'error', 5000)
                    return
                end
                QBCore.Functions.TriggerCallback('keep-companion:server:collar_change_owenership', function(result)
                    if result.state == false then
                        QBCore.Functions.Notify(result.msg, 'error', 5000)
                        return
                    end
                    QBCore.Functions.Notify(result.msg, 'success', 5000)
                end, {
                    new_owner_cid = inputData.cid,
                    hash = ActivePed:read().itemData.info.hash,
                })
            end
        )
    end
end)
