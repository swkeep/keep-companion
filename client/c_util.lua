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
    QBCore.Functions.TriggerCallback("qb-shops:server:getLicenseStatus", function(hasLicense, hasLicenseItem)
        ShopItems.label = data["label"]
        if data.type == "weapon" then
            if hasLicense and hasLicenseItem then
                ShopItems.items = SetupItems(shop)
                QBCore.Functions.Notify(Lang:t("success.dealer_verify"), "success")
                Wait(500)
            else
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
                QBCore.Functions.Notify(Lang:t("error.dealer_decline"), "error")
                Wait(500)
                QBCore.Functions.Notify(Lang:t("error.talk_cop"), "error")
                Wait(1000)
            end
        else
            ShopItems.items = SetupItems(shop)
        end
        for k, v in pairs(ShopItems.items) do
            ShopItems.items[k].slot = k
        end
        ShopItems.slots = 15
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "Itemshop_" .. shop, ShopItems)
    end)
end

local shop = 'petShop'

exports['qb-target']:SpawnPed({
    model = Config.Locations[shop]["ped"]["model"], -- This is the ped model that is going to be spawning at the given coords
    coords = Config.Locations[shop]["coords"][1], -- This is the coords that the ped is going to spawn at, always has to be a vector4 and the w value is the heading
    minusOne = true, -- Set this to true if your ped is hovering above the ground but you want it on the ground (OPTIONAL)
    freeze = true, -- Set this to true if you want the ped to be frozen at the given coords (OPTIONAL)
    invincible = true, -- Set this to true if you want the ped to not take any damage from any source (OPTIONAL)
    blockevents = true, -- Set this to true if you don't want the ped to react the to the environment (OPTIONAL)
    target = { -- This is the target options table, here you can specify all the options to display when targeting the ped (OPTIONAL)
        options = { -- This is your options table, in this table all the options will be specified for the target to accept
        { -- This is the first table with options, you can make as many options inside the options table as you want
            type = "client", -- This specifies the type of event the target has to trigger on click, this can be "client", "server", "command" or "qbcommand", this is OPTIONAL and will only work if the event is also specified
            icon = 'fas fa-shopping-basket', -- This is the icon that will display next to this trigger option
            label = 'Open Shop', -- This is the label of this option which you would be able to click on to trigger everything, this has to be a string
            action = function(entity) -- This is the action it has to perform, this REPLACES the event and this is OPTIONAL
                openShop(shop, Config.Locations[shop])
            end
        }},
        distance = 2.5 -- This is the distance for you to be at for the target to turn blue, this is in GTA units and has to be a float value
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
