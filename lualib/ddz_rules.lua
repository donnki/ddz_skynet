local suittype = {  
	Spade = 1, 			--黑桃
	Heart = 2, 			--红桃
	Club = 3, 			--梅花
	Diamond = 4, 		--方块
	Joker = 5,  		--大小王
}

local CardDisplay = {
	"A","2","3","4","5","6","7","8","9","10","J","Q","K","Kinglet","King",
}

local cardtype = {
	dan = 1, 			--单张
	duizi = 2,			--对子
	wangzha = 3,		--王炸 
	zhadan = 4,			--炸弹
	shunzi = 5, 		--顺子
	liandui = 6,		--连对
	san = 7, 			--三张（不带）
	sandaiyi = 8,		--三带一
	sandaidui = 9, 		--三带一对
	feiji = 10, 		--飞机（不带）
	feiji2 = 11, 		--飞机（单带）
	feiji4 = 12, 		--飞机（带对子）
	sidaier = 13, 		--四带二
	sidaierdui = 14, 	--四带两对
}

local function getsuit(id)  --花色
	local bigType = nil
	if id >= 1 and id <= 13 then
		bigType = suittype.Diamond
	elseif id >= 14 and id <= 26 then
		bigType = suittype.Club
	elseif id >= 27 and id <= 39 then
		bigType = suittype.Heart
	elseif id >= 40 and id <= 52 then
		bigType = suittype.Spade 
	elseif id == 53 or id == 54 then
		bigType = suittype.Joker
	end
	return bigType
end

local function getdisplay(id)  --牌号
	local display = nil
	if id >= 1 and id <= 52 then
		display = CardDisplay[(id-1) % 13 + 1]
	elseif id == 53 then
		display = CardDisplay[14]
	elseif id == 54 then
		display = CardDisplay[15]
	end
	return display
end

local function getgrade(id)  --权级
	local grade = 0
	if id == 53 then --小王
		grade = 16
	elseif id == 54 then 	--大王
		grade = 17
	else 
		local modResult = id % 13
		if modResult == 1 then -- A
			grade = 14
		elseif modResult == 2 then -- 2
			grade = 15
		elseif modResult >= 3 and modResult < 13 then  -- 3到Q
			grade = modResult
		elseif modResult == 0 then --K
			grade = 13
		end
	end
  	return grade
end 

local AllCards = {}
for i=1,54 do
	AllCards[i] = {
		id = i,
		grade=getgrade(i), 
		suit=getsuit(i),
		display=getdisplay(i),
	}
end

local function sortcards(cards)
	table.sort(cards, function(a,b)
			return AllCards[a].grade > AllCards[b].grade
		end)
end

local function getgrades(cards)
	local t = {}
	for i,v in ipairs(cards) do
		local grade = AllCards[v].grade
		if t[grade] == nil then t[grade] = 0 end
		t[grade] = t[grade] + 1
	end
	return t
end

local function dump(cards) 
	sortcards(cards)
	for i,v in ipairs(cards) do
		print(string.format("花色：%d，牌面：%s, 权重：%d", AllCards[v].suit, AllCards[v].display, AllCards[v].grade))
	end
end

-- local c = {}
-- for i=1,54 do
-- 	table.insert(c, i)
-- end
-- sortcards(c)
-- for i=1,54 do
-- 	print(string.format("id: %d,\t 花色：%d，牌面：%s, 权重：%d",c[i], AllCards[c[i]].suit, AllCards[c[i]].display, AllCards[c[i]].grade))
-- end

--单张
local function isDan(cards) 
	return #cards == 1
end
assert(isDan({33}))
assert(isDan({23,5})==false)

--对子
local function isDuiZi(cards)
	return #cards == 2 
		and AllCards[cards[1]].grade == AllCards[cards[2]].grade
end
assert(isDuiZi({30,43}))
assert(isDuiZi({30,52}) == false)

--大小王炸弹
local function isDuiWang(cards)
	return #cards == 2 and cards[1]+cards[2]==107
end
assert(isDuiWang({53,54}))
assert(isDuiWang({53,52}) == false)

--三张
local function isSan(cards)
	if #cards ~= 3 then return false end
	if AllCards[cards[1]].grade == AllCards[cards[2]].grade
		and AllCards[cards[2]].grade == AllCards[cards[3]].grade 
		then
		return true
	else
		return false
	end
end
assert(isSan({30,43,17})) 	--4 4 4 
assert(isSan({30,43,15}) == false) --4 4 2

