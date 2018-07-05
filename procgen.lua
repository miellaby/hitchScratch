function procgen(t, l, x0, y0, x3, y3, z0, z1, z2, z3)
	--[[
    (x0,y0)
	  z0    p1    z1
	  
         (x5,y5)
	  p2    p5    p3
	  
	  
	  z2    p4    z3
                (x3,y3)
	]]--
	
   local c = (x3 - x0)
   if c <= 2 then
	    local zz1 = math.floor((2 * z1 + z0) / 3)
	    local zz2 = math.floor((2 * z2 + z0) / 3)
	    local zz3 = math.floor((2 * z3 + z1 + z2) / 4)
		x3 = x3 - 1
		y3 = y3 - 1
		t[x0 + y0 * l] = z0
		t[x3 + y0 * l] = zz1
		t[x0 + y3 * l] = zz2
		t[x3 + y3 * l] = zz3
	    if x3 < l then
			t[x3 + 1 + y0 * l] = z1
			t[x3 + 1 + y3 * l] = z3
		end
        if y3 < l then
			t[x0 + y3 * l + l] = z2
			t[x3 + y3 * l + l] = z3
		end
		
		local z, zb = (z0 < z1 and z0 or z1), (z2 < z3 and z2 or z3)
		return z < zb and z or zb
   end
   
   local x5, y5 = math.floor((x3 + x0) / 2), math.floor((y3 + y0) / 2)
   local tp1 = t[x5 + y0 * l]
   local tp2 = t[x0 + y5 * l]

   local p5 = math.floor((z0 + z1 + z2 + z3) / 4) + math.random(-c, c)
   local p1 = tp1 or (math.floor((z0 + z1) / 2) + math.random(-c, c))
   local p2 = tp2 or (math.floor((z0 + z2) / 2) + math.random(-c, c))
   -- p1 = tp1 and (tp1 + 2 * p1) / 3 or p1
   -- p2 = tp2 and (tp2 + 2 * p2) / 3 or p2
   local p3 = math.floor((z1 + z3) / 2 + math.random(-c, c))
   local p4 = math.floor((z2 + z3) / 2 + math.random(-c, c))
   -- t[x5 + y0 * l] = p1
   -- t[x0 + y5 * l] = p2
   -- if x3 < 128 then t[x3 + y5 * l] = p3 end
   -- if y3 < 128 then t[x5 + y3 * l] = p4 end
   
   local m0 = procgen(t, l, x0, y0, x5, y5,  z0, p1, p2, p5)
   local m1 = procgen(t, l, x5, y0, x3, y5,  p1, z1, p5, p3)
   local m2 = procgen(t, l, x0, y5, x5, y3,  p2, p5, z2, p4)
   local m3 = procgen(t, l, x5, y5, x3, y3,  p5, p3, p4, z3)
   local z, zb = (m0 < m1 and m0 or m1), (m2 < m3 and m2 or m3)
   return z < zb and z or zb
end

