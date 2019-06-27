import { ComponentProps } from 'react';
import { Game } from '../../game-view/component';
import { noop } from 'mobx/lib/internal';
import { RoomControlHandlers } from '../../../defs';

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
