/**
 * ChunkManager - Manages multiple terrain chunks with seamless transitions
 * Based on the lua World.lua implementation
 */

import { HitchScratchChunk } from './HitchScratchChunk.js';

export class ChunkManager {
  static DEFAULT_CHUNK_SIZE = 128;
  static DEFAULT_PIXEL = 2;
  static CHUNK_MARGIN = 10; // Space between chunks in world units

  constructor(canvas, options = {}) {
    this.canvas = canvas;
    this.options = options;
    
    // Configuration
    this.chunkSize = options.chunkSize || ChunkManager.DEFAULT_CHUNK_SIZE;
    this.pixel = options.pixel || ChunkManager.DEFAULT_PIXEL;
    thisodex = options.codex || 0;
    
    // Chunk storage
    this.chunks = new Map(); // Map of "x_y" -> { chunk: HitchScratchChunk, x, y }
    this.chunkIndex = {}; // For quick lookup
    this.edgeLength = 1; // Current square size (1, 3, 5, 7...)
    this.n = 0; // Number of chunks created
    this.nextX = 0;
    this.nextY = 0;
    
    // Rendering state
    this.gl = null;
    this.terrainChunks = []; // Array of HitchScratchChunk instances (for those that are rendered)
    
    // Camera/position state
    this.cameraX = 0;
    this.cameraY = 0;
    this.cameraZ = -500;
    this.cameraRotX = -0.5;
    this.cameraRotZ = 0;
    
    // Initialize
    this.initWebGL();
    this.resizeHandler();
    
    // Create first chunk at origin
    this.openChunk({ x: 0, y: 0 });
  }

  // ==========================================
  // PUBLIC API
  // ==========================================

  /**
   * Set up the next chunk position following the Lua spiral pattern
   * This grows the world in a square spiral: 1, 3x3, 5x5, 7x7, etc.
   */
  setNextChunk() {
    let x, y;
    const n = this.n;
    let l = this.edgeLength;

    if (n === 0) {
      x = 0; y = 0; l = 1;
    } else {
      const nextN = n + 1;
      if (nextN > l * l) {
        l += 2; // Expand the square
      }

      const offset = nextN - (l - 2) * (l - 2) - 1;
      const side = Math.floor(offset / (l - 1));
      const sideOffset = offset % (l - 1);

      // Determine which side of the square we're on
      if (side === 0) {
        // Right side (top to bottom)
        x = (l - 1) / 2;
        y = -(l - 1) / 2 + sideOffset;
      } else if (side === 1) {
        // Bottom side (right to left)
        x = (l - 1) / 2 - sideOffset;
        y = (l - 1) / 2;
      } else if (side === 2) {
        // Left side (bottom to top)
        x = -(l - 1) / 2;
        y = (l - 1) / 2 - sideOffset;
      } else {
        // Top side (left to right)
        x = -(l - 1) / 2 + sideOffset;
        y = -(l - 1) / 2;
      }
    }

    this.n = n + 1;
    this.nextX = x;
    this.nextY = y;
    this.edgeLength = l;
    
    return { x, y, n: this.n };
  }

  /**
   * Open a chunk at given coordinates
   * If coordinates not provided, uses the next position in the spiral
   */
  openChunk(coords = null) {
    const x = coords?.x !== undefined ? coords.x : this.nextX;
    const y = coords?.y !== undefined ? coords.y : this.nextY;
    
    // Check if chunk already exists
    const chunkKey = `${x}_${y}`;
    if (this.chunks.has(chunkKey)) {
      console.log(`Chunk at (${x}, ${y}) already exists`);
      return this.chunks.get(chunkKey);
    }

    // Get seed values from neighboring chunks for continuity
    const seedValues = this.getNeighborSeeds(x, y);

    // Create a container canvas for this chunk
    // For now, we'll render all chunks to the same main canvas
    // In a full implementation, we'd need a more sophisticated approach
    
    // For the HTML port, we'll create HitchScratchChunk instances
    // and position them appropriately in 3D space
    
    const chunkOptions = {
      size: this.chunkSize,
      pixel: this.pixel,
      ...this.options.chunkOptions
    };

    // If seeds are available, pass them
    if (seedValues) {
      chunkOptions.seedValues = seedValues;
    }

    // Create the chunk (but don't start rendering yet)
    const chunk = {
      x,
      y,
      chunk: new HitchScratchChunk(this.canvas, chunkOptions)
    };

    // Store chunk
    this.chunks.set(chunkKey, chunk);
    this.chunkIndex[chunkKey] = chunk;
    
    // If this was a next position, set up the next one
    if (x === this.nextX && y === this.nextY) {
      this.setNextChunk();
    }

    return chunk;
  }

