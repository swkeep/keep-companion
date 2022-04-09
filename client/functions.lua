function TaskFollowTargetedPlayer(follower, targetPlayer, distanceToStopAt)
    -- i'm not which one is better but TaskFollowToOffsetOfEntity looks more natural
    TaskFollowToOffsetOfEntity(follower, targetPlayer, 2.0, 2.0, 2.0, 5.0, 10.0, distanceToStopAt, 1)

    -- TaskGotoEntityAiming(follower, targetPlayer, distanceToStopAt, 5.0)

    -- CreateThread(function()
    --     while DoesEntityExist(follower) do
    --         Wait(1000)
    --         local targetCoord = GetEntityCoords(targetPlayer)
    --         local followerCoord = GetEntityCoords(follower)
    --         local distance = #(targetCoord - followerCoord)
    --         if distance > distanceToStopAt then
    --             ClearPedTasks(follower)
    --             TaskGoToCoordAnyMeans(follower, targetCoord, 5.0, 0, 786603, 0xbf800000)
    --         else
    --             -- put some idle animation here
    --         end
    --     end
    -- end)
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
function taskAttackTarget(ped, targetPed, fleeTimeout)
    TaskCombatPed(ped, targetPed, 0, 16)
    CreateThread(function()
        Wait(fleeTimeout)
        TaskSmartFleePed(ped, targetPed, 100.0, 10.0, 0, 0)
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
        Draw2DText('Press ~g~E~w~ To go there', 4, {255, 255, 255}, 0.4, 0.43, 0.888 + 0.025)
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
                    playerAnimation(ped, 'sitting')
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
        Draw2DText('PRESS ~g~E~w~ TO ATTACK TARGET', 4, {255, 255, 255}, 0.4, 0.43, 0.888 + 0.025)
        if IsControlJustReleased(0, 38) then
            if IsEntityAPed(entity) then
                SetEntityAsMissionEntity(entity, true, true)
                AttackTargetedPed(ActivePed:read().entity, entity)
            end
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
    if IsPedInAnyVehicle(ped, true) == 1 then
        local plyped = PlayerPedId()
        if IsPedInAnyVehicle(plyped, true) then
            local vehicle = GetVehiclePedIsIn(plyped, false)
            local forward = GetEntityForwardVector(plyped)
            local trunkpos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "door_pside_f"))
            local x, y, z = table.unpack(trunkpos + forward * 2.5)
            SetEntityCoords(ped, x, y, z, 1, 0, 0, 1)
        else
            SetEntityCoords(ped, GetEntityCoords(plyped), 1, 0, 0, 1)
        end
    end
end

--- plays requested animation 
---@param ped 'ped'
---@param animation 'animation name'
function playerAnimation(ped, animation)
    -- sitting animation
    if animation == 'sleep_medium' then
        waitForAnimation('creatures@rottweiler@amb@sleep_in_kennel@')
        TaskPlayAnim(ped, 'creatures@rottweiler@amb@sleep_in_kennel@', 'sleep_in_kennel', 8.0, -8, -1, 1, 0, false,
            false, false)
    elseif animation == 'sleep_small' then
        waitForAnimation('creatures@coyote@amb@world_coyote_rest@idle_a')
        TaskPlayAnim(ped, 'creatures@coyote@amb@world_coyote_rest@idle_a', 'idle_a', 8.0, -8, -1, 1, 0, false, false,
            false)
    elseif animation == 'idle_a' then
        waitForAnimation('creatures@rottweiler@amb@world_dog_sitting@base')
        TaskPlayAnim(ped, 'creatures@rottweiler@amb@world_dog_sitting@base', 'base', 8.0, -8, -1, 1, 0, false, false,
            false)
    elseif animation == 'idle_b' then
        waitForAnimation('creatures@carlin@amb@world_dog_sitting@idle_a')
        TaskPlayAnim(ped, 'creatures@carlin@amb@world_dog_sitting@idle_a', 'idle_b', 8.0, -8, -1, 1, 0, false, false,
            false)
    elseif animation == 'sitting' then
        waitForAnimation('creatures@retriever@amb@world_dog_sitting@idle_a')
        TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_sitting@idle_a', 'idle_c', 8.0, -8, -1, 1, 0, false, false,
            false)
    elseif animation == 'sitting_idle' then
        waitForAnimation('creatures@rottweiler@amb@world_dog_sitting@idle_a')
        TaskPlayAnim(ped, 'creatures@rottweiler@amb@world_dog_sitting@idle_a', 'idle_c', 8.0, -8, -1, 1, 0, false,
            false, false)
    elseif animation == 'none' then
        ClearPedTasks(ped)
    end

    -- -- idle bark
    -- waitForAnimation('creatures@retriever@amb@world_dog_barking@idle_a')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_barking@idle_a', 'idle_a', 8.0, -8, -1, 1, 0, false, false,
    --     false)
    -- -- idel bark base
    -- waitForAnimation('creatures@retriever@amb@world_dog_barking@base')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_barking@base', 'base', 8.0, -8, -1, 1, 0, false, false, false)
    -- -- idle but with high jumping bark
    -- waitForAnimation('creatures@retriever@amb@world_dog_barking@idle_a')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_barking@idle_a', 'idle_b', 8.0, -8, -1, 1, 0, false, false,
    --     false)

    -- -- rotate around + bark
    -- waitForAnimation('creatures@retriever@amb@world_dog_barking@idle_a')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_barking@idle_a', 'idle_c', 8.0, -8, -1, 1, 0, false, false,
    --     false)
    -- -- siting dog base
    -- waitForAnimation('creatures@retriever@amb@world_dog_sitting@base')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_sitting@base', 'base', 8.0, -8, -1, 1, 0, false, false, false)

    -- -- sitting idle self itch
    -- waitForAnimation('creatures@retriever@amb@world_dog_sitting@idle_a')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_sitting@idle_a', 'idle_a', 8.0, -8, -1, 1, 0, false, false,
    --     false)

    -- -- sitting idle look around
    -- waitForAnimation('creatures@retriever@amb@world_dog_sitting@idle_a')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_sitting@idle_a', 'idle_b', 8.0, -8, -1, 1, 0, false, false,
    --     false)
    -- -- sitting idle full sit and up
    -- waitForAnimation('creatures@retriever@amb@world_dog_sitting@idle_a')
    -- TaskPlayAnim(ped, 'creatures@retriever@amb@world_dog_sitting@idle_a', 'idle_c', 8.0, -8, -1, 1, 0, false, false,
    --     false)

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
