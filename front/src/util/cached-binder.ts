export type BoundFunc<V, R> = (value: V) => R;
/**
 * Cache of bound functions.
 */
export class CachedBinder<T, V = any, R = void> {
  protected cache: Map<T, BoundFunc<V, R>> = new Map();

  /**
   * Get a bind for given arg.
   * `func` should be functionally consistent for the same `bound`.
   * @param func Function to bind to given argument.
   */
  public bind(bound: T, func: (bound: T, value: V) => R): BoundFunc<V, R> {
    const c = this.cache.get(bound);
    if (c != null) {
      return c;
    }
    // We don't have cache. make a new one.
    const f = func.bind(null, bound);
    this.cache.set(bound, f);
    return f;
  }
}
