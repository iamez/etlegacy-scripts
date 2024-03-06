local modname = "c0rnsp0rn"
local version = "1.0"

-- local constants

local storeTimeInterval = 5000 -- how often we store players stats
local CON_CONNECTED     = 2
local WS_KNIFE          = 0
local WS_MAX            = 28
local PERS_SCORE        = 0

-- local variables

local maxClients     = 20
local nextStoreTime  = 0
local intermission   = false
local stats          = {}

-- global variables
killing_sprees = {}
death_sprees = {}
topshots = {}
kmulti = {}
multikills = {}
wait_table = {}
hitters = {}
light_weapons = {1,2,3,5,6,7,8,9,10,11,12,13,14,17,37,38,44,45,46,50,51,53,54,55,56,61,62,66}
explosives = {15,16,18,19,20,22,23,26,39,40,41,42,52,63,64}
HR_HEAD = 0
HR_ARMS = 1
HR_BODY = 2
HR_LEGS = 3
HR_NONE = -1
HR_TYPES = {HR_HEAD, HR_ARMS, HR_BODY, HR_LEGS}
hitRegionsData = {}
death_time = {}
death_time_total = {}
players = {}
ltm2 = 0
redspawn = 0
bluespawn = 0
redspawn2 = 0
bluespawn2 = 0
spawns = {}
redflag = false
blueflag = false
redlimbo1 = 0
bluelimbo1 = 0
redlimbo2 = 0
bluelimbo2 = 0
changedred = false
changedblue = false
paused = false

function ConvertTimelimit(timelimit)
	local msec    = math.floor(tonumber(timelimit) * 60000)
	local seconds = math.floor(msec / 1000)
	local mins    = math.floor(seconds / 60)
	seconds       = math.floor(seconds - (mins * 60))
	local tens    = math.floor(seconds / 10)
	seconds       = math.floor(seconds - (tens * 10))
	
	return string.format("%i:%i%i", mins, tens, seconds)
end

function isEmpty(str)
	if str == nil or str == '' then
		return 0
	end
	return str
end

