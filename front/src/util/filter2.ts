/**
 * Parallelly filter over two arrays and return subarray of the right array.
 */
export function filter2Right<T, U>(
  arr1: T[],
  arr2: U[],
  filter: (val1: T, val2: U, index: number) => boolean,
): U[] {
  const len = Math.min(arr1.length, arr2.length);
  const result: U[] = [];
  for (let i = 0; i < len; i++) {
    if (filter(arr1[i], arr2[i], i)) {
      result.push(arr2[i]);
    }
  }
  return result;
}
