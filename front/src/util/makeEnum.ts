type EnumOf<T extends string> = { readonly [K in T]: K };

/**
 * Make an enum object with given keys.
 */
export function makeEnum<T extends string>(elements: T[]): EnumOf<T> {
  const result: any = {};
  for (const e of elements) {
    result[e] = e;
  }
  return result;
}
