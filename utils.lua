function yieldMe()
	if coroutine.running() then
		-- print('yield')
		coroutine.yield()
	end
end
