import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { PrizeStore } from './store';
import { PrizePage } from './component';
import { i18n, addResource } from '../../i18n';
import { Prize } from './defs';

/**
 * Options to place.
 */
export interface IPlaceOptions {
  i18n: i18n;
  /**
   * Node to place.
   */
  node: HTMLElement;
  /**
   * Initial list of prizes
   */
  initialPrizes: Prize[];
}
export interface IPlaceResult {
  unmount: () => void;
  store: PrizeStore;
}

export async function place({
  i18n,
  node,
  initialPrizes,
}: IPlaceOptions): Promise<IPlaceResult> {
  await addResource('prize_client', i18n);
  i18n.setDefaultNamespace('prize_client');

  const store = new PrizeStore();
  store.setPrizes(initialPrizes);

  const com = <PrizePage i18n={i18n} store={store} />;

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount, store };
}
