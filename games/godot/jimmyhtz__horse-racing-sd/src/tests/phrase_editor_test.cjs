// Pure unit test of the offline editor logic. Does not automate a browser.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const html=fs.readFileSync(path.join(root,'tools/phrase_editor.html'),'utf8');
const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
const elements={},blobs=[];
function element(){return {value:'',textContent:'',files:[],children:[],add(x){this.children.push(x)},append(x){this.children.push(x)},replaceChildren(...x){this.children=x},dispatchEvent(){if(this.oninput)this.oninput()},click(){}};}
const context=vm.createContext({document:{getElementById:id=>elements[id]??=(element()),createElement:()=>element()},Option:function(t,v){this.text=t;this.value=v},Event:function(t){this.type=t},Blob,URL:{createObjectURL:b=>(blobs.push(b),'blob:test'),revokeObjectURL(){}},setTimeout:fn=>fn(),console});
vm.runInContext(script,context);
for(const id of ['id','text','humor','sarcasm','energy','detail'])context.document.getElementById(id);
const original=JSON.parse(fs.readFileSync(path.join(root,'data/announcer_phrases.json'),'utf8'));
(async()=>{
 elements.file.files=[{text:async()=>JSON.stringify(original)}];
 await elements.file.onchange();
 assert.equal(elements.status.textContent,`Imported ${original.lines.length} lines.`);
 elements.id.value='developer-test';elements.category.value='middle';elements.text.value='A fresh line for a moving field.';
 for(const key of ['humor','sarcasm','energy','detail'])elements[key].value='0.5';
 elements.add.onclick();assert.match(elements.status.textContent,/Line staged/);
 elements.id.value='bad-context';elements.category.value='result';elements.text.value='Horse {winner} wins';
 elements.add.onclick();assert.match(elements.status.textContent,/Wrong-context placeholder/);
 elements.download.onclick();assert.equal(blobs.length,1);
 const exported=JSON.parse(await blobs[0].text());
 assert.equal(exported.lines.length,original.lines.length+1);assert.equal(exported.lines.at(-1).id,'developer-test');
 assert.equal(exported.lines.some(l=>l.id==='bad-context'),false);
 console.log('PHRASE EDITOR: import, traits, staged addition, invalid context rejection and export PASS');
})().catch(e=>{console.error(e);process.exitCode=1;});
