import { useRef } from 'react';

export function useRefs<Types extends unknown[]>(
  ...initialValues: { [K in keyof Types]: Types[K] | null }
): { [K in keyof Types]: React.RefObject<NonNullable<Types[K]>> } {
  return initialValues.map(v => useRef(v)) as any;
}
