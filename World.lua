World = Core.class(Sprite)
local CHUNCK_MARGIN = 14


function World:init(...)
	--  print(self)
	self.chunckIndex = {} -- index x-y des chuncks
	self.n = 0 -- nombre de chuncks déja créé
	self.edgeLength = 1 -- largeur coté carré carte
	self.chuncks = {} -- chuncks déja créé
	self.toBeGenerated = {} -- chuncks en cours de génération
	self.coBuildChunck = nil -- coroutine génération des chuncks
	-- fond du monde (visible quand on retourne les cases)
	self.background = Pixel.new(0, 1, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9)
	self.fullMap = Sprite.new() -- conteneur des cases
	self:addChild(self.background)
	self:addChild(self.fullMap)
	-- self:setAnchorPoint(0.5, 0.5)
	self:setNextChunck()
	self:openChunck({ type="home", x=self.nextX, y=self.nextY })
	self.nextX, self.nextY = nil, nil
end

function World:setNextChunck()
	local x, y
	local l, n = self.edgeLength, self.n
	if n == 0 then
	    l, x, y, n = 1, 0, 0, 1
	else
		n = n + 1
		if n > l * l then -- élargissement du carré-carte
			l = l + 2
		end
		
		local offset = n - (l - 2) * (l - 2) - 1
		local side = math.floor(offset / (l - 1))			
		local sideOffset = offset % (l - 1)
		if side == 0 then
			x, y = (l - 1) / 2,  -(l - 1) / 2 + sideOffset
		elseif side == 1 then
			x, y = (l - 1) / 2 - sideOffset, (l - 1) / 2
		elseif side == 2 then
			x, y = -(l - 1) / 2, (l - 1) / 2 - sideOffset
		else
			x, y = -(l - 1) / 2 + sideOffset, -(l - 1) / 2
		end
		-- print("n", n, x, y)
	end
	-- print(x, y, n, l)
	self.n, self.nextX, self.nextY, self.edgeLength = n, x, y, l
	return x, y, n
end

function World:turnChunckIntoCard(chunck)
	local card = FlippingCard:new(true, chunck, false)
	card:setPosition(chunck.x * (CHUNCK_SIZE + CHUNCK_MARGIN), chunck.y * (CHUNCK_SIZE + CHUNCK_MARGIN))
	card:addEventListener(Event.TOUCHES_END, card.touchFlip, card)
	self.fullMap:addChild(card)
end


function World:openChunck(def)
	def.world = self
	def.type = def.type or "regular"
	if def.x == nil then def.x = self.nextX end
	if def.y == nil then def.y = self.nextY end
	local newChunck = Chunck.new(def)
	local newBack = newChunck:getBack()
	newBack:setAnchorPoint(0.5, 0.5)
	newBack:setZ(0)
	newBack:setPosition(newChunck.x * (CHUNCK_SIZE + CHUNCK_MARGIN), newChunck.y * (CHUNCK_SIZE + CHUNCK_MARGIN))
	self.background:addChild(newBack)
	
	table.insert(self.chuncks, newChunck)
	table.insert(self.toBeGenerated, newChunck)
	if self.coBuildChunck == nil then
  	    self.coBuildChunck = coroutine.create(function()
			local oneChunck = self.toBeGenerated[1]
			while oneChunck ~= nil do
				-- print("there", table.getn(self.toBeGenerated), oneChunck and oneChunck.name)
				local map2d = oneChunck:getMap()
				-- print(oneChunck.x * CHUNCK_SIZE, oneChunck.y * CHUNCK_SIZE)
				map2d:setAnchorPoint(0.5, 0.5)
				oneChunck:getBack():removeFromParent()
				self:turnChunckIntoCard(oneChunck)
				
				-- self.fullMap:addChild(map2d)
				-- map2d:setPosition(oneChunck.x * (CHUNCK_SIZE + CHUNCK_MARGIN), oneChunck.y * (CHUNCK_SIZE + CHUNCK_MARGIN))
				-- print("done", oneChunck.x, oneChunck.y)
				table.remove(self.toBeGenerated, 1)
				-- print("x")
				oneChunck = self.toBeGenerated[1]
				-- print("xx", oneChunck and oneChunck.name)
			end
			-- print("build done")
			self.coBuildChunck = nil
	    end)
	end
		
end


function World:resumeGeneration()
	if not self.coBuildChunck then return end
	local status = coroutine.status(self.coBuildChunck)
	if status == "dead" then
		self.coBuildChunck = nil
	-- print("dead")
	elseif status == "suspended" then
		 local ok, stuff = coroutine.resume(self.coBuildChunck)
		 _ = not ok and print(stuff)
	end
end

world = World.new()

stage:addEventListener(Event.ENTER_FRAME, function()
	world:resumeGeneration()
end)