application:configureFrustum(30)
application:setBackgroundColor(0x00DDFF)


local iDemo, demos = 1, { 'show3d', 'chunck', 'procgen_2layers', 'procgen' }
local demo = demos[iDemo]
local ln, iteration, j = 1, 0, 1
local demoSprite, scene, chunck
-- démo avec zoom
local zoomArea = Mesh.new(true)
zoomArea:setScale(0.3)
stage:addChild(zoomArea)
world:setScale(2,2,2)
world:setAnchorPoint(0.5, 0.5)
zoomArea:setPosition(application:getContentWidth() / 2, application:getContentHeight() / 2)
if false then
for fi = 0, 8 do
	local fog = Pixel.new(0xDDFFFF, 0.1 + 0.05 * fi, 50000, 50000)
	fog:setAnchorPoint(0.5, 0.5)
	fog:setRotationX(12)
	-- fog:setRotationX(90)
	fog:setZ(600 - fi * 110)
	-- fog:setRotation(fi * 20)
	fog:setPosition(0, 0)
	--fog:setBlendMode(Sprite.SCREEN) -- Sprite.ADD)
	zoomArea:addChildAt(fog,1)
end
end

local chunck
local initDemo = {
	chunck = function() 
		scene = world
		while world.n < 81 do
			local x, y, n = world:setNextChunck()
			world:openChunck({
				type = "regular",
				x = x,
				y = y
			})
		end
	end,
	procgen = function()
		print("procgen")
		local map = {}
		local min = procgen(map, 128, 0, 0, 128, 128, math.random(140,160), math.random(140,160), math.random(140,160), math.random(140,160))
		
		-- pour être sur qu'il y au moins un point à 80
		start = math.random(0,128*128-1)
		map[start] = map[start] < 80 and 80 or map[start]
	   
		print("draw", min)
		scene = drawgen(map, 128, 128, { water = 30, sand = 40 })
	end,
	show3d = function()
	    _ = scene and scene:getNumChildren() > 0 and scene:removeChildAt(1)
		if not scene then
			scene = Mesh.new(true)
			for fi = 0, 12 do
				local fog = Pixel.new(0x264040, 1 / (3 + fi / 4), 5000, 5000)
				fog:setAnchorPoint(0.5, 0.5, 0)
				fog:setRotation(fi * 20)
				fog:setZ(30 + fi * 15)
				fog:setPosition(0, 0)
				fog:setBlendMode(Sprite.ADD)
				scene:addChild(fog)
			end
			scene:setRotationX(40)

			-- scene = mesh
			scene:setAnchorPoint(0, 0, 0)
			scene:setScale(1.3,1.3,1.3)
		end
		chunck = Chunck.new({})
		chunck:generate()
		local mesh = chunck:get3DMapMesh();
		
		-- mesh:setRotationX(66)
		scene:addChildAt(mesh, 1)
		
		
	end,
	procgen_2layers = function()
		print("procgen 2 layers")
		-- print("proc")
		local green, level = {}, {}
		local min = procgen(green, 128, 0, 0, 128, 128, math.random(140,160), math.random(140,160), math.random(140,160), math.random(140,160))
		local min2 = procgen(level, 128, 0, 0, 128, 128, math.random(96,120), math.random(96,160), math.random(96,120), math.random(96,160))
		scene = draw2gen(green, level, 128, 128, { water = 30, sand = 40 })
	end,
	procgen_2 = function()
		print("procgen_2")

		-- procgen_2(t, l, x0, y0, x3, y3, average, up, right, bottom, left)
		local map = {}
		procgen_2(map, 128, 0, 0, 128, 128, nil, nil, nil, nil, nil)
		scene = drawgen(map, 128, 128, { water = 30, sand = 40 })
	end,
	nothing = function()
		print("nothing")
	end
}

stage:addEventListener(Event.ENTER_FRAME, function()
	iteration = iteration + 1
	
	local fn = {
		chunck = function() 
		end,
	    procgen = function()
		end,
		show3d = function()
			scene:setAnchorPosition(0, 0)
			scene:setRotation(-math.sin(iteration / 200) * 200 + 12)
			local ap = 0.1 + math.sin(iteration / 80)*0.2
			-- scene:setY(300)

			-- scene:setZ(ap * CHUNCK_SIZE * 20)
		end,
	    procgen_2layers = function()
		end,
		procgen_2 = function()
		end,
		nothing = function()
			print("nothing")
		end
	}
	fn[demo]()
		
end)

stage:addEventListener(Event.KEY_UP, function(event)

   if event.keyCode == KeyCode.BACK then application:exit() end
   if event.keyCode == KeyCode.N or event.keyCode == KeyCode.SELECT then initDemo[demo]() end
   if event.keyCode == 32 then 
	   _ = demoSprite and demoSprite:removeFromParent()
	   demoSprite = nil
	   iDemo = iDemo + 1
	   demo = demos[iDemo]
	   if demo == nil then iDemo = 1; demo = demos[1]; end
		_ = scene and zoomArea:removeChild(scene)
		scene = nil
		initDemo[demo]()
		-- scene:setAnchorPoint(0, 0, 0)
		zoomArea:addChildAt(scene,1)
		-- zoomArea:setAnchorPoint(0, 0, 0)
		attachZoom(scene, 0.2, 1.5)
	end
end)

initDemo[demo]()
zoomArea:addChild(scene)
attachZoom(scene, 0.2, 0.5)
