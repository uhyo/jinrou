import {
    action,
    computed,
    observable,
} from 'mobx';

import {
    CastingDefinition,
    PresetFunction,
} from '../defs/casting-definition';

/**
 * Store of current selection of casting.
 */
export class CastingStore {
    /**
     * Current number of players.
     */
    @observable
    public playersNumber: number = 0;
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

    constructor(initialCasting: CastingDefinition) {
        this.currentCasting = initialCasting;
    }

    /**
     * Calculated number of jobs.
     */
    @computed
    public get jobNumbers(): Record<string, number> {
        const {
            preset,
        } = this.currentCasting;
        if (preset != null) {
            const res = preset(this.playersNumber);
            let total = 0;
            for (const key in res) {
                total += res[key];
            }
            // Human
            res.Human = (res.Human || 0) + (this.playersNumber - total);
            return res;
        } else {
            const result: Record<string, number> = {};
            let total = 0;
            for (const [key, value] of this.userJobNumbers) {
                result[key] = value;
                total += value;
            }
            result.Human = (result.Human || 0) + (this.playersNumber - total);
            return result;
        }
    }
    /**
     * Calculated required number of jobs.
     */
    @computed
    public get requiredNumber(): number {
        const jobs = this.jobNumbers;
        let result = 0;
        for (const key in jobs) {
            const v = jobs[key];
            if (v) {
                result += v;
            }
        }
        return result;
    }

    /**
     * Set player number.
     */
    @action
    public setPlayersNumber(num: number): void {
        this.playersNumber = num;
    }
    /**
     * Set current casting.
     */
    @action
    public setCurrentCasting(casting: CastingDefinition): void {
        this.currentCasting = casting;
    }
    /**
     * Partially update jobNumbers by given object.
     */
    @action
    public updateJobNumber(role: string, value: number): void {
        this.userJobNumbers.set(role, value);
    }
}
