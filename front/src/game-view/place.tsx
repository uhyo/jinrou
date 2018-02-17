import * as React from 'react';
import * as ReactDOM from 'react-dom';
import {
    i18n,
} from 'i18next';

import {
    GameStore,
} from './store';
import {
    Game,
} from './component';

/**
 * Options to place.
 */
export interface IPlaceOptions {
    /**
     * i18n instance to use.
     */
    i18n: i18n;
    /**
     * Node to place the component to.
     */
    node: HTMLElement;
}

export interface IPlaceResult {
    unmount(): void;
}
/**
 * Place a game view component.
 * @returns Unmount point with newly created store.
 */
export function place({
    i18n,
    node,
}: IPlaceOptions) {

    const store = new GameStore();

    const com = (<Game
        i18n={i18n}
        store={store}
    />);

    ReactDOM.render(com, node);

    return {
        store,
        unmount: ()=> {
            ReactDOM.unmountComponentAtNode(node);
        },
    };
}
