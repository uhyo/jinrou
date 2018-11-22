// include Polyfills.
// requestIdleCallback are not yet supported by some of "modern" browsers,
// so always include it.
import 'requestidlecallback';

export { place } from './place';
export { GameStore } from './store';
