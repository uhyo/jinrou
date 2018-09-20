import * as React from 'react';
import { I18n } from '../../../i18n';
import { colorNames, ColorProfileData, sampleIsBold } from '../defs';
import { OneColorDisp } from './one-color';
import { ColorProfile } from '../../../defs';
import { observer } from 'mobx-react';
import { ColorsTable } from './elements';

/**
 * Component of color profile.
 */
const ColorProfileDispInner: React.StatelessComponent<{
  profile: ColorProfileData;
}> = ({ profile }) => {
  return (
    <I18n>
      {t => (
        <section>
          <h2>{t('color.title')}</h2>
          <ColorsTable>
            <tbody>
              {colorNames.map(name => (
                <tr key={name}>
                  <OneColorDisp
                    name={name}
                    data={profile.profile[name]}
                    bold={sampleIsBold[name]}
                  />
                </tr>
              ))}
            </tbody>
          </ColorsTable>
        </section>
      )}
    </I18n>
  );
};

export const ColorProfileDisp = observer(ColorProfileDispInner);
