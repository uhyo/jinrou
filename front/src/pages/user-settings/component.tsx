import * as React from 'react';

import { UserSettingsStore } from './store';
import { observer } from 'mobx-react';
import { I18nProvider, i18n } from '../../i18n';
import { ColorProfileDisp } from './color-profile';

export interface IPropUserSettings {
  i18n: i18n;
  store: UserSettingsStore;
}

@observer
export class UserSettings extends React.Component<IPropUserSettings, {}> {
  public render() {
    const { i18n, store } = this.props;
    return (
      <I18nProvider i18n={i18n}>
        <h1>{i18n.t('title')}</h1>
        <ColorProfileDisp profile={store.currentProfile} />
      </I18nProvider>
    );
  }
}
