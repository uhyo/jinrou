import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { UserSettingsStore } from './store';
import { UserSettings } from './component';
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
}

export function place({ node }: IPlaceOptions): IPlaceResult {
  const store = new UserSettingsStore();

  const com = <UserSettings store={store} />;

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount };
}
