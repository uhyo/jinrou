import * as React from 'react';
import { withHandlers } from 'recompose';
import { I18n } from '../../../i18n';
import { OneColor } from '../../../defs';
import { observer } from 'mobx-react';
import { ColorBox } from './color-box';
import { SampleTextWrapper } from './elements';

export interface IPropOneColorDisp {
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
  /**
   * current focus in this disp.
   */
  currentFocus: 'color' | 'bg' | null;
  /**
   * Callback for focusing on one color box.
   */
  onFocus(type: 'color' | 'bg'): void;
}

const handlersComposer = withHandlers({
  onFgFocus: (props: IPropOneColorDisp) => () => {
    props.onFocus('color');
  },
  onBgFocus: (props: IPropOneColorDisp) => () => {
    props.onFocus('bg');
  },
});

export const OneColorDisp = observer(
  handlersComposer(
    ({
      name,
      bold,
      currentFocus,
      onFgFocus,
      onBgFocus,
      data: { color, bg },
    }) => {
      return (
        <I18n>
          {t => (
            <>
              <th>{t(`color.colorSetting.${name}`)}</th>
              <td>
                <ColorBox
                  color={bg}
                  label={t('color.backgroundColor')}
                  showPicker={currentFocus === 'bg'}
                  onFocus={onBgFocus}
                />
                <ColorBox
                  color={color}
                  label={t('color.textColor')}
                  showPicker={currentFocus === 'color'}
                  onFocus={onFgFocus}
                />
                <SampleText color={color} bg={bg} bold={bold}>
                  {t('color.sampleText')}
                </SampleText>
              </td>
            </>
          )}
        </I18n>
      );
    },
  ),
);

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
