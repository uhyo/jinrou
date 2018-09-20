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