function procgen_2(t, l, x0, y0, x3, y3, average, up, right, bottom, left)
    average = average or math.random(1, 255)
    local c = (x3 - x0) / 2
	local noise_min, noise_max = average - c > 0 and -c or -c + average, c 
	local noise0 = math.random(noise_min, noise_max)
	local noise1 = math.random(noise_min, noise_max)
	
	local zup, zright, zbottom, zleft
	
	if up then
		zup, _, _, z0_up, z1_up = unpack(up)
	else
		zup = average + noise0
	end
	if right then
		zright, z1_right, _, z3_right, _ = unpack(right)
	else
		zright = average + noise1 ; -- + math.random(noise_min, noise_max)
	end
	if bottom then
		zbottom, z2_bottom, z3_bottom, _, _ = unpack(bottom)
	else
		zbottom = average - noise0 ; -- + math.random(noise_min, noise_max)
	end
	if left then
		zleft, _, z0_left, _, z2_left = unpack(left)
	else 
		zleft = average - noise1 ; -- + math.random(noise_min, noise_max)
	end
	local z0_up, z1_up = z0_up or { zup }, z1_up or { zup }
	local z1_right, z3_right = z1_right or { zright }, z3_right or { zright }
	local z2_bottom, z3_bottom = z2_bottom or { zbottom }, z3_bottom or { zbottom }
	local z0_left, z2_left = z0_left or { zleft }, z2_left or { zleft }
	
    --[[
	             up
        (x0,y0)
            z0	      z1 
                average
    left       (x5,y5)     right
	  
	       z2        z3   
                      (x3,y3)
	          bottom    
	]]--
	local z0, z1, z2, z3
   if math.random(2) == 1 then
	   z0 = math.floor((3 * zleft + zright) / 4)
	   z1 = math.floor((3 * zright + zleft) / 4)
	   z2 = math.floor((z0 + zbottom) / 2)
	   z3 = math.floor((z2 + zbottom) / 2)
   else
	   z0 = math.floor((3 * zup + zbottom) / 4)
	   z2 = math.floor((3 * zbottom + zup) / 4)
	   z1 = math.floor((z0 + zright) / 2)
	   z3 = math.floor((z2 + zright) / 2)
   end
   -- local z0 = math.floor((3 * z0_left[1] + z1_right[1] + 3 * z0_up[1] + z2_bottom[1]) / 8) + math.random(-c, c)
   -- local z1 = math.floor((3 * z1_right[1] + z0_left[1] + 3 * z1_up[1] + z3_bottom[1]) / 8) + math.random(-c, c)
   -- local z2 = math.floor((3 * z2_left[1] + z3_right[1] + 3 * z2_bottom[1] + z0_up[1]) / 8) + math.random(-c, c)
   -- local z3 = math.floor((3 * z3_right[1] + z2_left[1] + 3 * z3_bottom[1] + z1_up[1]) / 8) + math.random(-c, c)
   if c == 1 then
		if x0 == 8 and y0 == 2 then print(zup, z0_up[1], zright, zbottom, zleft) end
		x3 = x3 - 1
		y3 = y3 - 1
		t[x0 + y0 * l] = z0
		t[x3 + y0 * l] = z1
		t[x0 + y3 * l] = z2
		t[x3 + y3 * l] = z3
		-- return { average }
		return { average, { z0 }, { z1 }, { z2 }, { z3 } }
		-- return { (z0 + z1 + z2 + z3) / 4 }
		-- return { z0, z0, z1, z1, z2, z2, z3, z3 }
   end
   
   local x5, y5 = math.floor((x3 + x0) / 2), math.floor((y3 + y0) / 2)
   

   -- procgen_2(t, l, x0, y0, x3, y3, average, up, right, bottom, left)
	
   local a0 = procgen_2(t, l, x0, y0, x5, y5,  z0, z0_up, { z1 }, { z2 }, z0_left)   
   local a1 = procgen_2(t, l, x5, y0, x3, y5,  z1, z1_up, z1_right, { z3 }, a0)
   local a2 = procgen_2(t, l, x0, y5, x5, y3,  z2, a0, { z3 }, z2_bottom, z2_left)
   local a3 = procgen_2(t, l, x5, y5, x3, y3,  z3, a1, z3_right, z3_bottom, a2)
   return { (z0 + z1 + z2 + z3) / 4, a0, a1, a2, a3 }
end


local px = {}

local gen = Sprite.new()
function drawgen(t, w, h, options) 
	for y=0,h-1 do
        for x=0,w-1 do
			local pp = px[y * w + x]
			if not pp then
			   pp = Pixel.new(0, 2, 2)
			   px[y * w + x] = pp
			   pp:setPosition(x * 2 - 2, y * 2)
				gen:addChild(pp)
			end
			-- print(x, y)
            local level = (t[y * w + x] - 64)
			if level == 155 then
				color = 0xFFFFFF
			elseif level < options.water then
				color = 0x22FF22 - ((options.water  - level) / 2) & 127 << 8
			elseif level < options.sand then
				color = 0x224400
			else
				color = 0x000000 + (level << 8)
			end
            pp:setColor(color)
		end
    end
    return gen
end

function draw2gen(t1, t2, w, h, options) 
	for y=0,h-1 do
        for x=0,w-1 do
			local pp = px[y * w + x]
			if not pp then
			   pp = Pixel.new(0, 2, 2)
			   px[y * w + x] = pp
			   pp:setPosition(x * 2 - 2, y * 2)
				gen:addChild(pp)
			end
			-- print(x, y)
            local level = (t1[y * w + x] - 64)
            local density = (t2[y * w + x] - 20)
			if density > 200 then
				color = (density - 200)
				color = 0x444444 + color + color << 8 + color << 16
			elseif density > 50 and density < 70 then
				color = 0x0000FF + (math.abs(density - 60) << 11)
			elseif density > 40 and density < 80 then
				local v = 20 - (math.abs(density - 60) - 20)
				--
				color = (v << 11) | 0xFF0000
				-- color = (0xFF0000 - (v << 20)) | (0x00FF00 - (v << 12))
			elseif density > math.random(120, 200) and density < math.random(0, 150) then
				color = 0xFF2200
			else
				local correction = 0
				if density > 30 then
					correction = math.floor((density - 30) / 2)
				elseif density < 90 then
					correction = math.floor((90 - density) / 2) 
				end
				level = level + correction
				if level == 155 then
					color = 0xFFFFFF
				elseif level < options.water then
					color = 0x22FF22 - ((options.water  - level) / 2) & 127 << 8
				elseif level < options.sand then
					color = 0x224400
				elseif level > 200 then
					color = 0x226622
				else
					color = 0x00FF00 - (math.floor(level * 0.9) << 8)
				end
			end
            pp:setColor(color)
		end
    end
   return gen
end

