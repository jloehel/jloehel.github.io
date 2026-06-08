document.addEventListener('DOMContentLoaded', function () {
  var labelCopy = document.body.dataset.copyLabel || 'Copy';
  var labelDone = document.body.dataset.copiedLabel || 'Copied';

  document.querySelectorAll('div.highlight').forEach(function (block) {
    var wrap = document.createElement('div');
    wrap.className = 'highlight-wrap';
    block.parentNode.insertBefore(wrap, block);
    wrap.appendChild(block);

    var button = document.createElement('button');
    button.type = 'button';
    button.className = 'copy-code';
    button.textContent = labelCopy;
    wrap.appendChild(button);

    button.addEventListener('click', function () {
      var code = block.querySelector('pre');
      if (!code) return;
      navigator.clipboard.writeText(code.innerText).then(function () {
        button.textContent = labelDone;
        setTimeout(function () { button.textContent = labelCopy; }, 1500);
      });
    });
  });
});
