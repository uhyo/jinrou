import * as React from 'react';
import { colorNames, sampleIsBold, ColorSettingTab, ColorName } from '../defs';
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
import {
  requestFocusLogic,
  colorChangeLogic,
  startEditLogic,
  colorChangeCompleteLogic,
  deleteProfileLogic,
  useProfileLogic,
} from '../logic';
import { ColorResult } from './color-box';
import { OneProfile } from './one-profile';
import { TranslationFunction } from 'i18next';
import { observerify } from '../../../util/mobx-react';
import { withTranslationFunction } from '../../../i18n/react';
import { ColorProfileData, defaultProfiles } from '../../../defs/color-profile';
import { ThemeStore, themeStore } from '../../../theme';

export interface IPropColorProfileDisp {
  page: ColorSettingTab;
  store: UserSettingsStore;
}
const addProps = withPropsOnChange(
  ['store'],
  ({ store, t }: IPropColorProfileDisp & { t: TranslationFunction }) => ({
    themeStore,
    onFocus: arrayMapToObject<
      ColorName,
      Record<ColorName, (type: 'color' | 'bg') => void>
    >(colorNames, name => (type: 'color' | 'bg') => {
      requestFocusLogic(t, store, name, type);
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
      colorChangeCompleteLogic(store, colorName, type, color);
    }),
    onEdit: (profile: ColorProfileData) => {
      // edit button is pressed.
      startEditLogic(t, store, profile);
    },
    onDelete: (profile: ColorProfileData) => {
      // delete button is pressed.
      deleteProfileLogic(t, store, profile);
    },
    onUse: (profile: ColorProfileData) => {
      // TODO
      useProfileLogic(store, profile);
    },
  }),
);

interface IPropColorProfileDispInner {
  t: TranslationFunction;
  page: ColorSettingTab;
  store: UserSettingsStore;
  themeStore: ThemeStore;
  onFocus: Record<ColorName, (type: 'color' | 'bg') => void>;
  onColorChange: Record<
    ColorName,
    (type: 'color' | 'bg', color: ColorResult) => void
  >;
  onColorChangeComplete: Record<
    ColorName,
    (type: 'color' | 'bg', color: ColorResult) => void
  >;
  onEdit: (profile: ColorProfileData) => void;
  onDelete: (profile: ColorProfileData) => void;
  onUse: (profile: ColorProfileData) => void;
}

const addDefaultProerties = observerify(
  withPropsOnChange(['t'], ({ t }: IPropColorProfileDispInner) => ({
    defaultProfiles: defaultProfiles.map((df, idx) => ({
      ...df,
      name: t('color.defaultProfile') + ' ' + (idx + 1),
    })),
  })),
);

const ColorProfileDispInner = addDefaultProerties(
  ({
    t,
    page,
    store,
    themeStore,
    onFocus,
    onColorChange,
    onColorChangeComplete,
    onEdit,
    onDelete,
    onUse,
    defaultProfiles,
  }) => {
    const profile = store.currentProfile;
    return (
      <section>
        <h2>{t('color.title')}</h2>
        <WholeWrapper>
          <MainTableWrapper>
            <p>
              {page.editing ? t('color.editing') + '：' : null}
              {profile.name}
            </p>
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
                      t={t}
                      key={profile.id + profile.name}
                      profile={profile}
                      used={
                        themeStore.savedTheme.colorProfile.id === profile.id
                      }
                      edited={
                        page.editing && store.currentProfile.id === profile.id
                      }
                      onEdit={onEdit}
                      onDelete={onDelete}
                      onUse={onUse}
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
export const ColorProfileDisp = withTranslationFunction(
  addProps(ColorProfileDispInner),
);
