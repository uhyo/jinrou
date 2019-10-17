import { GameStore } from '../game-view';
import { observable } from 'mobx';
import { i18n, TranslationFunction } from '../../i18n';
import { SilentDriver } from '../game-tutorial/story/driver';
import { UserInfo } from '../game-tutorial/defs';

export class GameStartTutorialStore {
  @observable.ref
  public gameStore: GameStore = new GameStore();
  private t: TranslationFunction;

  constructor(public userInfo: UserInfo, private i18n: i18n) {
    this.t = i18n.getFixedT(i18n.language, 'tutorial_game_start');
  }

  public initialize = async () => {
    const driver = new SilentDriver(this.t, this);

    console.log(driver.t(`tutorial_game:guide.npc1`));
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
  };
}
