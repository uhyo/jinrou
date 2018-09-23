/**
 * Object of info of user.
 */
export interface PublicPlayerInfo {
  /**
   * ID of this player.
   */
  id: string;
  /**
   * Display name of this player.
   */
  name: string;
  /**
   * Whether this player is dead.
   */
  dead: boolean;
  /**
   * Whether this player shows norevival flag.
   */
  norevive: boolean;
}
