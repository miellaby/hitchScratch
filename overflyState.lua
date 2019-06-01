-- search scene
local overflyScene = Mesh.new(true)
for fi = 0, 12 do
	local fog = Pixel.new(0x264040, 1 / (3 + fi / 4), 5000, 5000)
	fog:setAnchorPoint(0.5, 0.5, 0)
	fog:setRotation(fi * 20)
	fog:setZ(30 + fi * 15)
	fog:setPosition(0, 0)
	fog:setBlendMode(Sprite.ADD)
	overflyScene:addChild(fog)
end

overflyScene:setRotationX(40)
overflyScene:setAnchorPoint(0, 0, 0)
overflyScene:setScale(1.3,1.3,1.3)

gameStates.overfly = {
	name = "overfly",
	before = function()
		_ = overflyScene and overflyScene:getNumChildren() > 0 and overflyScene:removeChildAt(1)
		local mesh = chunck:get3DMapMesh();
		-- mesh:setRotationX(66)
		overflyScene:addChildAt(mesh, 1)
		overflyScene:setAnchorPosition(0, 0)
	end,
	after = nil,
	iterate = function()
		overflyScene:setRotation(-math.sin(iteration / 200) * 200 + 12)
		-- local ap = 0.1 + math.sin(iteration / 80)*0.2
		-- scene:setZ(ap * CHUNCK_SIZE * 20)
	end,
	scene = overflyScene
}

