import * as React from 'react';
import { GameStartTutorialStore } from './store';
import { Game } from '../game-view/component';
import { i18n } from '../../i18n';
import { RoomControlHandlers } from '../../defs';
import { observer } from 'mobx-react-lite';
import { showConfirmDialog } from '../../dialog';
import { useHelpChipHost } from '../../common/helpchip/useHelpChipHost';

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

  const reset = React.useCallback(
    () => {
      showConfirmDialog({
        modal: true,
        title: i18n.t('tutorial_game_start:reset.title') as string,
        message: i18n.t('tutorial_game_start:reset.message'),
        yes: i18n.t('tutorial_game_start:reset.yes'),
        no: i18n.t('tutorial_game_start:reset.no'),
      }).then(result => {
        if (result) {
          store.reset();
        }
      });
    },
    [store],
  );

  const gameInput = React.useMemo(
    () => ({
      onSpeak: store.interactiveDriver.getSpeakHandler(),
      onRefuseRevival: noop,
      onJobQuery: noop,
      onWillChange: noop,
      onResetButtonPress: reset,
    }),
    [store],
  );

  const roomControlHandlers: RoomControlHandlers = React.useMemo(
    () => ({
      openGameStart: noop,
      kick: noop,
      kickRemove: noop,
      resetReady: noop,
      discard: noop,
      newRoom: noop,
      join: store.interactiveDriver.getJoinHandler(),
      unjoin: store.interactiveDriver.getUnjoinHandler(),
      ready: store.interactiveDriver.getReadyHandler(),
      helper: noop,
    }),
    [store],
  );

  const Host = useHelpChipHost(helpName => {
    console.log(helpName);
  });

  return (
    <Host.Provider value={Host.helpChipContent}>
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
    </Host.Provider>
  );
});
