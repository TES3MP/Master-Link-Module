local mlapi = require "mlapi"
local cjson = require "cjson.safe"

local dataDir = os.getenv("MOD_DIR") .. "/"

local function StartupCfg()
    local f = assert(io.open(dataDir .. "master.json", "r"))
    local cfg = cjson.decode(f:read("*a"))
    f:close()
    return cfg
end

local updateMasterId
local cfg = StartupCfg()
local reconnectionAttempts = cfg.reconnectionAttempts

local compatFlag = {
    manualMaxPl = false,
    manualPassw = false,
    pluginListWorkarround = false,
    onPlayerConnectRet = false,
    manualPort = false
}

local function CheckCompatibility()
    local verStr = tes3mp.GetServerVersion()
    local ver = {}
    for substr in verStr:gmatch("([^.-]+)") do
        local num = tonumber(substr)
        ver[#ver + 1] = not num and substr or num
    end

    -- pre 0.7.0-alpha versions
    if ver[2] < 7 or not (ver[2] == 7 and ver[4] ~= "alpha") then
        compatFlag.manualMaxPl = true
        compatFlag.manualPassw = true
        compatFlag.manualPort = true
    end

    compatFlag.pluginListWorkarround = true
    compatFlag.onPlayerConnectRet = true
end

local function LoadPluginList()
    local pluginList = {}
    local f = assert(io.open(dataDir .. "pluginlist.json", "r"))
    repeat
        local ln = f:read("*l") -- skip comments, since they are not supported by the JSON format
    until ln:sub(1, 1) ~= "/"
    local plugins = cjson.decode(f:read("*a"))

    local pluginCnt = 0
    for i, _ in pairs(plugins) do if tonumber(i) > pluginCnt then pluginCnt = tonumber(i) end end

    for i = 0, pluginCnt do
        for k, _ in pairs(plugins[tostring(i)]) do
            pluginList[#pluginList + 1] = k
        end
    end
    f:close()
    return pluginList
end

local pluginList = {}
local playerList = {}

local function Connect()
    local ml = mlapi.new("https://master.tes3mp.com/api/servers")

    if compatFlag.manualMaxPl then
        ml:SetMaxPlayers(cfg.compat.maxPlayers)
    else
        ml:SetMaxPlayers(tes3mp.GetMaxPlayers())
    end

    if compatFlag.manualPassw then
        ml:SetPassword(cfg.compat.hasPassword)
    else
        ml:SetPassword(tes3mp.HasPassword())
    end

    if compatFlag.manualPort then
        ml:SetPort(cfg.compat.port)
    else
        ml:SetPort(tes3mp.GetPort())
    end

    if compatFlag.pluginListWorkarround and #pluginList == 0 then
        pluginList = LoadPluginList()
    end

    ml:SetVersion(tes3mp.GetServerVersion())
    ml:SetPlugins(pluginList)
    ml:SetHostname(cfg.hostname)
    ml:SetModname(cfg.modname)
    ml:SetExtraInfo(cfg.extra)
    local status, message = ml:Login(cfg.login, cfg.password)

    if status == "authfail" and reconnectionAttempts ~= 0 then
        print("Auth failed, trying reconnect")
        reconnectionAttempts = reconnectionAttempts - 1
        print(status, message)
        tes3mp.RestartTimer(updateMasterId, ml:MaxRate())
        return
    elseif reconnectionAttempts == 0 then
        print("Cannot connect to master after few attempts")
        tes3mp.StopTimer(updateMasterId)
        return
    elseif status == "ok" then
        reconnectionAttempts = cfg.reconnectionAttempts
    end

    return ml
end

local hasChangesInPlayerList = false

local function UpdatePlayerList(ml)
    if not hasChangesInPlayerList then return end
    hasChangesInPlayerList = false

    local list = {}
    for _, name in playerList do
        list[#list + 1] = name
    end
    ml:SetPlayers(list)
end

local ml

function UpdateMaster()
    UpdatePlayerList(ml)

    local status, message = ml:Update()
    if status ~= "ok" then
        if status == "authfail" then
            ml = Connect()
        end
        if not ml then end
    end
    tes3mp.RestartTimer(updateMasterId, ml:MinRate())
end

function OnServerPostInit()
    CheckCompatibility()
    updateMasterId = tes3mp.CreateTimer("UpdateMaster", 0)
    ml = Connect()
    tes3mp.StartTimer(updateMasterId)
end

function OnPlayerConnect(pid)
    playerList[pid] = tes3mp.GetName(pid)
    hasChangesInPlayerList = true

    if onPlayerConnectRet == true then
        return true
    end
end

function OnPlayerDisconnect(pid)
    table.remove(playerList, pid)
    hasChangesInPlayerList = true
end
