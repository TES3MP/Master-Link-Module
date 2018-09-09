--[[
    Master Server API
    Version: 0.1


]]

local curl = require "lcurl.safe"
local cjson = require "cjson.safe"


------------------------------------------------------------------------------
--- Helper functions


local function SendRequest(address, request, data)

    local payload = cjson.encode(data)

    local cresult
    local p = curl.easy{
        url = address,
        httpheader = {
            "Content-Type: application/json"
        },
        customrequest = request,
        postfields = payload,
        writefunction = function(str) cresult = str end
    }
    :perform()
    if not p then return nil end
    p:close()

    if not cresult then return nil end

    local res = cjson.decode(cresult)

    if res ~= "null" then return res end
end


------------------------------------------------------------------------------
--- Module space


local _M = {}

local mt = {}
mt.__index = mt


function _M.new(address)
    local self = setmetatable({}, mt)
    self.address = address
    self.server = {
        port = 25565,
        modname = "",
        hostname = "",
        version = "",
        maxPlayers = 0,
        players = {},
        plugins = {},
        extraInfo = {},
        dlServer = "",
        passw = false
    }
    self.updateRate = {1000, 10000}
    return self
end


------------------------------------------------------------------------------
--- Authentication methods

function mt.Login(self, login, password)
    assert (type(login) == "string")
    assert (type(password) == "string")


    local payload = self.server
    self.server = {} -- reset after copying
    payload["login"] = login
    payload["password"] = password

    local result = SendRequest(self.address, "POST", payload)


    local status = "ok"
    local message

    if not result then
        message = "Failed to connect to master server"
        status = "authfail"
    else
        status = result["status"]
        message = result["message"]
        self.sessionId = result["sessionId"]
        local limitations = result["limitations"]
        if limitations then
            local updateRate = limitations["timeout"]
            if updateRate then
                self.updateRate = updateRate
            end
        end
    end
    return status, message
end


function mt.Update(self)
    assert(self.sessionId)

    local status = "ok"
    local message

    local payload = self.server
    self.server = {} -- reset after copying
    payload["sessionId"] = self.sessionId

    local result = SendRequest(self.address, "PUT", payload)

    if not result then
        message = "Failed to connect to master server"
        status = "authfail"
    else
        status = result["status"]
        message = result["message"]
    end

    return status, message
end

function mt.MinRate(self)
    return self.updateRate[1]
end

function mt.MaxRate(self)
    return self.updateRate[2]
end


------------------------------------------------------------------------------
--- Data manipulation methods


function mt.SetPort(self, port)
    assert(type(port) == "number")
    self.server.port = port
end

function mt.SetModname(self, modname)
    assert(type(modname) == "string")
    self.server.modname = modname
end

function mt.SetHostname(self, hostname)
    assert(type(hostname) == "string")
    self.server.hostname = hostname
end

function mt.SetVersion(self, version)
    assert(type(version) == "string")
    self.server.version = version
end

function mt.SetPassword(self, passw)
    assert(type(passw) == "boolean")
    self.server.passw = passw
end

function mt.SetPlayers(self, players)
    assert(type(players) == "table")
    self.server.players = players
end

function mt.SetMaxPlayers(self, maxPlayers)
    assert(type(maxPlayers) == "number")
    self.server.maxPlayers = maxPlayers
end

function mt.SetPlugins(self, plugins)
    assert(type(plugins) == "table")
    self.server.plugins = plugins
end

function mt.SetExtraInfo(self, extraInfo)
    assert(type(extraInfo) == "table")
    self.server.extraInfo = extraInfo
end


function mt.SetDLServer(self, dlServer)
    assert(type(dlServer) == "string")
    self.server.dlServer = dlServer
end


------------------------------------------------------------------------------


return _M
