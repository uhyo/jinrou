import { TranslationFunction } from '../../../../i18n';
import { GameTutorialStore } from '../../store';
import { Driver } from '../defs';
import { Cancellation } from './cancellation';
import { arrayMapToObjectEntries } from '../../../../util/array-map-to-object';

/**
 * @package
 */
export abstract class DriverBase {
  protected cancellation = new Cancellation();
  constructor(
    public t: TranslationFunction,
    protected store: GameTutorialStore,
  ) {}

  public abstract messageDialog: Driver['messageDialog'];

  /**
   * Get a player by id.
   */
  protected getPlayer = (id: string) => {
    return this.store.innerStore.players.find(pl => pl.id === id);
  };
  protected getMe = () => {
    const { innerStore, userInfo } = this.store;
    return innerStore.players.find(pl => pl.realid === userInfo.userid);
  };

  public randomAlivePlayer: Driver['randomAlivePlayer'] = (
    excludeId?: string,
  ) => {
    const { innerStore, userInfo } = this.store;
    const candidates = innerStore.players.filter(
      pl => !pl.dead && pl.id !== userInfo.userid && pl.id !== excludeId,
    );
    if (candidates.length == 0) {
      // !?
      return null;
    }
    const r = Math.floor(Math.random() * candidates.length);
    return candidates[r].id;
  };

  public addLog: Driver['addLog'] = query => {
    const log = {
      userid: '',
      ...query,
      time: Date.now(),
      to: null,
    } as const;
    this.store.innerStore.addLog(log);
  };

  public addPlayer: Driver['addPlayer'] = ({ emitLog, ...player }) => {
    this.store.innerStore.addPlayer(player);
    if (emitLog) {
      this.addLog({
        mode: 'system',
        comment: this.t('game:system.rooms.enter', {
          name: player.name,
        }),
      });
    }
  };

  public killPlayer: Driver['killPlayer'] = (plId, buryLogType) => {
    const { innerStore } = this.store;
    const pl = this.getPlayer(plId);
    if (!pl) {
      return;
    }
    innerStore.updatePlayer(pl.id, {
      dead: true,
    });
    if (buryLogType != null) {
      this.addLog({
        mode: 'system',
        comment: this.t(`game:found.${buryLogType}`, {
          name: pl.name,
        }),
      });
    }
  };

  public openForm: Driver['openForm'] = form => {
    const { innerStore } = this.store;
    const roleInfo = innerStore.roleInfo;
    if (roleInfo == null) {
      // !?
      return;
    }
    // default form options
    const {
      type,
      objid,
      formType,
      options = innerStore.players.filter(pl => !pl.dead).map(pl => ({
        name: pl.name,
        value: pl.id,
      })),
      data = undefined,
    } = form;
    this.setRoleInfo({
      ...roleInfo,
      forms: [
        ...roleInfo.forms,
        {
          type,
          objid,
          formType,
          options,
          data,
        },
      ],
    });
  };

  public closeForm: Driver['closeForm'] = objid => {
    const { innerStore } = this.store;
    const { roleInfo } = innerStore;

    if (roleInfo == null) {
      return;
    }
    this.setRoleInfo({
      ...roleInfo,
      forms: roleInfo.forms.filter(f => f.objid !== objid),
    });
  };

  public voteTo: Driver['voteTo'] = userid => {
    const { userInfo } = this.store;
    const pl = this.getPlayer(userid);
    if (pl == null) {
      // no target
      this.messageDialog({
        message: this.t('game:error.voting.noTarget'),
      });
      return false;
    }
    if (userInfo.userid === userid) {
      // cannot vote to myself
      this.messageDialog({
        message: this.t('game:error.voting.self'),
      });
      return false;
    }

    this.addLog({
      mode: 'voteto',
      comment: this.t('game:system.votingbox.voted', {
        name: userInfo.name,
        target: pl.name,
      }),
    });
    return true;
  };

