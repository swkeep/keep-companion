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
    end
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

    -- move onControll to last spawned pet
    self.onControll = #self.data
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
    local index = ActivePed.onControll -- for some reason self trows error! 
    return ActivePed.data[index]
end

--- update requested value inside pet class
---@param options table
function ActivePed:update(options)
    local index = ActivePed.onControl
    if options.model ~= nil then
        self.data[index].model = options.model or self.data[index].model
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
function ActivePed:remove()
    -- #TODO should change onControl after removeal to correct value
    local index = ActivePed.onControl
    self.data[index] = nil
    self.onControl = #self.data
    if #self.data == 0 then
        self.onControl = -1
    end
end

function ActivePed:switchControl(to)
    if to > #self.data or to < 1 then
        return
    end
    self.onControll = to
end

function ActivePed:petsList()
    local tmp = {}
    for key, data in pairs(self.data) do
        table.insert(tmp, {
            key = key,
            name = data.itemData.info.name
        })
    end
    return tmp
end

--- call xp for distance moved by ped
function addXpForDistanceMoved()
    local pedData = ActivePed.read() or {}
    local activeped = ActivePed:read()
    if next(pedData) ~= nil then
        local currentCoord = GetEntityCoords(pedData.entity)
        local distance = #(currentCoord - pedData.lastCoord)
        distance = math.floor(distance)
        ActivePed:update{
            lastCoord = 1
        }

        if distance > 0 and IsPedInAnyVehicle(pedData.entity, true) ~= 1 then

            local Xp = pedData.XP
            local level = pedData.level
            local currentMaxXP = currentLvlExp(level)
            if level == Config.Balance.maximumLevel then
                return
            end

            Xp = Xp + calNextXp(level)
            if Xp >= currentMaxXP then
                ActivePed:update{
                    xp = Xp
                }
                ActivePed:update{
                    level = level + 1
                }
                TriggerEvent('QBCore:Notify', activeped.itemData.info.name .. " level up to " .. activeped.level)
            else
                ActivePed:update{
                    xp = Xp
                }
            end
        end
    end
end

RegisterNetEvent('keep-companion:client:callCompanion')
AddEventHandler('keep-companion:client:callCompanion', function(modelName, hostileTowardPlayer, item)
    -- add another layer when player spawn it inside Vehicle
    local model = (tonumber(modelName) ~= nil and tonumber(modelName) or GetHashKey(modelName))
    local plyPed = PlayerPedId()
    local coord = GetEntityCoords(plyPed)
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
            local forward = GetEntityForwardVector(plyPed)
            local x, y, z = table.unpack(coord + forward * 1.0)

            Citizen.CreateThread(function()
                local pos = vector3(x, y, z)
                ped = CreateAPed(model, pos)

                if hostileTowardPlayer == true then
                    -- if player is not owner of pet it will attack player
                    taskAttackTarget(ped, plyPed, 10000)
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
                -- check for variation data
                local variation = ActivePed:read().variation
                if variation ~= nil then
                    PetVariation:setPedVariation(ped, modelName, variation)
                end
                SetEntityMaxHealth(ped, ActivePed.read().maxHealth)
                SetEntityHealth(ped, ActivePed.read().health)

                -- add pet to active thread
                creatActivePetThread(ped)
                warpPedAroundPlayer(ped)

                exports['qb-target']:AddTargetEntity(ped, {
                    options = {{
                        icon = "fas fa-sack-dollar",
                        label = "pet",
                        canInteract = function(entity)
                            if not IsPedAPlayer(entity) then
                                if IsEntityDead(entity) == false then
                                    return true
                                else
                                    return false
                                end
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
                    }},
                    distance = 2.5
                })
                ActivePed:petsList()
            end)
        end)
end)

