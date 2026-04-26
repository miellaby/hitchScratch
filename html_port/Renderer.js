/**
 * Renderer - WebGL rendering engine
 * Can render multiple objects (chunks, animals, etc.) with a camera
 */

import { Mesh } from './Mesh.js';

export class Renderer {
  constructor(canvas, options = {}) {
    this.canvas = canvas;
    this.gl = null;
    this.program = null;
    this.objects = []; // Array of { mesh, modelMatrix, isAnimal }
    this.camera = null;
    this.terrainChunk = options.terrainChunk || null;
    this.fogColor = options.fogColor || [0.55, 0.78, 0.95];
    this.fogStart = options.fogStart || 1040.0;
    this.fogRange = options.fogRange || 1050.0;
    this.onInfoUpdate = options.onInfoUpdate || null;
    this.onReady = options.onReady || null;

    // Matrix cache
    this.matrices = {
      proj: new Float32Array(16),
      view: new Float32Array(16),
      model: new Float32Array(16),
      mvp: new Float32Array(16)
    };

    // Timing
    this.t0 = 0;
    this.lastFrameTime = 0;
    this.animationTime = 0;

    // Input
    this.drag = false;
    this.lastX = 0; this.lastY = 0; this.pDist = 0;

    this.init();
  }

  init() {
    this.gl = this.canvas.getContext('webgl') || this.canvas.getContext('experimental-webgl');
    if (!this.gl) throw new Error('WebGL not supported');
    
    this.gl.enable(this.gl.DEPTH_TEST);
    this.initShaders();
    this.setupEventListeners();
    this.resizeHandler();
  }

