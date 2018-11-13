import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { RoomListStore } from './store';
import { RoomList } from './component';
import { i18n } from '../../i18n';

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
   * Number of rooms in one page.
   */
  pageNumber: number;
  /**
   * handler of page move.
   */
  onPageMove: (dist: number) => void;
}
export interface IPlaceResult {
  unmount: () => void;
  store: RoomListStore;
}

export function place({
  i18n,
  node,
  pageNumber,
  onPageMove,
}: IPlaceOptions): IPlaceResult {
  const store = new RoomListStore(pageNumber);

  const com = <RoomList i18n={i18n} store={store} onPageMove={onPageMove} />;

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount, store };
}
