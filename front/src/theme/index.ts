import { computed, observable, action, runInAction, toJS } from 'mobx';

import { Theme } from './theme';
export { Theme };

/**
 * Store of theme.
 */
export class ThemeStore {
  @observable public theme: Map<keyof Theme, string> = new Map();
  @computed
  public get themeObject(): Theme {
    return toJS(this.theme) as any;
  }

  @action
  public update(obj: { [K in keyof Theme]: Theme[K] }): void {
    runInAction(() => {
      for (const k in obj) {
        const key = k as keyof Theme;
        this.theme.set(key, obj[key]);
      }
    });
  }
}

export const themeStore = new ThemeStore();
