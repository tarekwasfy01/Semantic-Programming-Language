const C = window.SEMANTIC_CONFIG || {};
const $ = (q, root=document) => root.querySelector(q);
const $$ = (q, root=document) => [...root.querySelectorAll(q)];

async function latestRelease(repo){
  try{
    const r=await fetch(`https://api.github.com/repos/${repo}/releases/latest`,{headers:{Accept:'application/vnd.github+json'}});
    if(!r.ok) throw new Error('no release');
    return await r.json();
  }catch{return null}
}

async function wireReleaseButtons(){
  for(const el of $$('[data-release-repo]')){
    const repo=el.dataset.releaseRepo;
    const rel=await latestRelease(repo);
    const label=el.querySelector('[data-release-label]');
    if(rel){
      let href=rel.html_url;
      if(el.dataset.asset){
        const rx=new RegExp(el.dataset.asset,'i');
        const asset=(rel.assets||[]).find(a=>rx.test(a.name));
        if(asset) href=asset.browser_download_url;
      }
      el.href=href;
      if(label) label.textContent=rel.tag_name || 'Latest release';
      const status=el.closest('.card')?.querySelector('[data-release-status]');
      if(status) status.textContent=`Latest release · ${rel.tag_name}`;
    }else{
      el.href=`https://github.com/${repo}/releases/latest`;
      if(label) label.textContent='Latest release';
      const status=el.closest('.card')?.querySelector('[data-release-status]');
      if(status) status.textContent='No published GitHub release yet — opens the releases page.';
    }
  }
}

function footerYear(){const y=$('[data-year]');if(y)y.textContent=new Date().getFullYear()}
document.addEventListener('DOMContentLoaded',()=>{footerYear();wireReleaseButtons()});
