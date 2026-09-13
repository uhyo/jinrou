/**
 * Data of one pize.
 * @package
 */
export interface Prize {
  /**
   * ID of prize.
   */
  id: string;
  /**
   * Displayed name of prize.
   */
  name: string;
  /**
   * Phonetic information of prize.
   */
  phonetic: string;
}

/**
 * Data of currently set prize.
 */
export type NowPrize =
  | {
      type: 'prize';
      value: string | null;
    }
  | {
      type: 'conjunction';
      value: string;
    };

export type NowPrizeType = NowPrize['type'];

/**
 * Series of prize.
 */
export type PrizeStatusSeries =
  | 'wincount'
  | 'losecount'
  | 'winteamcount'
  | 'counter'
  | 'ownprizes';

/**
 * Data of status of a prize (condition and progress).
 */
export interface PrizeStatusRow {
  /**
   * ID of prize.
   */
  id: string;
  /**
   * Series of the prize.
   */
  series: PrizeStatusSeries;
  /**
   * Key of the subgroup (job / team / counter type).
   */
  kind: string;
  /**
   * Key of the team which the job belongs to.
   * Only for wincount/losecount rows: "all" means overall (全職業),
   * otherwise a team key of shared/game.coffee (e.g. "Human").
   * Always null for other series.
   */
  team?: string | null;
  /**
   * Required count to achieve the prize.
   */
  required: number;
  /**
   * Current count.
   */
  current: number;
  /**
   * Whether the prize is achieved.
   */
  achieved: boolean;
  /**
   * Displayed name of the prize.
   */
  name: string;
  /**
   * Phonetic of the prize.
   * Not displayed for now (reserved for future use such as search).
   */
  phonetic: string;
  /**
   * Localized name of job (only for wincount/losecount).
   */
  jobName?: string | null;
  /**
   * Localized name of team (winteamcount rows, and the team of the job for
   * wincount/losecount rows). Null for wincount/losecount of "all".
   */
  teamName?: string | null;
}

/**
 * Status of all prizes.
 */
export type PrizeStatus = PrizeStatusRow[];

/**
 * Currently selected prize
 */
export type PrizeSelection =
  | NowPrize
  | {
      type: 'now';
      index: number;
    }
  | { type: 'trash' };

/**
 * Interface of provided utility around prizes.
 */
export interface PrizeUtil {
  /**
   * Get a template of prizes for given number of prizes.
   */
  getPrizesComposition(prizes: number): Array<NowPrizeType>;
  /**
   * List of conjunctions.
   */
  conjunctions: string[];
}
