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
function Pet:setAsSpawned(source, o)
    self.players[source] = self.players[source] or {}
    self.players[source][o.item.info.hash] = self.players[source][o.item.info.hash] or {}
    self.players[source][o.item.info.hash].model = o.model
    self.players[source][o.item.info.hash].entity = o.entity

    -- memmory new data saving method
    self.players[source][o.item.info.hash].name = o.item.name
    self.players[source][o.item.info.hash].info = o.item.info
    return true
end

--- removes pet from Pet table
function Pet:setAsDespawned(source, item)
    self.players[source] = self.players[source] or {}
    self.players[source][item.info.hash] = nil
end

--- start spawn chain
function Pet:spawnPet(source, model, item)
    -- sumun pet when it does exist inside our database
    local isSpawned = Pet:isSpawned(source, item)
    if isSpawned == true then
        -- depsawn ped
        Pet:despawnPet(source, item, nil)
    else
        local limit = Pet:isMaxLimitPedReached(source)
        if limit == true then
            TriggerClientEvent('QBCore:Notify', source, string.format(Lang:t('error.reached_max_allowed_pet'), maxLimit), 'error', 2500)
            return
        end
        local Player = QBCore.Functions.GetPlayer(source)
        -- spawn ped
        if item.weight == 500 then
            -- need inital values
            if Player.PlayerData.items[item.slot] then
                Player.PlayerData.items[item.slot].weight = math.random(1000, 4500)
            end
            Player.Functions.SetInventory(Player.PlayerData.items, true)
        end

        if item.info.health <= 100 and item.info.health ~= 0 then
            -- prevent 100 to stuck in data as health!
            if Player.PlayerData.items[item.slot] then
                Player.PlayerData.items[item.slot].info.health = 0
            end
            Player.Functions.SetInventory(Player.PlayerData.items, true)
            return
        end

        -- if player that is spawning pet is not owener spawn pet as hostile toward that player
        local owner = not (item.info.owner.phone == Player.PlayerData.charinfo.phone)
        TriggerClientEvent('keep-companion:client:callCompanion', source, model, owner, item)
    end
end

RegisterNetEvent('keep-companion:server:despwan_not_owned_pet', function(hash)
    Pet:despawnPet(source, { info = {
        hash = hash
    } }, true)
end)

--- check if player reached maximum allowed pet
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
function Pet:despawnPet(source, item, revive)
    -- despawn pet
    -- save all data after despawning pet
    TriggerClientEvent('keep-companion:client:despawn', source, item, revive)
end

function Pet:findbyhash(source, hash)
    for key, value in pairs(self.players[source]) do
        if key == hash then
            return value
        end
    end
    return false
end

local server_saving_interval = 5000
local server_saving_interval_sec = math.floor(server_saving_interval / 1000)
local day = 10
local max_age = 60 * 60 * 24 * day

function Pet:save_all_info(source, hash)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end
    local petData = Pet:findbyhash(source, hash)
    local items = Player.Functions.GetItemsByName(petData.name)
    local slot = nil

    -- find item
    for key, pet_item in pairs(items) do
        if pet_item.info.hash == hash then
            slot = pet_item.slot
            break
        end
    end
    if slot == nil then return end

    if petData.info.health > 100 then
        if petData.info.age >= max_age then
            return
        end
        -- increase pet age when it didnt reached max age
        petData.info.age = petData.info.age + (server_saving_interval_sec)
        Update:food(petData, 'decrease')
    else
        -- kill for hunger
        TriggerClientEvent('keep-companion:client:forceKill', source, hash)
    end

    if Player.PlayerData.items[slot] then
        petData.info.health = Round(petData.info.health, 2) -- round health value
        Player.PlayerData.items[slot].info = petData.info
    end
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end

RegisterNetEvent('keep-companion:server:setAsDespawned', function(item)
    if item == nil then return end
    Pet:setAsDespawned(source, item)
end)
-- ============================
--          Items
-- ============================
-- food
QBCore.Functions.CreateUseableItem('petfood', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end
    TriggerClientEvent('keep-companion:client:start_feeding_animation', source)
end)

