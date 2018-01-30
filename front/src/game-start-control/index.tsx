import * as React from 'react';

import {
    CastingDefinition,
} from '../defs';

interface IPropCasting {
    /**
     * Definition of roles.
     */
    roles: CastingDefinition[];
    /**
     * Current selection casting.
     */
    currentCasting: string;
    /**
     * Number of jobs.
     */
    jobNumbers: Record<string, number>;
    /**
     * Handler of setting new role state.
     */
    onSetJob?(casting: string, jobNumbers: Record<string, number>): void;
}

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
                    roles.map(obj=>{
                        return <option key={obj.id}>{obj.name}</option>;
                    })
                }</select>
            </fieldset>
        </div>;
    }
}
