import { observable, action } from 'mobx';
import { Tab, ColorProfileData, defaultColorProfile1, ColorName } from './defs';
import { ColorProfile } from '../../defs';
import { i18n } from '../../i18n';
import { deepClone } from '../../util/deep-clone';

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
    colorFocus: null,
  };
  /**
   * Current profile of colors.
   */
  @observable
  public currentProfile: ColorProfileData = deepClone(defaultColorProfile1);

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
  /**
   * Update a tab.
   */
  @action
  public updateTab(updator: (t: Tab) => Tab): void {
    this.tab = updator(this.tab);
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
}
