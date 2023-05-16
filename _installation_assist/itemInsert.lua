-- INSERT IMAGES TO /resources/[qb]/qb-inventory/html/images/
-- INSERT TO /resources/[qb]/qb-core/shared/items.lua
--[[
-- QB

    ['labor_enhancer'] = {
        ['name'] = 'labor_enhancer',
        ['label'] = 'Labor 1000',
        ['weight'] = 500,
        ['type'] = 'item',
        ['image'] = 'labor_enhancer.png',
        ['unique'] = false,
        ['useable'] = true,
        ['shouldClose'] = true,
        ['combinable'] = nil,
        ['description'] = 'Inrease labor 1000 points'
    },

-- ESX

    INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('labor_enhancer', 'Labor 1000', '1', '0', '1');
]]
