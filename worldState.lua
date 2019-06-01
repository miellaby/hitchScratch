-- world


world = World.new()

cursor = Pixel.new(0x550000, 0.5, 25, 25)
cursor0 = Pixel.new(0x555500, 0.5, 25, 25)
cursor1 = Pixel.new(0x550055, 0.5, 25, 25)
local zcursor = 10
local zText = TextField.new(nil, "some text")
local xcursor, ycursor = 0, 0
cursor:addChild(zText)	
cursor:setAnchorPosition(0.5, 0.5, 0.5)
cursor0:setAnchorPosition(0.5, 0.5, 0.5)
cursor1:setAnchorPosition(0.5, 0.5, 0.5)
world:addChild(cursor)
world:addChild(cursor0)
world:addChild(cursor1)
-- world.background:addChild(cursor)
local nn = 1
local xm, ym;

function projectMouse()
	if xm == nil then return end
	
	local z0, z1 = -1000, 1000
	local n = 20
	local x, y, z
	local xc1, yc1, zc1 = world:globalToLocal(xm, ym, z0)
	local xc0, yc0, zc0 = world:globalToLocal(xm, ym, z1)
	while true do
		n = n - 1
		zm = (z1 + z0) / 2
		x, y, z = world:globalToLocal(xm, ym, zm)
		if n == 0 or math.abs(z - zcursor) < 5 then break end
		if z > zcursor then
			z1 = zm
		else
			z0 = zm
		end
	end
	
	-- local x2, y2 = world:globalToLocal(x, y)
	-- print("nn", nn, "n", n, "zm", zm, "z", z, "z0", z0, "z1", z1)
	-- local x, y, z = world.background:globalToLocal(e.x, e.y, zm)
	xcursor, ycursor = x, y
	cursor0:setPosition(xc0, yc0, zc0)
	cursor1:setPosition(xc1, yc1, zc1)
	cursor:setPosition(xcursor, ycursor, zcursor)
	zText:setText(z)
end
	
stage:addEventListener(Event.MOUSE_HOVER, function(e)
	xm, ym = e.x, e.y;
end)

stage:addEventListener(Event.TOUCHES_END, World.touchCard, world)

stage:addEventListener(Event.ENTER_FRAME, function()
	nn = (nn + 1) % 10
	projectMouse()
	world:resumeGeneration()
end)

world:setScale(2,2,2)
world:setAnchorPoint(0.5, 0.5)

while world.n < 81 do
	local x, y, n = world:setNextChunck()
	world:openChunck({
		type = "regular",
		x = x,
		y = y
	})
end

gameStates.world ={
	name = "world",
	before = nil,
	after = nil,
	iterate = nil,
	scene = world
}
