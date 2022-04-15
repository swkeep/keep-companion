function warpPedAroundPlayer(ped)
    local currentPlayerCoord = GetEntityCoords(PlayerPedId())
    local x, y, z = table.unpack(currentPlayerCoord)
    SetEntityCoords(ped, x + 0.5, y + 0.5, z, 0, 0, 0, 0)
end

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
                    playAnimation(ped, 'retriever', 'siting', 'look_around', ActivePed:read().model, 'REPEAT')
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
                        ActivePed:update{
                            xp = Xp
                        }
                    end

                end)

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
        Draw2DText('Press ~g~E~w~ To go there', 4, {255, 255, 255}, 0.4, 0.43, 0.888 + 0.025)
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

function playAnimation(ped, petType, state, animation, currentPetType, c_timings)
    -- c_timings = REPEAT , STOP_LAST_FRAME , UPPERBODY ,ENABLE_PLAYER_CONTRO , CANCELABLE
    local animationList = {
        ['retriever'] = {
            ['standing'] = {
                ['normal_bark'] = {
                    animDictionary = 'creatures@retriever@amb@world_dog_barking@idle_a',
                    animationName = 'idle_a'
                },
                ['standing_bark'] = {
                    animDictionary = 'creatures@retriever@amb@world_dog_barking@idle_a',
                    animationName = 'idle_b'
                },
                ['rotate_bark'] = {
                    animDictionary = 'creatures@retriever@amb@world_dog_barking@idle_a',
                    animationName = 'idle_c'
                }
            },
            ['siting'] = {
                ['self_itch'] = {
                    animDictionary = 'creatures@retriever@amb@world_dog_sitting@idle_a',
                    animationName = 'idle_a'
                },
                ['look_around'] = {
                    animDictionary = 'creatures@retriever@amb@world_dog_sitting@idle_a',
                    animationName = 'idle_b',
                    skip = {'A_C_Westy', 'A_C_Pug', 'A_C_Poodle', 'A_C_Cat_01', 'A_C_MtLion', 'A_C_Panther'}
                },
                ['sit_Up'] = {
                    animDictionary = 'creatures@retriever@amb@world_dog_sitting@idle_a',
                    animationName = 'idle_c'
                },
                ['sit'] = {
                    animDictionary = 'creatures@retriever@amb@world_dog_sitting@base',
                    animationName = 'base'
                }
            },
            ['misc'] = {
                ['indicate_ahead'] = {
                    animDictionary = 'creatures@rottweiler@indication@',
                    animationName = 'indicate_ahead'
                },
                ['indicate_high'] = {
                    animDictionary = 'creatures@rottweiler@indication@',
                    animationName = 'indicate_high'
                },
                ['indicate_low'] = {
                    animDictionary = 'creatures@rottweiler@indication@',
                    animationName = 'indicate_low'
                }
            }
        },
        ['rottweiler'] = {
            ['standing'] = {},
            ['siting'] = {},
            ['misc'] = {
                ['indicate_ahead'] = {
                    animDictionary = 'creatures@rottweiler@indication@',
                    animationName = 'indicate_ahead'
                },
                ['indicate_high'] = {
                    animDictionary = 'creatures@rottweiler@indication@',
                    animationName = 'indicate_high'
                },
                ['indicate_low'] = {
                    animDictionary = 'creatures@rottweiler@indication@',
                    animationName = 'indicate_low'
                }
            },
            ['tricks'] = {
                ['beg_enter'] = {
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'beg_enter'
                },
                ['beg_exit'] = {
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'beg_exit'
                },
                ['beg_loop'] = {
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'beg_loop'
                },
                ['paw_right_enter'] = {
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'paw_right_enter'
                },
                ['paw_right_exit'] = {
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'paw_right_exit'
                },
                ['paw_right_loop'] = {
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'paw_right_loop'
                },
                ['petting_chop'] = {
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'petting_chop',
                    skip = {'A_C_Westy', 'A_C_Pug', 'A_C_Poodle', 'A_C_Cat_01', 'A_C_MtLion', 'A_C_Panther'}
                },
                ['petting_franklin'] = { -- this is for human that is petting dog!
                    animDictionary = 'creatures@rottweiler@tricks@',
                    animationName = 'petting_franklin'
                }
            },
            ['hump'] = {
                ['hump_enter_chop'] = {
                    animDictionary = 'creatures@rottweiler@amb@',
                    animationName = 'hump_enter_chop'
                },
                ['hump_enter_ladydog'] = {
                    animDictionary = 'creatures@rottweiler@amb@',
                    animationName = 'hump_enter_ladydog'
                },
                ['hump_exit_chop'] = {
                    animDictionary = 'creatures@rottweiler@amb@',
                    animationName = 'hump_exit_chop'
                },
                ['hump_exit_ladydog'] = {
                    animDictionary = 'creatures@rottweiler@amb@',
                    animationName = 'hump_exit_ladydog'
                },
                ['hump_loop_chop'] = {
                    animDictionary = 'creatures@rottweiler@amb@',
                    animationName = 'hump_loop_chop'
                },
                ['hump_loop_ladydog'] = {
                    animDictionary = 'creatures@rottweiler@amb@',
                    animationName = 'hump_loop_chop'
                }
            },
            ['sleep'] = {
                ['exit_kennel'] = {
                    animDictionary = 'creatures@rottweiler@amb@sleep_in_kennel@',
                    animationName = 'exit_kennel'
                },
                ['sleep_in_kennel'] = {
                    animDictionary = 'creatures@rottweiler@amb@sleep_in_kennel@',
                    animationName = 'sleep_in_kennel'
                }
            },
            ['pickup'] = {
                ['fetch_drop'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'fetch_drop'
                },
                ['fetch_pickup'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'fetch_pickup'
                }
            },
            ['dump'] = {
                ['dump_enter'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'dump_enter'
                },
                ['dump_exit'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'dump_exit'
                },
                ['dump_loop'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'dump_loop'
                }
            },
            ['pee'] = {
                ['pee_left_enter'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'pee_left_enter'
                },
                ['pee_left_exit'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'pee_left_exit'
                },
                ['pee_left_idle'] = {
                    animDictionary = 'CREATURES@ROTTWEILER@MOVE',
                    animationName = 'pee_left_idle'
                }
            }
        },
        ['cat'] = {
            ['standing'] = {
                ['idle'] = {
                    animDictionary = 'creatures@cat@move',
                    animationName = 'idle'
                },
                ['idle_dwn'] = {
                    animDictionary = 'creatures@cat@move',
                    animationName = 'idle_dwn'
                },
                ['idle_upp'] = {
                    animDictionary = 'creatures@cat@move',
                    animationName = 'idle_upp'
                }
            },
            ['siting'] = {
                ['sitting'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ledge@idle_a',
                    animationName = 'idle_a'
                }
            },
            ['misc'] = {},
            ['sleep'] = {
                ['enter_sleep'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ground@enter',
                    animationName = 'enter'
                },
                ['sleep'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ground@base',
                    animationName = 'base'
                },
                ['idle_sleep'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ground@idle_a',
                    animationName = 'idle_a'
                },
                ['exit_sleep'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ground@exit',
                    animationName = 'base'
                },
                ['exit2_sleep'] = {
                    animDictionary = 'creatures@cat@amb@peyote@enter',
                    animationName = 'enter'
                },
                ['exit_panic_sleep'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ground@exit',
                    animationName = 'idle_a'
                }
            }
        },
        ['cougar'] = {
            ['standing'] = {
                ['idle'] = {
                    animDictionary = 'creatures@cat@move',
                    animationName = 'idle'
                }

            },
            ['siting'] = {
                ['sitting'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ledge@idle_a',
                    animationName = 'idle_a'
                }
            },
            ['misc'] = {},
            ['sleep'] = {
                ['enter_sleep'] = {
                    animDictionary = 'creatures@cat@amb@world_cat_sleeping_ground@enter',
                    animationName = 'enter'
                }

            }
        }
    }

    -- if currentPetType is provided if we find it inside animation skip value we will skip this animation
    if animationList[petType][state][animation].skip ~= nil and currentPetType ~= nil then
        for key, value in pairs(animationList[petType][state][animation].skip) do
            if currentPetType == value then
                return
            end
        end
    end

    local c_animDictionary = animationList[petType][state][animation].animDictionary
    local c_animationName = animationList[petType][state][animation].animationName
    waitForAnimation(c_animDictionary)
    local flag = -1
    local slow = -1
    if c_timings ~= nil then
        if c_timings == 'REPEAT' then
            flag = 1
        elseif c_timings == 'STOP_LAST_FRAME' then
            flag = 2
        elseif c_timings == 'UPPERBODY' then
            flag = 16
        elseif c_timings == 'ENABLE_PLAYER_CONTROL' then
            flag = 32
        elseif c_timings == 'CANCELABLE' then
            flag = 120
        else
            flag = -1
        end
    end
    TaskPlayAnim(ped, c_animDictionary, c_animationName, 8.0, -8, slow, flag, 0, false, false, false)
end
