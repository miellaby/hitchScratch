-- zoom area where main scene is set

zoomArea = Mesh.new(true)
zoomArea:setScale(0.3)
zoomArea:setPosition(application:getContentWidth() / 2, application:getContentHeight() / 2)
stage:addChild(zoomArea)

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