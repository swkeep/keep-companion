local QBCore = exports['qb-core']:GetCoreObject()

--- get random pet name
---@param type 'species'
---@param gender integer
function NameGenerator(type, gender)
    local names = {
        dog = { { "Max", "Buddy", "Charlie", "Jack", "Cooper", "Rocky", "Toby", "Tucker", "Jake", "Bear", "Duke", "Teddy",
            "Oliver", "Riley", "Bailey", "Bentley", "Milo", "Buster", "Cody", "Dexter", "Winston", "Murphy", "Leo",
            "Lucky", "Oscar", "Louie", "Zeus", "Henry", "Sam", "Harley", "Baxter", "Gus", "Sammy", "Jackson",
            "Bruno", "Diesel", "Jax", "Gizmo", "Bandit", "Rusty", "Marley", "Jasper", "Brody", "Roscoe", "Hank",
            "Otis", "Bo", "Joey", "Beau", "Ollie", "Tank", "Shadow", "Peanut", "Hunter", "Scout", "Blue", "Rocco",
            "Simba", "Tyson", "Ziggy", "Boomer", "Romeo", "Apollo", "Ace", "Luke", "Rex", "Finn", "Chance", "Rudy",
            "Loki", "Moose", "George", "Samson", "Coco", "Benny", "Thor", "Rufus", "Prince", "Chester", "Brutus",
            "Scooter", "Chico", "Spike", "Gunner", "Sparky", "Mickey", "Kobe", "Chase", "Oreo", "Frankie", "Mac",
            "Benji", "Bubba", "Champ", "Brady", "Elvis", "Copper", "Cash", "Archie", "Walter" },
        { "Bella", "Lucy", "Daisy", "Molly", "Lola", "Sophie", "Sadie", "Maggie", "Chloe", "Bailey", "Roxy",
            "Zoey", "Lily", "Luna", "Coco", "Stella", "Gracie", "Abby", "Penny", "Zoe", "Ginger", "Ruby", "Rosie",
            "Lilly", "Ellie", "Mia", "Sasha", "Lulu", "Pepper", "Nala", "Lexi", "Lady", "Emma", "Riley", "Dixie",
            "Annie", "Maddie", "Piper", "Princess", "Izzy", "Maya", "Olive", "Cookie", "Roxie", "Angel", "Belle",
            "Layla", "Missy", "Cali", "Honey", "Millie", "Harley", "Marley", "Holly", "Kona", "Shelby", "Jasmine",
            "Ella", "Charlie", "Minnie", "Willow", "Phoebe", "Callie", "Scout", "Katie", "Dakota", "Sugar", "Sandy",
            "Josie", "Macy", "Trixie", "Winnie", "Peanut", "Mimi", "Hazel", "Mocha", "Cleo", "Hannah", "Athena",
            "Lacey", "Sassy", "Lucky", "Bonnie", "Allie", "Brandy", "Sydney", "Casey", "Gigi", "Baby", "Madison",
            "Heidi", "Sally", "Shadow", "Cocoa", "Pebbles", "Misty", "Nikki", "Lexie", "Grace", "Sierra" } }
    }
    local size = #names[type][gender]
    return names[type][gender][math.random(1, size)]
end

function initInfoHelper(Player, slot, data)
    if Player.PlayerData.items[slot] then
        Player.PlayerData.items[slot].info = data
    end
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end

