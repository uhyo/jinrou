/**
 * Parallelly map over two arrays.
 */
export function map2<T, U, R>(
  arr1: T[],
  arr2: U[],
  mapper: (val1: T, val2: U, index: number) => R,
): R[] {
  const len = Math.min(arr1.length, arr2.length);
  const result: R[] = [];
  for (let i = 0; i < len; i++) {
    result.push(mapper(arr1[i], arr2[i], i));
  }
  return result;
}
