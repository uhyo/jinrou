import * as React from 'react';
import { UserSettingsStore } from '../store';
import { withPropsOnChange, withProps } from 'recompose';
import { TranslationFunction } from '../../../i18n';
import { ThemeStore, themeStore } from '../../../theme';
import { observerify } from '../../../util/mobx-react';
import { observer } from 'mobx-react';
import { withTranslationFunction } from '../../../i18n/react';
import { ControlsWrapper, ControlsName } from '../commons/controls-wrapper';
import { Wrapper } from './elements';
import { RadioButtons } from '../commons/radio';
import { PhoneUITab } from '../defs/tabs';

export interface IPropPhoneUIDisp {
  page: PhoneUITab;
  store: UserSettingsStore;
}

interface IPropPhoneUIDispInner {
  t: TranslationFunction;
  page: PhoneUITab;
  store: UserSettingsStore;
  themeStore: ThemeStore;
  onUIUseChange: (value: string) => void;
}

const addProps = withProps(({ store }: IPropPhoneUIDisp) => ({
  themeStore,
  onUIUseChange: (value: string) => {
    themeStore.update({
      phoneUI: {
        ...themeStore.savedTheme.phoneUI,
        use: value === 'yes',
      },
    });
    themeStore.saveToStorage();
  },
}));

const addDefaultProerties = observer;

const ColorProfileDispInner = addDefaultProerties(
  ({ t, page, store, onUIUseChange, themeStore }: IPropPhoneUIDispInner) => {
    return (
      <Wrapper>
        <ControlsWrapper>
          <ControlsName>{t('phone.ui.title')}</ControlsName>
          <RadioButtons
            current={themeStore.savedTheme.phoneUI.use ? 'yes' : 'no'}
            options={[
              {
                value: 'yes',
                label: t('phone.ui.yes'),
              },
              {
                value: 'no',
                label: t('phone.ui.no'),
              },
            ]}
            onChange={onUIUseChange}
          />
        </ControlsWrapper>
      </Wrapper>
    );
  },
);
/**
 * Component of color profile.
 */
export const PhoneUIDisp = withTranslationFunction(
  addProps(ColorProfileDispInner),
);
