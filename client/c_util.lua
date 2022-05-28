function Draw2DText(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1], colour[2], colour[3], 255)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    AddTextComponentString(content)
    DrawText(x, y)
end

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z,
        destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return c, e
end

-- -- flip car if needed
-- local bones = { 'bodyshell' }
-- exports['qb-target']:AddTargetBone(bones, {
--     options = { { -- This is the first table with options, you can make as many options inside the options table as you want
--         type = "client",
--         icon = "fa-solid fa-scythe",
--         label = "Flip",
--         action = function(entity)
--             local QBcore = exports['qb-core']:GetCoreObject()
--             QBcore.Functions.Progressbar("flipingcAr", "Fliping car", Config.Settings.carFlipingDuration * 1000,
--                 false, false, {
--                     disableMovement = true,
--                     disableCarMovement = true,
--                     disableMouse = true,
--                     disableCombat = true
--                 }, {}, {}, {}, function()
--                 local plyped = PlayerPedId()
--                 ClearPedTasks(plyped)
--                 Citizen.CreateThread(function()
--                     local coord = GetEntityCoords(entity)
--                     local x, y, z = table.unpack(coord)
--                     local xx, yy, zz = GetEntityRotation(entity, 5)
--                     ground, posZ = GetGroundZFor_3dCoord(x + .0, y + .0, z, true)

--                     SetEntityRotation(entity, 0.0, yy, zz)
--                     SetEntityCoords(entity, x, y, posZ, 1, 0, 0, 1)
--                 end)
--             end)
--         end
--     } },
--     distance = 2.0
-- })
