-- lib to define and manage current app state
-- every state has a scene and event callback
-- known gameStates:
-- world
-- debug
-- overfly

game = stage
mixinAnimationState.mixin(game)

-- set of states
game.State = {}

-- starting state
game.State.START = {
	name = "start"
}


-- current state
function game:setScene(scene)
	if zoomArea:getNumChildren() > 0 then
		zoomArea:removeChildAt(1)
	end
	if scene ~= nil then
		zoomArea:addChild(scene)
		attachZoom(scene, 0.5, 2, application:getLogicalWidth() * 1.5, application:getLogicalHeight() * 1.5, 1)
	end
end

game:setState(game.START)
