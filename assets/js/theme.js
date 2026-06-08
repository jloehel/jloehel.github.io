(function () {
  var root = document.documentElement;
  var btn = document.querySelector('.theme-toggle');
  if (!btn) return;

  function current() {
    return root.getAttribute('data-theme') ||
      (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  }

  btn.setAttribute('aria-pressed', current() === 'dark');
  btn.addEventListener('click', function () {
    var next = current() === 'dark' ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    btn.setAttribute('aria-pressed', next === 'dark');
    try { localStorage.setItem('theme', next); } catch (e) {}
  });
})();
