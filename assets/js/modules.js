const cfg = window.SEMANTIC_CONFIG;
let allModules = [];
let filterMode = "all";

const esc = s => String(s ?? "").replace(/[&<>"']/g, c => ({
  "&":"&amp;", "<":"&lt;", ">":"&gt;", '"':"&quot;", "'":"&#39;"
}[c]));

function norm(s) {
  return String(s || "")
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^a-z0-9:/._-]+/g, " ");
}

function levenshtein(a, b) {
  a = norm(a); b = norm(b);
  const row = Array.from({length:b.length + 1}, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let prev = row[0];
    row[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const old = row[j];
      row[j] = Math.min(
        row[j] + 1,
        row[j - 1] + 1,
        prev + (a[i - 1] === b[j - 1] ? 0 : 1)
      );
      prev = old;
    }
  }
  return row[b.length];
}

function score(q, m) {
  if (!q) return 0;
  const nq = norm(q);
  const name = norm(m.name);
  const url = norm(m.url || m.repoUrl || "");
  const hay = filterMode === "name" ? name : filterMode === "url" ? url : `${name} ${url}`;

  if (hay.includes(nq)) return 100 - hay.indexOf(nq) / 100;

  const words = hay.split(/\s|\/|[-_.:]+/).filter(Boolean);
  let best = 0;
  for (const w of words) {
    const d = levenshtein(nq, w);
    best = Math.max(best, Math.max(0, 70 - d * 12));
    if (w.startsWith(nq) || nq.startsWith(w)) best = Math.max(best, 80);
  }
  return best;
}

async function fetchJSON(url) {
  const r = await fetch(url, {cache:"no-store"});
  if (!r.ok) throw new Error(`${r.status} ${r.statusText}`);
  return r.json();
}

async function load() {
  const officialOwner = cfg.officialOwner || "SemanticProgrammingLanguage";

  const [officialResult, registryResult] = await Promise.allSettled([
    fetchJSON(`https://api.github.com/users/${encodeURIComponent(officialOwner)}/repos?per_page=100&sort=updated`),
    fetchJSON(cfg.registryFile || "./modules.json")
  ]);

  const officialRepos = Array.isArray(officialResult.value) ? officialResult.value : [];
  const registry = Array.isArray(registryResult.value) ? registryResult.value : [];

  // Registered modules always win because they contain an explicit ZIP URL.
  const registeredNames = new Set(registry.map(x => String(x.name || "").toLowerCase()));

  const official = officialRepos
    .filter(r =>
      /^Semantic-/i.test(r.name) &&
      r.name !== "Semantic-Programming-Language" &&
      !registeredNames.has(r.name.toLowerCase())
    )
    .map(r => ({
      name: r.name,
      url: r.html_url,        // repository URL; module.html resolves its latest release
      repoUrl: r.html_url,
      official: true,
      sourceType: "github-repo",
      repo: r.full_name,
      description: r.description || ""
    }));

  const registered = registry
    .filter(x => x && typeof x.name === "string" && typeof x.url === "string")
    .map(x => ({
      ...x,
      official: false,
      sourceType: "archive"
    }));

  const map = new Map();
  [...official, ...registered].forEach(m => map.set(`${m.name}|${m.url}`, m));
  allModules = [...map.values()];
  render();
}

function moduleLink(m) {
  const p = new URLSearchParams();
  p.set("name", m.name);
  p.set("url", m.url);
  p.set("official", m.official ? "1" : "0");
  if (m.repo) p.set("repo", m.repo);
  if (m.sourceType) p.set("source", m.sourceType);
  return `module.html?${p.toString()}`;
}

function render() {
  const q = document.querySelector("#moduleSearch")?.value || "";

  const items = allModules
    .map(m => ({...m, _score: score(q, m)}))
    .filter(m => !q || m._score > 25)
    .sort((a, b) => q ? b._score - a._score : a.name.localeCompare(b.name));

  const root = document.querySelector("#moduleList");
  if (!root) return;

  root.innerHTML = items.length
    ? items.map(m => `
      <a class="module-row" href="${moduleLink(m)}">
        <span class="module-icon"><img src="assets/img/icon.png" alt=""></span>
        <span>
          <span class="module-name">${esc(m.name)}</span>
          ${m.official ? '<span class="official">Official</span>' : ""}
          <span class="module-url">${esc(m.url)}</span>
        </span>
        <span class="arrow">↗</span>
      </a>
    `).join("")
    : `<div class="empty">
         <img src="assets/img/semantic-logo.png" alt="Semantic">
         <p>No module matched your search.</p>
       </div>`;

  const count = document.querySelector("#moduleCount");
  if (count) count.textContent = `${items.length} module${items.length === 1 ? "" : "s"}`;
}

function issueURL(name, url) {
  const repo = cfg.registryRepo || `${cfg.repoOwner}/${cfg.repoName}`;
  const title = `[Module]: ${name}`;

  // Keep these headings EXACTLY in sync with scripts/register_module.py.
  const body = [
    "### Module name",
    name,
    "",
    "### Module ZIP URL",
    url,
    "",
    "### Confirmation",
    "I am authorized to publish this module."
  ].join("\n");

  return `https://github.com/${repo}/issues/new?title=${encodeURIComponent(title)}&body=${encodeURIComponent(body)}`;
}

document.addEventListener("DOMContentLoaded", () => {
  const search = document.querySelector("#moduleSearch");
  if (search) {
    const initial = new URLSearchParams(location.search).get("q");
    if (initial) search.value = initial;
    search.addEventListener("input", render);
  }

  load().catch(err => {
    const count = document.querySelector("#moduleCount");
    if (count) count.textContent = `Could not load modules: ${err.message}`;
  });

  document.querySelectorAll("[data-filter]").forEach(b => {
    b.addEventListener("click", () => {
      document.querySelectorAll("[data-filter]").forEach(x => x.classList.remove("active"));
      b.classList.add("active");
      filterMode = b.dataset.filter;
      render();
    });
  });

  const modal = document.querySelector("#addModal");
  document.querySelectorAll("[data-open-add]").forEach(b =>
    b.addEventListener("click", () => modal?.classList.add("open"))
  );
  document.querySelectorAll("[data-close-add]").forEach(b =>
    b.addEventListener("click", () => modal?.classList.remove("open"))
  );
  modal?.addEventListener("click", e => {
    if (e.target === modal) modal.classList.remove("open");
  });

  document.querySelector("#releaseForm")?.addEventListener("submit", e => {
    e.preventDefault();
    const name = document.querySelector("#releaseName").value.trim();
    const url = document.querySelector("#releaseUrl").value.trim();
    if (!name || !url) return;

    window.open(issueURL(name, url), "_blank", "noopener");

    const status = document.querySelector("#releaseStatus");
    if (status) {
      status.textContent =
        "GitHub opened in a new tab. Sign in, review the submission and submit it. " +
        "The registry workflow validates the .smod archive automatically.";
    }
  });
});
