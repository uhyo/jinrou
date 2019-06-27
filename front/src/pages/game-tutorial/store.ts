import { GameStore } from '../game-view';
import { i18n } from '../../i18n';
import { computed } from 'mobx';
import {
  StoryInputInterface,
  StoryInputRoomHeaderInterface,
} from './story/defs';

export class GameTutorialStore {
  innerStore: GameStore = new GameStore();
  constructor(private i18n: i18n) {
    this.innerStore.roomControls = {
      type: 'prelude',
      owner: false,
      joined: false,
      old: false,
      blind: false,
      theme: false,
    };
  }

  @computed
  get story(): {
    gameInput: StoryInputInterface;
    roomHedaerInput: StoryInputRoomHeaderInterface;
  } {
    const noop = () => {};
    return {
      gameInput: {
        onJobQuery: noop,
        onRefuseRevival: noop,
        onSpeak: noop,
        onWillChange: noop,
      },
      roomHedaerInput: {
        join: noop,
        unjoin: noop,
        ready: noop,
        helper: noop,
      },
    };
  }
}
