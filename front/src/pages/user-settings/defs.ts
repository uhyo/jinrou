import { ColorProfile } from '../../defs';

/**
 * Tabs of user settings.
 * @package
 */
export type Tab = 'color';

/**
 * Color profile object.
 */
export interface ColorProfileData {
  /**
   * Name of this profile.
   */
  name: string;
  /**
   * ID of this profile.
   * null if it is built-in.
   */
  id: string | null;
  /**
   * Color profile values.
   */
  profile: ColorProfile;
}

/**
 * Type of color profile color names.
 */
export type ColorName = keyof ColorProfile;

/**
 * Data of whether sample of each color should be displayed in bold.
 */
export const sampleIsBold: Record<ColorName, boolean> = {
  day: false,
  night: false,
  heaven: false,
};

/**
 * List of color setting names.
 */
export const colorNames: ColorName[] = ['day', 'night', 'heaven'];

/**
 * Default color profile.
 */
export const defaultColorProfile1: ColorProfileData = {
  name: '',
  id: null,
  profile: {
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
  },
};
