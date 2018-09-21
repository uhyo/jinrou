import { ColorName } from '../defs';
import { UserSettingsStore } from '../store';
import { ColorResult } from '../color-profile/color-box';
import { UserSettingDatabase } from './indexeddb';

/**
 * Logic which loads profiles from db.
 */
export function loadProfilesLogic(store: UserSettingsStore): void {
  const db = new UserSettingDatabase();
  db.transaction('r', db.color, () => db.color.toArray())
    .then(profiles => {
      store.updateSavedProfiles(profiles);
    })
    .catch(console.error);
}
/**
 * Logic when focus is requested.
 */
export function requestFocusLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
): void {
  store.updateTab(tab => {
    if (tab.page === 'color') {
      if (
        tab.colorFocus != null &&
        tab.colorFocus.key === colorName &&
        tab.colorFocus.type === type
      ) {
        // it has already focus.
        return {
          ...tab,
          colorFocus: null,
        };
      } else {
        // give them focus.
        return {
          ...tab,
          colorFocus: {
            key: colorName,
            type,
          },
        };
      }
    } else {
      // do not change.
      return tab;
    }
  });
}

/**
 * Logic when color is changed (realtime).
 */
export function colorChangeLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
  color: ColorResult,
): void {
  store.updateCurrentColor(colorName, type, color.hex);
}

/**
 * Logic run when color is decided.
 */
export function colorChangeCompleteLogic(
  store: UserSettingsStore,
  colorName: ColorName,
  type: 'color' | 'bg',
  color: ColorResult,
): void {
  // TODO
}
