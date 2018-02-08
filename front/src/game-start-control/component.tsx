import {
    observer,
} from 'mobx-react';
import * as React from 'react';

import {
    CastingDefinition,
    LabeledGroup,
} from '../defs';
import {
    SelectLabeledGroup,
} from '../util/labeled-group';

import {
    makeJobsString,
} from './jobs-string';
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
     * Id of roles.
     */
    roles: string[];
    /**
     * Handler of setting new role state.
     */
    onSetJob?(casting: CastingDefinition, jobUpdates: Record<string, number>): void;
}

@observer
export class Casting extends React.Component<IPropCasting, {}> {
    render(){
        const {
            store,
            castings,
            roles,
        } = this.props;
        const {
            playersNumber,
            currentCasting,
        } = store;

        const jobsString = makeJobsString(roles, store.jobNumbers);

        const handleChange = (value: CastingDefinition)=>{
            store.setCurrentCasting(value);
        };

        return (<div>
            <p>現在の人数：{playersNumber}人 - {jobsString}</p>
            <fieldset>
                <legend>役職</legend>

                <SelectLabeledGroup
                    items={castings}
                    getGroupLabel={(x: string)=>({
                        key: x,
                        label: x,
                    })}
                    getOptionKey={({id}: CastingDefinition)=>id}
                    makeOption={(obj: CastingDefinition)=>{
                        return <option value={obj.id} title={obj.label}>{obj.name}</option>;
                    }}
                    onChange={handleChange}
                />
            </fieldset>
        </div>);
    }
}
