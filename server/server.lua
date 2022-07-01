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
        return
    end

    local limit = Pet:isMaxLimitPedReached(source)
    if limit == true then
        TriggerClientEvent('QBCore:Notify', source, string.format(Lang:t('error.reached_max_allowed_pet'), maxLimit),
            'error', 2500)
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

    local owner = not (item.info.owner.phone == Player.PlayerData.charinfo.phone)
    TriggerClientEvent('keep-companion:client:callCompanion', source, model, owner, item)
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
    -- skip saving data if pet aleady dead
    if petData.info.health == 0 then return end
    if petData.info.health > 100 then
        if petData.info.age >= max_age then
            return
        end
        -- increase pet age when it didnt reached max age
        petData.info.age = petData.info.age + (server_saving_interval_sec)
        Update:food(petData, 'decrease')
        Update:thirst(petData, 'increase')
    else
        petData.info.health = 0
        TriggerClientEvent('keep-companion:client:forceKill', source, hash, 'hunger')
    end

    if Player.PlayerData.items[slot] then
        petData.info.health = Round(petData.info.health, 2) -- round values
        petData.info.thirst = Round(petData.info.thirst, 2)
        petData.info.food = Round(petData.info.food, 2)

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
local core_items = Config.core_items

local function remove_item(src, Player, name, amount)
    local res = Player.Functions.RemoveItem(name, amount)
    if res then
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[name], "remove")
    end
    return res
end

-- food
QBCore.Functions.CreateUseableItem(core_items.food.item_name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end
    TriggerClientEvent('keep-companion:client:start_feeding_animation', source)
end)

