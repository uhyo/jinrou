import {
    action,
    computed,
    observable,
} from 'mobx';

/**
 * Store of current game state.
 */
export class GameStore {
    /**
     * Name of your role.
     */
    @observable
    jobname: string = '';
}
