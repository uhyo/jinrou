import * as React from 'react';
import { I18n, TranslationFunction } from '../../../i18n';
import { bind } from '../../../util/bind';

import {
  GameInfo,
  RoleInfo,
  SpeakState,
  LogVisibility,
  SpeakQuery,
  PlayerInfo,
} from '../defs';

import { LogVisibilityControl } from './log-visibility';
import { WillForm } from './will-form';
import { makeMapByKey } from '../../../util/map-by-key';
import { SpeakKindSelect, speakKindLabel } from './speak-kind-select';
import {
  MainForm,
  SpeakTextArea,
  SpeakInput,
  SpeakInputArea,
  SpeakButtonArea,
  SpeakControlsArea,
  OthersArea,
  ButtonArea,
  LabeledControl,
  SpeakControlsSlim,
} from './layout';
import { IsPhone } from '../../../common/media';
import { FontAwesomeIcon } from '../../../util/icon';
import { SensitiveButton } from '../../../util/sensitive-button';
import { withTheme } from '../../../util/styled';
import { Theme } from '../../../theme';

export interface IPropSpeakForm extends SpeakState {
  /**
   * Info of game.
   */
  gameInfo: GameInfo;
  /**
   * Info of roles.
   */
  roleInfo: RoleInfo | null;
  /**
   * List of players currently in the room.
   */
  players: PlayerInfo[];
  /**
   * Info of log visibility.
   */
  logVisibility: LogVisibility;
  /**
   * Whether rule is available now.
   */
  rule: boolean;
  /**
   * update to a speak form state.
   */
  onUpdate: (obj: Partial<SpeakState>) => void;
  /**
   * update to log visibility.
   */
  onUpdateLogVisibility: (obj: LogVisibility) => void;
  /**
   * Speak a comment.
   */
  onSpeak: (query: SpeakQuery) => void;
  /**
   * Push a refuse revival button.
   */
  onRefuseRevival: () => void;
  /**
   * Push the rule button.
   */
  onRuleOpen: (scroll: boolean) => void;
  /**
   * Change the will.
   */
  onWillChange: (will: string) => void;
  /**
   * Focus/unfocus the speak input.
   */
  onFocus: (focus: boolean) => void;
}
/**
 * Speaking controls.
 */
export class SpeakForm extends React.PureComponent<
  IPropSpeakForm,
  {
    /**
     * Whether additional controls are shown,
     * only effective on phones UI.
     */
    additionalControlsShown: boolean;
  }
