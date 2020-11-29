-- a chunck is a part of a map
-- it's a square of CHUNCK_SIZExCHUNCK_SIZE cells

-- Chunck Class
Chunck = Core.class()
Chunck.newIndice = 0



-- render a chunck backside mesh
local function renderBackside()
	local mesh = chunckMeshes.map2d
	local i, j = 1, 1
	local map = {}
	for i = 1, CHUNCK_SIZE * CHUNCK_SIZE do
		local color = math.ceil((i * i) >> 10 + (i * i) >> 6) % 16
		map[i] = 0xFFFFAA - (color << 10 + color << 20)
		-- print(map[i])
	end
	i = 1
	for y = 0, CHUNCK_SIZE - 1 do
        local color
		for x = 0, CHUNCK_SIZE - 1 do
			color = map[i]
			mesh:setColors(j, color, 1)
			i = i + 1
			j = j + 1
		end
		mesh:setColors(j, color, 1)
		j = j + 1
	end
	for x = 0, CHUNCK_SIZE do
		local color = map[CHUNCK_SIZE * CHUNCK_SIZE - CHUNCK_SIZE + x]
		mesh:setColors(j, color, 1)
		j = j + 1
	end
	-- print("Chunck:get2DMapMesh", self.name, i, "done")
	local rt= RenderTarget.new(CHUNCK_SIZE, CHUNCK_SIZE)
	rt:draw(Pixel.new(0xAAFFAA, CHUNCK_SIZE, CHUNCK_SIZE))
	local sprite = Sprite.new()
	sprite:setScale((CHUNCK_SIZE - 10) / CHUNCK_SIZE)
	sprite:addChild(mesh)
	rt:draw(sprite, 5, 5)
	return rt
end

-- chunck backside Sprite
local backside = renderBackside()



function Chunck:init(...)
	Chunck.newIndice = Chunck.newIndice + 1
	local t = ...
	local l = CHUNCK_SIZE
	self.x, self.y = t.x, t.y 
	self.indice, self.type, self.name, self.options, self.neighbours, self.world = Chunck.newIndice, t.type or 'regular', t.name or ('anonymous' .. Chunck.newIndice), t.options or {}, t.neighbours, t.world
	self.options.water = self.options.water or 30
	self.options.sand = self.options.sand or 40
	
	self.map = nil

	-- 4 animals max
	self.animals = { nil, nil, nil, nil }
	
	if type == 'regular' then
		self.animals[0] = Animal.new()
	end
	if self.world then
		self.world.chunckIndex['' .. self.x .. '_' .. self.y] = self
	end

	-- print(self.name, 'created')
end

function Chunck:getBack()
	if self.backSprite then
		return self.backSprite
	end
	
	self.backSprite = Bitmap.new(backside)
	return self.backSprite
end

