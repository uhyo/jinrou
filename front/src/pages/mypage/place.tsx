import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { MyPage } from './component';
import { i18n, I18nProvider } from '../../i18n';

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

export function place({ i18n, node }: IPlaceOptions): IPlaceResult {
  const com = (
    <I18nProvider i18n={i18n}>
      <MyPage />
    </I18nProvider>
  );

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount };
}
