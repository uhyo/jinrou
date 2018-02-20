import * as React from 'react';
import {
    i18n,
} from 'i18next';
import {
    observer,
} from 'mobx-react';

import {
    GameStore,
} from './store';

import {
    JobInfo,
} from './job-info';

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
        } = store;
        return (<div>
            <JobInfo
                i18n={i18n}
                {...roleInfo}
            />
        </div>);
    }
}
