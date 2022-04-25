function calNextXp(level)
    local maxExp = math.floor(math.floor((level + 300) * (2 ^ (level / 7))) / 4)
    local minExp = math.floor(math.floor(((level - 1) + 300) * (2 ^ ((level - 1) / 7))) / 4)
    local dif = maxExp - minExp
    local pr = math.floor(maxExp / minExp)
    local multi = 1
    return math.floor(dif / (multi * (level + 1) * pr))
end

--- return max xp for current level
---@param level integer
function currentLvlExp(level)
    return math.floor(math.floor((level + 300) * (2 ^ (level / 7))) / 4)
end

function makeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
end

function TaskFollowTargetedPlayer(follower, targetPlayer, distanceToStopAt)
    TaskFollowToOffsetOfEntity(follower, targetPlayer, 2.5, 2.5, 2.5, 5.0, 10.0, distanceToStopAt, 1)
end

function wanderAroundWithDuration(ped, coord, radius, minimalLength, timeBetweenWalks)
    local duration = 10
    CreateThread(function()
        local count = 0
        local continue = true
        while continue and DoesEntityExist(ped) do
            Wait(1000)
            count = count + 1
            if not GetIsTaskActive(ped, 222) then
                TaskWanderInArea(ped, coord, radius, minimalLength, timeBetweenWalks)
            end
            if count >= duration then
                continue = false
                ClearPedTasks(ped)
            end
        end
    end)
end

--- func desc
---@param ped 'ped'
---@param targetPed 'ped'
---@param fleeTimeout integer
function taskAttackTarget(ped, targetPed, fleeTimeout, item)
    TaskCombatPed(ped, targetPed, 0, 16)
    CreateThread(function()
        Wait(fleeTimeout)
        TaskSmartFleePed(ped, targetPed, 100.0, 10.0, 0, 0)
        if item ~= nil then
            local maxDistance = Config.Settings.fleeFromNotOwenerDistance
            local finished = false
            while DoesEntityExist(ped) and finished == false do
                local plyCoord = GetEntityCoords(targetPed)
                local pedCoord = GetEntityCoords(ped)
                local distance = GetDistanceBetweenCoords(plyCoord, pedCoord)
                if distance > maxDistance then
                    -- #TODO this should remove pet from server too
                    ActivePed:remove(ActivePed:findByHash(item.info.hash))
                    finished = true
                end
                Wait(1000)
            end
        end
    end)
end

--- remove Relationship againt player.
---@param ped 'ped'
function removeRelationship(ped)
    if not ped then
        return
    end
    RemovePedFromGroup(ped)
end

--- set relationship with ped againt player. and disable Friendly fire when fighting againt player.
---@param ped 'ped'
function SetRelationshipBetweenPed(ped)
    if not ped then
        return
    end
    -- note: if we don't do this they will star fighting among themselves!
    RemovePedFromGroup(ped)
    SetPedRelationshipGroupHash(ped, GetHashKey(ped))
    SetCanAttackFriendly(ped, false, false)
end

function whistleAnimation(ped, timeout)
    CreateThread(function()
        waitForAnimation('rcmnigel1c')
        TaskPlayAnim(ped, "rcmnigel1c", "hailing_whistle_waive_a", 2.7, 2.7, -1, 49, 0, 0, 0, 0)
        Wait(timeout)
        ClearPedTasks(ped)
    end)
end

--- wait until animation is loaded
---@param animation any
function waitForAnimation(animation)
    RequestAnimDict(animation)
    while not HasAnimDictLoaded(animation) do
        Citizen.Wait(100)
    end
    return true
end

--- wait until model loaded
---@param model 'model'
function waitForModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(1)
    end
    return true
end

--- make blip
---@param data table
function createBlip(data)
    local blip = nil
    if data.petShop ~= nil then
        -- make blip for shop
        blip = AddBlipForCoord(data.petShop.x, data.petShop.y, data.petShop.z)
    elseif data.entity ~= nil then
        -- make blip for entities
        blip = AddBlipForEntity(data.entity)
    end
    if data.shortRange ~= nil and data.shortRange == true then
        SetBlipAsShortRange(blip, true)
    elseif data.shortRange == false then
        SetBlipAsShortRange(blip, false)
    end

    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.colour)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.text)
    EndTextCommandSetBlipName(blip)
    return blip
