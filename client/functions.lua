function makeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
end

function TaskFollowTargetedPlayer(follower, targetPlayer, distanceToStopAt, skip)
    ClearPedTasks(follower)
    if skip == false then
        TaskGoToCoordAnyMeans(follower, GetEntityCoords(targetPlayer), 10.0, 0, 0, 0, 0)
        Wait(5000)
    end
    TaskFollowToOffsetOfEntity(follower, targetPlayer, 2.5, 2.5, 2.5, 5.0, 10.0, distanceToStopAt, 1)
    return true
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

    while not DoesEntityExist(ped) do
        Wait(10)
    end

    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetModelAsNoLongerNeeded(ped)
    return ped
end

--- creates laser and force ped to move toward coord
---@param ped 'ped'
function goThere(ped)
    while true do
        local color = { r = 2, g = 241, b = 181, a = 200 }
        local plyped = PlayerPedId()
        local position = GetEntityCoords(plyped)
        local coords, entity = RayCastGamePlayCamera(1000.0)
        Draw2DText('Press ~g~E~w~ To go there', 4, { 255, 255, 255 }, 0.4, 0.43, 0.888 + 0.025)
        if IsControlJustReleased(0, 38) then
            TaskGoToCoordAnyMeans(ped, coords, 10.0, 0, 0, 0, 0)
            return
        end
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g,
            color.b, color.a, false, true, 2, nil, nil, false)
        Wait(0)
    end
end

--- logic to warp peds inside vehicles
function getIntoCar()
    local plyped = PlayerPedId()
    local ped = ActivePed:read().entity
    local player_coord = GetEntityCoords(plyped)
    local pet_coord = GetEntityCoords(ped)
    local distance = #(player_coord - pet_coord)
    if not IsPedSittingInAnyVehicle(plyped) then
        QBCore.Functions.Notify(Lang:t('error.need_to_be_inside_car'), "error", 1500)
        return
    end
    if distance > 8 then
        QBCore.Functions.Notify(Lang:t('error.to_far'), "error", 1500)
        return
    end
    local vehicle = GetVehiclePedIsUsing(plyped)
    local seatEmpty = 6

    for i = 1, 5, 1 do
        if IsVehicleSeatFree(vehicle, i - 2) then
            SetPedIntoVehicle(ped, vehicle, i - 2)
            Animator(ped, ActivePed.read().model, 'siting', {
                c_timings = 'REPEAT'
            })
            seatEmpty = i - 2
            break
        end
    end

    if seatEmpty == 6 then
        QBCore.Functions.Notify(Lang:t('error.no_empty_seat'), "error", 1500)
        return
    end
end

function attackLogic(alreadyHunting)
    while true do
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
            if IsEntityAPed(entity) ~= 1 then
                return false
            end

            local pet = ActivePed:read().entity
            local chaseDistance = Config.Settings.chaseDistance
            local indicator = Config.Settings.chaseIndicator
            AttackTargetedPed(pet, entity)
            alreadyHunting.state = true
            while IsPedDeadOrDying(entity) == false do
                -- draw every frame
                Wait(5)
                local pedCoord = GetEntityCoords(entity)
                local petCoord = GetEntityCoords(pet)
                local distance = GetDistanceBetweenCoords(pedCoord, petCoord)

                DrawMarker(2, pedCoord.x, pedCoord.y, pedCoord.z + 2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0,
                    1.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)

                if indicator ~= false and IsPedDeadOrDying(entity) ~= false then
                    alreadyHunting.state = false
                    return true
                end
                if distance >= chaseDistance then
                    alreadyHunting.state = false
                    return true
                end
            end
            -- later ask server to give xp
            alreadyHunting.state = false
            return true
        end
        -- target
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g,
            color.b, color.a, false, true, 2, nil, nil, false)
    end
end

