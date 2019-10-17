import { GameStore } from '../game-view';
import { observable, computed } from 'mobx';
import { i18n, TranslationFunction } from '../../i18n';
import { SilentDriver, InteractiveDriver } from '../game-tutorial/story/driver';
import { UserInfo } from '../game-tutorial/defs';

export class GameStartTutorialStore {
  @observable.ref
  public gameStore: GameStore = new GameStore();
  private t: TranslationFunction;
  public readonly silentDriver: SilentDriver;
  public readonly interactiveDriver: InteractiveDriver;

  constructor(public userInfo: UserInfo, private i18n: i18n) {
    this.t = i18n.getFixedT(i18n.language, 'tutorial_game_start');

    this.silentDriver = new SilentDriver(this.t, this);
    this.interactiveDriver = new InteractiveDriver(this.t, this);
  }

  public reset() {
    this.gameStore = new GameStore();
    this.initialize();
  }

  public initialize = async () => {
    const { gameStore, silentDriver: driver } = this;
    gameStore.roomName = this.t('room.title');
    gameStore.gameInfo = {
      day: 0,
      night: false,
      finished: false,
      status: 'waiting',
      watchspeak: true,
    };
    gameStore.roomControls = {
      type: 'prelude',
      owner: true,
      joined: false,
      old: false,
      blind: false,
      theme: false,
    };
    gameStore.logs.initializeLogs([]);

    // add 6 players
    for (let i = 0; i < 6; i++) {
      const realid = `身代わりくん${i + 2}`;
      driver.addPlayer({
        id: realid,
        realid,
        name: driver.t(`tutorial_game:guide.npc${i + 1}`),
        anonymous: false,
        icon: null,
        winner: null,
        jobname: null,
        dead: false,
        flags: ['ready'],
        emitLog: true,
      });
    }
    // initial log
    driver.addLog({
      mode: 'prepare',
      name: this.t('tutorial_game:guide.name'),
      comment: this.t('descriptionLog'),
    });
  };

  // This is needed for InteractiveDriver
  public step() {}

  @computed
  get isUserInRoom(): boolean {
    return (
      this.gameStore.players.find(
        player => player.realid === this.userInfo.userid,
      ) != null
    );
  }
}
