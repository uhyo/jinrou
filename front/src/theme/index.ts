import { computed, observable, action, runInAction, set } from 'mobx';

import { Theme } from './theme';
export { Theme };

/**
 * Store of theme.
 */
export class ThemeStore {
  @observable
  public themeObject: Theme = {
    day: {
      bg: '#ffd953',
      color: '#000000',
    },
    night: {
      bg: '#000044',
      color: '#ffffff',
    },
    heaven: {
      bg: '#fffff0',
      color: '#000000',
    },
  };

  @action
  public update(obj: { [K in keyof Theme]: Theme[K] }): void {
    runInAction(() => {
      for (const k in obj) {
        const key = k as keyof Theme;
        set(this.themeObject, key, obj[key]);
      }
    });
  }
}

export const themeStore = new ThemeStore();
