local PATH,IP,UID = ...

IP = IP or "127.0.0.1"
UID = UID or "alice"
package.path = string.format("%s/lualib/?.lua;%s/client/?.lua;%s/skynet/lualib/?.lua", PATH, PATH, PATH)
package.cpath = string.format("%s/skynet/luaclib/?.so;%s/lsocket/?.so", PATH, PATH)

local socket = require "simplesocket"
local message = require "simplemessage"
local rules = require("ddz_rules")
require("luahelper")

message.register(string.format("%s/proto/%s", PATH, "proto"))

message.peer(IP, 5678)
message.connect()

local event = {}
local sitIndex = 0
message.bind({}, event)

local mycards
function event:__error(what, err, req, session)
	print("error", what, err)
end

function event:ping()
	-- print("ping")
end

function event:signin(req, resp)
	print("signin", req.userid, resp.ok)
	if resp.ok then
		message.request "ping"	-- should error before login
		message.request "login"
	else
		-- signin failed, signup
		message.request("signup", { userid = UID})
	end
end

function event:signup(req, resp)
	print("signup", resp.ok)
	if resp.ok then
		message.request("signin", { userid = req.userid })
	else
		error "Can't signup"
	end
end

function event:login(_, resp)
	print("login", resp.ok)
	if resp.ok then
		message.request "joinroom"
	else
		error "Can't login"
	end
end

function event:joinroom(_, resp)
	if resp.ok then
		sitIndex = resp.index
		print("successful join room, index=", sitIndex)
		for i=1,3 do
			print(resp.room["user"..i])
		end

		message.request("oncommand", {cmd="ready",parameters="1"})
		-- local cmd = io.read()
		-- if cmd then
		-- 	if cmd == "quit" then
		-- 		message.request("quit")
		-- 	elseif cmd == "ready" then
		-- 		message.request("oncommand", {cmd="ready",parameters="1"})
		-- 	end
		-- end
	end
end

function event:heartbeat()
	message.request "ping"
end

function event:onuserready(args)
	print("~~~~onuserready", args.index, args.userid)
end

function event:onjoinroom(args)
	print("~~~~onjoinroom", args.index, args.userid)
end

function event:onleftroom(args)
	print("~~~~onleftroom", args.index, args.userid)
end

local function requestmaster()
	io.write("是否抢地主（0|1|2|3）：")
	local cmd = io.read()
	if cmd then
		if cmd == "" then cmd = "0" end
 		message.request("oncommand", {cmd="master",parameters=cmd})
	end
end

local function dumpcards(cards)
	for i,v in pairs(mycards) do
		-- print(string.format("花色：%d，牌面：%s, 权重：%d", v.suit, v.display, v.grade))
		io.write(v.display.."("..v.id..") ")
		-- io.write(v.id..",")
	end
	io.write("\n")
end

local termcards
local function playcards()
	io.write("我的当前牌面：")
	dumpcards(mycards)
	io.write("请出牌（半角逗号分隔）：")
	local cmd = io.read()
	pcall(function()
		if cmd then
			if cmd == "" then
				message.request("oncommand", {cmd="play",parameters=string.char(0)})
			else
				local cards = cmd:split(",")
				termcards = cards
				message.request("oncommand", {cmd="play",parameters=string.char(table.unpack(cards))})
			end
			
		end
	end, function(err)
		playcards()
	end)
	
end

function event:ongameready(args)
	local cards = {string.byte(args.cards, 1, -1)}
	
	mycards = rules.getsortedcarddetails(cards)
	io.write("发牌结束，初始牌面：")
	for i,v in ipairs(mycards) do
		-- print(string.format("花色：%d，牌面：%s, 权重：%d", v.suit, v.display, v.grade))
		io.write(v.display.." ")
	end
	io.write("\n")

	if args.first == sitIndex then
		requestmaster()
	end
end


function event:ongamestart(args)
	local cards = {string.byte(args.excards, 1, -1)}
	print("游戏开始，地主是: "..args.master.."，地主牌：")
	local s = rules.getsortedcarddetails(cards)
	for i,v in pairs(s) do
		-- print(string.format("花色：%d，牌面：%s, 权重：%d", v.suit, v.display, v.grade))
		io.write(v.display.." ")
	end
	io.write("\n")

	if args.master == sitIndex then
		for i,v in pairs(s) do
			table.insert(mycards, v)
		end
		table.sort(mycards,function(a,b) return a.grade > b.grade end)
		playcards()
	end
end
function event:onrequestmaster(args)
	print("玩家"..args.index.."叫地主："..args.rate.."分")
	if args.next == sitIndex then
		requestmaster()
	end
end

function event:onplay(args)
	local cards = {string.byte(args.cards, 1, -1)}
	if args.ok then
		if cards[1] == 0 then
			print("玩家"..args.index.."PASS！")
		else
			local s = rules.getsortedcarddetails(cards)
			io.write("玩家"..args.index.."出牌：")
			for i,v in pairs(s) do
				io.write(v.display.." ")
			end
			io.write("\n")

			if args.index == sitIndex then
				for i2,v2 in ipairs(termcards) do
					local idx = table.icontains(mycards, tonumber(v2), function(a,b) return a.id == b end)
					if idx then
						--从玩家牌堆里移除牌
						table.remove(mycards, idx)
					end
				end
			end
		end
	end
	
	
	if args.next == sitIndex then
		playcards()
	end
	
end

function event:ongameover(args)
	if args.farmerwin then
		print("农民胜利")
	else
		print("地主胜利")
	end
end

function event:push(args)
	print("server push", args.text)
end

message.request("signin", { userid = UID })

while true do
	message.update()

end
