import * as React from 'react';
import {
    i18n,
    I18n,
} from '../i18n';
import {
    bind,
} from '../util/bind';

import {
    RoleInfo,
    SpeakState,
} from './defs';

export interface IPropSpeakForm extends SpeakState {
    i18n: i18n;
    /**
     * Info of roles.
     */
    roleInfo: RoleInfo,
    /**
     * update to a speak form state.
     */
    onUpdate: (obj: Partial<SpeakState>)=> void;
}
/**
 * Speaking controls.
 */
export class SpeakForm extends React.PureComponent<IPropSpeakForm, {}> {
    protected comment: HTMLInputElement | null = null;
    public render() {
        const {
            i18n,
            roleInfo,
            size,
            kind,
        } = this.props;

        return (<form
            onSubmit={this.handleSubmit}
        >
            <I18n i18n={i18n}>{
                (t)=>
                (<>
                    {/* Comment input form. */}
                    <input
                        ref={e=> this.comment=e}
                        type='text'
                        size={50}
                        autoComplete='off'
                    />
                    {/* Speak button. */}
                    <input
                        type='submit'
                        value={i18n.t('game_client:speak.say')}
                    />
                    {/* Speak size select control. */}
                    <select
                        value={size}
                        onChange={this.handleSizeChange}
                    >
                        <option
                            value='small'
                        >
                            {t('game_client:speak.size.small')}
                        </option>
                        <option
                            value='normal'
                        >
                            {t('game_client:speak.size.normal')}
                        </option>
                        <option
                            value='big'
                        >
                            {t('game_client:speak.size.big')}
                        </option>
                    </select>
                    {/* Speech kind selection. */}
                    <select
                        value={kind}
                        onChange={this.handleKindChange}
                    >{
                        roleInfo.speak.map(value=> {
                            // special handling of speech kind.
                            let label;
                            if (value.startsWith('gmreply_')) {
                                // TODO
                                label = t('game_client:speak.kind.gmreply', {
                                    target: value.slice(8),
                                });
                            } else if (value.startsWith('helperwhisper_')) {
                                label = t('game_client:speak.kind.helperwhisper');
                            } else {
                                label = t(`game_client:speak.kind.${value}`);
                            }
                            return (<option
                                key={value}
                                value={value}
                            >{label}</option>);
                        })
                    }</select>

            </>)
            }</I18n>
        </form>);
    }
    /**
     * Handle submission of the speak form.
     */
    @bind
    protected handleSubmit(e: React.SyntheticEvent<HTMLFormElement>): void {
        e.preventDefault();
    }
    /**
     * Handle a change of comment size.
     */
    @bind
    protected handleSizeChange(e: React.SyntheticEvent<HTMLSelectElement>): void {
        this.props.onUpdate({
            size: e.currentTarget.value as 'small' | 'normal' | 'big',
        });
    }
    /**
     * Handle a change of speech kind.
     */
    @bind
    protected handleKindChange(e: React.SyntheticEvent<HTMLSelectElement>): void {
        this.props.onUpdate({
            kind: e.currentTarget.value || '',
        });
    }
}
