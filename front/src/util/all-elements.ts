type ElementOf<A extends any[]> = A extends (infer Elm)[] ? Elm : unknown;
type IsNever<T> = T[] extends never[] ? true : false;

/**
 * Checks whether given array has all specified elements.
 * Return type is `V[]` if yes and `unknown` otherwise.
 *
 * Usage:
 *     const val1: unknown = ellElemenets<'foo' | 'bar'>(['foo']);
 *     const val2: Array<'foo' | 'bar'> = ellElemenets<'foo' | 'bar'>(['foo', 'bar']);
 */
export function allElements<V>(): <Arr extends V[]>(
  arr: Arr,
) => IsNever<Exclude<V, ElementOf<Arr>>> extends true
  ? V[]
  : { notFound: Exclude<V, ElementOf<Arr>> } {
  return arr => arr as any;
}
