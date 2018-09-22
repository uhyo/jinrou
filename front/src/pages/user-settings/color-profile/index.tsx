import * as React from 'react';
import { I18n } from '../../../i18n';
import {
  colorNames,
  ColorProfileData,
  sampleIsBold,
  ColorSettingTab,
  ColorName,
  defaultProfiles,
} from '../defs';
import { OneColorDisp } from './one-color';
import { ColorProfile } from '../../../defs';
import { observer } from 'mobx-react';
import {
  ColorsTable,
  WholeWrapper,
  MainTableWrapper,
  ProfileListWrapper,
} from './elements';
import { UserSettingsStore } from '../store';
import { withPropsOnChange } from 'recompose';
import { arrayMapToObject } from '../../../util/array-map-to-object';
import { requestFocusLogic, colorChangeLogic } from '../logic';
import { ColorResult } from './color-box';
import { OneProfile } from './one-profile';
import { TranslationFunction } from 'i18next';
import { observable } from 'mobx';
import { observerify } from '../../../util/mobx-react';

export interface IPropColorProfileDisp {
  page: ColorSettingTab;
  store: UserSettingsStore;
}
const addProps = withPropsOnChange(
  ['store'],
  ({ store }: IPropColorProfileDisp) => ({
    onFocus: arrayMapToObject<
      ColorName,
      Record<ColorName, (type: 'color' | 'bg') => void>
    >(colorNames, name => (type: 'color' | 'bg') => {
      requestFocusLogic(store, name, type);
    }),
    onColorChange: arrayMapToObject<
      ColorName,
      Record<ColorName, (type: 'color' | 'bg', color: ColorResult) => void>
    >(colorNames, colorName => (type: 'color' | 'bg', color) => {
      colorChangeLogic(store, colorName, type, color);
    }),
    onColorChangeComplete: arrayMapToObject<
      ColorName,
      Record<ColorName, (type: 'color' | 'bg', color: ColorResult) => void>
    >(colorNames, colorName => (type: 'color' | 'bg', color) => {
      // TODO
    }),
  }),
);

const ColorProfileDispInner = observerify(
  withPropsOnChange(['t'], ({ t }: IPropColorProfileDispInner) => ({
    defaultProfiles: defaultProfiles(t),
  })),
)(
  ({
    t,
    page,
    store,
    onFocus,
    onColorChange,
    onColorChangeComplete,
    defaultProfiles,
  }) => {
    const profile = store.currentProfile;
    return (
      <section>
        <h2>{t('color.title')}</h2>
        <WholeWrapper>
          <MainTableWrapper>
            <p>{profile.name}</p>
            <ColorsTable>
              <tbody>
                {colorNames.map(name => (
                  <tr key={name}>
                    <OneColorDisp
                      t={t}
                      name={name}
                      data={profile.profile[name]}
                      bold={sampleIsBold[name]}
                      onFocus={onFocus[name]}
                      onColorChange={onColorChange[name]}
                      onColorChangeComplete={onColorChangeComplete[name]}
                      currentFocus={
                        page.colorFocus && page.colorFocus.key === name
                          ? page.colorFocus.type
                          : null
                      }
                    />
                  </tr>
                ))}
              </tbody>
            </ColorsTable>
          </MainTableWrapper>
          <ProfileListWrapper>
            <p>{t('color.savedProfiles')}</p>
            {store.savedColorProfiles == null
              ? t('loading')
              : store.savedColorProfiles
                  .concat(defaultProfiles)
                  .map(profile => (
                    <OneProfile
                      key={profile.id + profile.name}
                      profile={profile}
                    />
                  ))}
          </ProfileListWrapper>
        </WholeWrapper>
      </section>
    );
  },
);

/**
 * Component of color profile.
 */
export const ColorProfileDisp = addProps(props => {
  return <I18n>{t => <ColorProfileDispInner t={t} {...props} />}</I18n>;
});

interface IPropColorProfileDispInner {
  t: TranslationFunction;
  page: ColorSettingTab;
  store: UserSettingsStore;
  onFocus: Record<ColorName, (type: 'color' | 'bg') => void>;
  onColorChange: Record<
    ColorName,
    (type: 'color' | 'bg', color: ColorResult) => void
  >;
  onColorChangeComplete: Record<
    ColorName,
    (type: 'color' | 'bg', color: ColorResult) => void
  >;
}
