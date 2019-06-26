import * as React from 'react';
import { GameTutorialStore } from './store';
import { Game } from '../game-view/component';
import { i18n } from '../../i18n';
import { RoomControlHandlers } from '../../defs';

const reportForm = {
  enable: false,
  maxLength: 0,
  categories: [],
};

export interface IPropGameTutorial {
  i18n: i18n;
  store: GameTutorialStore;
  teamColors: Record<string, string | undefined>;
}
export const GameTutorial: React.FunctionComponent<IPropGameTutorial> = ({
  i18n,
  store,
  teamColors,
}) => {
  const emptyArray = React.useMemo(() => [], []);
  const noop = React.useCallback(() => {}, []);

  const roomControlHandlers: RoomControlHandlers = {
    join: noop,
    unjoin: noop,
    ready: noop,
    helper: noop,
    openGameStart: noop,
    kick: noop,
    kickRemove: noop,
    resetReady: noop,
    discard: noop,
    newRoom: noop,
  };
  return (
    <Game
      i18n={i18n}
      roomid={0}
      store={store.innerStore}
      categories={emptyArray}
      ruleDefs={emptyArray}
      reportForm={reportForm}
      teamColors={teamColors}
      roomControlHandlers={roomControlHandlers}
      onJobQuery={noop}
      onSpeak={noop}
      onReportFormSubmit={noop}
      onRefuseRevival={noop}
      onWillChange={noop}
    />
  );
};
