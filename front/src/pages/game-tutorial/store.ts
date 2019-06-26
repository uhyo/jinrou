import { GameStore } from '../game-view';
import { i18n } from '../../i18n';

export class GameTutorialStore {
  innerStore: GameStore = new GameStore();
  constructor(private i18n: i18n) {}
}