  /**
   * Get seed values from neighboring chunks for continuity
   * Returns format: { layer0: { corners, edges }, layer1: { corners, edges } }
   */
  getNeighborSeeds(x, y) {
    const size = this.chunkSize;
    const lowLine = (size - 1) * size;
    const rightColumn = size - 1;

    // Get neighboring chunks
    const cu = this.findChunk(x, y - 1); // up (top)
    const cd = this.findChunk(x, y + 1); // down (bottom)
    const cl = this.findChunk(x - 1, y); // left
    const cr = this.findChunk(x + 1, y); // right

    const seedValues = {
      layer0: { corners: [], edges: {} },
      layer1: { corners: [], edges: {} }
    };

    // Get corner values from diagonal neighbors
    // Top-left corner (z0) from chunk at (x-1, y-1) or random
    const tlChunk = this.findChunk(x - 1, y - 1);
    if (tlChunk && tlChunk.chunk.terrain) {
      const terrain = tlChunk.chunk.terrain;
      seedValues.layer0.corners[0] = terrain.layer0Corners[2]; // bottom-right of TL neighbor = top-left of this
      seedValues.layer1.corners[0] = terrain.layer1Corners[2];
    }

    // Top-right corner (z1) from chunk at (x+1, y-1) or random
    const trChunk = this.findChunk(x + 1, y - 1);
    if (trChunk && trChunk.chunk.terrain) {
      const terrain = trChunk.chunk.terrain;
      seedValues.layer0.corners[1] = terrain.layer0Corners[3]; // bottom-left of TR neighbor = top-right of this
      seedValues.layer1.corners[1] = terrain.layer1Corners[3];
    }

    // Bottom-left corner (z2) from chunk at (x-1, y+1) or random
    const blChunk = this.findChunk(x - 1, y + 1);
    if (blChunk && blChunk.chunk.terrain) {
      const terrain = blChunk.chunk.terrain;
      seedValues.layer0.corners[2] = terrain.layer0Corners[1]; // top-right of BL neighbor = bottom-left of this
      seedValues.layer1.corners[2] = terrain.layer1Corners[1];
    }

    // Bottom-right corner (z3) from chunk at (x+1, y+1) or random
    const brChunk = this.findChunk(x + 1, y + 1);
    if (brChunk && brChunk.chunk.terrain) {
      const terrain = brChunk.chunk.terrain;
      seedValues.layer0.corners[3] = terrain.layer0Corners[0]; // top-left of BR neighbor = bottom-right of this
      seedValues.layer1.corners[3] = terrain.layer1Corners[0];
    }

    // Get edge values from direct neighbors
    if (cu && cu.chunk.terrain) {
      const terrain = cu.chunk.terrain;
      // Top edge of this chunk = bottom edge of chunk above
      seedValues.layer0.edges.top = terrain.layer0Edges.bottom;
      seedValues.layer1.edges.top = terrain.layer1Edges.bottom;
    }

    if (cd && cd.chunk.terrain) {
      const terrain = cd.chunk.terrain;
      // Bottom edge of this chunk = top edge of chunk below
      seedValues.layer0.edges.bottom = terrain.layer0Edges.top;
      seedValues.layer1.edges.bottom = terrain.layer1Edges.top;
    }

    if (cl && cl.chunk.terrain) {
      const terrain = cl.chunk.terrain;
      // Left edge of this chunk = right edge of chunk to the left
      seedValues.layer0.edges.left = terrain.layer0Edges.right;
      seedValues.layer1.edges.left = terrain.layer1Edges.right;
    }

    if (cr && cr.chunk.terrain) {
      const terrain = cr.chunk.terrain;
      // Right edge of this chunk = left edge of chunk to the right
      seedValues.layer0.edges.right = terrain.layer0Edges.left;
      seedValues.layer1.edges.right = terrain.layer1Edges.left;
    }

    // If no seed values at all, return null to use random
    if (seedValues.layer0.corners.length === 0 && 
        seedValues.layer1.corners.length === 0 &&
        Object.keys(seedValues.layer0.edges).length === 0) {
      return null;
    }

    return seedValues;
  }

