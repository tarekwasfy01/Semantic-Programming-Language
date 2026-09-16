const cfg=window.SEMANTIC_CONFIG;
let allModules=[];let filterMode='all';
const esc=s=>(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

function norm(s){return (s||'').toLowerCase().normalize('NFKD').replace(/[^a-z0-9:/._-]+/g,' ')}
function levenshtein(a,b){a=norm(a);b=norm(b);const m=Array(b.length+1).fill(0).map((_,i)=>i);for(let i=1;i<=a.length;i++){let prev=m[0];m[0]=i;for(let j=1;j<=b.length;j++){const old=m[j];m[j]=Math.min(m[j]+1,m[j-1]+1,prev+(a[i-1]===b[j-1]?0:1));prev=old}}return m[b.length]}
function score(q,m){if(!q)return 0;const nq=norm(q), name=norm(m.name), url=norm(m.url);const hay=filterMode==='name'?name:filterMode==='url'?url:`${name} ${url}`;if(hay.includes(nq)) return 100-(hay.indexOf(nq)/100);const words=hay.split(/\s|\/|[-_.:]+/).filter(Boolean);let best=0;for(const w of words){const d=levenshtein(nq,w);const s=Math.max(0,70-d*12);best=Math.max(best,s);if(w.startsWith(nq)||nq.startsWith(w))best=Math.max(best,80)}return best}

async function load(){
  const [official,registry]=await Promise.allSettled([
    fetch(`https://api.github.com/users/${cfg.officialOwner}/repos?per_page=100&sort=updated`).then(r=>r.ok?r.json():[]),
    fetch(cfg.registryFile,{cache:'no-store'}).then(r=>r.ok?r.json():[])
  ]);
  const off=(official.value||[]).filter(r=>/^Semantic-/i.test(r.name)&&r.name!=='Semantic-Programming-Language').map(r=>({name:r.name,url:r.html_url,official:true,repo:r.full_name,description:r.description||''}));
  const reg=Array.isArray(registry.value)?registry.value.map(x=>({...x,official:false})):[];
  const map=new Map();[...off,...reg].forEach(m=>map.set(`${m.name}|${m.url}`,m));allModules=[...map.values()];render();
}
function render(){
 const q=document.querySelector('#moduleSearch')?.value||'';let items=allModules.map(m=>({...m,_score:score(q,m)})).filter(m=>!q||m._score>25).sort((a,b)=>q?b._score-a._score:a.name.localeCompare(b.name));
 const root=document.querySelector('#moduleList');if(!root)return;root.innerHTML=items.length?items.map(m=>`<a class="module-row" href="module.html?name=${encodeURIComponent(m.name)}&url=${encodeURIComponent(m.url)}&official=${m.official?'1':'0'}"><span class="module-icon"><img src="assets/img/icon.png" alt=""></span><span><span class="module-name">${esc(m.name)}</span> ${m.official?'<span class="official">Official</span>':''}<span class="module-url">${esc(m.url)}</span></span><span class="arrow">↗</span></a>`).join(''):`<div class="empty"><img src="assets/img/semantic-logo.png" alt="Semantic"><p>No module matched your search.</p></div>`;
 const count=document.querySelector('#moduleCount');if(count)count.textContent=`${items.length} module${items.length===1?'':'s'}`;
}
function issueURL(name,url){
 const repo=cfg.registryRepo;const title=`[Module] ${name}`;const body=`### Module name\n${name}\n\n### Release ZIP URL\n${url}\n\n### Declaration\nI confirm that I am authorized to publish this module and that the linked archive may be indexed by the Semantic Module Registry.`;
 return `https://github.com/${repo}/issues/new?title=${encodeURIComponent(title)}&body=${encodeURIComponent(body)}`
}
document.addEventListener('DOMContentLoaded',()=>{
 const s=document.querySelector('#moduleSearch');if(s){const initial=new URLSearchParams(location.search).get('q');if(initial)s.value=initial;s.addEventListener('input',render);}load();
 document.querySelectorAll('[data-filter]').forEach(b=>b.addEventListener('click',()=>{document.querySelectorAll('[data-filter]').forEach(x=>x.classList.remove('active'));b.classList.add('active');filterMode=b.dataset.filter;render()}));
 const modal=document.querySelector('#addModal');document.querySelectorAll('[data-open-add]').forEach(b=>b.addEventListener('click',()=>modal.classList.add('open')));document.querySelectorAll('[data-close-add]').forEach(b=>b.addEventListener('click',()=>modal.classList.remove('open')));modal?.addEventListener('click',e=>{if(e.target===modal)modal.classList.remove('open')});
 document.querySelector('#releaseForm')?.addEventListener('submit',e=>{e.preventDefault();const name=document.querySelector('#releaseName').value.trim();const url=document.querySelector('#releaseUrl').value.trim();if(!name||!url)return;window.open(issueURL(name,url),'_blank','noopener');document.querySelector('#releaseStatus').textContent='GitHub opened in a new tab. Sign in, review the pre-filled submission, and submit it. The registry bot will validate the .smod archive automatically.';});
});