function HuntandGrab(plyped, activePed)
    while true do
        Wait(0)
        local color = { r = 2, g = 241, b = 181, a = 200 }
        local position = GetEntityCoords(plyped)
        local coords, entity = RayCastGamePlayCamera(1000.0)
        Draw2DText('Press ~g~E~w~ To go there', 4, { 255, 255, 255 }, 0.4, 0.43, 0.888 + 0.025)
        if IsControlJustReleased(0, 38) then
            local pet = activePed.entity
            if IsPedAPlayer(entity) == 1 or IsEntityAPed(entity) == false or entity == pet then
                QBCore.Functions.Notify(Lang:t('error.could_not_do_that'), "error", 1500)
                return
            end

            TaskFollowToOffsetOfEntity(pet, entity, 0.0, 0.0, 0.0, 5.0, 10.0, 1.0, 1)
            while true do
                local pedCoord = GetEntityCoords(entity)
                local petCoord = GetEntityCoords(pet)
                local distance = GetDistanceBetweenCoords(pedCoord, petCoord)
                if distance >= 50.0 then
                    -- skip when to much distance
                    break
                else
                    AttackTargetedPed(pet, entity)
                    -- wait until pet kills target
                    while IsPedDeadOrDying(entity) == false do
                        Wait(250)
                    end
                    -- drag dead body
                    SetEntityCoords(entity, GetOffsetFromEntityInWorldCoords(pet, 0.0, 0.25, 0.0))
                    AttachEntityToEntity(entity, pet, 11816, 0.05, 0.05, 0.5, 0.0, 0.0, 0.0, false, false,
                        false, false, 2, true)
                    -- finish loop
                    break
                end
                Wait(500)
            end
            -- Detach entity when it has to much distance or it's near player

            TaskFollowToOffsetOfEntity(pet, plyped, 2.0, 2.0, 2.0, 1.0, 10.0, 3.0, 1)
            while true do
                local pedCoord = GetEntityCoords(plyped)
                local petCoord = GetEntityCoords(pet)
                local distance = GetDistanceBetweenCoords(pedCoord, petCoord)
                if entity ~= nil and distance < 3.0 or distance > 50.0 then
                    DetachEntity(entity, true, false)
                    ClearPedSecondaryTask(pet)
                    return
                end
                Wait(1000)
            end
            return -- just incase
        end
        DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
        DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r, color.g,
            color.b, color.a, false, true, 2, nil, nil, false)
    end
end

function get_player_cid()
    local players = GetActivePlayers()

    for _, player in pairs(players) do
        if player == PlayerId() then
            return _
        end
    end
    return false
end

function SearchLogic(plyped, activePed)
    if not PlayerJob then return end
    if not (PlayerJob.name == 'police') then
        QBCore.Functions.Notify('You are not allowed to do this action', "error", 1500)
        return
    end

    if not PlayerJob.onduty == true then
        QBCore.Functions.Notify('You Must be on duty to do this action', "error", 1500)
        return
    end

    ClearPedTasks(ActivePed:read().entity)
    local pedCoord = GetEntityCoords(PlayerPedId())
    local closestPlayer = QBCore.Functions.GetClosestPlayer(pedCoord)
    if closestPlayer == -1 then
        return
    end
    local pedplayer = GetPlayerPed(closestPlayer)
    TaskGoToCoordAnyMeans(activePed.entity, GetEntityCoords(pedplayer), 10.0, 0, 0, 0, 0)

    local finished = false
    CreateThread(function()
        while finished == false do
            -- draw every frame
            Wait(5)
            pedCoord = GetEntityCoords(GetPlayerPed(closestPlayer))
            DrawMarker(2, pedCoord.x, pedCoord.y, pedCoord.z + 2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 1.0, 1.0,
                1.0, 255, 128, 0, 50, false, true, 2, nil, nil, false)
        end
    end)


    local player_server_id = GetPlayerServerId(closestPlayer)
    QBCore.Functions.TriggerCallback('keep-companion:server:search_inventory', function(result)
        Wait(5000)

        Animator(activePed.entity, activePed.model, 'misc', {
            animation = 'indicate_low',
            sequentialTimings = {
                -- How close the value is to the Timeout value determines how fast the script moves to the next animation.
                [1] = 6, -- start animation Timeout ==> 1sec(6s-5s) to loop
                [2] = 0, -- loop animation Timeout  ==> 6sec(6s-0s) to exit
                [3] = 2, -- exit animation Timeout  ==> 4sec(6s-2s) to end
                step = 1,
                Timeout = 6
            }
        })
        Wait(5000)
        if result == true then
            TriggerEvent('QBCore:Notify', 'K9 found something', 'success', 2500)
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
        end
        finished = true
    end, player_server_id)
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
        return false
    end
    SetPedCombatAttributes(AttackerPed, 46, 1)
    TaskGoToEntityWhileAimingAtEntity(AttackerPed, targetPed, targetPed, 8.0, 1, 0, 15, 1, 1, 1566631136)
    TaskCombatPed(AttackerPed, targetPed, 0, 16)
    SetRelationshipBetweenPed(AttackerPed)
    SetPedCombatMovement(AttackerPed, 3)


    while IsPedDeadOrDying(targetPed, 0) ~= 1 do
        Wait(1000)
        -- skip
    end
    TaskFollowTargetedPlayer(AttackerPed, PlayerPedId(), 3.0, false)
end
