import { observable, action, computed } from 'mobx';
import {
  Prize,
  PrizeUtil,
  NowPrize,
  NowPrizeType,
  PrizeSelection,
} from './defs';
import { splitPrizesIntoGroups } from './logic/prize-groups';
import { fillTemplate } from './logic/fill-nowprize';

/**
 * States of prize page.
 * @package
 */
export class PrizeStore {
  constructor(public prizeUtil: PrizeUtil) {}
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
   * Prizes split into groups based on phonetics.
   */
  @computed
  public get prizeGroups(): Prize[][] {
    return splitPrizesIntoGroups(this.prizes);
  }
  /**
   * Map from prize id to display name of prize.
   */
  @computed
  public get prizeDisplayMap(): Map<string, string> {
    const result = new Map();
    for (const { id, name } of this.prizes) {
      result.set(id, name);
    }
    return result;
  }
  /**
   * Currently set prize of user.
   */
  @observable
  public nowprize: NowPrize[] = [];
  /**
   * Current template of prize setting.
   */
  @computed
  public get prizeTemplate(): Array<NowPrizeType> {
    return this.prizeUtil.getPrizesComposition(this.prizeNumber);
  }

  /**
   * Currently selected prize.
   */
  @observable
  public selection: PrizeSelection | null = null;

  /**
   * Whether list of prizes are shrinked.
   */
  @observable
  public shrinked: boolean = true;

  /**
   * Whether a change is made.
   */
  @observable
  public changed: boolean = false;

  /**
   * Set available prizes
   */
  @action
  public setPrizes(prizes: Prize[]): void {
    this.prizes = prizes;
  }
  /**
   * Set current prizes
   */
  @action
  public setNowPrize(nowprize: NowPrize[]): void {
    this.nowprize = fillTemplate(this.prizeTemplate, nowprize);
  }
  /**
   * Update specific index of current prizes
   */
  @action
  public updateNowPrize(index: number, prize: NowPrize): void {
    // update cannot change the type of nowprize.
    if (this.nowprize[index].type !== prize.type) {
      return;
    }
    this.nowprize[index] = { ...prize };
    this.changed = true;
  }
  /**
   * Delete specific index of current prizes
   */
  @action
  public deleteNowPrize(index: number): void {
    // update cannot change the type of nowprize.
    const p = this.nowprize[index];
    if (p.type === 'prize') {
      this.nowprize[index] = {
        type: 'prize',
        value: null,
      };
    } else {
      this.nowprize[index] = {
        type: 'conjunction',
        value: '',
      };
    }
    this.changed = true;
  }
  /**
   * Set shrinkedness of prize list
   */
  @action
  public setShrinked(shrinked: boolean): void {
    this.shrinked = shrinked;
  }
  /**
   * Set current selection of prize.
   */
  @action
  public setSelection(selection: PrizeSelection | null): void {
    this.selection = selection;
  }
  /**
   * Reset the changed state.
   */
  @action
  public unChange(): void {
    this.changed = false;
  }
}
