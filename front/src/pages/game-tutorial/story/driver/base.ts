import { TranslationFunction } from '../../../../i18n';
import { GameTutorialStore } from '../../store';
import { Driver } from '../defs';

/**
 * @package
 */
export class DriverBase {
  constructor(
    public t: TranslationFunction,
    protected store: GameTutorialStore,
  ) {}

  public addLog: Driver['addLog'] = query => {
    const log = {
      userid: '',
      ...query,
      time: Date.now(),
      to: null,
    } as const;
    this.store.innerStore.addLog(log);
  };

  /**
   * process a join of user.
   * @returns whether the user newly joined.
   */
  public join() {
    const {
      store: { innerStore, userInfo },
    } = this;
    if (innerStore.players.find(player => player.realid === userInfo.userid)) {
      // already in the room!
      return false;
    }
    // add user to the room.
    innerStore.addPlayer({
      id: userInfo.userid,
      realid: userInfo.userid,
      name: userInfo.name,
      anonymous: false,
      dead: false,
      icon: userInfo.icon,
      winner: null,
      jobname: null,
      flags: [],
    });
    // change the room controls.
    innerStore.update({
      roomControls: {
        type: 'prelude',
        owner: false,
        joined: true,
        old: false,
        blind: false,
        theme: false,
      },
    });
    // show join log.
    this.addLog({
      mode: 'system',
      comment: this.t('game:system.rooms.enter', {
        name: userInfo.name,
      }),
    });

    return true;
  }
}
