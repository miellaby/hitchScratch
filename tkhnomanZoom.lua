--  http://giderosmobile.com/forum/discussion/2269/pinch-to-zoom

--Function to get range between touch/coord
local function getDelta(point1, point2)
	local dx = point1.x - point2.x
	local dy = point1.y - point2.y
	return math.sqrt(dx * dx + dy * dy)
end

local function goToTarget(self, event)
	local _zoom = self._zoom
	local targetX, targetY, idTouchExist = _zoom.targetX, _zoom.targetY, _zoom.idTouchExist
	
	-- limit X,Y move into min and max ranges
	local noTouch = not idTouchExist[1] and not idTouchExist[2];
	if noTouch then
		if targetX < _zoom.rightLimit then _zoom.targetX, targetX = _zoom.rightLimit, _zoom.rightLimit
		elseif targetX > _zoom.leftLimit then _zoom.targetX, targetX = _zoom.leftLimit, _zoom.leftLimit
		end
		if targetY < _zoom.downLimit then _zoom.targetY, targetY = _zoom.downLimit, _zoom.downLimit
		elseif targetY > _zoom.upLimit then _zoom.targetY, targetY = _zoom.upLimit, _zoom.upLimit
		end
	end
	
	local move = false
	if targetX ~= self:getX() then 
		local delta = ( self:getX() - targetX ) * 0.3
		if math.abs(delta) > 1 then
			self:setX(self:getX() - delta)
		else
			self:setX(targetX)
			_zoom.targetX = self:getX()
		end
		move = true
	end 
	if targetY ~= self:getY() then 
		local delta = ( self:getY() - targetY ) * 0.3
		if math.abs(delta) > 1 then
			local before = self:getY()
			self:setY(self:getY() - delta)
			-- print("diffY", before, self:getY(), targetY, delta)
		else
			-- print("finishY", self:getY(), targetY)
			self:setY(targetY)
			_zoom.targetY = self:getY()
		end
		move = true
	end 
	if noTouch and not move then
		self:removeEventListener(Event.ENTER_FRAME, goToTarget, self)
	end
end

function zoomTo(self, x, y)
	local _zoom = self._zoom
	_zoom.targetX, _zoom.targetY = x, y
	self:addEventListener(Event.ENTER_FRAME, goToTarget, self)
end

