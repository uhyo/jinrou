/**
 * Pair of text color and background color.
 * @package
 */
export interface OneColor {
  /**
   * Foreground color in CSS color value.
   */
  color: string;
  /**
   * Background color in CSS color value.
   */
  bg: string;
}

/**
 * Profile of colors.
 * @package
 */
export interface ColorProfile {
  /**
   * Color of day.
   */
  day: OneColor;
  /**
   * Color of night.
   */
  night: OneColor;
  /**
   * Color of heaven.
   */
  heaven: OneColor;
}

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
  id: number | null;
  /**
   * Color profile values.
   */
  profile: ColorProfile;
}

/**
 * Type of default color profile which does not have name.
 */
export type DefaultColorProfileData = Pick<
  ColorProfileData,
  Exclude<keyof ColorProfileData, 'name'>
>;
/**
 * Default color profile.
 */
export const defaultColorProfile1: DefaultColorProfileData = {
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

/**
 * Default profiles.
 */
export const defaultProfiles: DefaultColorProfileData[] = [
  defaultColorProfile1,
];
