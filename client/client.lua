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
        time = nil
    }
}

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
end
--- return current active pet
function ActivePed:read()
    if next(ActivePed.data) ~= nil then
        return ActivePed.data
    end
end
--- update requested value inside pet class
---@param model 'model'
---@param hostile boolean
---@param item table
---@param ped 'ped'
---@param xp integer
---@param level integer
function ActivePed:update(model, hostile, item, ped, xp, level)
    self.data.model = model or self.data.model
    self.data.entity = ped or self.data.entity
    self.data.hostile = hostile or self.data.hostile
    self.data.XP = xp or self.data.XP
    self.data.level = level or self.data.level
    self.data.itemData = item or self.data.itemData
    self.data.lastCoord = GetEntityCoords(self.data.entity)
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
        local currentItem = {
            hash = activeped.itemData.info.hash,
            slot = activeped.itemData.slot
        }
        distance = math.floor(distance)
        ActivePed:update()

        if distance > 0 and IsPedInAnyVehicle(pedData.entity, true) ~= 1 then

            local Xp = pedData.XP
            local level = pedData.level
            local currentMaxXP = currentLvlExp(level)
            if level == Config.Balance.maximumLevel then
                return
            end
            local toNext
            if level ~= 0 then
                toNext = Xp + ((1 / level) * (currentMaxXP / 10))
            else
                toNext = Xp + ((1 / 1) * (currentMaxXP / 10))
            end
            if toNext >= currentMaxXP then
                ActivePed:update(nil, nil, nil, nil, toNext, level + 1)
                TriggerEvent('QBCore:Notify', activeped.itemData.info.name .. "level up to " .. activeped.level)
            else
                ActivePed:update(nil, nil, nil, nil, toNext, nil)
            end
            TriggerServerEvent('keep-companion:server:updateAllowedInfo', currentItem, {
                key = 'XP',
                content = Xp
            })
        end
    end
end
--- return max xp for current level
---@param level integer
function currentLvlExp(level)
    return math.floor(math.floor((level + 300) * (2 ^ (level / 7))) / 4)
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
            disableMovement = true,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true
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
                -- add pet to active thread
                creatActivePetThread(ped)
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
    CreateThread(function()
        -- it's table just to have passed by reference.
        local timeOut = {0}
        while DoesEntityExist(ped) do
            addXpForDistanceMoved()
            afkWandering(timeOut, goWanderingAfter)
            increasePetAge()
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
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
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
        local validation = ValidatePetName(name, 12) -- #TODO this sould be inside server
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

local bones = {'bodyshell'}
exports['qb-target']:AddTargetBone(bones, {
    options = {{ -- This is the first table with options, you can make as many options inside the options table as you want
        type = "client",
        event = "farming:harvestPlant",
        icon = "fa-solid fa-scythe",
        label = "Flip",
        action = function(entity)
            local plyped = PlayerPedId()
            CoreName.Functions.Progressbar("flipingcAr", "Fliping car", Config.Settings.carFlipingDuration * 1000,
                false, false, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = true,
                    disableCombat = true
                }, {}, {}, {}, function()
                    ClearPedTasks(plyped)
                    Citizen.CreateThread(function()
                        local coord = GetEntityCoords(entity)
                        local x, y, z = table.unpack(coord)
                        local xx, yy, zz = GetEntityRotation(entity, 5)
                        ground, posZ = GetGroundZFor_3dCoord(x + .0, y + .0, z, true)

                        SetEntityRotation(entity, 0.0, yy, zz)
                        SetEntityCoords(entity, x, y, posZ, 1, 0, 0, 1)
                    end)
                end)

        end
    }},
    distance = 2.0
})
