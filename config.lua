Config = Config or {}

Config.DEBUG = false -- make sure it's false

Config.callingCompanionDuration = 1000

Config.Settings = {
    callCompanionDuration = 2, -- sec
    despawnDuration = 3, -- sec
    itemUsageCooldown = 5, -- sec
    minHuntingAbilityLevel = 1, -- level
    changePetNameDuration = 5, -- sec
    carFlipingDuration = 5, -- sec
    PetMiniMap = {
        showblip = true,
        sprite = 442,
        colour = 2,
        shortRange = false
    }
}

Config.Balance = {
    maximumLevel = 50, -- xp callculation only work util level 99 don't set it to higher values
    goWander = 60 -- sec pet gonna go wandering around player after player is AFK for a certain time
}

-- distincts are needed for animations and to know if pet can hunt or not 
-- in my testing generaly small animals can't hunt. 
-- so potentially you won't need to change distinct value!
-- distinct = "yes dog" ==> means this pet can hunt
-- distinct = "no dog" ==> means this dog can't hunt

Config.Products = {
    ["petShop"] = {
        [1] = {
            name = 'keepcompanionwesty',
            model = 'A_C_Westy',
            distinct = 'no dog',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 1
        },
        [2] = {
            name = 'keepcompanionshepherd',
            model = 'A_C_shepherd',
            distinct = 'yes dog',
            price = 150000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 2
        },
        [3] = {
            name = 'keepcompanionretriever',
            model = 'A_C_Rottweiler',
            distinct = 'yes dog',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 3
        },
        [4] = {
            name = 'keepcompanionretriever',
            model = 'A_C_Retriever',
            distinct = 'yes dog',
            price = 75000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 4
        },
        [5] = {
            name = 'keepcompanionpug',
            model = 'A_C_Pug',
            distinct = 'no dog',
            price = 95000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 5
        },
        [6] = {
            name = 'keepcompanionpoodle',
            model = 'A_C_Poodle',
            distinct = 'no dog',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 6
        },

        [7] = {
            name = 'keepcompanionmtLion2',
            model = 'A_C_Panther',
            distinct = 'yes cat',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 7
        },
        [8] = {
            name = 'keepcompanionmtLion3',
            model = 'A_C_Cat_01',
            distinct = 'no cat',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 8
        },
        [9] = {
            name = 'keepcompanionmtLion',
            model = 'A_C_MtLion',
            distinct = 'yes cat',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 9
        },
        [10] = {
            name = 'keepcompanionhusky',
            model = 'A_C_Husky',
            distinct = 'yes dog',
            price = 50000,
            amount = 5,
            info = {},
            type = 'item',
            slot = 10
        }
    }
}

Config.Locations = {
    ["petShop"] = {
        ["label"] = "Pet Shop",
        ["coords"] = {
            [1] = vector4(-3225.63, 928.89, 13.9, 297.06)
        },
        ["ped"] = {
            ["model"] = 'S_M_M_StrVend_01'
        },
        ["radius"] = 1.5,
        ["products"] = Config.Products["petShop"],
        ["showblip"] = true,
        ["blipsprite"] = 267,
        ["colour"] = 5
    }
}