import * as React from 'react';
import styled from '../../util/styled';
import { Transition } from 'react-transition-group';
import * as Swipeable from 'react-swipeable';

import { ThemeProvider, withProps } from '../../util/styled';
import { i18n } from 'i18next';
import { observer } from 'mobx-react';

import { bind } from '../../util/bind';
import { themeStore } from '../../theme';
import { I18nProvider, I18n } from '../../i18n';

import {
  RuleGroup,
  RoomControlHandlers,
  RoleCategoryDefinition,
} from '../../defs';
import { SpeakState, LogVisibility, SpeakQuery } from './defs';
import { GameStore, UpdateQuery } from './store';
import { JobInfo } from './job-info';
import { SpeakForm } from './speak-form';
import { JobForms } from './job-forms';
import { Logs } from './logs';
import { ShowRule } from './rule';

import { Players } from './players';
import { RoomControls } from './room-controls';
import { lightA } from '../../styles/a';
import { GlobalStyle } from './global-style';
import { phone, notPhone } from '../../common/media';
import { computeGlobalStyle } from '../../theme/global-style';
import { styleModeOf } from './logic/style-mode';
import { AppStyling } from '../../styles/phone';
import { speakFormZIndex, ruleZIndex } from '../../common/z-index';

interface IPropGame {
  /**
   * i18n instance.
   */
  i18n: i18n;
  /**
   * ID of this room.
   */
  roomid: number;
  /**
   * store.
   */
  store: GameStore;
  /**
   * Definition of categories.
   */
  categories: RoleCategoryDefinition[];
  /**
   * Definition of rules.
   */
  ruleDefs: RuleGroup;
  /**
   * Color of each team.
   */
  teamColors: Record<string, string | undefined>;
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
  /**
   * Handle a will update event.
   */
  onWillChange: (will: string) => void;
  /**
   * Handlers of room prelude.
   */
  roomControlHandlers: RoomControlHandlers;
}

