import { action, computed, observable } from 'mobx';

import {
  GameInfo,
  RoleInfo,
  RuleInfo,
  SpeakState,
  LogVisibility,
  Log,
} from './defs';

/**
 * Query of updating the store.
 */
export interface UpdateQuery {
  gameInfo?: GameInfo;
  roleInfo?: RoleInfo | null;
  speakState?: Partial<SpeakState>;
  logVisibility?: LogVisibility;
  rule?: RuleInfo;
  icons?: Record<string, string | undefined>;
  ruleOpen?: boolean;
}
/**
 * Store of current game state.
 */
export class GameStore {
  /**
   * current info of game.
   */
  @observable
  gameInfo: GameInfo = {
    day: 0,
    finished: false,
  };
  /**
   * Name of your role.
   */
  @observable.shallow roleInfo: RoleInfo | null = null;
  /**
   * State of speaking forms.
   */
  @observable
  speakState: SpeakState = {
    size: 'normal',
    kind: '',
    multiline: false,
    willOpen: false,
  };
  /**
   * Which day is shown to user?
   */
  @observable.shallow
  logVisibility: LogVisibility = {
    type: 'all',
  };
  /**
   * URL of icons of users.
   */
  @observable.shallow icons: Record<string, string | undefined> = {};
  /**
   * Current rule.
   */
  @observable
  rule: RuleInfo = {
    jobNumbers: undefined,
    rule: undefined,
  };
  /**
   * Whether the rule information is open.
   */
  @observable ruleOpen: boolean = false;

  /**
   * All logs.
   */
  @observable logs: Log[] = [];

  /**
   * Update current role information.
   */
  @action
  public update({
    gameInfo,
    roleInfo,
    speakState,
    logVisibility,
    icons,
    rule,
    ruleOpen,
  }: UpdateQuery): void {
    if (gameInfo != null) {
      this.gameInfo = gameInfo;
    }
    if (roleInfo !== undefined) {
      // roleInfo is either null or RoleInfo object.
      this.roleInfo = roleInfo;
    }
    if (speakState != null) {
      Object.assign(this.speakState, speakState);
    }
    if (logVisibility != null) {
      this.logVisibility = logVisibility;
    }
    if (rule != null) {
      this.rule = rule;
    }
    if (icons != null) {
      this.icons = icons;
    }
    if (ruleOpen != null) {
      this.ruleOpen = ruleOpen;
    }
    // Check consistency.
    if (
      this.roleInfo != null &&
      !this.roleInfo.speak.includes(this.speakState.kind)
    ) {
      this.speakState.kind = this.roleInfo.speak[0] || '';
    }
  }

  /**
   * Add a log to the store.
   */
  @action
  public addLog(log: Log): void {
    this.logs.push(log);
  }

  /**
   * Prepend logs to the store.
   */
  @action
  public prependLogs(logs: Log[]): void {
    this.logs.splice(0, 0, ...logs);
  }
}