--三带一
local function isSanDaiYi(cards)
	if #cards ~= 4 then return false end
	sortcards(cards)
	if AllCards[cards[1]].grade ~= AllCards[cards[2]].grade then
		cards[1], cards[4] = cards[4], cards[1]
	end
	if AllCards[cards[1]].grade == AllCards[cards[2]].grade then
		if AllCards[cards[1]].grade == AllCards[cards[3]].grade
			and AllCards[cards[1]].grade ~= AllCards[cards[4]].grade then 
			return true
		else
			return false
		end
	else
		return false
	end
end
assert(isSanDaiYi({30,43,17,5})) 	--4 4 4 3 
assert(isSanDaiYi({30,43,17,4}) == false) --4 4 4 4


--三带一对
local function isSanDaiDui(cards)
	if #cards ~= 5 then return false end
	sortcards(cards)
	if AllCards[cards[1]].grade ~= AllCards[cards[3]].grade then
		cards[1], cards[4] = cards[4], cards[1]
		cards[2], cards[5] = cards[5], cards[2]
	end
	if AllCards[cards[1]].grade == AllCards[cards[2]].grade then
		if AllCards[cards[1]].grade == AllCards[cards[3]].grade
			and AllCards[cards[1]].grade ~= AllCards[cards[4]].grade  
			and AllCards[cards[4]].grade == AllCards[cards[5]].grade then
			return true
		else
			return false
		end
	else
		return false
	end
end
assert(isSanDaiDui({30,43,17,5,31})) 	-- 4 4 4 5 5
assert(isSanDaiDui({30,43,17,3,31}) == false) 	--4 4 4 5 3

--四张（炸弹）
local function isSi(cards)
	if #cards ~= 4 then return false end
	for i=1,3 do
		if AllCards[cards[i]].grade ~= AllCards[cards[i+1]].grade then
			return false
		end
	end
	return true
end
assert(isSi({30,43,17,4})) -- 4 4 4 4
assert(isSi({30,43,18,4}) == false) -- 4 4 5 4

--四带二
local function isSidaier(cards)
	if #cards ~= 6 then return false end
	local grades = getgrades(cards)
	for k,v in pairs(grades) do
		if v == 4 then return true end
	end
	return false
end
assert(isSidaier({30,43,17,4,3,5})) -- 4 4 4 4 3 5
assert(isSidaier({30,43,17,4,3,16})) -- 4 4 4 4 3 3

--四带两对
local function isSidaierdui(cards)
	if #cards ~= 8 then return false end
	local grades = getgrades(cards)
	local t = false
	for k,v in pairs(grades) do
		if v == 4 then 
			t = true
		elseif v ~= 2 then 
			return false
		end
	end
	return t
end
assert(isSidaierdui({30,43,17,4,3,16,5,18})) -- 4 4 4 4 3 3 5 5
assert(isSidaierdui({30,43,17,4,3,6,5,18}) == false) -- 4 4 4 4 3 6 5 5

--顺子
local function isShunzi(cards)
	if #cards < 5 then return false end
	sortcards(cards)
	if AllCards[cards[1]].grade > 14 then return false end --最大的牌不能超过A
	for i=1,#cards-1 do
		if AllCards[cards[i]].grade ~= AllCards[cards[i+1]].grade+1 then
			return false
		end
	end
	return true
end
assert(isShunzi({35,21,20,6,31,4}))  --9 8 7 6 5 4
assert(isShunzi({21,20,4,31}) == false)  --9 8 7 4 5
assert(isShunzi({35,21,5,6,31}) == false)  --9 8 5 6 5 4

--连对
local function isLiandui(cards)
	if #cards < 6 then return false end
	if #cards%2 == 1 then return false end  
	sortcards(cards)
	if AllCards[cards[1]].grade > 14 then return false end --最大的牌不能超过A
	for i=0,#cards/2-1 do
		if AllCards[cards[i*2+1]].grade ~= AllCards[cards[i*2+2]].grade then
			return false
		end
		if i<#cards/2-1 and AllCards[cards[(i+1)*2]].grade ~= AllCards[cards[(i+2)*2]].grade+1 then
			return false
		end
	end
	return true
end
assert(isLiandui({35,9,21,8,20,7})) -- 9 9 8 8 7 7
assert(isLiandui({35,9,21,8,20,7,6,19})) -- 9 9 8 8 7 7 6 6
assert(isLiandui({35,9,21,8,20,7,33}) == false) -- 9 9 8 8 7 7 7

