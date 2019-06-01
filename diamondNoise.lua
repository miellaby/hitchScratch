
-- generate a noise map layer
-- t: noise square array, l : square side length
-- (x0,y0)-(x3,y3) recursive computed square
--  z0, z1, z2 and z3 : 4 levels at square corners
function generateNoise(t, l, x0, y0, x3, y3, z0, z1, z2, z3)
	--[[
    (x0,y0)
	  z0    p1    z1
	  
         (x5,y5)
	  p2    p5    p3
	  
	  
	  z2    p4    z3
                (x3,y3)
	]]--
	
   local c = x3 - x0
   if c <= 2 then
		_ = x0 % 32 == 0 and y0 % 128 == 0 and yieldMe()
		local zz1 = math.floor((2 * z1 + z0) / 3)
	    local zz2 = math.floor((2 * z2 + z0) / 3)
	    local zz3 = math.floor((2 * z3 + z1 + z2) / 4)
		x3 = x3 - 1
		y3 = y3 - 1
		t[x0 + y0 * l] = z0
		t[x3 + y0 * l] = zz1
		t[x0 + y3 * l] = zz2
		t[x3 + y3 * l] = zz3
	    if x3 < l - 1 then
			t[x3 + 1 + y0 * l] = z1
			t[x3 + 1 + y3 * l] = z3
		end
        if y3 < l - 1 then
			t[x0 + y3 * l + l] = z2
			t[x3 + y3 * l + l] = z3
		end
		
		local z, zb = (z0 < z1 and z0 or z1), (z2 < z3 and z2 or z3)
		return z < zb and z or zb
   end
   
   local x5, y5 = math.floor((x3 + x0) / 2), math.floor((y3 + y0) / 2)
   local tp1 = t[x5 + y0 * l]
   local tp2 = t[x0 + y5 * l]
   local tp3 = x3 == l and t[l - 1 + y5 * l]
   local tp4 = y3 == l and t[x5 + (l - 1) * l]
   local p5 = math.floor((z0 + z1 + z2 + z3) / 4) + math.random(-c, c)
   local p1 = tp1 or (math.floor((z0 + z1) / 2) + math.random(-c, c))
   local p2 = tp2 or (math.floor((z0 + z2) / 2) + math.random(-c, c))
   local p3 = tp3 or (math.floor((z1 + z3) / 2) + math.random(-c, c))
   local p4 = tp4 or (math.floor((z2 + z3) / 2) + math.random(-c, c))
   
   local m0 = generateNoise(t, l, x0, y0, x5, y5,  z0, p1, p2, p5)
   local m1 = generateNoise(t, l, x5, y0, x3, y5,  p1, z1, p5, p3)
   local m2 = generateNoise(t, l, x0, y5, x5, y3,  p2, p5, z2, p4)
   local m3 = generateNoise(t, l, x5, y5, x3, y3,  p5, p3, p4, z3)
   local z, zb = (m0 < m1 and m0 or m1), (m2 < m3 and m2 or m3)
   return z < zb and z or zb
end
