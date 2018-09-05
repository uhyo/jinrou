import { computed, observable, action, runInAction, set } from 'mobx';

import { UserTheme, Theme } from './theme';
export { UserTheme, Theme };

/**
 * Store of user-defined theme.
 */
export class ThemeStore {
  @observable
  public themeObject: UserTheme = {
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
  public update(obj: { [K in keyof UserTheme]: UserTheme[K] }): void {
    runInAction(() => {
      for (const k in obj) {
        const key = k as keyof UserTheme;
        set(this.themeObject, key, obj[key]);
      }
    });
  }
}

export const themeStore = new ThemeStore();
