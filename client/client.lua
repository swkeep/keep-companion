local CoreName = exports['qb-core']:GetCoreObject()

-- ============================
--         Pet Class
-- ============================
ActivePed = {
    data = {},
    onControl = -1
}
-- itemData.name is item's name
-- itemData.info.name is pet's name

--- inital pet data
function ActivePed:new(model, hostile, item, ped)
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
    self.data[index]['hostile'] = hostile
    self.data[index]['XP'] = item.info.XP
    self.data[index]['level'] = item.info.level
    self.data[index]['itemData'] = item
    self.data[index]['lastCoord'] = GetEntityCoords(ped) -- if we don't have coord we know entity is missing
    self.data[index]['variation'] = item.info.variation
    self.data[index]['time'] = 1
    self.data[index]['health'] = item.info.health
    self.data[index]['food'] = item.info.food

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

function ActivePed:readByHash(hash)
    for key, data in pairs(self.data) do
        if data.itemData.info.hash == hash then
            return data
        end
    end
end

--- update requested value inside pet class
---@param options table
function ActivePed:update(options)
    local index
    if options.index == nil then
        index = ActivePed.onControl
    else
        index = options.index
    end
    if options.model ~= nil then
        self.data[index].model = options.model or self.data[index].model
    elseif options.time ~= nil then
        self.data[index].time = options.time or self.data[index].time
    elseif options.food ~= nil then
        self.data[index].food = options.food or self.data[index].food
    elseif options.hostile ~= nil then
        self.data[index].hostile = options.hostile or self.data[index].hostile
    elseif options.itemData ~= nil then
        self.data[index].itemData = options.itemData or self.data[index].itemData
    elseif options.entity ~= nil then
        self.data[index].entity = options.entity or self.data[index].entity
    elseif options.xp ~= nil then
        self.data[index].XP = options.xp or self.data[index].XP
    elseif options.level ~= nil then
        self.data[index].level = options.level or self.data[index].level
    elseif options.health ~= nil then
        self.data[index].health = options.health or self.data[index].health
    elseif options.lastCoord ~= nil then
        self.data[index].lastCoord = GetEntityCoords(self.data[index].entity)
    end
end

--- clean current ped data
function ActivePed:remove(index)
    DeletePed(self.data[index].entity)
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
            key = 'age',
            content = value.time
        })
        TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            key = 'food',
            content = value.food
        })
        TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            key = 'XP',
            content = value.XP
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
            return key
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

--- call xp for distance moved by ped
function addXpForDistanceMoved(savedData)
    local currentCoord = GetEntityCoords(savedData.entity)
    local distance = #(currentCoord - savedData.lastCoord)
    local index = ActivePed:findByHash(savedData.itemData.info.hash)
    distance = math.floor(distance)

    ActivePed:update {
        index = index,
        lastCoord = 1
    }

    if distance > 0 and IsPedInAnyVehicle(savedData.entity, true) ~= 1 then

        local Xp = savedData.XP
        local level = savedData.level
        local currentMaxXP = currentLvlExp(level)
        if level == Config.Balance.maximumLevel then
            return
        end

        Xp = Xp + calNextXp(level)
        if Xp >= currentMaxXP then
            ActivePed:update {
                index = index,
                xp = Xp
            }
            ActivePed:update {
                index = index,
                level = level + 1
            }
            TriggerEvent('QBCore:Notify', savedData.itemData.info.name .. " level up to " .. savedData.level)
        else
            ActivePed:update {
                index = index,
                xp = Xp
            }
        end
    end
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

        Citizen.CreateThread(function()
            local spawnCoord = getSpawnLocation(plyPed)
            ped = CreateAPed(model, spawnCoord)
            if hostileTowardPlayer == true then
                -- if player is not owner of pet it will attack player
                taskAttackTarget(ped, plyPed, 10000, item)
            else
                TaskFollowTargetedPlayer(ped, plyPed, 3.0)
                -- add blip to entity
                if Config.Settings.PetMiniMap.showblip ~= nil and Config.Settings.PetMiniMap.showblip == true then
                    createBlip({
                        entity = ped,
                        sprite = Config.Settings.PetMiniMap.sprite,
                        colour = Config.Settings.PetMiniMap.colour,
                        text = item.info.name,
                        shortRange = false
                    })
                end
                SetEntityAsMissionEntity(ped, true, true)
            end
            -- send ped data to server
            TriggerServerEvent('keep-companion:server:updatePedData', item, model, ped)
            -- init ped data inside client
            ActivePed:new(modelName, hostileTowardPlayer, item, ped)
            local currentPetData = ActivePed:readByHash(item.info.hash)
            -- check for variation data
            if currentPetData.itemData.info.variation ~= nil then
                PetVariation:setPedVariation(ped, modelName, currentPetData.itemData.info.variation)
            end
            SetEntityMaxHealth(ped, currentPetData.maxHealth)
            SetEntityHealth(ped, currentPetData.itemData.info.health)
            local currentHealth = GetEntityHealth(ped)
            if currentHealth == 0 then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = { {
                        icon = "fas fa-first-aid",
                        label = "revive pet",
                        canInteract = function(entity)
                            if IsEntityDead(entity) == 1 and ActivePed.read() ~= nil then
                                return true
                            else
                                return false
                            end
                        end,
                        action = function(entity)
                            if DoesEntityExist(entity) then
                                TriggerEvent('keep-companion:client:increaseHealth', ped, item, 'revive')
                            end
                            return true
                        end
                    } },
                    distance = 1.5
                })
            else
                creatActivePetThread(ped, item)
                exports['qb-target']:AddTargetEntity(ped, {
                    options = { {
                        icon = "fas fa-sack-dollar",
                        label = "pet",
                        canInteract = function(entity)
                            if IsEntityDead(entity) == false then
                                return true
                            else
                                return false
                            end
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

                            TriggerServerEvent('hud:server:RelieveStress', Config.Balance.petStressReliefValue)
                            return true
                        end
                    }, {
                        icon = "fas fa-first-aid",
                        label = "Heal",
                        canInteract = function(entity)
                            if IsEntityDead(entity) == false then
                                return true
                            else
                                return false
                            end
                        end,
                        action = function(entity)
                            TriggerEvent('keep-companion:client:increaseHealth', ped, item, 'Heal')
                            return true
                        end
                    } },
                    distance = 1.5
                })
            end
        end)
    end)
