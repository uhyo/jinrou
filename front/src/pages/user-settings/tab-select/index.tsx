import { UserSettingsStore } from '../store';
import { TranslationFunction } from '../../../i18n';
import { withTranslationFunction } from '../../../i18n/react';
import { Wrapper } from './elements';
import * as React from 'react';
import { Button, ActiveButton } from '../../../common/forms/button';
import { withPropsOnChange, withProps } from 'recompose';
import { arrayMapToObject } from '../../../util/array-map-to-object';
import { initTab } from '../logic/tab-init';
import { TabName } from '../defs/tabs';

export interface IPropTabSelect {
  store: UserSettingsStore;
}

interface IPropTabSelectInner extends IPropTabSelect {
  t: TranslationFunction;
  onTabSelect: Record<TabName, () => void>;
}

/**
 * List of tabs.
 */
const tabNames: Array<TabName> = ['phone', 'color'];

/**
 * Tab selection component.
 */
const TabSelectInner = ({ store, t, onTabSelect }: IPropTabSelectInner) => {
  return (
    <Wrapper>
      {tabNames.map(tab => {
        const pageName = t(`user_settings_client:${tab}.title`);
        return (
          <ActiveButton
            key={tab}
            onClick={onTabSelect[tab]}
            active={store.tab.page === tab}
          >
            {pageName}
          </ActiveButton>
        );
      })}
    </Wrapper>
  );
};

const addProps = withProps(({ store }: IPropTabSelect) => ({
  onTabSelect: arrayMapToObject(tabNames, tab => () => {
    store.setTab(initTab(tab));
  }),
}));

export const TabSelect = withTranslationFunction(addProps(TabSelectInner));
