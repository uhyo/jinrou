import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { i18n, addResource } from '../../i18n';
import { GameTutorial } from './component';
import { GameStartTutorialStore } from './store';
import { UserInfo } from './defs';

export interface IPlaceOptions {
  /**
   * i18n instance to use.
   */
  i18n: i18n;
  /**
   * Node to place the component to.
   */
  node: HTMLElement;
  /**
   * Color of teams.
   */
  teamColors: Record<string, string | undefined>;
  /**
   * Get user profile.
   */
  getUserProfile: () => Promise<UserInfo>;
}

export interface IPlaceResult {
  store: GameStartTutorialStore;
  unmount(): void;
}

export async function place({
  i18n,
  node,
  teamColors,
  getUserProfile,
}: IPlaceOptions): Promise<IPlaceResult> {
  const [userInfo] = await Promise.all([
    getUserProfile(),
    addResource('tutorial_game_start', i18n),
    addResource('roles', i18n),
    addResource('game', i18n),
  ]);

  const store = new GameStartTutorialStore(i18n);
  const com = (
    <GameTutorial i18n={i18n} store={store} teamColors={teamColors} />
  );

  ReactDOM.render(com, node);

  return {
    store,
    unmount: () => {
      ReactDOM.unmountComponentAtNode(node);
    },
  };
}
