-- zoom feature
--  http://giderosmobile.com/forum/discussion/2269/pinch-to-zoom
-- see attachZoom

-- the current scene with zoom abilities
local currentZoomable

--Function to get range between touch/coord
local function getDelta(point1, point2)
	local dx = point1.x - point2.x
	local dy = point1.y - point2.y
	return math.sqrt(dx * dx + dy * dy)
end

local function goToTarget(self, event)
	local _zoom = self._zoom
	local targetX, targetY, targetZoom, idTouchExist = _zoom.targetX, _zoom.targetY, _zoom.targetZoom, _zoom.idTouchExist
	
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
	local currentZoom = self._zoom.scale
	if targetZoom ~= currentZoom then 
		local delta = ( currentZoom - targetZoom ) * 0.4
		local newScale
		if math.abs(delta) > 0.01 then
			newScale = currentZoom - delta
		else
			newScale = targetZoom
		end
		self:getParent():setScale(newScale, newScale, newScale)
		self._zoom.scale = newScale
		move = true
	end 
	
	if noTouch and not move then
		self:removeEventListener(Event.ENTER_FRAME, goToTarget, self)
	end
end

function zoomTo(self, x, y, zoom)
	local _zoom = self._zoom
	_zoom.targetX, _zoom.targetY, _zoom.currentZoom = x, y, zoom or self:getParent():getScale(X)
	self:addEventListener(Event.ENTER_FRAME, goToTarget, self)
end

function resetZoom(self, scale, x, y, targetX, targetY, targetZoom)
	local _zoom = self._zoom
	x = x or self:getX()
	y = y or self:getY()
	self:setX(x)
	self:setY(y)
	_zoom.scale, _zoom.targetX, _zoom.targetY, _zoom.targetZoom = scale, targetX or x, targetY or y, targetZoom or scale
	self:getParent():setScale(scale, scale, scale)
end

function getZoom(self)
	return self._zoom.scale, self:getX(), self:getY(), self._zoom.targetX, self._zoom.targetY
end

function handleZoom(self, event)
	local scalingHappen, movingHappen = false, false
	local _zoom = self._zoom
	local parent, touchPoints, idTouchExist = self:getParent(), _zoom.touchPoints, _zoom.idTouchExist
	   
	if parent ~= nil and event.type == "mouseWheel" then
		local lx, ly = parent:globalToLocal(event.x, event.y)
		
		local ratio = (360 + event.wheel * 0.5) / 360
		local oldScale = parent:getScaleX()
		local newScale = oldScale * ratio
		if newScale > _zoom.max  then
			newScale = _zoom.max
		elseif newScale < _zoom.min then
			newScale = _zoom.min
		end	
		_zoom.targetZoom = newScale
		
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
		
		if parent ~= nil and event.type == "touchesBegin" then
				
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
 
		elseif parent ~= nil and event.type == "touchesMove" then
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
					_zoom.scale = newScale
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
		elseif parent ~= nil or event.type == "touchesEnd" then
 
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
		if parent:getScaleX() > _zoom.max  then
			_zoom.scale = _zoom.max
			parent:setScale(_zoom.max, _zoom.max, _zoom.max)
		elseif parent:getScaleX() < _zoom.min then
			_zoom.scale = _zoom.min
			parent:setScale(_zoom.min, _zoom.min, _zoom.min)
		end	
	end

	return true
end
 
function attachZoom(scene, minZoom, maxZoom, halfWidth, halfHeight, zoom)
	if currentZoomable then
		currentZoomable:removeEventListener(Event.TOUCHES_BEGIN, handleZoom, scene)
		currentZoomable:removeEventListener(Event.TOUCHES_MOVE, handleZoom, scene)
		currentZoomable:removeEventListener(Event.TOUCHES_END, handleZoom, scene)
		currentZoomable:removeEventListener(Event.MOUSE_WHEEL, handleZoom, scene)
		currentZoomable:removeEventListener(Event.ENTER_FRAME, goToTarget, scene)
	end
	currentZoomable = scene
	scene:addEventListener(Event.TOUCHES_BEGIN, handleZoom, scene)
	scene:addEventListener(Event.TOUCHES_MOVE, handleZoom, scene)
	scene:addEventListener(Event.TOUCHES_END, handleZoom, scene)
	scene:addEventListener(Event.MOUSE_WHEEL, handleZoom, scene)
	
	local halfWidth, halfHeight = halfWidth or scene:getWidth() * 1.5, halfHeight or scene:getHeight() * 1.5
	-- print('halfWidth', halfWidth, 'halfHeight', halfHeight);
	
	-- initialization for Pinch-Zoom
	local parent = scene:getParent()
	if zoom ~= nil then
		parent:setScale(zoom, zoom, zoom)
	else
		zoom = parent:getScaleX()
	end
	scene._zoom = {
		scale = zoom,
		min = minZoom,
		max = maxZoom,
		leftLimit = halfWidth,
		rightLimit = -halfWidth,
		upLimit = halfHeight,
		downLimit = -halfHeight,
		touchPoints = { {}, {} },
		idTouchExist = { false, false },
		oriDeltaTouch = nil,
		oriScale = nil,
		-- for animated translation
		targetX = scene:getX(),
		targetY = scene:getY(),
		targetZoom = zoom,
		-- center of zoom: if one touch, its coordinate, if 2 touch, the middle of the 2 fingers
		x0 = nil,
		y0 = nil,
		-- if pinch-zoom then capture
		capture = false
	};
	scene.resetZoom = resetZoom
	scene.getZoom = getZoom
	scene.zoomTo = zoomTo
end
