CHUNCK_SIZE = 128

local function yieldMe()
	if coroutine.running() then
		-- print('yield')
		coroutine.yield()
	end
end

local function buildSquareMesh()
	local mesh = Mesh.new(false)
	
	-- build vertices
	local i = 1
	for y = 0, CHUNCK_SIZE do
		for x = 0, CHUNCK_SIZE do
			mesh:setVertex(i, x, y)
			i = i + 1
		end
	end
	
	-- build triangles
	local i, j = 1, 1
	for y = 0, CHUNCK_SIZE - 1 do
		for x = 0, CHUNCK_SIZE - 1 do
			-- 2 triangles filling a square
			if (x + y) % 2 == 0 then
				mesh:setIndices(j, i,    j + 1, i + 1,     j + 2, i + CHUNCK_SIZE + 1,    j + 3, i + 1,     j + 4, i + CHUNCK_SIZE + 1,     j + 5, i + CHUNCK_SIZE + 2)
			else
				mesh:setIndices(j, i,    j + 1, i + 1,     j + 2, i + CHUNCK_SIZE + 2,    j + 3, i,     j + 4, i + CHUNCK_SIZE + 1,     j + 5, i + CHUNCK_SIZE + 2)
			end
			j = j + 6
			i = i + 1
		end
		i = i + 1
	end
	return mesh
end

local sharedMesh = buildSquareMesh()


local backgroundMesh
local function renderBackground()
	local mesh = sharedMesh
	local i, j = 1, 1
	local map = {}
	for i = 1, CHUNCK_SIZE * CHUNCK_SIZE do
		local color = math.ceil((i * i) >> 10 + (i * i) >> 6) % 16
		map[i] = 0xFFFAA - (color << 16 + color << 20)
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
	rt:draw(Pixel.new(0xFFFFFF, CHUNCK_SIZE, CHUNCK_SIZE))
	local sprite = Sprite.new()
	sprite:addChild(mesh)
	sprite:setScale((CHUNCK_SIZE - 10) / CHUNCK_SIZE)
	rt:draw(sprite, 5, 5)
	return rt
end

local backgroundStuff = renderBackground()

-- generate a noise map layer
-- t: noise square array, l : square side length
-- (x0,y0)-(x3,y3) recursive computed square
--  z0, z1, z2 and z3 : 4 levels at square corners
function generateNoise(t, l, x0, y0, x3, y3, z0, z1, z2, z3)
	--[[
    (x0,y0)
	  z0    p1    z1
	  
         (x5,y5)
	  p2    p5    p3
	  
	  
	  z2    p4    z3
                (x3,y3)
	]]--
	
   local c = x3 - x0
   if c <= 2 then
		_ = x0 % 32 == 0 and y0 % 128 == 0 and yieldMe()
		local zz1 = math.floor((2 * z1 + z0) / 3)
	    local zz2 = math.floor((2 * z2 + z0) / 3)
	    local zz3 = math.floor((2 * z3 + z1 + z2) / 4)
		x3 = x3 - 1
		y3 = y3 - 1
		t[x0 + y0 * l] = z0
		t[x3 + y0 * l] = zz1
		t[x0 + y3 * l] = zz2
		t[x3 + y3 * l] = zz3
	    if x3 < l - 1 then
			t[x3 + 1 + y0 * l] = z1
			t[x3 + 1 + y3 * l] = z3
		end
        if y3 < l - 1 then
			t[x0 + y3 * l + l] = z2
			t[x3 + y3 * l + l] = z3
		end
		
		local z, zb = (z0 < z1 and z0 or z1), (z2 < z3 and z2 or z3)
		return z < zb and z or zb
   end
   
   local x5, y5 = math.floor((x3 + x0) / 2), math.floor((y3 + y0) / 2)
   local tp1 = t[x5 + y0 * l]
   local tp2 = t[x0 + y5 * l]
   local tp3 = x3 == l and t[l - 1 + y5 * l]
   local tp4 = y3 == l and t[x5 + (l - 1) * l]
   local p5 = math.floor((z0 + z1 + z2 + z3) / 4) + math.random(-c, c)
   local p1 = tp1 or (math.floor((z0 + z1) / 2) + math.random(-c, c))
   local p2 = tp2 or (math.floor((z0 + z2) / 2) + math.random(-c, c))
   local p3 = tp3 or (math.floor((z1 + z3) / 2) + math.random(-c, c))
   local p4 = tp4 or (math.floor((z2 + z3) / 2) + math.random(-c, c))
   
   local m0 = generateNoise(t, l, x0, y0, x5, y5,  z0, p1, p2, p5)
   local m1 = generateNoise(t, l, x5, y0, x3, y5,  p1, z1, p5, p3)
   local m2 = generateNoise(t, l, x0, y5, x5, y3,  p2, p5, z2, p4)
   local m3 = generateNoise(t, l, x5, y5, x3, y3,  p5, p3, p4, z3)
   local z, zb = (m0 < m1 and m0 or m1), (m2 < m3 and m2 or m3)
   return z < zb and z or zb
end


-- A Chunck
Chunck = Core.class()

Chunck.newIndice = 0

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
	
	self.backSprite = Bitmap.new(backgroundStuff)
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
            local level = (layer0[y * CHUNCK_SIZE + x] - 64)
            local density = (layer1[y * CHUNCK_SIZE + x] - 20)
			local color
			if density > 200 then
				color = (density - 200)
				color = 0x444444 + color + color << 8 + color << 16
			elseif density > 50 and density < 70 then
				color = 0x0000FF + (math.abs(density - 60) << 11)
			elseif density > 40 and density < 80 then
				local v = 20 - (math.abs(density - 60) - 20)
				--
				color = (v << 11) | 0xFF0000
				-- color = (0xFF0000 - (v << 20)) | (0x00FF00 - (v << 12))
			elseif density > math.random(120, 200) and density < math.random(0, 150) then
				color = 0xFF2200
			else
				local correction = 0
				if density > 30 then
					correction = math.floor((density - 30) / 2)
				elseif density < 90 then
					correction = math.floor((90 - density) / 2) 
				end
				level = level + correction
				if level == 155 then
					color = 0xFFFFFF
				elseif level < options.water then
					color = 0x22FF22 - ((options.water  - level) / 2) & 127 << 8
				elseif level < options.sand then
					color = 0x224400
				elseif level > 200 then
					color = 0x226622
				else
					color = 0x00FF00 - (math.floor(level * 0.9) << 8)
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
	local mesh = sharedMesh	
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
