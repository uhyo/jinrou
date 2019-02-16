import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { i18n, I18nProvider } from '../../i18n';
import { NewRoom, ThemeDoc } from './component';
import { NewRoomStore } from './store';
import { showErrorDialog } from '../../dialog';

export interface IPlaceOptions {
  i18n: i18n;
  /**
   * Node to place.
   */
  node: HTMLElement;
  /**
   * callback called on creating a new room.
   */
  onCreate(query: unknown): Promise<void>;
  /**
   * List of available themes.
   */
  themes: ThemeDoc[];
}
export interface IPlaceResult {
  store: NewRoomStore;
  unmount: () => void;
}

export function place({
  i18n,
  node,
  onCreate,
  themes,
}: IPlaceOptions): IPlaceResult {
  const store = new NewRoomStore();
  const createHandler = (query: unknown) => {
    store.setFormDisabled(true);
    onCreate(query).catch(err => {
      store.setFormDisabled(false);
      showErrorDialog({
        modal: true,
        message: String(err),
      });
    });
  };
  const com = (
    <I18nProvider i18n={i18n}>
      <NewRoom store={store} onCreate={createHandler} themes={themes} />
    </I18nProvider>
  );

  ReactDOM.render(com, node);

  const unmount = () => {
    ReactDOM.unmountComponentAtNode(node);
  };
  return { store, unmount };
}
