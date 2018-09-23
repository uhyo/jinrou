/**
 * Check whether given value is primitive.
 */
export function isPrimitive(value: unknown): boolean {
  const objt = typeof value;
  if (
    objt === 'string' ||
    objt === 'number' ||
    objt === 'boolean' ||
    objt === 'symbol' ||
    value == null
  ) {
    return true;
  }
  return false;
}

export function isPrimitiveOrFunction(value: unknown): boolean {
  return isPrimitive(value) || typeof value === 'function';
}
