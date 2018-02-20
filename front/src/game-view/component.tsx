import * as React from 'react';
import {
    i18n,
} from 'i18next';
import {
    observer,
} from 'mobx-react';

import {
    bind,
} from '../util/bind';

import {
    SpeakState,
} from './defs';
import {
    GameStore,
    UpdateQuery,
} from './store';
import {
    JobInfo,
} from './job-info';
import {
    SpeakForm,
} from './speak-form';

interface IPropGame {
    /**
     * i18n instance.
     */
    i18n: i18n;
    /**
     * store.
     */
    store: GameStore;
}

@observer
export class Game extends React.Component<IPropGame, {}> {
    public render() {
        const {
            i18n,
            store,
        } = this.props;
        const {
            roleInfo,
            speakState,
        } = store;
        return (<div>
            <JobInfo
                i18n={i18n}
                {...roleInfo}
            />
            <SpeakForm
                i18n={i18n}
                onUpdate={this.handleSpeakUpdate}
                {...speakState}
            />
        </div>);
    }
    /**
     * Handle an update to the store.
     */
    @bind
    protected handleSpeakUpdate(obj: Partial<SpeakState>): void {
        this.props.store.update({
            speakState: obj,
        });
    }
}