RegisterNetEvent('keep-companion:server:increaseFood', function(item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil or item == nil then return end
    if not remove_item(source, Player, Config.core_items.food.item_name, 1) then
        TriggerClientEvent('QBCore:Notify', source, 'Failed to remove from your inventory', 'error', 2500)
        return
    end
    local petData = Pet:findbyhash(source, item.info.hash)
    petData.info.food = petData.info.food + 50
    TriggerClientEvent('QBCore:Notify', source, 'Feeding was successful wait little bit to take effect!', 'success', 2500)
end)

-- change owenership
QBCore.Functions.CreateUseableItem(core_items.collar.item_name, function(source, item)
    TriggerClientEvent('keep-companion:client:collar_process', source)
end)

-- rename - name tag
QBCore.Functions.CreateUseableItem(core_items.nametag.item_name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil or item == nil then return end
    TriggerClientEvent('keep-companion:client:rename_name_tag', source, item)
end)

RegisterNetEvent('keep-companion:server:rename_name_tag', function(name)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end

    if not remove_item(source, Player, Config.core_items.nametag.item_name, 1) then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.failed_to_remove_item_from_inventory'), 'error', 2500)
        return
    end

    TriggerClientEvent("keep-companion:client:rename_name_tagAction", source, name)
end)

-- first aid - revive
QBCore.Functions.CreateUseableItem(core_items.firstaid.item_name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end

end)

QBCore.Functions.CreateUseableItem(core_items.groomingkit.item_name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end
    TriggerClientEvent('keep-companion:client:start_grooming_process', source)
end)

RegisterNetEvent('keep-companion:server:grooming_process', function(item)
    local pet_information = find_pet_model_by_item_name(item.name)

    local information = {
        pet_variation_list = PetVariation:getPedVariationsNameList(pet_information.model),
        pet_information = pet_information,
        disable = {
            rename = true
        },
        type = Config.core_items.groomingkit.item_name
    }

    TriggerClientEvent('keep-companion:client:initialization_process', source, item, information)
end)

local function save_info_waterbottle(Player, item, amount)
    if Player.PlayerData.items[item.slot] then
        Player.PlayerData.items[item.slot].info.liter = amount
    end
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end

local function initialize_info_waterbottle(Player, item)
    if Player.PlayerData.items[item.slot] then
        Player.PlayerData.items[item.slot].info = {}
        Player.PlayerData.items[item.slot].info.liter = 0
    end
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end

local function fillwater_bottle(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player == nil then return end
    local max_c = Config.core_items.waterbottle.settings.max_capacity
    local water_bottle_refill_value = Config.core_items.waterbottle.settings.water_bottle_refill_value
    local amount = 0

    if type(item.info) ~= "table" or (type(item.info) == "table" and item.info.liter == nil) then
        initialize_info_waterbottle(Player, item)
        TriggerClientEvent('QBCore:Notify', source, 'Washing water bottle!', 'primary', 2500)
        return
    end

    if item.info.liter == nil then
        -- backup initialization
        initialize_info_waterbottle(Player, item)
        TriggerClientEvent('QBCore:Notify', source, 'Washing water bottle!', 'primary', 2500)
        return
    end

    if item.info.liter > max_c then
        TriggerClientEvent('QBCore:Notify', source, 'could not do that already reached max capacity', 'error', 2500)
        return
    elseif item.info.liter == max_c then
        amount = max_c
        TriggerClientEvent('QBCore:Notify', source, 'filling already filled bottle has no effect on capacity',
            'error', 2500)
    else
        amount = item.info.liter + water_bottle_refill_value
        if amount >= max_c then
            amount = max_c
        end
    end
    if type(amount) ~= "number" then
        TriggerClientEvent('QBCore:Notify', source, 'Failed to get amount', 'error', 2500)
        return
    end
    save_info_waterbottle(Player, item, amount)
    TriggerClientEvent('QBCore:Notify', source, 'Filled bottle', 'success', 2500)
end

QBCore.Functions.CreateUseableItem(core_items.waterbottle.item_name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    local water_bottle_refill_value = Config.core_items.waterbottle.settings.water_bottle_refill_value
    if Player == nil then return end
    if not remove_item(source, Player, 'water_bottle', water_bottle_refill_value) then
        local msg = Lang:t('error.not_enough_water_bottles')
        msg = string.format(msg, water_bottle_refill_value)
        TriggerClientEvent('QBCore:Notify', source, msg, 'error', 2500)
        return
    end
    TriggerClientEvent('keep-companion:client:filling_animation', source, item)
end)

RegisterNetEvent('keep-companion:server:filling_event', function(item)
    fillwater_bottle(source, item)
end)

QBCore.Functions.CreateCallback('keep-companion:server:decrease_thirst', function(source, cb, data)
    local player = QBCore.Functions.GetPlayer(source)
    local pet_water_bottle = player.Functions.GetItemByName(Config.core_items.waterbottle.item_name)

    if pet_water_bottle.info == nil then
        TriggerClientEvent('QBCore:Notify', source, 'You should wash water bottle first!', 'error', 2500)
        print('issue with nill info: https://github.com/swkeep/keep-companion/issues/25')
        return
    end

    if pet_water_bottle.info.liter == nil then
        TriggerClientEvent('QBCore:Notify', source, 'You should wash water bottle first!', 'error', 2500)
        print('maybe use your water bottle when there is some water_bottle s in your inventory')
        print('developer: issue with nill info -> liter: https://github.com/swkeep/keep-companion/issues/25')
        return
    end

    pet_water_bottle.info.liter = pet_water_bottle.info.liter -
        Config.core_items.waterbottle.settings.water_bottle_refill_value
    if pet_water_bottle.info.liter < 0 then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.not_enough_water_in_your_bottle'), 'error', 2500)
        return
    end

    local petData = Pet:findbyhash(source, data.info.hash)
    local t_r_p_d = Config.core_items.waterbottle.settings.thirst_reduction_per_drinking

    if not pet_water_bottle then cb(false) return end

    if petData.info.thirst < 0 then
        petData.info.thirst = 0
    end

    if petData.info.thirst <= t_r_p_d then
        petData.info.thirst = 0
    else
        petData.info.thirst = petData.info.thirst - t_r_p_d
    end

    TriggerClientEvent('QBCore:Notify', source, Lang:t('success.successful_drinking'), 'success', 2500)
    save_info_waterbottle(player, pet_water_bottle, pet_water_bottle.info.liter)
end)

RegisterNetEvent('keep-companion:server:revivePet', function(item, process_type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local petData = Pet:findbyhash(source, item.itemData.info.hash)
    local heal_amount = Config.core_items.firstaid.settings.heal_amount
    local revive_bonuses = Config.core_items.firstaid.settings.revive_heal_bonuses
    local pet_maxHealth = getMaxHealth(item.model)
    local potential_heal_amount = math.floor(pet_maxHealth * (heal_amount / 100))
    local msg = ''

    if not petData then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.failed_to_start_procces') .. process_type, 'primary', 2500)
        return
    end

    if petData.info.health >= pet_maxHealth then
        -- pet has more than life more than correct max life rewrite wrong value
        petData.info.health = pet_maxHealth
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.full_life_pet'), 'primary', 2500)
        return
    end

    if not remove_item(source, Player, Config.core_items.firstaid.item_name, 1) then
        TriggerClientEvent('QBCore:Notify', src, 'Failed to remove from your inventory', 'error', 2500)
        return
    end

    if process_type and process_type == 'Heal' then
        local res = math.floor(petData.info.health + potential_heal_amount)
        petData.info.health = res
        if petData.info.health >= pet_maxHealth then
            petData.info.health = pet_maxHealth
        end

        Pet:save_all_info(src, item.itemData.info.hash)
        msg = Lang:t('success.healing_was_successful')
        msg = string.format(msg, petData.info.health, pet_maxHealth)
        TriggerClientEvent('keep-companion:client:update_health_value', src, item, petData.info.health)
        TriggerClientEvent('QBCore:Notify', src, msg, 'success', 2500)
        return
    end

    petData.info.health = 100 + revive_bonuses
    Pet:save_all_info(src, item.itemData.info.hash) -- save pet's data
    Pet:despawnPet(src, petData, true) -- despawn dead pet
    msg = Lang:t('success.successful_revive')
    msg = string.format(msg, item.itemData.info.name)
    TriggerClientEvent('QBCore:Notify', src, msg, 'success', 2500)
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
        -- need inital values
        if type(item.info) ~= "table" or (type(item.info) == "table" and item.info.hash == nil) then
            -- init companion
            initItem(source, item)
            TriggerClientEvent('QBCore:Notify', source, Lang:t('success.pet_initialization_was_successful'), 'success',
                2500)
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

local function search_inventory(cid)
    local Player = QBCore.Functions.GetPlayer(cid)
    if not Player then return false end
    local count = 0
    for k, illegal_item in pairs(Config.k9.illegal_items) do
        local item = Player.Functions.GetItemByName(illegal_item)
        if item then
            count = count + 1
            if count > 0 then
                return true
            end
        end
    end
    return false
end

QBCore.Functions.CreateCallback('keep-companion:server:search_inventory', function(source, cb, cid)
    local res = search_inventory(cid)
    if not res then
        TriggerClientEvent('QBCore:Notify', source, 'K9 could not find anything!', 'error', 2500)
        cb(res)
        return
    end
    cb(res)
end)

local function search_vehicle(Type, plate)
    local illegal_items = Config.k9.illegal_items
    local items_list = nil

    if Type == 1 then
        items_list = exports[Config.inventory_name]:getGloveboxes(plate)
    elseif Type == 2 then
        items_list = exports[Config.inventory_name]:getTruck(plate)
    end

    if items_list then
        for key, item in pairs(items_list.items) do
            for k, i_name in pairs(illegal_items) do
                if item.name == i_name then
                    return true
                end
            end
        end
    end
    return false
end

QBCore.Functions.CreateCallback('keep-companion:server:search_vehicle', function(source, cb, data)
    local res = search_vehicle(data.key, data.plate)
    if not res then
        TriggerClientEvent('QBCore:Notify', source, 'K9 could not find anything!', 'error', 2500)
        cb(res)
        return
    end
    TriggerClientEvent('QBCore:Notify', source, 'K9 found something', 'success', 2500)
    cb(res)
end)
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
    if current_pet_data == nil or current_pet_data == false then return end
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

    Player.Functions.AddItem(PETname, 1)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[PETname], "add")
end, 'admin')

QBCore.Commands.Add('addItem', 'add item to player inventory (Admin Only)', {}, false, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.AddItem(item[1], 1)
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[ item[1] ], "add")
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

RegisterNetEvent('keep-companion:server:ForceRemoveNetEntity', function(netId)
    local net = NetworkGetEntityFromNetworkId(netId)
    DeleteEntity(net)
end)
