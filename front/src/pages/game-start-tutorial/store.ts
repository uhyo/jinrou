import { GameStore } from '../game-view';
import { observable } from 'mobx';
import { i18n } from '../../i18n';

export class GameStartTutorialStore {
  @observable.ref
  public innerStore: GameStore = new GameStore();

  constructor(private i18n: i18n) {}
}
