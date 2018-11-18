import * as React from 'react';

import { UserSettingsStore } from './store';
import { observer } from 'mobx-react';
import { I18nProvider, i18n } from '../../i18n';
import { ColorProfileDisp } from './color-profile';
import { makeRouter } from '../../common/router';
import { PhoneUIDisp } from './phone-ui';
import { TabSelect } from './tab-select';
import { Tab } from './defs/tabs';

export interface IPropUserSettings {
  i18n: i18n;
  store: UserSettingsStore;
}

/**
 * router for each tab.
 */
const TabRouter = makeRouter<
  {
    store: UserSettingsStore;
  },
  Tab,
  'page'
>(
  {
    color: ColorProfileDisp,
    phone: PhoneUIDisp,
  },
  'page',
);

@observer
export class UserSettings extends React.Component<IPropUserSettings, {}> {
  public render() {
    const { i18n, store } = this.props;
    return (
      <I18nProvider i18n={i18n}>
        <h1>{i18n.t('title')}</h1>
        <p>
          <a href="/my">{i18n.t('backLink')}</a>
        </p>
        <p>{i18n.t('description')}</p>
        <TabSelect store={store} />
        <TabRouter page={store.tab} store={store} />
      </I18nProvider>
    );
  }
}
