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
    JobsString,
    PlayerNumberError,
} from './jobs-string';
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
     * Handler of setting new role state.
     */
    onSetJob?(casting: CastingDefinition, jobUpdates: Record<string, number>): void;
}

@observer
export class Casting extends React.Component<IPropCasting, {}> {
    render(){
        const {
            i18n,
            store,
            castings,
            roles,
        } = this.props;
        const {
            playersNumber,
            currentCasting,
        } = store;

        const handleChange = (value: CastingDefinition)=>{
            store.setCurrentCasting(value);
        };

        // Check whether current number of players is admissible.
        const {
            min = undefined,
            max = undefined,
        } = currentCasting.suggestedPlayersNumber || {};
        const minReq = Math.max(min || -Infinity, store.requiredNumber);
            

        return (<I18n i18n={i18n} namespace='game_client'>{
            (t)=> {
                const jobsMonitor =
                    max && max < playersNumber ?
                    (<PlayerNumberError t={t} maxNumber={max} />) :
                    minReq > playersNumber ? 
                    (<PlayerNumberError t={t} minNumber={minReq} />) :
                    (<JobsString
                        i18n={i18n}
                        jobNumbers={store.jobNumbers}
                        roles={roles}
                    />);
                return (<div>
                    <p>
                        {t('gamestart.info.playerNumber', {count: playersNumber})}
                    {' - '}
                    {store.currentCasting.name}
                    {' / '}
                    {jobsMonitor}
                    </p>
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
                        </fieldset>
                    </div>);
            }
        }</I18n>);
    }
}