--飞机(不带)
local function isFeiji(cards)
	if #cards ~= 6 and #cards ~= 9 then return false end
	local grades = getgrades(cards)
	local t, t2
	for k,v in pairs(grades) do
		if v ~= 3 then return false end
		if t == nil then t = k 
		else
			if #cards == 6 then --两头飞机
				return t == k+1 or t == k-1
			elseif #cards == 9 then --三头飞机
				if not t2 then t2 = k
				else
					local arr = {t,t2,k}
					table.sort(arr, function(a,b) return a>b end)
					if arr[1] == arr[2]+1 and arr[2] == arr[3]+1 then 
						return true
					else
						return false
					end
				end
			end
		end
	end
end
assert(isFeiji({35,9,22,21,8,34})) -- 9 9 9 8 8 8
assert(isFeiji({35,9,22,21,8,34,7,20,33})) -- 9 9 9 8 8 8 7 7 7
assert(isFeiji({35,9,22,20,7,33}) == false) -- 9 9 9 7 7 7

--飞机(带单张)
local function isFeiji2(cards)
	if #cards ~= 8 and #cards ~= 12 then return false end
	local grades = getgrades(cards)
	local t1, t2, t3
	for k,v in pairs(grades) do
		if v >= 3 then
			if not t1 then t1 = k 
			elseif not t2 then t2 = k
			elseif not t3 then t3 = k
			end
		end
	end
	if #cards == 8 and t1 and t2 and (t1 == t2+1 or t2==t1+1) then
		return true
	elseif #cards == 12 and t1 and t2 and t3 then
		local arr = {t1,t2,t3}
		table.sort(arr, function(a,b) return a>b end)
		if arr[1] == arr[2]+1 and arr[2] == arr[3]+1 then 
			return true
		else
			return false
		end
	end
	return false
end
assert(isFeiji2({35,9,22,21,8,34,3,4})) -- 9 9 9 8 8 8 3 4
assert(isFeiji2({35,9,22,21,8,34,7,20,33,3,4,5})) -- 9 9 9 8 8 8 3 4 5
assert(isFeiji2({35,9,22,20,7,33,3,4}) == false) -- 9 9 9 7 7 7


--飞机(带对子)
local function isFeiji4(cards)
	if #cards ~= 10 and #cards ~= 15 then return false end
	local grades = getgrades(cards)
	local t1, t2, t3
	for k,v in pairs(grades) do
		if v == 3 then
			if not t1 then t1 = k 
			elseif not t2 then t2 = k
			elseif not t3 then t3 = k
			end
		elseif v ~= 2 then
			return false
		end
	end
	if #cards == 10 and t1 and t2 and (t1 == t2+1 or t2==t1+1) then
		return true
	elseif #cards == 15 and t1 and t2 and t3 then
		local arr = {t1,t2,t3}
		table.sort(arr, function(a,b) return a>b end)
		if arr[1] == arr[2]+1 and arr[2] == arr[3]+1 then 
			return true
		else
			return false
		end
	end
	return false
end
assert(isFeiji4({35,9,22,21,8,34,3,4,16,17})) -- 9 9 9 8 8 8 3 3 4 4 
assert(isFeiji4({35,9,22,21,8,34,7,20,33,3,16,4,17,5,18})) --9 9 9 8 8 8 7 7 7 3 3 4 4 5 5
assert(isFeiji4({35,9,22,21,8,34,3,4,16,18}) == false) -- 9 9 9 8 8 8 3 3 4 5 

