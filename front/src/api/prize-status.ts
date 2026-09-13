/**
 * An API to fetch the status of all prizes (conditions and progress)
 * of the logged-in user.
 * TODO: it depends directly on the legacy ss api.
 */
import { PrizeStatus } from '../pages/prize/defs';

export function getPrizeStatus(): Promise<PrizeStatus | null> {
  return new Promise(resolve => {
    (window as any).ss.rpc('user.getPrizeStatus', (result: any) => {
      if (!result || result.error) {
        // failure
        console.error(result && result.error);
        resolve(null);
      } else {
        resolve(result.statuses != null ? result.statuses : []);
      }
    });
  });
}
