import * as React from 'react';

import { I18nProvider, i18n } from '../../i18n';
import { RoomListStore } from './store';
import { observer } from 'mobx-react';
import { RoomListWrapper, Wrapper } from './elements';
import { Room } from './room';

export interface IPropRoomList {
  i18n: i18n;
  store: RoomListStore;
}

@observer
export class RoomList extends React.Component<IPropRoomList, {}> {
  public render() {
    const { i18n, store } = this.props;
    console.log(store.rooms.length);
    return (
      <I18nProvider i18n={i18n}>
        <Wrapper>
          <h1>{i18n.t('rooms_client:title')}</h1>
          {store.rooms.length === 0 ? (
            <p>{i18n.t('rooms_client:noRoom')}</p>
          ) : null}
          <RoomListWrapper>
            {store.rooms.map(room => (
              <Room key={room.id} room={room} />
            ))}
          </RoomListWrapper>
        </Wrapper>
      </I18nProvider>
    );
  }
}
