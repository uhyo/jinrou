import {
    observer,
} from 'mobx-react';
import * as React from 'react';

import {
    WideButton,
} from '../common/button';
import {
    CastingDefinition,
    LabeledGroup,
    RoleCategoryDefinition,
    RuleGroup,
} from '../defs';
import {
    bind,
} from '../util/bind';
import {
    SelectLabeledGroup,
    IPropSelectLabeledGroup,
} from '../util/labeled-group';
import {
    ReactCtor,
} from '../util/react-type';

import {
    JobsString,
    PlayerNumberError,
} from './jobs-string';
import {
    RuleControl,
} from './rule-control';
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
     * Id of roles.
     */
    roles: string[];
    /**
     * Definition of castings.
     */
    castings: LabeledGroup<CastingDefinition, string>;
    /**
     * Definition of categories.
     */
    categories: RoleCategoryDefinition[];
    /**
     * Definition of rules.
     */
    ruledefs: RuleGroup;
    /**
     * Event of pressing gamestart button.
     */
    onStart: (query: Record<string, string>)=> void;
}

@observer
export class Casting extends React.Component<IPropCasting, {}> {
    public render(){
        const {
            i18n,
            store,
            roles,
            castings,
            categories,
            ruledefs,
        } = this.props;
        const {
            playersNumber,
            currentCasting,
            jobNumbers,
            jobInclusions,
            ruleObject,
        } = store;

        // Check whether current number of players is admissible.
        const {
            min = undefined,
            max = undefined,
        } = currentCasting.suggestedPlayersNumber || {};
        const minReq = Math.max(min || -Infinity, store.requiredNumber);
            
        // Specialized generic component.
        const SLG: ReactCtor<IPropSelectLabeledGroup<CastingDefinition, string>, {}> = SelectLabeledGroup;

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

                        <SLG
                            items={castings}
                            getGroupLabel={(x: string)=>({
                                key: x,
                                label: x,
                            })}
                            getOptionKey={({id}: CastingDefinition)=>id}
                            makeOption={(obj: CastingDefinition)=>{
                                return <option value={obj.id} title={obj.label}>{obj.name}</option>;
                                }}
                                onChange={this.handleCastingChange}
                            />
                        {
                            currentCasting.roleSelect ?
                                <SelectRoles
                                    categories={categories}
                                    t={t}
                                    jobNumbers={jobNumbers}
                                    jobInclusions={jobInclusions}
                                    roleExclusion={currentCasting.roleExclusion || false}
                                    noFill={currentCasting.noFill || false}
                                    useCategory={currentCasting.category || false}
                                    onUpdate={this.handleJobUpdate}
                                /> :
                                null
                        }
                    </fieldset>
                    <fieldset>
                        <legend>{t('gamestart.control.rules')}</legend>
                        <RuleControl
                            t={t}
                            ruledefs={ruledefs}
                            ruleObject={ruleObject}
                            onUpdate={this.handleRuleUpdate}
                        />
                    </fieldset>
                    <div>
                        <WideButton
                            onClick={this.handleGameStart}
                        >
                            {t('gamestart.control.start')}
                        </WideButton>
                    </div>
                </div>);
            }
        }</I18n>);
    }
    public componentDidCatch(err: any) {
        console.error(err);
    }
    @bind
    protected handleCastingChange(value: CastingDefinition): void {
        this.props.store.setCurrentCasting(value);
    }
    @bind
    protected handleJobUpdate(role: string, value: number, included: boolean): void {
        this.props.store.updateJobNumber(role, value, included);
    }
    @bind
    protected handleRuleUpdate(rule: string, value: string): void {
        this.props.store.updateRule(rule, value);
    }
    @bind
    protected handleGameStart(): void {
        const query = this.props.store.getQuery();
        this.props.onStart(query);
    }
}
