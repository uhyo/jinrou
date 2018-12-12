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
