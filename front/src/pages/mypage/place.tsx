import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { MyPage } from './component';
import { i18n, I18nProvider } from '../../i18n';
import { Store } from './store';
import { UserProfile } from './defs';

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
   * Initial profile of user.
   */
  profile: UserProfile;
}
export interface IPlaceResult {
  unmount: () => void;
  store: Store;
}

export function place({ i18n, node, profile }: IPlaceOptions): IPlaceResult {
  const store = new Store({
    profile,
  });
  const com = (
    <I18nProvider i18n={i18n}>
      <MyPage store={store} />
    </I18nProvider>
  );

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount, store };
}
