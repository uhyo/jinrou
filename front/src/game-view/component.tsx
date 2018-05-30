import * as React from 'react';
import { ThemeProvider } from '../util/styled';
import { i18n } from 'i18next';
import { observer } from 'mobx-react';

import { bind } from '../util/bind';
import { themeStore } from '../theme';
import { I18nProvider } from '../i18n';

import { RuleGroup } from '../defs';
import { SpeakState, LogVisibility, SpeakQuery } from './defs';
import { GameStore, UpdateQuery } from './store';
import { JobInfo } from './job-info';
import { SpeakForm } from './speak-form';
import { JobForms } from './job-forms';
import { Logs } from './logs';
import { ShowRuleWrapper } from './rule';

import { showConfirmDialog } from '../dialog';

interface IPropGame {
  /**
   * i18n instance.
   */
  i18n: i18n;
  /**
   * store.
   */
  store: GameStore;
  /**
   * List of role ids.
   */
  roles: string[];
  /**
   * Definition of rules.
   */
  ruleDefs: RuleGroup;
  /**
   * Handle a speak event.
   */
  onSpeak: (query: SpeakQuery) => void;
  /**
   * Handle a refuse revival event.
   */
  onRefuseRevival: () => void;
  /**
   * Handle a job query event.
   */
  onJobQuery: (query: Record<string, string>) => void;
}

@observer
export class Game extends React.Component<IPropGame, {}> {
  public render() {
    const { i18n, store, roles, ruleDefs, onJobQuery } = this.props;
    const {
      gameInfo,
      roleInfo,
      speakState,
      logVisibility,
      rule,
      ruleOpen,
    } = store;
    return (
      <ThemeProvider theme={themeStore.themeObject}>
        <I18nProvider i18n={i18n}>
          <div>
            {/* Information of your role. */}
            {roleInfo != null ? <JobInfo {...roleInfo} /> : null}
            {/* Open forms. */}
            {!gameInfo.finished && roleInfo != null ? (
              <JobForms forms={roleInfo.forms} onSubmit={onJobQuery} />
            ) : null}
            {/* Form for speak and other utilities. */}
            <SpeakForm
              gameInfo={gameInfo}
              roleInfo={roleInfo}
              logVisibility={logVisibility}
              rule={rule != null}
              onUpdate={this.handleSpeakUpdate}
              onUpdateLogVisibility={this.handleLogVisibilityUpdate}
              onSpeak={this.handleSpeak}
              onRefuseRevival={this.handleRefuseRevival}
              onRuleOpen={this.handleRuleOpen}
              {...speakState}
            />
            {/* Main game screen. */}
            <div>
              {/* Rule panel if open. */}
              {rule != null && ruleOpen ? (
                <ShowRuleWrapper
                  rule={rule}
                  roles={roles}
                  ruleDefs={ruleDefs}
                />
              ) : null}
              {/* Logs. */}
              <Logs
                logs={store.logs}
                visibility={store.logVisibility}
                icons={store.icons}
                rule={store.rule}
              />
            </div>
          </div>
        </I18nProvider>
      </ThemeProvider>
    );
  }
  /**
   * Handle an update to the store.
   */
  @bind
  protected handleSpeakUpdate(obj: Partial<SpeakState>): void {
    this.props.store.update({
      speakState: obj,
    });
  }
  /**
   * Handle an update to log visibility.
   */
  @bind
  protected handleLogVisibilityUpdate(obj: LogVisibility): void {
    this.props.store.update({
      logVisibility: obj,
    });
  }
  /**
   * Handle a speak event.
   */
  @bind
  protected handleSpeak(query: SpeakQuery): void {
    const { store, onSpeak } = this.props;
    // Back to the single line mode.
    store.update({
      speakState: {
        multiline: false,
      },
    });
    onSpeak(query);
  }
  /**
   * Handle a refuse revival event.
   */
  @bind
  protected handleRefuseRevival(): void {
    const { onRefuseRevival } = this.props;
    onRefuseRevival();
  }
  /**
   * handle the rule open button event.
   */
  @bind
  protected handleRuleOpen(): void {
    const { store } = this.props;
    // toggle the rule pane.
    store.update({
      ruleOpen: !store.ruleOpen,
    });
  }
}
