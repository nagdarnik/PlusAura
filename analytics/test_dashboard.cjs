// Runs the built HTML scripts against a minimal DOM to catch build/runtime errors.
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
function openDashboard(){
 const html=fs.readFileSync(path.join(__dirname,'index.html'),'utf8');
 const elements=new Map();
 for(const [,id] of html.matchAll(/\bid="([^"]+)"/g))elements.set(id,{id,value:'',innerHTML:'',textContent:'',hidden:false,setAttribute(k,v){this[k]=v;},getAttribute(k){return this[k];},replaceChildren(...options){this.options=options;this.value=options[0]?.value||'';}});
 const tabs=['overview','retention','progress'].map(id=>{const el=elements.get('tab-'+id);el['aria-controls']=id;return el;});
 const context=vm.createContext({console,Intl,URL,Blob,setTimeout,Option:function(text,value){this.text=text;this.value=value;},document:{getElementById:id=>elements.get(id),querySelectorAll:()=>tabs,createElement:()=>({click(){}})}});
 for(const [,source] of html.matchAll(/<script>([\s\S]*?)<\/script>/g))new vm.Script(source).runInContext(context);
 return {elements,context,tabs};
}
test('built dashboard renders synthetic metrics and all three views without runtime errors',()=>{const {elements,context,tabs}=openDashboard();assert.equal(elements.get('error').textContent,'');for(const id of ['overviewCards','retentionCards','progressCards','trend','cohorts','weekly']){assert.ok(elements.get(id).innerHTML.length>20,id);assert.ok(!elements.get(id).innerHTML.includes('NaN'),id);}assert.equal(vm.runInContext('DEMO.users.length',context),600);tabs[1].onclick();assert.equal(elements.get('retention').hidden,false);assert.equal(elements.get('overview').hidden,true);});
test('filters recompute metrics; invalid range prevents stale CSV export',()=>{const {elements,context}=openDashboard();const all=vm.runInContext('result.newUsers',context);elements.get('segment').value='Органика';elements.get('apply').onclick();assert.ok(vm.runInContext('result.newUsers',context)<all);elements.get('start').value='2026-10-01';elements.get('end').value='2026-09-01';elements.get('apply').onclick();assert.equal(vm.runInContext('result',context),null);elements.get('export').onclick();assert.ok(elements.get('error').textContent.includes('фильтры'));elements.get('reset').onclick();assert.equal(vm.runInContext('result.newUsers',context),all);});
