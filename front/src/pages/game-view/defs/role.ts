import { PublicPlayerInfo } from './player';
import { FormDesc } from './form';
/**
 * Information of your job, typically sent from server.
 */
export interface RoleInfo extends RolePeersInfo, RoleOtherPlayerInfo {
  /**
   * Name of current job.
   */
  jobname: string;
  /**
   * Whether you are dead.
   */
  dead: boolean;
  /**
   * Descriptions provided to you.
   */
  desc: RoleDesc[];
  /**
   * Kind of speech available now.
   */
  speak: string[];
  /**
   * Content of will.
   */
  will: string | undefined;
  /**
   * Whether the player won the game.
   * null is for not determined.
   */
  win: boolean | null;
  /**
   * Your team.
   */
  myteam?: string;
  /**
   * Info of currently open forms.
   */
  forms: FormDesc[];
  /**
   * Your player number when quantum werewolf.
   */
  quantumwerewolf_number?: number;
  /**
   * Info of player which you support.
   */
  supporting?: PublicPlayerInfo & {
    supportingJob: string;
  };
  /**
   * Info for Streamer: current number of listeners.
   */
  listenerNumber?: number;
  /**
   * Info for Gambler: current number of stocked votes.
   */
  gamblerStock?: number;
}

/**
 * Part of RoleInfo which consists of information of other players.
 */
export type RolePeersInfo = Partial<
  Record<
    | 'wolves'
    | 'peers'
    | 'madpeers'
    | 'foxes'
    | 'nobles'
    | 'queens'
    | 'spy2s'
    | 'friends'
    | 'cultmembers'
    | 'vampires'
    | 'twins'
    | 'myfans'
    | 'ravens'
    | 'hooligans'
    | 'draculas'
    | 'draculaBitten'
    | 'absolutewolves'
    | 'santaclauses'
    | 'loreleis'
    | 'bonds'
    | 'targets'
    | 'enemies'
    | 'spaceWerewolfImposters',
    PublicPlayerInfo[]
  >
>;
/**
 * Part of RoleInfo which consists of information of one other player.
 */
export type RoleOtherPlayerInfo = Partial<
  Record<'stalking' | 'dogOwner' | 'fanof', PublicPlayerInfo>
>;

/**
 * Description of one role.
 * @package
 */
export interface RoleDesc {
  /**
   * Name of role.
   */
  name: string;
  /**
   * Id of role.
   */
  type: string;
}
