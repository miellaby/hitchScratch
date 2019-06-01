-- lib to define and manage current app state
-- every state has a scene and event callback
-- known gameStates:
-- world
-- debug
-- overfly

-- set of states
gameStates = {}

-- starting state
gameStates.start = {
	name = "start",
	before = nil,
	after = nil,
	iterate = nil,
	scene = nil
}

-- current state
gameState = gameStates.start

function setGameState(newState)
	if newState == gameState then return end
	_ = gameState.scene and zoomArea:removeChild(gameState.scene)
	if newState.scene then
		zoomArea:addChild(newState.scene)
		attachZoom(newState.scene, 0.2, 1.5)
	end
	gameState = newState
end

local iteration = 0
stage:addEventListener(Event.ENTER_FRAME, function()
	iteration = iteration + 1
	_ = gameState.iterate and gameState.iterate()
end)
