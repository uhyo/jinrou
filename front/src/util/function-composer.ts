/**
 * Compose functions by calling functons in sequence.
 */
export function inSequence<T>(
  ...funcs: Array<(arg: T) => void>
): (arg: T) => void {
  return arg => {
    for (const f of funcs) {
      f(arg);
    }
  };
}
