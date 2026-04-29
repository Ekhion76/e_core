--- e_core schema migrations (Phase 3).
--- Order: ascending `id`; each applied migration is stored in `e_core_migrations`.
--- Add new migration by extending `ECORE_DB_MIGRATIONS` and bumping `ECORE_DB_SCHEMA_TARGET` (export/docs).

ECORE_DB_SCHEMA_TARGET = 4
local hf = lib.require('src/imports/sdk/helper_base/shared')
local hfe = hfe

local MIGRATIONS_DDL = [[
CREATE TABLE IF NOT EXISTS `e_core_migrations` (
  `id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `name` VARCHAR(128) NOT NULL,
  `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function ensure_migrations_table()
    local ok, err = hfe.mysqlAwait('migration:ensure_table', function()
        MySQL.query.await(MIGRATIONS_DDL)
    end)
    if not ok then
        error(tostring(err))
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param id number
--- @return any result
local function migration_applied(id)
    local ok, rows = hfe.mysqlAwait(('migration:has_%d'):format(id), function()
        return MySQL.query.await('SELECT `id` FROM `e_core_migrations` WHERE `id` = ? LIMIT 1', { id })
    end)
    if not ok then
        -- Ne tételezzük fel, hogy a migráció nincs bent: különben ismételt DDL / inkonzisztens állapot.
        error(('[e_core] migration_applied(%d): DB lekérdezés sikertelen: %s'):format(id, tostring(rows)))
    end
    return rows and rows[1] ~= nil
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @param id number
--- @param name string
--- @return any result
local function mark_migration_applied(id, name)
    local ok, err = hfe.mysqlAwait(('migration:mark_%d'):format(id), function()
        MySQL.query.await(
            'INSERT IGNORE INTO `e_core_migrations` (`id`, `name`) VALUES (?, ?)',
            { id, name }
        )
    end)
    if not ok then
        error(tostring(err))
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function migration_001_add_e_core_column()
    local sql
    if QB_CORE then
        sql = 'ALTER TABLE `players` ADD COLUMN IF NOT EXISTS `e_core` LONGTEXT NULL DEFAULT NULL'
    else
        sql = 'ALTER TABLE `users` ADD COLUMN IF NOT EXISTS `e_core` LONGTEXT NULL DEFAULT NULL'
    end
    local ok, err = hfe.mysqlAwait('migration:001_alter_e_core', function()
        MySQL.query.await(sql)
    end)
    if not ok then
        error(tostring(err))
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function migration_002_create_profession_registry_tables()
    local createLevelProfilesSql = [[
CREATE TABLE IF NOT EXISTS `e_core_level_profiles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `profile_key` VARCHAR(64) NOT NULL,
  `display_name` VARCHAR(128) NOT NULL,
  `mode` VARCHAR(16) NOT NULL DEFAULT 'advanced',
  `levels_json` LONGTEXT NOT NULL,
  `created_by` VARCHAR(128) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_e_core_level_profiles_profile_key` (`profile_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

    local createProfessionsSql = [[
CREATE TABLE IF NOT EXISTS `e_core_professions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(64) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `display_name` VARCHAR(128) NOT NULL,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `level_profile_id` INT UNSIGNED NULL,
  `max_proficiency` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_e_core_professions_category_name` (`category`, `name`),
  KEY `ix_e_core_professions_level_profile_id` (`level_profile_id`),
  CONSTRAINT `fk_e_core_professions_level_profile_id`
    FOREIGN KEY (`level_profile_id`) REFERENCES `e_core_level_profiles` (`id`)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

    local ok1, err1 = hfe.mysqlAwait('migration:002_create_level_profiles', function()
        MySQL.query.await(createLevelProfilesSql)
    end)
    if not ok1 then
        error(tostring(err1))
    end

    local ok2, err2 = hfe.mysqlAwait('migration:002_create_professions', function()
        MySQL.query.await(createProfessionsSql)
    end)
    if not ok2 then
        error(tostring(err2))
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function migration_003_create_cleanup_jobs_table()
    local createCleanupJobsSql = [[
CREATE TABLE IF NOT EXISTS `e_core_cleanup_jobs` (
  `job_id` VARCHAR(32) NOT NULL,
  `status` VARCHAR(16) NOT NULL,
  `mode` VARCHAR(16) NOT NULL,
  `category` VARCHAR(64) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `requested_by` VARCHAR(128) NULL,
  `batch_size` INT UNSIGNED NOT NULL DEFAULT 500,
  `last_cursor` VARCHAR(128) NULL,
  `processed` INT UNSIGNED NOT NULL DEFAULT 0,
  `changed_rows` INT UNSIGNED NOT NULL DEFAULT 0,
  `removed_keys` INT UNSIGNED NOT NULL DEFAULT 0,
  `failed` INT UNSIGNED NOT NULL DEFAULT 0,
  `invalid_json` INT UNSIGNED NOT NULL DEFAULT 0,
  `cancel_requested` TINYINT(1) NOT NULL DEFAULT 0,
  `errors_json` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `started_at` TIMESTAMP NULL DEFAULT NULL,
  `finished_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`job_id`),
  KEY `ix_e_core_cleanup_jobs_status_created` (`status`, `created_at`),
  KEY `ix_e_core_cleanup_jobs_profession` (`category`, `name`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

    local ok, err = hfe.mysqlAwait('migration:003_create_cleanup_jobs', function()
        MySQL.query.await(createCleanupJobsSql)
    end)
    if not ok then
        error(tostring(err))
    end
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
local function migration_004_create_admin_denied_audit_table()
    local createDeniedAuditSql = [[
CREATE TABLE IF NOT EXISTS `e_core_admin_denied_audit` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ts` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `section` VARCHAR(64) NOT NULL,
  `action` VARCHAR(128) NOT NULL,
  `source` INT NULL,
  `requested_by` VARCHAR(128) NULL,
  `reason` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_e_core_admin_denied_audit_ts` (`ts`),
  KEY `ix_e_core_admin_denied_audit_section_action_ts` (`section`, `action`, `ts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

    local ok, err = hfe.mysqlAwait('migration:004_create_admin_denied_audit', function()
        MySQL.query.await(createDeniedAuditSql)
    end)
    if not ok then
        error(tostring(err))
    end
end

--- @return number Highest applied migration `id`, or 0 when empty/error.
function e_core_get_applied_migration_id()
    local ok, rows = hfe.mysqlAwait('migration:max_id', function()
        return MySQL.query.await('SELECT MAX(`id`) AS `m` FROM `e_core_migrations`', {})
    end)
    if not ok or not rows or not rows[1] or rows[1].m == nil then
        return 0
    end
    local maxId = tonumber(rows[1].m) or 0
    if maxId < ECORE_DB_SCHEMA_TARGET then
        hf.cLog(
            ('[e_core] DB migrációk elmaradva: alkalmazott_max=%d, repó_cél=%d (indítsd újra az e_core-t / nézd a migrációs hibákat).')
            :format(
                maxId,
                ECORE_DB_SCHEMA_TARGET
            ),
            'warning',
            2
        )
    end
    return maxId
end

--- Auto-generated annotation. Refine behavior details if needed.
--- @return any result
function e_core_run_db_migrations()
    local ok, err = pcall(function()
        ensure_migrations_table()
        for _, m in ipairs(ECORE_DB_MIGRATIONS) do
            if not migration_applied(m.id) then
                m.run()
                mark_migration_applied(m.id, m.name)
                hf.cLog(('[e_core] DB migration %d applied: %s'):format(m.id, m.name), 'info', 1)
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
    { id = 1, name = 'add_e_core_longtext_column',        run = migration_001_add_e_core_column },
    { id = 2, name = 'create_profession_registry_tables', run = migration_002_create_profession_registry_tables },
    { id = 3, name = 'create_cleanup_jobs_table',         run = migration_003_create_cleanup_jobs_table },
    { id = 4, name = 'create_admin_denied_audit_table',   run = migration_004_create_admin_denied_audit_table },
}
