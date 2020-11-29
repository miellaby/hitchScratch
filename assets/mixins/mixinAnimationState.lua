-- à utiliser sur un sprite pour lui ajouter un aspect animable par états
mixinAnimationState = Core.class()
function mixinAnimationState.mixin(class)
	class.setState = mixinAnimationState.setState
	class.animate  = mixinAnimationState.animate
end

function mixinAnimationState:setState(state)
	if state == nil then
		print('state issue')
		return
	end
	print("setState", state.name)
	local lastState = self.state
	if lastState ~= nil then
		if lastState.animate ~= nil then
			self:removeEventListener(Event.ENTER_FRAME, self.animate, self)
		end
		_ = lastState.leave ~= nil and lastState.leave(self, state)
	end
	self.state = state
	self.iteration = 0
	if state.animate ~= nil then
		self:addEventListener(Event.ENTER_FRAME, self.animate, self)
	end
	_ = state.enter ~= nil and state.enter(self, lastState)
end

function mixinAnimationState:animate()
	local lastState = self.state
	lastState.animate(self, self.iteration)
	if self.state == lastState then
		self.iteration = self.iteration + 1
	end
end
