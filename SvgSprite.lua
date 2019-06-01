SvgSprite = Core.class(Sprite)
function SvgSprite:init(model)
	local sprite, p = self, nil
	p = Path2D.new()
	p:setSvgPath(model.p1) --Set the path from a SVG path description
	p:setFillColor(model.c1) --Fill color
	p:setLineThickness(0) -- Outline width
	p:setAnchorPosition(model.x1, model.y1)
	sprite:addChild(p);
	p = Path2D.new()
	p:setSvgPath(model.p2) --Set the path from a SVG path description
	p:setFillColor(model.c2) --Fill color
	p:setLineThickness(0) -- Outline width
	p:setAnchorPosition(model.x2, model.y2)
	sprite:addChild(p);
	p = Path2D.new()
	p:setSvgPath(model.p3) --Set the path from a SVG path description
	p:setFillColor(model.c3) --Fill color
	p:setLineThickness(0) -- Outline width
	p:setAnchorPosition(model.x3, model.y3)
	sprite:addChild(p);
	return sprite;
end