end)

AddEventHandler('keep-companion:client:increaseHealth', function(ped, item, TYPE)
    QBCore.Functions.TriggerCallback("QBCore:HasItem", function(hasitem)
        if hasitem then
            local plyID = PlayerPedId()
            makeEntityFaceEntity(plyID, ped)
            if TYPE == 'Heal' then
                makeEntityFaceEntity(ped, plyID)
                TaskPause(ped, 5000)
            end
            local timeout = Config.Settings.firstAidDuration
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
                Config.Settings.firstAidDuration * 1000, false, false, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true
                }, {}, {}, {}, function()
                local currectPet = ActivePed.data[ActivePed:findByHash(item.info.hash)]
                TriggerServerEvent('keep-companion:server:revivePet', currectPet, TYPE)
                TaskFollowTargetedPlayer(ped, plyID)
            end)
        else
            QBCore.Functions.Notify('You need first aid to revive your pet!', "error", 1500)
        end
    end, 'firstaidforpet')
end)

--- when the player is AFK for a certain time pet will wander around
---@param timeOut table
---@param afk number
local function afkWandering(timeOut, afk, plyPed, ped)
    local coord = GetEntityCoords(plyPed)
    if IsPedStopped(plyPed) then
        if timeOut[1] < afk.afkTimerRestAfter then
            timeOut[1] = timeOut[1] + 1
            -- code here
            if timeOut[1] == afk.wanderingInterval then
                print('tr 1')
                if timeOut.lastAction == nil or (timeOut.lastAction ~= nil and timeOut.lastAction == 'animation') then
                    ClearPedTasks(ped) -- clear last animation
                    TaskWanderInArea(ped, coord, 4.0, 2, 8.0)
                    timeOut.lastAction = 'wandering'
                end
            end
            if timeOut[1] == afk.animationInterval then
                print('tr 2')

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
            petAgeCounter(savedData)
            afkWandering(timeOut, afk, plyPed, ped)
            addXpForDistanceMoved(savedData)

            -- update every 10 sec
            if tmpcount >= count then
                local activeped = savedData
                local currentItem = {
                    hash = activeped.itemData.info.hash,
                    slot = activeped.itemData.slot
                }

                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'XP',
                    content = activeped.XP
                })

                -- full server side
                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'food',
                    content = 'decrease'
                })
                tmpcount = 0
            end
            tmpcount = tmpcount + 1

            -- update health
            local currentHealth = GetEntityHealth(savedData.entity)
            if IsPedDeadOrDying(savedData.entity) == false and savedData.maxHealth ~= currentHealth and savedData.health ~=
                currentHealth then
                -- ped is still alive
                local retval, outBone = GetPedLastDamageBone(savedData.entity) -- #TODO cal damage by bone!
                local activeped = savedData
                local currentItem = {
                    hash = activeped.itemData.info.hash,
                    slot = activeped.itemData.slot
                }
                -- SetEntityMaxHealth(entity, value)
                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'health',
                    content = GetEntityHealth(savedData.entity)
                })
                -- update current health value inside client
                ActivePed:update {
                    index = ActivePed:findByHash(activeped.itemData.info.hash),
                    health = GetEntityHealth(savedData.entity)
                }
            end
            if IsPedDeadOrDying(savedData.entity) == 1 then
                -- #TODO report pet state and health to serve
                local c_health = GetEntityHealth(savedData.entity)
                local currentItem = {
                    hash = savedData.itemData.info.hash,
                    slot = savedData.itemData.slot
                }
                if c_health == 0 or c_health == 100 then
                    TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                        key = 'health',
                        content = c_health
                    })
                    fninished = true
                end
            end
            Wait(1000)
        end
    end)
