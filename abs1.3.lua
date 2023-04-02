local version = 1.3
local modname = "abs"

function getTeam(clientNum)
    return et.gentity_get(clientNum, "sess.sessionTeam")
end

-- callbacks
function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname(modname .. " " .. version)
end

function et_ClientSpawn(clientNum, revived, teamChange, restoreHealth)
    et.gentity_set(clientNum, "ps.powerups", et.PW_NOFATIGUE, 1)
    et.gentity_set(clientNum, "health", 10000)
    if getTeam(clientNum) == 1 then
        et.AddWeaponToPlayer(clientNum, et.WP_MP40, 9999, 9999, 0)
    end
    if getTeam(clientNum) == 2 then
        et.AddWeaponToPlayer(clientNum, et.WP_THOMPSON, 9999, 9999, 0)
    end
end

