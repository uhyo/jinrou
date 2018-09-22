import { ColorProfile } from '../../defs';
import { TranslationFunction } from 'i18next';

/**
 * Type of color profile color names.
 */
export type ColorName = keyof ColorProfile;

/**
 * Content of tabs.
 * @package
 */
export type Tab = ColorSettingTab;

/**
 * Color setting tab.
 */
export interface ColorSettingTab {
  page: 'color';
  /**
   * Whether current profile is being edited.
   */
  editing: boolean;
  /**
   * Currently edited color.
   */
  colorFocus: null | {
    key: ColorName;
    type: 'color' | 'bg';
  };
}

/**
 * Data of whether sample of each color should be displayed in bold.
 */
export const sampleIsBold: Record<ColorName, boolean> = {
  day: false,
  night: false,
  heaven: false,
  audience: false,
  couple: false,
  fox: false,
  gm1: false,
  gm2: false,
  heavenmonologue: false,
  half_day: false,
  helperwhisper: false,
  inlog: true,
  madcouple: true,
  monologue: false,
  nextturn: true,
  probability_table: false,
  skill: true,
  system: true,
  userinfo: true,
  voteto: true,
  werewolf: false,
  will: false,
};

/**
 * List of color setting names.
 */
export const colorNames: ColorName[] = [
  'day',
  'night',
  'heaven',
  'system',
  'nextturn',
  'skill',
  'voteto',
  'monologue',
  'audience',
  'inlog',
  'werewolf',
  'couple',
  'fox',
  'madcouple',
  'half_day',
  'heavenmonologue',
  'gm1',
  'gm2',
  'helperwhisper',
  'userinfo',
  'will',
  'probability_table',
];
