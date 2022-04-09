local QBCore = exports['qb-core']:GetCoreObject()
local balanceBettings = Config.Balance
-- pet system
local maxLimit = 1

-- ============================
--          Class
-- ============================

local Pet = {
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
                Player.PlayerData.items[item.slot].weight = math.random(501, 4500)
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
--- depsawn helper
---@param source integer
---@param item table
function Pet:despawnPet(source, item)
    -- despawn pet 
    -- save all data after despawning pet
    TriggerClientEvent('keep-companion:client:despawn', source, self.players[source][item.info.hash].entity)
    Pet:setAsDespawned(source, item)
end

function Pet:feedPet()
    -- increase food property of pet inside database

end

function Pet:checkFoodStatus()
    -- return food status from database

end

function Pet:revivePet()
    -- revive pet when it's dead! :)
end

-- ============================
--          Item
-- ============================

for key, value in pairs(Config.Products["petShop"]) do
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
--- inital pet data after player bought pet
---@param source any
---@param item any
function initItem(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local random = math.random(1, 2)
    local gender = {true, false}
    local gen = gender[random]
    item.info.hash = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) ..
                                  QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
    item.info.name = NameGenerator('dog', random)
    item.info.gender = gen
    item.info.age = 0
    item.info.food = 100
    item.info.health = 100
    -- state = alive or dead
    item.info.state = true
    -- owener data
    item.info.owner = Player.PlayerData.charinfo
    -- inital level and xp
    item.info.level = 0
    item.info.XP = 0
    -- inital variation
    local petVariation = ''
    for k, v in pairs(Config.Products.petShop) do
        if v.name == item.name then
            petVariation = PetVariation:getRandomPedVariationsName(v.model, true)
        end
    end
    item.info.variation = petVariation
    initInfoHelper(Player, item.slot, item.info)
end

function initInfoHelper(Player, slot, data)
    if Player.PlayerData.items[slot] then
        Player.PlayerData.items[slot].info = data
    end
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end

-- ================================================
--          Item - Updating Information
-- ================================================
-- #TODO add a way to fix undefined level and xp

RegisterNetEvent('keep-companion:server:updatePedData', function(item, model, entity)
    Pet:setAsSpawned(source, item, model, entity)
end)

RegisterNetEvent('keep-companion:server:updateAllowedInfo', function(item, data)
    -- #TODO optimize to just use one updateInfoHelper()
    -- #TODO data validation
    local Player = QBCore.Functions.GetPlayer(source)
    local requestedItem = Player.PlayerData.items[item.slot] -- ask item's data from sever
    data = data or {}
    local mData = {}

    if next(data) ~= nil and item.hash == requestedItem.info.hash then
        -- listed by most frequent update method
        if data.key == 'XP' then
            -- normalize xp value
            mData = {
                key = data.key,
                content = math.floor(data.content)
            }
            -- #TODO xp and level validation
            local level = convertXpToLevel(mData.content)
            local xp = mData.content
            local server_cXP = requestedItem.info.XP
            local server_Level = requestedItem.info.level

            updateInfoHelper(Player, item.slot, mData)
            if server_Level ~= level and (level >= 0 and level <= balanceBettings.maximumLevel) then
                updateInfoHelper(Player, item.slot, {
                    key = 'level',
                    content = level
                })
            end
        elseif data.key == 'food' then
        elseif data.key == 'state' then
            -- update pet state
            updateInfoHelper(Player, item.slot, data)
        elseif data.key == 'age' then
            if type(requestedItem.info.age) == "number" and (data.content ~= nil or data.content ~= 0) and data.content <=
                60 * 60 * 24 * 10 then
                mData = {
                    key = data.key,
                    content = requestedItem.info.age + data.content
                }
                updateInfoHelper(Player, item.slot, mData)
            end

        elseif data.key == 'name' then
            -- change pet name
            if requestedItem.info.name ~= data.content then
                updateInfoHelper(Player, item.slot, data)
                TriggerClientEvent('QBCore:Notify', source, "your pet name changed to " .. data.content)
            else
                TriggerClientEvent('QBCore:Notify', source, "your pet already named like that: " .. data.content)
            end

        elseif data.key == 'owner' then
            -- #TODO data.owner add later  

        end
    end
end)

function updateInfoHelper(Player, slot, data)
    if Player.PlayerData.items[slot] then
        Player.PlayerData.items[slot].info[data.key] = data.content
    end
    -- print('updating: ' .. Player.PlayerData.citizenid, "whichPart: " .. data.key)
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end

RegisterNetEvent('keep-companion:server:onPlayerUnload', function(item)
    -- save pet's Information when player logout
    Pet:setAsDespawned(source, item)
end)
-- ============================
--         Calculation
-- ============================

function convertXpToLevel(xp)
    -- hardcoded level 0
    if xp >= 0 and xp <= 75 then
        return 0
    end

    local maxExp = 0
    local minExp = 0

    for i = 1, 51, 1 do
        maxExp = math.floor(math.floor((i + 300) * (2 ^ (i / 7))) / 4)
        minExp = math.floor(math.floor(((i - 1) + 300) * (2 ^ ((i - 1) / 7))) / 4)
        if xp >= minExp and xp <= maxExp then
            return i
        end
    end
end

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
    local gender = {true, false}
    local gen = gender[random]
    itemData.info.hash = tostring(
        QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) ..
            QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
    itemData.info.name = NameGenerator('dog', random)
    itemData.info.gender = gen
    itemData.info.age = 0
    itemData.info.food = 100
    itemData.info.health = 100
    -- state = alive or dead
    itemData.info.state = true
    -- owener data
    itemData.info.owner = Player.PlayerData.charinfo
    -- inital level and xp
    itemData.info.level = 0
    itemData.info.XP = 0
    -- inital variation
    local petVariation = ''
    for k, v in pairs(Config.Products.petShop) do
        if v.name == PETname then
            petVariation = PetVariation:getRandomPedVariationsName(v.model, true)
        end
    end
    itemData.info.variation = petVariation

    Player.Functions.AddItem(PETname, 1, nil, itemData.info)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[PETname], "add")
