import {
    action,
    observable,
} from 'mobx';

/**
 * Store of current selection of casting.
 */
export class CastingStore {
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
