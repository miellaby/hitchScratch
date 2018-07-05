local canvas = RenderTarget.new(CHUNCK_SIZE, CHUNCK_SIZE)
local mesh = Mesh.new()
canvas:clear(0, 0)
canvas:draw(mesh, 0, 0)
