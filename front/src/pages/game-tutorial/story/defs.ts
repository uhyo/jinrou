import { ComponentProps } from 'react';
import { Game } from '../../game-view/component';
import { RoomControlHandlers } from '../../../defs';
import { IMessageDialog } from '../../../dialog/defs';
import { i18n, TranslationFunction } from '../../../i18n';
import { GameTutorialStore } from '../store';
import { SpeakQuery } from '../../game-view/defs';

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
export interface Driver {
  t: TranslationFunction;
  /**
   * Show a message dialog to user.
   */
  messageDialog(d: DriverMessageDialog): Promise<void>;
  /**
   * Get a handler of speak.
   */
  getSpeakHandler(): (query: SpeakQuery) => void;
}

/**
 * Definition of phase object.
 */
export interface Phase {
  step(driver: Driver): Promise<number | void>;
  getStory(): {
    gameInput?: Partial<StoryInputInterface>;
    roomHedaerInput?: Partial<StoryInputRoomHeaderInterface>;
  };
}
