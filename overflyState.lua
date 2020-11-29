-- chunck overfly scene
local overflyScene = Mesh.new(true)
local animal = Box.new(2, 2, 4, Shape.SOLID, 0xFF7777, Shape.SOLID, 0x000000, Shape.SOLID, 0xFFFFFF)
animal:setRotationX(180)

local card3d
if false then
for fi = 0, 12 do
	local fog = Pixel.new(0x264040, 1 / (3 + fi / 4), 5000, 5000)
	fog:setAnchorPoint(0.5, 0.5, 0)
	fog:setRotation(fi * 20)
	fog:setZ(30 + fi * 15)
	fog:setPosition(0, 0)
	fog:setBlendMode(Sprite.ADD)
	overflyScene:addChild(fog)
end
end

animal.touch = function(self, event)
	local x, y = event.touch.x, event.touch.y
	print('animal ?', x, y)
	if self:hitTestPoint(x, y, false) then
		print('animal touched', x, y)
		self.touched = true
	end
end

-- overflyScene:setRotationX(40)
-- overflyScene:setAnchorPoint(0, 0, 0)
-- overflyScene:setScale(1.2, 1.2, 1.2)
	
game.State.OVERFLY = {
	name = "OVERFLY",
	enter = function(self)
		local world = game.State.WORLD.scene
		local card = world.focusCard
		
		overflyScene:setRotationX(world:getRotationX())
		overflyScene:setScale(world:getScale())
		overflyScene:setX(world:getX())
		overflyScene:setY(world:getY())
		overflyScene:setZ(world:getZ())

		self.d = 7000
		game:setScene(overflyScene)
		
		-- overflyButton:setRotation(40)
		print(world:getZoom())	
		overflyScene:resetZoom(world:getZoom())
		for i = overflyScene:getNumChildren(), 1, -1 do
			overflyScene:removeChildAt(i)
		end
		animal.touched = false
		animal.elevation = card.chunck:getElevation(CHUNCK_SIZE * 0.5, CHUNCK_SIZE * 0.5) / 10;
		animal:setPosition(CHUNCK_SIZE * 0.5, CHUNCK_SIZE * 0.5, animal.elevation - 5)
		animal:setShader(fogShader)
		animal:addEventListener(Event.TOUCHES_END, animal.touch, animal)

		card3d = card.chunck:get3DMapMesh()
		card3d:setScale(card:getScale())
		card3d:setPosition(card:getPosition())
		-- card3d:setRotationX(card:getRotationX())
		-- card3d:setRotationY(card:getRotationY())
		-- card3d:setRotation(card:getRotation())

		overflyScene:addChild(card3d)
		card3d:addChild(animal)
		card3d:setShader(fogShader)

		overflyButton:setAlpha(1)	
	end,
	leave = function(self)
		animal:removeEventListener(Event.TOUCHES_END, animal.touch, animal)

		-- overflyButton:setRotation(0)
		overflyButton:setAlpha(0.4)	
	end,
	animate = function(self, iteration)
		self.d = 7000 * math.max(0, 1 - (iteration / 100.0))
		-- print(self.d)
		local sc = math.min(4, 0.1 + card3d:getScaleX())
		card3d:setScale(sc, sc, sc)
		card3d:setRotationX(math.min(card3d:getRotationX() + 1, math.min(iteration, 40)))
		card3d:setRotation(-math.sin(iteration / 200) * 200)
		
		-- animal:setRotationX(-math.sin(iteration / 200) * 200)
		-- animal:setRotationY(-math.sin(iteration / 100) * 200)
		animal:setRotation(-math.sin(iteration / 100) * 200)
		if animal.touched then
			animal.elevation = animal.elevation < 10000 and animal.elevation + (1 + math.log(animal.elevation)) or 10000
			animal:setZ(animal.elevation)
		elseif iteration < 180 or iteration % 180 < 60 then 
			if iteration % 180 == 0 then
				local xa, ya = math.random(CHUNCK_SIZE - 1), math.random(CHUNCK_SIZE - 1)
				animal.elevation = world.focusCard.chunck:getElevation(xa, ya) / 10
				animal:setPosition(xa, ya, animal.elevation - 5)
			end
			animal:setZ(-2000)
		else
			animal:setZ(animal.elevation - 5 + math.abs(math.sin(math.pi * iteration / 60)) * 10)
		end
		-- local ap = 0.1 + math.sin(iteration / 80)*0.2
		-- overflyScene:setZ(ap * CHUNCK_SIZE * 20)
	end
}

