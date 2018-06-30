/**
 * An API to get a Twitter icon of given user.
 * TODO: it depends directly on the legacy ss api.
 */
export function getTwitterIcon(id: string): Promise<string | null> {
  return new Promise(resolve => {
    (window as any).ss.rpc('user.getTwitterIcon', id, (url: string | null) => {
      if (!url) {
        // failure
        resolve(null);
      } else {
        resolve(url);
      }
    });
  });
}
