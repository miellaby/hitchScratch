/**
 * HitchScratchChunk - Reusable 3D terrain chunk renderer
 * Pure ES6 module, no dependencies
 */

export class HitchScratchChunk {
  // Default configuration
  static DEFAULT_SIZE = 128;
  static DEFAULT_PIXEL = 2;
  static DEFAULT_FOV = 0.52;
  static DEFAULT_NEAR = 1;
  static DEFAULT_FAR = 2000;
  static DEFAULT_CAM_DIST = 400;
  static DEFAULT_ROT_X = -1.0;
  static DEFAULT_ROT_Z = 0.15;
  static SKY_COLOR = [0.55, 0.78, 0.95];
  static FOG_START = 240.0;
  static FOG_RANGE = 350.0;

  constructor(canvas, options = {}) {
    // Store canvas reference
    this.canvas = canvas;
    this.options = options;

    // Configuration from options with defaults
    this.SIZE = options.size || HitchScratchChunk.DEFAULT_SIZE;
    this.PIXEL = options.pixel || HitchScratchChunk.DEFAULT_PIXEL;
    this.fov = options.fov || HitchScratchChunk.DEFAULT_FOV;
    this.near = options.near || HitchScratchChunk.DEFAULT_NEAR;
    this.far = options.far || HitchScratchChunk.DEFAULT_FAR;

    // Camera state
    this.rotXA = options.rotX !== undefined ? options.rotX : HitchScratchChunk.DEFAULT_ROT_X;
    this.rotZA = options.rotZ !== undefined ? options.rotZ : HitchScratchChunk.DEFAULT_ROT_Z;
    this.camDist = options.camDist !== undefined ? options.camDist : HitchScratchChunk.DEFAULT_CAM_DIST;

    // Auto-orbit mode (for title screen)
    this.autoOrbit = options.autoOrbit || false;
    this.orbitTime = 0;
    this.orbitSpeed = options.orbitSpeed || 1.0;
    this.orbitCamX = 0;
    this.orbitCamY = 0;
    this.orbitCamZ = 0;
    this.orbitRadius = options.orbitRadius || 450;
    this.viewMatrix = null; // Exposed for debugging

    // Animation state
    this.animalOn = options.animalOn !== undefined ? options.animalOn : true;
    this.anX = this.SIZE / 2;
    this.anY = this.SIZE / 2;
    this.anAngle = 0;
    this.anStep = 0;

    // Terrain data
    this.terrain = null;

    // WebGL state
    this.gl = null;
    this.program = null;
    this.buffers = {
      pos: null,
      col: null,
      idx: null
    };
    this.animalBuffers = {
      pos: null,
      col: null,
      idx: null
    };
    this.indexCount = 0;

    // Shader locations
    this.locations = {};

    // Matrix cache
    this.matrices = {
      proj: new Float32Array(16),
      MrX: new Float32Array(16),
      MrZ: new Float32Array(16),
      Mtr: new Float32Array(16),
      tmp: new Float32Array(16),
      mvp: new Float32Array(16),
      mdl: new Float32Array(16),
      anMdl: new Float32Array(16)
    };

    // Timing
    this.t0 = 0;
    this.lastFrameTime = 0;

    // Input state
    this.drag = false;
    this.lastX = 0;
    this.lastY = 0;
    this.pDist = 0;

    // Event callbacks
    this.onInfoUpdate = options.onInfoUpdate || null;
    this.onReady = options.onReady || null;

    // Initialize
    this.initWebGL();
    this.initShaders();
    this.initAnimal();
    this.setupEventListeners();
    this.resizeHandler();

    // Generate initial terrain
    this.regen();
  }

  // ==========================================
  // PUBLIC API
  // ==========================================

  /**
   * Regenerate terrain
   */
  regen() {
    this.terrain = this.buildTerrain();
    this.upload(this.terrain);
    this.anX = this.SIZE / 2;
    this.anY = this.SIZE / 2;
    this.updateInfo();
  }

  /**
   * Toggle animal visibility
   */
  toggleAnimal() {
    this.animalOn = !this.animalOn;
    return this.animalOn;
  }

