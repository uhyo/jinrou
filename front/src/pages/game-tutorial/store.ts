import { GameStore } from '../game-view';
import { i18n, TranslationFunction } from '../../i18n';
import { computed, observable, action } from 'mobx';
import {
  StoryInputInterface,
  StoryInputRoomHeaderInterface,
  Driver,
} from './story/defs';
import { InteractiveDriver, SilentDriver } from './story/driver';
import { phases } from './story/phases';
import { UserInfo, currentPhaseStorageKey } from './defs';
import { isCancellationError } from './story/driver/cancellation';

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
      flags: ['ready'],
    });
    this.innerStore.logs.initializeLogs([]);
  }

  /**
   * Proceed a step with given driver.
   * returns true if proceeded to the next step.
   */
  private stepWithDriver = async (driver: Driver) => {
    const phase = phases[this.phase];
    if (phase == null) {
      // ???
      return false;
    }
    try {
      const next = await phase.step(driver);
      if (next != null) {
        this.setPhase(next);
        const nextPhase = phases[next];
        console.log('next', next, nextPhase);
        if (nextPhase != null && nextPhase.init != null) {
          nextPhase.init(driver);
        }
        return true;
      }
    } catch (e) {
      if (!isCancellationError(e)) {
        // cancellationErrorなら無視する
        throw e;
      }
    }
    return false;
  };

  /**
   * Proceed a step with given driver.
   * returns true if proceeded to the next step.
   */
  public step = async (): Promise<boolean> => {
    return this.stepWithDriver(this.interactiveDriver);
  };

  /**
   * Initialize the story.
   */
  public initialize = async () => {
    const goalPhase = Number(localStorage[currentPhaseStorageKey]);
    if (!Number.isFinite(goalPhase)) {
      // no initial phase.
      localStorage.removeItem(currentPhaseStorageKey);
      this.phase = 0;
      return this.step();
    }
    const driver = new SilentDriver(this.t, this);
    while (this.phase !== goalPhase || driver.stepCalled) {
      driver.stepCalled = false;
      const proc = await this.stepWithDriver(driver);
      if (!proc) {
        break;
      }
    }
  };

  @action
  public setPhase(phase: number) {
    this.phase = phase;
    localStorage[currentPhaseStorageKey] = String(phase);
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