> {
  state = {
    additionalControlsShown: false,
  };
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
      gameInfo,
      roleInfo,
      players,
      size,
      kind,
      multiline,
      willOpen,
      logVisibility,
      rule,
    } = this.props;
    const { additionalControlsShown } = this.state;

    // whether speech is allowed.
    const speakAllowed = !(roleInfo == null && !gameInfo.watchspeak);
    // list of speech kind.
    const speaks = roleInfo != null ? roleInfo.speak : ['day'];
    const playersMap = makeMapByKey(players, 'id');
    return (
      <I18n>
        {t => (
          <IsPhone>
            {isPhone => {
              // whether additional controls are actually hidden.
              const othersHidden = isPhone && !additionalControlsShown;
              return (
                <>
                  <MainForm onSubmit={this.handleSubmit}>
                    {/* Comment input form. */}
                    <SpeakInputArea>
                      {!speakAllowed ? (
                        <SpeakInput
                          key="nonallowed-speakinput"
                          ref={e => (this.comment = e)}
                          type="text"
                          size={50}
                          disabled
                          value={t('game_client:speak.noWatchSpeak')}
                        />
                      ) : multiline ? (
                        <SpeakTextArea
                          key="allowed-speakinput-multiline"
                          ref={e => (this.comment = e)}
                          cols={50}
                          rows={4}
                          required
                          autoComplete="off"
                          defaultValue={this.commentString}
                          onChange={this.handleCommentChange}
                          onFocus={this.handleFocus}
                          onBlur={this.handleBlur}
                        />
                      ) : (
                        <SpeakInput
                          key="allowed-speakinput"
                          ref={e => (this.comment = e)}
                          type="text"
                          size={50}
                          required
                          autoComplete="off"
                          defaultValue={this.commentString}
                          onChange={this.handleCommentChange}
                          onKeyDown={this.handleKeyDownComment}
                          onFocus={this.handleFocus}
                          onBlur={this.handleBlur}
                        />
                      )}
                    </SpeakInputArea>
                    {/* Speak button. */}
                    <SpeakButtonArea>
                      <input
                        type="submit"
                        value={t('game_client:speak.say')}
                        disabled={!speakAllowed}
                      />
                    </SpeakButtonArea>
                    {/* Speech-related controls. */}
                    <SpeakControlsArea hidden={othersHidden}>
                      {othersHidden ? (
                        <SpeakControlsSlim>
                          {t('game_client:speak.size.description')}:
                          {t(`game_client:speak.size.${size}`)}
                          {'　'}
                          {speakKindLabel(t, playersMap, kind || speaks[0])}
                        </SpeakControlsSlim>
                      ) : (
                        <>
                          {/* Speak size select control. */}
                          <LabeledControl
                            label={t('game_client:speak.size.description')}
                          >
                            <select
                              value={size}
                              onChange={this.handleSizeChange}
                            >
                              <option value="small">
                                {t('game_client:speak.size.small')}
                              </option>
                              <option value="normal">
                                {t('game_client:speak.size.normal')}
                              </option>
                              <option value="big">
                                {t('game_client:speak.size.big')}
                              </option>
                            </select>
                          </LabeledControl>
                          {/* Speech kind selection. */}
                          <LabeledControl
                            label={t('game_client:speak.kind.description')}
                          >
                            <SpeakKindSelect
                              kinds={speaks}
                              current={kind}
                              t={t}
                              playersMap={playersMap}
                              onChange={this.handleKindChange}
                            />
                          </LabeledControl>
                          {/* Multiline checkbox. */}
                          <label>
                            <input
                              type="checkbox"
                              name="multilinecheck"
                              checked={multiline}
                              onChange={this.handleMultilineChange}
                            />
                            {t('game_client:speak.multiline')}
                          </label>
                        </>
                      )}
                    </SpeakControlsArea>
                    {/* Other controls. */}
                    <OthersArea hidden={othersHidden}>
                      {/* Will open button. */}
                      <button type="button" onClick={this.handleWillClick}>
                        {willOpen
                          ? t('game_client:speak.will.close')
                          : t('game_client:speak.will.open')}
                      </button>
                      {/* Show rule button. */}
                      <RuleButton
                        t={t}
                        handleRuleClick={this.props.onRuleOpen}
                        disabled={!rule}
                        isPhone={isPhone}
                      />
                      {/* Log visibility control. */}
                      <LabeledControl
                        label={t('game_client:speak.logVisibility.description')}
                      >
                        <LogVisibilityControl
                          visibility={logVisibility}
                          day={gameInfo.day}
                          onUpdate={this.handleVisibilityUpdate}
                        />
                      </LabeledControl>
                      {/* Refuse revival button. */}
                      <button
                        type="button"
                        onClick={this.handleRefuseRevival}
                        disabled={gameInfo.status !== 'playing'}
                      >
                        {t('game_client:speak.refuseRevival')}
                      </button>
                    </OthersArea>
                    <ButtonArea>
                      <ExpandButton
                        isPhone={isPhone}
                        additionalControlsShown={additionalControlsShown}
                        onClick={this.handleAdditionalControls}
                      />
                    </ButtonArea>
                  </MainForm>
                  <WillForm
                    hidden={othersHidden}
                    t={t}
                    open={willOpen}
                    will={(roleInfo && roleInfo.will) || undefined}
                    onWillChange={this.handleWillChange}
                  />
                </>
              );
            }}
          </IsPhone>
        )}
      </I18n>
    );
  }
  public componentDidUpdate() {
    // process the temporal flag to focus.
    if (this.focus && this.comment != null) {
      this.focus = false;
      this.comment.focus();
    }
  }
  /**
   * Forse a focus on speak input.
   */
  public setFocus() {
    if (this.comment != null) {
      this.comment.focus();
    }
  }
  /**
   * Handle submission of the speak form.
   */
  @bind
  protected handleSubmit(e: React.SyntheticEvent<HTMLFormElement>): void {
    const { kind, size, onSpeak } = this.props;
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
  protected handleCommentChange(
    e: React.SyntheticEvent<HTMLInputElement | HTMLTextAreaElement>,
  ): void {
    this.commentString = e.currentTarget.value;
  }
  /**
   * Handle a keydown event of comment input.
   */
  @bind
  protected handleKeyDownComment(
    e: React.KeyboardEvent<HTMLInputElement>,
  ): void {
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
  protected handleKindChange(kind: string): void {
    this.props.onUpdate({
      kind,
    });
  }
  /**
   * Handle a change of multiline checkbox.
   */
  @bind
  protected handleMultilineChange(
    e: React.SyntheticEvent<HTMLInputElement>,
  ): void {
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
      willOpen: !this.props.willOpen,
    });
  }
  /**
   * Handle a change to the will.
   */
  @bind
  protected handleWillChange(will: string): void {
    const { onUpdate, onWillChange } = this.props;
    // close will form.
    onUpdate({
      willOpen: false,
    });
    onWillChange(will);
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
    this.props.onRefuseRevival();
  }
  /**
   * Handle a click of additional controls button.
   */
  @bind
  protected handleAdditionalControls(): void {
    this.setState(s => ({
      additionalControlsShown: !s.additionalControlsShown,
    }));
  }
  /**
   * Handle a focus of speak input.
   */
  @bind
  protected handleFocus(): void {
    this.props.onFocus(true);
  }
  /**
   * Handle a blur of speak input.
   */
  @bind
  protected handleBlur(): void {
    this.props.onFocus(false);
  }
}

const ExpandButton = withTheme(
  ({
    theme,
    isPhone,
    additionalControlsShown,
    onClick,
  }: {
    theme: Theme;
    isPhone: boolean;
    additionalControlsShown: boolean;
    onClick: () => void;
  }) => {
    return (
      <SensitiveButton type="button" hidden={!isPhone} onClick={onClick}>
        <FontAwesomeIcon
          icon={
            additionalControlsShown !==
            (theme.user.speakFormPosition === 'normal')
              ? 'caret-square-down'
              : 'caret-square-up'
          }
        />
      </SensitiveButton>
    );
  },
);

const RuleButton = withTheme(
  ({
    theme,
    isPhone,
    t,
    handleRuleClick,
    disabled,
  }: {
    theme: Theme;
    t: TranslationFunction;
    handleRuleClick: (scroll: boolean) => void;
    isPhone: boolean;
    disabled: boolean;
  }) => (
    <button
      type="button"
      onClick={() =>
        handleRuleClick(isPhone && theme.user.speakFormPosition === 'fixed')
      }
      disabled={disabled}
    >
      {t('game_client:speak.rule')}
    </button>
  ),
);
