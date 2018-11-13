import * as React from 'react';

import { I18nProvider, i18n } from '../../i18n';
import { RoomListStore } from './store';
import { observer } from 'mobx-react';
import { RoomListWrapper, Wrapper } from './elements';
import { Room } from './room';
import { NormalButton } from '../../common/button';
import { bind } from 'bind-decorator';

export interface IPropRoomList {
  /**
   * i18next instance.
   */
  i18n: i18n;
  /**
   * store.
   */
  store: RoomListStore;
  /**
   * Page move event.
   */
  onPageMove: (dist: number) => void;
}

@observer
export class RoomList extends React.Component<IPropRoomList, {}> {
  public render() {
    const { i18n, store } = this.props;
    const { rooms, prevAvailable, nextAvailable, mode } = store;
    return (
      <I18nProvider i18n={i18n}>
        <Wrapper>
          <h1>{i18n.t('rooms_client:title')}</h1>
          {rooms.length === 0 ? (
            <p>{i18n.t('rooms_client:noRoom')}</p>
          ) : (
            <>
              <p>
                <NormalButton
                  disabled={!prevAvailable}
                  onClick={this.handlePrevClick}
                >
                  {i18n.t('rooms_client:prevPageButton')}
                </NormalButton>
                <NormalButton
                  disabled={!nextAvailable}
                  onClick={this.handleNextClick}
                >
                  {i18n.t('rooms_client:nextPageButton')}
                </NormalButton>
              </p>
            </>
          )}
          <RoomListWrapper>
            {rooms.map(room => (
              <Room key={room.id} room={room} listMode={mode} />
            ))}
          </RoomListWrapper>
        </Wrapper>
      </I18nProvider>
    );
  }
  @bind
  private handlePrevClick() {
    this.props.onPageMove(-1);
  }
  @bind
  private handleNextClick() {
    this.props.onPageMove(1);
  }
}
