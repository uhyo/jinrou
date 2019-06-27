import * as React from 'react';
import { GameTutorialStore } from './store';
import { Game } from '../game-view/component';
import { i18n } from '../../i18n';
import { RoomControlHandlers } from '../../defs';
import { observer } from 'mobx-react-lite';

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
export const GameTutorial: React.FunctionComponent<
  IPropGameTutorial
> = observer(({ i18n, store, teamColors }) => {
  const emptyArray = React.useMemo(() => [], []);
  const noop = React.useCallback(() => {}, []);

  const story = store.story;
  const roomControlHandlers: RoomControlHandlers = {
    ...story.roomHedaerInput,
    openGameStart: noop,
    kick: noop,
    kickRemove: noop,
    resetReady: noop,
    discard: noop,
    newRoom: noop,
  };
  return (
    <>
      <h1 id="roomname">{i18n.t('tutorial_game:room.title')}</h1>
      <Game
        i18n={i18n}
        roomid={0}
        store={store.innerStore}
        categories={emptyArray}
        ruleDefs={emptyArray}
        reportForm={reportForm}
        teamColors={teamColors}
        roomControlHandlers={roomControlHandlers}
        {...story.gameInput}
        onReportFormSubmit={noop}
      />
    </>
  );
});