--- when the player is AFK for a certain time pet will wander around
---@param timeOut table
---@param afk number
local function afkWandering(timeOut, afk)
    local ped = ActivePed:read().entity
    local plyPed = PlayerPedId()
    local coord = GetEntityCoords(plyPed)
    if IsPedStopped(plyPed) then
        if timeOut[1] < afk.afkTimerRestAfter then
            timeOut[1] = timeOut[1] + 1
            -- code here
            if timeOut[1] == afk.wanderingInterval then
                if timeOut.lastAction == nil or (timeOut.lastAction ~= nil and timeOut.lastAction == 'animation') then
                    ClearPedTasks(ped) -- clear last animation
                    TaskWanderInArea(ped, coord, 4.0, 2, 8.0)
                    timeOut.lastAction = 'wandering'
                end
            elseif timeOut[1] == afk.animationInterval then
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
function creatActivePetThread(ped)
    local afk = Config.Balance.afk
    local count = Config.DataUpdateInterval -- this value is
    local tmpcount = 0
    CreateThread(function()
        -- it's table just to have passed by reference.
        local timeOut = {
            0,
            lastAction = nil
        }
        while DoesEntityExist(ped) do
            afkWandering(timeOut, afk)

            -- addXpForDistanceMoved()
            -- increasePetAge()

            -- -- update every 10 sec
            -- if tmpcount >= count then
            --     local activeped = ActivePed:read()
            --     local currentItem = {
            --         hash = activeped.itemData.info.hash,
            --         slot = activeped.itemData.slot
            --     }

            --     TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            --         key = 'XP',
            --         content = activeped.XP
            --     })

            --     -- full server side
            --     TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            --         key = 'food',
            --         content = 'decrease'
            --     })
            --     tmpcount = 0
            -- end
            -- tmpcount = tmpcount + 1

            -- -- update health
            -- local currentHealth = GetEntityHealth(ActivePed:read().entity)
            -- if IsPedDeadOrDying(ActivePed:read().entity) == false and ActivePed:read().maxHealth ~= currentHealth and
            --     ActivePed:read().health ~= currentHealth then
            --     -- ped is still alive
            --     local retval --[[ boolean ]] , outBone --[[ integer ]] =
            --         GetPedLastDamageBone(ActivePed:read().entity --[[ Ped ]] )
            --     print(outBone)
            --     local activeped = ActivePed:read()
            --     local currentItem = {
            --         hash = activeped.itemData.info.hash,
            --         slot = activeped.itemData.slot
            --     }
            --     -- SetEntityMaxHealth(entity, value)
            --     TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            --         key = 'health',
            --         content = GetEntityHealth(ActivePed:read().entity)
            --     })
            --     -- update current health value inside client
            --     ActivePed:update{
            --         health = GetEntityHealth(ActivePed:read().entity)
            --     }
            -- end
            Wait(1000)
        end
    end)
end

function increasePetAge()
    if ActivePed.data.time ~= nil then
        ActivePed.data.time = ActivePed.data.time + 1
    end
end

RegisterNetEvent('keep-companion:client:despawn')
AddEventHandler('keep-companion:client:despawn', function(ped)
    local plyPed = PlayerPedId()
    local activeped = ActivePed:read()
    SetCurrentPedWeapon(plyPed, 0xA2719263, true)
    ClearPedTasks(plyPed)
    local currentItem = {
        hash = activeped.itemData.info.hash,
        slot = activeped.itemData.slot
    }
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
                key = 'state',
                content = IsPedDeadOrDying(ped, 1)
            })
            if activeped.time ~= nil then
                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'age',
                    content = activeped.time
                })
            end
            DeletePed(ped)
            ActivePed:remove()
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    local activeped = ActivePed:read()
    if activeped ~= nil then
        local currentItem = {
            hash = activeped.itemData.info.hash,
            slot = activeped.itemData.slot
        }
        TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
            key = 'state',
            content = IsPedDeadOrDying(activeped.entity, 1)
        })
        if activeped.time ~= nil then
            TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                key = 'age',
                content = activeped.time
            })
        end
        TriggerServerEvent('keep-companion:server:onPlayerUnload', activeped.itemData)
        DeletePed(activeped.entity)
        ActivePed:remove()
    end
    PlayerData = {} -- empty playerData
end)

-- =========================================
--          Commands Client Events
-- =========================================

RegisterNetEvent('keep-companion:client:updateFood')
AddEventHandler('keep-companion:client:updateFood', function(newValue)
    -- process of updating pet's name
    ActivePed:update{
        food = newValue
    }
end)

RegisterNetEvent('keep-companion:client:getPetdata')
AddEventHandler('keep-companion:client:getPetdata', function()
    TriggerServerEvent('keep-companion:server:increaseFood', ActivePed:read().itemData)
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

-- #TODO this event should be two events one get active pet and one for changing pet name
RegisterNetEvent('keep-companion:client:getActivePet')
AddEventHandler('keep-companion:client:getActivePet', function(name)
    -- process of updating pet's name
    local activePed = ActivePed:read() or nil

    if activePed ~= nil then
        local validation = ValidatePetName(name, 12) -- #TODO this sould be inside server/if needed
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
            TriggerEvent('QBCore:Notify', "you can't name you pet like that!")
            print_table(validation.words)
        elseif validation.reason == 'maxCharacter' then
            TriggerEvent('QBCore:Notify', "you reached maximum allowed Characters!")
        elseif validation.reason == 'moreThanOneWord' then
            -- won't trigger
            TriggerEvent('QBCore:Notify', "we can't save names that contain more than one word!")
        end
    else
        TriggerEvent('QBCore:Notify', "no active pet found!")
    end
end)
