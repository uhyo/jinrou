/**
 * Assert that given value has 'never' type (at compile time).
 * https://github.com/Microsoft/TypeScript/issues/20823
 */
export function assertNever(value: never): never {
  throw new Error(`Illegal value: ${value}`);
}