--- inital pet data after player bought pet
---@param source any
---@param item any
function initItem(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local random = math.random(1, 2)
    local gender = { true, false }
    local gen = gender[random]
    item.info.hash = tostring(QBCore.Shared.RandomInt(2) .. QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(1) ..
        QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(4))
    item.info.name = NameGenerator('dog', random)
    item.info.gender = gen
    item.info.age = 0
    item.info.food = 100
    -- owener data
    item.info.owner = Player.PlayerData.charinfo
    -- inital level and xp
    item.info.level = 0
    item.info.XP = 0
    -- inital variation
    local petVariation = ''
    local maxHealth = 200
    for k, v in pairs(Config.pets) do
        if v.name == item.name then
            petVariation = PetVariation:getRandomPedVariationsName(v.model, true)
            maxHealth = v.maxHealth
        end
    end
    item.info.variation = petVariation
    item.info.health = maxHealth
    initInfoHelper(Player, item.slot, item.info)
end

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

function updateInfoHelper(Player, slot, data)
    if Player.PlayerData.items[slot] then
        Player.PlayerData.items[slot].info[data.key] = data.content
    end
    -- print('how much: ', data.content, 'itemHash: ' .. Player.PlayerData.items[slot].info['hash'],
    --     "whichPart: " .. data.key)
    Player.Functions.SetInventory(Player.PlayerData.items, true)
end

-- 1 --> 7 year old
CalorieCalData = {
    dog = {
        maximumCal = 2000,
        activity = {
            low = 1.6,
            high = 5.0
        },
        RER = function(lbs)
            return 70 * (lbs ^ (0.75))
        end
    },
    cat = {
        maximumCal = 1000,
        activity = {
            low = 1.2,
            high = 1.8
        },
        RER = function(lbs)
            return 40 * (lbs ^ (0.75))
        end
    }
}

function CalorieCalData:calRER(lbs, type)
    local res = 0
    res = math.floor(self[type]['RER'](lbs))
    return res
end

function CalorieCalData:convertWeightToLbs(weight)
    return (weight * 10) / 500
end

--- update logic
function FindWhereIsItem(Player, item, source)
    if Player.PlayerData.items ~= nil and next(Player.PlayerData.items) ~= nil then
        for k, v in pairs(Player.PlayerData.items) do
            if Player.PlayerData.items[k] ~= nil then
                if Player.PlayerData.items[k].info.hash == item.hash then
                    local slot = Player.PlayerData.items[k].slot
                    return Player.PlayerData.items[slot]
                end
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', source, "no items in inventory!")
        return false
    end
end

function Update_XP(Player, data, item, source, requestedItem)
    -- normalize xp value
    local mData = {}
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
    if server_Level ~= level and (level >= 0 and level <= Config.Balance.maximumLevel) then
        updateInfoHelper(Player, item.slot, {
            key = 'level',
            content = level
        })
    end
end

function Update_food(Player, data, item, source, requestedItem)
    -- update food value
    local mData = {}
    if data.content == nil then
        return
    elseif data.content == 'decrease' then
        if requestedItem.info.food > 0 then
            -- value reached zore or negetive value
            local weight = CalorieCalData:convertWeightToLbs(requestedItem.weight)
            local RER = CalorieCalData:calRER(weight, 'dog') -- maxCalories
            -- step calculation ==> (1min / timeIterval) * foodCycle
            local step = math.floor(RER / ((60 / Config.DataUpdateInterval) * Config.foodCycleEnd))

            mData = {
                key = data.key,
                content = math.floor(requestedItem.info.food - step)
            }
        elseif requestedItem.info.food <= 0 then
            mData = {
                key = data.key,
                content = 0
            }
        end
    elseif data.content == 'increase' then
        local weight = CalorieCalData:convertWeightToLbs(requestedItem.weight)
        local RER = CalorieCalData:calRER(weight, 'dog') -- maxCalories
        local overEat = 0

        overEat = Config.weightIncreaseByOverEat
        local currentEstimatedFoodValue = requestedItem.info.food + data.amount

        if currentEstimatedFoodValue > RER then
            mData = {
                key = data.key,
                content = RER * (Config.foodOverEat / 100)
            }
            overEat = RER - (RER * (Config.foodOverEat / 100))
            if Player.PlayerData.items[item.slot] then
                Player.PlayerData.items[item.slot].weight = Player.PlayerData.items[item.slot].weight +
                    (overEat * (Config.weightIncreaseByOverEat / 100))
            end
            Player.Functions.SetInventory(Player.PlayerData.items, true)
        elseif currentEstimatedFoodValue < RER and currentEstimatedFoodValue >= 0 then
            mData = {
                key = data.key,
                content = requestedItem.info.food + (data.amount * (Config.foodOverEat / 100))
            }
        else
            mData = {
                key = data.key,
                content = 500
            }
        end
        TriggerClientEvent('QBCore:Notify', source, "Pet food value increased too: " .. mData.content)
    end
    updateInfoHelper(Player, item.slot, mData)
    TriggerClientEvent('keep-companion:client:updateFood', source, {
        content = mData.content,
        hash = Player.PlayerData.items[item.slot].info['hash']
    })

end

function Update_age(Player, data, item, source, requestedItem)
    if type(requestedItem.info.age) == "number" and (data.content ~= nil or data.content ~= 0) and data.content <= 60 *
        60 * 24 * 10 then
        mData = {
            key = data.key,
            content = requestedItem.info.age + data.content
        }
        updateInfoHelper(Player, item.slot, mData)
    end
end

function Update_name(Player, data, item, source, requestedItem)
    if requestedItem.info.name ~= data.content then
        updateInfoHelper(Player, item.slot, data)
        TriggerClientEvent('QBCore:Notify', source, "your pet name changed to " .. data.content)
    else
        TriggerClientEvent('QBCore:Notify', source, "your pet already named like that: " .. data.content)
    end
    Pet:despawnPet(source, { info = {
        hash = item.hash
    } }, true)
end

-- ============================
--           Cooldown
-- ============================

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
