import { DriverBase, ParentStore } from './base';
import { Driver, DriverMessageDialog } from '../defs';
import { SpeakQuery } from '../../../game-view/defs';
import { showMessageDialog } from '../../../../dialog';

interface ParentStoreInteractive extends ParentStore {
  step: () => void;
  isUserInRoom: boolean;
}

export class InteractiveDriver extends DriverBase<ParentStoreInteractive>
  implements Driver {
  get step() {
    return this.store.step;
  }
  public cancelStep() {
    this.cancellation.cancelAll();
  }
  public sleep: Driver['sleep'] = this.cancellation.toCancellable(duration => {
    return new Promise(resolve => {
      setTimeout(resolve, duration);
    });
  });
  public messageDialog = this.cancellation.toCancellable(
    (d: DriverMessageDialog) => {
      return showMessageDialog({
        modal: true,
        title: this.t('common.messageDialog.title') as string,
        ok: this.t('common.messageDialog.ok'),
        ...d,
      });
    },
  );

  public getSpeakHandler() {
    return (query: SpeakQuery) => {
      const store = this.store;
      const innerStore = store.gameStore;
      const mode = ({
        waiting: store.isUserInRoom ? 'prepare' : 'audience',
        playing:
          (query.mode as any) ||
          (innerStore.gameInfo.night ? 'monologue' : 'day'),
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
  public getJoinHandler: Driver['getJoinHandler'] = () => () => {
    this.join();
  };
  public getUnjoinHandler: Driver['getUnjoinHandler'] = () => () => {
    this.unjoin();
  };
  public getReadyHandler: Driver['getReadyHandler'] = () => () => {
    this.ready();
  };
  public getRejectionHandler: Driver['getRejectionHandler'] = () => () => {
    showMessageDialog({
      modal: true,
      title: this.t('common:errorDialog.title'),
      ok: this.t('common:errorDialog.close'),
      message: this.t('common.notTaughtMessage'),
    });
  };
}
