pixelSize = 1
	

-- called once to build chunckMesh
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

-- called once to build chunck3dMesh
local function build3dSquareMesh()
	local mesh = Mesh.new(true)
	
	-- build vertices
	local i = 1
	for y = 0, CHUNCK_SIZE - 1, 2 do
		for x = 0, CHUNCK_SIZE - 1, 2 do
			mesh:setVertex(i, x * pixelSize, y * pixelSize, 0)
			i = i + 1
			mesh:setVertex(i, x * pixelSize + 2 * pixelSize, y * 2 * pixelSize, 0)
			i = i + 1
			mesh:setVertex(i, x * pixelSize, y * pixelSize + 2 * pixelSize, 0)
			i = i + 1
			mesh:setVertex(i, x * pixelSize + 2 * pixelSize, y * pixelSize + 2 * pixelSize, 0)
			i = i + 1
			mesh:setVertex(i, x * pixelSize + pixelSize, y * pixelSize + pixelSize, 0)
			i = i + 1
		end
	end
	-- print(i)

	local i, j = 1, 1
	for y = 0, CHUNCK_SIZE - 1, 2 do
		for x = 0, CHUNCK_SIZE - 1, 2 do
			-- 2 triangles filling a square
			mesh:setIndices(j, i,        j + 1, i + 1,     j + 2, i + 3,    j + 3, i + 3,     j + 4, i + 2,     j + 5, i)
			j = j + 6
			mesh:setIndices(j, i,        j + 1, i + 4,     j + 2, i + 3,    j + 3, i + 1,     j + 4, i + 4,     j + 5, i + 2)
			j = j + 6
			if x > 0 then
				local b = i - 5 -- le carré d'avant en x
				-- relier b1  0 2 b3
				mesh:setIndices(j, b + 1,    j + 1, i,     j + 2, i + 2,    j + 3, i + 2,     j + 4, b + 3,     j + 5, b + 1)
				j = j + 6
			end
			if y > 0 then
				local b = i - 5 * CHUNCK_SIZE / 2 -- le carré d'avant en y
				-- relier b3 1 0 b2 
				mesh:setIndices(j, b + 3,    j + 1, i + 1,     j + 2, i)
				j = j + 3
				mesh:setIndices(j, i,        j + 1, b + 2,     j + 2, b + 3)
				j = j + 3
			end
			i = i + 5
		end
	end
	return mesh
end

-- two local mesh objects are reused:
--  a 2D mesh which is used to generate a 2D rendition (map tile) of the chunck
--  a 3D mesh for the 3D rendering
chunckMeshes = {
 map2d = buildSquareMesh(),
 map3d = build3dSquareMesh()
}
