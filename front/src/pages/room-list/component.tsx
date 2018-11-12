import * as React from 'react';

import { I18nProvider, i18n } from '../../i18n';
import { RoomListStore } from './store';
import { observer } from 'mobx-react';

export interface IPropRoomList {
  i18n: i18n;
  store: RoomListStore;
}

@observer
export class RoomList extends React.Component<IPropRoomList, {}> {
  public render() {
    const { i18n, store } = this.props;
    return (
      <I18nProvider i18n={i18n}>
        <h1>{i18n.t('rooms_client:title')}</h1>
      </I18nProvider>
    );
  }
}
