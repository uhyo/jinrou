import {
    observer,
} from 'mobx-react';
import * as React from 'react';

import {
    CastingDefinition,
    LabeledGroup,
    RoleCategoryDefinition,
} from '../defs';
import {
    SelectLabeledGroup,
} from '../util/labeled-group';

import {
    JobsString,
    PlayerNumberError,
} from './jobs-string';
import {
    SelectRoles,
} from './select-roles';
import {
    CastingStore,
} from './store';

import {
    i18n,
    I18n,
} from '../i18n';

interface IPropCasting {
    /**
     * i18n instance.
     */
    i18n: i18n,
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
     * Definition of categories.
     */
    categories: RoleCategoryDefinition[];
}

@observer
export class Casting extends React.Component<IPropCasting, {}> {
    render(){
        const {
            i18n,
            store,
            castings,
            roles,
            categories,
        } = this.props;
        const {
            playersNumber,
            currentCasting,
            jobNumbers,
            jobInclusions,
        } = store;

        const handleChange = (value: CastingDefinition)=> {
            store.setCurrentCasting(value);
        };
        const handleUpdate = (role: string, value: number)=> {
            store.updateJobNumber(role, value);
        };

        // Check whether current number of players is admissible.
        const {
            min = undefined,
            max = undefined,
        } = currentCasting.suggestedPlayersNumber || {};
        const minReq = Math.max(min || -Infinity, store.requiredNumber);
            

        return (<I18n i18n={i18n} namespace='game_client'>{
            (t)=> {
                // status line indicating jobs.
                const warning =
                    max && max < playersNumber ?
                    (<p><PlayerNumberError t={t} maxNumber={max} /></p>) :
                    minReq > playersNumber ? 
                    (<p><PlayerNumberError t={t} minNumber={minReq} /></p>) :
                    null;
                return (<div>
                    <p>
                        {t('gamestart.info.playerNumber', {count: playersNumber})}
                    {' - '}
                    {store.currentCasting.name}
                    {' / '}
                    <JobsString
                        i18n={i18n}
                        jobNumbers={jobNumbers}
                        roles={roles}
                    />
                    </p>
                    {warning}
                    <fieldset>
                        <legend>{t('gamestart.control.roles')}</legend>

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
                        {
                            currentCasting.roleSelect ?
                                <SelectRoles
                                    categories={categories}
                                    t={t}
                                    jobNumbers={jobNumbers}
                                    jobInclusions={jobInclusions}
                                    roleExclusion={currentCasting.roleExclusion || false}
                                    onUpdate={handleUpdate}
                                /> :
                                null
                        }
                    </fieldset>
                </div>);
            }
        }</I18n>);
    }
}
