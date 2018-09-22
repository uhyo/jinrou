import { isPrimitiveOrFunction } from './is-primitive';

/**
 * Clone simple object.
 */
export function deepClone<T>(obj: T): T {
  if (isPrimitiveOrFunction(obj)) {
    return obj;
  }
  const result = {} as T;
  for (const key in obj) {
    result[key] = deepClone(obj[key]);
  }
  return result;
}
