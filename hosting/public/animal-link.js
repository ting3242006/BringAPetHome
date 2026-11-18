(() => {
  const match = /^\/animal\/([1-9][0-9]*)$/.exec(location.pathname);
  const reference = document.getElementById('animal-reference');
  if (!match || BigInt(match[1]) > 9223372036854775807n) {
    reference.textContent = '請從朋友分享的完整動物連結開啟。';
    return;
  }
  const animalId = match[1];
  reference.textContent = `動物編號 ${animalId}`;
  const openApp = document.getElementById('open-app');
  openApp.href = `bringapethome://animal/${animalId}`;
  openApp.hidden = false;
})();