  /**
   * Set camera rotation X
   */
  setRotX(value) {
    this.rotXA = Math.max(-1.0, Math.min(0, value));
  }

  /**
   * Set camera rotation Z
   */
  setRotZ(value) {
    this.rotZA = value;
  }

  /**
   * Set camera distance
   */
  setCamDist(value) {
    this.camDist = Math.max(200, Math.min(600, value));
  }

  /**
   * Get current terrain layers for continuity
   */
  getTerrainLayers() {
    if (!this.terrain) return null;
    return {
      layer0: this.terrain.layer0,
      layer1: this.terrain.layer1
    };
  }

  /**
   * Clean up resources
   */
  destroy() {
    if (this.gl) {
      Object.values(this.buffers).forEach(b => b && this.gl.deleteBuffer(b));
      Object.values(this.animalBuffers).forEach(b => b && this.gl.deleteBuffer(b));
      if (this.program) this.gl.deleteProgram(this.program);
    }
    if (this.canvas) {
      this.canvas.removeEventListener('mousedown', this.handleMouseDown);
      window.removeEventListener('mouseup', this.handleMouseUp);
      this.canvas.removeEventListener('mousemove', this.handleMouseMove);
      this.canvas.removeEventListener('wheel', this.handleWheel);
      this.canvas.removeEventListener('touchstart', this.handleTouchStart);
      this.canvas.removeEventListener('touchend', this.handleTouchEnd);
      this.canvas.removeEventListener('touchmove', this.handleTouchMove);
    }
    window.removeEventListener('resize', this.handleResize);
  }

  /**
   * Start rendering loop
   */
  start() {
    this.t0 = performance.now();
    requestAnimationFrame(this.render.bind(this));
    if (this.onReady) this.onReady(this);
  }

  // ==========================================
  // TERRAIN GENERATION
  // ==========================================

  /**
   * Diamond-square noise generation
   * Uses seed values if provided for continuity with neighboring chunks
   */
  generateNoise(baseVal, spread, seedValues = null) {
    const N = this.SIZE;
    const gs = N + 1;
    const g = new Float32Array(gs * gs);
    const rand = s => (Math.random() * 2 - 1) * s;

    let z0, z1, z2, z3;
    if (seedValues && seedValues.corners) {
      z0 = seedValues.corners[0] !== undefined ? seedValues.corners[0] : baseVal + rand(spread);
      z1 = seedValues.corners[1] !== undefined ? seedValues.corners[1] : baseVal + rand(spread);
      z2 = seedValues.corners[2] !== undefined ? seedValues.corners[2] : baseVal + rand(spread);
      z3 = seedValues.corners[3] !== undefined ? seedValues.corners[3] : baseVal + rand(spread);
    } else {
      z0 = baseVal + rand(spread);
      z1 = baseVal + rand(spread);
      z2 = baseVal + rand(spread);
      z3 = baseVal + rand(spread);
    }

    g[0] = z0;
    g[N] = z1;
    g[N * gs] = z2;
    g[N * gs + N] = z3;

    if (seedValues && seedValues.edges) {
      const size = this.SIZE;
      for (let i = 0; i < size; i++) {
        if (seedValues.edges.top) g[i * gs] = seedValues.edges.top[i];
        if (seedValues.edges.bottom) g[i * gs + N] = seedValues.edges.bottom[i];
      }
      for (let j = 0; j <= size; j++) {
        if (seedValues.edges.left) g[j * gs] = seedValues.edges.left[j];
        if (seedValues.edges.right) g[j * gs + N] = seedValues.edges.right[j];
      }
    }

    let step = N, scale = spread * 0.7;
    while (step > 1) {
      const half = step >> 1;
      for (let y = 0; y < N; y += step) {
        for (let x = 0; x < N; x += step) {
          const avg = (g[x + y * gs] + g[x + step + y * gs] + 
                      g[x + (y+step) * gs] + g[x + step + (y+step) * gs]) * 0.25;
          g[(x+half) + (y+half) * gs] = avg + rand(scale);
        }
      }
      for (let y = 0; y <= N; y += half) {
        const xStart = ((y / half) % 2 === 0) ? half : 0;
        for (let x = xStart; x <= N; x += step) {
          let sum = 0, cnt = 0;
          if (x-half >= 0) { sum += g[(x-half) + y * gs]; cnt++; }
          if (x+half <= N) { sum += g[(x+half) + y * gs]; cnt++; }
          if (y-half >= 0) { sum += g[x + (y-half) * gs]; cnt++; }
          if (y+half <= N) { sum += g[x + (y+half) * gs]; cnt++; }
          g[x + y * gs] = sum / cnt + rand(scale);
        }
      }
      step = half;
      scale *= 0.5;
    }

    const t = new Float32Array(this.SIZE * this.SIZE);
    for (let y = 0; y < this.SIZE; y++)
      for (let x = 0; x < this.SIZE; x++)
        t[x + y * this.SIZE] = Math.floor(g[x + y * gs]);
    return t;
  }

