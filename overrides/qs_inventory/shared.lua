if not QS_INVENTORY then return end

-- these functions override the bridge/global/ and bridge/esx/qb/ functions
-- if you want to rewrite any function, copy it here and modify it here

local hf = hf
local qs_inventory = exports['qs-inventory']

--- It returns the entire registered item list, unified and filtering out unnecessary information
---@return {name: string, label: string, isUnique: boolean, isWeapon: boolean, weight: number, image: string, ammoname: string}
function eCore:getRegisteredItems()
    hf.itemConvertWarnCustomConvertItems('qs.override')
    return hf.convertItemsWithProfile(qs_inventory:GetItemList(), 'qs', {
        sourceTag = 'qs.convertItems',
    })
end
