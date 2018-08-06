/**
 * Returns an increasing range of int.
 */
export function* intRange(
  start: number,
  end: number,
): IterableIterator<number> {
  for (let i = start; i <= end; i++) {
    yield i;
  }
}