  /**
   * Get elevation and fluff for a cell
   */
  getElevation(layer0, layer1, x, y) {
    const SIZE = this.SIZE;
    const green = layer0[y * SIZE + x] - 64;
    const level = layer1[y * SIZE + x] - 20;
    let correction = 0, fluff = 0;

    if (level < 30) {
      correction = (level - 30) * 2;
    } else if (level < 90) {
      correction = Math.min(Math.floor(level-30), Math.floor(90-level));
      if (level > 50 && level < 70) correction *= 1.2;
    } else if (level > 200) {
      correction = 200 - level;
    }

    if (green < 0) {
      correction += (-green) * Math.log(-green);
      if (green > -0x33 && level < 200 && (level < 50 || level > 70)) fluff = -green;
    } else if (green < 200 && level < 200 && (level < 40 || level > 80)) {
      correction -= level / 20;
      fluff = Math.max(0, green - 60);
    }

    let z = 250 + level * 3 - correction * 3;
    if (z < 0) z = 50 * z / (50 + z * z);
    const fs = 5;
    if (x < 1 || y < 1 || x >= SIZE-2 || y >= SIZE-2) {
      z = -4000;
    } else if (x < fs || y < fs || x >= SIZE-fs || y >= SIZE-fs) {
      const fall = Math.max(fs-x, fs-y, x-SIZE+fs+1, y-SIZE+fs+1);
      z -= 10 * Math.exp(fall / 3);
    }
    return [z, fluff];
  }

  /**
   * Cell color based on green and level values
   */
  cellColor(green, level) {
    let r, g, b;
    if (level > 200) {
      const v = Math.min(0xBB, level - 200);
      r = 0x44+v; g = 0x44+v; b = 0x44+v;
    } else if (level > 50 && level < 70) {
      const boost = 255 + Math.abs(level-60)*4096;
      r = 0x22;
      g = Math.min(255, 0x44 + boost / 0xFF);
      b = Math.min(255, (0xFF + boost) % 0xFF);
    } else if (level > 40 && level < 80) {
      const v = 21-(Math.abs(level-60)-20);
      r = 0xDD; g = (v * 8) & 0xFF; b = 0x66;
    } else if (green === 155) {
      r = g = b = 0xFF;
    } else if (green > 200) {
      r = 0x22; g = 0x66; b = 0x22;
    } else if (green >= 0) {
      r = 0x22; g = (0xFF - green * 5) & 0xFF; b = 0x22;
    } else {
      r = 0xF0; g = 0x66; b = 0x4D;
    }
    return [r, g, b];
  }

  /**
   * Get edge values from a layer for chunk continuity
   */
  getLayerEdges(layer) {
    const size = this.SIZE;
    const edges = {};
    edges.top = new Float32Array(size);
    for (let x = 0; x < size; x++) edges.top[x] = layer[x];
    edges.bottom = new Float32Array(size);
    const bottomRow = (size - 1) * size;
    for (let x = 0; x < size; x++) edges.bottom[x] = layer[bottomRow + x];
    edges.left = new Float32Array(size + 1);
    for (let y = 0; y <= size; y++) edges.left[y] = layer[y * size];
    edges.right = new Float32Array(size + 1);
    for (let y = 0; y <= size; y++) edges.right[y] = layer[y * size + (size - 1)];
    return edges;
  }

