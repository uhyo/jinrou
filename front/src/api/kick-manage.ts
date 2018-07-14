/**
 * API to fetch the list of kicked user.
 * Appropreate privilege is required.
 */
export function getKickList(roomid: number): Promise<string[]> {
  return new Promise((resolve, reject) => {
    (window as any).ss.rpc('game.rooms.getbanlist', roomid, (result: any) => {
      if (!result || result.error) {
        // failure
        reject(result && result.error);
        return;
      }
      console.log(result);
      resolve(result.result);
    });
  });
}
