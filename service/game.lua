local skynet = require "skynet"
local service = require "service"
local client = require "client"
local log = require "log"
local proxy = require "socket_proxy"
local rules = require "ddz_rules"
require "luahelper"
local CMD = {}
local players
local termIndex
local excards 
local askTimes
local curterm 
local GAME_PLAYER = 3

local precards

local function getindexbyid(userid)
	local index 
	for i,v in ipairs(players) do
		if v.userid == userid then
			index = i
		end
	end
	return index
end
local function shuffle(array)
	for i=1,#array do
		local r = math.random(1,54)
		local t = array[i]
		array[i] = array[r]
		array[r] = t 
	end
end
local function dump(array)
	for i=1,#array do
		io.write(array[i].." ")
	end
	io.write("\n")
end

local function serialize(cards)
	-- local s = ""
	-- for i=1,#cards do
	-- 	s = s..string.format("%c", cards[i])
	-- end
	-- return s
	return string.char(table.unpack(cards))
end

function CMD.init(_players)
	local str = ""
	for i,v in ipairs(_players) do
		str = str..v.userid.."("..v.fd.."), "
		v.card = {}
	end
	print("game init: players", str)
	players = _players

	local cards = {}
	for i=1,54 do
		cards[i] = i
	end
	shuffle(cards) 		--洗牌
	local t = 51/GAME_PLAYER 	--玩家牌数目
	for i=1,51 do 	--发牌51张
		table.insert(players[(i-1)%GAME_PLAYER+1].card, cards[i])
	end
	excards = {cards[52], cards[53], cards[54]}
	termIndex = math.random(1,GAME_PLAYER) 	--随机先叫地主
	askTimes = {} 		--抢地主的状态
	curterm = {} 		--当前轮的出牌状态
	for i,v in ipairs(players) do
		-- dump(v.card)
		print(skynet.address(v.agentfd))
		local s = serialize(v.card)
		skynet.call(v.agentfd, "lua", "ongameready", skynet.self(), {cards=s,first=termIndex})
		proxy.subscribe(v.fd)
		-- client.fdpush(v.fd, "ongameready", {cards=s,first=master}) 	--初始牌信息推送给每个玩家
	end
end