end, 'admin')

QBCore.Commands.Add('addItem', 'add item to player inventory (Admin Only)', {}, false, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    Player.Functions.AddItem(item[1], 1)
    TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[item[1]], "add")
end, 'admin')

QBCore.Commands.Add('changePetName', 'change pet name', {{"name", "new pet name"}}, false, function(source, args)
    TriggerClientEvent("keep-companion:client:getActivePet", source, args[1])
end, 'admin')

RegisterNetEvent('keep-companion:server:updatePedData', function(item, model, entity)
    Pet:setAsSpawned(source, item, model, entity)
end)

-- ============================
--           Cooldown
-- ============================

-- #region
local usageCooldown = Config.Settings.itemUsageCooldown * 1000
PlayersCooldown = {
    players = {}
}

function PlayersCooldown:initCooldown(player)
    self.players[player] = usageCooldown
end

function PlayersCooldown:cleanOflinePlayers()
    local onlinePlayers = QBCore.Functions.GetPlayers()
    for ID, cooldown in pairs(self.players) do
        for key, id in pairs(onlinePlayers) do
            if ID == id then
                goto here
            end
        end
        self.players[ID] = nil
        ::here::
    end
end

function PlayersCooldown:updateCooldown(player)
    if self.players[player] > 0 then
        self.players[player] = self.players[player] - 1000
    end
    return 0
end

function PlayersCooldown:isOnCooldown(player)
    if self.players[player] == nil then
        PlayersCooldown:initCooldown(player)
        return 0
    elseif self.players[player] == 0 then
        PlayersCooldown:initCooldown(player)
        return 0
    elseif self.players[player] > 0 then
        return self.players[player]
    end
end

function PlayersCooldown:onlinePlayers()
    local count = 0
    for _ in pairs(self.players) do
        count = count + 1
    end
    return count
end

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

-- #endregion
-- local nClock = os.clock()
-- print(("Elapsed time: " .. os.clock() - nClock))

-- ============================

-- RegisterNetEvent('keep-companion:server:spawn', function(model)
--     local src = source
--     local ped = GetPlayerPed(src)
--     local playerCoords = GetEntityCoords(ped)
--     local x, y, z = table.unpack(playerCoords)
--     x = x + (1.0 * math.cos(45))
--     y = y + (1.0 * math.sin(45))
--     local pet = CreatePed(5, model, x, y, z, 0.0, true, true)
--     return pet
-- end)