end

function DeletePed(ped)
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end

function CreateAPed(hash, pos)
    local ped = nil
    waitForModel(hash)

    ped = CreatePed(5, hash, pos.x, pos.y, pos.z, 0.0, true, false)

    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetModelAsNoLongerNeeded(ped)
    return ped
end

--- creates laser and force ped to move toward coord
---@param ped 'ped'
function goThere(ped)
    local activeLaser = true
    while activeLaser do
        Wait(0)
        local color = {
            r = 2,
            g = 241,
            b = 181,
            a = 200
        }
        local plyped = PlayerPedId()
        local position = GetEntityCoords(plyped)
        local coords, entity = RayCastGamePlayCamera(1000.0)
        Draw2DText('Press ~g~E~w~ To go there', 4, { 255, 255, 255 }, 0.4, 0.43, 0.888 + 0.025)
        if IsControlJustReleased(0, 38) then
            TaskGoToCoordAnyMeans(ped, coords, 10.0, 0, 0, 0, 0)
            activeLaser = false
        end
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g,
            color.b, color.a, false, true, 2, nil, nil, false)
    end
end

--- logic to warp peds inside vehicles
function getIntoCar()
    local plyped = PlayerPedId()
    local ped = ActivePed:read().entity
    local coords = GetEntityCoords(plyped)
    local coords2 = GetEntityCoords(ped)
    local distance = GetDistanceBetweenCoords(coords, coords2, true)
    if IsPedSittingInAnyVehicle(plyped) then
        if distance < 8 then
            local vehicle = GetVehiclePedIsUsing(plyped)
            local seatEmpty = 6
            Citizen.Wait(200)
            for i = 1, 5, 1 do
                if IsVehicleSeatFree(vehicle, i - 2) then
                    SetPedIntoVehicle(ped, vehicle, i - 2)
                    Animator(ped, ActivePed.read().model, 'siting', {
                        c_timings = 'REPEAT'
                    })
                    seatEmpty = i - 2
                    goto here
                end
            end
            ::here::
            if seatEmpty == 6 then
                TriggerEvent('QBCore:Notify', "No empty seat!")
            end
        else
            TriggerEvent('QBCore:Notify', "To far")
        end
    else
        TriggerEvent('QBCore:Notify', "you need to be inside a car")
    end
end

function attackLogic()
    local activeLaser = true
    while activeLaser do
        Wait(0)
        local color = {
            r = 2,
            g = 241,
            b = 181,
            a = 200
        }
        local plyped = PlayerPedId()
        local position = GetEntityCoords(plyped)
        local coords, entity = RayCastGamePlayCamera(1000.0)
        Draw2DText('PRESS ~g~E~w~ TO ATTACK TARGET', 4, { 255, 255, 255 }, 0.4, 0.43, 0.888 + 0.025)
        if IsControlJustReleased(0, 38) then
            ClearPedTasks(ActivePed:read().entity)
            if IsEntityAPed(entity) then
                CreateThread(function()

                    local pet = ActivePed:read().entity
                    local finished = false
                    AttackTargetedPed(ActivePed:read().entity, entity)

                    while IsPedDeadOrDying(entity) == false and finished == false do
                        -- draw every frame
                        Wait(0)
                        local pedCoord = GetEntityCoords(entity)
                        local petCoord = GetEntityCoords(pet)
                        local distance = GetDistanceBetweenCoords(pedCoord, petCoord)
                        if distance < Config.Settings.chaseDistance then
                            finished = true
                        end
                        DrawMarker(2, pedCoord.x, pedCoord.y, pedCoord.z + 2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0,
                            1.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)
                    end
                    Wait(1000)

                    -- #TODO give combat XP need better function
                    local pedData = ActivePed.read() or {}
                    if next(pedData) ~= nil then
                        local Xp = pedData.XP
                        local level = pedData.level
                        if level == Config.Balance.maximumLevel then
                            return
                        end

                        local Xp = Xp + (calNextXp(level) * 3)
                        ActivePed:update {
                            xp = Xp
                        }
                    end

                end)
                return true
            else
                return false
            end
            activeLaser = false
        end
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g,
            color.b, color.a, false, true, 2, nil, nil, false)
    end
end

