const fs = require('fs')
const Module = require("./mimer.js")
//const to_jmap = Module.cwrap('to_jmap', 'string', ['string'])

//console.log(process.argv)

const ready = new Promise((resolve) => {
  Module.onRuntimeInitialized = resolve
})

function _arrayToHeap(jsbuf){
  const numBytes = jsbuf.length
  const ptr = Module._malloc(numBytes);

  Module.HEAPU8.set(jsbuf, ptr)

//  const heapBytes = new Uint8Array(Module.HEAPU8.buffer, ptr, numBytes);
//  console.log('buffer size', jsbuf.length)
//  heapBytes.set(new Uint8Array(jsbuf.buffer));
  return ptr
}

function _freeArray(ptr){
  Module._free(ptr)
  
//  Module._free(heapBytes.byteOffset);
}

/*
const to_jmap = (mime_content) => {
  const ptr = _arrayToHeap(mime_content);
  const ret = Module.ccall('to_jmap', 'string', ['number','number'],
    [ptr, mime_content.length]);
  _freeArray(ptr);
  return ret;
};
*/

const heapToBuf = (base, len) => {
  const buf_slice = Buffer.from(Module.HEAPU8.buffer, base, len)
  return Buffer.from(buf_slice) // Copy it
}

const to_jmap = mime_content => {
  // First create a cyrusmsg*
  const mime_ptr = _arrayToHeap(mime_content);
  const msg = Module._msg_parse(mime_ptr, mime_content.length)
  Module._free(mime_ptr)

  // Ok now get JSON out
  const json_str = Module.ccall('msg_to_json', 'string', ['number'], [msg])
  const json = JSON.parse(json_str)

  // ... And the attachments!
  const blobid_ptr = Module._get_blob_space();
  const attachments = {}
  for (const {blobId, name, size} of json.attachments) {
    console.log('blob', blobId, name, size)
    if (blobId.length !== 41) throw Error('unexpected blob length')
    const blob_buf = Buffer.from(blobId, 'ascii')
    Module.HEAPU8.set(blob_buf, blobid_ptr)
    const blob_ptr = Module._msg_get_blob(msg, null, size);
    attachments[blobId] = heapToBuf(blob_ptr, size)
    //console.log(blob_ptr)
  }

  Module._msg_free(msg)

  return {json, attachments}
}

ready.then(async () => {
  for (let i = 2; i < process.argv.length; i++) {
    const buf = fs.readFileSync(process.argv[i])
    //console.log(JSON.parse(to_jmap(buf)))
    const {json, attachments} = to_jmap(buf)
    console.log(process.argv[i])
    console.dir(json ? json : 'ERROR', {depth:null})

    // for (const {name, blobId, type} of json.attachments) {
    //   const data = attachments[blobId]
    //   console.log('Got file', name, data.length, 'of type', type)
    //   fs.writeFileSync('xx_' + name, data)
    // }
  }
})


