/**
 * Data of one room.
 * @package
 */
export interface Room {
  /**
   * ID of room.
   */
  id: number;
  /**
   * Name of room.
   */
  name: string;
  /**
   * Maximum number of players.
   */
  number: number;
  /**
   * Current status of room.
   */
  mode: 'waiting' | 'playing' | 'end';
  /**
   * Date of creation.
   */
  made: number;
  /**
   * Room comment.
   */
  comment: string;
  /**
   * Owner of room.
   * Undefined if hidden.
   */
  owner?: {
    userid: string;
    name: string;
  };
  /**
   * List of players.
   */
  players: unknown[];
  /**
   * blind mode.
   */
  blind: '' | 'yes' | 'complete';
  /**
   * using theme.
   */
  theme: '' | null | string;
  /**
   * fullname of theme.
   */
  themeFullName: null | string;
  /**
   * Whether watch speak allowed.
   */
  watchspeak: boolean;
  /**
   * Whether password is needed.
   */
  needpassword?: true;
  /**
   * whether this room has gm.
   */
  gm: boolean;
  /**
   * Additional info which is available in 'my' mode.
   */
  gameinfo?: GameInfo;
}
/**
 * mode fo roomlist.
 */
export type RoomListMode = '' | 'old' | 'log' | 'my';

/**
 * Additional game information.
 */
export interface GameInfo {
  /**
   * ID of my job.
   */
  job: string;
  subtype: 'win' | 'lose' | 'draw' | 'gm' | 'helper' | null;
}

/**
 * Duration where room is considered fresh, in ms.
 * 1.5 hours
 */
export const freshDuration = 1000 * 60 * 90;
