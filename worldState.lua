-- world


world = World.new()

cursor = Pixel.new(0x550000, 0.9, 24, 24)
cursor0 = Pixel.new(0x005500, 0.9, 24, 24)
cursor1 = Pixel.new(0x000055, 0.3, 24, 24)
cursor1:setRotation(25)
local zcursor = 10
local zText = TextField.new(nil, "some text")
local xcursor, ycursor = 0, 0
cursor:setAnchorPosition(12, 12, 0)
cursor:addChild(zText)
cursor0:setAnchorPosition(12, 12, 0)
cursor1:setAnchorPosition(12, 12, 0)
world:addChild(cursor)
world:addChild(cursor0)
world:addChild(cursor1)
-- world.background:addChild(cursor)
local nn = 1
local xm, ym;

function correctPerspective(xx, yy, zz)
	local xc, yc = application:getLogicalWidth() / 2, application:getLogicalHeight() / 2
	local xd, yd = xx - xc, yy - yc
    -- local d = math.sqrt(math.pow(xd, 2) + math.pow(yd, 2))
	-- d = d * zz / 100
	local d = 1 ; -- 1000 / zz -- (-zz ) / 100
	-- print("zz", zz, "d", d)
	return xc + d * xd, yc + d * yd
end

function projectMouse()
	if xm == nil then return end
	
	local z0, z1 = -500, 300
	local n = 20
	local x, y, z
	local xx, yy, zz
	-- local invertWorld = world:getMatrix()
	-- invertWorld:invert()
	-- local invertProjection = zoomArea:getMatrix()
	-- invertProjection:perspectiveProjection(30,1,1,10000000)
	-- invertProjection:translate(-application:getLogicalWidth(),-application:getLogicalHeight())
	-- invertProjection:setScale(application:getLogicalWidth()/2)
	-- invertProjection:invert()
	
	xx, yy, zz = xm, ym, z0
	-- xx, yy, zz = stage:globalToLocal(xx, yy, zz)
	-- xx, yy, zz = xx / zz, yy / zz, zz
    --xx, yy, zz = zoomArea:globalToLocal(xx, yy, zz)
	-- print(xx, yy, zz)
	-- xx, yy = invertProjection:transformPoint(xx, yy, zz)
	-- print(xx, yy, zz)
	xx, yy = correctPerspective(xx, yy, zz)
	xx, yy, zz = world:globalToLocal(xx, yy, zz)
	-- xx, yy, zz = zoomArea:globalToLocal(xx, yy, zz)
	-- xx, yy, zz = invertWorld:transformPoint(xx, yy, zz)
    -- xx, yy, zz = world.background:globalToLocal(xx, yy, zz)
	local xc0, yc0, zc0 = xx, yy, zz
	cursor0:setPosition(xc0, yc0, zc0)
	
	
	xx, yy, zz = xm, ym, z1
	-- xx, yy, zz = stage:globalToLocal(xx, yy, zz)
    -- xx, yy, zz = xx / zz, yy / zz, zz
	--xx, yy, zz = zoomArea:globalToLocal(xx, yy, zz)
	-- xx, yy = invertProjection:transformPoint(xx, yy)
	xx, yy = correctPerspective(xx, yy, zz)
	xx, yy, zz = world:globalToLocal(xx, yy, zz)
	-- xx, yy, zz = zoomArea:globalToLocal(xx, yy, zz)
	-- xx, yy, zz =invertWorld:transformPoint(xx, yy, zz)
	-- xx, yy, zz = world.background:globalToLocal(xx, yy, zz)
	local xc1, yc1, zc1 = xx, yy, zz
	cursor1:setPosition(xc1, yc1, zc1)
	
	while true do
		n = n - 1
		zm = (z1 + z0) / 2
		xx, yy, zz = xm, ym, zm
		-- xx, yy, zz = stage:globalToLocal(xx, yy, zz)
		-- xx, yy, zz = xx / zz, yy / zz, zz
		--xx, yy, zz = zoomArea:globalToLocal(xx, yy, zz)
		-- xx, yy = invertProjection:transformPoint(xx, yy, zz)
		xx, yy = correctPerspective(xx, yy, zz)
		xx, yy, zz = world:globalToLocal(xx, yy, zz)
		-- xx, yy, zz = zoomArea:globalToLocal(xx, yy, zz)
		-- xx, yy, zz = invertWorld:transformPoint(xx, yy, zz)
		-- xx, yy, zz = world.background:globalToLocal(xx, yy, zz)
		x, y, z = xx, yy, zz
		if n == 0 or math.abs(zz - zcursor) < 5 then break end
		if zz > zcursor and z1 >= zz  then
			z1 = zm
		else
			z0 = zm
		end
		break
	end
	
	-- local x2, y2 = world:globalToLocal(x, y)
	-- print("nn", nn, "n", n, "zm", zm, "z", z, "z0", z0, "z1", z1)
	-- local x, y, z = world.background:globalToLocal(e.x, e.y, zm)
	xcursor, ycursor = x, y
	cursor:setPosition(xcursor, ycursor, zcursor)
	zText:setText(z)
end
	
stage:addEventListener(Event.MOUSE_HOVER, function(e)
	xm, ym = e.x, e.y;
end)


while world.n < 81 do
	local x, y, n = world:setNextChunck()
	world:openChunck({
		type = "regular",
		x = x,
		y = y
	})
end

game.State.WORLD ={
	name = "WORLD",
	scene = world,
	enter = function(self, lastState)
		game:setScene(world)
		if lastState == game.State.OVERFLY then
			world:unfocus()
		else
			-- world:getParent():setScale(0.3)
		end
		stage:addEventListener(Event.TOUCHES_END, World.touch, world)
	end,
	leave = function(self)
		stage:removeEventListener(Event.TOUCHES_END, World.touch, world)
	end,
	animate = function(self)
		nn = (nn + 1) % 10
		projectMouse()
		world:resumeGeneration()
	end
}