function Chunck:generate()
	if self.map then
		return
	end
	-- print("Chunck:generate", self.name)
	local map, options = {}, self.options
	
	-- generate 2 layers of noise
	local layer0, layer1 = {}, {}
	local layers = {layer0, layer1}
	self.layers = layers
	
	-- get limits from neighbours
	if self.world and self.x ~= nil then
		local chunckIndex = self.world.chunckIndex
		local x, y = self.x, self.y
		local cu, cd, cr, cl = chunckIndex['' .. x .. '_' .. (y - 1)], chunckIndex['' .. x .. '_' .. (y + 1)], chunckIndex['' .. (x - 1) .. '_' .. y], chunckIndex['' .. (x + 1) .. '_' .. y]
		local lowLine, rightColumn = (CHUNCK_SIZE - 1) * CHUNCK_SIZE, CHUNCK_SIZE - 1
		-- print(cu and 'cu', cd and 'cd', cl and 'cl', cr and 'cr')
		if cu and cu.map then
			local ocLayer0, ocLayer1 = cu.layers[1], cu.layers[2]
			for i = 0, CHUNCK_SIZE - 1 do
				layer0[i] = ocLayer0[lowLine + i]
				layer1[i] = ocLayer1[lowLine + i]
			end
			yieldMe()
		end
		if cd and cd.map then
			local ocLayer0, ocLayer1 = cd.layers[1], cd.layers[2]
			for i = 0, CHUNCK_SIZE - 1 do
				layer0[lowLine + i] = ocLayer0[i]
				layer1[lowLine + i] = ocLayer1[i]
			end
			yieldMe()
		end
		if cl and cl.map then
			local ocLayer0, ocLayer1 = cl.layers[1], cl.layers[2]
			for j = 0, (CHUNCK_SIZE - 1) * CHUNCK_SIZE, CHUNCK_SIZE do
				layer0[j] = ocLayer0[rightColumn + j]
				layer1[j] = ocLayer1[rightColumn + j]
			end
			yieldMe()
		end
		if cr and cr.map then
			local ocLayer0, ocLayer1 = cr.layers[1], cr.layers[2]
			for j = 0, (CHUNCK_SIZE - 1) * CHUNCK_SIZE, CHUNCK_SIZE do
				layer0[rightColumn + j] = ocLayer0[j]
				layer1[rightColumn + j] = ocLayer1[j]
			end
			yieldMe()
		end
	end

	local z0, z1, z2, z3  = layer0[0] or math.random(140,160), layer0[CHUNCK_SIZE - 1] or math.random(140,160), layer0[(CHUNCK_SIZE - 1) * CHUNCK_SIZE] or math.random(140,160), layer0[CHUNCK_SIZE * CHUNCK_SIZE - 1] or math.random(140,160)
	local min1 = generateNoise(layer0, CHUNCK_SIZE, 0, 0, CHUNCK_SIZE, CHUNCK_SIZE, z0, z1, z2, z3)
	local z0, z1, z2, z3  = layer1[0] or math.random(96,160), layer1[CHUNCK_SIZE - 1] or math.random(96,160), layer1[(CHUNCK_SIZE - 1) * CHUNCK_SIZE] or math.random(96,160), layer1[CHUNCK_SIZE * CHUNCK_SIZE - 1] or math.random(96,160)
	local min2 = generateNoise(layer1, CHUNCK_SIZE, 0, 0, CHUNCK_SIZE, CHUNCK_SIZE, z0, z1, z2, z3)
			  
	-- start point at level>=80 min
	--     X
	--    XXX
	--     X     at self.startX,selt.startY
	local start = math.random(0, CHUNCK_SIZE * CHUNCK_SIZE -1)
	self.startY = math.floor(start / CHUNCK_SIZE)
	self.startX = start - CHUNCK_SIZE * self.startY
	
	layer0[start] = layer0[start] < 80 and 80 or layer0[start]
	if start > 0 then layer0[start - 1] = layer0[start - 1] < 80 and 80 or layer0[start - 1] end
	if start >= CHUNCK_SIZE then layer0[start - CHUNCK_SIZE] = layer0[start - CHUNCK_SIZE] < 80 and 80 or layer0[start - CHUNCK_SIZE] end
	if start < CHUNCK_SIZE * CHUNCK_SIZE - 1 then layer0[start + 1] = layer0[start + 1] < 80 and 80 or layer0[start + 1] end
	if start < CHUNCK_SIZE * (CHUNCK_SIZE- 1) then layer0[start + CHUNCK_SIZE] = layer0[start + CHUNCK_SIZE] < 80 and 80 or layer0[start + CHUNCK_SIZE] end
	
	-- generate a map with these 2 layers of noise
	local i = 1
	for y = 0, CHUNCK_SIZE - 1 do
        for x = 0, CHUNCK_SIZE - 1 do
            local green = (layer0[y * CHUNCK_SIZE + x] - 64)
            local level = (layer1[y * CHUNCK_SIZE + x] - 20)
			local color
			if level > 200 then
				-- moutain
				color = (level - 200)
				color = 0x444444 + color + color << 8 + color << 16
				fluff = math.random(6) == 5 and 20 or 0
			elseif level > 50 and level < 70 then
				-- water
				color = 0x0000FF + (math.abs(level - 60) << 11)
				color = color + 0x223344
					
			elseif level > 40 and level < 80 then
				-- sand
				local v = 21 - (math.abs(level - 60) - 20)
				--
				color = (v << 11) | 0xFF0000
				-- color = (0xFF0000 - (v << 20)) | (0x00FF00 - (v << 12))
				color = color - 0x220000 + 0x000066
				
			elseif level > math.random(120, 200) and level < math.random(0, 150) then
				-- flower
				color = 0xFF2200
			else
				-- forest
				
				if green == 155 then
					-- white dot
					color = 0xFFFFFF
				-- elseif green < options.water then
					
				-- 	color = 0x22FF22 - ((options.water  - green) / 2) & 127 << 8
				-- elseif green < options.sand then
				--	color = 0x224400
				elseif green > 200 then
					-- swamp
					color = 0x226622
				elseif green >= 0 then
					-- green
					color = 0x00FF00 - (math.floor(green ) << 8)
					color = color + 0x220022
					
				else
					-- too much green
					if green < -0x33 then
						color = 0x00664D
					else
						local v = math.floor(0xFF + 5 * green)
						color = (-0.05 * green) << 16 + v << 8 + (-0.03 * green) 
					end
				end
			end
			map[i] = color
			i = i + 1
			_ = i % 512 == 0 and yieldMe()
		end
    end
	-- map exposed once computed
	self.map = map
end


-- build map from 2 noise layers
function Chunck:get2DMapMesh()
	-- print("Chunck:get2DMapMesh", self.name)

	local options = self.options
	local mesh = chunckMeshes.map2d
	local map = self.map
	local i, j = 1, 1
	for y = 0, CHUNCK_SIZE - 1 do
        local color
		for x = 0, CHUNCK_SIZE - 1 do
			color = map[i]
			mesh:setColors(j, color, 1)
			i = i + 1
			j = j + 1
		end
		mesh:setColors(j, color, 1)
		j = j + 1
		_ = j % 32 == 0 and yieldMe()
	end
	for x = 0, CHUNCK_SIZE do
		local color = map[CHUNCK_SIZE * CHUNCK_SIZE - CHUNCK_SIZE + x]
		mesh:setColors(j, color, 1)
		j = j + 1
	end
	-- print("Chunck:get2DMapMesh", self.name, i, "done")
	return mesh
