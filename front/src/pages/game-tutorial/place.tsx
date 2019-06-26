import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { i18n } from '../../i18n';
import { GameTutorial } from './component';
import { GameTutorialStore } from './store';

export interface IPlaceOptions {
  /**
   * i18n instance to use.
   */
  i18n: i18n;
  /**
   * Node to place the component to.
   */
  node: HTMLElement;
  /**
   * Color of teams.
   */
  teamColors: Record<string, string | undefined>;
}

export interface IPlaceResult {
  store: GameTutorialStore;
  unmount(): void;
}

export function place({ i18n, node, teamColors }: IPlaceOptions): IPlaceResult {
  const store = new GameTutorialStore();
  const com = (
    <GameTutorial i18n={i18n} store={store} teamColors={teamColors} />
  );

  ReactDOM.render(com, node);

  return {
    store,
    unmount: () => {
      ReactDOM.unmountComponentAtNode(node);
    },
  };
}