  /**
   * Get corner values from a layer
   */
  getLayerCorners(layer) {
    const size = this.SIZE;
    return [
      layer[0], layer[size - 1],
      layer[(size - 1) * size], layer[size * size - 1]
    ];
  }

  /**
   * Build terrain mesh data
   */
  buildTerrain(seedValues = null) {
    const layer0Seeds = seedValues?.layer0 || null;
    const layer1Seeds = seedValues?.layer1 || null;
    const layer0 = this.generateNoise(140, 20, layer0Seeds);
    const layer1 = this.generateNoise(96, 64, layer1Seeds);
    const CHUNK_SIZE = this.SIZE;
    const verts = [];
    const colors = [];
    const indices = [];

    for (let y = 0; y < CHUNK_SIZE; y += 2) {
      for (let x = 0; x < CHUNK_SIZE; x += 2) {
        const green = layer0[y * this.SIZE + x] - 64;
        const level = layer1[y * this.SIZE + x] - 20;
        const [z, fluff] = this.getElevation(layer0, layer1, x, y);
        const [cr, cg, cb] = this.cellColor(green, level);
        const col = [cr/255, cg/255, cb/255, 1];

        verts.push(x * this.PIXEL, y * this.PIXEL, z * this.PIXEL / 10);
        colors.push(...col);
        verts.push((x + 2) * this.PIXEL, y * this.PIXEL, z * this.PIXEL / 10);
        colors.push(...col);
        verts.push(x * this.PIXEL, (y + 2) * this.PIXEL, z * this.PIXEL / 10);
        colors.push(...col);
        verts.push((x + 2) * this.PIXEL, (y + 2) * this.PIXEL, z * this.PIXEL / 10);
        colors.push(...col);
        const ox = ((7 + Math.floor(Math.random() * 5)) / 10) * this.PIXEL;
        const oy = ((7 + Math.floor(Math.random() * 5)) / 10) * this.PIXEL;
        verts.push(x * this.PIXEL + ox, y * this.PIXEL + oy, (z + fluff) * this.PIXEL / 10);
        colors.push(...col);
      }
    }

    let i = 0;
    for (let y = 0; y < CHUNK_SIZE; y += 2) {
      for (let x = 0; x < CHUNK_SIZE; x += 2) {
        indices.push(i, i+1, i+3);
        indices.push(i+3, i+2, i);
        indices.push(i, i+4, i+3);
        indices.push(i+1, i+2, i+4);
        if (x > 0) {
          const b = i - 5;
          indices.push(b+1, i, i+2);
          indices.push(i+2, b+3, b+1);
        }
        if (y > 0) {
          const b = i - 5 * (CHUNK_SIZE / 2);
          indices.push(b+3, i+1, i);
          indices.push(i, b+2, b+3);
        }
        i += 5;
      }
    }

    return {
      verts, colors, indices,
      layer0, layer1,
      layer0Corners: this.getLayerCorners(layer0),
      layer0Edges: this.getLayerEdges(layer0),
      layer1Corners: this.getLayerCorners(layer1),
      layer1Edges: this.getLayerEdges(layer1)
    };
  }

  // ==========================================
  // WEBGL INIT
  // ==========================================

  initWebGL() {
    this.gl = this.canvas.getContext('webgl') || this.canvas.getContext('experimental-webgl');
    if (!this.gl) throw new Error('WebGL not supported');
    this.gl.enable(this.gl.DEPTH_TEST);
  }

  initShaders() {
    const gl = this.gl;
    const vsrc = `attribute vec3 aPos; attribute vec4 aColor; uniform mat4 uMVP; uniform mat4 uModel; varying vec4 vColor; void main(){ gl_Position = uMVP * uModel * vec4(aPos,1.0); vColor = aColor; }`;
    const fsrc = `precision mediump float; varying vec4 vColor; uniform float uFog; const float FOG_START = 240.0; const float FOG_RANGE = 350.0; void main(){ float fog = clamp((gl_FragCoord.z/gl_FragCoord.w - FOG_START)/FOG_RANGE, 0.0, 1.0) * uFog; gl_FragColor = vec4(mix(vColor.rgb, vec3(0.55, 0.78, 0.95), fog), vColor.a); }`;

    const mkSh = (src, type) => {
      const s = gl.createShader(type);
      gl.shaderSource(s, src);
      gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
        console.error('Shader error:', gl.getShaderInfoLog(s));
        return null;
      }
      return s;
    };

