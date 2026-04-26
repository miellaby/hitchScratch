/**
 * Animal - Creature entity for the world
 * Generates animal geometry and manages its model matrix
 */

import { Mesh } from './Mesh.js';

export class Animal {
  constructor(gl, options = {}) {
    this.gl = gl;
    this.scale = options.scale || 0.5;
    this.mesh = null;
    this.modelMatrix = new Float32Array(16);
    this.anX = options.anX !== undefined ? options.anX : 64;
    this.anY = options.anY !== undefined ? options.anY : 64;
    this.anAngle = options.anAngle !== undefined ? options.anAngle : 0;
    this.anStep = options.anStep !== undefined ? options.anStep : 0;
    this.animalOn = options.animalOn !== undefined ? options.animalOn : true;
    
    this.initMesh();
  }

  initMesh() {
    const h = 1 * this.scale, w = 1 * this.scale, d = 2 * this.scale;
    
    // Vertex positions for 6 faces of a rectangular prism
    // Each face is defined by 4 vertices (x,y,z)
    const v = [
      // Bottom face (-d)
      -h,-w,-d,  h,-w,-d,  h,w,-d,  -h,w,-d,
      // Top face (+d)
      -h,-w,d,   h,-w,d,   h,w,d,   -h,w,d,
      // Front face (-w)
      -h,-w,-d,  -h,-w,d,  h,-w,d,   h,-w,-d,
      // Back face (+w)
      -h,w,-d,   h,w,-d,   h,w,d,   -h,w,d,
      // Left face (-h) - wait, need to be careful with winding
      -h,-w,-d,  -h,w,-d,  -h,w,d,  -h,-w,d,
      // Right face (+h)
      h,-w,-d,   h,w,-d,   h,w,d,   h,-w,d
    ];
    
    // Colors per face: front=red, back=light blue, rest=dark gray
    const cols = [];
    for (let f = 0; f < 6; f++) {
      const c = f === 0 ? [0.9,0.45,0.45,1] : f === 1 ? [0.25,0.75,0.95,1] : [0.2,0.2,0.2,1];
      for (let k = 0; k < 4; k++) cols.push(...c);
    }
    
    // Indices: 2 triangles per quad face
    const idx = [];
    for (let f = 0; f < 6; f++) { 
      const b = f * 4; 
      idx.push(b, b+1, b+2, b, b+2, b+3); 
    }
    
    this.mesh = new Mesh(this.gl, v, cols, idx);
    this.mesh.isAnimal = true;
  }

  update(dt, renderer) {
    if (!this.animalOn || !this.mesh || !renderer || !renderer.terrainChunk) return;
    
    const terrainChunk = renderer.terrainChunk;
    const SIZE = 128, PIXEL = 2;
    const ax = Math.floor(Math.max(1, Math.min(SIZE-2, this.anX)));
    const ay = Math.floor(Math.max(1, Math.min(SIZE-2, this.anY)));
    
    // Get terrain elevation at animal position
    const [z, fluff] = terrainChunk.getElevation(terrainChunk.layer0, terrainChunk.layer1, ax, ay);
    const animalHeight = (z) * PIXEL / 10 + 0;
    
    // Update animal animation time
    this.anAngle += dt * 2.0;
    this.anStep += dt;
    if (this.anStep > 3) {
      this.anStep = 0;
      this.anX = 8 + Math.random() * (SIZE - 16);
      this.anY = 8 + Math.random() * (SIZE - 16);
    }
    
    // Build model matrix: rotation + position
    const ident = m => { m.fill(0); m[0]=m[5]=m[10]=m[15]=1; return m; };
    ident(this.modelMatrix);
    const c = Math.cos(this.anAngle), s = Math.sin(this.anAngle);
    this.modelMatrix[0] = c; this.modelMatrix[1] = s; 
    this.modelMatrix[4] = -s; this.modelMatrix[5] = c;
    this.modelMatrix[10] = 1; this.modelMatrix[15] = 1;
    this.modelMatrix[12] = ax * PIXEL - (SIZE * PIXEL / 2);
    this.modelMatrix[13] = ay * PIXEL - (SIZE * PIXEL / 2);
    this.modelMatrix[14] = animalHeight;
  }

  setPosition(x, y) {
    this.anX = x;
    this.anY = y;
  }

  setScale(scale) {
    this.scale = scale;
    // Would need to regenerate mesh with new scale
  }

  destroy() {
    if (this.mesh) {
      this.mesh.destroy();
      this.mesh = null;
    }
  }
}