end

function petAgeCounter(savedData)
    ActivePed:update {
        index = ActivePed:findByHash(savedData.itemData.info.hash),
        time = savedData.time + 1
    }
end

RegisterNetEvent('keep-companion:client:despawn')
AddEventHandler('keep-companion:client:despawn', function(ped, item, revive)
    if revive ~= nil and revive == true then
        -- revive skip animation
        ActivePed:remove(ActivePed:findByHash(item.info.hash))
        TriggerServerEvent('keep-companion:server:setAsDespawned', item)
        return
    end
    local plyPed = PlayerPedId()
    local currentItem = {
        hash = item.info.hash,
        slot = item.slot
    }

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
            TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                key = 'age',
                content = ActivePed.data[ActivePed:findByHash(item.info.hash)].time
            })
            ActivePed:remove(ActivePed:findByHash(item.info.hash))
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

RegisterNetEvent('keep-companion:client:updateFood')
AddEventHandler('keep-companion:client:updateFood', function(petData)
    -- process of updating pet's name
    ActivePed:update {
        index = ActivePed:findByHash(petData.hash),
        food = petData.content
    }
end)

RegisterNetEvent('keep-companion:client:getPetdata')
AddEventHandler('keep-companion:client:getPetdata', function()
    CoreName.Functions.Progressbar("feeding", "Feeding", Config.Settings.feedingSpeed * 1000, false, false, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false
    }, {}, {}, {}, function()
        TriggerServerEvent('keep-companion:server:increaseFood', ActivePed:read().itemData)
    end)
end)

RegisterNetEvent('keep-companion:client:increaseFood')
AddEventHandler('keep-companion:client:increaseFood', function(item, amount)
    TriggerServerEvent('keep-companion:server:updateAllowedInfo', {
        hash = item.info.hash,
        slot = item.slot
    }, {
        key = 'food',
        content = 'increase',
        amount = amount
    })
end)

RegisterNetEvent('keep-companion:client:renameCollar', function(item)
    if ActivePed:read() ~= nil then
        local name = exports['qb-input']:ShowInput({
            header = "rename: " .. ActivePed:read().itemData.info.name,
            submitText = "rename",
            inputs = { {
                type = 'text',
                isRequired = true,
                name = 'PETNAME',
                text = "enter pet name"
            } }
        })
        if name then
            if not name.PETNAME then
                return
            end
            TriggerServerEvent('keep-companion:server:renameCollar', name.PETNAME)
        end
    else
        QBCore.Functions.Notify('Aleast one pet should be on your control!', 'error', 7500)
    end

end)

-- #TODO this event should be two events one get active pet and one for changing pet name
RegisterNetEvent('keep-companion:client:renameCollarAction', function(name)
    -- process of updating pet's name
    local activePed = ActivePed:read() or nil
    if activePed ~= nil then
        local validation = ValidatePetName(name, 12)
        local currentItem = {
            hash = activePed.itemData.info.hash or nil,
            slot = activePed.itemData.slot or nil
        }

        if next(currentItem) ~= nil and type(name) == "string" and validation == false then
            CoreName.Functions.Progressbar("waitingForName", "waiting for Name",
                Config.Settings.changePetNameDuration * 1000, false, false, {
                    disableMovement = false,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true
                }, {}, {}, {}, function()
                Citizen.CreateThread(function()
                    TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                        key = 'name',
                        content = name
                    })
                end)
            end)
        elseif validation.reason == 'badword' then
            TriggerEvent('QBCore:Notify', "Don't name your pet like that!")
            print_table(validation.words)
        elseif validation.reason == 'maxCharacter' then
            TriggerEvent('QBCore:Notify', "You can not use that many words!")
        elseif validation.reason == 'moreThanOneWord' then
            -- won't trigger
            TriggerEvent('QBCore:Notify', "we can't save names that contain more than one word!")
        end
    else
        TriggerEvent('QBCore:Notify', "no active pet found!")
    end
end)
