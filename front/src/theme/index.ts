import { computed, observable, action, runInAction, set, toJS } from 'mobx';

import { UserTheme, Theme, GlobalStyleTheme, UserProvidedTheme } from './theme';
import { isPrimitive } from '../util/is-primitive';
import { deepExtend } from '../util/deep-extend';
import { defaultColorProfile1, ColorProfileData } from '../defs/color-profile';
import { deepClone } from '../util/deep-clone';
import { GlobalStyleMode, computeGlobalStyle } from './global-style';
import { PhoneUISettings } from '../defs';
export {
  UserTheme,
  Theme,
  UserProvidedTheme,
  GlobalStyleTheme,
  GlobalStyleMode,
  computeGlobalStyle,
};

/**
 * Key of localStorage to save theme.
 */
const localStorageKey = 'userTheme';

/**
 * Key of color profile for backwards compatibility
 */
const localStorageColorProfileKey = 'colorProfile';

/**
 * Key of localStorage to communicate with outside of application
 * for disabling smartphone UI
 */
const localStorageUsePhoneUIKey = 'usePhoneUI';

/**
 * Default phone UI settings.
 */
const defaultPhoneUISettings: PhoneUISettings = {
  use: true,
  fontSize: 'normal',
  speakFormPosition: 'normal',
};

/**
 * Themes saved in user's storage.
 */
export interface SavedTheme {
  colorProfile: ColorProfileData;
  phoneUI: PhoneUISettings;
}

/**
 * Store of user-defined theme.
 */
export class ThemeStore {
  @observable
  public savedTheme!: SavedTheme;
  @computed
  public get themeObject(): UserTheme {
    return {
      ...this.savedTheme.colorProfile.profile,
      phoneFontSize: this.savedTheme.phoneUI.fontSize,
      speakFormPosition: this.savedTheme.phoneUI.speakFormPosition,
    };
  }

  constructor() {
    this.loadThemeFromStorage();
  }

  /**
   * Update current theme.
   */
  @action
  public update(obj: Partial<SavedTheme>): void {
    runInAction(() => {
      for (const k in obj) {
        const key = k as keyof SavedTheme;
        set(this.savedTheme, key, deepClone(obj[key]));
      }
    });
  }
  /**
   * Load theme from storage.
   */
  @action
  private loadThemeFromStorage(): void {
    this.savedTheme = loadFromStorage();
  }
  /**
   * Save current setting to storage.
   */
  public saveToStorage() {
    localStorage.setItem(
      localStorageKey,
      JSON.stringify(toJS(this.savedTheme)),
    );
    localStorage.setItem(
      localStorageUsePhoneUIKey,
      String(this.savedTheme.phoneUI.use),
    );
  }
}

/**
 * Load and make a theme object from localStorage.
 */
function loadFromStorage(): SavedTheme {
  const lsk = localStorage.getItem(localStorageKey);
  if (lsk) {
    // this user has the new format data.
    try {
      const savedTheme = JSON.parse(lsk);
      // found the saved theme.
      savedTheme.colorProfile = treatColorProfile(savedTheme.colorProfile);
      savedTheme.phoneUI = treatPhoneUI(savedTheme.phoneUI);
      return savedTheme;
    } catch (e) {
      console.error(e);
    }
  }
  // fallback to old colorProflie.
  let colorProfile: any = {};
  try {
    colorProfile = JSON.parse(
      localStorage.getItem(localStorageColorProfileKey) || '{}',
    );
    if (isPrimitive(colorProfile)) {
      colorProfile = {};
    }
  } catch (e) {
    console.error(e);
  }
  const colorProfileData = {
    id: null,
    name: '',
    profile: colorProfile,
  };
  return {
    colorProfile: treatColorProfile(colorProfileData),
    phoneUI: defaultPhoneUISettings,
  };
}

function treatColorProfile(colorProfile: any): any {
  return deepExtend(defaultColorProfile1, colorProfile);
}
function treatPhoneUI(phoneUI: any): any {
  return deepExtend(defaultPhoneUISettings, phoneUI);
}

export const themeStore = new ThemeStore();
