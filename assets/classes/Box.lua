local function face(l, g, z, fillStyle, fillStuff, rx, ry)
	c=Sprite.new()
	sb=NdShape.new()
	c:addChild(sb)
	if fillStyle == Shape.SOLID then
		sb:setFillStyle(Shape.SOLID, fillStuff, 1.0)
	else
		sb:setFillStyle(fillStyle, fillStuff, Matrix.new(1, 0, 0, 1));
	end
	
	sb:beginPath()
	sb:rect(0,0,l,g)
	sb:fill()
	sb:setZ(-z)
	
	c:setRotationX(rx)
	c:setRotationY(ry)
	return c;
end

Box = Core.class(Mesh)

function Box:init(w, l, h, frontStyle, front, backStyle, back, sideStyle, side)
	self:addChild(face(w, l, h / 2,  frontStyle, front,  0, 0))
	self:addChild(face(w, l, h / 2,  backStyle,  back, 180, 0))
	self:addChild(face(w, h, l / 2,  sideStyle,  side,  90, 0))
	self:addChild(face(w, h, l / 2,  sideStyle,  side, -90, 0))
	self:addChild(face(l, h, w / 2,  sideStyle,  side,  90, 90))
	self:addChild(face(l, h, w / 2,  sideStyle,  side,  90, -90))
end
