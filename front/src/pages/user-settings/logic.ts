import { ColorName } from './defs';
import { UserSettingsStore } from './store';
import { ColorResult } from './color-profile/color-box';

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
