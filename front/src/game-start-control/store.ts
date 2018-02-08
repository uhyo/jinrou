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
    public updateJobNumbers(obj: Record<string, number>): void {
        Object.assign(this.userJobNumbers, obj);
    }
}
