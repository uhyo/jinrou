// Feature check script.
// Check required feature and redirect to `_global_notSupportedPage` if not satisfied.
(function(){
  if ('undefined' === typeof localStorage) {
    location.href = _global_notSupportedPage;
    return;
  }
  // Check skip flag in the localStorage.
  if (localStorage['jinrou-not-supported-confirm']) {
    return;
  }
  // Skip Googlebot.
  if (navigator.userAgent.indexOf("Googlebot")>=0) {
    return;
  }
  try {
    // Check ES2017 async/await feature.
    eval('(async function(){})');
    // Check Array.includes.
    ['a', 'b', 'c'].includes('b');
    // Check basic DOM feature.
    document.documentElement.classList.contains;
    document.documentElement.dataset.foobar;
  } catch(e) {
    // If error, supported feature is not enough.
    location.href = _global_notSupportedPage;
  }
})();
