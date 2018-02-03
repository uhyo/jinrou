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

interface IPropCasting {
    /**
     * Definition of roles.
     */
    roles: LabeledGroup<CastingDefinition, string>;
    /**
     * Current selection casting.
     */
    currentCasting: string;
    /**
     * Number of jobs.
     */
    jobNumbers: Map<string, number>;
    /**
     * Handler of setting new role state.
     */
    onSetJob?(casting: string, jobUpdates: Record<string, number>): void;
}

@observer
export class Casting extends React.Component<IPropCasting, {}> {
    render(){
        const {
            roles,
            currentCasting,
        } = this.props;

        return <div>
            <fieldset>
                <legend>役職</legend>

                <select>{
                    Optgroups({
                        items: roles,
                        getGroupLabel: (x: string)=>({
                            key: x,
                            label: x,
                        }),
                        getOptionKey: ({id}: CastingDefinition)=>id,
                        makeOption: (obj: CastingDefinition)=>{
                            return <option value={obj.id}>{obj.name}</option>;
                        },
                    })
                }</select>
            </fieldset>
        </div>;
    }
}
