import {
    action,
    computed,
    observable,
} from 'mobx';

import {
    RoleInfo,
} from './defs';

/**
 * Query of updating the store.
 */
export interface UpdateQuery {
    roleInfo?: RoleInfo;
}
/**
 * Store of current game state.
 */
export class GameStore {
    /**
     * Name of your role.
     */
    @observable.shallow
    roleInfo: RoleInfo = {
        jobname: '',
        desc: [],
    };

    @action
    public update({
        roleInfo,
    }: UpdateQuery): void {
        if (roleInfo != null) {
            this.roleInfo = roleInfo;
        }
    }
}
