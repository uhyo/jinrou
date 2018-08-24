import { computed } from 'mobx';

/**
 * Convert a Map to plain object.
 */
export function mapToObject<K extends string | number | symbol, V>(
  map: Map<K, V>,
): { [idx in K]: V } {
  const result = {} as { [idx in K]: V };
  for (const [k, v] of map) {
    result[k] = v;
  }
  return result;
}
