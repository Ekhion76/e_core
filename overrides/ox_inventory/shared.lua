if not OX_INVENTORY then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here

local hf = hf
local ox_inventory = exports.ox_inventory

--- It returns the entire registered item list, unified and filtering out unnecessary information
---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
function eCore:getRegisteredItems()
    hf.itemConvertWarnCustomConvertItems('ox.override')
    return hf.convertItemsWithProfile(ox_inventory:Items(), 'ox', {
        sourceTag = 'ox.convertItems',
    })
end
