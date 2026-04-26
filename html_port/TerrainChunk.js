/**
 * TerrainChunk - Pure data class for terrain mesh
 * No rendering, no WebGL, no camera - just vertex data
 */

export class TerrainChunk {
  constructor(options = {}) {
    this.SIZE = options.size || 128;
    this.PIXEL = options.pixel || 2;
    this.verts = null;
    this.colors = null;
    this.indices = null;
    this.layer0 = null;
    this.layer1 = null;
    this.layer0Corners = null;
    this.layer0Edges = null;
    this.layer1Corners = null;
    this.layer1Edges = null;
  }

  generate(seedValues = null) {
    this.layer0 = this.generateNoise(140, 20, seedValues?.layer0 || null);
    this.layer1 = this.generateNoise(96, 64, seedValues?.layer1 || null);
    const result = this.buildTerrain(seedValues);
    this.verts = result.verts;
    this.colors = result.colors;
    this.indices = result.indices;
    this.layer0Corners = result.layer0Corners;
    this.layer0Edges = result.layer0Edges;
    this.layer1Corners = result.layer1Corners;
    this.layer1Edges = result.layer1Edges;
  }

  getVertexCount() { return this.verts ? this.verts.length / 3 : 0; }
  getIndexCount() { return this.indices ? this.indices.length : 0; }
  getBounds() {
    return {
      min: [0, 0, -4000],
      max: [this.SIZE * this.PIXEL, this.SIZE * this.PIXEL, 200]
    };
  }

  // ========== PRIVATE ==========

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

    g[0] = z0; g[N] = z1; g[N * gs] = z2; g[N * gs + N] = z3;

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
          const avg = (g[x + y * gs] + g[x + step + y * gs] + g[x + (y+step) * gs] + g[x + step + (y+step) * gs]) * 0.25;
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

  getElevation(layer0, layer1, x, y) {
    const SIZE = this.SIZE;
    const green = layer0[y * SIZE + x] - 64;
    const level = layer1[y * SIZE + x] - 20;
    let correction = 0, fluff = 0;

    if (level < 30) correction = (level - 30) * 2;
    else if (level < 90) {
      correction = Math.min(Math.floor(level-30), Math.floor(90-level));
      if (level > 50 && level < 70) correction *= 1.2;
    } else if (level > 200) correction = 200 - level;

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
    if (x < 1 || y < 1 || x >= SIZE-2 || y >= SIZE-2) z = -4000;
    else if (x < fs || y < fs || x >= SIZE-fs || y >= SIZE-fs) {
      const fall = Math.max(fs-x, fs-y, x-SIZE+fs+1, y-SIZE+fs+1);
      z -= 10 * Math.exp(fall / 3);
    }
    return [z, fluff];
  }

  cellColor(green, level) {
    let r, g, b;
    if (level > 200) {
      const v = Math.min(0xBB, level - 200);
      r = 0x44+v; g = 0x44+v; b = 0x44+v;
    } else if (level > 50 && level < 70) {
      const boost = 255 + Math.abs(level-60)*4096;
      r = 0x22; g = Math.min(255, 0x44 + boost / 0xFF); b = Math.min(255, (0xFF + boost) % 0xFF);
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
    return [r/255, g/255, b/255, 1];
  }

  getLayerEdges(layer) {
    const size = this.SIZE;
    return {
      top: new Float32Array(size, (_, i) => layer[i]),
      bottom: new Float32Array(size, (_, i) => layer[(size-1)*size + i]),
      left: new Float32Array(size+1, (_, i) => layer[i*size]),
      right: new Float32Array(size+1, (_, i) => layer[i*size + (size-1)])
    };
  }

  getLayerCorners(layer) {
    const size = this.SIZE;
    return [layer[0], layer[size-1], layer[(size-1)*size], layer[size*size-1]];
  }

  buildTerrain(seedValues = null) {
    const layer0Seeds = seedValues?.layer0 || null;
    const layer1Seeds = seedValues?.layer1 || null;
    const layer0 = this.layer0 || this.generateNoise(140, 20, layer0Seeds);
    const layer1 = this.layer1 || this.generateNoise(96, 64, layer1Seeds);
    const CHUNK_SIZE = this.SIZE;
    const verts = []; const colors = []; const indices = [];

    for (let y = 0; y < CHUNK_SIZE; y += 2) {
      for (let x = 0; x < CHUNK_SIZE; x += 2) {
        const green = layer0[y * this.SIZE + x] - 64;
        const level = layer1[y * this.SIZE + x] - 20;
        const [z, fluff] = this.getElevation(layer0, layer1, x, y);
        const col = this.cellColor(green, level);

        const p = this.PIXEL, hp = p/2;
        verts.push(x*p, y*p, z*p/10); colors.push(...col);
        verts.push((x+2)*p, y*p, z*p/10); colors.push(...col);
        verts.push(x*p, (y+2)*p, z*p/10); colors.push(...col);
        verts.push((x+2)*p, (y+2)*p, z*p/10); colors.push(...col);

        // Center the fluff vertex above the cell's center with slight randomness
        // Base spans [x*p, (x+2)*p] in X and [y*p, (y+2)*p] in Y
        // Center is at x*p + p, y*p + p
        const ox = p + (Math.random() * p - p/2) * 0.3;  // Small random offset around center
        const oy = p + (Math.random() * p - p/2) * 0.3;  // Small random offset around center
        verts.push(x*p + ox, y*p + oy, (z + fluff) * p / 10);
        colors.push(...col);
      }
    }

    let i = 0;
    for (let y = 0; y < CHUNK_SIZE; y += 2) {
      for (let x = 0; x < CHUNK_SIZE; x += 2) {
        indices.push(i, i+1, i+3, i+3, i+2, i);
        indices.push(i, i+4, i+3, i+1, i+2, i+4);
        if (x > 0) {
          const b = i - 5;
          indices.push(b+1, i, i+2, i+2, b+3, b+1);
        }
        if (y > 0) {
          const b = i - 5 * (CHUNK_SIZE / 2);
          indices.push(b+3, i+1, i, i, b+2, b+3);
        }
        i += 5;
      }
    }

    return { verts, colors, indices,
      layer0, layer1,
      layer0Corners: this.getLayerCorners(layer0),
      layer0Edges: this.getLayerEdges(layer0),
      layer1Corners: this.getLayerCorners(layer1),
      layer1Edges: this.getLayerEdges(layer1) };
  }
  
  getTerrainLayers() {
    return { layer0: this.layer0, layer1: this.layer1 };
  }
  
  getNeighborSeeds() {
    return {
      layer0: { corners: this.layer0Corners, edges: this.layer0Edges },
      layer1: { corners: this.layer1Corners, edges: this.layer1Edges }
    };
  }
}

export default TerrainChunk;
