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
  mode: 'probability_table';
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

/**
 * Maximum number of rows in one `display: grid` container.
 * Currently, Google Chrome limits the number of rows to 1000.
 * cf. https://github.com/rachelandrew/gridbugs/issues/28
 *
 * As one log occupies two rows in phone UI, the limit is set to the half of the Chrome limit.
 * @package
 */
export const maxLogsInGrid = 500;
