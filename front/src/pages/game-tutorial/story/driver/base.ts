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
}
