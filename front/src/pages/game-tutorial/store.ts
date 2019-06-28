import { GameStore } from '../game-view';
import { i18n, TranslationFunction } from '../../i18n';
import { computed, observable, action } from 'mobx';
import {
  StoryInputInterface,
  StoryInputRoomHeaderInterface,
} from './story/defs';
import { InteractiveDriver } from './story/driver';
import { phases } from './story/phases';
import { UserInfo } from './defs';

export class GameTutorialStore {
  public innerStore: GameStore = new GameStore();
  @observable
  public phase = 0;
  public skipMode = false;
  private t: TranslationFunction;
  private interactiveDriver: InteractiveDriver;
  constructor(public userInfo: UserInfo, private i18n: i18n) {
    this.t = i18n.getFixedT(i18n.language, 'tutorial_game');
    this.interactiveDriver = new InteractiveDriver(this.t, this);
    // initialize state of the room
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
    this.innerStore.addPlayer({
      id: '身代わりくん',
      realid: '身代わりくん',
      name: this.t('guide.name'),
      anonymous: false,
      dead: false,
      icon: null,
      winner: null,
      jobname: null,
      flags: [],
    });
    this.innerStore.logs.initializeLogs([]);
  }

  public step = async () => {
    const driver = this.interactiveDriver;
    const phase = phases[this.phase];
    if (phase == null) {
      // ???
      return;
    }
    const next = await phase.step(driver);
    if (next != null) {
      this.setPhase(next);
    }
  };

  @action
  public setPhase(phase: number) {
    this.phase = phase;
  }

  @computed
  get story(): {
    gameInput?: Partial<StoryInputInterface>;
    roomHedaerInput?: Partial<StoryInputRoomHeaderInterface>;
  } {
    const phase = phases[this.phase];
    if (phase == null) {
      return {};
    }
    return phase.getStory(this.interactiveDriver);
  }

  @computed
  get isUserInRoom(): boolean {
    return (
      this.innerStore.players.find(
        player => player.realid === this.userInfo.userid,
      ) != null
    );
  }
}
