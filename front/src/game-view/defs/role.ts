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
   * Info of currently open forms.
   */
  forms: FormDesc[];
}

/**
 * Part of RoleInfo which consists of information of other players.
 */
export type RolePeersInfo = Record<
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
  | 'twins',
  PublicPlayerInfo[] | undefined
>;
/**
 * Part of RoleInfo which consists of information of one other player.
 */
export type RoleOtherPlayerInfo = Record<
  'stalking' | 'dogOwner',
  PublicPlayerInfo | undefined
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
