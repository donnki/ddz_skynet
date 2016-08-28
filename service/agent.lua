local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"

local agent = {}
local data = {}
local cli = client.handler()

function cli:ping()
	assert(self.login)
	-- log "ping"
end

function cli:login()
	assert(not self.login)
	if data.fd then
		log("login fail %s fd=%d", data.userid, self.fd)
		return { ok = false }
	end
	data.fd = self.fd
	self.login = true
	log("login succ %s fd=%d", data.userid, self.fd)
	client.push(self, "push", { text = "welcome" })	-- push message to client
	return { ok = true }
end

function cli:joinroom()
	assert(self.login) --TODO: 判断是否已登录
	skynet.fork(function()
		while true do
			client.push(self, "heartbeat")
			skynet.sleep(500)
		end
	end)
	local roominfo, count, roomfd, index = skynet.call(service.manager, "lua", "assignroom", self.fd, data.userid, data.agentfd)
	data.room = roomfd
	return { ok = true, room = roominfo, index=index }
end


function cli:oncommand(args)
	print("oncommand:", args.cmd, args.parameters)
	if args.cmd == "ready" then  --准备或取消准备
		if data.room then
			skynet.call(data.room, "lua", "onready", data.userid, args.parameters)
		else
			print("not join room yet.")
		end
	elseif args.cmd == "master" then --抢地主
		skynet.call(data.game, "lua", "askmaster", data.userid, tonumber(args.parameters))
	elseif args.cmd == "play" then --出牌
		skynet.call(data.game, "lua", "play", data.userid, args.parameters)
	end
end

local function new_user(fd)
	local ok, error = pcall(client.dispatch , { fd = fd })
	log("fd=%d is gone. error = %s", fd, error)
	client.close(fd)
	if data.room then
		skynet.call(data.room, "lua", "leftroom", data.userid)
	end
	if data.fd == fd then
		data.fd = nil
		skynet.sleep(1000)	-- exit after 10s
		if data.fd == nil then
			-- double check
			if not data.exit then
				data.exit = true	-- mark exit
				skynet.call(service.manager, "lua", "exit", data.userid)	-- report exit
				log("user %s afk", data.userid)
				skynet.exit()
			end
		end
	end
end

function agent.ongameready(gamefd, args)
	data.game = gamefd
	client.fdpush(data.fd, "ongameready", args)
end

function agent.assign(fd, userid)
	if data.exit then
		return false
	end
	if data.userid == nil then
		data.userid = userid
	end
	data.agentfd = skynet.self()

	assert(data.userid == userid)
	skynet.fork(new_user, fd)
	return true
end

service.init {
	command = agent,
	info = data,
	require = {
		"manager",
	},
	init = client.init "proto",
}

