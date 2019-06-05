import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { TopPage } from './component';
import { i18n } from '../../i18n';
import { LoginHandler, SignupHandler } from './def';

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
   * handler of login.
   */
  onLogin: LoginHandler;
  /**
   * handler of signup.k
   */
  onSignup: SignupHandler;
}
export interface IPlaceResult {
  unmount: () => void;
}

export function place({
  i18n,
  node,
  onLogin,
  onSignup,
}: IPlaceOptions): IPlaceResult {
  const com = <TopPage i18n={i18n} onLogin={onLogin} onSignup={onSignup} />;

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount };
}
