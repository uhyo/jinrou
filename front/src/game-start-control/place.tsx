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
} from '../defs';

/**
 * Options to place.
 */
export interface IPlaceOptions {
    /**
     * A node to place the component to.
     */
    node: HTMLElement;
    /**
     * Definition of roles.
     */
    roles: LabeledGroup<CastingDefinition, string>;
    /**
     * Initial selection of casting.
     */
    initialCasting: string;
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
    roles,
    initialCasting,
}: IPlaceOptions): IPlaceResult {
    const store = new CastingStore();
    store.setCurrentCasting(initialCasting);

    const onSetJob = (casting: string, jobUpdates: Record<string, number>)=>{
        runInAction(()=>{
            store.setCurrentCasting(casting);
            store.updateJobNumbers(jobUpdates);
        });
    };

    const com =
        <Casting
            roles={roles}
            currentCasting={store.currentCasting}
            jobNumbers={store.jobNumbers}
            onSetJob={onSetJob}
        />;

    ReactDOM.render(com, node);

    return {
        store,
        unmount: ()=>{
            ReactDOM.unmountComponentAtNode(node);
        },
    };
}
