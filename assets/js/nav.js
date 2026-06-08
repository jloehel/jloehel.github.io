document.querySelector('.burger').addEventListener('click', e => {
  const b = e.currentTarget;
  b.setAttribute('aria-expanded', b.getAttribute('aria-expanded') !== 'true');
});

// Close the language dropdown on outside click or Escape.
const langSwitcher = document.querySelector('.lang-switcher');
if (langSwitcher) {
  document.addEventListener('click', e => {
    if (langSwitcher.open && !langSwitcher.contains(e.target)) langSwitcher.open = false;
  });
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && langSwitcher.open) {
      langSwitcher.open = false;
      langSwitcher.querySelector('summary').focus();
    }
  });
}
