import { GameStore } from '../game-view';
import { i18n, TranslationFunction } from '../../i18n';
import { computed } from 'mobx';
import {
  StoryInputInterface,
  StoryInputRoomHeaderInterface,
} from './story/defs';
import { InteractiveDriver } from './story/driver';
import { phases } from './story/phases';

export class GameTutorialStore {
  public innerStore: GameStore = new GameStore();
  public phase = 0;
  private t: TranslationFunction;
  private interactiveDriver: InteractiveDriver;
  constructor(private i18n: i18n) {
    this.t = i18n.getFixedT(i18n.language, 'tutorial_game');
    this.interactiveDriver = new InteractiveDriver(this.t);
    this.innerStore.gameInfo = {
      day: 0,
      night: false,
      finished: false,
      status: 'waiting',
      watchspeak: true,
    };
    this.innerStore.roomControls = {
      type: 'prelude',
      owner: false,
      joined: false,
      old: false,
      blind: false,
      theme: false,
    };
  }

  public step = async (skip: boolean) => {
    const driver = this.interactiveDriver;
    const phase = phases[this.phase];
    if (phase == null) {
      // ???
      return;
    }
    await phase.step(driver);
  };
  public normalStep = () => this.step(false);
  public skipStep = () => this.step(true);

  @computed
  get story(): {
    gameInput: Partial<StoryInputInterface>;
    roomHedaerInput: Partial<StoryInputRoomHeaderInterface>;
  } {
    const noop = () => {};
    switch (this.phase) {
      case 0: {
        // First phase:
        break;
      }
    }
    return {
      gameInput: {},
      roomHedaerInput: {},
    };
  }
}