local function getCardType(cards) 
	local c = #cards
	if c == 1 then 		--单张
		return cardtype.dan
	elseif c == 2 then 	--两张只可能是王炸或一对
		if isDuiWang(cards) then 
			return cardtype.wangzha
		elseif  isDuiZi(cards) then 
			return cardtype.duizi
		end
	elseif c == 3 then 	--三张只可能是单出三张
		if isSan(cards) then
			return cardtype.san
		end
	elseif c == 4 then 	--四张只可能是炸弹或三带一
		if isSi(cards) then 
			return cardtype.zhadan
		elseif  isSanDaiYi(cards) then 
			return cardtype.sandaiyi
		end
	elseif c == 5 then 	--5张只可能是顺子或三带一对
		if isShunzi(cards) then 
			return cardtype.shunzi
		elseif  isSanDaiDui(cards) then 
			return cardtype.sandaidui
		end
	elseif c == 6 then	--6张可能是顺子、飞机（不带）、四带二、连对
		if isShunzi(cards) then 
			return cardtype.shunzi
		elseif isFeiji(cards) then 
			return cardtype.feiji
		elseif isSidaier(cards) then 
			return cardtype.sidaier
		elseif isLiandui(cards) then
			return cardtype.liandui
		end
	elseif c == 7 or c == 11 then --7或11张只可能是顺子
		if isShunzi(cards) then 
			return cardtype.shunzi
		end
	elseif c == 8 then --8张可能是顺子、连对、飞机（带单）
		if isShunzi(cards) then 
			return cardtype.shunzi
		elseif isFeiji2(cards) then 
			return cardtype.feiji
		elseif isLiandui(cards) then
			return cardtype.liandui
		end
	elseif c == 9 then --9张只可能是顺子、飞机（3头不带）
		if isShunzi(cards) then 
			return cardtype.shunzi
		elseif isFeiji(cards) then 
			return cardtype.feiji
		end
	elseif c == 10 then --10张可能是顺子、飞机(2头带对子)、连对
		if isShunzi(cards) then 
			return cardtype.shunzi
		elseif isFeiji4(cards) then 
			return cardtype.feiji
		elseif isLiandui(cards) then
			return cardtype.liandui
		end
	elseif c == 12 then --12张可能是顺子、飞机(3头带单张)、连对
		if isShunzi(cards) then 
			return cardtype.shunzi
		elseif isFeiji2(cards) then 
			return cardtype.feiji
		elseif isLiandui(cards) then
			return cardtype.liandui
		end
	elseif c == 14 then --14张只可能是连对
		if isLiandui(cards) then
			return cardtype.liandui
		end
	elseif c == 15 then --15张只可能是飞机（3头带对子）
		if isFeiji4(cards) then
			return cardtype.feiji
		end
	end
    return nil  
end
assert(getCardType({54}) == cardtype.dan)
assert(getCardType({54,53}) == cardtype.wangzha)
assert(getCardType({3,3}) == cardtype.duizi)
assert(getCardType({3,3,4,4,5,5}) == cardtype.liandui)
assert(getCardType({3,4,5,6,7}) == cardtype.shunzi)
assert(getCardType({13,3,4,5,6,7,8,9,10,11,12,1}) == cardtype.shunzi)
assert(getCardType({3,3,3,3}) == cardtype.zhadan)
assert(getCardType({3,3,3,3,4,4,4,4}) == cardtype.feiji)
assert(getCardType({3,4,5,6,7,8,9}) == cardtype.shunzi)
assert(getCardType({3,3,3,4,4,4,5,5,5}) == cardtype.feiji)
assert(getCardType({3,3,3,1,4,4,4,2,5,5,5,7}) == cardtype.feiji)
assert(getCardType({3,3,3,1,1,4,4,4,2,2,5,5,5,7,7}) == cardtype.feiji)
assert(getCardType({3,3,4,4,2,2}) == nil)
assert(getCardType({3,3,3,4,2}) == nil)
assert(getCardType({3,3,3,4,4,4,2}) == nil)
assert(getCardType({2,3,4,5,6}) == nil)
assert(getCardType({3,4,5,6,7,7}) == nil)
---------------------------------------------
local rule = {}

rule.gettype = getCardType
rule.sortcards = sortcards

function rule.getcarddetail(card)
	return AllCards[card]
end

function rule.getsortedcarddetails(cards)
	sortcards(cards)
	local carddetails = {}
	for i,v in ipairs(cards) do
		carddetails[i] = rule.getcarddetail(v)
	end
	return carddetails
end

function rule.checkcards(precards, curcards)
	local ct = getCardType(curcards)
	if ct == nil then
		print("错误：不成牌型！不能出！")
		return false
	end
	if precards == nil then
		return true
	else
		local prect = getCardType(precards)
		if ct == cardtype.wangzha then
			return true
		elseif ct == cardtype.zhadan then --出炸弹
			if prect == cardtype.wangzha then
				print("错误：不可能比王炸还大！")
				return false
			elseif prect == cardtype.zhadan then
				if AllCards[precards[1]].grade < AllCards[curcards[1]].grade then
					return true
				else
					print("错误：炸弹不如上家大！")
					return false
				end
			else
				return true
			end
		elseif prect ~= ct then
			print("错误：牌型和上家不一样！")
			return false
		elseif #precards ~= #curcards then
			print("错误：牌型相同，但牌数不同，不能出牌！")
			return false
		else
			sortcards(precards)
			sortcards(curcards)
			if AllCards[precards[1]].grade < AllCards[curcards[1]].grade then
				return true
			else
				print("错误：牌面不如上家大！")
				return false
			end
		end
	end
end
return rule