  /**
   * Find a chunk at given coordinates
   */
  findChunk(x, y) {
    const chunkKey = `${x}_${y}`;
    return this.chunks.get(chunkKey) || null;
  }

  /**
   * Ensure chunks are generated in a radius around a point
   */
  ensureRadius(x, y, radius) {
    for (let dy = -radius; dy <= radius; dy++) {
      for (let dx = -radius; dx <= radius; dx++) {
        this.openChunk({ x: x + dx, y: y + dy });
      }
    }
  }

  /**
   * Start rendering all chunks
   */
  start() {
    for (const [key, chunkData] of this.chunks) {
      chunkData.chunk.start();
      this.terrainChunks.push(chunkData.chunk);
    }
  }

  /**
   * Update camera position
   */
  setCamera(x, y, z, rotX, rotZ) {
    this.cameraX = x;
    this.cameraY = y;
    this.cameraZ = z;
    this.cameraRotX = rotX;
    this.cameraRotZ = rotZ;
    
    // Update all chunks with camera
    for (const chunkData of this.chunks.values()) {
      const distFromCenter = Math.sqrt(
        (chunkData.x - x) * (chunkData.x - x) +
        (chunkData.y - y) * (chunkData.y - y)
      );
      // Could implement LOD based on distance here
    }
  }

  /**
   * Get all chunks in a square area
   */
  getChunksInArea(minX, minY, maxX, maxY) {
    const chunks = [];
    for (let y = minY; y <= maxY; y++) {
      for (let x = minX; x <= maxX; x++) {
        const chunk = this.findChunk(x, y);
        if (chunk) {
          chunks.push(chunk);
        }
      }
    }
    return chunks;
  }

  /**
   * Remove a chunk
   */
  removeChunk(x, y) {
    const chunkKey = `${x}_${y}`;
    if (this.chunks.has(chunkKey)) {
      const chunkData = this.chunks.get(chunkKey);
      chunkData.chunk.destroy();
      this.chunks.delete(chunkKey);
      delete this.chunkIndex[chunkKey];
      
      // Remove from terrainChunks array
      const idx = this.terrainChunks.indexOf(chunkData.chunk);
      if (idx >= 0) {
        this.terrainChunks.splice(idx, 1);
      }
    }
  }

  /**
   * Clean up all resources
   */
  destroy() {
    for (const [key, chunkData] of this.chunks) {
      chunkData.chunk.destroy();
    }
    this.chunks.clear();
    this.chunkIndex = {};
    this.terrainChunks = [];
  }

  // ==========================================
  // WEBGL & RESIZE
  // ==========================================

  initWebGL() {
    // The WebGL context is managed by individual HitchScratchChunk instances
    // This is a simplified approach - a full implementation would share a single context
  }

  resizeHandler() {
    // Canvas resize is handled by individual chunks
    if (this.canvas) {
      const displayWidth = this.canvas.clientWidth;
      const displayHeight = this.canvas.clientHeight;
      
      // For now, just ensure canvas matches display size
      if (this.canvas.width !== displayWidth || 
          this.canvas.height !== displayHeight) {
        this.canvas.width = displayWidth;
        this.canvas.height = displayHeight;
      }
    }

    // Notify all chunks of resize
    for (const chunkData of this.chunks.values()) {
      if (chunkData.chunk.resizeHandler) {
        chunkData.chunk.resizeHandler();
      }
    }
  }
}

export default ChunkManager;
