--  http://giderosmobile.com/forum/discussion/2269/pinch-to-zoom


--Function to get range between touch/coord
local function getDelta(point1, point2)
	local dx = point1.x - point2.x
	local dy = point1.y - point2.y
	return math.sqrt(dx * dx + dy * dy)
end
 
function handleZoom(self, event)
	local scalingHappen, movingHappen = false, false
	local parent, touchPoints, idTouchExist, scaleRev = self:getParent(), self.touchPoints, self.idTouchExist, self.scaleRev
	if touchPoints == nil then
		-- first call
	    touchPoints = { {}, {} }
		idTouchExist = { false, false }
		scaleRev = (1 / parent:getScaleX())
		self.touchPoints  = touchPoints
		self.idTouchExist = idTouchExist
		self.scaleRev = scaleRev
	end
	print("scaleRev", scaleRev)
	if event.type == "mouseWheel" then
		local ratio = (360 + event.wheel * 0.5) / 360
		local lx, ly = self:globalToLocal(event.x, event.y)
		local newScale = parent:getScaleX() * ratio
		parent:setScale(newScale)
		local nlx, nly = self:globalToLocal(event.x, event.y)
		scaleRev = 1 / newScale
		self:setX(self:getX() + (nlx - lx) * 1)
		self:setY(self:getY() + (nly - ly) * 1)
		movingHappen = true
		scalingHappen = true
		event:stopPropagation()		
	end
	
	local touchGet = event.touch
	local id = touchGet and touchGet.id -- id is the finger number

	if id == 1 or id == 2 then
		local otherID = (id == 2 and 1 or 2)
		
		if event.type == "touchesBegin" then
				
			if not idTouchExist[otherID] then
				--Get the first Finger
				touchPoints[id].x = touchGet.x
				touchPoints[id].y = touchGet.y

				local scale = parent:getScaleX()
				self.x0 = touchGet.x - self:getX() * scale
				self.y0 = touchGet.y - self:getY() * scale
 
			elseif not idTouchExist[id] then
				--Get the second Finger
				touchPoints[id].x = touchGet.x
				touchPoints[id].y = touchGet.y
 
				-- get Length between touch and original Zoom
				local deltaTouch = getDelta(touchPoints[1], touchPoints[2]) 

				-- get center of 1 & 2
				local touchCX, touchCY = (touchPoints[1].x + touchPoints[2].x) * 0.5, (touchPoints[1].y + touchPoints[2].y) * 0.5
				local scale = parent:getScaleX()
				if deltaTouch > 0 then
					self.oriDeltaTouch = deltaTouch
					self.oriScale = scale
				end
 
				self.x0 = touchCX - self:getX() * scale
				self.y0 = touchCY - self:getY() * scale
 			end
 
			idTouchExist[id] = true
 
		elseif event.type == "touchesMove" then
			-- save Touch Pos
			touchPoints[id].x = touchGet.x
			touchPoints[id].y = touchGet.y
 
			if not idTouchExist[otherID] then
				-- If there is one Touch then move
				self:setX((touchGet.x  - self.x0) * scaleRev)
				self:setY((touchGet.y  - self.y0) * scaleRev)
				movingHappen = true
 
			else
				-- If there is second finger Then Scale And Move	
 
				local deltaTouch = getDelta(touchPoints[1], touchPoints[2]) 
				local scaler = deltaTouch / self.oriDeltaTouch
 
				if scaler > 0 then
					local newScale = self.oriScale * scaler
					parent:setScale(newScale)
					scaleRev = 1 / newScale
					scalingHappen = true
				end
 
				local touchCX, touchCY = (touchPoints[1].x + touchPoints[2].x) * 0.5, (touchPoints[1].y + touchPoints[2].y) * 0.5
				self:setX((touchCX - self.x0) * scaleRev)
				self:setY((touchCY  - self.y0) * scaleRev)
				movingHappen = true
			end
 
			event:stopPropagation()
 
 
			-- Using animation also nice...
			-- So just give some condition to let  ENTER_FRAME event do the scaling / moving after
			-- And then let them move like this:
				-- if self.targetX ~= self:getX() then 
				-- 	local delta = ( self:getX() - self.TargetX ) * 0.1
				--		if delta > 0 then delta = ceil(delta) else delta = floor(delta) end
				--		self:setX( self:getX() - delta )
				-- end 
			-- But it more complexer than that, i think
 
 
		elseif event.type == "touchesEnd" then
 
			if idTouchExist[otherID] then
				self.x0 = touchPoints[otherID].x  -( self:getX()* parent:getScaleX() )
				self.y0 = touchPoints[otherID].y  - ( self:getY()* parent:getScaleX() )
			end	

			idTouchExist[id] = false
 
			event:stopPropagation()
		end
	end
 
	if movingHappen then
		-- limit X,Y max and min
		if self:getY() < self.downLimit then self:setY( self.downLimit )
		elseif self:getY() > self.upLimit then self:setY(  self.upLimit )
		end
		if self:getX() < self.rightLimit then self:setX( self.rightLimit )
		elseif self:getX() > self.leftLimit then self:setX(  self.leftLimit )
		end
	end
	
	if scalingHappen then
		-- limit scaling
		if parent:getScaleX() > 1.0  then
			parent:setScale(1.0)
			scaleRev = 1
		elseif parent:getScaleX() < self.minZoom then
			parent:setScale(self.minZoom)
			scaleRev = 1 / self.minZoom
		end	
		
		self.scaleRev = scaleRev
	end

	return true
end

function attachZoom(zoomable, minZoom, maxMoveRatio)
	local halfWidth, halfHeight = zoomable:getWidth() * maxMoveRatio, zoomable:getHeight() * maxMoveRatio

	-- Some of initialization that i need for Pinch-Zoom
	zoomable.minZoom = minZoom
	zoomable.leftLimit = halfWidth
	zoomable.rightLimit = -halfWidth
	zoomable.upLimit = halfHeight
	zoomable.downLimit = -halfHeight
 
	zoomable:addEventListener(Event.TOUCHES_BEGIN, handleZoom, zoomable)
	zoomable:addEventListener(Event.TOUCHES_MOVE, handleZoom, zoomable)
	zoomable:addEventListener(Event.TOUCHES_END, handleZoom, zoomable)
	zoomable:addEventListener(Event.MOUSE_WHEEL, handleZoom, zoomable)
end
