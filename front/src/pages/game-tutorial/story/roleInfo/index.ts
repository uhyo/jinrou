import { RoleInfo } from '../../../game-view/defs';
import { TranslationFunction } from '../../../../i18n';

/**
 * Basic data of Human.
 */
export const humanRole = (
  t: TranslationFunction,
  night: boolean,
): RoleInfo => ({
  jobname: t('roles:jobname.Human'),
  dead: false,
  desc: [
    {
      name: t('roles:jobname.Human'),
      type: 'Human',
    },
  ],
  speak: night ? ['monologue'] : ['day', 'monologue'],
  will: undefined,
  win: null,
  forms: [],
});
