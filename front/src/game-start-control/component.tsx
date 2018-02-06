import {
    observer,
} from 'mobx-react';
import * as React from 'react';

import {
    CastingDefinition,
    LabeledGroup,
} from '../defs';
import {
    Optgroups,
} from '../util/labeled-group';

import {
    CastingStore,
} from './store';

interface IPropCasting {
    /**
     * store.
     */
    store: CastingStore;
    /**
     * Definition of castings.
     */
    castings: LabeledGroup<CastingDefinition, string>;
    /**
     * Handler of setting new role state.
     */
    onSetJob?(casting: string, jobUpdates: Record<string, number>): void;
}

@observer
export class Casting extends React.Component<IPropCasting, {}> {
    render(){
        const {
            store,
            castings,
        } = this.props;
        const {
            playersNumber,
            currentCasting,
        } = store;

        return <div>
            <p>現在の人数：{playersNumber}人</p>
            <fieldset>
                <legend>役職</legend>

                <select>{
                    Optgroups({
                        items: castings,
                        getGroupLabel: (x: string)=>({
                            key: x,
                            label: x,
                        }),
                        getOptionKey: ({id}: CastingDefinition)=>id,
                        makeOption: (obj: CastingDefinition)=>{
                            return <option value={obj.id} title={obj.label}>{obj.name}</option>;
                        },
                    })
                }</select>
            </fieldset>
        </div>;
    }
}
