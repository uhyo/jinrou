/**
 * Map given array into object using value-generation function.
 */
export function arrayMapToObject<
  T extends string | number | symbol,
  M extends Record<T, unknown>
>(arr: T[], gen: <K extends T>(elm: K) => M[K]): M {
  const result = {} as M;
  for (const key of arr) {
    result[key] = gen(key);
  }
  return result;
}

/**
 * Map given array into object using [key, value]-generation function.
 */
export function arrayMapToObjectEntries<
  T,
  K extends string | number | symbol,
  M extends Record<K, unknown>
>(arr: T[], gen: (elm: T) => [K, M[K]]): M {
  const result = {} as M;
  for (const elm of arr) {
    const [key, value] = gen(elm);
    result[key] = value;
  }
  return result;
}
