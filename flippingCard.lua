local dirt = Texture.new("rsc/dirtf.png", false, {wrap = Texture.REPEAT});
local function face(l,g,z,stuff,rx,ry)
	c=Sprite.new()
	sb=NdShape.new()
	c:addChild(sb)
	if stuff then
		sb:setFillStyle(Shape.SOLID, 0xAAFFAA,1.0)
	else
		sb:setFillStyle(Shape.TEXTURE, dirt, Matrix.new(1, 0, 0, 1));
	end
	
	sb:beginPath()
	sb:rect(0,0,l,g)
	sb:fill()
	sb:setZ(-z)
	_ = stuff and sb:addChild(stuff)
	if stuff then
		s=NdShape.new()
		sb:addChild(s)
		s:setLineStyle(4,0x004000,1.0)
		s:beginPath()
		s:rect(0,0,l,g)
		s:stroke()
		s:setZ(-1)
	end
	
	c:setRotationX(rx)
	c:setRotationY(ry)
	return c;
end

FlippingCard = Core.class(Mesh)

function FlippingCard:init(what, is3d, chunck, flipped)
    print(chunck.name)
	self.chunck = chunck
	self.flipped = flipped
	self.up = false
	self:addChild(face(CHUNCK_SIZE,CHUNCK_SIZE,25, chunck:getBack(),180,0))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,90,0))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,-90,0))
	self:addChild(face(CHUNCK_SIZE,CHUNCK_SIZE,25, chunck:getMap(),0,0))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,90,90))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,90,-90))
	self:setZ(-20)
	_ = flipped and self:setRotationX(180)
	chunck:getBack():setPosition(0,0)
	chunck:getMap():setPosition(0,0)
	chunck:getMap():setAlpha(0.8)
end

function FlippingCard:doGoUp()
	if self.up then
		self:setZ(math.exp(2 + (400 - self.incUp) / 100) - math.exp(2))
	else
		self:setZ(math.exp(2 + self.incUp / 100) - math.exp(2))
	end
	self.incUp = self.incUp + 10
	if self.incUp == 410 then
		self.up = not self.up
		self.goingUp = false
		self:removeEventListener(Event.ENTER_FRAME, self.doGoUp, self)
	end
end

function FlippingCard:goUp()
	if self.goingUp then
		self.up = not self.up
		self.incUp = 400 - self.incUp
	else
		self.goingUp = true
		self.incUp = 0
		self:addEventListener(Event.ENTER_FRAME, self.doGoUp, self)
	end
	
end

function FlippingCard:doFlip()
	self:setRotationX(self.inc * 36 / 8)
	self:setRotationY(self.inc * 36 / 4)
	self:setRotation(- self.inc * 36 / 8)
	self.inc = self.inc + 1
	self.chunck:getMap():setAlpha(0.4 + 0.3 * math.cos(self.inc / 10 * math.pi))
	if self.inc == 41 then
		self.flipping = false
		self.flipped = true
		self:removeEventListener(Event.ENTER_FRAME, self.doFlip, self)
	end
end

function FlippingCard:flip()
	if not self.flipped and not self.flipping then
		self.flipping = true
		self.inc = 0
		self:addEventListener(Event.ENTER_FRAME, self.doFlip, self)
	end
end

