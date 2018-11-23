import {
  requestIdleCallback as rIC,
  cancelIdleCallback as cIC,
} from 'requestidlecallback';
/**
 * Type definition of currently lacked requestIdleCallback stuff.
 */

declare global {
  const requestIdleCallback: typeof rIC;
  const cancelIdleCallback: typeof cIC;
}
