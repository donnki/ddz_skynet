local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local proxy = require "socket_proxy"

local CMD = {}
local roomusers = {}

local GAME_PLAYER = 3
local function getroomuser(index)
	local users = {}
	local count = 0
	for i=1,GAME_PLAYER do
		if roomusers[i] then
			users["user"..i] = roomusers[i].userid
			count = count + 1
		end
	end
	return users, count, skynet.self(), index
end

local function getuserbyid(userid)
	for i=1,GAME_PLAYER do
		if roomusers[i] and roomusers[i].userid == userid then
			return roomusers[i], i
		end
	end
end

function CMD.playernum()
	local _, count = getroomuser()
	return count
end

function CMD.joinroom(fd, userid, agentfd) 	--加入房间
	print("user： ",fd, userid, " has joinned room ")
	proxy.subscribe(fd)
	local index = 0
	for i=1,GAME_PLAYER do
		if not roomusers[i] then  	--找到一个空位就坐上去
			roomusers[i] = {fd=fd,userid=userid,agentfd=agentfd}
			index = i
			break
		end
	end

	for i=1,GAME_PLAYER do
		if index ~= i and roomusers[i] then 		--已上坐玩家发送消息更新房间
			client.fdpush(roomusers[i].fd, "onjoinroom", {index=index, userid=userid})
		end
	end
	return getroomuser(index)
end

function CMD.leftroom(userid) 	--离开房间
	local index = 0
	for i=1,GAME_PLAYER do
		if roomusers[i] and roomusers[i].userid == userid then
			roomusers[i] = nil
			index = i
			break
		end
	end

	for i=1,GAME_PLAYER do
		if roomusers[i] then 		--已上坐玩家发送消息更新房间
			client.fdpush(roomusers[i].fd, "onleftroom", {index=index, userid=userid})
		end
	end
	print("user: ", userid, " has left the room")
end

function CMD.onready(userid, flag)
	local user,index = getuserbyid(userid)
	if flag == "1" then
		user.ready = true
		print("~~~~~", userid, "on ready")
	else
		user.ready = false
		print("~~~~~", userid, "unready")
	end
	

	for i=1,GAME_PLAYER do 	--向房间里其它人发送“玩家已准备“消息
		if roomusers[i] and roomusers[i] ~= user then 
			client.fdpush(roomusers[i].fd, "onuserready", {index=index, userid=user.userid})
		end
	end

	local readycount = 0
	for i=1,GAME_PLAYER do
		if roomusers[i] and roomusers[i].ready then 
			readycount = readycount + 1
		end
	end

	if readycount == GAME_PLAYER then
		skynet.call(service.manager, "lua", "roomstart", skynet.self(), roomusers)
	end

end

service.init {
	command = CMD,
	require = {
		"manager",
	},
	init = client.init "proto",
}