--- DB domain init (server): side effects only (DB bootstrap hooks).

MySQL.ready(function()
    e_core_run_db_migrations()
    if type(e_core_schedule_admin_denied_audit_purge) == 'function' then
        e_core_schedule_admin_denied_audit_purge()
    end
end)
