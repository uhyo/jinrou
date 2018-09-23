import * as React from 'react';
import {
  withHandlers,
  compose,
  InferableComponentEnhancerWithProps,
} from 'recompose';
import { I18n } from '../../../i18n';
import { OneColor } from '../../../defs';
import { observer } from 'mobx-react';
import { ColorBox, ColorResult } from './color-box';
import { SampleTextWrapper } from './elements';
import { TranslationFunction } from 'i18next';
import { observerify } from '../../../util/mobx-react';

export interface IPropOneColorDisp {
  t: TranslationFunction;
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
  /**
   * Callback for changing color.
   */
  onColorChange(type: 'color' | 'bg', color: ColorResult): void;
  /**
   * Callback for color is fixed.
   */
  onColorChangeComplete(type: 'color' | 'bg', color: ColorResult): void;
}

const handlersComposer = withHandlers({
  onFgFocus: (props: IPropOneColorDisp) => () => {
    props.onFocus('color');
  },
  onBgFocus: (props: IPropOneColorDisp) => () => {
    props.onFocus('bg');
  },
  onFgChange: (props: IPropOneColorDisp) => (color: ColorResult) => {
    props.onColorChange('color', color);
  },
  onBgChange: (props: IPropOneColorDisp) => (color: ColorResult) => {
    props.onColorChange('bg', color);
  },
  onFgChangeComplete: (props: IPropOneColorDisp) => (color: ColorResult) => {
    props.onColorChangeComplete('color', color);
  },
  onBgChangeComplete: (props: IPropOneColorDisp) => (color: ColorResult) => {
    props.onColorChangeComplete('bg', color);
  },
});

export const OneColorDisp = observerify(handlersComposer)(
  ({
    t,
    name,
    bold,
    currentFocus,
    onFgFocus,
    onBgFocus,
    onFgChange,
    onBgChange,
    onFgChangeComplete,
    onBgChangeComplete,
    data: { color, bg },
  }) => {
    return (
      <>
        <th>{t(`color.colorSetting.${name}`)}</th>
        <td>
          <ColorBox
            color={bg}
            label={t('color.backgroundColor')}
            showPicker={currentFocus === 'bg'}
            onFocus={onBgFocus}
            onColorChange={onBgChange}
            onColorChangeComplete={onBgChangeComplete}
          />
          <ColorBox
            color={color}
            label={t('color.textColor')}
            showPicker={currentFocus === 'color'}
            onFocus={onFgFocus}
            onColorChange={onFgChange}
            onColorChangeComplete={onFgChangeComplete}
          />
          <SampleText color={color} bg={bg} bold={bold}>
            {t('color.sampleText')}
          </SampleText>
        </td>
      </>
    );
  },
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
