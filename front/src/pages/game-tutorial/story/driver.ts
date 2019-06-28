import { showMessageDialog } from '../../../dialog';
import { TranslationFunction } from '../../../i18n';
import { Driver, DriverMessageDialog } from './defs';
import { GameTutorialStore } from '../store';
import { SpeakQuery } from '../../game-view/defs';

class DriverBase {
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
}

export class InteractiveDriver extends DriverBase implements Driver {
  get step() {
    return this.store.step;
  }
  public sleep: Driver['sleep'] = duration => {
    return new Promise(resolve => {
      setTimeout(resolve, duration);
    });
  };
  public messageDialog(d: DriverMessageDialog) {
    return showMessageDialog({
      modal: true,
      title: this.t('common.messageDialog.title') as string,
      ok: this.t('common.messageDialog.ok'),
      ...d,
    });
  }

  public getSpeakHandler() {
    return (query: SpeakQuery) => {
      const store = this.store;
      const innerStore = store.innerStore;
      const mode = ({
        waiting: store.isUserInRoom ? 'prepare' : 'audience',
        playing: innerStore.gameInfo.night ? 'monologue' : 'day',
        finished: 'prepare',
      } as const)[innerStore.gameInfo.status];

      this.addLog({
        mode,
        comment: query.comment,
        name: store.userInfo.name,
        size: query.size || undefined,
        userid: store.userInfo.userid,
      });
    };
  }
}