  public divinerSkillTo: Driver['divinerSkillTo'] = userid => {
    const { userInfo } = this.store;
    const targetPl = this.getPlayer(userid);

    return {
      select: () => {
        if (targetPl == null) {
          return;
        }
        this.addLog({
          mode: 'skill',
          comment: this.t('roles:Diviner.select', {
            name: userInfo.name,
            target: targetPl.name,
          }),
        });
      },
      result: () => {
        if (targetPl == null) {
          return;
        }
        this.addLog({
          mode: 'skill',
          comment: this.t('roles:Diviner.resultlog', {
            name: userInfo.name,
            target: targetPl.name,
            result: this.t('roles:fortune.human'),
          }),
        });
      },
    };
  };

  public execute: Driver['execute'] = (
    target,
    myvote,
    other = this.store.userInfo.userid,
  ) => {
    const { innerStore, userInfo } = this.store;
    const alives = innerStore.players.filter(({ dead }) => !dead);
    const voteresult = alives.map(pl => ({
      id: pl.id,
      name: pl.name,
      voteto:
        userInfo.userid === pl.id ? myvote : target === pl.id ? other : target,
    }));
    this.addLog({
      mode: 'voteresult',
      voteresult,
      tos: arrayMapToObjectEntries(alives, ({ id }) => [
        id,
        voteresult.filter(v => v.voteto === id).length,
      ]),
    });
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
    this.addPlayer({
      emitLog: true,
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
  public ready(setReady?: boolean) {
    const {
      store: { innerStore, userInfo },
    } = this;
    const pl = innerStore.players.find(pl => pl.realid === userInfo.userid);
    if (pl == null) {
      return false;
    }
    const { flags } = pl;
    const readyNow = flags.includes('ready');
    const newReady = setReady != null ? setReady : !readyNow;
    if (newReady !== readyNow) {
      const newFlags = readyNow
        ? flags.filter(f => f !== 'ready')
        : flags.concat('ready');
      innerStore.updatePlayer(pl.id, {
        flags: newFlags,
      });
    }
    return newReady;
  }

  public changeGamePhase: Driver['changeGamePhase'] = ({
    gameStart,
    timer,
    ...query
  }) => {
    const {
      store: { innerStore },
    } = this;
    const roomControls = gameStart ? null : undefined;
    if (gameStart) {
      const players = innerStore.players.map(pl => ({
        ...pl,
        flags: [],
      }));

      innerStore.resetPlayers(players);
    }

    innerStore.update({
      timer,
      roomControls,
      gameInfo: {
        ...innerStore.gameInfo,
        status: 'playing',
        ...query,
      },
    });
    this.addLog({
      mode: 'nextturn',
      comment: this.t(`game:system.phase.${query.night ? 'night' : 'day'}`, {
        day: query.day,
      }),
      day: query.day,
      night: query.night,
    });
  };

  public endGame: Driver['endGame'] = ({ loser }) => {
    const { innerStore, userInfo } = this.store;
    // TODO
    this.addLog({
      mode: 'nextturn',
      comment: this.t('game:system.judge', {
        short: this.t('game:judge.short.human'),
        result: this.t('game:judge.human'),
      }),
      day: 0,
      night: false,
    });

    innerStore.update({
      gameInfo: {
        ...innerStore.gameInfo,
        finished: true,
        status: 'finished',
      },
      timer: {
        enabled: false,
        name: '',
        target: 0,
      },
    });

    const players = innerStore.players.map(pl => ({
      ...pl,
      winner: pl.id !== loser,
      jobname:
        pl.id === loser
          ? this.t('roles:jobname.Werewolf')
          : pl.id === userInfo.userid
            ? this.t('roles:jobname.Diviner')
            : this.t('roles:jobname.Human'),
    }));

    innerStore.resetPlayers(players);

    if (innerStore.roleInfo != null) {
      this.setRoleInfo({
        ...innerStore.roleInfo,
        win: true,
      });
    }
  };

  public setRoleInfo: Driver['setRoleInfo'] = roleInfo => {
    this.store.innerStore.update({
      roleInfo,
    });
  };
}
