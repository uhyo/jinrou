import { Tab } from '../defs/tabs';

/**
 * Create an update of tab to start editing.
 */
export function startEditUpdator(): (tab: Tab) => Tab {
  return tab => {
    if (tab.page === 'color') {
      return {
        ...tab,
        editing: true,
        colorFocus: null,
      };
    } else {
      return tab;
    }
  };
}

/**
 * Create an update of tab to end editing.
 */
export function endEditUpdator(): (tab: Tab) => Tab {
  return tab => {
    if (tab.page === 'color') {
      return {
        ...tab,
        editing: false,
        colorFocus: null,
      };
    } else {
      return tab;
    }
  };
}
