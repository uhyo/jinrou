/**
 * Compare two objects for updates using given keys.
 */
export function propUpdated<T>(
  oldProps: T,
  newProps: T,
  keys: Array<keyof T>,
): boolean {
  return keys.some(k => oldProps[k] !== newProps[k]);
}
