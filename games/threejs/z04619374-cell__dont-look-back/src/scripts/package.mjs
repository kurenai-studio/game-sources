import { mkdir, readdir, readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { deflateRawSync } from 'node:zlib';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(fileURLToPath(new URL('../', import.meta.url)));
const output = path.join(root,'output');
const allowed = ['dist','tests','scripts','docs','.github','README.md','LICENSE','THIRD_PARTY_NOTICES.md','package.json','.gitignore'];
const files=[];
async function walk(relative) {
  if (relative === 'docs/concepts') return;
  const entries = await readdir(path.join(root,relative),{withFileTypes:true}).catch(()=>null);
  if (entries === null) { files.push(relative); return; }
  for (const entry of entries) await walk(path.posix.join(relative,entry.name));
}
for (const name of allowed) await walk(name);
await mkdir(output,{recursive:true});
const checksums={};
for (const file of files) checksums[file]=createHash('sha256').update(await readFile(path.join(root,file))).digest('hex');
await writeFile(path.join(output,'SHA256SUMS.json'),JSON.stringify(checksums,null,2)+'\n');
// ZIP32 with DEFLATE, UTF-8 names and fixed timestamps. Node built-ins only.
const crcTable = Array.from({length:256},(_,n)=>{
  for(let k=0;k<8;k++) n=(n&1)?0xedb88320^(n>>>1):n>>>1;
  return n>>>0;
});
function crc32(buffer) {
  let crc=0xffffffff;
  for(const byte of buffer) crc=crcTable[(crc^byte)&255]^(crc>>>8);
  return (crc^0xffffffff)>>>0;
}
const locals=[], directory=[];
let offset=0;
for(const file of [...files,'output/SHA256SUMS.json']) {
  const name=Buffer.from('dont-look-back/'+file.replace(/^output\//,''));
  const data=await readFile(path.join(root,file)), packed=deflateRawSync(data);
  const crc=crc32(data), local=Buffer.alloc(30), central=Buffer.alloc(46);
  local.writeUInt32LE(0x04034b50,0); local.writeUInt16LE(20,4);
  local.writeUInt16LE(0x800,6); local.writeUInt16LE(8,8); local.writeUInt16LE(33,12);
  local.writeUInt32LE(crc,14); local.writeUInt32LE(packed.length,18); local.writeUInt32LE(data.length,22);
  local.writeUInt16LE(name.length,26);
  central.writeUInt32LE(0x02014b50,0); central.writeUInt16LE(20,4); central.writeUInt16LE(20,6);
  central.writeUInt16LE(0x800,8); central.writeUInt16LE(8,10); central.writeUInt16LE(33,14);
  central.writeUInt32LE(crc,16); central.writeUInt32LE(packed.length,20); central.writeUInt32LE(data.length,24);
  central.writeUInt16LE(name.length,28); central.writeUInt32LE(offset,42);
  locals.push(local,name,packed); directory.push(central,name);
  offset+=local.length+name.length+packed.length;
}
const central=Buffer.concat(directory), end=Buffer.alloc(22);
end.writeUInt32LE(0x06054b50,0); end.writeUInt16LE(files.length+1,8); end.writeUInt16LE(files.length+1,10);
end.writeUInt32LE(central.length,12); end.writeUInt32LE(offset,16);
await writeFile(path.join(output,'dont-look-back-source.zip'),Buffer.concat([...locals,central,end]));
console.log(JSON.stringify({sourceZip:path.join(output,'dont-look-back-source.zip'),files:files.length,checksums:path.join(output,'SHA256SUMS.json')}));
