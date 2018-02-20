import {
    action,
    computed,
    observable,
} from 'mobx';

import {
    RoleInfo,
    SpeakState,
} from './defs';

/**
 * Query of updating the store.
 */
export interface UpdateQuery {
    roleInfo?: RoleInfo;
    speakState?: Partial<SpeakState>,
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
    /**
     * State of speaking forms.
     */
    @observable
    speakState: SpeakState = {
        size: 'normal',
    };

    /**
     * Update current role information.
     */
    @action
    public update({
        roleInfo,
        speakState,
    }: UpdateQuery): void {
        if (roleInfo != null) {
            this.roleInfo = roleInfo;
        }
        if (speakState != null) {
            Object.assign(this.speakState, speakState);
        }
    }
}
