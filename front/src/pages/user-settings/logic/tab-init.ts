import { assertNever } from '../../../util/assert-never';
import { TabName, Tab, ColorSettingTab, PhoneUITab } from '../defs/tabs';

/**
 * Initialize a tab of given kind.
 */
export function initTab<P extends TabName>(page: P): Extract<Tab, { page: P }> {
  const p = page as TabName;
  switch (p) {
    case 'color': {
      const res: ColorSettingTab = {
        page: 'color',
        editing: false,
        colorFocus: null,
      };
      return res as any;
    }
    case 'phone': {
      const res: PhoneUITab = {
        page: 'phone',
      };
      return res as any;
    }
    default: {
      return assertNever(p);
    }
  }
}
