import { observable, action } from 'mobx';
import { Tab, ColorProfileData, defaultColorProfile1 } from './defs';
import { ColorProfile } from '../../defs';
import { i18n } from '../../i18n';

/**
 * States of user settings page.
 */
export class UserSettingsStore {
  /**
   * Current tab.
   */
  @observable
  public tab: Tab = {
    page: 'color',
    editing: false,
  };
  /**
   * Current profile of colors.
   */
  @observable public currentProfile: ColorProfileData = defaultColorProfile1;

  constructor(i18n: i18n) {
    this.currentProfile.name = i18n.t('color.profile') + ' 1';
  }

  /**
   * Go to another tab.
   */
  @action
  public setTab(tab: Tab): void {
    this.tab = tab;
  }
}
