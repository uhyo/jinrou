import * as React from 'react';

import { I18nProvider, i18n } from '../../i18n';
import { PrizeStore } from './store';
import { observer } from 'mobx-react';

export interface IPropPrize {
  /**
   * i18next instance.
   */
  i18n: i18n;
  /**
   * store.
   */
  store: PrizeStore;
}

@observer
export class PrizePage extends React.Component<IPropPrize, {}> {
  public render() {
    const { i18n, store } = this.props;
    return <I18nProvider i18n={i18n}>TODO</I18nProvider>;
  }
}
