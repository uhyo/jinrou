/**
 * Information of your job.
 */
export interface RoleInfo {
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
 * Provided info og game.
 */
export interface GameInfo {
  /**
   * Current day.
   */
  day: number;
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
 * Normal Log.
 */
export interface NormalLog {
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
    | 'eyeswolfskill';
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
}

/**
 * Phase change log.
 */
export interface NextTurnLog {
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
export interface VoteResultLog {
  mode: 'voteresult';
  /**
   * TODO Result of all votes.
   */
  voteresult: any[];
  /**
   * TODO Dictionary of all voting.
   */
  tos: any;
}

/**
 * Type of log.
 */
export type Log = NormalLog | NextTurnLog | VoteResultLog;
