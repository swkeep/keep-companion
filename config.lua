Config = Config or {}

Config.DEBUG = false -- make sure it's false

Config.callingCompanionDuration = 1000

Config.RadialMeneu = {
    [1] = {
        lable = 'Follow',
        action = function()
            local plyped = PlayerPedId()
            local ped = ActivePed:read().entity
            doSomethingIfPedIsInsideVehicle(ped)
            TaskFollowTargetedPlayer(ped, plyped, 3.0)
        end
    },
    [2] = {
        lable = "Hunt",
        action = function()
            if ActivePed:read().level >= 25 then
                attackLogic()
            else
                TriggerEvent('QBCore:Notify', "Not enoght levels")
            end
        end
    },
    [3] = {
        lable = "Change Color",
        action = function()
            local ped = ActivePed:read().entity
            local model = ActivePed:read().model
            variationTester(ped, 0)
        end
    },
    [4] = {
        lable = "There",
        action = function()
            local ped = ActivePed:read().entity
            doSomethingIfPedIsInsideVehicle(ped)
            goThere(ped)
        end
    },
    [5] = {
        lable = "Wait",
        action = function()
            local ped = ActivePed:read().entity
            ClearPedTasks(ped)
        end
    },
    [6] = {
        lable = "Get in Car",
        action = function()
            getIntoCar()
        end
    }
}

Config.pedModels = {
    [1] = {
        model = -1788665315,
        lable = 'chien',
        price = 50000
    },
    [2] = {
        model = 1462895032,
        lable = 'chat',
        price = 50000
    },
    [3] = {
        model = -1682622302,
        lable = 'loup',
        price = 50000
    },
    [4] = {
        model = -541762431,
        lable = 'lapin',
        price = 50000
    },
    [5] = {
        model = 1318032802,
        lable = 'husky',
        price = 50000
    },
    [6] = {
        model = -1323586730,
        lable = 'cochon',
        price = 50000
    },
    [7] = {
        model = 1125994524,
        lable = 'caniche',
        price = 50000
    },
    [8] = {
        model = 1832265812,
        lable = 'carlin',
        price = 50000
    },
    [9] = {
        model = 882848737,
        lable = 'retriever',
        price = 50000
    },
    [10] = {
        model = 1126154828,
        lable = 'berger',
        price = 50000
    },
    [11] = {
        model = -1384627013,
        lable = 'westie',
        price = 50000
    },
    [12] = {
        model = 351016938,
        lable = 'rottweiler',
        price = 50000
    }
}

