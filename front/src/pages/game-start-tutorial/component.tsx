import * as React from 'react';
import { GameStartTutorialStore } from './store';
import { Game } from '../game-view/component';
import { i18n } from '../../i18n';
import { RoomControlHandlers } from '../../defs';
import { observer } from 'mobx-react-lite';

const reportForm = {
  enable: false,
  maxLength: 0,
  categories: [],
};

const shareButton = {
  twitter: false,
};

export interface IPropGameTutorial {
  i18n: i18n;
  store: GameStartTutorialStore;
  teamColors: Record<string, string | undefined>;
}
export const GameStartTutorial: React.FunctionComponent<
  IPropGameTutorial
> = observer(({ i18n, store, teamColors }) => {
  const emptyArray = React.useMemo(() => [], []);
  const noop = React.useCallback(() => {}, []);

  const roomControlHandlers: RoomControlHandlers = {
    openGameStart: noop,
    kick: noop,
    kickRemove: noop,
    resetReady: noop,
    discard: noop,
    newRoom: noop,
    join: noop,
    unjoin: noop,
    ready: noop,
    helper: noop,
  };
  const gameInput = {
    onSpeak: noop,
    onRefuseRevival: noop,
    onJobQuery: noop,
    onWillChange: noop,
  };
  console.log(store);
  return (
    <>
      <h1 id="roomname">{i18n.t('tutorial_game_start:room.title')}</h1>
      <Game
        i18n={i18n}
        roomid={0}
        store={store.gameStore}
        categories={emptyArray}
        ruleDefs={emptyArray}
        reportForm={reportForm}
        shareButton={shareButton}
        teamColors={teamColors}
        roomControlHandlers={roomControlHandlers}
        {...gameInput}
        onReportFormSubmit={noop}
      />
    </>
  );
});
