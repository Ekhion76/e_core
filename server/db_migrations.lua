--- e_core – séma migrációk (Fázis 3).
--- Sorrend: növekvő `id`; alkalmazás után sor kerül az `e_core_migrations` táblába.
--- Új migráció: bővítsd a `ECORE_DB_MIGRATIONS` tömböt; növeld `ECORE_DB_SCHEMA_TARGET` (export / doksi).

ECORE_DB_SCHEMA_TARGET = 1

local MIGRATIONS_DDL = [[
CREATE TABLE IF NOT EXISTS `e_core_migrations` (
  `id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `name` VARCHAR(128) NOT NULL,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

local function ensure_migrations_table()
    local ok, err = hf.mysqlAwait('migration:ensure_table', function()
        MySQL.query.await(MIGRATIONS_DDL)
    end)
    if not ok then
        error(tostring(err))
    end
end

local function migration_applied(id)
    local ok, rows = hf.mysqlAwait(('migration:has_%d'):format(id), function()
        return MySQL.query.await('SELECT `id` FROM `e_core_migrations` WHERE `id` = ? LIMIT 1', { id })
    end)
    if not ok then
        return false
    end
    return rows and rows[1] ~= nil
end

local function mark_migration_applied(id, name)
    local ok, err = hf.mysqlAwait(('migration:mark_%d'):format(id), function()
        MySQL.query.await(
            'INSERT IGNORE INTO `e_core_migrations` (`id`, `name`) VALUES (?, ?)',
            { id, name }
        )
    end)
    if not ok then
        error(tostring(err))
    end
end

local function migration_001_add_e_core_column()
    local sql
    if QB_CORE then
        sql = 'ALTER TABLE `players` ADD COLUMN IF NOT EXISTS `e_core` LONGTEXT NULL DEFAULT NULL'
    else
        sql = 'ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `e_core` LONGTEXT NULL DEFAULT NULL'
    end
    local ok, err = hf.mysqlAwait('migration:001_alter_e_core', function()
        MySQL.query.await(sql)
    end)
    if not ok then
        error(tostring(err))
    end
end

--- @return number legmagasabb alkalmazott migráció `id`, vagy 0 ha üres / hiba
function e_core_get_applied_migration_id()
    local ok, rows = hf.mysqlAwait('migration:max_id', function()
        return MySQL.query.await('SELECT MAX(`id`) AS `m` FROM `e_core_migrations`', {})
    end)
    if not ok or not rows or not rows[1] or rows[1].m == nil then
        return 0
    end
    local maxId = tonumber(rows[1].m) or 0
    if maxId < ECORE_DB_SCHEMA_TARGET then
        cLog(
            ('[e_core] DB migrációk elmaradva: alkalmazott_max=%d, repó_cél=%d (indítsd újra az e_core-t / nézd a migrációs hibákat).'):format(
                maxId,
                ECORE_DB_SCHEMA_TARGET
            ),
            'warning',
            2
        )
    end
    return maxId
end

function e_core_run_db_migrations()
    local ok, err = pcall(function()
        ensure_migrations_table()
        for _, m in ipairs(ECORE_DB_MIGRATIONS) do
            if not migration_applied(m.id) then
                m.run()
                mark_migration_applied(m.id, m.name)
                cLog(('[e_core] DB migration %d applied: %s'):format(m.id, m.name), 'info', 1)
            end
        end
    end)
    if not ok then
        local msg = tostring(err)
        print(('[^1e_core^7] DB migration failed: %s'):format(msg))
        error(('[e_core] DB migration failed: %s'):format(msg))
    end
end

ECORE_DB_MIGRATIONS = {
    { id = 1, name = 'add_e_core_longtext_column', run = migration_001_add_e_core_column },
}