function HuntandGrab(plyped, activePed)
    local activeLaser = true
    while activeLaser do
        Wait(0)
        local color = {
            r = 2,
            g = 241,
            b = 181,
            a = 200
        }
        local position = GetEntityCoords(plyped)
        local coords, entity = RayCastGamePlayCamera(1000.0)
        Draw2DText('Press ~g~E~w~ To go there', 4, { 255, 255, 255 }, 0.4, 0.43, 0.888 + 0.025)
        if IsControlJustReleased(0, 38) then
            local dragger = activePed.entity
            if IsPedAPlayer(entity) == 1 or IsEntityAPed(entity) == false or entity == dragger then
                QBCore.Functions.Notify('Could not do that', "error", 1500)
                return
            end
            CreateThread(function()
                local finished = false
                TaskFollowToOffsetOfEntity(dragger, entity, 0.0, 0.0, 0.0, 5.0, 10.0, 1.0, 1)
                while finished == false do
                    local pedCoord = GetEntityCoords(entity)
                    local petCoord = GetEntityCoords(dragger)
                    local distance = GetDistanceBetweenCoords(pedCoord, petCoord)
                    if distance < 5.0 then
                        AttackTargetedPed(dragger, entity)
                        -- wait until pet kill target
                        while IsPedDeadOrDying(entity) == false do
                            Wait(250)
                        end
                        -- drag dead body
                        SetEntityCoords(entity, GetOffsetFromEntityInWorldCoords(dragger, 0.0, 0.25, 0.0))
                        AttachEntityToEntity(entity, dragger, 11816, 0.05, 0.05, 0.5, 0.0, 0.0, 0.0, false, false,
                            false, false, 2, true)
                        finished = true
                    elseif distance > 50.0 then
                        -- skip when to much distance
                        finished = true
                    end
                    Wait(1000)
                end
                -- Detach entity when it has to much distance or it's near player
                CreateThread(function()
                    local finished = false
                    local playerPed = plyped
                    TaskFollowToOffsetOfEntity(dragger, playerPed, 2.0, 2.0, 2.0, 1.0, 10.0, 3.0, 1)
                    while finished == false do
                        local pedCoord = GetEntityCoords(playerPed)
                        local petCoord = GetEntityCoords(dragger)
                        local distance = GetDistanceBetweenCoords(pedCoord, petCoord)
                        if distance < 3.0 or distance > 50.0 then
                            DetachEntity(entity, true, false)
                            ClearPedSecondaryTask(dragger)
                            finished = true
                        end
                        Wait(1000)
                    end
                end)
            end)
            activeLaser = false
        end
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g,
            color.b, color.a, false, true, 2, nil, nil, false)
    end
end

--- if player is inside a vehicle we need to relocate ped location so they won't sucide
---@param ped 'ped'
function doSomethingIfPedIsInsideVehicle(ped)
    local playerped = PlayerPedId()
    local coord = getSpawnLocation(playerped)
    if IsPedInAnyVehicle(ped, true) then
        SetEntityCoords(ped, coord, 1, 0, 0, 1)
    end
    Wait(75)
end

function getSpawnLocation(plyped)
    if IsPedInAnyVehicle(plyped, true) then
        return GetOffsetFromEntityInWorldCoords(plyped, -2.0, 1.0, 0.5)
    else
        return GetOffsetFromEntityInWorldCoords(plyped, 1.0, -1.0, 0.5)
    end
end

--- gives ped ability to follow and attack targeted ped
---@param AttackerPed 'ped'
---@param targetPed 'ped'
---@return 'void'
function AttackTargetedPed(AttackerPed, targetPed)
    if not AttackerPed and not targetPed then
        return
    end
    SetPedCombatAttributes(AttackerPed, 46, 1)
    TaskGoToEntityWhileAimingAtEntity(AttackerPed, targetPed, targetPed, 8.0, 1, 0, 15, 1, 1, 1566631136)
    TaskCombatPed(AttackerPed, targetPed, 0, 16)
    SetRelationshipBetweenPed(AttackerPed)
    SetPedCombatMovement(AttackerPed, 3)

    CreateThread(function()
        while not IsPedDeadOrDying(targetPed) do
            Wait(2000)
            -- skip
        end
        TaskFollowTargetedPlayer(AttackerPed, PlayerPedId(), 3.0)
    end)
end
