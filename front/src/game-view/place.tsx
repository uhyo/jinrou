import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { i18n } from 'i18next';

import { GameStore } from './store';
import { Game } from './component';
import { SpeakQuery } from './defs';

/**
 * Options to place.
 */
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
   * Handle a speak event.
   */
  onSpeak: (query: SpeakQuery) => void;
  /**
   * Handle a refuse revival event.
   */
  onRefuseRevival: () => void;
}

export interface IPlaceResult {
  unmount(): void;
}
/**
 * Place a game view component.
 * @returns Unmount point with newly created store.
 */
export function place({ i18n, node, onSpeak, onRefuseRevival }: IPlaceOptions) {
  const store = new GameStore();

  const com = (
    <Game
      i18n={i18n}
      store={store}
      onSpeak={onSpeak}
      onRefuseRevival={onRefuseRevival}
    />
  );

  ReactDOM.render(com, node);

  return {
    store,
    unmount: () => {
      ReactDOM.unmountComponentAtNode(node);
    },
  };
}
