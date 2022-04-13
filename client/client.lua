local CoreName = exports['qb-core']:GetCoreObject()

-- ============================
--         Pet Class
-- ============================
ActivePed = {
    data = {
        model = nil,
        entity = nil,
        hostile = nil,
        XP = nil,
        level = nil,
        itemData = nil,
        lastCoord = nil,
        variation = nil,
        time = nil,
        health = nil
    }
}
-- itemData.name is item's name
-- itemData.info.name is pet's name

--- inital pet data
function ActivePed:new(model, hostile, item, ped)
    self.data.model = model
    self.data.entity = ped
    self.data.hostile = hostile
    self.data.XP = item.info.XP
    self.data.level = item.info.level
    self.data.itemData = item
    self.data.lastCoord = GetEntityCoords(ped) -- if we don't have coord we know entity is missing
    self.data.variation = item.info.variation
    self.data.time = 1
    self.data.health = item.info.health
    -- set modelString and canHunt
    for key, information in pairs(Config.pets) do
        if information.name == item.name then
            self.data.modelString = information.model
            self.data.maxHealth = information.maxHealth
            for w in information.distinct:gmatch("%S+") do
                if w == 'yes' then
                    self.data.canHunt = true
                elseif w == 'no' then
                    self.data.canHunt = false
                end
            end
            return
        end
    end
end

--- return current active pet
function ActivePed:read()
    if next(ActivePed.data) ~= nil then
        return ActivePed.data
    end
end

--- update requested value inside pet class
---@param options table
function ActivePed:update(options)
    if options.model ~= nil then
        self.data.model = options.model or self.data.model
    elseif options.hostile ~= nil then
        self.data.hostile = options.hostile or self.data.hostile
    elseif options.itemData ~= nil then
        self.data.itemData = options.itemData or self.data.itemData
    elseif options.entity ~= nil then
        self.data.entity = options.entity or self.data.entity
    elseif options.xp ~= nil then
        self.data.XP = options.xp or self.data.XP
    elseif options.level ~= nil then
        self.data.level = options.level or self.data.level
    elseif options.health ~= nil then
        self.data.health = options.health or self.data.health
    elseif options.lastCoord ~= nil then
        self.data.lastCoord = GetEntityCoords(self.data.entity)
    end
end

--- clean current ped data
function ActivePed:remove()
    self.data = {}
end

--- call xp for distance moved by ped
function addXpForDistanceMoved()
    local pedData = ActivePed.read() or {}
    local activeped = ActivePed:read()
    if next(pedData) ~= nil then
        local currentCoord = GetEntityCoords(pedData.entity)
        local distance = #(currentCoord - pedData.lastCoord)
        distance = math.floor(distance)
        ActivePed:update {
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
                ActivePed:update {
                    xp = Xp
                }
                ActivePed:update {
                    level = level + 1
                }
                TriggerEvent('QBCore:Notify', activeped.itemData.info.name .. "level up to " .. activeped.level)
            else
                ActivePed:update {
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
                    options = { {
                        icon = "fas fa-sack-dollar",
                        label = "pet",
                        -- canInteract = function(entity)
                        --     if not IsPedAPlayer(entity) then
                        --         return (entity and IsEntityDead(entity))
                        --     end
                        -- end,
                        action = function(entity)
                            makeEntityFaceEntity(PlayerPedId(), entity)
                            makeEntityFaceEntity(entity, PlayerPedId())

                            local playerPed = PlayerPedId()
                            local coords = GetEntityCoords(playerPed)
                            local forward = GetEntityForwardVector(playerPed)
                            local x, y, z = table.unpack(coords + forward * 1.0)

                            SetEntityCoords(entity, x, y, z, 0, 0, 0, 0)
                            TaskPause(entity, 5000)

                            waitForAnimation('amb@medic@standing@kneel@base')
                            waitForAnimation('anim@gangops@facility@servers@bodysearch@')
                            TaskPlayAnim(PlayerPedId(), "amb@medic@standing@kneel@base", "base", 8.0, -8.0, -1, 1, 0,
                                false, false, false)
                            TaskPlayAnim(PlayerPedId(), "anim@gangops@facility@servers@bodysearch@", "player_search",
                                8.0, -8.0, -1, 48, 0, false, false, false)
                            -- if IsPedAPlayer(entity) and IsEntityDead(entity) then
                            --     return false
                            -- end
                            -- TriggerEvent('keep-hunting:client:slaughterAnimal', entity)
                            return true
                        end
                    } },
                    distance = 1.5
                })
            end)
        end)
end)


--- when the player is AFK for a certain time pet will wander around
---@param timeOut table
---@param goWanderingAfter number
local function afkWandering(timeOut, goWanderingAfter)
    -- #TODO follow player when not afk
    local ped = ActivePed:read().entity
    local plyPed = PlayerPedId()
    local coord = GetEntityCoords(plyPed)
    if IsPedStopped(plyPed) then
        if timeOut[1] ~= (goWanderingAfter + 1) then
            timeOut[1] = timeOut[1] + 1
        end
        if timeOut[1] == goWanderingAfter then
            -- player is stoped more than 10sec
            TaskWanderInArea(ped, coord, 4.0, 2, 8.0)
        end
    else
        timeOut[1] = 0
    end
end

--- this set of Functions will executed evetry sec to tracker pet's behaviour.
---@param ped any
function creatActivePetThread(ped)
    local goWanderingAfter = Config.Balance.goWander
    local count = 10
    local tmpcount = 0
    CreateThread(function()
        -- it's table just to have passed by reference.
        local timeOut = { 0 }
        while DoesEntityExist(ped) do
            addXpForDistanceMoved()
            afkWandering(timeOut, goWanderingAfter)
            increasePetAge()

            -- update every 10 sec
            if tmpcount >= count then
                local activeped = ActivePed:read()
                local currentItem = {
                    hash = activeped.itemData.info.hash,
                    slot = activeped.itemData.slot
                }

                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'XP',
                    content = activeped.XP
                })
                tmpcount = 0
            end
            tmpcount = tmpcount + 1

            -- update health
            local currentHealth = GetEntityHealth(ActivePed:read().entity)
            if IsPedDeadOrDying(ActivePed:read().entity) == false and ActivePed:read().maxHealth ~= currentHealth and
                ActivePed:read().health ~= currentHealth then
                -- ped is still alive
                local retval--[[ boolean ]] , outBone--[[ integer ]]  =
                GetPedLastDamageBone(ActivePed:read().entity--[[ Ped ]] )
                print(outBone)
                local activeped = ActivePed:read()
                local currentItem = {
                    hash = activeped.itemData.info.hash,
                    slot = activeped.itemData.slot
                }
                -- SetEntityMaxHealth(entity, value)
                TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                    key = 'health',
                    content = GetEntityHealth(ActivePed:read().entity)
                })
                -- update current health value inside client
                ActivePed:update {
                    health = GetEntityHealth(ActivePed:read().entity)
                }
            end
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
