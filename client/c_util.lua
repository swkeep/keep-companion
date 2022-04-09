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

local function SetupItems(shop)
    local products = Config.Locations[shop].products
    local playerJob = QBCore.Functions.GetPlayerData().job.name
    local items = {}
    for i = 1, #products do
        if not products[i].requiredJob then
            items[#items + 1] = products[i]
        else
            for i2 = 1, #products[i].requiredJob do
                if playerJob == products[i].requiredJob[i2] then
                    items[#items + 1] = products[i]
                end
            end
        end
    end
    return items
end

local function openShop(shop, data)
    local products = data.products
    local ShopItems = {}
    ShopItems.items = {}
    ShopItems.label = data["label"]
    for i = 1, #products do
        if not products[i].requiredJob then
            if not products[i].requiresLicense then
                ShopItems.items[#ShopItems.items + 1] = products[i]
            end
        else
            for i2 = 1, #products[i].requiredJob do
                if QBCore.Functions.GetPlayerData().job.name == products[i].requiredJob[i2] and
                    not products[i].requiresLicense then
                    ShopItems.items[#ShopItems.items + 1] = products[i]
                end
            end
        end
    end
    ShopItems.items = SetupItems(shop)
    for k, v in pairs(ShopItems.items) do
        ShopItems.items[k].slot = k
    end
    ShopItems.slots = #Config.Products.petShop
    TriggerServerEvent("inventory:server:OpenInventory", "shop", "Itemshop_" .. shop, ShopItems)
end

local shop = 'petShop'

exports['qb-target']:SpawnPed({
    model = Config.Locations[shop]["ped"]["model"],
    coords = Config.Locations[shop]["coords"][1],
    minusOne = true,
    freeze = true,
    invincible = true,
    blockevents = true,
    target = {
        options = {{
            type = "client",
            icon = 'fas fa-shopping-basket',
            label = 'Open Shop',
            action = function(entity)
                openShop(shop, Config.Locations[shop])
            end
        }},
        distance = 2.5
    }
})

if Config.Locations.petShop.showblip == true then
    createBlip({
        petShop = Config.Locations[shop]["coords"][1],
        sprite = Config.Locations.petShop.blipsprite,
        colour = Config.Locations.petShop.colour,
        text = Config.Locations.petShop.label,
        shortRange = true
    })
end
