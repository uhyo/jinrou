import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { UserSettingsStore } from './store';
import { UserSettings } from './component';
import { i18n, addResource } from '../../i18n';
import { loadProfilesLogic } from './logic';

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
   * Notify change to usage of phone ui.
   */
  onChangePhoneUI(use: boolean): void;
}
export interface IPlaceResult {
  unmount: () => void;
}

export async function place({
  i18n,
  node,
  onChangePhoneUI,
}: IPlaceOptions): Promise<IPlaceResult> {
  // i18nに必要なリソースを読み込む
  await addResource('user_settings_client', i18n);
  i18n.setDefaultNamespace('user_settings_client');

  const store = new UserSettingsStore(i18n, onChangePhoneUI);

  // Parallely load data from IndexedDB.
  loadProfilesLogic(store);

  const com = <UserSettings i18n={i18n} store={store} />;

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount };
}
