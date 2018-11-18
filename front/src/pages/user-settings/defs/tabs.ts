import { ColorName } from './color-profile';

/**
 * Content of tabs.
 * @package
 */
export type Tab = ColorSettingTab | PhoneUITab;

/**
 * Name of tab.
 */
export type TabName = Tab['page'];

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
 * Phone UI settings tab.
 */
export interface PhoneUITab {
  page: 'phone';
}
