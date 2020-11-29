local dirt = Texture.new("rsc/dirtf.png", false, {wrap = Texture.REPEAT});

local State = {}

State.DOWN = {
	name = "down",
	enter = function(self)
		self:setZ(0)
		self:setRotationX(180)
	end
}

State.RAISING = {
	name = "raising",
	enter = function(self)
		self:setRotationX(180)
	end,
	animate = function(self, iteration)
		self:setZ(20 * math.log(1 + 100 * iteration) - 20)
		if iteration == 40 then
			self:setState(State.UP)
		end
	end
}

State.LANDING = {
	name = "landing",
	enter = function(self)
		self:setRotation(180)
		self:setRotationY(0)
		self:setRotationX(180)
	end,
	animate = function(self, iteration)
		self:setZ(20 * math.log(1 + 100 * (40 - iteration)) - 20)
		if iteration == 40 then
			self:setState(State.DOWN)
		end
	end
}

State.UP = {
	name = "up",
	enter = function(self)
		self:setZ(20 * math.log(1 + 4000) - 20)
	end
}

State.FLIPPING = {
	name = "flipping",
	animate = function(self, iteration)
		self:setRotationX(iteration * 36 / 8)
		self:setRotationY(iteration * 36 / 4)
		self:setRotation(- iteration * 36 / 8)
		self:setZ(20 * math.log(1 + 100 * iteration) - 20)
		-- self:setZ(100 * math.sin(math.pi * iteration / 40) - 20)
		-- self.chunck:getMap():setAlpha(0.6 - 0.4 * math.cos(iteration / 41 * math.pi))
		if iteration == 40 then
			self:setState(State.UP)
		end
	end
}

State.HIDDEN = {
	name = "hidden",
	enter = function(self)
		self:setZ(-21)
	end
}

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
		s:setLineStyle(2,0x004000,1.0)
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
mixinAnimationState.mixin(FlippingCard)

function FlippingCard:init(what, is3d, chunck, flipped)
    -- print(chunck.name)
	self.chunck = chunck
	self:addChild(face(CHUNCK_SIZE,CHUNCK_SIZE,-25, chunck:getMap(),0,180))
	self:addChild(face(CHUNCK_SIZE,CHUNCK_SIZE,25, chunck:getBack(),180,0))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,90,0))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,-90,0))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,90,90))
	self:addChild(face(CHUNCK_SIZE,50,CHUNCK_SIZE/2,nil,90,-90))
	
	chunck:getBack():setPosition(0,0)
	chunck:getMap():setPosition(0,0)
	-- chunck:getMap():setAlpha(0.8)
	self:setState(flipped and State.DOWN or State.HIDDEN);
end



function FlippingCard:land()
	if self.state == State.DOWN or self.state == State.LANDING then
		return
	end
		
	self:setState(State.LANDING)
end

function FlippingCard:touch()
	if self.state == State.HIDDEN then
		self:setState(State.FLIPPING)
	elseif self.state == State.DOWN or self.state == State.LANDING then
		self:setState(State.RAISING)
	elseif self.state == State.UP or self.state == State.RAISING or self.state == State.FLIPPING then
		self:setState(state.LANDING)
	end
end


FlippingCard.State = State