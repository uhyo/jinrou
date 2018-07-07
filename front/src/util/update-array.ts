/**
 * Return a new array with given index updated.
 */
export function updateArray<T>(arr: T[], index: number, value: T): T[] {
  return arr.map((val, i) => (i === index ? value : val));
}
