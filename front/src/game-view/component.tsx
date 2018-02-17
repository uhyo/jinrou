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
        return (<div>
            Hi
        </div>);
    }
}
