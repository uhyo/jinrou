import { useRef } from 'react';

/**
 * Generate a unique ID. The returned ID is persistent throughout component's life.
 * @param generator Function to generate a new unique ID.
 */
export function useUniqueId(generator?: () => string): string {
  const idRef = useRef<string | undefined>(undefined);
  if (idRef.current == null) {
    if (generator) {
      idRef.current = generator();
    } else {
      idRef.current =
        'id_' +
        Math.random()
          .toString(36)
          .slice(2);
    }
  }
  return idRef.current;
}