@observer
export class Game extends React.Component<IPropGame, {}> {
  private ruleElement = React.createRef<HTMLElement>();
  public render() {
    const {
      i18n,
      roomid,
      store,
      categories,
      ruleDefs,
      teamColors,
      onJobQuery,
      onWillChange,
      roomControlHandlers,
    } = this.props;
    const {
      gameInfo,
      roleInfo,
      speakState,
      logVisibility,
      rule,
      ruleOpen,
      timer,
      players,
      roomControls,
      logPickup,
      speakFocus,
    } = store;

    const styleMode = styleModeOf(roleInfo, gameInfo);
    const theme = {
      user: themeStore.themeObject,
      teamColors,
    };

    return (
      <ThemeProvider theme={theme} mode={styleMode}>
        <I18nProvider i18n={i18n}>
          <AppWrapper>
            {/* List of players. */}
            <RoomHeaderPart>
              <Players players={players} onFilter={this.handleLogFilter} />
            </RoomHeaderPart>
            {/* Room control buttons. */}
            {roomControls != null ? (
              <I18n>
                {t => (
                  <RoomPreludePart>
                    <RoomControls
                      roomControls={roomControls}
                      t={t}
                      roomid={roomid}
                      players={players}
                      handlers={roomControlHandlers}
                    />
                  </RoomPreludePart>
                )}
              </I18n>
            ) : null}
            {/* Information of your role. */}
            <JobInfoPart speakFocus={speakFocus}>
              <JobInfo roleInfo={roleInfo} timer={timer} players={players} />
            </JobInfoPart>
            {/* Open forms. */}
            {gameInfo.status === 'playing' && roleInfo != null ? (
              <RoomHeaderPart>
                <JobForms forms={roleInfo.forms} onSubmit={onJobQuery} />
              </RoomHeaderPart>
            ) : null}
            {/* Form for speak and other utilities. */}
            <SpeakFormPart>
              <SpeakForm
                gameInfo={gameInfo}
                roleInfo={roleInfo}
                players={players}
                logVisibility={logVisibility}
                rule={rule != null}
                onUpdate={this.handleSpeakUpdate}
                onUpdateLogVisibility={this.handleLogVisibilityUpdate}
                onSpeak={this.handleSpeak}
                onRefuseRevival={this.handleRefuseRevival}
                onRuleOpen={this.handleRuleOpen}
                onWillChange={onWillChange}
                onFocus={this.handleSpeakFocus}
                {...speakState}
              />
            </SpeakFormPart>
            {/* Main game screen. */}
            <MainWrapper>
              {/* Rule panel if open. */}
              <Transition in={rule != null && ruleOpen} timeout={250}>
                {(state: string) => {
                  const closed =
                    state === 'exiting' ||
                    state === 'exited' ||
                    state === 'unmounted';
                  return (
                    <>
                      <RuleWrapper closed={closed}>
                        {rule != null ? (
                          <RuleStickyWrapper closed={closed}>
                            <RuleInnerWrapper innerRef={this.ruleElement}>
                              <Swipeable
                                onSwipingLeft={this.handleRuleSwipeToLeft}
                                onSwipingRight={this.handleRuleSwipeToRight}
                              >
                                <ShowRule
                                  rule={rule}
                                  categories={categories}
                                  ruleDefs={ruleDefs}
                                />
                              </Swipeable>
                            </RuleInnerWrapper>
                          </RuleStickyWrapper>
                        ) : null}
                      </RuleWrapper>
                      {/* Logs. */}
                      <LogsWrapper ruleOpen={!closed}>
                        <Logs
                          logs={store.logs}
                          visibility={store.logVisibility}
                          icons={store.icons}
                          rule={store.rule}
                          logPickup={logPickup}
                          onResetLogPickup={this.handleResetLogPickup}
                        />
                      </LogsWrapper>
                    </>
                  );
                }}
              </Transition>
            </MainWrapper>
            <GlobalStyle />
          </AppWrapper>
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
  protected handleRuleOpen(scroll: boolean): void {
    const { store } = this.props;
    // toggle the rule pane.
    const prevOpen = store.ruleOpen;
    store.update({
      ruleOpen: !prevOpen,
    });
    if (!prevOpen && scroll && this.ruleElement.current != null) {
      // if scroll request is positive,
      // scroll to the rule pane.
      this.ruleElement.current.scrollIntoView(true);
    }
  }
  /**
   * handle swipe of rule to left.
   */
  @bind
  protected handleRuleSwipeToLeft(): void {
    // when rule is swiped to left, it is open.
    this.props.store.update({
      ruleOpen: true,
    });
  }
  /**
   * handle swipe of rule to right.
   */
  @bind
  protected handleRuleSwipeToRight(): void {
    // when rule is swiped to left, rule is closed.
    this.props.store.update({
      ruleOpen: false,
    });
  }
  /**
   * Handle update of log pickup filter.
   */
  @bind
  protected handleLogFilter(userid: string): void {
    const { store } = this.props;
    // If userid is same to the current one, reset filter.
    store.update({
      logPickup: store.logPickup === userid ? null : userid,
    });
  }
  /**
   * Handle setting signal of log pickup.
   */
  @bind
  protected handleResetLogPickup(): void {
    this.props.store.update({ logPickup: null });
  }
  /**
   * Handle a focus change of speak input.
   */
  @bind
  protected handleSpeakFocus(focus: boolean): void {
    this.props.store.update({
      speakFocus: focus,
    });
  }
}

/**
 * Wrapper of whole app.
 */
const AppWrapper = styled(AppStyling)`
  display: flex;
  flex-flow: column nowrap;
`;

/**
 * Wrapper of each room control.
 */
const RoomHeaderPart = styled.div`
  margin: 4px 0;
  padding: 0 8px;
  ${phone`
    padding: 0;
  `};
`;

/**
 * Wrapper of room prelude.
 */
const RoomPreludePart = styled(RoomHeaderPart)`
  display: flex;
  flex-flow: row wrap;

  > button {
    margin: 2px;
  }

  ${phone`
    padding: 0 8px;
    justify-content: space-between;
    > button {
      margin: 3px;
    }
  `};
`;

/**
 * Wrapper of speak form.
 */
const SpeakFormPart = styled(RoomHeaderPart)`
  background-color: ${({ theme }) => theme.globalStyle.background};
  ${phone`
    /* On phones, speak form is fixed to the bottom. */
    order: 5;
    position: sticky;
    z-index: ${speakFormZIndex};
    left: 0;
    bottom: 0;

    margin: 0;
    padding: 4px 8px;
    border-top: 1px solid ${({ theme }) => theme.globalStyle.color};
  `};
`;

/**
 * Wrapper of jobinfo form.
 */
const JobInfoPart = withProps<{
  /**
   * Whether speak focus has a focus.
   */
  speakFocus: boolean;
}>()(styled(RoomHeaderPart))`
  ${phone`
    position: sticky;
    left: 0;
    top: 0;
    ${({ speakFocus }) => (speakFocus ? 'opacity: 0.15;' : '')}
  `};
`;

/**
 * Wrapper for main game panel.
 */
const MainWrapper = styled.div`
  display: flex;
  flex-flow: row nowrap;
`;

/**
 * Wrapper of logs.
 */
const LogsWrapper = withProps<{
  /**
   * Whether the rule pane is open.
   */
  ruleOpen?: boolean;
}>()(styled.div)`
  flex: auto 1 1;
  order: 1;
  ${phone`
    transition: margin-left 250ms ease-out;
    margin-left: ${({ ruleOpen }) => (ruleOpen ? '-20em' : '0)')};
  `}
`;

interface IPropsRuleWrapper {
  /**
   * Whether this is in closed state.
   */
  closed?: boolean;
}
/**
 * Wrapper of rule.
 */
const RuleWrapper = withProps<IPropsRuleWrapper>()(styled.div)`
  transition: width 250ms ease-out;
  flex: auto 0 0;
  width: ${({ closed }) => (closed ? '0' : '20em')};
  order: 2;

  z-index: ${ruleZIndex};
  background-color: #ffd1f2;
  color: black;

  a {
    ${lightA}
  }
`;

const RuleStickyWrapper = withProps<IPropsRuleWrapper>()(styled.div)`
  transition: width 250ms ease-out;
  width: ${({ closed }) => (closed ? '0' : '20em')};
  position: sticky;
  top: 0;
  overflow-x: hidden;
`;

const RuleInnerWrapper = styled.div`
  box-sizing: border-box;
  max-height: 100vh;
  width: 20em;
  padding: 5px;
  ${phone`
    max-height: 80vh;
  `};
`;
