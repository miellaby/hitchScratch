application:configureFrustum(25)


local iDemo, demos = 1, { 'chunck', 'procgen_2layers', 'procgen' }
local demo = demos[iDemo]
local ln, i, j = 1, 0, 1
local demoSprite
-- démo avec zoom
application:setBackgroundColor(0)
local zoomArea = Sprite.new()
zoomArea:setScale(0.5)
world:setScale(2)
attachZoom(world, 0.2, 0.5)
zoomArea:setPosition(application:getContentWidth() / 2, application:getContentHeight() / 2)
-- zoomArea:setAnchorPoint(0.5, 0.5)
--   -application:getLogicalWidth() / 2,
--   -application:getLogicalHeight() / 2)


stage:addEventListener(Event.KEY_UP, function(event)
   if event.keyCode == 17 then return end
   iDemo = iDemo + 1
   demo = demos[iDemo]
   _ = demoSprite and demoSprite:removeFromParent()
   if demo == nil then iDemo = 1; demo = demos[1]; end
end)

stage:addEventListener(Event.ENTER_FRAME, function()
	i = i + 1

	local fn = {
		chunck = function() 
			if i % 5 == 1  and world.n < 81 then
				local x, y, n = world:setNextChunck()
				world:openChunck({
					type = "regular",
					x = x,
					y = y
				})
			end
			zoomArea:addChild(world)
			stage:addChild(zoomArea)
			-- world:setRotation(i / 100)
			demoSprite = zoomArea
		end,
	    procgen = function()
			if i % 60 == 0 then
				print("procgen")
				local map = {}
			    local min = procgen(map, 128, 0, 0, 128, 128, math.random(140,160), math.random(140,160), math.random(140,160), math.random(140,160))
			    
			    -- pour être sur qu'il y au moins un point à 80
			    start = math.random(0,128*128-1)
			    map[start] = map[start] < 80 and 80 or map[start]
			   
			    print("draw", min)
			    demoSprite = drawgen(map, 128, 128, { water = 30, sand = 40 })
				stage:addChild(demoSprite)
			    demoSprite:setAnchorPoint(0.5, 0.5)
				demoSprite:setPosition(
					application:getDeviceWidth() / 2,
					application:getDeviceHeight() / 2)
			end
		end,
	    procgen_2layers = function()
			if i % 60 == 0 then
				print("procgen 2 layers")
			    -- print("proc")
				local map, density = {}, {}
			    local min = procgen(map, 128, 0, 0, 128, 128, math.random(140,160), math.random(140,160), math.random(140,160), math.random(140,160))
			    local min2 = procgen(density, 128, 0, 0, 128, 128, math.random(96,120), math.random(96,160), math.random(96,120), math.random(96,160))
			  
			    -- pour être sur qu'il y au moins un point à 80
			    start = math.random(0,128*128-1)
			    map[start] = map[start] < 80 and 80 or map[start]
			   
			    print("draw", min)
			    demoSprite = draw2gen(map, density, 128, 128, { water = 30, sand = 40 })
			    stage:addChild(demoSprite)
			    
				demoSprite:setAnchorPoint(0.5, 0.5)
				demoSprite:setPosition(
					application:getDeviceWidth() / 2,
					application:getDeviceHeight() / 2)
			end
		end,
		procgen_2 = function()
			if i % 6 == 1 then
				print("procgen_2")

			    -- procgen_2(t, l, x0, y0, x3, y3, average, up, right, bottom, left)
				local map = {}
			    procgen_2(map, 128, 0, 0, 128, 128, nil, nil, nil, nil, nil)
			    start = math.random(0,128*128-1)
			    map[start] = map[start] < 80 and 80 or map[start]
			   
			    demoSprite = drawgen(map, 128, 128, { water = 30, sand = 40 })
				stage:addChild(demoSprite)
				demoSprite:setAnchorPoint(0.5, 0.5)
				demoSprite:setPosition(
					application:getDeviceWidth() / 2,
					application:getDeviceHeight() / 2)
			end
		end,
		nothing = function()
			print("nothing")
		end
	}
	fn[demo]()
		
end)
