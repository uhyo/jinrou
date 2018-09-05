/**
 * Sort given array using given priority and return the new one.
 */
export function sortBy<T>(arr: T[], priority: (elm: T) => number): T[] {
  return arr.concat([]).sort((a, b) => priority(a) - priority(b));
}
