import * as React from 'react';
import * as ReactDOM from 'react-dom';
import {
    runInAction,
} from 'mobx';

import {
    CastingStore,
} from './store';
import {
    Casting,
} from './component';
import {
    CastingDefinition,
    LabeledGroup,
    RoleCategoryDefinition,
} from '../defs';
import {
    forLanguage,
} from '../i18n';

/**
 * Options to place.
 */
export interface IPlaceOptions {
    /**
     * A node to place the component to.
     */
    node: HTMLElement;
    /**
     * Definition of castings.
     */
    castings: LabeledGroup<CastingDefinition, string>;
    /**
     * Id of roles.
     */
    roles: string[];
    /**
     * Definition of categories.
     */
    categories: RoleCategoryDefinition[];
    /**
     * Initial selection of casting.
     */
    initialCasting: CastingDefinition;
}
export interface IPlaceResult {
    store: CastingStore;
    unmount(): void;
}

/**
 * Place a game start control component.
 * @returns Unmount point with newly created store.
 */
export function place({
    node,
    castings,
    roles,
    categories,
    initialCasting,
}: IPlaceOptions): IPlaceResult {
    const store = new CastingStore(initialCasting);
    store.setCurrentCasting(initialCasting);

    // TODO language
    const i18n = forLanguage('ja');

    const com =
        <Casting
            i18n={i18n}
            store={store}
            castings={castings}
            roles={roles}
            categories={categories}
        />;

    ReactDOM.render(com, node);

    return {
        store,
        unmount: ()=>{
            ReactDOM.unmountComponentAtNode(node);
        },
    };
}
