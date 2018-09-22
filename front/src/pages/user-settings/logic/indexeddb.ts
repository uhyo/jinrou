import Dexie from 'dexie';
import { ColorProfile } from '../../../defs';

/**
 * Database name
 */
const DB_NAME = 'jinrou_user_settings';

/**
 * Type of document in DB.
 */
export interface ColorDoc {
  /**
   * Primary id of this document.
   */
  id: number;
  /**
   * name of this document.
   */
  name: string;
  /**
   * Color profile.
   */
  profile: ColorProfile;
}

export type ColorDocWithoutId = Pick<ColorDoc, Exclude<keyof ColorDoc, 'id'>>;

/**
 * Database of user setting.
 */
export class UserSettingDatabase extends Dexie {
  public color!: Dexie.Table<ColorDoc, number>;
  constructor() {
    super(DB_NAME);
    this.version(1).stores({
      color: '++id',
    });
  }
}
