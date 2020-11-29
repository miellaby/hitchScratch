-- à utiliser sur un sprite pour lui ajouter un aspect animable par états

function mixinState(sprite)
	self = sprite
	self.state, self._nextState = {}, nil, nil;

	
	function sprite:setState(state)
		self._stateRoutine = coroutine.create(function()
			local currentState = self.state;
			if currentState.leave ~= nil then
				if currentState.leave(self, state) == false then return Fend
				coroutine.yield()
			end
			if currentState.enter ~= nil then
				if currentState.enter(self) == false then return end
				coroutine.yield()
			end
			local newState = state;		
			self.state = newState;
			
			if currentState.leaved ~= nil then
				currentState.leaved(self, state)
				coroutine.yield()
			end
			if newState.entered ~= nil then
				newState.entered(self, currentState)
				coroutine.yield()
			end
			self._stateRoutine = nil
		end)
	end
	
end
