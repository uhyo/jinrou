import { RoleInfo } from '../../../game-view/defs';
import { TranslationFunction } from '../../../../i18n';

const roleBasis = (night: boolean) => ({
  dead: false,
  speak: night ? ['monologue'] : ['day', 'monologue'],
  will: undefined,
  win: null,
  forms: [],
});
/**
 * Basic data of Human.
 */
export const humanRole = (
  t: TranslationFunction,
  night: boolean,
): RoleInfo => ({
  ...roleBasis(night),
  myteam: 'Human',
  jobname: t('roles:jobname.Human'),
  desc: [
    {
      name: t('roles:jobname.Human'),
      type: 'Human',
    },
  ],
});

/**
 * Basic data of Diviner.
 */
export const divinerRole = (
  t: TranslationFunction,
  night: boolean,
): RoleInfo => ({
  ...roleBasis(night),
  myteam: 'Human',
  jobname: t('roles:jobname.Diviner'),
  desc: [
    {
      name: t('roles:jobname.Diviner'),
      type: 'Diviner',
    },
  ],
});
