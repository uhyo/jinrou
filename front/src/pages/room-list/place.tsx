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
}
export interface IPlaceResult {
  unmount: () => void;
  store: RoomListStore;
}

export function place({ i18n, node }: IPlaceOptions): IPlaceResult {
  const store = new RoomListStore();

  const com = <RoomList i18n={i18n} store={store} />;

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount, store };
}
