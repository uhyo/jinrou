import Color from 'color';

import { GameInfo, RoleInfo } from '../pages/game-view/defs';
import { GlobalStyleTheme, UserTheme } from './theme';

/**
 * Mode for selecting current style.
 */
export type GlobalStyleMode = 'day' | 'night' | 'heaven' | null;

/**
 * Compute global style.
 */
export function computeGlobalStyle(
  userTheme: UserTheme,
  mode: GlobalStyleMode,
): GlobalStyleTheme {
  // Compute global style from user theme and mode.
  const background =
    mode === 'day'
      ? userTheme.day.bg
      : mode === 'night'
        ? userTheme.night.bg
        : mode === 'heaven'
          ? userTheme.heaven.bg
          : '#ffffff';
  const color =
    mode === 'day'
      ? userTheme.day.color
      : mode === 'night'
        ? userTheme.night.color
        : mode === 'heaven'
          ? userTheme.heaven.color
          : '#000000';

  // Determine link color according to lightness of bg..
  const linkColor1 = Color('#000a68');
  const linkColor2 = Color('#ffffff');

  const bgObj = Color(background);

  const linkObj =
    bgObj.contrast(linkColor1) > bgObj.contrast(linkColor2)
      ? linkColor1
      : linkColor2;
  const link = linkObj.rgb().string();

  return {
    background,
    color,
    link,
  };
}