end

function Chunck:getElevation(x, y)
	local layer0, layer1 = self.layers[1], self.layers[2]
	local green = (layer0[y * CHUNCK_SIZE + x] - 64)
	local level = (layer1[y * CHUNCK_SIZE + x] - 20)
	local correction = 0
	local fluff = 0

	if level < 30 then
		-- en dessous de la rivière = en dessus en fait
		correction = (level - 30) * 2
	elseif level < 90 then
		-- près de la rivière : annulation du niveau
		correction = math.min(math.floor((level - 30)), math.floor((90 - level)))
		if level > 50 and level < 70 then
			-- in the river
			correction = correction * 1.2
		elseif level > 40 and level < 80 then
			-- sand
		end
	elseif level > 200 then
		-- renforcement montagne
		correction = (200 - level)
	else
		-- entre 90 et 200 rien
	end
	-- if level > 200 and green > 200 then
	--	correction = (green - 190)
	-- end
	
	if green < 0 then
		correction = correction + (-green) * math.log(-green) -- + 20 + math.max(0, math.abs(level - 60) - 40) * 0.01 * (-green) * math.log(-green) 
		if  green > -0x33 and level < 200  and (level < 50 or level > 70) then fluff = -green end
	elseif green < 200 and level < 200 and (level < 40 or level > 80) then
		if color ~= 0xFFFFFF and color ~= 0xFF2200 then
			-- tree
			correction = correction - level / 20
			fluff = green / 5 -- (200 - green) / 10
		else
			correction = -20
		end
	end

	local z = 250 + level * 2 - correction * 2

	-- exagération des trous
	if z < 0 then
		z = 50 * z / (50 + z * z) 
	end
	
	-- effondrement près des bords
	if true then
		local fallStart = 5
		if x < 1 or y < 1 or x >= CHUNCK_SIZE - 2 or y >= CHUNCK_SIZE - 2 then
			z = - 4000
		elseif x < fallStart or y < fallStart or x >= CHUNCK_SIZE - fallStart or y >= CHUNCK_SIZE - fallStart then
			local fallRatio = 10
			local fall = math.max(fallStart - x, fallStart - y, x - CHUNCK_SIZE + fallStart + 1, y - CHUNCK_SIZE + fallStart + 1)
			z = z - fallRatio * math.exp(fall / 3)
		end
	end

	return z, fluff
end



-- build 3D map from 2 noise layers
function Chunck:get3DMapMesh()
	-- print("Chunck:get2DMapMesh", self.name)

	local options = self.options
	local mesh = chunckMeshes.map3d
	local map = self.map
	while mesh:getNumChildren() > 0 do
		mesh:removeChildAt(1)
	end
	local i, j = 1, 1
	for y = 0, CHUNCK_SIZE - 1, 2 do
        local color
		for x = 0, CHUNCK_SIZE - 1, 2 do
			color = map[1 + x + y * CHUNCK_SIZE]
			local z, fluff = self:getElevation(x, y)
			
			mesh:setVertex(j, x * pixelSize, y * pixelSize, z * pixelSize / 10)
			mesh:setColors(j, color, 1)
			j = j + 1
			mesh:setVertex(j, x * pixelSize + 2 * pixelSize, y * pixelSize, z * pixelSize / 10)
			mesh:setColors(j, color, 1)
			j = j + 1
			mesh:setVertex(j, x * pixelSize, y * pixelSize + 2 * pixelSize, z * pixelSize / 10)
			mesh:setColors(j, color, 1)
			j = j + 1
			mesh:setVertex(j, x * pixelSize + 2 * pixelSize, y * pixelSize + 2 * pixelSize, z * pixelSize / 10)
			mesh:setColors(j, color, 1)
			j = j + 1
			mesh:setVertex(j, x * pixelSize + pixelSize * ((7 + math.random(5)) / 10) , y * pixelSize + pixelSize * ((7 + math.random(5)) / 10), (z + fluff) * pixelSize / 10)
			mesh:setColors(j, color, 1)
			j = j + 1
			-- i = i + 2
		end
		yieldMe()
	end
	
	mesh:setAnchorPoint(0.5, 0.5, 1)
	return mesh
end

function Chunck:drawMap()
	if self.canvas then
		return self.canvas
	end
	local mesh = self:get2DMapMesh()
	self.canvas = RenderTarget.new(CHUNCK_SIZE, CHUNCK_SIZE)
	self.canvas:draw(mesh, 0, 0)
	return self.canvas
end

function Chunck:getMap()
	if self.bitmap then
		return self.bitmap
	end
	self:generate()
	self:drawMap()
	yieldMe()
	self.bitmap = Bitmap.new(self.canvas)
	return self.bitmap
end
