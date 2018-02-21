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
    LogVisibility,
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
            gameInfo,
            roleInfo,
            speakState,
            logVisibility,
        } = store;
        return (<div>
            <JobInfo
                i18n={i18n}
                {...roleInfo}
            />
            <SpeakForm
                i18n={i18n}
                gameInfo={gameInfo}
                roleInfo={roleInfo}
                logVisibility={logVisibility}
                onUpdate={this.handleSpeakUpdate}
                onUpdateLogVisibility={this.handleLogVisibilityUpdate}
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
    /**
     * Handle an update to log visibility.
     */
    @bind
    protected handleLogVisibilityUpdate(obj: LogVisibility): void {
        this.props.store.update({
            logVisibility: obj,
        });
    }
}