  initShaders() {
    const gl = this.gl;
    const vsrc = `attribute vec3 aPos; attribute vec4 aColor; uniform mat4 uMVP; varying vec4 vColor; void main(){ gl_Position = uMVP * vec4(aPos,1.0); vColor = aColor; }`;
    const fsrc = `precision mediump float; varying vec4 vColor; uniform float uFog; uniform float uFogStart; uniform float uFogRange; void main(){ float fog = clamp((gl_FragCoord.z/gl_FragCoord.w - uFogStart)/uFogRange, 0.0, 1.0) * uFog; gl_FragColor = vec4(mix(vColor.rgb, vec3(0.55, 0.78, 0.95), fog), vColor.a); }`;

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
      uFog: gl.getUniformLocation(this.program, 'uFog'),
      uFogStart: gl.getUniformLocation(this.program, 'uFogStart'),
      uFogRange: gl.getUniformLocation(this.program, 'uFogRange')
    };
  }



  setCamera(camera) {
    this.camera = camera;
    if (camera && this.canvas.width > 0 && this.canvas.height > 0) {
      camera.setAspect(this.canvas.width, this.canvas.height);
    }
    return this;
  }

  addObject(meshOrObj, modelMatrix = null) {
    // If meshOrObj already has mesh and modelMatrix properties, use it directly
    if (meshOrObj && meshOrObj.mesh && meshOrObj.modelMatrix) {
      this.objects.push(meshOrObj);
    } else {
      this.objects.push({ mesh: meshOrObj, modelMatrix: modelMatrix || new Float32Array(16) });
    }
    return this;
  }

  removeObject(mesh) {
    this.objects = this.objects.filter(o => o.mesh !== mesh);
    return this;
  }

  clearObjects() {
    this.objects = [];
    return this;
  }

  // ========== RENDERING ==========

  drawMesh(pb, cb, ib, cnt, mm) {
    const gl = this.gl, loc = this.locations;
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

  render(ts) {
    requestAnimationFrame(this.render.bind(this));
    
    if (!this.camera || this.objects.length === 0) {
      this.gl.clearColor(...this.fogColor, 1);
      this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
      return;
    }

    // Handle resize
    if (this.canvas.width !== this.canvas.clientWidth || this.canvas.height !== this.canvas.clientHeight)
      this.resizeHandler();

    // Update camera
    const dt = Math.min((ts - this.t0) / 1000, 0.1);
    this.t0 = ts;
    if (this.camera.mode === 'orbit') {
      this.camera.updateOrbit(dt);
    }

    // Update animation
    this.animationTime += dt;

    // Compute matrices
    const m = this.matrices;
    this.camera.computeProjectionMatrix();
    this.camera.computeViewMatrix();
    
    const gl = this.gl;
    gl.viewport(0, 0, this.canvas.width, this.canvas.height);
    gl.clearColor(...this.fogColor, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);
    


    // Copy projection to our cache
    m.proj.set(this.camera.projMatrix);
    m.view.set(this.camera.viewMatrix);

    // Update any objects that have an update method
    for (const obj of this.objects) {
      if (obj.update && typeof obj.update === 'function') {
        obj.update(dt, this);
      }
    }

    // Render each object
    const ident = m => { m.fill(0); m[0]=m[5]=m[10]=m[15]=1; return m; };
    const mul = Renderer.mul;

    for (const obj of this.objects) {
      // Model matrix for this object (centered at origin by default)
      if (!obj.modelMatrix) obj.modelMatrix = ident(new Float32Array(16));
      
      // MVP = proj * view * model
      // Use temp to avoid aliasing issue with mul
      mul(m.mvp, m.proj, m.view);
      const tmpMvp = new Float32Array(16);
      mul(tmpMvp, m.mvp, obj.modelMatrix);
      m.mvp.set(tmpMvp);
      
      // Draw
      gl.uniformMatrix4fv(this.locations.uMVP, false, m.mvp);
      gl.uniform1f(this.locations.uFog, 1.0);
      gl.uniform1f(this.locations.uFogStart, this.fogStart);
      gl.uniform1f(this.locations.uFogRange, this.fogRange);
      this.drawMesh(obj.mesh.posBuf, obj.mesh.colBuf, obj.mesh.idxBuf, obj.mesh.idxCount, obj.modelMatrix);
    }

    // Update info
    if (this.onInfoUpdate && this.camera) {
      const text = this.camera.mode === 'orbit'
        ? `Orbit | cam:(${this.camera.position[0].toFixed(0)},${this.camera.position[1].toFixed(0)},${this.camera.position[2].toFixed(0)})`
        : `Manual | rotX:${this.camera.rotX.toFixed(2)} rotZ:${this.camera.rotZ.toFixed(2)} dist:${this.camera.distance.toFixed(0)}`;
      this.onInfoUpdate(text + ` | objs:${this.objects.length}`);
    }
  }

  start() {
    this.t0 = performance.now();
    requestAnimationFrame(this.render.bind(this));
    if (this.onReady) this.onReady(this);
    return this;
  }

  // ========== UTILITIES ==========

  setupEventListeners() {
    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseUp = this.handleMouseUp.bind(this);
    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.handleWheel = this.handleWheel.bind(this);
    this.handleTouchStart = this.handleTouchStart.bind(this);
    this.handleTouchEnd = this.handleTouchEnd.bind(this);
    this.handleTouchMove = this.handleTouchMove.bind(this);
    this.handleResize = this.resizeHandler.bind(this);

    this.canvas.addEventListener('mousedown', this.handleMouseDown);
    window.addEventListener('mouseup', this.handleMouseUp);
    this.canvas.addEventListener('mousemove', this.handleMouseMove);
    this.canvas.addEventListener('wheel', this.handleWheel, { passive: false });
    this.canvas.addEventListener('touchstart', this.handleTouchStart, { passive: false });
    this.canvas.addEventListener('touchend', this.handleTouchEnd);
    this.canvas.addEventListener('touchmove', this.handleTouchMove, { passive: false });
    window.addEventListener('resize', this.handleResize);
  }

  handleMouseDown(e) { this.drag = true; this.lastX = e.clientX; this.lastY = e.clientY; e.preventDefault(); }
  handleMouseUp() { this.drag = false; }
  handleMouseMove(e) {
    if (!this.drag || !this.camera) return;
    const camera = this.camera;
    camera.rotZ += (e.clientX - this.lastX) * 0.005;
    camera.rotX += (e.clientY - this.lastY) * 0.005;
    camera.rotX = Math.max(-1.0, Math.min(0, camera.rotX));
    this.lastX = e.clientX; this.lastY = e.clientY;
  }
  handleWheel(e) {
    if (this.camera) {
      this.camera.distance = Math.max(200, Math.min(600, this.camera.distance + e.deltaY * 0.3));
    }
    e.preventDefault();
  }
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
    if (e.touches.length === 2 && this.camera) {
      const dx = e.touches[0].clientX - e.touches[1].clientX;
      const dy = e.touches[0].clientY - e.touches[1].clientY;
      const d = Math.sqrt(dx*dx + dy*dy);
      this.camera.distance = Math.max(200, Math.min(600, this.camera.distance - (d - this.pDist) * 0.5));
      this.pDist = d;
    } else if (this.drag && this.camera) {
      this.camera.rotZ += (e.touches[0].clientX - this.lastX) * 0.005;
      this.camera.rotX += (e.touches[0].clientY - this.lastY) * 0.005;
      this.camera.rotX = Math.max(-1.0, Math.min(0, this.camera.rotX));
      this.lastX = e.touches[0].clientX; this.lastY = e.touches[0].clientY;
    }
    e.preventDefault();
  }

  resizeHandler() {
    const w = this.canvas.clientWidth, h = this.canvas.clientHeight;
    this.canvas.width = w; this.canvas.height = h;
    if (this.camera) this.camera.setAspect(w, h);
  }

  destroy() {
    if (this.gl) {
      if (this.program) this.gl.deleteProgram(this.program);
      this.animalBuffers.pos && this.gl.deleteBuffer(this.animalBuffers.pos);
      this.animalBuffers.col && this.gl.deleteBuffer(this.animalBuffers.col);
      this.animalBuffers.idx && this.gl.deleteBuffer(this.animalBuffers.idx);
      this.objects.forEach(obj => {
        obj.mesh.posBuf && this.gl.deleteBuffer(obj.mesh.posBuf);
        obj.mesh.colBuf && this.gl.deleteBuffer(obj.mesh.colBuf);
        obj.mesh.idxBuf && this.gl.deleteBuffer(obj.mesh.idxBuf);
      });
    }
    this.canvas.removeEventListener('mousedown', this.handleMouseDown);
    window.removeEventListener('mouseup', this.handleMouseUp);
    this.canvas.removeEventListener('mousemove', this.handleMouseMove);
    this.canvas.removeEventListener('wheel', this.handleWheel);
    this.canvas.removeEventListener('touchstart', this.handleTouchStart);
    this.canvas.removeEventListener('touchend', this.handleTouchEnd);
    this.canvas.removeEventListener('touchmove', this.handleTouchMove);
    window.removeEventListener('resize', this.handleResize);
  }

  // ========== STATIC HELPERS ==========

  static mul(o, a, b) {
    for (let c = 0; c < 4; c++)
      for (let r = 0; r < 4; r++) {
        o[c*4+r] = 0;
        for (let k = 0; k < 4; k++)
          o[c*4+r] += a[k*4+r] * b[c*4+k];
      }
    return o;
  }
}

export default Renderer;
