import { ComponentProps } from 'react';
import { Game } from '../../game-view/component';
import { RoomControlHandlers } from '../../../defs';
import { IMessageDialog } from '../../../dialog/defs';
import { i18n, TranslationFunction } from '../../../i18n';
import { GameTutorialStore } from '../store';
import {
  SpeakQuery,
  NormalLog,
  PlayerInfo,
  GameInfo,
  TimerInfo,
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
export type DriverAddLogQuery = PartiallyPartial<
  Pick<NormalLog, 'mode' | 'size' | 'userid' | 'name' | 'comment'>,
  'userid'
>;
export type DriverAddPlayerQuery = PlayerInfo & {
  emitLog?: boolean;
};
export type ChangePhaseQuery = {
  day: number;
  night: boolean;
  timer?: TimerInfo;
};

export interface Driver {
  t: TranslationFunction;
  step: () => unknown;
  /**
   * cancel ongoing step.
   */
  cancelStep: () => void;
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
 * Definition of phase object.
 */
export interface Phase {
  init?(driver: Driver): void;
  step(driver: Driver): Promise<number | void>;
  getStory(
    driver: Driver,
  ): {
    gameInput?: Partial<StoryInputInterface>;
    roomHedaerInput?: Partial<StoryInputRoomHeaderInterface>;
  };
}
