/**
 * User info of player
 */
export interface UserInfo {
  userid: string;
  name: string;
  icon: string | null;
}

/**
 * Storage key of current phase.
 */
export const currentPhaseStorageKey = 'game-tutorial-current-key';
