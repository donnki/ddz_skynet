local skynet = require "skynet"
local service = require "service"
local log = require "log"

local manager = {}
local users = {}

local rooms = {waittingroom={}, runningroom={}}

local function new_agent()
	-- todo: use a pool
	return skynet.newservice "agent"
end

local function free_agent(agent)
	-- kill agent, todo: put it into a pool maybe better
	skynet.kill(agent)
end

function manager.assign(fd, userid)
	local agent
	repeat
		agent = users[userid]
		if not agent then
			agent = new_agent()
			if not users[userid] then
				-- double check
				users[userid] = agent
			else
				free_agent(agent)
				agent = users[userid]
			end
		end
	until skynet.call(agent, "lua", "assign", fd, userid)
	log("Assign %d to %s [%s]", fd, userid, agent)
end

--分配一个房间
function manager.assignroom(fd, userid, agentfd)
	local room
	for i,v in ipairs(rooms.waittingroom) do 	--等待中房间
		local nums = skynet.call(v, "lua", "playernum")
		if nums < 3 then 		--玩家数目小于3
			room = v
			break
		end
	end
	if not room then 	--新建房间
		room = skynet.newservice "room"
		table.insert(rooms.waittingroom, room)
	end
	-- local agent = users[userid]
	-- agent.room = room
	return skynet.call(room, "lua", "joinroom", fd, userid, agentfd)
end

--房间开始游戏
function manager.roomstart(roomfd, players)
	for i,v in ipairs(rooms.waittingroom) do
		if v == roomfd then
			table.remove(rooms.waittingroom, i)
			break
		end
	end
	table.insert(rooms.runningroom, roomfd)

	local game = skynet.newservice "game"
	skynet.call(game, "lua", "init", players)
end

function manager.exit(userid)
	users[userid] = nil
end

service.init {
	command = manager,
	data = users,
}


