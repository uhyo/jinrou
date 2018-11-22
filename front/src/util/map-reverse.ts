/**
 * Make a new array which is reversed and mapped.
 * The original index is passed to mapper's second argument.
 * Callback function is called in reversed order.
 */
export function mapReverse<T, U>(
  arr: T[],
  mapper: (arg: T, index: number) => U,
): U[] {
  const result = [];
  for (let i = arr.length - 1; i >= 0; i--) {
    result.push(mapper(arr[i], i));
  }
  return result;
}
