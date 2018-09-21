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
import { requestFocusLogic } from '../logic';

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
  }),
);

/**
 * Component of color profile.
 */
export const ColorProfileDisp = observer(
  addProps(({ page, store, onFocus }) => {
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
                      name={name}
                      data={profile.profile[name]}
                      bold={sampleIsBold[name]}
                      onFocus={onFocus[name]}
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
