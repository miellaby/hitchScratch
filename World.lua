World = Core.class(Sprite)
	
function World:init(...)
	--  print(self)
	self.chunckIndex = {} -- index x-y des chuncks
	self.n = 0 -- nombre de chuncks déja créé
	self.edgeLength = 1 -- largeur coté carré carte
	self.chuncks = {} -- chuncks
	self.cards = {} -- cards
	self.toBeGenerated = {} -- chuncks en cours de génération
	self.coBuildChunck = nil -- coroutine génération des chuncks

	self:setAnchorPosition((CHUNCK_SIZE + CHUNCK_MARGIN) * 9 / 2, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9 / 2)
	-- self:setAnchorPoint(0.5, 0.5)
	
	-- fond du monde (visible quand on retourne les cases)
	self.background = Pixel.new(0x446644, 1, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5)
	self.background:setPosition((CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5 / 2, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5 / 2)
	self.background:setAnchorPosition((CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5 / 2, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5 / 2)
	self:addChild(self.background)
	
	-- conteneur des cases
	self.fullMap = Sprite.new()
	self.fullMap:setPosition((CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5 / 2, (CHUNCK_SIZE + CHUNCK_MARGIN) * 9.5 / 2)
	self:addChild(self.fullMap)
	
	-- open first chunck
	self:setNextChunck()
	self:openChunck({ type="home" })
	
	self:setRotationX(OVERVIEW_ANGLE)
	-- local m = Matrix.new()
	-- m:setRotationX(OVERVIEW_ANGLE)
	-- self:setMatrix(m)
	

end

function World:setNextChunck()
	local x, y
	local n, l = self.n, self.edgeLength
	if n == 0 then
	    n, x, y, l = 1, 0, 0, 1
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
	chunck:getBack():setZ(0)
	local card = FlippingCard:new(true, chunck, false)
	card:setPosition(chunck.x * (CHUNCK_SIZE + CHUNCK_MARGIN), chunck.y * (CHUNCK_SIZE + CHUNCK_MARGIN))
	table.insert(self.cards, card)
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
	newBack:setZ(1)
	newBack:setPosition(newChunck.x * (CHUNCK_SIZE + CHUNCK_MARGIN), newChunck.y * (CHUNCK_SIZE + CHUNCK_MARGIN))
	self.fullMap:addChild(newBack)

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

function World:doFocusing()
	local p = self:getParent()
	if not p then return end
	local sc = p:getScaleX()
	local stillWork = false;
	
	if self.focusCard then
		if sc <= 0.86 then
			p:setScale(sc + 0.04, sc + 0.04, sc + 0.04)
			stillWork = true
		end
		if self:getRotationX() > 0 then
			self:setRotationX(self:getRotationX() - 2)
			stillWork = true
		end
		
		local cx, cy = self.focusCard:getPosition()
		local ax, ay = self:getAnchorPosition()
		print("z z cx cy ax ay", self:getScaleX(), p:getScaleX(), cx, cy, ax, ay)
		local pi = Pixel.new(0x264040, 1, 10, 10);
		pi:setPosition(cx, cy)
		self.fullMap:addChild(pi);
		-- self:zoomTo(-cx / p:getScaleX(), -cy / p:getScaleX())
		-- self:zoomTo(-cx * self:getScaleX() / p:getScaleX(), -cy * self:getScaleX() / p:getScaleX())
		self:zoomTo(-cx * self:getScaleX(), -cy * self:getScaleX())
	else
		if sc > 0.3 then
			p:setScale(sc - 0.04, sc - 0.04, sc - 0.04)
			stillWork = true
		end
		if self:getRotationX() < OVERVIEW_ANGLE then
			self:setRotationX(self:getRotationX() + 2)
			stillWork = true
		end
	end
	_ = stillWork or self:removeEventListener(Event.ENTER_FRAME, self.doFocusing, self)
end

function World:unfocus(card)
	self.focusCard = nil
	self:addEventListener(Event.ENTER_FRAME, self.doFocusing, self)
	overflyButton:removeFromParent();
end

function World:focus(card)
	self.focusCard = card
	stage:addChild(overflyButton);
	self:addEventListener(Event.ENTER_FRAME, self.doFocusing, self)
end


function World:touchCard(event)
	if not self:isVisible() then
		return
	end
	
	local touch = event.touch
	for _, card in pairs(self.cards) do
		if card:hitTestPoint(touch.x, touch.y, true) then
			local lastCard = self.focusCard
			if card.up and not card.goingUp or not card.up and card.goingUp then
				self:unfocus()
			else
				self:focus(card)
				card:flip()
			end
			card:goUp()
			if lastCard and lastCard ~= card and (lastCard.up and not lastCard.goingUp or not lastCard.up and lastCard.goingUp) then
				lastCard:goUp()
			end
		end
	end
end
