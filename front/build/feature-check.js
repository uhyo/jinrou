/**
 * feature-check: set `_global_legacy_browser` variable according to the current browser's feature.
 * false if latest, 'legacy' if legacy, and 'hopeless' if not applicable of legacy builds.
 */
(function() {
  _global_legacy_browser = false;
  try {
    // ES2018 check (to kick out old iOS)
    if ('function' !== typeof Promise.prototype.finally) {
      throw new Error();
    }
    // ES2017 async/await
    // Maybe Safari on iOS 11.0 cannot parse await in if condition
    eval('(async function(f){ if(!await Object(f)())return})');
    // ES2017 String.prototype.padStart
    ''.padStart();
    // ES2016 Array.includes.
    ['a', 'b', 'c'].includes('b');
    //
  } catch (e) {
    _global_legacy_browser = 'legacy';
    // Skip Googlebot.
    if (navigator.userAgent.indexOf('Googlebot') >= 0) {
      return;
    }
    try {
      // Check basic DOM feature.
      document.documentElement.classList.contains;
      document.documentElement.dataset.foobar;
    } catch (e) {
      _global_legacy_browser = 'hopeless';
    }
    return;
  }
})();
