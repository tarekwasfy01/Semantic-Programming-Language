const cfg = window.SEMANTIC_CONFIG;

let allModules = [];
let filterMode = "all";

const esc = s =>
  String(s ?? "").replace(/[&<>"']/g, c => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;"
  }[c]));

function norm(s) {
  return String(s || "")
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[^a-z0-9:/._-]+/g, " ");
}

function levenshtein(a, b) {
  a = norm(a);
  b = norm(b);

  const row = Array.from(
    { length: b.length + 1 },
    (_, i) => i
  );

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

function score(q, module) {
  if (!q) return 0;

  const nq = norm(q);
  const name = norm(module.name);
  const url = norm(module.url);

  let haystack;

  if (filterMode === "name") {
    haystack = name;
  } else if (filterMode === "url") {
    haystack = url;
  } else {
    haystack = `${name} ${url}`;
  }

  if (haystack.includes(nq)) {
    return 100 - haystack.indexOf(nq) / 100;
  }

  const words = haystack
    .split(/\s|\/|[-_.:]+/)
    .filter(Boolean);

  let best = 0;

  for (const word of words) {
    const distance = levenshtein(nq, word);

    const fuzzyScore = Math.max(
      0,
      70 - distance * 12
    );

    best = Math.max(
      best,
      fuzzyScore
    );

    if (
      word.startsWith(nq) ||
      nq.startsWith(word)
    ) {
      best = Math.max(
        best,
        80
      );
    }
  }

  return best;
}

async function fetchJSON(url) {
  const response = await fetch(
    url,
    {
      cache: "no-store"
    }
  );

  if (!response.ok) {
    throw new Error(
      `${response.status} ${response.statusText}`
    );
  }

  return response.json();
}

async function load() {
  const registry = await fetchJSON(
    cfg.registryFile || "./modules.json"
  );

  if (!Array.isArray(registry)) {
    throw new Error(
      "modules.json must contain a JSON array."
    );
  }

  allModules = registry
    .filter(module =>
      module &&
      typeof module.name === "string" &&
      typeof module.url === "string" &&
      module.name.trim() !== "" &&
      module.url.trim() !== ""
    )
    .map(module => ({
      name: module.name.trim(),
      url: module.url.trim(),

      official:
        module.url.startsWith(
          "https://github.com/SemanticProgrammingLanguage/"
        ),

      sourceType: "archive"
    }));

  render();
}

function moduleLink(module) {
  const params = new URLSearchParams();

  params.set(
    "name",
    module.name
  );

  params.set(
    "url",
    module.url
  );

  params.set(
    "official",
    module.official ? "1" : "0"
  );

  params.set(
    "source",
    "archive"
  );

  return `module.html?${params.toString()}`;
}

function render() {
  const searchInput =
    document.querySelector("#moduleSearch");

  const query =
    searchInput?.value || "";

  let items = allModules
    .map(module => ({
      ...module,
      _score: score(
        query,
        module
      )
    }))
    .filter(module =>
      !query ||
      module._score > 25
    )
    .sort((a, b) => {
      if (query) {
        return (
          b._score -
          a._score
        );
      }

      return a.name.localeCompare(
        b.name
      );
    });

  const root =
    document.querySelector("#moduleList");

  if (!root) {
    return;
  }

  if (!items.length) {
    root.innerHTML = `
      <div class="empty">
        <img
          src="assets/img/semantic-logo.png"
          alt="Semantic"
        >

        <p>
          No module matched your search.
        </p>
      </div>
    `;
  } else {
    root.innerHTML = items
      .map(module => `
        <a
          class="module-row"
          href="${moduleLink(module)}"
        >

          <span class="module-icon">
            <img
              src="assets/img/icon.png"
              alt=""
            >
          </span>

          <span>

            <span class="module-name">
              ${esc(module.name)}
            </span>

            ${
              module.official
                ? '<span class="official">Official</span>'
                : ""
            }

            <span class="module-url">
              ${esc(module.url)}
            </span>

          </span>

          <span class="arrow">
            ↗
          </span>

        </a>
      `)
      .join("");
  }

  const count =
    document.querySelector("#moduleCount");

  if (count) {
    count.textContent =
      `${items.length} module${
        items.length === 1
          ? ""
          : "s"
      }`;
  }
}

function issueURL(name, url) {
  const repo =
    cfg.registryRepo ||
    `${cfg.repoOwner}/${cfg.repoName}`;

  const title =
    `[Module]: ${name}`;

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

  return (
    `https://github.com/${repo}/issues/new` +
    `?title=${encodeURIComponent(title)}` +
    `&body=${encodeURIComponent(body)}`
  );
}

document.addEventListener(
  "DOMContentLoaded",
  () => {

    const search =
      document.querySelector(
        "#moduleSearch"
      );

    if (search) {
      const initial =
        new URLSearchParams(
          location.search
        ).get("q");

      if (initial) {
        search.value =
          initial;
      }

      search.addEventListener(
        "input",
        render
      );
    }

    load().catch(error => {
      const count =
        document.querySelector(
          "#moduleCount"
        );

      if (count) {
        count.textContent =
          `Could not load modules: ${error.message}`;
      }

      const root =
        document.querySelector(
          "#moduleList"
        );

      if (root) {
        root.innerHTML = `
          <div class="empty">
            <img
              src="assets/img/semantic-logo.png"
              alt="Semantic"
            >

            <p>
              The module registry could not be loaded.
            </p>
          </div>
        `;
      }
    });

    document
      .querySelectorAll(
        "[data-filter]"
      )
      .forEach(button => {

        button.addEventListener(
          "click",
          () => {

            document
              .querySelectorAll(
                "[data-filter]"
              )
              .forEach(x =>
                x.classList.remove(
                  "active"
                )
              );

            button.classList.add(
              "active"
            );

            filterMode =
              button.dataset.filter;

            render();
          }
        );
      });

    const modal =
      document.querySelector(
        "#addModal"
      );

    document
      .querySelectorAll(
        "[data-open-add]"
      )
      .forEach(button => {

        button.addEventListener(
          "click",
          () => {
            modal?.classList.add(
              "open"
            );
          }
        );
      });

    document
      .querySelectorAll(
        "[data-close-add]"
      )
      .forEach(button => {

        button.addEventListener(
          "click",
          () => {
            modal?.classList.remove(
              "open"
            );
          }
        );
      });

    modal?.addEventListener(
      "click",
      event => {

        if (
          event.target ===
          modal
        ) {
          modal.classList.remove(
            "open"
          );
        }
      }
    );

    const form =
      document.querySelector(
        "#releaseForm"
      );

    form?.addEventListener(
      "submit",
      event => {

        event.preventDefault();

        const name =
          document
            .querySelector(
              "#releaseName"
            )
            .value
            .trim();

        const url =
          document
            .querySelector(
              "#releaseUrl"
            )
            .value
            .trim();

        if (
          !name ||
          !url
        ) {
          return;
        }

        window.open(
          issueURL(
            name,
            url
          ),
          "_blank",
          "noopener"
        );

        const status =
          document.querySelector(
            "#releaseStatus"
          );

        if (status) {
          status.textContent =
            "GitHub opened in a new tab. " +
            "Sign in, review the submission, and submit it. " +
            "The registry bot will validate the .smod archive automatically.";
        }
      }
    );
  }
);
