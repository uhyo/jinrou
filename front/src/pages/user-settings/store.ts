import { observable, action } from 'mobx';
import { i18n } from '../../i18n';
import { deepClone } from '../../util/deep-clone';
import {
  ColorProfileData,
  defaultColorProfile1,
} from '../../defs/color-profile';
import { initTab } from './logic/tab-init';
import { Tab } from './defs/tabs';
import { ColorName } from './defs/color-profile';

/**
 * States of user settings page.
 */
export class UserSettingsStore {
  /**
   * Current tab.
   */
  @observable
  public tab: Tab = initTab('phone');
  /**
   * Current profile of colors.
   */
  @observable
  public currentProfile: ColorProfileData;
  /**
   * Profile selected by default.
   */
  public defaultProfile: ColorProfileData;

  constructor(i18n: i18n, public onChangePhoneUI: (use: boolean) => void) {
    this.defaultProfile = {
      ...defaultColorProfile1,
      name: i18n.t('color.defaultProfile'),
    };
    this.currentProfile = deepClone(this.defaultProfile);
  }
  /**
   * Saved color profiles.
   */
  @observable
  public savedColorProfiles: ColorProfileData[] | null = null;

  /**
   * Set saved profiles.
   */
  @action
  public updateSavedProfiles(profiles: ColorProfileData[]): void {
    this.savedColorProfiles = profiles;
  }
  /**
   * Go to another tab.
   */
  @action
  public setTab(tab: Tab): void {
    this.tab = tab;
  }
  /**
   * Update a tab.
   */
  @action
  public updateTab(updator: (t: Tab) => Tab): void {
    this.tab = updator(this.tab);
  }
  /**
   * Update whole profile.
   */
  @action
  public setCurrentProfile(profile: ColorProfileData): void {
    this.currentProfile = profile;
  }
  /**
   * Update current color.
   */
  @action
  public updateCurrentColor(
    colorName: ColorName,
    type: 'color' | 'bg',
    color: string,
  ): void {
    this.currentProfile.profile[colorName][type] = color;
  }
  /**
   * Update profile by id.
   */
  @action
  public updateProfileById(id: number, profile: ColorProfileData): void {
    const { savedColorProfiles } = this;
    if (savedColorProfiles == null) {
      return;
    }
    for (let i = 0; i < savedColorProfiles.length; i++) {
      if (savedColorProfiles[i].id === id) {
        savedColorProfiles[i] = profile;
        break;
      }
    }
  }
}
