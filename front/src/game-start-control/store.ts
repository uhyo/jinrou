import {
    action,
    computed,
    observable,
    runInAction,
} from 'mobx';

import {
    CastingDefinition,
    PresetFunction,
} from '../defs/casting-definition';
import {
    RoleCategoryDefinition,
} from '../defs/category-definition';
import {
    Rule,
} from '../defs/rule-definition';

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
        for (const {id} of categories) {
            this.categoryNumbers.set(id, 0);
        }
    }

    /**
     * Computed number of players.
     */
    @computed
    public get playersNumber(): number {
        // if scapegoat is on, an NPC is added.
        const npc =
            this.rules.get('scapegoat') === 'on' ?
            1 :
            0;
        return this.actualPlayersNumber + npc;
    }

    /**
     * Calculated number of jobs.
     */
    @computed
    public get jobNumbers(): Record<string, number> {
        const {
            preset,
            noFill,
        } = this.currentCasting;
        if (preset != null) {
            const res = preset(this.playersNumber);
            let total = 0;
            for (const key in res) {
                total += res[key];
            }
            if (!noFill) {
                // Human
                res.Human = Math.max(0, (res.Human || 0) + (this.playersNumber - total));
            }
            return res;
        } else {
            const result: Record<string, number> = {};
            let total = 0;
            for (const [key, value] of this.userJobNumbers) {
                result[key] = value;
                total += value;
            }
            if (!noFill) {
                result.Human = Math.max(0, (result.Human || 0) + (this.playersNumber - total));
            }
            return result;
        }
    }
    /**
     * Calculated required number of jobs.
     */
    @computed
    public get requiredNumber(): number {
        const {
            jobNumbers,
            categoryNumbers,
        } = this;
        let result = 0;
        for (const key in jobNumbers) {
            const v = jobNumbers[key];
            if (v) {
                result += v;
            }
        }
        for (const [, v] of categoryNumbers) {
            result += v;
        }
        return result;
    }
    /**
     * Computed complete rule object.
     */
    @computed
    public get ruleObject(): Rule {
        return {
            casting: this.currentCasting,
            rules: this.rules,
            jobNumbers: this.jobNumbers,
        };
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
    public updateRule(rule: string, value: string): void {
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
}
