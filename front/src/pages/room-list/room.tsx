import { Room, RoomListMode } from './defs';
import {
  RoomWrapper,
  RoomName,
  Status,
  roomStatus,
  Locked,
  HasGM,
  Blind,
  RoomOpenTime,
  Comment,
  RoomOwner,
} from './elements';
import * as React from 'react';
import { I18n, TranslationFunction } from '../../i18n';
import { Observer } from 'mobx-react';
import { FontAwesomeIcon } from '../../util/icon';

/**
 * Component to show one room.
 */
export function Room({
  room,
  listMode,
}: {
  room: Room;
  listMode: RoomListMode;
}) {
  const { id, name } = room;

  return (
    <I18n namespace="rooms_client">
      {t => (
        <Observer>
          {() => (
            <RoomWrapper>
              <RoomName href={`/room/${id}`}>{name}</RoomName>
              <RoomStatus room={room} listMode={listMode} t={t} />
            </RoomWrapper>
          )}
        </Observer>
      )}
    </I18n>
  );
}

/**
 * Show room status.
 */
function RoomStatus({
  room,
  listMode,
  t,
}: {
  room: Room;
  listMode: RoomListMode;
  t: TranslationFunction;
}) {
  const {
    mode,
    needpassword,
    gm,
    blind,
    players,
    number,
    made,
    comment,
    owner,
  } = room;

  const RS = roomStatus[mode];

  return (
    <>
      <Status>
        <RS>
          {t(`status.${mode}`)} ({t('playerNumber', { count: players.length })}{' '}
          / {t('playerNumber', { count: number })})
        </RS>
        {needpassword ? (
          listMode === 'old' || listMode === 'log' || listMode === 'my' ? (
            // lock is outdated.
            <Locked title={t('game_client:roominfo.password')}>
              <FontAwesomeIcon icon="unlock" />
            </Locked>
          ) : (
            <Locked>
              <FontAwesomeIcon icon="lock" />
              {t('game_client:roominfo.password')}
            </Locked>
          )
        ) : null}
        {gm ? (
          <HasGM>
            <FontAwesomeIcon icon="user-tie" />
            {t('gm')}
          </HasGM>
        ) : null}
        {blind === 'yes' ? (
          <Blind>
            <FontAwesomeIcon icon="user-secret" />
            {t('game_client:roominfo.blind')}
          </Blind>
        ) : blind === 'complete' ? (
          <Blind>
            <FontAwesomeIcon icon="user-secret" />
            {t('game_client:roominfo.blindComplete')}
          </Blind>
        ) : null}
      </Status>
      <Status>
        <RoomOwner>
          {t('ownerPrefix')}
          {owner != null ? (
            <a href={`/user/${owner.userid}`}>{owner.name}</a>
          ) : (
            t('ownerHidden')
          )}
        </RoomOwner>
      </Status>
      <Status>
        <RoomOpenTime>{new Date(made).toLocaleString()}</RoomOpenTime>
        <Comment>{comment}</Comment>
      </Status>
    </>
  );
}
