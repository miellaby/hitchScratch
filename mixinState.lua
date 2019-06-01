-- à utiliser sur un sprite pour lui ajouter un aspect animable par états

function mixinState(sprite)
	self = sprite
	self._states, self.state, self._nextState = {}, nil, nil;
	function sprite:addState(stateId, state)
		state.stateId = stateId
		self._states[stateId] = state
	end
	
	function sprite:setState(stateId)
		self._stateRoutine = coroutine.create(function()
			local currentState = self.state;
			if currentState.leave ~= nil then
				if currentState.leave(self) == false then return end
				coroutine.yield()
			end
			if currentState.enter ~= nil then
				if currentState.enter(self) == false then return end
				coroutine.yield()
			end
			local newState = self._states[stateId];		
			self._nextState = newState;
			
			self.state = newState;
			
			if currentState.leaved ~= nil then
				currentState.leaved(self)
				coroutine.yield()
			end
			if currentState.entered ~= nil then
				currentState.entered(self)
				coroutine.yield()
			end
			self._stateRoutine = nil
		end)
	end
	
end
