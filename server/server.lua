local QBCore = exports['qb-core']:GetCoreObject()
-- pet system
local maxLimit = Config.MaxActivePetsPetPlayer

-- ============================
--          Class
-- ============================

Pet = {
    players = {}
}

--- search for player(source) item's hash inside Pet list
---@param source integer
---@param item table
function Pet:isSpawned(source, item)
    if self.players[source] ~= nil then
        for key, table in pairs(self.players[source]) do
            if item.info.hash == key then
                return true
            end
        end
    end
    return false
end

--- add pet to Pet table
---@param source integer
---@param item table
---@param model string
---@param entity 'entity'
function Pet:setAsSpawned(source, item, model, entity)
    self.players[source] = self.players[source] or {}
    self.players[source][item.info.hash] = self.players[source][item.info.hash] or {}
    self.players[source][item.info.hash].model = model
    self.players[source][item.info.hash].entity = entity
end

--- removes pet from Pet table
---@param source integer
---@param item table
function Pet:setAsDespawned(source, item)
    self.players[source] = self.players[source] or {}
    self.players[source][item.info.hash] = nil
end

--- start spawn chain
---@param source integer
---@param model string
---@param item table
function Pet:spawnPet(source, model, item)
    -- sumun pet when it does exist inside our database
    local isSpawned = Pet:isSpawned(source, item)
    if isSpawned == true then
        -- depsawn ped
        Pet:despawnPet(source, item)
    else
        local limit = Pet:isMaxLimitPedReached(source)
        if limit == true then
            TriggerClientEvent('QBCore:Notify', source, "you can't have more than " .. maxLimit .. " active pets!")
            return
        end
        local Player = QBCore.Functions.GetPlayer(source)
        -- spawn ped
        if item.weight == 500 then
            -- need inital values
            local Player = QBCore.Functions.GetPlayer(source)

            if Player.PlayerData.items[item.slot] then
                Player.PlayerData.items[item.slot].weight = math.random(1000, 4500)
            end
            Player.Functions.SetInventory(Player.PlayerData.items, true)
        end

        -- if player that is spawning pet is not owener spawn pet as hostile toward that player
        if item.info.owner.phone == Player.PlayerData.charinfo.phone then
            -- owner of pet
            TriggerClientEvent('keep-companion:client:callCompanion', source, model, false, item)

        else
            -- not owner
            TriggerClientEvent('keep-companion:client:callCompanion', source, model, true, item)
        end
    end
    -- create active thread inside source client to track entity state ( death food etc )
    -- add it to server active pets
end

--- check if player reached maximum allowed pet
---@param source integer
function Pet:isMaxLimitPedReached(source)
    local count = 0
    if self.players[source] == nil then
        return false
    else
        for _ in pairs(self.players[source]) do
            count = count + 1
        end
        if count == 0 then
            return false

        elseif count >= maxLimit then
            return true
        end
    end
end

--- despawn pet and remove it's data from server
---@param source integer
---@param item table
---@param revive boolean
function Pet:despawnPet(source, item, revive)
    -- despawn pet
    -- save all data after despawning pet
    TriggerClientEvent('keep-companion:client:despawn', source, self.players[source][item.info.hash].entity, item, revive)
end

RegisterNetEvent('keep-companion:server:setAsDespawned', function(item)
    if item == nil then
        return
    end
    Pet:setAsDespawned(source, item)
end)
-- ============================
--          Items
-- ============================
-- food
QBCore.Functions.CreateUseableItem('petfood', function(source, item)
    TriggerClientEvent('keep-companion:client:getPetdata', source)
end)

RegisterNetEvent('keep-companion:server:increaseFood', function(item)
    if item == nil then
        return
    end
    TriggerClientEvent('keep-companion:client:increaseFood', source, item, math.random(1500, 2000))
end)

-- rename - collar
QBCore.Functions.CreateUseableItem('collarpet', function(source, item)
    TriggerClientEvent('keep-companion:client:renameCollar', source, item)
end)

RegisterNetEvent('keep-companion:server:renameCollar', function(name)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem("collarpet", 1) then
        TriggerClientEvent("keep-companion:client:renameCollarAction", source, name)
    end
end)

-- first aid - revive
QBCore.Functions.CreateUseableItem('firstaidforpet', function(source, item)
    TriggerClientEvent('QBCore:Notify', source, "Use your 3th eye on pet!", 'error', 2500)
end)

--- revive or heal pet by it's item's hash
---@param Player table
---@param item table
---@param TYPE string
---@return boolean
---@return table
---@return number
---@return boolean
local function revivePet(Player, item, TYPE)
    local percentage = Config.Settings.firstAidHealthRecoverAmount
    local maxHealth = getMaxHealth(item.model)
    local res = math.floor(maxHealth * (percentage / 100))

    for key, items in pairs(Player.PlayerData.items) do
        if items.info.hash ~= nil and (items.info.hash == item.itemData.info.hash) then
            local amount
            local wasMaxHealth = false
            if items.info.health >= maxHealth then
                amount = maxHealth
                wasMaxHealth = true
            else
                if TYPE == 'revive' then
                    amount = 100
                else
                    amount = items.info.health + res
                    if amount >= maxHealth then
                        amount = maxHealth
                    end
                end
                wasMaxHealth = false
            end
            Player.PlayerData.items[items.slot].info.health = amount
            Player.Functions.SetInventory(Player.PlayerData.items, true)
            return true, items, amount, wasMaxHealth
        end
    end
end

