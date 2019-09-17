import { ComponentProps } from 'react';
import { Game } from '../../game-view/component';
import { RoomControlHandlers } from '../../../defs';
import { IMessageDialog } from '../../../dialog/defs';
import { TranslationFunction } from '../../../i18n';
import {
  SpeakQuery,
  NormalLog,
  PlayerInfo,
  TimerInfo,
  RoleInfo,
  FormDesc,
  NextTurnLog,
  VoteResultLog,
} from '../../game-view/defs';

/**
 * Input to the story.
 */
export type StoryInputInterface = Pick<
  ComponentProps<typeof Game>,
  'onSpeak' | 'onJobQuery' | 'onRefuseRevival' | 'onWillChange'
>;

/**
 * Input to the story which is inside room header.
 */
export type StoryInputRoomHeaderInterface = Pick<
  RoomControlHandlers,
  'join' | 'unjoin' | 'ready' | 'helper'
>;

export type DriverMessageDialog = PartiallyPartial<
  IMessageDialog,
  'modal' | 'ok' | 'title'
>;
export type DriverAddLogQuery =
  | PartiallyPartial<
      Pick<NormalLog, 'mode' | 'size' | 'userid' | 'name' | 'comment'>,
      'userid'
    >
  | Omit<NextTurnLog, 'time'>
  | Omit<VoteResultLog, 'time'>;
export type DriverAddPlayerQuery = PlayerInfo & {
  emitLog?: boolean;
};
export type ChangePhaseQuery = {
  day: number;
  night: boolean;
  timer?: TimerInfo;
  gameStart?: boolean;
};

export type EndGameQuery = {
  loser: string | null;
};

export interface Driver {
  t: TranslationFunction;
  step: () => unknown;
  /**
   * cancel ongoing step.
   */
  cancelStep: () => void;
  /**
   * Select an alive player randomly.
   */
  randomAlivePlayer(excludeId?: string): string | null;
  /**
   * Sleep for given duration (in ms)
   */
  sleep(duration: number): Promise<void>;
  /**
   * Show a message dialog to user.
   */
  messageDialog(d: DriverMessageDialog): Promise<void>;
  /**
   * Add a log.
   */
  addLog(query: DriverAddLogQuery): void;
  /**
   * Add a player.
   */
  addPlayer(player: DriverAddPlayerQuery): void;
  /**
   * Kill a player and show a bury message if found is provided.
   */
  killPlayer(playerId: string, found?: string): void;
  /**
   * Process join of user.
   */
  join(): void;
  /**
   * Process unjoin of user.
   */
  unjoin(): void;
  /**
   * Process ready of user.
   * @returns readyness state after this.
   */
  ready(setReady?: boolean): boolean;
  /**
   * change a phase.
   */
  changeGamePhase(gameInfo: ChangePhaseQuery): void;
  /**
   * End the game.
   */
  endGame(query: EndGameQuery): void;
  /**
   * set RoleInfo.
   */
  setRoleInfo(roleInfo: RoleInfo): void;
  /**
   * Open a new form of player.
   * Some form desc is optional.
   */
  openForm(form: PartiallyPartial<FormDesc, 'options' | 'data'>): void;
  /**
   * Close a form of given objid.
   */
  closeForm(objid: string): void;
  /**
   * Perform a vote to given player.
   * @returns whether vote was successful.
   */
  voteTo(userid: string): boolean;
  /**
   * Generate driver functions to run a Diviner skill to given player.
   */
  divinerSkillTo(
    userid: string,
  ): {
    select(): void;
    result(): void;
  };

  /**
   * Perform a punishment.
   */
  execute(target: string, myVote: string, other?: string): void;

  /**
   * Get a handler of speak.
   */
  getSpeakHandler(): (query: SpeakQuery) => void;
  /**
   * Get a handler of join.
   */
  getJoinHandler(): RoomControlHandlers['join'];
  /**
   * Get a handler of unjoin.
   */
  getUnjoinHandler(): RoomControlHandlers['unjoin'];
  /**
   * Get a handler of ready.
   */
  getReadyHandler(): RoomControlHandlers['ready'];
  /**
   * Get a handler which shows rejection message.
   */
  getRejectionHandler(): () => void;
}

/**
 * Storage which can be used during the tutorial.
 */
export interface TutorialStorage {
  /**
   * target of day 2 form.
   */
  day2DayTarget: string | null;
  /**
   * target of night 2 form.
   */
  day2NightTarget: string | null;
  /**
   * victim of night 2.
   */
  day2NightVictim: string | null;
  /**
   * target of day 3 form.
   */
  day3DayTarget: string | null;
  /**
   * Victom of day 3.
   */
  day3DayVictim: string | null;
}

/**
 * Definition of phase object.
 */
export interface Phase {
  isFinished?: boolean;
  init?(driver: Driver): void;
  step(driver: Driver, storage: TutorialStorage): Promise<number | void>;
  getStory(
    driver: Driver,
    storage: TutorialStorage,
  ): {
    gameInput?: Partial<StoryInputInterface>;
    roomHedaerInput?: Partial<StoryInputRoomHeaderInterface>;
  };
}
