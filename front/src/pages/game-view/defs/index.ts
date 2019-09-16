export * from './player';
export * from './role';
export * from './form';
export * from './speak';
export * from './room';
export * from './log';

/**
 * Provided info of game.
 */
export interface GameInfo {
  /**
   * Current day.
   */
  day: number;
  /**
   * Whether it is night.
   */
  night: boolean;
  /**
   * Whether game is finished.
   */
  finished: boolean;
  /**
   * Status of game.
   */
  status: 'waiting' | 'playing' | 'finished';
  /**
   * Whether watcher's speech is allowed.
   */
  watchspeak: boolean;
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
 * Current status of timer.
 */
export interface TimerInfo {
  /**
   * Whether timer is currently enabled.
   */
  enabled: boolean;
  /**
   * Displayed name of timer.
   */
  name: string;
  /**
   * Target time of countdown (in ms).
   */
  target: number;
}

/**
 * One player in player list.
 */
export interface PlayerInfo {
  /**
   * userid of player.
   */
  id: string;
  /**
   * realid of player.
   */
  realid: string | null;
  /**
   * Whether this player is anonymized.
   */
  anonymous: boolean;
  /**
   * Displayed name of this player.
   */
  name: string;
  /**
   * Whether this player is dead.
   */
  dead: boolean;
  /**
   * URL of icon of this player.
   */
  icon: string | null;
  /**
   * Whether this player is a winner.
   * Null indicates that game is not finished yet.
   */
  winner: boolean | null;
  /**
   * Displayed jobname.
   */
  jobname: string | null;
  /**
   * Flags enabled for this player.
   */
  flags: Array<'ready' | 'helper' | 'gm' | 'norevive'>;
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
 * Data of report form.
 */
export interface ReportFormConfig {
  /**
   * Whether to enable report form.
   */
  enable: boolean;
  /**
   * Maximum number of characters of content.
   */
  maxLength: number;
  /**
   * Available categories of report.
   */
  categories: Array<{
    name: string;
    description: string;
  }>;
}

/**
 * Config of share button.
 */
export interface ShareButtonConfig {
  /**
   * Whether to enable share with Twitter button.
   */
  twitter: boolean;
}

/**
 * Query of sending report form.
 */
export interface ReportFormQuery {
  kind: string;
  content: string;
}
