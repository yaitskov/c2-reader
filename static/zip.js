const EOCD_SIGNATURE = 0x06054b50;
const CENTRAL_SIGNATURE = 0x02014b50;
const LOCAL_SIGNATURE = 0x04034b50;
const EOCD_MIN_SIZE = 22;
const EOCD_MAX_COMMENT = 0xffff;

function findEndOfCentralDirectory(view) {
  if (view.byteLength < EOCD_MIN_SIZE) {
    throw new Error("not a zip: archive is too short");
  }
  const last = view.byteLength - EOCD_MIN_SIZE;
  const first = Math.max(0, last - EOCD_MAX_COMMENT);
  for (let offset = last; offset >= first; offset--) {
    if (view.getUint32(offset, true) === EOCD_SIGNATURE) {
      return offset;
    }
  }
  throw new Error("not a zip: end of central directory not found");
}

async function inflateRaw(bytes) {
  if (typeof DecompressionStream === "undefined") {
    throw new Error("DecompressionStream is not supported in this browser");
  }
  const stream = new Blob([bytes])
    .stream()
    .pipeThrough(new DecompressionStream("deflate-raw"));
  return await new Response(stream).arrayBuffer();
}

async function readEntry(view, buffer, offset, decoder) {
  if (view.getUint32(offset, true) !== CENTRAL_SIGNATURE) {
    throw new Error("corrupt zip: bad central directory header");
  }
  const flags = view.getUint16(offset + 8, true);
  const method = view.getUint16(offset + 10, true);
  const compressedSize = view.getUint32(offset + 20, true);
  const nameLength = view.getUint16(offset + 28, true);
  const extraLength = view.getUint16(offset + 30, true);
  const commentLength = view.getUint16(offset + 32, true);
  const localOffset = view.getUint32(offset + 42, true);
  const name = decoder.decode(new Uint8Array(buffer, offset + 46, nameLength));
  const next = offset + 46 + nameLength + extraLength + commentLength;

  if (flags & 0x1) {
    throw new Error(`encrypted entry is not supported: ${name}`);
  }
  if (localOffset === 0xffffffff || compressedSize === 0xffffffff) {
    throw new Error(`ZIP64 entry is not supported: ${name}`);
  }
  if (view.getUint32(localOffset, true) !== LOCAL_SIGNATURE) {
    throw new Error(`corrupt zip: bad local header for ${name}`);
  }

  const localNameLength = view.getUint16(localOffset + 26, true);
  const localExtraLength = view.getUint16(localOffset + 28, true);
  const dataStart = localOffset + 30 + localNameLength + localExtraLength;
  const compressed = new Uint8Array(buffer, dataStart, compressedSize);

  let content;
  if (method === 0) {
    content = compressed.slice().buffer;
  } else if (method === 8) {
    content = await inflateRaw(compressed);
  } else {
    throw new Error(`unsupported compression method ${method}: ${name}`);
  }

  return { name, content, next };
}

async function unzipImpl(buffer) {
  const view = new DataView(buffer);
  const eocd = findEndOfCentralDirectory(view);
  const count = view.getUint16(eocd + 10, true);
  const directoryOffset = view.getUint32(eocd + 16, true);

  if (count === 0xffff || directoryOffset === 0xffffffff) {
    throw new Error("ZIP64 archives are not supported");
  }

  const decoder = new TextDecoder("utf-8");
  const files = {};
  let offset = directoryOffset;
  for (let index = 0; index < count; index++) {
    const entry = await readEntry(view, buffer, offset, decoder);
    files[entry.name] = entry.content;
    offset = entry.next;
  }
  return files;
}

export async function unzip(buffer) {
  try {
    return { ok: true, files: await unzipImpl(buffer) };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  }
}
