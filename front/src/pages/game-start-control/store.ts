import { action, computed, observable, runInAction } from 'mobx';

import {
  CastingDefinition,
  PresetFunction,
} from '../../defs/casting-definition';
import { RoleCategoryDefinition } from '../../defs/category-definition';
import { Rule } from '../../defs/rule-definition';
import { mapToObject } from '../../util/map-to-object';

/**
 * Store of current selection of casting.
 */
export class CastingStore {
  /**
   * All known names of roles.
   */
  protected roles: string[];
  /**
   * All known categories.
   */
  protected categories: RoleCategoryDefinition[];
  /**
   * Current number of players.
   */
  @observable
  public actualPlayersNumber: number = 0;
  /**
   * Current selected casting.
   */
  @observable.ref
  public currentCasting: Readonly<CastingDefinition>;
  /**
   * User input of number of jobs.
   */
  @observable
  public userJobNumbers: Map<string, number> = new Map();
  /**
   * Inclusion of roles by user.
   */
  @observable
  public jobInclusions: Map<string, boolean> = new Map();
  /**
   * User input of number of categories.
   */
  @observable
  public categoryNumbers: Map<string, number> = new Map();

  /**
   * Current rule options.
   */
  @observable
  public rules: Map<string, string> = new Map();

  /**
   * Whether the setting stored in this is consumed.
   */
  public consumed: boolean = false;

  constructor(
    roles: string[],
    categories: RoleCategoryDefinition[],
    initialCasting: CastingDefinition,
  ) {
    this.roles = roles;
    this.categories = categories;
    this.currentCasting = initialCasting;
    // Init userInclusion by filling with true.
    this.resetInclusion();
    // Init category numbers.
    for (const { id } of categories) {
      this.categoryNumbers.set(id, 0);
    }
  }

  /**
   * Computed number of players.
   */
  @computed
  public get playersNumber(): number {
    // if scapegoat is on, an NPC is added.
    const npc = this.rules.get('scapegoat') === 'on' ? 1 : 0;
    return this.actualPlayersNumber + npc;
  }
  /**
   * Computed sum of role assignments.
   */
  @computed
  protected get rolesNumber(): number {
    // Normally, one role per player.
    let result = this.playersNumber;
    // But when the game is chemical, two roles per player.
    if (this.rules.get('chemical') === 'on') {
      // XXX it depends on definition of rules!
      result *= 2;
    }
    return result;
  }

  /**
   * Role sets required by casting.
   */
  @computed
  protected get castingJobNumbers(): Record<string, number> {
    const { preset } = this.currentCasting;
    if (preset != null) {
      return preset(this.playersNumber);
    } else {
      const result: Record<string, number> = {};
      for (const [key, value] of this.userJobNumbers) {
        result[key] = value;
      }
      return result;
    }
  }
  /**
   * Calculated required number of players.
   */
  @computed
  public get requiredPlayersNumber(): number {
    const { castingJobNumbers, categoryNumbers, currentCasting } = this;
    if (!currentCasting.roleSelect) {
      // If current casting does not involve role selection, there is no required number of players.
      return 0;
    }
    let result = 0;
    for (const key in castingJobNumbers) {
      const v = castingJobNumbers[key];
      if (v && !(key === 'Human' && !currentCasting.noFill)) {
        result += v;
      }
    }
    for (const [, v] of categoryNumbers) {
      result += v;
    }
    // If chemical, required players number is adjusted.
    result = Math.ceil((result * this.playersNumber) / this.rolesNumber);
    return result;
  }

  /**
   * Calculated number of jobs.
   */
  @computed
  public get jobNumbers(): Record<string, number> {
    const {
      castingJobNumbers,
      currentCasting: { noFill },
    } = this;
    const res: Record<string, number> = {};

    let total = 0;
    // copy to res, counting total number of requested jobs.
    for (const key in castingJobNumbers) {
      res[key] = castingJobNumbers[key];
      total += res[key];
    }
    if (!noFill) {
      // Remaining players are filled with Humans.
      res.Human = Math.max(0, (res.Human || 0) + (this.rolesNumber - total));
    }
    return res;
  }
  /**
   * Computed complete rule object.
   */
  @computed
  public get ruleObject(): Rule {
    return {
      casting: this.currentCasting.id,
      rules: this.rules,
      jobNumbers: this.jobNumbers,
    };
  }
  /**
   * Serialized representation of whole rule setting.
   */
  @computed
  public get serializedRule(): string {
    const ruleObj = {
      casting: this.currentCasting.id,
      rules: mapToObject(this.rules),
      jobNumbers: this.jobNumbers,
      jobInclusions: mapToObject(this.jobInclusions),
    };
    return JSON.stringify(ruleObj);
  }

  /**
   * Set player number.
   */
  @action
  public setPlayersNumber(num: number): void {
    this.actualPlayersNumber = num;
  }
  /**
   * Set current casting.
   */
  @action
  public setCurrentCasting(casting: CastingDefinition): void {
    if (this.currentCasting.roleExclusion && !casting.roleExclusion) {
      // If new casting does not allow exclusions,
      // reset exclusion state.
      this.resetInclusion();
    }
    this.currentCasting = casting;
    // investigate its forced suggestions.
    if (casting.suggestedOptions != null) {
      for (const key in casting.suggestedOptions) {
        const sug = casting.suggestedOptions[key];
        if (sug.type === 'string' && sug.must === true) {
          // This is a must-suggestion.
          this.updateRule(key, sug.value);
        }
      }
    }
  }
  /**
   * Update jobNumbers of given role.
   */
  @action
  public updateJobNumber(role: string, value: number, included: boolean): void {
    if (!included) {
      // An excluded role should not be selected.
      value = 0;
    }
    this.userJobNumbers.set(role, value);
    this.jobInclusions.set(role, included);
  }
  /**
   * Update number of given category.
   */
  @action
  public updateCategoryNumber(category: string, value: number): void {
    this.categoryNumbers.set(category, value);
  }
  /**
   * Update rule.
   */
  @action
  public updateRule(rule: string, value: string, init?: boolean): void {
    if (!init) {
      // if non-init mode,
      // check whether this rule exists.
      if (!this.rules.has(rule)) {
        throw new Error(`No such rule: ${rule}`);
      }
    }
    this.rules.set(rule, value);
  }
  /**
   * Reset inclusion of roles.
   */
  @action
  protected resetInclusion(): void {
    for (const role of this.roles) {
      this.jobInclusions.set(role, true);
    }
  }
  /**
   * Load serialized representation of rule.
   */
  @action
  public loadSerializedRule(
    repr: string,
    lookupCasting: (id: string) => CastingDefinition | null,
  ): void {
    try {
      const { casting, rules, jobNumbers, jobInclusions } = JSON.parse(repr);

      this.resetInclusion();
      const castingDef = lookupCasting(casting);
      if (castingDef == null) {
        // unknown casting id.
        return;
      }
      this.setCurrentCasting(castingDef);
      for (const ruleKey in rules) {
        const ruleValue = rules[ruleKey];
        if ('string' !== typeof ruleValue) {
          continue;
        }
        this.updateRule(ruleKey, rules[ruleKey]);
      }
      for (const job in jobNumbers) {
        const jobNum = jobNumbers[job];
        if ('number' !== typeof jobNum) {
          continue;
        }
        const ji = jobInclusions[job];

        this.updateJobNumber(job, jobNum, ji != null ? !!ji : true);
      }
    } catch (err) {
      console.error(err);
      return;
    }
  }
  /**
   * Set consumed flag of this store.
   */
  public setConsumed(): void {
    this.consumed = true;
  }
}
