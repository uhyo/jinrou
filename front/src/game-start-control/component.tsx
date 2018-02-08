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
    PlayerTooFew,
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

        return (<I18n i18n={i18n} namespace='game_client'>{
            (t)=> {
                return (<div>
                    <p>
                        {t('gamestart.info.player_number', {count: playersNumber})}
                    {' - '}
                    {store.currentCasting.name}
                    {' / '}
                    {
                        playersNumber >= store.requiredNumber ?
                        <JobsString
                            i18n={i18n}
                            jobNumbers={store.jobNumbers}
                            roles={roles}
                        /> :
                        <PlayerTooFew
                            i18n={i18n}
                            requiredNumber={store.requiredNumber}
                        />
                        }
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
