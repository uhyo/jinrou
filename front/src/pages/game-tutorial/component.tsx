import * as React from 'react';
import { GameTutorialStore } from './store';
import { Game } from '../game-view/component';
import { i18n } from '../../i18n';
import { RoomControlHandlers } from '../../defs';
import { observer } from 'mobx-react-lite';
import { StoryInputInterface } from './story/defs';

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
    ...story.roomHedaerInput,
  };
  const gameInput: StoryInputInterface = {
    onSpeak: noop,
    onRefuseRevival: noop,
    onJobQuery: noop,
    onWillChange: noop,
    ...story.gameInput,
  };
  console.log(store);
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
        shareButton={shareButton}
        teamColors={teamColors}
        roomControlHandlers={roomControlHandlers}
        {...gameInput}
        onReportFormSubmit={noop}
      />
    </>
  );
});
