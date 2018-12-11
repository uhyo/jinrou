import * as React from 'react';

import { I18nProvider, i18n } from '../../i18n';
import { PrizeStore } from './store';
import { observer } from 'mobx-react';
import { PageWrapper } from './elements';

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
    return (
      <I18nProvider i18n={i18n}>
        <PageWrapper>
          <h1>{i18n.t('title')}</h1>
          <p>
            <a href="/my">{i18n.t('backLink')}</a>
          </p>
        </PageWrapper>
      </I18nProvider>
    );
  }
}
