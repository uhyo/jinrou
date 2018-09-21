import * as React from 'react';
import { I18n } from '../../../i18n';
import {
  colorNames,
  ColorProfileData,
  sampleIsBold,
  ColorSettingTab,
  ColorName,
} from '../defs';
import { OneColorDisp } from './one-color';
import { ColorProfile } from '../../../defs';
import { observer } from 'mobx-react';
import { ColorsTable } from './elements';
import { UserSettingsStore } from '../store';
import { withPropsOnChange } from 'recompose';
import { arrayMapToObject } from '../../../util/array-map-to-object';
import { requestFocusLogic, colorChangeLogic } from '../logic';
import { ColorResult } from './color-box';

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

/**
 * Component of color profile.
 */
export const ColorProfileDisp = observer(
  addProps(({ page, store, onFocus, onColorChange, onColorChangeComplete }) => {
    const profile = store.currentProfile;
    return (
      <I18n>
        {t => (
          <section>
            <h2>{t('color.title')}</h2>
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
          </section>
        )}
      </I18n>
    );
  }),
);