----------规则-------------
--1. 叫地主-不抢-不抢
--2. 叫地主-不抢-抢地主-抢地主
--3. 叫地主-不抢-抢地主-不抢
--4. 叫地主-抢地主-不抢-抢地主
--5. 叫地主-抢地主-不抢-不抢
--6. 叫地主-抢地主-抢地主-抢地主
--7. 叫地主-抢地主-抢地主-不抢
--8. 不叫-不叫-不叫
--9. 不叫-不叫-叫地主
--10. 不叫-抢地主-不抢
--11. 不叫-抢地主-抢地主-抢地主
--12. 不叫-抢地主-抢地主-不抢
function CMD.askmaster(userid, rate)
	print(userid, "ask master with rate: ", rate)
	local playerIndex = getindexbyid(userid)
	local nextIndex = playerIndex + 1
	

	table.insert(askTimes, rate)
	local finished = false
	local neednext = false

	--TODO：需要验证客户端数字有效性
	if #askTimes < 3 then
		neednext = true
	elseif #askTimes == 3 then --叫地主3次
		if askTimes[1] > 0 then
			if askTimes[2] == 0 and askTimes[3] == 0 then
				termIndex = termIndex   --#1
				finished = true
			else
				neednext = true
			end
		else 
			if askTimes[2] == 0 then
				if askTimes[3] == 0 then --#8
					--game restart
				else 				--#9
					termIndex = termIndex + 2  
					finished = true
				end
			else
				if askTimes[3] == 0 then --#10
					termIndex = termIndex + 1
					finished = true
				else
					neednext = true
					nextIndex = nextIndex + 1  --跳过1号
				end
			end
		end
	else  --叫地主相关的4次或以上
		if askTimes[1] > 0 then --1号抢地主
			if askTimes[2] == 0 and askTimes[3] >= askTimes[1] then --2号不抢地主,3号抢地主
				if askTimes[4] == 0 then --1号不抢，地主是3号
					termIndex = termIndex + 2  			--#3
					finished = true
				elseif askTimes[4] >= askTimes[3] then --1号抢地主，地主是1号
					termIndex = termIndex 	   			--#2
					finished = true
				end
			elseif askTimes[2] >= askTimes[1] then --2号抢地主
				if askTimes[3] >= askTimes[2] then --3号抢地主
					if askTimes[4] >= askTimes[3] then
						termIndex = termIndex  			--#6
						finished = true
					elseif askTimes[4] == 0 then 
						termIndex = termIndex + 2 		--#7
						finished = true
					end
				elseif askTimes[3] == 0 then --3号不抢
					if askTimes[4] >= askTimes[2] then --1号抢地主，地主是1号
						termIndex = termIndex  			--#4
						finished = true
					elseif askTimes[4] == 0 then 
						termIndex = termIndex + 2 		--#5
						finished = true
					end
				end
			else
				print("错误，抢地主的倍率不能小于上一家")
			end
		else --1号不抢地主
			if askTimes[2] > 0 and askTimes[3] >= askTimes[2] then
				if askTimes[4] >= askTimes[3] then
					termIndex = termIndex + 1   --#11
					finished = true
				elseif askTimes[4] == 0 then
					termIndex = termIndex + 2 	--#12
					finished = true
				end
			end
		end
	end
	if nextIndex > 3 then nextIndex = nextIndex - 3 end
	if termIndex > 3 then termIndex = termIndex - 3 end
	for i,v in ipairs(players) do
		client.fdpush(v.fd, "onrequestmaster", {rate=rate,index=playerIndex,next=(neednext and nextIndex or 0)}) 
	end
	if finished then
		for i,v in ipairs(excards) do
			table.insert(players[termIndex].card,v)
		end
		players[termIndex].master = true
		for i,v in ipairs(players) do
			client.fdpush(v.fd, "ongamestart", {master=termIndex,excards=serialize(excards)}) 
		end
	end
	
end

local function gameover(winner)
	skynet.sleep(200)
	local farmerwin = not players[winner].master
	--TODO:计算每个玩家的得分
	for i,v in ipairs(players) do
		client.fdpush(v.fd, "ongameover", {
			farmerwin=farmerwin,
			p1score=10,
			p2score=10,
			p3score=10
		}) 
	end
end

function CMD.play(userid, cardstr)
	local pindex = getindexbyid(userid)
	local cards = {string.byte(cardstr, 1, -1)}
	local ok = true
	
	--TODO: 检查重复ID
	if cards[1] == 0 then -- PASS
		print("玩家"..pindex.."PASS!")
		termIndex = pindex + 1
		if termIndex > 3 then termIndex = 1 end
		if precards and precards[1] == 0 then  --上一家也不要
			curtermcards = nil --清空precards
		end
		precards = cards
	else
		local s = rules.getsortedcarddetails(cards)
		io.write("玩家"..pindex.."本轮出牌：")
		for i,v in pairs(s) do
			io.write(v.display.." ")
		end
		io.write("\n")
		if rules.checkcards(curtermcards, cards) then --验证是否可以出牌
			for i2,v2 in ipairs(cards) do
				local idx = table.icontains(players[pindex].card, v2)
				if idx then
					--从玩家牌堆里移除牌
					table.remove(players[pindex].card, idx)
				end
			end
			
			if #players[pindex].card == 0 then --玩家已出完全部牌
				print("~~~~~gameover")
				termIndex = 0
				skynet.fork(gameover, pindex)
			else
				curtermcards = cards
				termIndex = pindex + 1
				if termIndex > 3 then termIndex = 1 end
			end
			precards = cards
		else --出牌无效
			cardstr = string.char(0)
			ok = false
		end
	end
	
	for i,v in ipairs(players) do
		client.fdpush(v.fd, "onplay", {cards=cardstr,index=pindex, next=termIndex, ok=ok}) 
	end
end

service.init {
	command = CMD,
	init = client.init "proto",
}