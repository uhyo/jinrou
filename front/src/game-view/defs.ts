/**
 * Information of your job, typically sent from server.
 */
export interface RoleInfo extends RolePeersInfo, RoleOtherPlayerInfo {
  /**
   * Name of current job.
   */
  jobname: string;
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
/**
 * Provided info of game.
 */
export interface GameInfo {
  /**
   * Current day.
   */
  day: number;
}

/**
 * Provided information of rule setting.
 */
export interface RuleInfo {
  /**
   * Job number settings.
   */
  jobNumbers: Record<string, number> | undefined;
  /**
   * Rule settings.
   * It may not exist at certain cituations.
   */
  rule: Record<string, string> | undefined;
}

/**
 * State of speaking form.
 */
export interface SpeakState {
  /**
   * Size of comment.
   */
  size: 'small' | 'normal' | 'big';
  /**
   * Kind of speech.
   */
  kind: string;
  /**
   * Multiline or not.
   */
  multiline: boolean;
  /**
   * Whether will form is open.
   */
  willOpen: boolean;
}

/**
 * visibility of logs per day.
 */
export type LogVisibility = LogAll | LogToday | LogOneDay;

export interface LogAll {
  type: 'all';
}
export interface LogToday {
  type: 'today';
}
export interface LogOneDay {
  type: 'one';
  day: number;
}

/**
 * Query of speaking.
 */
export interface SpeakQuery {
  /**
   * Comment string.
   */
  comment: string;
  /**
   * Type of comment.
   */
  mode: string;
  /**
   * Size of comment.
   */
  size: 'big' | '' | 'small';
}

/**
 * Base of log.
 */
export interface LogBase {
  time: number;
}

/**
 * Normal Log.
 */
export interface NormalLog extends LogBase {
  /**
   * Type of this log.
   */
  mode:
    | 'day'
    | 'system'
    | 'werewolf'
    | 'heaven'
    | 'prepare'
    | 'skill'
    | 'audience'
    | 'monologue'
    | 'couple'
    | 'fox'
    | 'will'
    | 'userinfo'
    | 'madcouple'
    | 'wolfskill'
    | 'emmaskill'
    | 'eyeswolfskill'
    | 'half-day'
    | 'heavenmonologue'
    | 'voteto'
    | 'gm'
    | 'gmreply'
    | 'gmheaven'
    | 'gmaudience'
    | 'gmmonologue'
    | 'helperwhisper'
    | 'inlog';
  /**
   * Content of this log.
   */
  comment: string;
  /**
   * Userid.
   */
  userid: string;
  /**
   * Displayed name of speaker.
   */
  name?: string;
  /**
   * Target of this log.
   */
  to: string | null;
  /**
   * Size of comment.
   */
  size?: 'big' | 'small';
}

/**
 * Phase change log.
 */
export interface NextTurnLog extends LogBase {
  mode: 'nextturn';
  comment: string;
  /**
   * Day number of this log.
   */
  day: number;
  /**
   * Whether this is night.
   */
  night: boolean;
  /**
   * Whether this is a finished log.
   */
  finished?: boolean;
}

/**
 * Vote result log.
 */
export interface VoteResultLog extends LogBase {
  mode: 'voteresult';
  /**
   * Result of all votes.
   */
  voteresult: Array<{
    id: string;
    name: string;
    voteto: string;
  }>;
  /**
   * Dictionary of all voting.
   */
  tos: Record<string, number | undefined>;
}

/**
 * Probability table log.
 */
export interface ProbabilityTableLog extends LogBase {
  mode: 'probabilitytable';
  /**
   * Probability table attached to this log.
   */
  probability_table: Record<
    string,
    {
      name: string;
      Human: number;
      Diviner: number;
      Werewolf: number;
      dead: number;
    }
  >;
}

/**
 * Type of log.
 */
export type Log = NormalLog | NextTurnLog | ProbabilityTableLog | VoteResultLog;
