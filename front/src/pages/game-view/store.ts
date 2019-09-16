import { action, computed, observable } from 'mobx';

import { Rule } from '../../defs';
import {
  GameInfo,
  RoleInfo,
  SpeakState,
  LogVisibility,
  Log,
  TimerInfo,
  PlayerInfo,
  RoomControlInfo,
  getSpeakKindPriority,
} from './defs';
import { LogStore } from './logs/log-store';
import { arrayShallowEqual } from '../../util/array-shallow-equal';
import { sortBy } from '../../util/sort-by';

/**
 * Query of updating the store.
 */
export interface UpdateQuery {
  roomName?: string;
  gameInfo?: GameInfo;
  roleInfo?: RoleInfo | null;
  speakState?: Partial<SpeakState>;
  logVisibility?: LogVisibility;
  rule?: Rule;
  icons?: Record<string, string | undefined>;
  ruleOpen?: boolean;
  timer?: TimerInfo;
  roomControls?: RoomControlInfo | null;
  logPickup?: string | null;
  speakFocus?: boolean;
}
/**
 * Store of current game state.
 */
export class GameStore {
  /**
   * Name of room.
   */
  @observable
  roomName: string = '';

  /**
   * current info of game.
   */
  @observable
  gameInfo: GameInfo = {
    day: 0,
    night: false,
    // tricky.
    finished: true,
    status: 'waiting',
    watchspeak: true,
  };
  /**
   */
  @observable.shallow
  roomControls: RoomControlInfo | null = null;
  /**
   * Name of your role.
   */
  @observable.shallow
  roleInfo: RoleInfo | null = null;
  /**
   * List of players.
   */
  @observable
  players: PlayerInfo[] = [];
  /**
   * Currently picked up user in logs.
   */
  @observable
  logPickup: string | null = null;
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
  @observable.shallow
  icons: Record<string, string | undefined> = {};
  /**
   * Current rule.
   */
  @observable
  rule: Rule | undefined = undefined;
  /**
   * Whether the rule information is open.
   */
  @observable
  ruleOpen: boolean = false;
  /**
   * Whether the speak input has focus.
   */
  @observable
  speakFocus: boolean = false;
  /**
   * State of timer.
   */
  @observable
  timer: TimerInfo = {
    enabled: false,
    name: '',
    target: 0,
  };

  /**
   * All logs.
   */
  public logs: LogStore = new LogStore();

  /**
   * Update current role information.
   */
  @action
  public update({
    roomName,
    gameInfo,
    roleInfo,
    speakState,
    logVisibility,
    icons,
    rule,
    ruleOpen,
    timer,
    roomControls,
    logPickup,
    speakFocus,
  }: UpdateQuery): void {
    if (roomName != null) {
      this.roomName = roomName;
    }
    if (gameInfo != null) {
      this.gameInfo = gameInfo;
    }
    const prevRoleInfo = this.roleInfo;
    if (roleInfo !== undefined) {
      // roleInfo is either null or RoleInfo object.
      // sort speak kinds by priority.
      if (roleInfo != null) {
        roleInfo.speak = sortBy(roleInfo.speak, getSpeakKindPriority);
      }
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
    if (timer != null) {
      this.timer = timer;
    }
    if (roomControls !== undefined) {
      this.roomControls = roomControls;
    }
    if (logPickup !== undefined) {
      this.logPickup = logPickup;
    }
    if (speakFocus != null) {
      this.speakFocus = speakFocus;
    }
    // Check consistency.
    if (roleInfo != null) {
      if (
        prevRoleInfo == null ||
        !arrayShallowEqual(roleInfo.speak, prevRoleInfo.speak)
      ) {
        this.speakState.kind = roleInfo.speak[0] || '';
      }
    }
    if (
      this.roleInfo != null &&
      !this.roleInfo.speak.includes(this.speakState.kind)
    ) {
      // if roleInfo.speak and speakState.kind are inconsistent,
      // adjust current kind.
      this.speakState.kind = this.roleInfo.speak[0] || '';
    }
  }

  /**
   * Add a log to the store.
   */
  @action
  public addLog(log: Log): void {
    this.logs.addLog(log);
  }
  /**
   * Reset current logs.
   */
  @action
  public resetLogs(): void {
    this.logs.reset();
  }
  /**
   * Add a player.
   */
  @action
  public addPlayer(player: PlayerInfo): void {
    this.players.push(player);
  }
  /**
   * Update current player.
   */
  @action
  public updatePlayer(id: string, player: Partial<PlayerInfo>): void {
    for (const p of this.players) {
      if (p.id === id) {
        // This player is updated.
        Object.assign(p, player);
        break;
      }
    }
  }
  /**
   * Remove a player.
   */
  @action
  public removePlayer(id: string): void {
    this.players = this.players.filter(p => p.id !== id);
  }
  /**
   * Reset players with given list of players.
   */
  @action
  public resetPlayers(players: PlayerInfo[]): void {
    this.players = players;
  }
}
