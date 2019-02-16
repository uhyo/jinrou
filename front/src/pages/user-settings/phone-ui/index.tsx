import * as React from 'react';
import { UserSettingsStore } from '../store';
import { withPropsOnChange, withProps } from 'recompose';
import { TranslationFunction } from '../../../i18n';
import { ThemeStore, themeStore } from '../../../theme';
import { observer } from 'mobx-react';
import { withTranslationFunction } from '../../../i18n/react';
import { Controls } from '../../../common/forms/controls-wrapper';
import { Wrapper } from './elements';
import { RadioButtons } from '../../../common/forms/radio';
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
  onFontSizeChange: (value: string) => void;
  onSpeakFormPositionChange: (value: string) => void;
}

const addProps = withProps(({ store }: IPropPhoneUIDisp) => ({
  themeStore,
  onUIUseChange: (value: string) => {
    const use = value === 'yes';
    themeStore.update({
      phoneUI: {
        ...themeStore.savedTheme.phoneUI,
        use,
      },
    });
    themeStore.saveToStorage();
    store.onChangePhoneUI(use);
  },
  onFontSizeChange: (value: string) => {
    themeStore.update({
      phoneUI: {
        ...themeStore.savedTheme.phoneUI,
        fontSize: value as any,
      },
    });
    themeStore.saveToStorage();
  },
  onSpeakFormPositionChange: (value: string) => {
    themeStore.update({
      phoneUI: {
        ...themeStore.savedTheme.phoneUI,
        speakFormPosition: value as any,
      },
    });
    themeStore.saveToStorage();
  },
}));

const addDefaultProerties = observer;

const ColorProfileDispInner = addDefaultProerties(
  ({
    t,
    onUIUseChange,
    onFontSizeChange,
    onSpeakFormPositionChange,
    themeStore,
  }: IPropPhoneUIDispInner) => {
    return (
      <Wrapper>
        <Controls title={t('phone.ui.title')}>
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
        </Controls>
        <Controls
          title={t('phone.fontSize.title')}
          description={t('phone.fontSize.description')}
        >
          <RadioButtons
            current={themeStore.savedTheme.phoneUI.fontSize}
            options={['large', 'normal', 'small', 'very-small'].map(value => ({
              value,
              label: t(`phone.fontSize.${value}`),
            }))}
            onChange={onFontSizeChange}
          />
        </Controls>
        <Controls
          title={t('phone.speakFormPosition.title')}
          description={t('phone.speakFormPosition.description')}
        >
          <RadioButtons
            current={themeStore.savedTheme.phoneUI.speakFormPosition}
            options={['normal', 'fixed'].map(value => ({
              value,
              label: t(`phone.speakFormPosition.${value}`),
            }))}
            onChange={onSpeakFormPositionChange}
          />
        </Controls>
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
