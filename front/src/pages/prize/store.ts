import { observable, action, computed } from 'mobx';
import { Prize } from './defs';

/**
 * States of prize page.
 * @package
 */
export class PrizeStore {
  constructor() {}
  /**
   * List of available prizes.
   */
  @observable
  public prizes: Prize[] = [];
  /**
   * Number of available prizes.
   */
  @computed
  public get prizeNumber(): number {
    return this.prizes.length;
  }

  /**
   * Set available prizes
   */
  @action
  public setPrizes(prizes: Prize[]): void {
    this.prizes = prizes;
  }
}
