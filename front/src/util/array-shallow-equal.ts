import { values } from 'mobx';

/**
 * Shallow equaltiy of arrays.
 */
export function arrayShallowEqual<T>(arr1: T[], arr2: T[]): boolean {
  if (arr1.length !== arr2.length) return false;
  return arr1.every((value, idx) => value === arr2[idx]);
}
