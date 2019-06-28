import { showMessageDialog } from '../../../dialog';
import { TranslationFunction } from '../../../i18n';
import { Driver, DriverMessageDialog } from './defs';
import { GameTutorialStore } from '../store';
import { SpeakQuery } from '../../game-view/defs';

export class InteractiveDriver implements Driver {
  constructor(
    public t: TranslationFunction,
    private store: GameTutorialStore,
  ) {}

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

      const log = {
        mode,
        comment: query.comment,
        name: store.userInfo.name,
        size: query.size || undefined,
        userid: store.userInfo.userid,
        time: Date.now(),
        to: null,
      } as const;
      this.store.innerStore.addLog(log);
    };
  }
}
