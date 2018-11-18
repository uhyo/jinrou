import { ColorProfile, PhoneFontSize } from '../defs';
import { SpeakFormPosition } from '../defs/phone-ui';

/**
 * Theme that are provided to styled components.
 */
export interface UserTheme extends ColorProfile {
  phoneFontSize: PhoneFontSize;
  speakFormPosition: SpeakFormPosition;
}

/**
 * Calculated style, mainly for global styling.
 */
export interface GlobalStyleTheme {
  /**
   * Backgroud color of game page.
   */
  background: string;
  /**
   * Text color of game page.
   */
  color: string;
  /**
   * Text color of links.
   */
  link: string;
}

/**
 * Theme object.
 */
export interface Theme {
  /**
   * Theme specified by the user.
   */
  user: UserTheme;
  /**
   * Color of teams.
   */
  teamColors: Record<string, string | undefined>;
  /**
   * Calculated global style.
   */
  globalStyle: GlobalStyleTheme;
}

/**
 * Theme which should be provided by user.
 */
export type UserProvidedTheme = Pick<
  Theme,
  Extract<keyof Theme, 'user' | 'teamColors'>
>;
