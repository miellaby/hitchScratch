
local iDemo, ln, iteration, j = 0, 1, 0, 1
local currentDemo, demoSprite, chunck
local demos = {
	{
		name = 'procgen',
		init = function()
			local map = {}
			local min = procgen(map, 128, 0, 0, 128, 128, math.random(140,160), math.random(140,160), math.random(140,160), math.random(140,160))
			
			-- pour être sur qu'il y au moins un point à 80
			start = math.random(0,128*128-1)
			map[start] = map[start] < 80 and 80 or map[start]
		   
			print("draw", min)
			return drawgen(map, 128, 128, { water = 30, sand = 40 })
		end,
		iteration = nil
	},
	{
		name = 'procgen_2layers',
		init = function()
			local green, level = {}, {}
			local min = procgen(green, 128, 0, 0, 128, 128, math.random(140,160), math.random(140,160), math.random(140,160), math.random(140,160))
			local min2 = procgen(level, 128, 0, 0, 128, 128, math.random(96,120), math.random(96,160), math.random(96,120), math.random(96,160))
			return draw2gen(green, level, 128, 128, { water = 30, sand = 40 })
		end,
		iteration = nil
	},
	{
		name = 'procgen_2',
		init = function()
			local map = {}
			procgen_2(map, 128, 0, 0, 128, 128, nil, nil, nil, nil, nil)
			return drawgen(map, 128, 128, { water = 30, sand = 40 })
		end,
		iteration = nil
	},
	{
		name = 'nothing',
		init = function()
			return Sprite.new()
		end,
		iteration = nil
	}
}

stage:addEventListener(Event.ENTER_FRAME, function()
	iteration = iteration + 1
	_ = currentDemo and currentDemo.iteration and currentDemo.iteration()
end)

stage:addEventListener(Event.KEY_UP, function(event)

   if event.keyCode == KeyCode.BACK then application:exit() end
   if event.keyCode == 32 then 
	    _ = demoSprite and demoSprite:removeFromParent()
		iDemo = iDemo + 1
	    currentDemo = demos[iDemo]
	    if currentDemo == nil then iDemo = 1; currentDemo = demos[1]; end
		print("new demo", currentDemo.name)
		demoSprite = currentDemo.init()
		debugScene:addChildAt(demoSprite, 1)
		if currentDemo.name == 'nothing' then
			game:setState(game.State.WORLD)
		else
			game:setState(game.State.DEBUG)
		end
	end
end)