RegisterNetEvent('keep-companion:server:revivePet', function(item, TYPE)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local state, updatedItem, amount, wasMaxHealth = revivePet(Player, item, TYPE)
    if state == true then
        if wasMaxHealth == false then
            if Player.Functions.RemoveItem("firstaidforpet", 1) then
                if TYPE == 'Heal' then
                    TriggerClientEvent('QBCore:Notify', src, "You pet healed for: " .. amount, 'success', 2500)
                elseif TYPE == 'revive' then
                    Pet:despawnPet(src, updatedItem, true)
                    TriggerClientEvent('QBCore:Notify', src, "Your per revived!", 'success', 2500)
                end
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Pet is on full health!", 'error', 2500)
        end
    end
end)

--- get pet max health from confing file by it's model
---@param model string
---@return integer
function getMaxHealth(model)
    for key, value in pairs(Config.pets) do
        if value.model == model then
            return value.maxHealth
        end
    end
end

-- all pets
for key, value in pairs(Config.pets) do
    QBCore.Functions.CreateUseableItem(value.name, function(source, item)
        if item.name == value.name then
            local model = value.model
            if type(item.info) == "table" and next(item.info) ~= nil then
                local cooldown = PlayersCooldown:isOnCooldown(source)
                if cooldown > 0 then
                    TriggerClientEvent('QBCore:Notify', source, "On cooldown remaining: " .. (cooldown / 1000) .. "sec")
                else
                    Pet:spawnPet(source, model, item)
                end
            else
                -- init
                TriggerClientEvent('QBCore:Notify', source, "your pet is warming up!")
                initItem(source, item)
            end
        end
    end)
end

-- ================================================
--          Item - Updating Information
-- ================================================

RegisterNetEvent('keep-companion:server:updateAllowedInfo', function(item, data)
    -- #TODO optimize to just use one updateInfoHelper()
    local Player = QBCore.Functions.GetPlayer(source)
    local requestedItem = Player.PlayerData.items[item.slot] -- ask sever to give item's data
    data = data or {}
    if requestedItem == nil or item.hash ~= requestedItem.info.hash then
        -- either item doesnt exist or player changed slot
        requestedItem = FindWhereIsItem(Player, item, source)
    end

    if next(data) ~= nil and item.hash == requestedItem.info.hash then
        -- listed by most frequent update method
        if data.key == 'XP' then
            Update_XP(Player, data, item, source, requestedItem)
        elseif data.key == 'food' then
            Update_food(Player, data, item, source, requestedItem)
        elseif data.key == 'health' then
            if data.content ~= requestedItem.info.health then
                -- need to get maxHealth
                updateInfoHelper(Player, item.slot, data)
            end
        elseif data.key == 'age' then
            Update_age(Player, data, item, source, requestedItem)
        elseif data.key == 'name' then
            -- change pet name
            Update_name(Player, data, item, source, requestedItem)
        elseif data.key == 'owner' then
            -- #TODO data.owner add later

        end
    end
end)

RegisterNetEvent('keep-companion:server:updatePedData', function(item, model, entity)
    Pet:setAsSpawned(source, item, model, entity)
end)

RegisterNetEvent('keep-companion:server:onPlayerUnload', function(items)
    -- save pet's Information when player logout
    for key, value in pairs(items) do
        Pet:setAsDespawned(source, value)
    end
end)

-- ============================
--          Commands
-- ============================

QBCore.Commands.Add('addpet', 'add a pet to player inventory (Admin Only)', {}, false, function(source, args)
    local PETname = args[1]
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local itemData = {
        info = {}
    }
    local random = math.random(1, 2)
    local gender = { true, false }
    local gen = gender[random]
    itemData.info.hash = tostring(
        QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) ..
        QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
    itemData.info.name = NameGenerator('dog', random)
    itemData.info.gender = gen
    itemData.info.age = 0
    itemData.info.food = 100
    -- owener data
    itemData.info.owner = Player.PlayerData.charinfo
    -- inital level and xp
    itemData.info.level = 0
    itemData.info.XP = 0
    -- inital variation
    local petVariation = ''
    local maxHealth = 200
    for k, v in pairs(Config.pets) do
        if v.name == PETname then
            petVariation = PetVariation:getRandomPedVariationsName(v.model, true)
            maxHealth = v.maxHealth
        end
    end
    itemData.info.variation = petVariation
    itemData.info.health = maxHealth
    Player.Functions.AddItem(PETname, 1, nil, itemData.info)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[PETname], "add")
end, 'admin')

QBCore.Commands.Add('addItem', 'add item to player inventory (Admin Only)', {}, false, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.AddItem(item[1], 1)
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[item[1]], "add")
end, 'admin')

QBCore.Commands.Add('renamePet', 'rename pet', { { "name", "new pet name" } }, false, function(source, args)
    TriggerClientEvent("keep-companion:client:renameCollar", source, args[1])
end, 'admin')

-- ============================
--           Cooldown
-- ============================

-- start active cooldowns
Citizen.CreateThread(function()
    local timeToClean = 600 -- sec
    local count = 0
    while true do
        Wait(1000)
        count = count + 1
        local size = PlayersCooldown:onlinePlayers()
        if size > 0 then
            for ped, cooldown in pairs(PlayersCooldown.players) do
                PlayersCooldown:updateCooldown(ped)
            end
        end

        -- remove offline player from cooldown list
        if count >= timeToClean and not count == 0 then
            PlayersCooldown:cleanOflinePlayers()
            count = 0
        end
    end
end)
