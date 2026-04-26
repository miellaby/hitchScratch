/**
 * Mesh - WebGL buffer wrapper for renderable geometry
 * Connects data (from TerrainChunk) to WebGL buffers
 */

export class Mesh {
  constructor(gl, verts, colors, indices) {
    this.gl = gl;
    this.verts = verts;
    this.colors = colors;
    this.indices = indices;
    this.posBuf = null;
    this.colBuf = null;
    this.idxBuf = null;
    this.idxCount = indices ? indices.length : 0;
    this.upload();
  }

  upload() {
    const gl = this.gl;
    
    if (this.posBuf) gl.deleteBuffer(this.posBuf);
    if (this.colBuf) gl.deleteBuffer(this.colBuf);
    if (this.idxBuf) gl.deleteBuffer(this.idxBuf);

    this.posBuf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.posBuf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(this.verts), gl.STATIC_DRAW);

    this.colBuf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, this.colBuf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(this.colors), gl.STATIC_DRAW);

    this.idxBuf = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.idxBuf);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(this.indices), gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, null);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
  }

  update(verts, colors, indices) {
    this.verts = verts;
    this.colors = colors;
    this.indices = indices;
    this.idxCount = indices ? indices.length : 0;
    this.upload();
  }

  destroy() {
    const gl = this.gl;
    if (this.posBuf) gl.deleteBuffer(this.posBuf);
    if (this.colBuf) gl.deleteBuffer(this.colBuf);
    if (this.idxBuf) gl.deleteBuffer(this.idxBuf);
    this.posBuf = null;
    this.colBuf = null;
    this.idxBuf = null;
  }
}

export default Mesh;
