import { isPrimitiveOrFunction } from './is-primitive';

/**
 * Deep version of Object.assign.
 */
export function deepExtend<T, U>(obj1: T, ...objs: U[]): T & U {
  const result = {} as T & U;
  for (const key in obj1) {
    if (key !== '__proto__') {
      (result as any)[key] = obj1[key];
    }
  }
  for (const obj2 of objs) {
    for (const key in obj2) {
      if (key === '__proto__') {
        continue;
      }
      const v2 = obj2[key];
      if (isPrimitiveOrFunction(v2)) {
        (result as any)[key] = v2;
      } else {
        if (isPrimitiveOrFunction(result[key])) {
          result[key] = {} as any;
        }
        result[key] = deepExtend(result[key], obj2[key]);
      }
    }
  }
  return result;
}
