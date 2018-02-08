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
     * Definition of castings.
     */
    castings: LabeledGroup<CastingDefinition, string>;
    /**
     * Id of roles.
     */
    roles: string[];
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
    initialCasting,
}: IPlaceOptions): IPlaceResult {
    const store = new CastingStore(initialCasting);
    store.setCurrentCasting(initialCasting, );

    const onSetJob = (casting: CastingDefinition, jobUpdates: Record<string, number>)=>{
        runInAction(()=>{
            store.setCurrentCasting(casting);
            store.updateJobNumbers(jobUpdates);
        });
    };

    const com =
        <Casting
            store={store}
            castings={castings}
            roles={roles}
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
