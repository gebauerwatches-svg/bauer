const installCommands = {
  mac: 'curl -sSL https://bauerai.vercel.app/install.sh | bash',
  windows: 'iwr https://bauerai.vercel.app/install.ps1 | iex',
};

const appNames = {
  mac: 'Terminal',
  windows: 'PowerShell',
};

const openHints = {
  mac: 'Press ⌘ + Space to open Spotlight. Type "Terminal" and press Enter. A black window will pop up — that\'s the right place.',
  windows: 'Press the Windows key. Type "PowerShell". Click the result. A blue window will pop up — that\'s the right place.',
};

const buttons = document.querySelectorAll('.os-btn');
const step2 = document.querySelector('.step-2');
const step3 = document.querySelector('.step-3');
const cmdEl = document.getElementById('install-cmd');
const appNameEl = document.getElementById('app-name');
const openHintEl = document.getElementById('open-app-hint');
const copyBtn = document.getElementById('copy-btn');

function selectOs(os) {
  buttons.forEach(b => b.classList.toggle('active', b.dataset.os === os));
  appNameEl.textContent = appNames[os];
  openHintEl.textContent = openHints[os];
  cmdEl.textContent = installCommands[os];
  step2.classList.remove('hidden');
  step3.classList.remove('hidden');
}

buttons.forEach(btn => {
  btn.addEventListener('click', () => selectOs(btn.dataset.os));
});

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

const ua = (navigator.userAgent || '').toLowerCase();
if (ua.includes('mac')) {
  selectOs('mac');
} else if (ua.includes('win')) {
  selectOs('windows');
}