RegisterNetEvent('keep-companion:server:increaseFood', function(item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil or item == nil then return end
    if Player.Functions.RemoveItem('petfood', 1) ~= true then
        TriggerClientEvent('QBCore:Notify', source, 'Failed to remove from your inventory', 'error', 2500)
        return
    end
    local petData = Pet:findbyhash(source, item.info.hash)
    petData.info.food = petData.info.food + 50
    TriggerClientEvent('QBCore:Notify', source, 'Feeding was successful wait little bit to take effect!', 'success', 2500)
end)

-- change owenership
QBCore.Functions.CreateUseableItem('collarpet', function(source, item)
    TriggerClientEvent('keep-companion:client:collar_process', source)
end)

-- rename - name tag
QBCore.Functions.CreateUseableItem('petnametag', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil or item == nil then return end
    TriggerClientEvent('keep-companion:client:rename_name_tag', source, item)
end)

RegisterNetEvent('keep-companion:server:rename_name_tag', function(name)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end

    if Player.Functions.RemoveItem("petnametag", 1) ~= true then
        TriggerClientEvent('QBCore:Notify', source, 'Failed to remove from your inventory', 'error', 2500)
        return
    end

    TriggerClientEvent("keep-companion:client:rename_name_tagAction", source, name)
end)

-- first aid - revive
QBCore.Functions.CreateUseableItem('firstaidforpet', function(source, item)
    TriggerClientEvent('QBCore:Notify', source, Lang:t('info.use_3th_eye'), 'primary', 2500)
end)

--- revive or heal pet by it's item's hash
---@param Player any
---@param source any
---@param item any
---@param process_type any
---@return 'state' boolean
---@return 'updatedItem' table
---@return 'amount' integer
---@return 'wasMaxHealth' boolean
local function revivePet(Player, source, item, process_type)
    local percentage = Config.Settings.firstAidHealthRecoverAmount
    local petData = Pet:findbyhash(source, item.itemData.info.hash)
    local maxHealth = getMaxHealth(item.model)
    local potential_increase_health = math.floor(maxHealth * (percentage / 100))

    if petData.info.health >= maxHealth then
        petData.info.health = maxHealth
        return true, petData, petData.info.health, true
    else
        if process_type == 'revive' then
            petData.info.health = 125 -- +25 just in case
            Pet:save_all_info(source, item.itemData.info.hash) -- save pet's data
        else
            petData.info.health = petData.info.health + potential_increase_health
            if petData.info.health >= maxHealth then
                petData.info.health = maxHealth
            end
        end
        return true, petData, petData.info.health, false, maxHealth
    end
    return false
end

RegisterNetEvent('keep-companion:server:revivePet', function(item, process_type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local state, updatedItem, amount, wasMaxHealth, maxHealth = revivePet(Player, source, item, process_type)
    local msg = ''

    if state ~= true then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.failed_to_start_procces'), 'primary', 2500)
        return
    end

    if wasMaxHealth ~= false then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('info.full_life_pet'), 'primary', 2500)
        return
    end

    if Player.Functions.RemoveItem("firstaidforpet", 1) ~= true then
        TriggerClientEvent('QBCore:Notify', source, 'Failed to remove from your inventory', 'error', 2500)
        return
    end

    if process_type == 'Heal' then
        msg = Lang:t('success.healing_was_successful')
        msg = string.format(msg, amount, maxHealth)
        TriggerClientEvent('QBCore:Notify', source, msg, 'success', 2500)
        return
    end

    msg = Lang:t('success.successful_revive')
    msg = string.format(msg, item.itemData.info.name)
    TriggerClientEvent('QBCore:Notify', source, msg, 'success', 2500)
    Pet:despawnPet(src, updatedItem, true) -- despawn dead pet
end)

--- get pet max health from confing file by it's model
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
        if item.name ~= value.name then return end
        local model = value.model
        if type(item.info) == "table" and item.info.hash == nil then
            -- init companion
            initItem(source, item)
            TriggerClientEvent('QBCore:Notify', source, Lang:t('success.pet_initialization_was_successful'), 'success', 2500)
            return
        end

        local cooldown = PlayersCooldown:isOnCooldown(source)
        if cooldown > 0 then
            local msg = Lang:t('info.still_on_cooldown')
            msg = string.format(msg, (cooldown / 1000))
            TriggerClientEvent('QBCore:Notify', source, msg, 'primary', 2500)
            return
        end

        Pet:spawnPet(source, model, item)
    end)
