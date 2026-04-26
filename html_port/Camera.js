/**
 * Camera - View parameters only, no rendering
 * Represents camera position, orientation, and projection
 */

export class Camera {
  constructor() {
    // Position
    this.position = [0, 0, 0];
    
    // Orientation (lookAt style)
    this.target = [0, 0, 0];
    this.up = [0, 1, 0];
    
    // Projection
    this.fov = 0.52;   // radians
    this.aspect = 1;
    this.near = 1;
    this.far = 2000;
    
    // Manual rotation mode (legacy support)
    this.rotX = -1.0;
    this.rotZ = 0.15;
    this.distance = 400;
    
    // Orbital mode
    this.orbitRadius = 450;
    this.orbitAzimuth = 0;   // XZ plane angle
    this.orbitElevation = 160; // Height
    this.orbitTime = 0;
    this.orbitSpeed = 1.0;
    
    // Flags
    this.mode = 'manual'; // 'manual' | 'orbit'
    
    // Cached matrices (computed on request)
    this.viewMatrix = new Float32Array(16);
    this.projMatrix = new Float32Array(16);
    this.mvpMatrix = new Float32Array(16);
  }

  // ========== POSITIONING ==========

  setPosition(x, y, z) {
    this.position[0] = x;
    this.position[1] = y;
    this.position[2] = z;
    return this;
  }

  lookAt(eyeX, eyeY, eyeZ, targetX, targetY, targetZ, upX, upY, upZ) {
    this.position = [eyeX, eyeY, eyeZ];
    this.target = [targetX, targetY, targetZ];
    this.up = [upX, upY, upZ];
    return this;
  }

  lookAtTarget(target) {
    this.target = target;
    return this;
  }

  // ========== ORBITAL MODE ==========

  setOrbitMode(radius = 450, speed = 1.0) {
    this.mode = 'orbit';
    this.orbitRadius = radius;
    this.orbitSpeed = speed;
    return this;
  }

  setManualMode() {
    this.mode = 'manual';
    return this;
  }

  setAzimuthElevation(azimuth, elevation) {
    this.orbitAzimuth = azimuth;
    this.orbitElevation = elevation;
    return this;
  }

  updateOrbit(dt) {
    if (this.mode !== 'orbit') return this;
    
    // Lissajous curve: freqX = 1.0, freqY = 1.5
    this.orbitTime += dt * 1000 * this.orbitSpeed;
    
    const freqX = 1.0, freqY = 1.5, r = this.orbitRadius;
    const cx = Math.sin(this.orbitTime * 0.001 * freqX) * r;
    const cz = -Math.cos(this.orbitTime * 0.001 * freqY) * r - r;
    const d = Math.sqrt(cx*cx + cz*cz);
    
    // Height modulation
    const h = this.orbitElevation + r * (0.3 + d/(r*1.414) * 0.4);
    
    // Speed modulation (pendulum effect)
    const sf = 0.5 + 1.5 * (1 - d/(r*Math.sqrt(2)));
    
    // In our coordinate system: X and Y are ground plane, Z is height (up)
    // Camera position: X=cx (horizontal), Y=cz (horizontal), Z=h (height)
    this.position = [cx, cz, h];
    this.target = [0, 0, 0];
    this.up = [0, 0, 1];
    
    return this;
  }

  // ========== MANUAL MODE ==========

  setManualRotation(rotX, rotZ) {
    this.rotX = Math.max(-1.0, Math.min(0, rotX));
    this.rotZ = rotZ;
    return this;
  }

  setDistance(d) {
    this.distance = Math.max(200, Math.min(600, d));
    return this;
  }

  // ========== PROJECTION ==========

  setProjection(fov, aspect, near, far) {
    this.fov = fov;
    this.aspect = aspect;
    this.near = near;
    this.far = far;
    return this;
  }

  setAspect(w, h) {
    this.aspect = w / h;
    return this;
  }

  // ========== MATRIX COMPUTATION ==========

  computeViewMatrix() {
    if (this.mode === 'manual') {
      // Manual mode: match original behavior
      // Original: view = tr(0, -50, -distance) * rx(rotX) * rz(rotZ)
      const rx = this.rotX, rz = this.rotZ, d = this.distance;
      
      // Build rotation matrices
      const cRx = Math.cos(rx), sRx = Math.sin(rx);
      const cRz = Math.cos(rz), sRz = Math.sin(rz);
      
      // Build rx matrix
      const mRx = new Float32Array(16);
      Camera.ident(mRx);
      mRx[5] = cRx; mRx[6] = sRx; mRx[9] = -sRx; mRx[10] = cRx;
      
      // Build rz matrix
      const mRz = new Float32Array(16);
      Camera.ident(mRz);
      mRz[0] = cRz; mRz[1] = sRz; mRz[4] = -sRz; mRz[5] = cRz;
      
      // Build translation matrix
      const mTr = new Float32Array(16);
      Camera.ident(mTr);
      mTr[12] = 0; mTr[13] = -50; mTr[14] = -d;
      
      // view = tr * rx * rz
      // Use temp matrix to avoid overwriting during multiplication
      const tmp1 = new Float32Array(16);
      Camera.mul(tmp1, mTr, mRx);
      Camera.mul(this.viewMatrix, tmp1, mRz);
      
      return this.viewMatrix;
    } else {
      // Orbit mode: use position, target, up
      return Camera.lookAt(
        this.viewMatrix,
        this.position[0], this.position[1], this.position[2],
        this.target[0], this.target[1], this.target[2],
        this.up[0], this.up[1], this.up[2]
      );
    }
  }

  computeProjectionMatrix() {
    const m = this.projMatrix;
    const t = 1 / Math.tan(this.fov / 2);
    m[0] = t / this.aspect;
    m[1] = 0;
    m[2] = 0;
    m[3] = 0;
    m[4] = 0;
    m[5] = t;
    m[6] = 0;
    m[7] = 0;
    m[8] = 0;
    m[9] = 0;
    m[10] = (this.far + this.near) / (this.near - this.far);
    m[11] = -1;
    m[12] = 0;
    m[13] = 0;
    m[14] = (2 * this.far * this.near) / (this.near - this.far);
    m[15] = 0;
    // Actually m[15] should be 0 for perspective, but original has m[15]=1
    // Let me check... original persp has m[15]=0 implicitly from fill(0)
    // But it sets m[14] = 2*f*n/(n-f)
    return m;
  }

  computeMVPMatrix(modelMatrix) {
    Camera.mul(this.mvpMatrix, this.projMatrix, this.viewMatrix);
    Camera.mul(this.mvpMatrix, this.mvpMatrix, modelMatrix);
    return this.mvpMatrix;
  }

  // ========== STATIC HELPERS ==========

  static lookAt(m, eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ) {
    // console.log(`lookAt: eye=(${eyeX},${eyeY},${eyeZ}) center=(${centerX},${centerY},${centerZ}) up=(${upX},${upY},${upZ})`);
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

  static mul(o, a, b) {
    for (let c = 0; c < 4; c++)
      for (let r = 0; r < 4; r++) {
        o[c*4+r] = 0;
        for (let k = 0; k < 4; k++)
          o[c*4+r] += a[k*4+r] * b[c*4+k];
      }
    return o;
  }

  static tr(m, x, y, z) {
    m.fill(0);
    m[0] = m[5] = m[10] = m[15] = 1;
    m[12] = x; m[13] = y; m[14] = z;
    return m;
  }

  static ident(m) {
    m.fill(0);
    m[0] = m[5] = m[10] = m[15] = 1;
    return m;
  }
}

export default Camera;
