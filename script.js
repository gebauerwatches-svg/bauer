// Bauer install-page interactions:
//   1. Path picker: Claude (closed-source) vs local (open-source)
//   2. OS picker (Mac vs Windows) inside the Claude path
//   3. Copy-to-clipboard for the install command

const installCommands = {
  mac:     'curl -sSL https://bauerai.vercel.app/install.sh | bash',
  windows: 'iwr https://bauerai.vercel.app/install.ps1 | iex',
};

const appNames = {
  mac:     'Terminal',
  windows: 'PowerShell',
};

const openHints = {
  mac:     'Press ⌘ + Space to open Spotlight. Type "Terminal" and press Enter. A black window will pop up — that\'s the right place.',
  windows: 'Press the Windows key. Type "PowerShell". Click the result. A blue window will pop up — that\'s the right place.',
};

// ---------- Path picker ----------
const pathButtons = document.querySelectorAll('.path-btn');
const pathSections = {
  claude: document.getElementById('path-claude'),
  local:  document.getElementById('path-local'),
};

function selectPath(path) {
  pathButtons.forEach(b => b.classList.toggle('active', b.dataset.path === path));
  Object.entries(pathSections).forEach(([key, el]) => {
    if (!el) return;
    el.classList.toggle('hidden', key !== path);
  });
}

pathButtons.forEach(btn => {
  btn.addEventListener('click', () => selectPath(btn.dataset.path));
});

// ---------- OS picker (only matters inside the Claude path) ----------
const osButtons = document.querySelectorAll('.os-btn');
const step2 = document.querySelector('.step-2');
const step3 = document.querySelector('.step-3');
const cmdEl = document.getElementById('install-cmd');
const appNameEl = document.getElementById('app-name');
const openHintEl = document.getElementById('open-app-hint');
const copyBtn = document.getElementById('copy-btn');

function selectOs(os) {
  osButtons.forEach(b => b.classList.toggle('active', b.dataset.os === os));
  if (appNameEl) appNameEl.textContent = appNames[os];
  if (openHintEl) openHintEl.textContent = openHints[os];
  if (cmdEl) cmdEl.textContent = installCommands[os];
  if (step2) step2.classList.remove('hidden');
  if (step3) step3.classList.remove('hidden');
}

osButtons.forEach(btn => {
  btn.addEventListener('click', () => selectOs(btn.dataset.os));
});

// ---------- Copy-to-clipboard ----------
if (copyBtn) {
  copyBtn.addEventListener('click', async () => {
    const original = copyBtn.textContent;
    try {
      await navigator.clipboard.writeText(cmdEl.textContent);
      copyBtn.textContent = 'Copied!';
    } catch (_e) {
      const range = document.createRange();
      range.selectNode(cmdEl);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
      copyBtn.textContent = 'Select + ⌘C';
    }
    setTimeout(() => { copyBtn.textContent = original; }, 1800);
  });
}

// ---------- OS auto-detect ----------
const ua = (navigator.userAgent || '').toLowerCase();
if (ua.includes('mac')) {
  selectOs('mac');
} else if (ua.includes('win')) {
  selectOs('windows');
}
