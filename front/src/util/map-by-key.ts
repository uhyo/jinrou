/**
 * Make a Map from given array of objects.
 */
export function makeMapByKey<T, K extends keyof T>(
  arr: T[],
  key: K,
): Map<T[K], T> {
  return new Map(arr.map(obj => [obj[key], obj] as [T[K], T]));
}
