-- local PetVariation = {
--     pedHash = {
--         variation = {
--             componentId = 0,
--             drawableId = 0,
--             textureId = 0
--         }
--     }
-- }
PetVariation = {
    ['a_c_husky'] = {
        ['default'] = {
            componentId = 0,
            drawableId = 0,
            textureId = 0
        },
        ['brown'] = {
            componentId = 0,
            drawableId = 0,
            textureId = 1
        },
        ['white'] = {
            componentId = 0,
            drawableId = 0,
            textureId = 2
        }
    }
}

--- set color/variation of peds
---@param pedHnadle integer
---@param pedModel string
---@param variation string
---@return boolean
function PetVariation:setPedVariation(pedHnadle, pedModel, variation)
    local data = PetVariation[pedModel][variation]
    if data ~= nil and IsPedComponentVariationValid(pedHnadle, data.componentId, data.drawableId, data.textureId) then
        SetPedComponentVariation(pedHnadle, data.componentId, data.drawableId, data.textureId)
        return true
    else
        return false
    end
end

--- get all pets collor variation
---@param pedModel any
---@param justVariation any
---@return table
function PetVariation:getRandomPedVariationsName(pedModel, justVariation)
    if justVariation ~= nil and justVariation == true then
        local tmp = {}
        for key, value in pairs(PetVariation[pedModel]) do
            table.insert(tmp, key)
        end
        return tmp[math.random(1, #tmp)] -- #TODO simple for now replace it with alias table later
    end
end

--- find valid variation
---@param ped any
---@param componentId any
function variationTester(ped, componentId)
    -- componentId
    -- 0 - Head
    -- 1 - Beard
    -- 2 - Hair
    -- 3 - Torso
    -- 4 - Legs
    -- 5 - Hands
    -- 6 - Foot
    -- 7 - None?
    -- 8 - Accessories like parachute, scuba tank
    -- 9 - Accessories like bags, mask, scuba mask
    -- 10- Decals and mask
    -- 11 - Auxiliary parts for torso
    local drawableId = GetNumberOfPedDrawableVariations(ped, componentId)
    print('usable IDs starting from 0 not 1')
    print('count(drawableId): ', drawableId)

    for drawableIndex = 0, drawableId - 1, 1 do
        local textureId = GetNumberOfPedTextureVariations(ped, componentId, drawableIndex)
        print('count(textureId): ', textureId)
        for textureIndex = 0, textureId - 1, 1 do
            print('drawableindex: ', drawableIndex, 'textureIndex: ', textureIndex, 'valid: ',
                IsPedComponentVariationValid(ped, componentId, drawableIndex, textureIndex))
        end
    end
end
