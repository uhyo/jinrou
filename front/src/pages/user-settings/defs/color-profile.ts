import { ColorProfile } from '../../../defs';
import { allElements } from '../../../util/all-elements';

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
  audience: false,
  couple: false,
  fox: false,
  gm1: false,
  gm2: false,
  heavenmonologue: false,
  half_day: false,
  helperwhisper: false,
  hidden: false,
  inlog: true,
  madcouple: true,
  monologue: false,
  nextturn: true,
  poem: false,
  probability_table: false,
  skill: true,
  streaming: false,
  system: true,
  userinfo: true,
  voteto: true,
  werewolf: false,
  will: false,
};

/**
 * List of color setting names.
 */
export const colorNames: ColorName[] = allElements<ColorName>()([
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
  'poem',
  'streaming',
  'hidden',
  'will',
  'probability_table',
]);