function handleZoom(self, event)
	local scalingHappen, movingHappen = false, false
	local _zoom = self._zoom
	local parent, touchPoints, idTouchExist = self:getParent(), _zoom.touchPoints, _zoom.idTouchExist

	if event.type == "mouseWheel" then
		local lx, ly = parent:globalToLocal(event.x, event.y)
		
		local ratio = (360 + event.wheel * 0.5) / 360
		local oldScale = parent:getScaleX()
		local newScale = oldScale * ratio
		if newScale > 1.0  then
			newScale = 1.0
		elseif newScale < _zoom.min then
			newScale = _zoom.min
		end	
		parent:setScale(newScale, newScale, newScale)

		local nlx, nly = parent:globalToLocal(event.x, event.y)
		_zoom.targetX = self:getX() + nlx - lx
		_zoom.targetY = self:getY() + nly - ly
		self:setX(_zoom.targetX)
		self:setY(_zoom.targetY)
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
				_zoom.x0 = touchGet.x - self:getX() * scale
				_zoom.y0 = touchGet.y - self:getY() * scale
 
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
					_zoom.oriDeltaTouch = deltaTouch
					_zoom.oriScale = scale
				end
 
				_zoom.x0 = touchCX - self:getX() * scale
				_zoom.y0 = touchCY - self:getY() * scale
 			end
 
			idTouchExist[id] = true
 
		elseif event.type == "touchesMove" then
			if _zoom.x0 == nil then return end -- can happen if activation under already touched screen
			local scaleRev = 1 / parent:getScaleX() 
				
			-- save Touch Pos
			touchPoints[id].x = touchGet.x
			touchPoints[id].y = touchGet.y
			if not idTouchExist[otherID] then
				-- If there is one Touch then move
				_zoom.targetX = (touchGet.x  - _zoom.x0) * scaleRev
				_zoom.targetY = (touchGet.y  - _zoom.y0) * scaleRev
				movingHappen = true
 
			else
				-- If there is second finger Then Scale And Move	
 
				local deltaTouch = getDelta(touchPoints[1], touchPoints[2]) 
				local scaler = deltaTouch / _zoom.oriDeltaTouch
				
				if scaler > 0 then
					local newScale = _zoom.oriScale * scaler
					parent:setScale(newScale)
					scaleRev = 1 / newScale
					scalingHappen = true
				end
 
				local touchCX, touchCY = (touchPoints[1].x + touchPoints[2].x) * 0.5, (touchPoints[1].y + touchPoints[2].y) * 0.5
				_zoom.targetX = ((touchCX - _zoom.x0) * scaleRev);
				_zoom.targetY = ((touchCY - _zoom.y0) * scaleRev);
				movingHappen = true
			end
 
			event:stopPropagation()
		elseif event.type == "touchesEnd" then
 
			if idTouchExist[otherID] then
				local scale = parent:getScaleX()
				_zoom.x0 = touchPoints[otherID].x - self:getX()* scale
				_zoom.y0 = touchPoints[otherID].y - self:getY()* scale
			end	

			idTouchExist[id] = false
 
			_ = _zoom.capture and event:stopPropagation()
			if not idTouchExist[otherId] then _zoom.capture = false end
		end
	end
 
	if movingHappen then
		self:addEventListener(Event.ENTER_FRAME, goToTarget, self)
		-- as soon as with move from 2px, one capture touchesEnd
		if not _zoom.capture and math.abs(_zoom.targetX - self:getX()) + math.abs(_zoom.targetX - self:getX()) > 10 then
			_zoom.capture = true
		end
	end
	
	if scalingHappen then
		-- limit scaling
		if parent:getScaleX() > 1.0  then
			parent:setScale(1.0, 1.0, 1.0)
		elseif parent:getScaleX() < _zoom.min then
			parent:setScale(_zoom.min, _zoom.min, _zoom.min)
		end	
	end

	return true
end
 
local currentZoomable
function attachZoom(self, minZoom, maxMoveRatio)
	if currentZoomable then
		currentZoomable:removeEventListener(Event.TOUCHES_BEGIN, handleZoom, self)
		currentZoomable:removeEventListener(Event.TOUCHES_MOVE, handleZoom, self)
		currentZoomable:removeEventListener(Event.TOUCHES_END, handleZoom, self)
		currentZoomable:removeEventListener(Event.MOUSE_WHEEL, handleZoom, self)
		currentZoomable:removeEventListener(Event.ENTER_FRAME, goToTarget, self)
	end
	currentZoomable = self
	self:addEventListener(Event.TOUCHES_BEGIN, handleZoom, self)
	self:addEventListener(Event.TOUCHES_MOVE, handleZoom, self)
	self:addEventListener(Event.TOUCHES_END, handleZoom, self)
	self:addEventListener(Event.MOUSE_WHEEL, handleZoom, self)
	
	local halfWidth, halfHeight = self:getWidth() * maxMoveRatio, self:getHeight() * maxMoveRatio
	
	-- initialization for Pinch-Zoom
	local parent = self:getParent()
	self._zoom = {
		min = minZoom,
		leftLimit = halfWidth,
		rightLimit = -halfWidth,
		upLimit = halfHeight,
		downLimit = -halfHeight,
		touchPoints = { {}, {} },
		idTouchExist = { false, false },
		oriDeltaTouch = nil,
		oriScale = nil,
		-- for animated translation
		targetX = self:getX(),
		targetY = self:getY(),
		-- center of zoom: if one touch, its coordinate, if 2 touch, the middle of the 2 fingers
		x0 = nil,
		y0 = nil,
		-- if pinch-zoom then capture
		capture = false
	};
	self.zoomTo = zoomTo
end
