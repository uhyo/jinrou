import { deepExtend } from '../util/deep-extend';

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
  /**
   * Color of system logs.
   */
  system: OneColor;
  /**
   * Color of audience's speech.
   */
  audience: OneColor;
  /**
   * Color of couple's speech.
   */
  couple: OneColor;
  /**
   * Color of foxes' speech.
   */
  fox: OneColor;
  /**
   * Color of gm's speech.
   */
  gm1: OneColor;
  /**
   * Color of gm's speech.
   */
  gm2: OneColor;
  /**
   * Color of monologue in heaven
   */
  heavenmonologue: OneColor;
  /**
   * Color of half speech in  day.
   */
  half_day: OneColor;
  /**
   * Color of helper's speech
   */
  helperwhisper: OneColor;
  /**
   * Hidden log
   */
  hidden: OneColor;
  /**
   * Color of user's inlog.
   */
  inlog: OneColor;
  /**
   * Color of madcouple's inlog.
   */
  madcouple: OneColor;
  /**
   * Color of monologue
   */
  monologue: OneColor;
  /**
   * Color of nextturn log
   */
  nextturn: OneColor;
  /**
   * Color of probability table.
   */
  probability_table: OneColor;
  /**
   * Color of streaming log.
   */
  streaming: OneColor;
  /**
   * Color of user's info.
   */
  userinfo: OneColor;
  /**
   * Color of skill.
   */
  skill: OneColor;
  /**
   * Color of voting log.
   */
  voteto: OneColor;
  /**
   * Color of poem log.
   */
  poem: OneColor;
  /**
   * Color of werewolf's speech.
   */
  werewolf: OneColor;
  /**
   * Color of will log.
   */
  will: OneColor;
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
 * data common to all default profiles.
 */
const commonDefaults = {
  audience: {
    bg: '#ddffdd',
    color: '#000000',
  },
  couple: {
    bg: '#ddddff',
    color: '#000000',
  },
  fox: {
    bg: '#934293',
    color: '#ffffff',
  },
  gm1: {
    bg: '#ffd1d1',
    color: '#000000',
  },
  gm2: {
    bg: '#ffe5c9',
    color: '#000000',
  },
  heavenmonologue: {
    bg: '#8888aa',
    color: '#ffffff',
  },
  half_day: {
    bg: '#f8f3be',
    color: '#999999',
  },
  helperwhisper: {
    bg: '#fff799',
    color: '#000000',
  },
  hidden: {
    bg: '#888888',
    color: '#eeeeee',
  },
  inlog: {
    bg: '#a6daff',
    color: '#000000',
  },
  madcouple: {
    bg: '#e2e2c0',
    color: '#000000',
  },
  monologue: {
    bg: '#000044',
    color: '#ffffff',
  },
  nextturn: {
    bg: '#eeeeee',
    color: '#000000',
  },
  poem: {
    bg: '#f1a0a2',
    color: '#000000',
  },
  probability_table: {
    bg: '#eeeeee',
    color: '#000000',
  },
  streaming: {
    bg: '#ffe5c9',
    color: '#000000',
  },
  userinfo: {
    bg: '#0000cc',
    color: '#ffffff',
  },
  skill: {
    bg: '#cc0000',
    color: '#ffffff',
  },
  system: {
    bg: '#cccccc',
    color: '#000000',
  },
  voteto: {
    bg: '#009900',
    color: '#ffffff',
  },
  werewolf: {
    bg: '#000044',
    color: '#ffffff',
  },
  will: {
    bg: '#222222',
    color: '#ffffff',
  },
};

/**
 * Default color profile.
 */
export const defaultColorProfile1: DefaultColorProfileData = {
  id: null,
  profile: deepExtend(
    {
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
    commonDefaults,
  ),
};
const defaultColorProfile2: DefaultColorProfileData = {
  id: null,
  profile: deepExtend(
    {
      day: {
        bg: '#f0e68c',
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
    commonDefaults,
  ),
};
const defaultColorProfile3: DefaultColorProfileData = {
  id: null,
  profile: deepExtend(
    {
      day: {
        bg: '#ffffff',
        color: '#000000',
      },
      night: {
        bg: '#000044',
        color: '#ffffff',
      },
      heaven: {
        bg: '#e3e3e3',
        color: '#000000',
      },
    },
    commonDefaults,
  ),
};

/**
 * Default profiles.
 */
export const defaultProfiles: DefaultColorProfileData[] = [
  defaultColorProfile1,
  defaultColorProfile2,
  defaultColorProfile3,
];
