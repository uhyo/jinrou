import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { RoomListStore } from './store';
import { RoomList } from './component';
import { i18n } from '../../i18n';
import { RoomListMode } from './defs';
import { GetJobColorProvider, GetJobColorFunction } from './get-job-color';

/**
 * Options to place.
 */
export interface IPlaceOptions {
  i18n: i18n;
  /**
   * Node to place.
   */
  node: HTMLElement;
  /**
   * Current mode of list.
   */
  listMode: RoomListMode;
  /**
   * Number of rooms in one page.
   */
  pageNumber: number;
  /**
   * When enabled, links are not shown.
   */
  noLinks: boolean;
  /**
   * Start number of index of rooms.
   */
  indexStart: number;
  /**
   * handler of page move.
   */
  onPageMove: (dist: number) => void;
  /**
   * Function to return color of given job.
   */
  getJobColor: GetJobColorFunction;
}
export interface IPlaceResult {
  unmount: () => void;
  store: RoomListStore;
}

export function place({
  i18n,
  node,
  pageNumber,
  listMode,
  noLinks,
  onPageMove,
  getJobColor,
}: IPlaceOptions): IPlaceResult {
  const store = new RoomListStore(pageNumber, listMode);

  const com = (
    <GetJobColorProvider value={getJobColor}>
      <RoomList
        i18n={i18n}
        store={store}
        noLinks={noLinks}
        onPageMove={onPageMove}
      />
    </GetJobColorProvider>
  );

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };

  return { unmount, store };
}
