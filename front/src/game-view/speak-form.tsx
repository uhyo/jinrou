import * as React from 'react';
import {
    i18n,
    I18n,
} from '../i18n';
import {
    bind,
} from '../util/bind';

import {
    SpeakState,
} from './defs';

export interface IPropSpeakForm extends SpeakState {
    i18n: i18n;
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
            size,
        } = this.props;

        return (<form
            onSubmit={this.handleSubmit}
        >
            <I18n i18n={i18n}>{
                (t)=>
                (<>
                    <input
                        ref={e=> this.comment=e}
                        type='text'
                        size={50}
                        autoComplete='off'
                    />
                    <input
                        type='submit'
                        value={i18n.t('game_client:speak.say')}
                    />
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
}
