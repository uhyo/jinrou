import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { i18n } from 'i18next';
import { runInAction } from 'mobx';

import { GameStore } from './store';
import { Game } from './component';
import { SpeakQuery, Log } from './defs';
import { makeRefuseRevivalLogic } from './logic/refuse-revival';

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
  onRefuseRevival: () => Promise<void>;
  /**
   * Handle a job query.
   */
  onJobQuery: (query: Record<string, string>) => void;
}

export interface IPlaceResult {
  /**
   * store.
   */
  store: GameStore;
  /**
   * RunInAction helper.
   */
  runInAction: typeof runInAction;
  /**
   * Unmount the component placed by place().
   */
  unmount(): void;
}
/**
 * Place a game view component.
 * @returns Unmount point with newly created store.
 */
export function place({
  i18n,
  node,
  onSpeak,
  onRefuseRevival,
  onJobQuery,
}: IPlaceOptions): IPlaceResult {
  const store = new GameStore();
  // 蘇生辞退時のロジックを作る
  const refuseRevivalLogic = makeRefuseRevivalLogic(i18n, onRefuseRevival);

  const com = (
    <Game
      i18n={i18n}
      store={store}
      onSpeak={onSpeak}
      onRefuseRevival={refuseRevivalLogic}
      onJobQuery={onJobQuery}
    />
  );

  ReactDOM.render(com, node);

  return {
    store,
    runInAction,
    unmount: () => {
      ReactDOM.unmountComponentAtNode(node);
    },
  };
}