    const vert = mkSh(vsrc, gl.VERTEX_SHADER);
    const frag = mkSh(fsrc, gl.FRAGMENT_SHADER);
    this.program = gl.createProgram();
    gl.attachShader(this.program, vert);
    gl.attachShader(this.program, frag);
    gl.linkProgram(this.program);
    gl.useProgram(this.program);

    this.locations = {
      aPos: gl.getAttribLocation(this.program, 'aPos'),
      aColor: gl.getAttribLocation(this.program, 'aColor'),
      uMVP: gl.getUniformLocation(this.program, 'uMVP'),
      uModel: gl.getUniformLocation(this.program, 'uModel'),
      uFog: gl.getUniformLocation(this.program, 'uFog')
    };
  }

  initAnimal() {
    const gl = this.gl;
    const h = 1, w = 1, d = 2;
    const v = [-h,-w,-d,h,-w,-d,h,w,-d,-h,w,-d, -h,-w,d,h,-w,d,h,w,d,-h,w,d,
              -h,-w,-d,-h,w,-d,-h,w,d,-h,-w,d, h,-w,-d,h,w,-d,h,w,d,h,-w,d,
              -h,-w,-d,h,-w,-d,h,-w,d,-h,-w,d, -h,w,-d,h,w,-d,h,w,d,-h,w,d];
    const cols = [];
    for (let f = 0; f < 6; f++) {
      const c = f === 0 ? [0.9,0.45,0.45,1] : f === 1 ? [0.25,0.75,0.95,1] : [0.2,0.2,0.2,1];
      for (let k = 0; k < 4; k++) cols.push(...c);
    }
    const idx = [];
    for (let f = 0; f < 6; f++) { const b = f*4; idx.push(b,b+1,b+2,b,b+2,b+3); }

    this.animalBuffers.pos = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.animalBuffers.pos);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(v), gl.STATIC_DRAW);
    this.animalBuffers.col = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.animalBuffers.col);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(cols), gl.STATIC_DRAW);
    this.animalBuffers.idx = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.animalBuffers.idx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(idx), gl.STATIC_DRAW);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
  }

  upload(data) {
    const gl = this.gl;
    Object.values(this.buffers).forEach(b => b && gl.deleteBuffer(b));
    const vb = d => { const b = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, b); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(d), gl.STATIC_DRAW); return b; };
    this.buffers.pos = vb(data.verts);
    this.buffers.col = vb(data.colors);
    this.buffers.idx = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.buffers.idx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(data.indices), gl.STATIC_DRAW);
    this.indexCount = data.indices.length;
    gl.bindBuffer(gl.ARRAY_BUFFER, null);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
  }

  // ==========================================
  // MATRIX HELPERS
  // ==========================================

  static m4() { return new Float32Array(16); }
  static ident(m) { m.fill(0); m[0]=m[5]=m[10]=m[15]=1; return m; }
  static mul(o, a, b) { for (let c=0;c<4;c++) for (let r=0;r<4;r++) { o[c*4+r]=0; for (let k=0;k<4;k++) o[c*4+r]+=a[k*4+r]*b[c*4+k]; } return o; }
  static persp(m, fov, asp, n, f) { const t=1/Math.tan(fov/2); m.fill(0); m[0]=t/asp; m[5]=t; m[10]=(f+n)/(n-f); m[11]=-1; m[14]=2*f*n/(n-f); return m; }
  static rx(m, a) { HitchScratchChunk.ident(m); const c=Math.cos(a),s=Math.sin(a); m[5]=c;m[6]=s; m[9]=-s;m[10]=c; return m; }
  static rz(m, a) { HitchScratchChunk.ident(m); const c=Math.cos(a),s=Math.sin(a); m[0]=c;m[1]=s; m[4]=-s;m[5]=c; return m; }
  static tr(m, x, y, z) { HitchScratchChunk.ident(m); m[12]=x;m[13]=y;m[14]=z; return m; }

  /**
   * lookAt view matrix - camera at (eye), looking at (center), up vector (up)
   */
  static lookAt(m, eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ) {
    const fx = centerX - eyeX, fy = centerY - eyeY, fz = centerZ - eyeZ;
    const f_len = Math.sqrt(fx*fx + fy*fy + fz*fz);
    const inv_f = f_len > 0 ? 1/f_len : 0;
    const fnx = fx * inv_f, fny = fy * inv_f, fnz = fz * inv_f;
    const u_len = Math.sqrt(upX*upX + upY*upY + upZ*upZ);
    const inv_u = u_len > 0 ? 1/u_len : 0;
    const unx = upX * inv_u, uny = upY * inv_u, unz = upZ * inv_u;
    const rnx = fny*unz - fnz*uny, rny = fnz*unx - fnx*unz, rnz = fnx*uny - fny*unx;
    const r_len = Math.sqrt(rnx*rnx + rny*rny + rnz*rnz);
    const inv_r = r_len > 0 ? 1/r_len : 0;
    const rnxi = rnx * inv_r, rnyi = rny * inv_r, rnzi = rnz * inv_r;
    const ux = rnyi*fnz - rnzi*fny, uy = rnzi*fnx - rnxi*fnz, uz = rnxi*fny - rnyi*fnx;
    m[0]=rnxi; m[4]=rnyi; m[8]=rnzi; m[12]=-(rnxi*eyeX + rnyi*eyeY + rnzi*eyeZ);
    m[1]=ux;   m[5]=uy;   m[9]=uz;   m[13]=-(ux*eyeX + uy*eyeY + uz*eyeZ);
    m[2]=-fnx; m[6]=-fny; m[10]=-fnz; m[14]=fnx*eyeX + fny*eyeY + fnz*eyeZ;
    m[3]=0;    m[7]=0;    m[11]=0;    m[15]=1;
    return m;
  }

  // ==========================================
  // DRAWING
  // ==========================================

  drawMesh(pb, cb, ib, cnt, mm) {
    const gl = this.gl, loc = this.locations;
    gl.uniformMatrix4fv(loc.uModel, false, mm);
    gl.bindBuffer(gl.ARRAY_BUFFER, pb);
    gl.enableVertexAttribArray(loc.aPos);
    gl.vertexAttribPointer(loc.aPos, 3, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, cb);
    gl.enableVertexAttribArray(loc.aColor);
    gl.vertexAttribPointer(loc.aColor, 4, gl.FLOAT, false, 0, 0);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ib);
    gl.drawElements(gl.TRIANGLES, cnt, gl.UNSIGNED_SHORT, 0);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
  }

  updateInfo() {
    if (this.onInfoUpdate) {
      if (this.autoOrbit) {
        const fx = 0 - this.orbitCamX, fy = 0 - this.orbitCamY, fz = 80 - this.orbitCamZ;
        const f_len = Math.sqrt(fx*fx + fy*fy + fz*fz);
        const d = (f_len > 0 ? 1/f_len : 0);
        let text = `Chunk ${this.SIZE}x${this.SIZE} — overfly | ` +
          `cam:(${this.orbitCamX.toFixed(0)},${this.orbitCamY.toFixed(0)},${this.orbitCamZ.toFixed(0)}) ` +
          `dir:(${fx.toFixed(0)},${fy.toFixed(0)},${fz.toFixed(0)}) ` +
          `dist:${f_len.toFixed(0)}`;
        if (this.terrain) {
          const vc = Math.floor(this.terrain.verts.length / 3);
          const ic = this.terrain.indices.length;
          text += ` | v:${vc} i:${ic}`;
        }
        this.onInfoUpdate(text);
      } else {
        this.onInfoUpdate(`Chunk ${this.SIZE}x${this.SIZE} — manual | rotX:${this.rotXA.toFixed(2)} rotZ:${this.rotZA.toFixed(2)} dist:${this.camDist.toFixed(0)}`);
      }
    }
  }

  // ==========================================
  // CAMERA / OVERFLY - SEPARATED FOR DEBUGGING
  // ==========================================

  /**
   * Compute camera state and view matrix for current frame.
   * Exposed for debugging - inspect this.viewMatrix after calling.
   * Usage: chunk.updateCameraMatrix(dt); console.log(chunk.viewMatrix);
   */
  updateCameraMatrix(dt) {
    if (!this.autoOrbit) {
      this.viewMatrix = null;
      return null;
    }

    const freqX = 1.0, freqY = 1.5;
    const r = this.orbitRadius;

    const cx = Math.sin(this.orbitTime * 0.001 * freqX) * r;
    const cz = -Math.cos(this.orbitTime * 0.001 * freqY) * r - r;
    const d = Math.sqrt(cx*cx + cz*cz);

    const sf = 0.5 + 1.5 * (1 - d/(r*Math.sqrt(2)));
    const h = r * (0.3 + d/(r*1.414) * 0.4);

    this.orbitCamX = cx;
    this.orbitCamY = h;
    this.orbitCamZ = cz;
    this.rotXA = 0; this.rotZA = 0; this.camDist = r;

    this.orbitTime += dt * 1000 * sf;

    this.viewMatrix = HitchScratchChunk.lookAt(
      this.viewMatrix || new Float32Array(16),
      cx, h, cz, 0, 0, 80, 0, 1, 0
    );

    return this.viewMatrix;
  }

  render(ts) {
    requestAnimationFrame(this.render.bind(this));
    this.updateInfo();
    if (!this.terrain || !this.gl || !this.program) return;

    const dt = Math.min((ts - this.t0) / 1000, 0.1);
    this.t0 = ts;

    if (this.canvas.width !== this.canvas.clientWidth || this.canvas.height !== this.canvas.clientHeight)
      this.resizeHandler();

    this.anStep += dt;
    if (this.anStep > 3) {
      this.anStep = 0;
      this.anX = 8 + Math.random() * (this.SIZE - 16);
      this.anY = 8 + Math.random() * (this.SIZE - 16);
    }
    this.anAngle += dt * 0.8;

    const gl = this.gl, loc = this.locations, m = this.matrices;
    gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    gl.clearColor(...HitchScratchChunk.SKY_COLOR, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);

    const cx2d = this.SIZE * this.PIXEL / 2, cy2d = this.SIZE * this.PIXEL / 2;
    HitchScratchChunk.persp(m.proj, this.fov, this.canvas.width / this.canvas.height, this.near, this.far);
    HitchScratchChunk.tr(m.Mtr, -cx2d, -cy2d, 0);

    if (this.autoOrbit) {
      this.updateCameraMatrix(dt);
      HitchScratchChunk.mul(m.tmp, m.proj, this.viewMatrix);
      HitchScratchChunk.mul(m.tmp, m.tmp, m.Mtr);
    } else {
      HitchScratchChunk.rx(m.MrX, this.rotXA);
      HitchScratchChunk.rz(m.MrZ, this.rotZA);
      HitchScratchChunk.tr(m.tmp, 0, -50, -this.camDist);
      HitchScratchChunk.mul(m.mvp, m.tmp, m.MrX);
      HitchScratchChunk.mul(m.tmp, m.mvp, m.MrZ);
      HitchScratchChunk.mul(m.mvp, m.tmp, m.Mtr);
      HitchScratchChunk.mul(m.tmp, m.proj, m.mvp);
    }

    HitchScratchChunk.ident(m.mdl);
    gl.uniformMatrix4fv(loc.uMVP, false, HitchScratchChunk.mul(m.mvp, m.tmp, m.mdl));
    gl.uniform1f(loc.uFog, 1.0);
    this.drawMesh(this.buffers.pos, this.buffers.col, this.buffers.idx, this.indexCount, m.mdl);

    if (this.animalOn) {
      const ax = Math.floor(Math.max(1, Math.min(this.SIZE - 2, this.anX)));
      const ay = Math.floor(Math.max(1, Math.min(this.SIZE - 2, this.anY)));
      const [ez] = this.getElevation(this.terrain.layer0, this.terrain.layer1, ax, ay);
      const screenY = (this.SIZE - 1 - ay) * this.PIXEL;
      const az = -(ez * this.PIXEL / 10 + 2 + Math.abs(Math.sin(this.anAngle)) * 3);
      HitchScratchChunk.ident(m.anMdl);
      const c2 = Math.cos(this.anAngle * 0.4), s2 = Math.sin(this.anAngle * 0.4);
      m.anMdl[0] = c2; m.anMdl[1] = s2; m.anMdl[4] = -s2; m.anMdl[5] = c2;
      m.anMdl[10] = 1; m.anMdl[15] = 1; m.anMdl[12] = ax * this.PIXEL;
      m.anMdl[13] = screenY; m.anMdl[14] = az;
      gl.uniformMatrix4fv(loc.uMVP, false, HitchScratchChunk.mul(m.mvp, m.tmp, m.anMdl));
      gl.uniform1f(loc.uFog, 0.5);
      this.drawMesh(this.animalBuffers.pos, this.animalBuffers.col, this.animalBuffers.idx, 36, m.anMdl);
    }
  }

  // ==========================================
  // EVENT HANDLERS
  // ==========================================

  setupEventListeners() {
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.handleWheel = this.handleWheel.bind(this);
    this.handleTouchStart = this.handleTouchStart.bind(this);
    this.handleTouchEnd = this.handleTouchEnd.bind(this);
    this.handleTouchMove = this.handleTouchMove.bind(this);
    this.handleResize = this.resizeHandler.bind(this);

    if (!this.autoOrbit) {
      this.canvas.addEventListener('mousedown', this.handleMouseDown);
      window.addEventListener('mouseup', this.handleMouseUp);
      this.canvas.addEventListener('mousemove', this.handleMouseMove);
      this.canvas.addEventListener('wheel', this.handleWheel, { passive: false });
      this.canvas.addEventListener('touchstart', this.handleTouchStart, { passive: false });
      this.canvas.addEventListener('touchend', this.handleTouchEnd);
      this.canvas.addEventListener('touchmove', this.handleTouchMove, { passive: false });
    }
    window.addEventListener('resize', this.handleResize);
  }

  handleMouseDown(e) { this.drag = true; this.lastX = e.clientX; this.lastY = e.clientY; e.preventDefault(); }
  handleMouseUp() { this.drag = false; }
  handleMouseMove(e) {
    if (!this.drag) return;
    this.rotZA += (e.clientX - this.lastX) * 0.005; this.rotXA += (e.clientY - this.lastY) * 0.005;
    this.rotXA = Math.max(-1.0, Math.min(0, this.rotXA));
    this.lastX = e.clientX; this.lastY = e.clientY;
  }
  handleWheel(e) { this.camDist = Math.max(200, Math.min(600, this.camDist + e.deltaY * 0.3)); e.preventDefault(); }
  handleTouchStart(e) {
    if (e.touches.length === 2) {
      const dx = e.touches[0].clientX - e.touches[1].clientX;
      const dy = e.touches[0].clientY - e.touches[1].clientY;
      this.pDist = Math.sqrt(dx*dx + dy*dy);
    } else { this.drag = true; this.lastX = e.touches[0].clientX; this.lastY = e.touches[0].clientY; }
    e.preventDefault();
  }
  handleTouchEnd() { this.drag = false; }
  handleTouchMove(e) {
    if (e.touches.length === 2) {
      const dx = e.touches[0].clientX - e.touches[1].clientX;
      const dy = e.touches[0].clientY - e.touches[1].clientY;
      const d = Math.sqrt(dx*dx + dy*dy);
      this.camDist = Math.max(200, Math.min(600, this.camDist - (d - this.pDist) * 0.5));
      this.pDist = d;
    } else if (this.drag) {
      this.rotZA += (e.touches[0].clientX - this.lastX) * 0.005;
      this.rotXA += (e.touches[0].clientY - this.lastY) * 0.005;
      this.rotXA = Math.max(-1.0, Math.min(0, this.rotXA));
      this.lastX = e.touches[0].clientX; this.lastY = e.touches[0].clientY;
    }
    e.preventDefault();
  }

  resizeHandler() {
    const w = this.canvas.clientWidth, h = this.canvas.clientHeight;
    this.canvas.width = w; this.canvas.height = h;
  }
}

export default HitchScratchChunk;
