import { isPrimitiveOrFunction } from './is-primitive';

/**
 * Deep version of Object.assign.
 */
export function deepExtend<T>(obj1: T, ...objs: T[]): T {
  for (const obj2 of objs) {
    for (const key in obj2) {
      const v2 = obj2[key];
      if (isPrimitiveOrFunction(v2)) {
        obj1[key] = v2;
      } else {
        if (isPrimitiveOrFunction(obj1[key])) {
          obj1[key] = {} as any;
        }
        deepExtend(obj1[key], obj2[key]);
      }
    }
  }
  return obj1;
}
