/**
 * Clone simple object.
 */
export function deepClone<T>(obj: T): T {
  const objt = typeof obj;
  if (
    objt === 'string' ||
    objt === 'number' ||
    objt === 'boolean' ||
    objt === 'symbol' ||
    obj == null
  ) {
    return obj;
  }
  if (objt === 'function') {
    // function is not cloned.
    return obj;
  }
  const result = {} as T;
  for (const key in obj) {
    result[key] = deepClone(obj[key]);
  }
  return result;
}
