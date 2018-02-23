import * as React from 'react';
import {
    i18n,
    I18n,
} from '../../i18n';
import {
    bind,
} from '../../util/bind';

import {
    GameInfo,
    RoleInfo,
    SpeakState,
    LogVisibility,
    SpeakQuery,
} from '../defs';

import {
    LogVisibilityControl,
} from './log-visibility';

export interface IPropSpeakForm extends SpeakState {
    i18n: i18n;
    /**
     * Info of game.
     */
    gameInfo: GameInfo;
    /**
     * Info of roles.
     */
    roleInfo: RoleInfo | null;
    /**
     * Info of log visibility.
     */
    logVisibility: LogVisibility;
    /**
     * update to a speak form state.
     */
    onUpdate: (obj: Partial<SpeakState>)=> void;
    /**
     * update to log visibility.
     */
    onUpdateLogVisibility: (obj: LogVisibility)=> void;
    /**
     * Speak a comment.
     */
    onSpeak: (query: SpeakQuery)=> void;
}
/**
 * Speaking controls.
 */
export class SpeakForm extends React.PureComponent<IPropSpeakForm, {}> {
    protected comment: HTMLInputElement | HTMLTextAreaElement | null = null;
    /**
     * Temporally saved comment.
     */
    protected commentString: string = '';
    /**
     * Temporal flag to focus on the comment input.
     */
    protected focus: boolean = false;
    public render() {
        const {
            i18n,
            gameInfo,
            roleInfo,
            size,
            kind,
            multiline,
            willOpen,
            logVisibility,
        } = this.props;

        // list of speech kind.
        const speaks = roleInfo != null ? roleInfo.speak : ['day'];

        return (<form
            onSubmit={this.handleSubmit}
        >
            <I18n i18n={i18n}>{
                (t)=>
                (<>
                    {/* Comment input form. */}
                    {
                        multiline ?
                        <textarea
                            ref={e=> this.comment=e}
                            cols={50}
                            rows={4}
                            required
                            autoComplete='off'
                            defaultValue={this.commentString}
                            onChange={this.handleCommentChange}
                        /> :
                        <input
                            ref={e=> this.comment=e}
                            type='text'
                            size={50}
                            required
                            autoComplete='off'
                            defaultValue={this.commentString}
                            onChange={this.handleCommentChange}
                            onKeyDown={this.handleKeyDownComment}
                        />
                    }
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
                        speaks.map(value=> {
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
                    {/* Multiline checkbox. */}
                    <label>
                        <input
                            type='checkbox'
                            name='multilinecheck'
                            checked={multiline}
                            onChange={this.handleMultilineChange}
                        />
                        {t('game_client:speak.multiline')}
                    </label>
                    {/* Will open button. */}
                    <button
                        type='button'
                        onClick={this.handleWillClick}
                    >
                        {t('game_client:speak.will.open')}
                    </button>
                    {/* Show rule button. */}
                    <button
                        type='button'
                        onClick={this.handleRuleClick}
                    >
                        {t('game_client:speak.rule')}
                    </button>
                    {/* Log visibility control. */}
                    <LogVisibilityControl
                        i18n={i18n}
                        visibility={logVisibility}
                        day={gameInfo.day}
                        onUpdate={this.handleVisibilityUpdate}
                    />
                    {/* Refuse revival button. */}
                    <button
                        type='button'
                        onClick={this.handleRefuseRevival}
                    >
                        {t('game_client:speak.refuseRevival')}
                    </button>

            </>)
            }</I18n>
        </form>);
    }
    public componentDidUpdate() {
        // process the temporal flag to focus.
        if (this.focus && this.comment != null) {
            this.focus = false;
            this.comment.focus();
        }
    }
    /**
     * Handle submission of the speak form.
     */
    @bind
    protected handleSubmit(e: React.SyntheticEvent<HTMLFormElement>): void {
        const {
            kind,
            size,
            onSpeak,
        } = this.props;
        e.preventDefault();

        const query: SpeakQuery = {
            comment: this.commentString,
            mode: kind,
            // XXX compatibility!
            size: size === 'normal' ? '' : size,
        };
        this.props.onSpeak(query);
        // reset the comment form.
        this.commentString = '';
        if (this.comment != null) {
            this.comment.value = '';
        }
    }
    /**
     * Handle a change of comment input.
     */
    @bind
    protected handleCommentChange(e: React.SyntheticEvent<HTMLInputElement | HTMLTextAreaElement>): void {
        this.commentString = e.currentTarget.value;
    }
    /**
     * Handle a keydown event of comment input.
     */
    @bind
    protected handleKeyDownComment(e: React.KeyboardEvent<HTMLInputElement>): void {
        if (e.key === 'Enter' && (e.shiftKey || e.ctrlKey || e.metaKey)) {
            // this keyboard input switches to the multiline mode.
            e.preventDefault();
            this.commentString += '\n';
            this.focus = true;
            this.props.onUpdate({
                multiline: true,
            });
        }
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
    /**
     * Handle a change of multiline checkbox.
     */
    @bind
    protected handleMultilineChange(e: React.SyntheticEvent<HTMLInputElement>): void {
        this.props.onUpdate({
            multiline: e.currentTarget.checked,
        });
    }
    /**
     * Handle a click of will button.
     */
    @bind
    protected handleWillClick(): void {
        this.props.onUpdate({
            willOpen: true,
        });
    }
    /**
     * Handle a click of rule button.
     */
    @bind
    protected handleRuleClick(): void {
        // TODO
    }
    /**
     * Handle an update of log visibility.
     */
    @bind
    protected handleVisibilityUpdate(v: LogVisibility): void {
        this.props.onUpdateLogVisibility(v);
    }
    /**
     * Handle a click of refuse revival button.
     */
    @bind
    protected handleRefuseRevival(): void {
        // TODO
    }
}