function roundNum(num, n)
	local mult = 10^(n or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function getMatchID(matchIDPath)
	print(matchIDPath)
    local matchFile = assert(io.open(matchIDPath, "rb")) -- r read mode and b binary mode
    if not matchFile then return 0 end
	-- Use "a" in Lua 5.3; "*a" in Lua 5.1 and 5.2
    local matchID = assert(matchFile:read(_VERSION <= "Lua 5.2" and "*a" or "a"))
    matchFile:close()
    return matchID
end

-- char *G_createStats(gentity_t *ent) g_match.c
function StoreStats()
	for i = 0, max_clients - 1 do
	    if et.gentity_get(i, "pers.connected") == CON_CONNECTED then
			local dwWeaponMask = 0
			local aWeaponStats = {}
			local weaponStats  = ""

			for j = WS_KNIFE, WS_MAX - 1 do
				aWeaponStats[j] = et.gentity_get(i, "sess.aWeaponStats", j)

				local atts      = aWeaponStats[j][1]
				local deaths    = aWeaponStats[j][2]
				local headshots = aWeaponStats[j][3]
				local hits      = aWeaponStats[j][4]
				local kills     = aWeaponStats[j][5]
				topshots[i][11] = topshots[i][11] + atts

				if atts ~= 0 or hits ~= 0 or deaths ~= 0 or kills ~= 0 then
					weaponStats  = string.format("%s %d %d %d %d %d", weaponStats, hits, atts, kills, deaths, headshots)
					dwWeaponMask = dwWeaponMask | (1 << j)
				end
			end

			if dwWeaponMask ~= 0 then
				local userinfo = et.trap_GetUserinfo(i)
				local guid     = string.upper(et.Info_ValueForKey(userinfo, "cl_guid"))
				local name     = et.gentity_get(i, "pers.netname")
				local rounds   = et.gentity_get(i, "sess.rounds")
				local team     = et.gentity_get(i, "sess.sessionTeam")

				local damageGiven        = et.gentity_get(i, "sess.damage_given")
				local damageReceived     = et.gentity_get(i, "sess.damage_received")
				local teamDamageGiven    = et.gentity_get(i, "sess.team_damage_given")
				local teamDamageReceived = et.gentity_get(i, "sess.team_damage_received")
				local gibs               = et.gentity_get(i, "sess.gibs")
				local deaths           = et.gentity_get(i, "sess.deaths")
				local kills                = et.gentity_get(i, "sess.kills")
				local selfkills          = et.gentity_get(i, "sess.self_kills")
				local teamkills          = et.gentity_get(i, "sess.team_kills")
				local teamgibs           = et.gentity_get(i, "sess.team_gibs")
				local timeAxis           = et.gentity_get(i, "sess.time_axis")
				local timeAllies         = et.gentity_get(i, "sess.time_allies")
				local timePlayed         = et.gentity_get(i, "sess.time_played")
				local tp                  = timeAxis + timeAllies
				local xp                 = et.gentity_get(i, "ps.persistant", PERS_SCORE)
				timePlayed               = timeAxis + timeAllies == 0 and 0 or (100.0 * timePlayed / (timeAxis + timeAllies))
				local kd = 0
				local dpm = 0
				dpm = damageGiven/((tp/1000)/60)
				topshots[i][12] = roundNum(dpm, 2)
				if damageReceived > 1000 then
					local drdr = 0
					if deaths ~= 0 then
						drdr = (damageReceived / deaths) / 130
					else
						drdr = (damageReceived + 1) / 130
					end
					if drdr > 3 then
						topshots[i][13] = roundNum(drdr, 2)
					end
				end
				if death_time[i] ~= 0 then
					local diff = et.trap_Milliseconds() - death_time[i]
					death_time_total[i] = death_time_total[i] + diff
				end
				if tp > 120000 or tp == et.trap_Cvar_Get("timelimit") then
					if (death_time_total[i] / tp) * 100 > 0 then
						topshots[i][14] = roundNum((death_time_total[i] / tp) * 100, 2)
					end
				end
				if deaths ~= 0 then
					kd = roundNum(kills/deaths, 2)
				else
					kd = kills + 1
				end
				
				stats[guid] = string.format("%s\\%s\\%d\\%d\\%d%s", string.sub(guid, 1, 8), name, rounds, team, dwWeaponMask, weaponStats)
				stats[guid] = string.format("%s %d %d %d %d %d %d %d %d %0.1f %d %d %d %d %d %d %d %d %d %d %d %d %0.1f %0.1f %0.1f %d %0.1 %d %d %d %d %d %d\n", stats[guid], damageGiven, damageReceived, teamDamageGiven, teamDamageReceived, gibs, selfkills, teamkills, teamgibs, timePlayed, xp, topshots[i][1], topshots[i][2], topshots[i][3], topshots[i][4], topshots[i][5], topshots[i][6], topshots[i][7], topshots[i][8], topshots[i][9], topshots[i][10], topshots[i][11], topshots[i][12], topshots[i][13], topshots[i][14], roundNum((death_time_total[i] / 60000), 2), kd, topshots[i][15], multikills[i][1], multikills[i][2], multikills[i][3], multikills[i][4], multikills[i][5])
			end
		end
	end
end

function SaveStats()
	local statsPath = "/home/puran/etlegacy-v2.81.1-x86_64/legacy/gamestats/"
	local matchIDFile   = "matchid.txt"
	local matchID 	   = getMatchID(statsPath .. matchIDFile)
	local mapname      = et.Info_ValueForKey(et.trap_GetConfigstring(et.CS_SERVERINFO), "mapname")
	local round        = tonumber(et.trap_Cvar_Get("g_currentRound")) == 0 and 2 or 1
	local fileName     = string.format("gamestats\\%s-%s%s-round-%d.txt", matchID, os.date('%Y-%m-%d-%H%M%S-'), mapname, round)
	
	
	-- header data
	local servername    = et.trap_Cvar_Get("sv_hostname")
	local config        = et.trap_Cvar_Get("g_customConfig")
	local defenderteam  = tonumber(isEmpty(et.Info_ValueForKey(et.trap_GetConfigstring(et.CS_MULTI_INFO), "d"))) + 1 -- change from scripting value for winner (0==AXIS, 1==ALLIES) to spawnflag value
	local winnerteam    = tonumber(isEmpty(et.Info_ValueForKey(et.trap_GetConfigstring(et.CS_MULTI_MAPWINNER), "w"))) + 1 -- change from scripting value for winner (0==AXIS, 1==ALLIES) to spawnflag value
	local timelimit     = ConvertTimelimit(et.trap_Cvar_Get("timelimit"))
	local nextTimeLimit = ConvertTimelimit(et.trap_Cvar_Get("g_nextTimeLimit"))
	local header        = string.format("%s\\%s\\%s\\%d\\%d\\%d\\%s\\%s\\%s\n", servername, mapname, config, round, defenderteam, winnerteam, timelimit, nextTimeLimit, matchID)

	local fileHandle = et.trap_FS_FOpenFile(fileName, et.FS_WRITE)
	et.trap_FS_Write(header, string.len(header), fileHandle);

	for i, value in pairs(stats) do
		et.trap_FS_Write(value, string.len(value), fileHandle);
	end

	et.trap_FS_FCloseFile(fileHandle)
end

function et_ShutdownGame(restart) -- store and save stats for when 2nd round changes to different map before intermission
    if restart == 0 then
        StoreStats()
        SaveStats()
    end
end

function et_RunFrame(levelTime)
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	
	-- store stats in case player leaves prematurely
	if levelTime >= nextStoreTime then
		StoreStats()
		nextStoreTime = levelTime + storeTimeInterval
	end

	if gamestate == et.GS_INTERMISSION and not intermission then
		intermission = true
		StoreStats()
		SaveStats()
	end

	if gamestate ~= et.GS_INTERMISSION then
		intermission = false
	end
	
	if gamestate == 0 then
		local cs = tonumber(et.trap_GetConfigstring(et.CS_SERVERTOGGLES))
		if paused == false then
			if (1 << 4 & cs) == 1 then
				paused = true
				changedred = true
				redflag = false
				changedblue = true
				blueflag = false
			end
		elseif paused == true then
			if (1 << 4 & cs) == 0 then
				paused = false
			end
		end

		local ltm = et.trap_Milliseconds()
		for id, arr in pairs(wait_table) do
			local startpause = tonumber(arr[1])
			local whichkill = arr[2]
		
			if whichkill == 2 and (startpause + 3100) < ltm then
				multikills[id][1] = multikills[id][1] + 1
				wait_table[id] = nil
			end
		
			if whichkill == 3 and (startpause + 3100) < ltm then
				multikills[id][2] = multikills[id][2] + 1
				wait_table[id] = nil
			end
		
			if whichkill == 4 and (startpause + 3100) < ltm then
				multikills[id][3] = multikills[id][3] + 1
				wait_table[id] = nil
			end
		
			if whichkill == 5 and (startpause + 3100) < ltm then
				multikills[id][4] = multikills[id][4] + 1
				wait_table[id] = nil
			end
		
			if whichkill == 6 and (startpause + 3100) < ltm then
				multikills[id][5] = multikills[id][5] + 1
				wait_table[id] = nil
			end
		end

		if math.fmod(levelTime, 1000) ~= 0 then return end
		redlimbo1 = tonumber(et.trap_Cvar_Get("g_redlimbotime"))
		bluelimbo1 = tonumber(et.trap_Cvar_Get("g_bluelimbotime"))
		if redlimbo2 == 0 then
			redlimbo2 = redlimbo1
			bluelimbo2 = bluelimbo1
		end
		if redlimbo1 ~= redlimbo2 or bluelimbo1 ~= bluelimbo2 then
			if redlimbo1 ~= redlimbo2 then
				changedred = true
				redflag = false
				redlimbo2 = redlimbo1
			elseif bluelimbo1 ~= bluelimbo2 then
				changedblue = true
				blueflag = false
				bluelimbo2 = bluelimbo1
			end
		end
		ltm2 = os.time()
		if redflag == true then
			if ltm2 == redspawn + redlimbo1 / 1000 then
				redspawn = ltm2
			end
		end
		if blueflag == true then
			if ltm2 == bluespawn + bluelimbo1 / 1000 then
				bluespawn = ltm2
			end
		end
	end
end

function et_InitGame()
	et.RegisterModname(modname .. " " .. version)

	max_clients = tonumber(et.trap_Cvar_Get("sv_maxClients"))
	gamestate = -1

	local i = 0
	for i=0, max_clients-1 do
		killing_sprees[i] = 0
		death_sprees[i] = 0
		topshots[i] = { [1]=0, [2]=0, [3]=0, [4]=0, [5]=0, [6]=0, [7]=0, [8]=0, [9]=0, [10]=0, [11]=0, [12]=0, [13]=0, [14]=0, [15]=0} -- [1]=killing spree, [2]=death spree, [3]=kill assists, [4]=kill steals, [5]=headshot kills, [6]=objectives stolen, [7]=objectives returned, [8]=dynamites planted, [9]=dynamites defused, [10]=most revived, [11]=bullets fired, [12]=DPM, [13]=tank/meatshield, [14]=time dead ratio, [15]=most useful kills
		kmulti[i] = { [1]=0, [2]=0 }
		multikills[i] = { [1]=0, [2]=0, [3]=0, [4]=0, [5]=0 } -- 2 kills, 3 kills, 4 kills, 5 kills, 6 kills
		hitters[i] = {nil, nil, nil, nil}
		death_time[i] = 0
        death_time_total[i] = 0
		players[i] = nil
        spawns[i] = nil
	end
end

function checkKSpreeEnd(id)
	if killing_sprees[id] >= 3 then
		if killing_sprees[id] > topshots[id][1] then
			topshots[id][1] = killing_sprees[id]
		end
	end
end

function checkDSpreeEnd(id)
	if death_sprees[id] >= 3 then
		if death_sprees[id] > topshots[id][2] then
			topshots[id][2] = death_sprees[id]
		end
	end
end

function checkMultiKill(id, mod)
	local lvltime = et.trap_Milliseconds()
	if (lvltime - kmulti[id][1]) < 3000 then
		kmulti[id][2] = kmulti[id][2] + 1
	
		if kmulti[id][2] == 2 then
			wait_table[id] = {lvltime, 2}
		elseif kmulti[id][2] == 3 then
			wait_table[id] = {lvltime, 3}
		elseif kmulti[id][2] == 4 then
			wait_table[id] = {lvltime, 4}
		elseif kmulti[id][2] == 5 then
			wait_table[id] = {lvltime, 5}
		elseif kmulti[id][2] == 6 then
			wait_table[id] = {lvltime, 6}
		end
	else
		kmulti[id][2] = 1
	end
	kmulti[id][1] = lvltime
end

function et_Obituary(victim, killer, mod)
	if gamestate == 0 then
		local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
		local k_teamid = -1
		if killer ~= 1022 and killer ~= 1023 then -- no world / unknown kills
			k_teamid = et.gentity_get(killer, "sess.sessionTeam")
		end

		if victim == killer then
			if mod ~= 59 then -- switchteam
				death_sprees[victim] = death_sprees[victim] + 1
				death_time[victim] = et.trap_Milliseconds()
			end
			checkKSpreeEnd(victim)
			killing_sprees[victim] = 0
		else
			death_time[victim] = et.trap_Milliseconds()
			if v_teamid == k_teamid then -- team kill
				checkKSpreeEnd(victim)
				killing_sprees[victim] = 0
				--death_sprees[victim] = death_sprees[victim] + 1
			else -- normal kill
				if killer ~= 1022 and killer ~= 1023 then -- no world / unknown kills
					killing_sprees[killer] = killing_sprees[killer] + 1
					death_sprees[victim] = death_sprees[victim] + 1
					checkMultiKill(killer, mod)
					checkKSpreeEnd(victim)
					checkDSpreeEnd(killer)
					killing_sprees[victim] = 0
					death_sprees[killer] = 0
					if v_teamid == 1 then
						if redspawn + redlimbo1 / 1000 - ltm2 >= (redlimbo1/1000)/2 and redspawn + redlimbo1 / 1000 - ltm2 > 0 then
							topshots[killer][15] = topshots[killer][15] + 1
						end
					elseif v_teamid == 2 then
						if bluespawn + bluelimbo1 / 1000 - ltm2 >= (bluelimbo1/1000)/2 and bluespawn + bluelimbo1 / 1000 - ltm2 > 0 then
							topshots[killer][15] = topshots[killer][15] + 1
						end
					end
				else
					checkKSpreeEnd(victim)
				end
			end
		end

		if has_value(light_weapons, mod) or has_value(explosives, mod) then
			local killer_dmg = 0
			local assist_dmg = {}
			local last_assist_wpn = {}
			local ms = et.trap_Milliseconds()
			for m=ms, ms-1500, -1 do
				if hitters[victim][m] then
					if hitters[victim][m][1] == killer then
						killer_dmg = killer_dmg + hitters[victim][m][2]
					else
						if assist_dmg[hitters[victim][m][1]] == nil then
							assist_dmg[hitters[victim][m][1]] = hitters[victim][m][2]
						else
							assist_dmg[hitters[victim][m][1]] = assist_dmg[hitters[victim][m][1]] + hitters[victim][m][2]
						end
						if not last_assist_wpn[hitters[victim][m][1]] then
							last_assist_wpn[hitters[victim][m][1]] = hitters[victim][m][3]
						end
					end
				end
			end
			local keyset={}
			local n=0
			for k,v in pairs(assist_dmg) do
				n=n+1
				keyset[n]=k
			end
			for j=1,#keyset do
				if v_teamid ~= et.gentity_get(keyset[j], "sess.sessionTeam") then
					topshots[keyset[j]][3] = topshots[keyset[j]][3] + 1
				end
				if assist_dmg[keyset[j]] > killer_dmg then
					if not has_value(explosives, mod) and not has_value(explosives, last_assist_wpn[keyset[j]]) then
						if v_teamid ~= et.gentity_get(keyset[j], "sess.sessionTeam") and v_teamid ~= k_teamid then 
							topshots[killer][4] = topshots[killer][4] + 1
						end
					end
				end
			end
		end
	end
end

function has_value (tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

function getAllHitRegions(clientNum)
	local regions = {}
	for index, hitType in ipairs(HR_TYPES) do
		regions[hitType] = et.gentity_get(clientNum, "pers.playerStats.hitRegions", hitType)
	end       
	return regions
end     

function hitType(clientNum)
	local playerHitRegions = getAllHitRegions(clientNum)
	if hitRegionsData[clientNum] == nil then
		hitRegionsData[clientNum] = playerHitRegions
		return 2
	end
	for index, hitType in ipairs(HR_TYPES) do
		if playerHitRegions[hitType] > hitRegionsData[clientNum][hitType] then
			hitRegionsData[clientNum] = playerHitRegions
			return hitType
		end		
	end
	hitRegionsData[clientNum] = playerHitRegions
	return -1
end

function et_ClientSpawn(id, revived)
	killing_sprees[id] = 0
	local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
	if revived ~= 1 then
		local health = tonumber(et.gentity_get(id, "health"))
		local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
		if team == 1 then
			if health > 0 then
				if redflag == false then
					if spawns[id] == nil then
						spawns[id] = 1
					else
						spawns[id] = spawns[id] + 1
					end
					if spawns[id] == 2 then
						redflag = true
						redspawn = os.time()
					end
					if changedred == true then
						redflag = true
						redspawn = os.time()
						changedred = false
					end
				end
				redspawn2 = os.time()
				if redspawn ~= 0 and redspawn ~= redspawn2 then
					redspawn = redspawn2
				end
			end
		elseif team == 2 then
			if health > 0 then
				if blueflag == false then
					if spawns[id] == nil then
						spawns[id] = 1
					else
						spawns[id] = spawns[id] + 1
					end
					if spawns[id] == 2 then
						blueflag = true
						bluespawn = os.time()
					end
					if changedblue == true then
						blueflag = true
						bluespawn = os.time()
						changedblue = false
					end
				end
				bluespawn2 = os.time()
				if bluespawn ~= 0 and bluespawn ~= bluespawn2 then
					bluespawn = bluespawn2
				end
			end
		end
	end
	hitters[id] = {nil, nil, nil, nil}
	hitRegionsData[id] = getAllHitRegions(id)
	if team == 1 or team == 2 then
		if death_time[id] ~= 0 then
			local diff = et.trap_Milliseconds() - death_time[id]
			death_time_total[id] = death_time_total[id] + diff
		end
	end
	death_time[id] = 0
end

function et_ClientDisconnect(id)
	killing_sprees[id] = 0
	death_sprees[id] = 0
	topshots[id] = { [1]=0, [2]=0, [3]=0, [4]=0, [5]=0, [6]=0, [7]=0, [8]=0, [9]=0, [10]=0, [11]=0, [12]=0, [13]=0, [14]=0, [15]=0}
	kmulti[id] = { [1]=0, [2]=0 }
	multikills[id] = { [1]=0, [2]=0, [3]=0, [4]=0, [5]=0 }
	hitters[id] = {nil, nil, nil, nil}
	death_time[id] = 0
	death_time_total[id] = 0
	players[id] = nil
	spawns[id] = nil
end

function et_Damage(target, attacker, damage, damageFlags, meansOfDeath)
	if target ~= attacker and attacker ~= 1022 and attacker ~= 1023 then
		if has_value(light_weapons, meansOfDeath) or has_value(explosives, meansOfDeath) then
			local v_team = et.gentity_get(target, "sess.sessionTeam")
			local k_team = et.gentity_get(attacker, "sess.sessionTeam")
			local v_health = et.gentity_get(target, "health")
			local hitType = hitType(attacker)
			if hitType == HR_HEAD then
				if not has_value(explosives, meansOfDeath) then
					hitters[target][et.trap_Milliseconds()] = {[1]=attacker, [2]=damage, [3]=meansOfDeath}
					if v_team ~= k_team then
						if damage >= v_health then
							topshots[attacker][5] = topshots[attacker][5] + 1 -- headshot kill
						end
					end
				end
			else
				hitters[target][et.trap_Milliseconds()] = {[1]=attacker, [2]=damage, [3]=meansOfDeath}
			end
		end
	end
end

function et_Print(text)
	if gamestate == 0 then
		if string.find(text, "team_CTF_redflag") or string.find(text, "team_CTF_blueflag") then
			local i, j = string.find(text, "%d+")   
			local id = tonumber(string.sub(text, i, j))
			if string.find(text, "team_CTF_redflag") then
				local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
				if team == 2 then
					topshots[id][6] = topshots[id][6] + 1
				elseif team == 1 then
					topshots[id][7] = topshots[id][7] + 1
				end
			elseif string.find(text, "team_CTF_blueflag") then
				local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
				if team == 1 then
					topshots[id][6] = topshots[id][6] + 1
				elseif team == 2 then
					topshots[id][7] = topshots[id][7] + 1
				end
			end
		end
		if string.find(text, "Dynamite_Plant") then
			local i, j = string.find(text, "%d+")   
			local id = tonumber(string.sub(text, i, j))
			topshots[id][8] = topshots[id][8] + 1
		end
		if string.find(text, "Dynamite_Diffuse") then
			local i, j = string.find(text, "%d+")   
			local id = tonumber(string.sub(text, i, j))
			topshots[id][9] = topshots[id][9] + 1
		end
		if string.find(text, "Medic_Revive") then
			local junk1,junk2,medic,revived = string.find(text, "^Medic_Revive:%s+(%d+)%s+(%d+)")
			topshots[tonumber(revived)][10] = topshots[tonumber(revived)][10] + 1
		end
	end


	if text == "Exit: Timelimit hit.\n" or text == "Exit: Wolf EndRound.\n" then
		for i = 0, max_clients-1 do
			if killing_sprees[i] > 0 then
				checkKSpreeEnd(i)
			end
		end
		return(nil)
	end
end

