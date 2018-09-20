import * as React from 'react';
import { I18n } from '../../../i18n';
import { OneColor } from '../../../defs';
import { observer } from 'mobx-react';
import { ColorBox } from './color-box';
import { SampleTextWrapper } from './elements';

const OneColorDispInner: React.StatelessComponent<{
  /**
   * name of this color setting.
   */
  name: string;
  /**
   * data of one color.
   */
  data: OneColor;
  /**
   * Whether text is shown in bold along with this color setting.
   */
  bold: boolean;
}> = ({ name, bold, data: { color, bg } }) => {
  return (
    <I18n>
      {t => (
        <>
          <th>{t(`color.colorSetting.${name}`)}</th>
          <td>
            <ColorBox color={bg} label={t('color.backgroundColor')} />
            <ColorBox color={color} label={t('color.textColor')} />
            <SampleText color={color} bg={bg} bold={bold}>
              {t('color.sampleText')}
            </SampleText>
          </td>
        </>
      )}
    </I18n>
  );
};

const SampleText: React.StatelessComponent<{
  color: string;
  bg: string;
  bold: boolean;
}> = ({ color, bg, bold, children }) => {
  const styleObject: React.CSSProperties = {
    color,
    backgroundColor: bg,
    fontWeight: bold ? 'bold' : 'normal',
  };
  return <SampleTextWrapper style={styleObject}>{children}</SampleTextWrapper>;
};

export const OneColorDisp = observer(OneColorDispInner);
