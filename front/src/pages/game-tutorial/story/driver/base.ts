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
  /**
   * process unjoin of user.
   * @returns whether unjoin is processed.
   */
  public unjoin() {
    const {
      store: { innerStore, userInfo },
    } = this;
    if (!innerStore.players.find(player => player.realid === userInfo.userid)) {
      // not in the room
      return false;
    }
    // add user to the room.
    innerStore.removePlayer(userInfo.userid);
    // change the room controls.
    innerStore.update({
      roomControls: {
        type: 'prelude',
        owner: false,
        joined: false,
        old: false,
        blind: false,
        theme: false,
      },
    });
    // show leave log.
    this.addLog({
      mode: 'system',
      comment: this.t('game:system.rooms.leave', {
        name: userInfo.name,
      }),
    });

    return true;
  }
  public ready() {
    const {
      store: { innerStore, userInfo },
    } = this;
    const pl = innerStore.players.find(pl => pl.realid === userInfo.userid);
    if (pl == null) {
      return false;
    }
    const { flags } = pl;
    const readyNow = flags.includes('ready');
    console.log(flags, readyNow);
    const newFlags = readyNow
      ? flags.filter(f => f !== 'ready')
      : flags.concat('ready');
    innerStore.updatePlayer(pl.id, {
      flags: newFlags,
    });
    return !readyNow;
  }
}
