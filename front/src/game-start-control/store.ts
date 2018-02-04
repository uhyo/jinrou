import {
    action,
    observable,
} from 'mobx';

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
    @observable
    public currentCasting: string = '';
    /**
     * Number of jobs.
     */
    @observable
    public jobNumbers: Map<string, number> = new Map();

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
    public setCurrentCasting(casting: string): void {
        this.currentCasting = casting;
    }
    /**
     * Partially update jobNumbers by given object.
     */
    @action
    public updateJobNumbers(obj: Record<string, number>): void {
        for (const key in obj) {
            this.jobNumbers.set(key, obj[key]);
        }
    }
}