end

-- ================================================
--          Item - Updating Information
-- ================================================
function FindWhereIsItem(Player, item, source)
    if Player.PlayerData.items == nil or next(Player.PlayerData.items) == nil then
        TriggerClientEvent('QBCore:Notify', source, "no items in inventory!")
        return false
    end
    for k, v in pairs(Player.PlayerData.items) do
        if Player.PlayerData.items[k] ~= nil then
            if Player.PlayerData.items[k].info.hash == item.hash then
                local slot = Player.PlayerData.items[k].slot
                return Player.PlayerData.items[slot]
            end
        end
    end
    TriggerClientEvent('QBCore:Notify', source, "Could not find pet")
    return false
end

RegisterNetEvent('keep-companion:server:updateAllowedInfo', function(item, data)
    if type(data) ~= "table" or next(data) == nil then return end
    local Player = QBCore.Functions.GetPlayer(source)
    local current_pet_data = Pet:findbyhash(source, item.hash)
    local requestedItem = Player.Functions.GetItemsByName(current_pet_data.name)

    if type(requestedItem) == "table" then
        for key, pet_item in pairs(requestedItem) do
            if pet_item.info.hash == item.hash then
                requestedItem = pet_item
            end
        end
        if requestedItem == false then return end
    end

    if data.key == 'XP' then
        Update:xp(source, current_pet_data)
        return
    end

    Update:health(source, data, current_pet_data)
end)

QBCore.Functions.CreateCallback('keep-companion:server:renamePet', function(source, cb, item)
    local player = QBCore.Functions.GetPlayer(source)
    local current_pet_data = Pet:findbyhash(source, item.hash)

    -- sanity check
    if player == nil or current_pet_data == nil or current_pet_data == false or type(item.name) ~= "string" then
        local msg = Lang:t('error.failed_to_rename')
        msg = string.format(msg, item.name)
        TriggerClientEvent('QBCore:Notify', source, msg, 'error')
        cb(false)
        return
    end

    if current_pet_data.info.name == item.content then
        local msg = Lang:t('error.failed_to_rename_same_name')
        msg = string.format(msg, item.name)
        TriggerClientEvent('QBCore:Notify', source, msg, 'error')
        cb(false)
        return
    end

    current_pet_data.info.name = item.name
    Pet:save_all_info(source, item.hash) -- save name outside loop
    -- despawn pet to save name
    Pet:despawnPet(source, { info = {
        hash = item.hash
    } }, true)
    cb(item.name)
end)

-- saving thread
CreateThread(function()
    -- #TODO add check to table changes
    while true do
        for source, activePets in pairs(Pet.players) do
            if next(activePets) ~= nil then

                for hash, petData in pairs(activePets) do
                    Pet:save_all_info(source, hash)
                end

            end
        end
        Wait(server_saving_interval)
    end
end)


QBCore.Functions.CreateCallback('keep-companion:server:updatePedData', function(source, cb, clientRes)
    local player = QBCore.Functions.GetPlayer(source)
    if player == nil then
        cb(false)
        return
    end
    if Pet:setAsSpawned(source, clientRes) then
        cb(true)
        return
    end
    cb(false)
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
    TriggerClientEvent("keep-companion:client:rename_name_tag", source, args[1])
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
